import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gezgor10/mekan_detay_screen.dart';
import 'girisyap_screen.dart';

class KullaniciProfilSayfasi extends StatefulWidget {
  const KullaniciProfilSayfasi({super.key});

  @override
  State<KullaniciProfilSayfasi> createState() => _KullaniciProfilSayfasiState();
}

class _KullaniciProfilSayfasiState extends State<KullaniciProfilSayfasi>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _kullaniciVerisi;
  bool _isLoading = true;
  bool _isDeletingReview = false;
  bool _isSavingNote = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _kullaniciyiGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _kullaniciyiGetir() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('Uye').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _kullaniciVerisi = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı verisi bulunamadı')),
        );
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama e-postası gönderildi!'),
            backgroundColor: Colors.teal,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta adresi bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteReview(String yorumId, String mekanId) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yapmalısınız'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Yorumu Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Bu yorumu silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sil',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (confirmDelete != true) return;

    setState(() => _isDeletingReview = true);

    try {
      await _firestore
          .collection('Mekanlar')
          .doc(mekanId)
          .collection('yorumlar')
          .doc(yorumId)
          .delete();

      await _firestore
          .collection('Uye')
          .doc(user.uid)
          .collection('yorumlar')
          .doc(yorumId)
          .delete();

      await _updateMekanRating(mekanId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum silindi'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum silinirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDeletingReview = false);
    }
  }

  Future<void> _updateMekanRating(String mekanId) async {
    try {
      final yorumlarSnapshot =
          await _firestore
              .collection('Mekanlar')
              .doc(mekanId)
              .collection('yorumlar')
              .get();

      if (yorumlarSnapshot.docs.isEmpty) {
        await _firestore.collection('Mekanlar').doc(mekanId).update({
          'ortalamaPuan': 0.0,
          'yorumSayisi': 0,
        });
        return;
      }

      double toplamPuan = 0;
      int yorumSayisi = yorumlarSnapshot.docs.length;

      for (var doc in yorumlarSnapshot.docs) {
        toplamPuan += (doc.data()['puan'] ?? 0).toDouble();
      }

      double ortalamaPuan = toplamPuan / yorumSayisi;

      await _firestore.collection('Mekanlar').doc(mekanId).update({
        'ortalamaPuan': ortalamaPuan,
        'yorumSayisi': yorumSayisi,
      });
    } catch (e) {
      debugPrint('Ortalama puan güncellenirken hata: $e');
    }
  }

  Future<void> _editReview(
    BuildContext context,
    String yorumId,
    String mekanId,
    String mevcutYorum,
    double mevcutPuan,
  ) async {
    final TextEditingController yorumController = TextEditingController(
      text: mevcutYorum,
    );
    double yeniPuan = mevcutPuan;

    final bool? confirmEdit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  'Yorumu Düzenle',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: yorumController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Yorum',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Puan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: yeniPuan,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: yeniPuan.toStringAsFixed(1),
                        activeColor: Colors.teal,
                        inactiveColor: Colors.grey[300],
                        onChanged: (value) => setState(() => yeniPuan = value),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.teal),
                    ),
                  ),
                ],
              ),
        );
      },
    );

    if (confirmEdit != true) return;

    try {
      await _firestore
          .collection('Mekanlar')
          .doc(mekanId)
          .collection('yorumlar')
          .doc(yorumId)
          .update({
            'yorum': yorumController.text.trim(),
            'puan': yeniPuan,
            'tarih': Timestamp.now(),
          });

      await _firestore
          .collection('Uye')
          .doc(_auth.currentUser!.uid)
          .collection('yorumlar')
          .doc(yorumId)
          .update({
            'yorum': yorumController.text.trim(),
            'puan': yeniPuan,
            'tarih': Timestamp.now(),
          });

      await _updateMekanRating(mekanId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum güncellendi'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum güncellenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addOrEditNote(
    BuildContext context,
    String? mekanId,
    String? mekanAdi,
    String? existingBaslik,
    String? existingNote,
    String? docId, // Yeni parametre: Belge kimliği
  ) async {
    final TextEditingController baslikController = TextEditingController(
      text: existingBaslik ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: existingNote ?? '',
    );
    final user = _auth.currentUser;

    final bool? confirmAction = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              existingNote == null ? 'Not Ekle' : 'Notu Düzenle',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: baslikController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Not İçeriği',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (baslikController.text.trim().isEmpty ||
                      noteController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Başlık ve içerik boş olamaz'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Kaydet',
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
    );

    if (confirmAction != true || user == null) return;

    setState(() => _isSavingNote = true);

    try {
      final noteData = {
        'mekanId': mekanId,
        'mekanAdi': mekanAdi,
        'baslik': baslikController.text.trim(),
        'not': noteController.text.trim(),
        'tarih': Timestamp.now(),
      };

      if (existingNote == null) {
        await _firestore
            .collection('Uye')
            .doc(user.uid)
            .collection('notlar')
            .doc(mekanId ?? DateTime.now().millisecondsSinceEpoch.toString())
            .set(noteData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not eklendi'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        if (docId == null || docId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçersiz not kimliği'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await _firestore
            .collection('Uye')
            .doc(user.uid)
            .collection('notlar')
            .doc(docId)
            .update(noteData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not güncellendi'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSavingNote = false);
    }
  }

  Future<void> _deleteNote(String mekanId, String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz not kimliği'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Notu Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sil',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (confirmDelete != true) return;

    try {
      await _firestore
          .collection('Uye')
          .doc(user.uid)
          .collection('notlar')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not silindi'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not silinirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
        ),
        title: const Text(
          'Profilim',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
              : _kullaniciVerisi == null
              ? const Center(
                child: Text(
                  'Kullanıcı verisi yok',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00838F), // Arka plan rengi güncellendi
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'profile_avatar',
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TabBar(
                            controller: _tabController,
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 3,
                              ),
                              insets: EdgeInsets.symmetric(horizontal: 20),
                            ),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            labelStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(fontSize: 16),
                            tabs: const [
                              Tab(text: 'Profil Bilgileri'),
                              Tab(text: 'Yorumlarım'),
                              Tab(text: 'Notlarım'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProfilBilgileri(),
                              _buildYorumlarim(),
                              _buildNotlarim(),
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

  Widget _buildProfilBilgileri() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            '${_kullaniciVerisi!['ad']} ${_kullaniciVerisi!['soyad']}',
            _kullaniciVerisi!['email'],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'Telefon',
            _kullaniciVerisi!['telefon'] ?? 'Belirtilmemiş',
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            'Adres',
            '${_kullaniciVerisi!['mahalle'] ?? ''}, ${_kullaniciVerisi!['ilce'] ?? ''}, ${_kullaniciVerisi!['il'] ?? ''}',
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            'Cinsiyet',
            _kullaniciVerisi!['cinsiyet'] ?? 'Belirtilmemiş',
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            'Doğum Tarihi',
            _kullaniciVerisi!['dogumTarihi'] != null
                ? _kullaniciVerisi!['dogumTarihi'].toString().split('T')[0]
                : 'Belirtilmemiş',
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _sendPasswordResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A99D),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.teal.withOpacity(0.3),
            ),
            child: const Text(
              'Şifre Sıfırlama',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => _signOut(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.red.withOpacity(0.3),
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYorumlarim() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Kullanıcı oturumu açık değil',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('Uye')
              .doc(user.uid)
              .collection('yorumlar')
              .orderBy('tarih', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (snapshot.hasError) {
          debugPrint('StreamBuilder hatası: ${snapshot.error}');
          return Center(
            child: Text(
              'Hata: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('Yorum verisi yok. Koleksiyon: Uye/${user.uid}/yorumlar');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'Henüz yorum yapmadınız',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ziyaret ettiğiniz mekanları değerlendirerek başlayabilirsiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        debugPrint('Yorum sayısı: ${snapshot.data!.docs.length}');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final yorumData = doc.data() as Map<String, dynamic>;
            final String yorumId = doc.id;
            final String mekanId = yorumData['mekanId'] ?? '';
            final String yorum = yorumData['yorum'] ?? '';
            final double puan = (yorumData['puan'] ?? 0).toDouble();

            String tarih = 'Belirtilmemiş';
            if (yorumData['tarih'] != null) {
              final timestamp = yorumData['tarih'] as Timestamp;
              final date = timestamp.toDate();
              tarih = '${date.day}.${date.month}.${date.year}';
            }

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('Mekanlar').doc(mekanId).get(),
              builder: (context, mekanSnapshot) {
                String mekanAdi = 'Mekan bilgisi yüklenemedi';
                String kategori = '';
                String mekanFoto = '';

                if (mekanSnapshot.hasData && mekanSnapshot.data!.exists) {
                  final mekanData =
                      mekanSnapshot.data!.data() as Map<String, dynamic>;
                  mekanAdi = mekanData['mekanAdi'] ?? 'İsim yok';
                  kategori = mekanData['kategori'] ?? '';
                  mekanFoto = mekanData['fotoUrl'] ?? '';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Stack(
                            children: [
                              mekanFoto.isNotEmpty
                                  ? Image.network(
                                    mekanFoto,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 150,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white,
                                              ),
                                            ),
                                  )
                                  : Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white,
                                    ),
                                  ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 15,
                                right: 15,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mekanAdi,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (kategori.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Text(
                                          kategori,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        tarih,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            puan.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Yorumunuz',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                yorum,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    debugPrint(
                                      'İncele butonuna basıldı, mekanId: $mekanId',
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => MekanDetayScreen(
                                              mekanId: mekanId,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('İncele'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A99D),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isDeletingReview
                                          ? null
                                          : () {
                                            debugPrint(
                                              'Düzenle butonuna basıldı, _isDeletingReview: $_isDeletingReview',
                                            );
                                            _editReview(
                                              context,
                                              yorumId,
                                              mekanId,
                                              yorum,
                                              puan,
                                            );
                                          },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Düzenle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    disabledBackgroundColor: Colors.blue[200],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isDeletingReview
                                          ? null
                                          : () {
                                            debugPrint(
                                              'Sil butonuna basıldı, _isDeletingReview: $_isDeletingReview',
                                            );
                                            _deleteReview(yorumId, mekanId);
                                          },
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Sil'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    disabledBackgroundColor: Colors.red[200],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotlarim() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Kullanıcı oturumu açık değil',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('Uye')
              .doc(user.uid)
              .collection('notlar')
              .orderBy('tarih', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (snapshot.hasError) {
          debugPrint('StreamBuilder hatası: ${snapshot.error}');
          return Center(
            child: Text(
              'Hata: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Henüz not eklemediniz',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mekanlara not eklemek için bir mekan seçin',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      () =>
                          _addOrEditNote(context, null, null, null, null, null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A99D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Not Ekle',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed:
                    _isSavingNote
                        ? null
                        : () => _addOrEditNote(
                          context,
                          null,
                          null,
                          null,
                          null,
                          null,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A99D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.teal[200],
                ),
                child: const Text(
                  'Yeni Not Ekle',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final noteData = doc.data() as Map<String, dynamic>;
                  final String docId = doc.id; // Belge kimliğini al
                  final String mekanId = noteData['mekanId'] ?? '';
                  final String baslik = noteData['baslik'] ?? 'Başlıksız';
                  final String note = noteData['not'] ?? '';
                  final String tarih =
                      noteData['tarih'] != null
                          ? (noteData['tarih'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')[0]
                          : 'Belirtilmemiş';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: const Icon(
                        Icons.note,
                        color: Color(0xFF00A99D),
                        size: 30,
                      ),
                      title: Text(
                        baslik,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            note,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Tarih: $tarih',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => _addOrEditNote(
                                  context,
                                  mekanId,
                                  noteData['mekanAdi'],
                                  baslik,
                                  note,
                                  docId,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteNote(mekanId, docId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00A99D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
