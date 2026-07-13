// lib/screens/host_login_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // dictionary.json okumak için eklendi kanka
import 'host_screen.dart';
import 'player_screen.dart'; 

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

  // =========================================================================
  // ⚙️ YENİ EKLENEN YER: HOST AYAR DEĞİŞKENLERİ
  // =========================================================================
  String _selectedMod = 'Klasik';
  String _selectedCategory = 'Rastgele';
  int _selectedImpostorCount = 1;

  final List<String> _oyunModlari = ['Klasik', 'Yakin Kelime'];
  List<String> _kategoriler = ['Rastgele']; 
  bool _isJsonLoading = true; // JSON yüklenirken bekletmek için kanka
  // =========================================================================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kategorileriYukle(); // Ekran açılır açılmaz JSON'ı tarıyoruz kanka 🔥
  }

  // JSON dosyasının içindeki kategori isimlerini dinamik çeken fonksiyon kanka
  Future<void> _kategorileriYukle() async {
    try {
      final String response = await rootBundle.loadString('dictionary.json');
      final Map<String, dynamic> data = json.decode(response);
      
      setState(() {
        _kategoriler = ['Rastgele', ...data.keys.toList()];
        _isJsonLoading = false;
      });
    } catch (e) {
      debugPrint("JSON okuma hatası kanka: $e");
      setState(() { _isJsonLoading = false; });
    }
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10, width: 1),
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
                    
                    // JSON yüklenirken spinner dönüyor, yüklenince içerik geliyor kanka
                    _isJsonLoading
                        ? const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(color: Colors.redAccent),
                          )
                        : IntrinsicHeight(
                            child: SizedBox(
                              // Dropdownlar gelince sığması için yüksekliği otomatik veya daha esnek bıraktık kanka
                              width: double.infinity,
                              child: AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, child) {
                                  return IndexedStack(
                                    index: _tabController.index,
                                    children: [
                                      _buildHostForm(),
                                      _buildJoinForm(),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Sekme: ODA KURMA FORMU (YENİ SEÇENEKLERLE BERABER 🚀)
  Widget _buildHostForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1A1A2E)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İsim Girişi
            TextField(
              controller: _hostNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'İsminiz (Öğretmen/Host)',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Oyun Modu Seçimi Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMod,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Oyun Modu',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(12)),
              ),
              items: _oyunModlari.map((mod) => DropdownMenuItem(value: mod, child: Text(mod == 'Klasik' ? 'Klasik (İmpostor Kelimeyi Görmez)' : 'Yakın Kelime (Farklı Kelime)'))).toList(),
              onChanged: (val) => setState(() => _selectedMod = val!),
            ),
            const SizedBox(height: 16),

            // 2. Kategori Seçimi Dropdown (JSON'dan Dinamik Besleniyor kanka)
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Kelime Kategorisi',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(12)),
              ),
              items: _kategoriler.map((kat) => DropdownMenuItem(value: kat, child: Text(kat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),

            // 3. İmpostor Sayısı Seçimi Dropdown
            DropdownButtonFormField<int>(
              value: _selectedImpostorCount,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'İmpostor Sayısı',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(12)),
              ),
              items: [1, 2, 3].map((count) => DropdownMenuItem(value: count, child: Text('$count İmpostor'))).toList(),
              onChanged: (val) => setState(() => _selectedImpostorCount = val!),
            ),
            const SizedBox(height: 24),

            // ODA OLUŞTUR BUTONU
            ElevatedButton(
              onPressed: () {
                if (_hostNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen isminizi girin!')),
                  );
                  return;
                }
                
                // Seçilen ayarları bir sonraki ekrana paslıyoruz kanka
                // host_login_screen.dart içindeki ODA OLUŞTUR butonunun onPressed içi:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HostScreen(
                      gameMode: _selectedMod,
                      category: _selectedCategory,
                      impostorCount: _selectedImpostorCount,
                    ),
                  ),
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
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
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
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              String pName = _playerNameController.text.trim();
              String rCode = _roomCodeController.text.trim().toUpperCase();

              if (pName.isEmpty || rCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen isim ve oda kodunu eksikosiz doldurun!')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(playerName: pName, roomCode: rCode),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E2E5C),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
            ),
            child: const Text('ODAYA KATIL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}