const express = require('express');
const http = require('http');
const Redis = require('ioredis');
const fs = require('fs');
const readline = require('readline'); // .txt dosyasını satır satır okumak için yerleşik modül

const app = express();
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

    // '../dictionary.txt' diyerek bir üst klasördeki (imposter_game içindeki) dosyaya erişiyoruz
    const rl = readline.createInterface({
        input: fs.createReadStream('../dictionary.txt'),
        output: process.stdout,
        terminal: false
    });

    // Dosyadaki her bir satırı tek tek yakalıyoruz
    rl.on('line', (line) => {
        const temizKelime = line.trim();
        if (temizKelime) {
            kelimeHavuzu.push(temizKelime);
        }
    });

    // Dosyanın sonuna gelindiğinde çalışacak kısım
    rl.on('close', async () => {
        console.log(`2. Adım: dictionary.txt dosyası okundu. Toplam ${kelimeHavuzu.length} kelime bulundu.`);

        // Eski kelimeleri temizle
        await redisClient.del('kelime_havuzu');

        if (kelimeHavuzu.length > 0) {
            // Tüm kelimeleri Redis Set (Küme) yapısına ekliyoruz
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

server.listen(3000, () => {
    console.log('Sunucu 3000 portunda hazır.');
});