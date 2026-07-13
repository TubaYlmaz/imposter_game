// lib/screens/host_screen.dart

import 'package:flutter/material.dart';
import 'dart:math'; 

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  // Şimdilik test amaçlı yazdığımız öğrenci listesi
  final List<String> joinedPlayers = [
    'Ceyda',
    'Ahmet',
    'Ayşe',
    'Mehmet',
  ];

  late String roomCode;

  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığı an kodu 6 haneli ve rastgele üretiyoruz
    roomCode = _generateRandomRoomCode();
  }

  // 6 Haneli Rastgele Kod Üreten Fonksiyon
  String _generateRandomRoomCode() {
    const chars = 'ABCDEFGHJKLMNOPQRSTUVWXYZ23456789'; 
    Random random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Giriş ekranıyla birebir aynı mor-lacivert neon gradyan arka plan
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E1E38),
              Color(0xFF13132B),
              Color(0xFF0B0B1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ÜST KISIM: Oda Kodu Bilgisi (Sizin Panele Uygun)
                Card(
                  color: const Color(0xFF181832).withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Color(0xFF2E2E5C), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'ÖĞRENCİLER İÇİN ODA KODU',
                          style: TextStyle(color: Color(0xFF8E8EAF), fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          roomCode,
                          style: const TextStyle(
                            color: Color(0xFF00D2FF), // Orijinal turkuaz neon kod renginiz
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // ORTA KISIM: Katılan Oyuncu Sayısı ve Başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Katılan Oyuncular',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text('${joinedPlayers.length} Oyuncu'),
                      backgroundColor: const Color(0xFF2E2E5C),
                      side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // OYUNCU LİSTESİ: Anlık girenlerin listelendiği alan
                Expanded(
                  child: joinedPlayers.isEmpty
                      ? const Center(
                          child: Text(
                            'Oyuncuların gelmesi bekleniyor...',
                            style: TextStyle(color: Color(0xFF8E8EAF), fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: joinedPlayers.length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: const Color(0xFF101026),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFF2E2E5C), width: 1),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Color(0xFF8E8EAF)),
                                title: Text(
                                  joinedPlayers[index],
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                trailing: const Icon(Icons.check_circle, color: Color(0xFF00D2FF)), // Turkuaz onay
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),

                // EN ALT KISIM: Oyunu Başlatma Butonu
                ElevatedButton(
                  onPressed: () {
                    debugPrint("Oyunu Başlat butonuna basıldı! Üretilen Kod: $roomCode");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D2FF), // Turkuaz buton
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'OYUNU BAŞLAT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B0B1A), letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} // Sınıfı kapatan parantez burası kanka, az önce uçmuştu