// lib/screens/player_screen.dart

import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  final String playerName;
  final String roomCode;

  const PlayerScreen({
    super.key,
    required this.playerName,
    required this.roomCode,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Şimdilik test amaçlı lobide duran diğer oyuncular
  // İleride WebSocket + Redis bağlandığında bu liste diğer öğrenciler girdikçe anlık güncellenecek!
  final List<String> joinedPlayers = [
    'Ceyda',
    'Ahmet',
    'Ayşe',
    'Mehmet',
    'Selin', // Test için oyuncunun kendisi hariç lobi kalabalık gözüksün kanka
  ];

  @override
  Widget build(BuildContext context) {
    // Eğer listede oyuncunun kendi adı yoksa test amaçlı listeye ekleyelim
    if (!joinedPlayers.contains(widget.playerName)) {
      joinedPlayers.add(widget.playerName);
    }

    return Scaffold(
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
                // ÜST KISIM: Oda Kodu Kartı (Host ekranı ile aynı şık tasarım)
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
                          'BAĞLANILAN ODA KODU',
                          style: TextStyle(color: Color(0xFF8E8EAF), fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.roomCode,
                          style: const TextStyle(
                            color: Color(0xFF00D2FF), // Orijinal turkuaz neon
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

                // ORTA KISIM: Oyuncu Sayısı Başlığı ve Odadan Çık Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Odada Kimler Var?',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('${joinedPlayers.length} Oyuncu'),
                          backgroundColor: const Color(0xFF2E2E5C),
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    
                    // 🚪 ODADAN ÇIK BUTONU
                    TextButton.icon(
                      onPressed: () {
                        // Bir önceki giriş ekranına geri fırlatır
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      label: const Text(
                        'Odadan Çık',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // OYUNCU LİSTESİ: Oyuncu da odadaki herkesi görebilecek
                Expanded(
                  child: ListView.builder(
                    itemCount: joinedPlayers.length,
                    itemBuilder: (context, index) {
                      bool isMe = joinedPlayers[index] == widget.playerName;
                      return Card(
                        color: const Color(0xFF101026),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isMe ? const Color(0xFF00D2FF) : const Color(0xFF2E2E5C), 
                            width: isMe ? 1.5 : 1, // Oyuncunun kendi ismini belli etmek için turkuaz çerçeve
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.person, 
                            color: isMe ? const Color(0xFF00D2FF) : const Color(0xFF8E8EAF),
                          ),
                          title: Text(
                            joinedPlayers[index] + (isMe ? " (Sen)" : ""),
                            style: TextStyle(
                              color: isMe ? const Color(0xFF00D2FF) : Colors.white, 
                              fontSize: 16, 
                              fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(Icons.check_circle, color: Color(0xFF00D2FF)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // EN ALT KISIM: Bilgilendirme Alanı (Buton yerine)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181832).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E2E5C)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Hostun oyunu başlatması bekleniyor...',
                        style: TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF8E8EAF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}