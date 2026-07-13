const express = require('express');
const http = require('http');
const Redis = require('ioredis');
const fs = require('fs');
const readline = require('readline');
const { Server } = require('socket.io'); // 👈 Canlı bağlantılar için Socket.io ekledik

const app = express();
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
        console.log(`2. Adım: dictionary.txt okundu. Toplam ${kelimeHavuzu.length} kelime.`);
        await redisClient.del('kelime_havuzu');
        if (kelimeHavuzu.length > 0) {
            await redisClient.sadd('kelime_havuzu', kelimeHavuzu);
            console.log("3. Adım: Kelimeler Redis'e yüklendi!");
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

server.listen(3000, () => {
    console.log('Sunucu 3000 portunda hazır.');
});