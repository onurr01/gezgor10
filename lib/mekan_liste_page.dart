import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'mekan_detay_screen.dart';

class MekanListePage extends StatefulWidget {
  final String turu;

  const MekanListePage({Key? key, required this.turu}) : super(key: key);

  @override
  _MekanListePageState createState() => _MekanListePageState();
}

class _MekanListePageState extends State<MekanListePage> {
  final _auth = FirebaseAuth.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isAdmin = false;
      });
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Uye')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        setState(() {
          _isAdmin = userDoc.data()?['role'] == 'admin';
        });
      }
    } catch (e) {
      debugPrint('Admin kontrolü sırasında hata: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _toggleFavorite(
    String mekanId,
    Map<String, dynamic> mekanData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    final String userId = user.uid;
    final favRef = FirebaseFirestore.instance
        .collection('Uye')
        .doc(userId)
        .collection('favorites')
        .doc(mekanId);

    try {
      final doc = await favRef.get();
      if (doc.exists) {
        await favRef.delete();
        debugPrint('Favori kaldırıldı: $mekanId');
        _showSnackBar('Mekan favorilerden kaldırıldı', Colors.redAccent);
      } else {
        final favoriteData = {
          'mekanId': mekanId,
          'mekanAdi': mekanData['mekanAdi'] ?? 'Ad yok',
          'fotoUrl': mekanData['fotoUrl'] ?? '',
          'il': mekanData['il'] ?? '',
          'ilce': mekanData['ilce'] ?? '',
          'mekanTuru': mekanData['mekanTuru'] ?? 'Restoran',
          'eklemeTarihi': FieldValue.serverTimestamp(),
        };
        await favRef.set(favoriteData);
        debugPrint('Favori eklendi: $mekanId, Veri: $favoriteData');
        _showSnackBar('Mekan favorilere eklendi', Colors.teal);
      }
    } catch (e) {
      debugPrint('Favori işlemi sırasında hata: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase hata kodu: ${e.code}, Mesaj: ${e.message}');
      }
      _showSnackBar(
        'İşlem sırasında bir hata oluştu: ${e.toString()}',
        Colors.red,
      );
    }
  }

  Future<void> _deleteMekan(
    String mekanId,
    Map<String, dynamic> mekanData,
  ) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mekanı Sil'),
            content: Text(
              '${mekanData['mekanAdi'] ?? 'Bu mekan'} adlı mekanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmDelete != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(mekanId)
          .delete();

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('Uye').get();
      for (var userDoc in usersSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('Uye')
            .doc(userDoc.id)
            .collection('favorites')
            .doc(mekanId)
            .delete();
      }

      for (var userDoc in usersSnapshot.docs) {
        final yorumlarSnapshot =
            await FirebaseFirestore.instance
                .collection('Uye')
                .doc(userDoc.id)
                .collection('yorumlar')
                .where('mekanId', isEqualTo: mekanId)
                .get();
        for (var yorumDoc in yorumlarSnapshot.docs) {
          await yorumDoc.reference.delete();
        }
      }

      final mekanYorumlarSnapshot =
          await FirebaseFirestore.instance
              .collection('Mekanlar')
              .doc(mekanId)
              .collection('yorumlar')
              .get();
      for (var yorumDoc in mekanYorumlarSnapshot.docs) {
        await yorumDoc.reference.delete();
      }

      _showSnackBar('Mekan başarıyla silindi', Colors.teal);
    } catch (e) {
      debugPrint('Mekan silinirken hata: $e');
      _showSnackBar('Mekan silinirken bir hata oluştu', Colors.red);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Giriş Gerekli'),
            content: const Text('Favori eklemek için lütfen giriş yapın.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    Stream<QuerySnapshot> favStream;
    if (user != null) {
      favStream =
          FirebaseFirestore.instance
              .collection('Uye')
              .doc(user.uid)
              .collection('favorites')
              .snapshots();
    } else {
      favStream = const Stream.empty();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade200],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.turu,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('Mekanlar')
                          .where('mekanTuru', isEqualTo: widget.turu)
                          .snapshots(),
                  builder: (context, mekanSnapshot) {
                    if (mekanSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    }

                    if (!mekanSnapshot.hasData ||
                        mekanSnapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront,
                              size: 80,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bu kategoride mekan bulunamadı.',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final mekanDocs = mekanSnapshot.data!.docs;

                    return StreamBuilder<QuerySnapshot>(
                      stream: favStream,
                      builder: (context, favSnapshot) {
                        Map<String, bool> favorites = {};
                        if (favSnapshot.hasData && user != null) {
                          for (var doc in favSnapshot.data!.docs) {
                            favorites[doc.id] = true;
                          }
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: mekanDocs.length,
                          itemBuilder: (context, index) {
                            final data =
                                mekanDocs[index].data() as Map<String, dynamic>;
                            final docId = mekanDocs[index].id;
                            final isFavorite = favorites[docId] ?? false;

                            return Dismissible(
                              key: Key(docId),
                              direction:
                                  _isAdmin
                                      ? DismissDirection.endToStart
                                      : DismissDirection.none,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                alignment: Alignment.centerRight,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Mekanı Sil'),
                                        content: Text(
                                          '${data['mekanAdi'] ?? 'Bu mekan'} adlı mekanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('İptal'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text(
                                              'Sil',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                              onDismissed: (direction) {
                                _deleteMekan(docId, data);
                              },
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              MekanDetayScreen(mekanId: docId),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                            child:
                                                data['fotoUrl'] != null
                                                    ? Image.network(
                                                      data['fotoUrl'],
                                                      width: double.infinity,
                                                      height: 180,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Container(
                                                            width:
                                                                double.infinity,
                                                            height: 180,
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 60,
                                                              color:
                                                                  Colors
                                                                      .grey[500],
                                                            ),
                                                          ),
                                                    )
                                                    : Container(
                                                      width: double.infinity,
                                                      height: 180,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 60,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child:
                                                _isAdmin
                                                    ? Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: IconButton(
                                                            icon: const Icon(
                                                              Icons.delete,
                                                              color:
                                                                  Colors.white,
                                                              size: 28,
                                                            ),
                                                            constraints:
                                                                const BoxConstraints(
                                                                  minWidth: 0,
                                                                  minHeight: 0,
                                                                ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            onPressed:
                                                                () =>
                                                                    _deleteMekan(
                                                                      docId,
                                                                      data,
                                                                    ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: IconButton(
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.white,
                                                              size: 28,
                                                            ),
                                                            constraints:
                                                                const BoxConstraints(
                                                                  minWidth: 0,
                                                                  minHeight: 0,
                                                                ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => MekanDuzenlemePage(
                                                                        mekanId:
                                                                            docId,
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                    : const SizedBox.shrink(),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    (data['ortalamaPuan'] ??
                                                            4.0)
                                                        .toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(
                                                      0.7,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      data['mekanAdi'] ??
                                                          'Ad Yok',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        shadows: [
                                                          Shadow(
                                                            blurRadius: 3,
                                                            color: Colors.black,
                                                            offset: Offset(
                                                              0,
                                                              1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap:
                                                        () => _toggleFavorite(
                                                          docId,
                                                          data,
                                                        ),
                                                    child: AnimatedSwitcher(
                                                      duration: const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                      transitionBuilder:
                                                          (child, animation) =>
                                                              ScaleTransition(
                                                                scale:
                                                                    animation,
                                                                child: child,
                                                              ),
                                                      child: Icon(
                                                        isFavorite
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        key: ValueKey<bool>(
                                                          isFavorite,
                                                        ),
                                                        color:
                                                            isFavorite
                                                                ? Colors
                                                                    .redAccent
                                                                : Colors.white,
                                                        size: 30,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MekanDuzenlemePage extends StatefulWidget {
  final String mekanId;

  const MekanDuzenlemePage({Key? key, required this.mekanId}) : super(key: key);

  @override
  _MekanDuzenlemePageState createState() => _MekanDuzenlemePageState();
}

class _MekanDuzenlemePageState extends State<MekanDuzenlemePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  final _mekanAdiController = TextEditingController();
  final _bilgiController = TextEditingController();
  final _ilController = TextEditingController();
  final _ilceController = TextEditingController();
  final _mahallesiController = TextEditingController();
  final _mekanTuruController = TextEditingController();
  final _noController = TextEditingController();
  final _sokakController = TextEditingController();

  String? _existingFotoUrl;

  @override
  void initState() {
    super.initState();
    _loadMekanData();
  }

  Future<void> _loadMekanData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('Mekanlar')
              .doc(widget.mekanId)
              .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _mekanAdiController.text = data['mekanAdi'] ?? '';
        _bilgiController.text = data['bilgi'] ?? '';
        _ilController.text = data['il'] ?? '';
        _ilceController.text = data['ilce'] ?? '';
        _mahallesiController.text = data['mahallesi'] ?? '';
        _mekanTuruController.text = data['mekanTuru'] ?? 'Restoran';
        _noController.text = data['no'] ?? '';
        _sokakController.text = data['sokak'] ?? '';
        setState(() {
          _existingFotoUrl = data['fotoUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Mekan verileri yüklenirken hata: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateMekan() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Lütfen tüm zorunlu alanları doldurun', Colors.red);
      return;
    }

    String fotoUrl = _existingFotoUrl ?? '';
    if (_imageFile != null) {
      final storageRef = FirebaseStorage.instance.ref().child(
        'mekanlar/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await storageRef.putFile(_imageFile!);
      fotoUrl = await storageRef.getDownloadURL();
    }

    final updatedData = {
      'mekanAdi': _mekanAdiController.text,
      'bilgi': _bilgiController.text,
      'il': _ilController.text,
      'ilce': _ilceController.text,
      'mahallesi': _mahallesiController.text,
      'mekanTuru': _mekanTuruController.text,
      'no': _noController.text,
      'sokak': _sokakController.text,
      'fotoUrl': fotoUrl,
    };

    try {
      final docRef = FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(widget.mekanId);
      debugPrint('Güncellenecek veri: $updatedData');
      await docRef.update(updatedData);
      final updatedDoc = await docRef.get();
      debugPrint('Güncellenen veri: ${updatedDoc.data()}');
      _showSnackBar('Mekan başarıyla güncellendi', Colors.teal);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Mekan güncellenirken hata: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase hata kodu: ${e.code}, Mesaj: ${e.message}');
      }
      _showSnackBar('Mekan güncellenirken bir hata oluştu', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _mekanAdiController.dispose();
    _bilgiController.dispose();
    _ilController.dispose();
    _ilceController.dispose();
    _mahallesiController.dispose();
    _mekanTuruController.dispose();
    _noController.dispose();
    _sokakController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool optional = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty)) {
            return 'Bu alan zorunlu';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade200],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Mekanı Düzenle',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            controller: _mekanAdiController,
                            label: 'Mekan Adı',
                          ),
                          _buildInputField(
                            controller: _bilgiController,
                            label: 'Bilgi/Açıklama',
                            maxLines: 3,
                          ),
                          _buildInputField(
                            controller: _ilController,
                            label: 'İl',
                          ),
                          _buildInputField(
                            controller: _ilceController,
                            label: 'İlçe',
                          ),
                          _buildInputField(
                            controller: _mahallesiController,
                            label: 'Mahallesi',
                            optional: true,
                          ),
                          _buildInputField(
                            controller: _mekanTuruController,
                            label: 'Mekan Türü',
                          ),
                          _buildInputField(
                            controller: _sokakController,
                            label: 'Sokak',
                            optional: true,
                          ),
                          _buildInputField(
                            controller: _noController,
                            label: 'Kapı Numarası',
                            optional: true,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_camera, size: 20),
                            label: const Text('Fotoğraf Seç'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_imageFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imageFile!,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (_existingFotoUrl != null &&
                              _existingFotoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingFotoUrl!,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: _updateMekan,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.black45,
                                surfaceTintColor: Colors.transparent,
                              ).copyWith(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        MaterialState.pressed,
                                      )) {
                                        return Colors.teal[800];
                                      }
                                      return Colors.teal;
                                    }),
                              ),
                              child: const Text(
                                'Güncelle',
                                style: TextStyle(
                                  fontSize: 18,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
