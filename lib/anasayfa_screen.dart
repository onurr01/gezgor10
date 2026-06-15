import 'package:flutter/material.dart';
import 'package:gezgor10/adminprofil_screen.dart';
import 'package:gezgor10/favoriler_screen.dart';
import 'package:gezgor10/kullaniciprofil_screen.dart';
import 'package:gezgor10/mekan_liste_page.dart';

class SecimEkrani extends StatefulWidget {
  final bool isAdmin;

  const SecimEkrani({Key? key, required this.isAdmin}) : super(key: key);

  @override
  State<SecimEkrani> createState() => _SecimEkraniState();
}

class _SecimEkraniState extends State<SecimEkrani> {
  int _currentIndex = 0;

  // Profil sayfasına yönlendirme için yardımcı metod
  void _navigateToProfile() {
    if (widget.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminProfilSayfasi()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KullaniciProfilSayfasi()),
      );
    }
  }

  List<Widget> get _pages {
    return [
      _buildMainContent(),
      const FavoriPage(),
      // Profil sayfası yerine bir placeholder koyuyoruz, yönlendirme onTap ile yapılacak
      Container(),
    ];
  }

  Widget _buildMainContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00838F), Color(0xFF006064)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSelectionCard(
                        'BELEDIYE TESİSLERİ',
                        'assets/images/belediye_tesisleri.jpg',
                        'Belediye Tesisleri',
                      ),
                      const SizedBox(height: 16),
                      _buildSelectionCard(
                        'ORMAN VE KORULAR',
                        'assets/images/orman_korular.jpeg',
                        'Orman ve Korular',
                      ),
                      const SizedBox(height: 16),
                      _buildSelectionCard(
                        'MESİRE ALANLARI',
                        'assets/images/mesire_alanlari.webp',
                        'Mesire Alanları',
                      ),
                      const SizedBox(height: 16),
                      _buildSelectionCard(
                        'TARİHİ YERLER',
                        'assets/images/müzeler.webp',
                        'Tarihi Yerler',
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMekanList(String turu) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MekanListePage(turu: turu)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Profil butonuna basıldığında yönlendirme yap
            _navigateToProfile();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        backgroundColor: Colors.white,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal.shade800,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(String title, String imagePath, String turu) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _navigateToMekanList(turu);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(imagePath, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    color: Colors.white.withOpacity(0.85),
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF00838F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
