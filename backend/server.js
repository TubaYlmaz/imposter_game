const express = require('express');
const http = require('http');
const Redis = require('ioredis');
const fs = require('fs');
const readline = require('readline');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
const server = http.createServer(app);

// 1. Redis İstemcisini Oluştur
const redisClient = new Redis();

redisClient.on('connect', () => {
    console.log("1. Adım: Redis'e başarıyla bağlanıldı!");
    kelimeleriYukle();
});

redisClient.on('error', (err) => {
    console.log('Redis Hatası:', err);
});

// 2. TXT Dosyasını Okuma ve Redis'e Yükleme Fonksiyonu
function kelimeleriYukle() {
    const kelimeHavuzu = [];

    const rl = readline.createInterface({
        input: fs.createReadStream('../dictionary.txt'),
        output: process.stdout,
        terminal: false
    });

    rl.on('line', (line) => {
        const temizKelime = line.trim();
        if (temizKelime) {
            kelimeHavuzu.push(temizKelime);
        }
    });

    rl.on('close', async () => {
        console.log(`2. Adım: dictionary.txt dosyası okundu. Toplam ${kelimeHavuzu.length} kelime bulundu.`);

        await redisClient.del('kelime_havuzu');

        if (kelimeHavuzu.length > 0) {
            await redisClient.sadd('kelime_havuzu', kelimeHavuzu);
            console.log("3. Adım: Tüm kelimeler başarıyla Redis'e yüklendi!");

            const testKelime = await redisClient.srandmember('kelime_havuzu');
            console.log("🎯 Redis Testi - Rastgele Seçilen Kelime:", testKelime);
        } else {
            console.log("⚠️ Uyarı: dictionary.txt dosyası boş veya bulunamadı!");
        }
    });
}

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