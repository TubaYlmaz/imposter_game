const express = require('express');
const http = require('http');
const Redis = require('ioredis');
const fs = require('fs');
const readline = require('readline'); // .txt dosyasını satır satır okumak için yerleşik modül
const { Server } = require('socket.io'); // Canlı bağlantılar için Socket.io
const cors = require('cors'); // 👈 İşte o meşhur paketimiz burada!

const app = express();
app.use(cors()); // Flutter Web ve Mobil ağ istekleri için CORS aktif
app.use(express.json()); // HTTP POST isteklerindeki JSON gövdelerini okuyabilmek için

const server = http.createServer(app);

// WebSocket için CORS ayarları
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const redisClient = new Redis();

redisClient.on('connect', () => {
    console.log("1. Adım: Redis'e başarıyla bağlanıldı!");
    kelimeleriYukle();
});

redisClient.on('error', (err) => {
    console.log('Redis Hatası:', err);
});

// Kelime havuzunu yükleyen fonksiyon
function kelimeleriYukle() {
    const kelimeHavuzu = [];

    // '../dictionary.txt' diyerek bir üst klasördeki dosyaya erişiyoruz
    const rl = readline.createInterface({
        input: fs.createReadStream('../dictionary.txt'),
        output: process.stdout,
        terminal: false
    });

    rl.on('line', (line) => {
        const temizKelime = line.trim();
        if (temizKelime) kelimeHavuzu.push(temizKelime);
    });

    rl.on('close', async () => {
        console.log(`2. Adım: dictionary.txt dosyası okundu. Toplam ${kelimeHavuzu.length} kelime bulundu.`);

        // Eski kelimeleri temizle
        await redisClient.del('kelime_havuzu');
        if (kelimeHavuzu.length > 0) {
            await redisClient.sadd('kelime_havuzu', kelimeHavuzu);
            console.log("3. Adım: Tüm kelimeler başarıyla Redis'e yüklendi!");

            // TEST: Rastgele kelime çekmeyi deniyoruz
            const testKelime = await redisClient.srandmember('kelime_havuzu');
            console.log("🎯 Redis Testi - Rastgele Seçilen Kelime:", testKelime);
        } else {
            console.log("⚠️ Uyarı: dictionary.txt dosyası boş veya bulunamadı!");
        }
    });
}

// ==========================================
// 🚀 OYUN LOGIC VE WEBSOCKET BAĞLANTILARI
// ==========================================

io.on('connection', (socket) => {
    console.log(`🔌 Bir kullanıcı bağlandı: ${socket.id}`);

    // ➡️ 1. HOST ODA OLUŞTURDUĞUNDA
    socket.on('create_room', async (data) => {
        const { roomCode, hostName } = data;

        const roomData = {
            host: hostName,
            status: 'waiting',
            players: JSON.stringify([hostName])
        };

        // Redis'e oda verisini 2 saatlik ömürle (TTL) yazıyoruz
        await redisClient.hmset(`room:${roomCode}`, roomData);
        await redisClient.expire(`room:${roomCode}`, 7200);

        socket.join(roomCode);
        console.log(`🏠 Oda Oluşturuldu: ${roomCode} | Host: ${hostName}`);

        socket.emit('room_created', { success: true, roomCode });
    });

    // ➡️ 2. OYUNCU ODAYA KATILMAK İSTEDİĞİNDE
    socket.on('join_room', async (data) => {
        const { roomCode, playerName } = data;

        const roomExists = await redisClient.exists(`room:${roomCode}`);

        if (!roomExists) {
            socket.emit('error_message', { message: '❌ OOOOPS! Böyle bir oda bulunamadı.' });
            return;
        }

        const currentRoom = await redisClient.hgetall(`room:${roomCode}`);
        let players = JSON.parse(currentRoom.players || '[]');

        if (!players.includes(playerName)) {
            players.push(playerName);
        }

        await redisClient.hset(`room:${roomCode}`, 'players', JSON.stringify(players));

        socket.join(roomCode);
        console.log(`🏃‍♂️ ${playerName}, ${roomCode} odasına katıldı.`);

        // Odadaki HERKESE güncel oyuncu listesini fırlatıyoruz!
        io.to(roomCode).emit('room_updated', {
            roomCode,
            players: players,
            host: currentRoom.host
        });
    });

    socket.on('disconnect', () => {
        console.log(`❌ Kullanıcı ayrıldı: ${socket.id}`);
    });
});

// ==========================================
// 🏁 --- API ENDPOINT'LERİ ---
// ==========================================

// 🏁 1. Host'un Oyunu Başlatma İstetiği
app.post('/api/start-game', async (req, res) => {
    try {
        const { roomCode, players } = req.body;

        if (!players || players.length === 0) {
            return res.status(400).json({ error: "Odadaki oyuncu listesi boş olamaz!" });
        }

        const selectedWord = await redisClient.srandmember('kelime_havuzu');

        if (!selectedWord) {
            return res.status(500).json({ error: "Redis kelime havuzu boş!" });
        }

        const randomIndex = Math.floor(Math.random() * players.length);
        const impostorName = players[randomIndex];

        console.log(`🎮 Oda [${roomCode}] için Oyun Başladı!`);
        console.log(`🎯 Seçilen Kelime: ${selectedWord} | 😈 Imposter: ${impostorName}`);

        // Veri tutarlılığı için bilgileri Redis Hash yapısında güncelliyoruz kanka
        await redisClient.hset(`room:${roomCode}`, 'status', 'started');
        await redisClient.hset(`room:${roomCode}`, 'secretWord', selectedWord);
        await redisClient.hset(`room:${roomCode}`, 'impostor', impostorName);

        // Hem Hash'e yazıyoruz hem de arkadaşının eski kod mantığı (String) kırılmasın diye yedek olarak set ediyoruz
        const roomDataString = {
            status: "started",
            secretWord: selectedWord,
            impostor: impostorName
        };
        await redisClient.set(`room:string:${roomCode}`, JSON.stringify(roomDataString));

        // 🔥 WebSocket üzerinden odadaki herkese anlık sinyal gönderiyoruz kanka
        io.to(roomCode).emit('game_started', {
            status: "started",
            secretWord: selectedWord,
            impostor: impostorName
        });

        return res.json({
            status: "success",
            secretWord: selectedWord,
            impostor: impostorName
        });

    } catch (error) {
        console.error("Oyun başlatılırken hata oluştu:", error);
        return res.status(500).json({ error: "Sunucu hatası" });
    }
});

// 📡 2. Oyuncuların Oda Durumunu Sorgulama İstetiği
app.get('/api/game-status/:roomCode', async (req, res) => {
    try {
        const { roomCode } = req.params;

        // Önce Hash yapısından verileri çekelim kanka
        let roomData = await redisClient.hgetall(`room:${roomCode}`);

        // Eğer Hash yapısı boşsa, arkadaşının yazdığı düz string kaydına baksın ki uyumluluk bozulmasın
        if (!roomData || Object.keys(roomData).length === 0) {
            const rawData = await redisClient.get(`room:string:${roomCode}`);
            if (!rawData) {
                return res.json({ status: "waiting" });
            }
            roomData = JSON.parse(rawData);
            return res.json(roomData);
        }

        if (roomData.players) {
            roomData.players = JSON.parse(roomData.players);
        }

        return res.json(roomData); 

    } catch (error) {
        console.error("Oda durumu kontrol edilirken hata oluştu:", error);
        return res.status(500).json({ error: "Sunucu hatası" });
    }
});

// Sunucuyu Dinlemeye Başla
server.listen(3000, () => {
    console.log('Sunucu 3000 portunda hazır.');
});