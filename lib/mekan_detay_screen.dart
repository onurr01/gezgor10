import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MekanDetayScreen extends StatefulWidget {
  final String mekanId;

  const MekanDetayScreen({Key? key, required this.mekanId}) : super(key: key);

  @override
  State<MekanDetayScreen> createState() => _MekanDetayScreenState();
}

class _MekanDetayScreenState extends State<MekanDetayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _yorumController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  double _rating = 3.0;
  bool _isSubmittingReview = false;
  bool _isDeletingReview = false;
  bool _isSubmittingPhoto = false;
  bool _isDeletingPhoto = false;
  DocumentSnapshot? _mekanData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadMekanData();
    _checkIfFavorite();
  }

  Future<void> _loadMekanData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('Mekanlar')
              .doc(widget.mekanId)
              .get();
      if (doc.exists) {
        setState(() {
          _mekanData = doc;
        });
      }
    } catch (e) {
      debugPrint('Mekan verisi yüklenirken hata: $e');
    }
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isFavorite = false;
        _isCheckingFavorite = false;
      });
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('Uye')
              .doc(user.uid)
              .collection('favorites')
              .doc(widget.mekanId)
              .get();

      setState(() {
        _isFavorite = doc.exists;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      debugPrint('Favori kontrolü sırasında hata: $e');
      setState(() {
        _isFavorite = false;
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> mekanData) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Favori eklemek için giriş yapmalısınız', Colors.orange);
      return;
    }

    setState(() {
      _isCheckingFavorite = true;
    });

    try {
      final favRef = FirebaseFirestore.instance
          .collection('Uye')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.mekanId);

      if (_isFavorite) {
        await favRef.delete();
        _showSnackBar('Favorilerden kaldırıldı', Colors.redAccent);
      } else {
        await favRef.set({
          'mekanId': widget.mekanId,
          'mekanAdi': mekanData['mekanAdi'] ?? 'Ad yok',
          'fotoUrl': mekanData['fotoUrl'] ?? '',
          'il': mekanData['il'] ?? '',
          'ilce': mekanData['ilce'] ?? '',
          'mekanTuru': mekanData['kategori'] ?? 'Restoran',
          'eklemeTarihi': FieldValue.serverTimestamp(),
        });
        _showSnackBar('Favorilere eklendi', Colors.teal);
      }

      setState(() {
        _isFavorite = !_isFavorite;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      debugPrint('Favori işlemi sırasında hata: $e');
      _showSnackBar('İşlem sırasında bir hata oluştu', Colors.red);
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() {
        _showTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() {
        _showTitle = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _yorumController.dispose();
    super.dispose();
  }

  void _openGoogleMaps(String adres) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(adres)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Google Maps açılamadı: $url');
    }
  }

  void _openMenuBottomSheet(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Menü",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: WebViewWidget(
                      controller:
                          WebViewController()
                            ..loadRequest(
                              Uri.parse(
                                url.startsWith('http') ? url : 'https://$url',
                              ),
                            )
                            ..setJavaScriptMode(JavaScriptMode.unrestricted),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _submitReview() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Yorum yapmak için giriş yapmalısınız', Colors.orange);
      return;
    }

    if (_yorumController.text.trim().isEmpty) {
      _showSnackBar('Lütfen bir yorum yazınız', Colors.orange);
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Uye')
              .doc(user.uid)
              .get();
      if (!userDoc.exists) {
        _showSnackBar('Kullanıcı verisi bulunamadı', Colors.red);
        setState(() {
          _isSubmittingReview = false;
        });
        return;
      }

      final userData = userDoc.data() ?? {};
      final String ad = userData['ad']?.trim() ?? '';
      final String soyad = userData['soyad']?.trim() ?? '';
      final String kullaniciAdi = '$ad $soyad'.trim();
      if (kullaniciAdi.isEmpty) {
        _showSnackBar(
          'Ad ve soyad bilgisi eksik. Profil bilgilerinizi güncelleyin.',
          Colors.red,
        );
        setState(() {
          _isSubmittingReview = false;
        });
        return;
      }

      final String? profilFoto = userData['profilFoto'] ?? user.photoURL;

      final yorumData = {
        'kullaniciId': user.uid,
        'kullaniciAdi': kullaniciAdi,
        'profilFoto': profilFoto,
        'yorum': _yorumController.text.trim(),
        'puan': _rating,
        'tarih': FieldValue.serverTimestamp(),
        'mekanId': widget.mekanId,
      };

      final mekanYorumRef = await FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(widget.mekanId)
          .collection('yorumlar')
          .add(yorumData);

      await FirebaseFirestore.instance
          .collection('Uye')
          .doc(user.uid)
          .collection('yorumlar')
          .doc(mekanYorumRef.id)
          .set({...yorumData, 'mekanId': widget.mekanId});

      await _updateMekanRating();

      _yorumController.clear();
      _showSnackBar('Yorumunuz başarıyla eklendi', Colors.teal);

      setState(() {
        _isSubmittingReview = false;
      });
    } catch (e) {
      debugPrint('Yorum eklerken hata: $e');
      _showSnackBar('Yorum eklenirken bir hata oluştu: $e', Colors.red);
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  Future<void> _deleteReview(String yorumId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Giriş yapmalısınız', Colors.orange);
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Yorumu Sil'),
            content: const Text(
              'Bu yorumu silmek istediğinizden emin misiniz?',
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

    setState(() {
      _isDeletingReview = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(widget.mekanId)
          .collection('yorumlar')
          .doc(yorumId)
          .delete();

      await FirebaseFirestore.instance
          .collection('Uye')
          .doc(user.uid)
          .collection('yorumlar')
          .doc(yorumId)
          .delete();

      await _updateMekanRating();

      _showSnackBar('Yorum silindi', Colors.redAccent);
    } catch (e) {
      debugPrint('Yorum silerken hata: $e');
      _showSnackBar('Yorum silinirken hata oluştu', Colors.red);
    } finally {
      setState(() {
        _isDeletingReview = false;
      });
    }
  }

  Future<void> _updateMekanRating() async {
    try {
      final yorumlarSnapshot =
          await FirebaseFirestore.instance
              .collection('Mekanlar')
              .doc(widget.mekanId)
              .collection('yorumlar')
              .get();

      if (yorumlarSnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('Mekanlar')
            .doc(widget.mekanId)
            .update({'ortalamaPuan': 0.0, 'yorumSayisi': 0});
        return;
      }

      double toplamPuan = 0;
      int yorumSayisi = yorumlarSnapshot.docs.length;

      for (var doc in yorumlarSnapshot.docs) {
        toplamPuan += (doc.data()['puan'] ?? 0).toDouble();
      }

      double ortalamaPuan = toplamPuan / yorumSayisi;

      await FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(widget.mekanId)
          .update({'ortalamaPuan': ortalamaPuan, 'yorumSayisi': yorumSayisi});
    } catch (e) {
      debugPrint('Ortalama puan güncellenirken hata: $e');
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

  Future<void> _submitPhoto() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Fotoğraf yüklemek için giriş yapmalısınız', Colors.orange);
      return;
    }

    if (_imageFile == null) {
      _showSnackBar('Lütfen bir fotoğraf seçin', Colors.orange);
      return;
    }

    setState(() {
      _isSubmittingPhoto = true;
    });

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Uye')
              .doc(user.uid)
              .get();
      if (!userDoc.exists) {
        _showSnackBar('Kullanıcı verisi bulunamadı', Colors.red);
        setState(() {
          _isSubmittingPhoto = false;
        });
        return;
      }

      final userData = userDoc.data() ?? {};
      final String ad = userData['ad']?.trim() ?? '';
      final String soyad = userData['soyad']?.trim() ?? '';
      final String kullaniciAdi = '$ad $soyad'.trim();
      if (kullaniciAdi.isEmpty) {
        _showSnackBar(
          'Ad ve soyad bilgisi eksik. Profil bilgilerinizi güncelleyin.',
          Colors.red,
        );
        setState(() {
          _isSubmittingPhoto = false;
        });
        return;
      }

      final String? profilFoto = userData['profilFoto'] ?? user.photoURL;

      // Firebase Storage'a fotoğrafı yükle
      final storageRef = FirebaseStorage.instance.ref().child(
        'kullanici_fotograflari/${widget.mekanId}/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await storageRef.putFile(_imageFile!);
      final String fotoUrl = await storageRef.getDownloadURL();

      final fotoData = {
        'kullaniciId': user.uid,
        'kullaniciAdi': kullaniciAdi,
        'profilFoto': profilFoto,
        'fotoUrl': fotoUrl,
        'tarih': FieldValue.serverTimestamp(),
        'mekanId': widget.mekanId,
        'storagePath': storageRef.fullPath, // Silme işlemi için path'i sakla
      };

      final mekanFotoRef = await FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(widget.mekanId)
          .collection('kullanici_fotograflari')
          .add(fotoData);

      await FirebaseFirestore.instance
          .collection('Uye')
          .doc(user.uid)
          .collection('fotograflar')
          .doc(mekanFotoRef.id)
          .set({...fotoData, 'mekanId': widget.mekanId});

      _showSnackBar('Fotoğraf başarıyla yüklendi', Colors.teal);

      setState(() {
        _imageFile = null;
        _isSubmittingPhoto = false;
      });
    } catch (e) {
      debugPrint('Fotoğraf yüklerken hata: $e');
      _showSnackBar('Fotoğraf yüklenirken bir hata oluştu', Colors.red);
      setState(() {
        _isSubmittingPhoto = false;
      });
    }
  }

  Future<void> _deletePhoto(String fotoId, String storagePath) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Giriş yapmalısınız', Colors.orange);
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Fotoğrafı Sil'),
            content: const Text(
              'Bu fotoğrafı silmek istediğinizden emin misiniz?',
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

    setState(() {
      _isDeletingPhoto = true;
    });

    try {
      // Firebase Storage'dan fotoğrafı sil
      await FirebaseStorage.instance.ref(storagePath).delete();

      // Firestore'dan kaydı sil
      await FirebaseFirestore.instance
          .collection('Mekanlar')
          .doc(widget.mekanId)
          .collection('kullanici_fotograflari')
          .doc(fotoId)
          .delete();

      await FirebaseFirestore.instance
          .collection('Uye')
          .doc(user.uid)
          .collection('fotograflar')
          .doc(fotoId)
          .delete();

      _showSnackBar('Fotoğraf silindi', Colors.redAccent);
    } catch (e) {
      debugPrint('Fotoğraf silerken hata: $e');
      _showSnackBar('Fotoğraf silinirken hata oluştu', Colors.red);
    } finally {
      setState(() {
        _isDeletingPhoto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mekanData == null) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }

    final data = _mekanData!.data() as Map<String, dynamic>;
    final String fotoUrl = data['fotoUrl'] ?? '';
    final List<String> galleryImages =
        data['galleryImages'] != null
            ? List<String>.from(data['galleryImages'])
            : [fotoUrl];
    final String mekanAdi = data['mekanAdi'] ?? 'Ad yok';
    final String bilgi = data['bilgi'] ?? 'Bilgi yok';
    final String adres =
        '${data['mahalle'] ?? ''} ${data['sokak'] ?? ''} No:${data['no'] ?? ''}, ${data['ilce'] ?? ''} / ${data['il'] ?? ''}';
    final String? menuLink = data['menuLink'];
    // final String kategori = data['kategori'] ?? 'Restoran';
    final double ortalamaPuan = (data['ortalamaPuan'] ?? 0).toDouble();
    final int yorumSayisi = (data['yorumSayisi'] ?? 0);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.teal.shade700,
            title: AnimatedOpacity(
              opacity: _showTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                mekanAdi,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child:
                    _isCheckingFavorite
                        ? Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.teal.shade700,
                              ),
                            ),
                          ),
                        )
                        : CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 22,
                              color:
                                  _isFavorite
                                      ? Colors.redAccent
                                      : Colors.black87,
                            ),
                            onPressed: () => _toggleFavorite(data),
                          ),
                        ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: galleryImages[index],
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        /*child: Text(
                          kategori,
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),*/
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            ortalamaPuan.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' ($yorumSayisi)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mekanAdi,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.teal.shade700,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.teal.shade700,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: "Hakkında"),
                      Tab(text: "Menü"),
                      Tab(text: "Konum"),
                      Tab(text: "Yorumlar"),
                      Tab(text: "Fotoğraflar"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 280,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Hakkında Sekmesi
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Açıklama",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bilgi,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Menü Sekmesi
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child:
                          menuLink != null && menuLink.isNotEmpty
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Mekanın menüsünü görüntülemek için",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _openMenuBottomSheet(
                                          context,
                                          menuLink,
                                        ),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text("Menüyü Görüntüle"),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.teal.shade700,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Menü bilgisi bulunamadı",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  // Konum Sekmesi
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey[200],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.location_on,
                                    size: 48,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openGoogleMaps(adres),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: const Text("Haritada Aç"),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.teal.shade700,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Adres",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade700.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        adres,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _openGoogleMaps(adres),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Yol tarifi al",
                                              style: TextStyle(
                                                color: Colors.teal.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.directions,
                                              size: 16,
                                              color: Colors.teal.shade700,
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
                        ],
                      ),
                    ),
                  ),
                  // Yorumlar Sekmesi
                  // Yorumlar Sekmesi
                  SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Kaydırmayı etkinleştir
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Değerlendirmenizi Yazın",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: RatingBar.builder(
                                      initialRating: _rating,
                                      minRating: 1,
                                      direction: Axis.horizontal,
                                      allowHalfRating: true,
                                      itemCount: 5,
                                      itemPadding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      itemBuilder:
                                          (context, _) => const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                      onRatingUpdate: (rating) {
                                        setState(() {
                                          _rating = rating;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _yorumController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: "Deneyiminizi paylaşın...",
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSubmittingReview
                                              ? null
                                              : _submitReview,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.teal.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child:
                                          _isSubmittingReview
                                              ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : const Text(
                                                "Yorumu Gönder",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Değerlendirmeler",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (yorumSayisi > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${ortalamaPuan.toStringAsFixed(1)} ($yorumSayisi)",
                                        style: TextStyle(
                                          color: Colors.teal.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Mekanlar')
                                    .doc(widget.mekanId)
                                    .collection('yorumlar')
                                    .orderBy('tarih', descending: true)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                debugPrint(
                                  'Yorumlar yüklenirken hata: ${snapshot.error}',
                                );
                                return const Center(
                                  child: Text(
                                    'Yorumlar yüklenirken bir hata oluştu.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Henüz değerlendirme yapılmamış",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "İlk değerlendirmeyi siz yapın!",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true, // İçeriği sığdırmak için
                                physics:
                                    const NeverScrollableScrollPhysics(), // Ana kaydırma ile uyumlu çalışsın
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final doc = snapshot.data!.docs[index];
                                  final yorumData =
                                      doc.data() as Map<String, dynamic>;
                                  final String yorumId = doc.id;
                                  final String kullaniciId =
                                      yorumData['kullaniciId'] ?? '';
                                  final String kullaniciAdi =
                                      yorumData['kullaniciAdi'] ??
                                      'Bilgi Eksik';
                                  final String? profilFoto =
                                      yorumData['profilFoto'];
                                  final String yorum = yorumData['yorum'] ?? '';
                                  final double puan =
                                      (yorumData['puan'] ?? 0).toDouble();

                                  String tarih = 'Bilinmiyor';
                                  if (yorumData['tarih'] != null) {
                                    final timestamp =
                                        yorumData['tarih'] as Timestamp;
                                    final date = timestamp.toDate();
                                    tarih =
                                        '${date.day}.${date.month}.${date.year}';
                                  }

                                  final currentUser = _auth.currentUser;
                                  final bool isOwnReview =
                                      currentUser != null &&
                                      currentUser.uid == kullaniciId;

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage:
                                                  profilFoto != null &&
                                                          profilFoto.isNotEmpty
                                                      ? NetworkImage(profilFoto)
                                                      : null,
                                              child:
                                                  profilFoto == null ||
                                                          profilFoto.isEmpty
                                                      ? const Icon(
                                                        Icons.person,
                                                        color: Colors.grey,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    kullaniciAdi,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    tarih,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    puan.toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          yorum,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                          ),
                                        ),
                                        if (isOwnReview) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed:
                                                    _isDeletingReview
                                                        ? null
                                                        : () => _deleteReview(
                                                          yorumId,
                                                        ),
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                ),
                                                label: const Text('Sil'),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  elevation: 0,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Fotoğraflar Sekmesi
                  // Fotoğraflar Sekmesi
                  SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Kaydırmayı etkinleştir
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Fotoğraf Paylaş",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Fotoğraf Seç'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.teal.shade700,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  if (_imageFile != null) ...[
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageFile!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSubmittingPhoto
                                                ? null
                                                : _submitPhoto,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.teal.shade700,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child:
                                            _isSubmittingPhoto
                                                ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                                : const Text(
                                                  "Fotoğrafı Yükle",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Kullanıcı Fotoğrafları",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Mekanlar')
                                    .doc(widget.mekanId)
                                    .collection('kullanici_fotograflari')
                                    .orderBy('tarih', descending: true)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                debugPrint(
                                  'Fotoğraflar yüklenirken hata: ${snapshot.error}',
                                );
                                return const Center(
                                  child: Text(
                                    'Fotoğraflar yüklenirken bir hata oluştu.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Henüz fotoğraf paylaşılmamış",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "İlk fotoğrafı siz paylaşın!",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true, // İçeriği sığdırmak için
                                physics:
                                    const NeverScrollableScrollPhysics(), // Ana kaydırma ile uyumlu çalışsın
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final doc = snapshot.data!.docs[index];
                                  final fotoData =
                                      doc.data() as Map<String, dynamic>;
                                  final String fotoId = doc.id;
                                  final String kullaniciId =
                                      fotoData['kullaniciId'] ?? '';
                                  final String kullaniciAdi =
                                      fotoData['kullaniciAdi'] ?? 'Bilgi Eksik';
                                  final String? profilFoto =
                                      fotoData['profilFoto'];
                                  final String fotoUrl =
                                      fotoData['fotoUrl'] ?? '';
                                  final String storagePath =
                                      fotoData['storagePath'] ?? '';

                                  String tarih = 'Bilinmiyor';
                                  if (fotoData['tarih'] != null) {
                                    final timestamp =
                                        fotoData['tarih'] as Timestamp;
                                    final date = timestamp.toDate();
                                    tarih =
                                        '${date.day}.${date.month}.${date.year}';
                                  }

                                  final currentUser = _auth.currentUser;
                                  final bool isOwnPhoto =
                                      currentUser != null &&
                                      currentUser.uid == kullaniciId;

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage:
                                                  profilFoto != null &&
                                                          profilFoto.isNotEmpty
                                                      ? NetworkImage(profilFoto)
                                                      : null,
                                              child:
                                                  profilFoto == null ||
                                                          profilFoto.isEmpty
                                                      ? const Icon(
                                                        Icons.person,
                                                        color: Colors.grey,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    kullaniciAdi,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    tarih,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: fotoUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 200,
                                            placeholder:
                                                (context, url) => Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        if (isOwnPhoto) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed:
                                                    _isDeletingPhoto
                                                        ? null
                                                        : () => _deletePhoto(
                                                          fotoId,
                                                          storagePath,
                                                        ),
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                ),
                                                label: const Text('Sil'),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  elevation: 0,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
