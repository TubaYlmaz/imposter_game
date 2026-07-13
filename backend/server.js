const express = require('express');
const http = require('http');
const Redis = require('ioredis');
const fs = require('fs');
const readline = require('readline'); // .txt dosyasını satır satır okumak için yerleşik modül

const app = express();
app.use(cors());
app.use(express.json());
const server = http.createServer(app);

// Flutter web veya mobil ağ uyarısı vermesin diye CORS ayarlarını açıyoruz kanka
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

// Kelime havuzunu yükleyen o güzel fonksiyonun (Aynen korundu kanka)
function kelimeleriYukle() {
    const kelimeHavuzu = [];

    // '../dictionary.txt' diyerek bir üst klasördeki (imposter_game içindeki) dosyaya erişiyoruz
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

        // Oda verisini Redis'te saklamak için bir obje hazırlıyoruz
        const roomData = {
            host: hostName,
            status: 'waiting',
            players: JSON.stringify([hostName]) // Hostu da ilk oyuncu olarak ekledik kanka
        };

        // Redis'e oda verisini 2 saatlik ömürle (TTL) yazıyoruz ki şişme yapmasın
        await redisClient.hmset(`room:${roomCode}`, roomData);
        await redisClient.expire(`room:${roomCode}`, 7200);

        // Soketi bu odaya özel odaya (odalar arası chat odası gibi düşün) sokuyoruz
        socket.join(roomCode);
        console.log(`🏠 Oda Oluşturuldu: ${roomCode} | Host: ${hostName}`);

        // Başarılı sinyalini hosta geri dönüyoruz
        socket.emit('room_created', { success: true, roomCode });
    });

    // ➡️ 2. OYUNCU ODAYA KATILMAK İSTEDİĞİNDE
    socket.on('join_room', async (data) => {
        const { roomCode, playerName } = data;

        // Redis'te bu oda kodu var mı kontrol et
        const roomExists = await redisClient.exists(`room:${roomCode}`);

        if (!roomExists) {
            socket.emit('error_message', { message: '❌ OOOOPS! Böyle bir oda bulunamadı.' });
            return;
        }

        // Redis'ten oda verisini çek
        const currentRoom = await redisClient.hgetall(`room:${roomCode}`);
        let players = JSON.parse(currentRoom.players || '[]');

        // Oyuncu zaten odadaysa tekrar ekleme kanka
        if (!players.contains ? players.includes(playerName) : false) {
            // Opsiyonel: isim çakışması kontrolü
        } else {
            players.push(playerName);
        }

        // Güncel oyuncu listesini Redis'e geri yaz
        await redisClient.hset(`room:${roomCode}`, 'players', JSON.stringify(players));

        // Soketi odaya dahil et
        socket.join(roomCode);
        console.log(`🏃‍♂️ ${playerName}, ${roomCode} odasına katıldı.`);

        // 💥 EN KRİTİK YER: Odadaki HERKESE (Host + Tüm Oyuncular) güncel oyuncu listesini fırlatıyoruz!
        io.to(roomCode).emit('room_updated', {
            roomCode,
            players: players,
            host: currentRoom.host
        });
    });

    // ➡️ 3. BAĞLANTI KOPTIĞINDA (Kullanıcı sekmeyi kapattığında vs.)
    socket.on('disconnect', () => {
        console.log(`❌ Kullanıcı ayrıldı: ${socket.id}`);
    });
});

// --- API ENDPOINT'LERİ ---

// 🏁 1. Host'un Oyunu Başlatma İstetiği
app.post('/api/start-game', async (req, res) => {
    try {
        const { roomCode, players } = req.body;

        if (!players || players.length === 0) {
            return res.status(400).json({ error: "Odadaki oyuncu listesi boş olamaz!" });
        }

        // Redis havuzundan rastgele 1 kelime çekiyoruz
        const selectedWord = await redisClient.srandmember('kelime_havuzu');

        if (!selectedWord) {
            return res.status(500).json({ error: "Redis kelime havuzu boş!" });
        }

        // Oyuncuların içinden rastgele bir Imposter seçiyoruz
        const randomIndex = Math.floor(Math.random() * players.length);
        const impostorName = players[randomIndex];

        console.log(`🎮 Oda [${roomCode}] için Oyun Başladı!`);
        console.log(`🎯 Seçilen Kelime: ${selectedWord} | 😈 Imposter: ${impostorName}`);

        // 💾 ODA BİLGİLERİNİ REDIS'E KAYDETME (Oyuncuların okuyabilmesi için)
        const roomData = {
            status: "started",
            secretWord: selectedWord,
            impostor: impostorName
        };

        // Bilgileri JSON string formatında Redis'e kaydediyoruz. Oda kodu anahtar olarak kullanılıyor.
        await redisClient.set(`room:${roomCode}`, JSON.stringify(roomData));

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

// 📡 2. Oyuncuların Oda Durumunu Sorgulama İstetiği (YENİ EKLENDİ)
app.get('/api/game-status/:roomCode', async (req, res) => {
    try {
        const { roomCode } = req.params;

        // Redis'ten odaya ait verileri çekiyoruz
        const rawData = await redisClient.get(`room:${roomCode}`);

        if (!rawData) {
            // Oda henüz oluşturulmamış veya oyun başlamamışsa bekleme statüsü döner
            return res.json({ status: "waiting" });
        }

        const roomData = JSON.parse(rawData);
        return res.json(roomData); // { status: "started", secretWord: "...", impostor: "..." }

    } catch (error) {
        console.error("Oda durumu kontrol edilirken hata oluştu:", error);
        return res.status(500).json({ error: "Sunucu hatası" });
    }
});

// Sunucuyu Dinlemeye Başla
server.listen(3000, () => {
    console.log('Sunucu 3000 portunda hazır.');
});