// lib/screens/host_login_screen.dart

import 'package:flutter/material.dart';
import 'host_screen.dart';
import 'player_screen.dart'; // 👈 En üstteki importların arasına ekle kanka

class HostLoginScreen extends StatefulWidget {
  const HostLoginScreen({super.key});

  @override
  State<HostLoginScreen> createState() => _HostLoginScreenState();
}

class _HostLoginScreenState extends State<HostLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _hostNameController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostNameController.dispose();
    _playerNameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka planı tamamen özelleştirmek için body'i Container ile sarıp gradyan veriyoruz
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Oyun merkezine yakışacak derin lacivert, mor ve siyaha çalan tonlar
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Merkez Kutusu (Card)
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  // Kutu biraz şeffaf olsun ki arkadaki gradyan derinlik katsın (Glow efekti)
                  color: const Color(0xFF0F0F1E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10, width: 1), // İnce şık bir kenarlık
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 30),
                    const Icon(Icons.videogame_asset_rounded, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    const Text(
                      'IMPOSTOR GAME',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    
                    // Üst Sekmeler
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.redAccent,
                      labelColor: Colors.redAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'ODA KUR (HOST)'),
                        Tab(text: 'ODAYA KATIL'),
                      ],
                    ),
                    
                    // Sekme İçerikleri
                    SizedBox(
                      height: 260, 
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHostForm(),
                          _buildJoinForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Sekme: ODA KURMA FORMU
  Widget _buildHostForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _hostNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'İsminiz (Öğretmen/Host)',
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_hostNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen isminizi girin!')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HostScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            child: const Text('ODA OLUŞTUR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // 2. Sekme: ODAYA KATILMA FORMU
  Widget _buildJoinForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _playerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Oyuncu Adı',
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Oda Kodu',
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              String pName = _playerNameController.text.trim();
              String rCode = _roomCodeController.text.trim().toUpperCase(); // Harfleri otomatik büyütelim kanka

              // Basit bir doğrulama yapalım boş geçmesinler
              if (pName.isEmpty || rCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen isim ve oda kodunu eksiksiz doldurun!')),
                );
                return;
              }

              // Her şey okeyse oyuncuyu kendi bekleme ekranına uçuruyoruz!
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    playerName: pName,
                    roomCode: rCode,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E2E5C),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
            ),
            child: const Text(
              'ODAYA KATIL', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}