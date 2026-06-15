import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MekanEklePage extends StatefulWidget {
  const MekanEklePage({Key? key}) : super(key: key);

  @override
  _MekanEklePageState createState() => _MekanEklePageState();
}

class _MekanEklePageState extends State<MekanEklePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;

  String? mekanAdi,
      bilgi,
      il,
      ilce,
      mahalle,
      sokak,
      no,
      selectedMekanTuru,
      menuLink;

  final List<String> iller = ['İstanbul'];
  final List<String> ilceler = ['Beykoz'];
  final List<String> mahalleler = [
    "Anadolu Hisarı",
    "Baklacı",
    "Bozhane",
    "Cumhuriyet",
    "Çamlıbahçe",
    "Çengeldere",
    "Çiftlik",
    "Çubuklu",
    "Dereseki",
    "Elmalı",
    "Ferah",
    "Göllü",
    "Gümüşsuyu",
    "Görele",
    "İncirköy",
    "İshaklı",
    "Kanlıca",
    "Kavacık",
    "Mahmutşevketpaşa",
    "Merkez",
    "Ortaçeşme",
    "Paşabahçe",
    "Polonezköy",
    "Poyrazköy",
    "Riva",
    "Soğuksu",
    "Tokatköy",
    "Yalıköy",
    "Yavuz Selim",
    "Yenimahalle",
    "Zerzevatçı",
  ];

  final List<String> mekanTurleri = [
    'Belediye Tesisleri',
    'Orman ve Korular',
    'Mesire Alanları',
    'Milli Saraylar Müzeler',
    'Müzeler',
  ];

  final Map<String, IconData> mekanIkonlari = {
    'Belediye Tesisleri': Icons.account_balance,
    'Orman ve Korular': Icons.park,
    'Mesire Alanları': Icons.landscape,
    'Milli Saraylar Müzeler': Icons.museum,
    'Müzeler': Icons.library_books,
  };

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _mekanKaydet() async {
    if (!_formKey.currentState!.validate() ||
        selectedMekanTuru == null ||
        il == null ||
        ilce == null ||
        mahalle == null) {
      _showSnackBar('Lütfen tüm zorunlu alanları doldurun.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    try {
      String fotoUrl = '';
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'mekanlar/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await storageRef.putFile(_imageFile!);
        fotoUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('Mekanlar').add({
        'mekanAdi': mekanAdi,
        'mekanTuru': selectedMekanTuru,
        'bilgi': bilgi,
        'il': il,
        'ilce': ilce,
        'mahalle': mahalle,
        'sokak': sokak,
        'no': no,
        'menuLink': menuLink ?? '',
        'fotoUrl': fotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSuccessDialog();
    } catch (e) {
      _showSnackBar('Mekan eklenirken bir hata oluştu.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Başarılı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Mekan başarıyla eklendi!',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: Text('Tamam', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
    );
  }

  Widget _buildModernCard({required Widget child, EdgeInsets? padding}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required Function(String?) onSaved,
    bool optional = false,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty)) {
            return 'Bu alan zorunlu';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required dynamic value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 12),
              Text(
                'Fotoğraf',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _imageFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(
                _imageFile == null ? Icons.add_photo_alternate : Icons.edit,
              ),
              label: Text(
                _imageFile == null ? 'Fotoğraf Ekle' : 'Fotoğraf Değiştir',
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Mekan Ekle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Temel Bilgiler
              _buildModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Temel Bilgiler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      label: 'Mekan Adı',
                      onSaved: (val) => mekanAdi = val,
                      icon: Icons.place,
                    ),
                    _buildInputField(
                      label: 'Açıklama',
                      onSaved: (val) => bilgi = val,
                      icon: Icons.description,
                    ),
                    _buildDropdown(
                      hint: 'Mekan Türü Seçin',
                      value: selectedMekanTuru,
                      items: mekanTurleri,
                      onChanged:
                          (val) => setState(() => selectedMekanTuru = val),
                      validator:
                          (val) => val == null ? 'Mekan türü seçin' : null,
                      icon: mekanIkonlari[selectedMekanTuru] ?? Icons.category,
                    ),
                    _buildInputField(
                      label: 'Menü Linki (isteğe bağlı)',
                      onSaved: (val) => menuLink = val,
                      icon: Icons.link,
                      optional: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Konum Bilgileri
              _buildModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Konum Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildDropdown(
                      hint: 'İl seçin',
                      value: il,
                      items: iller,
                      onChanged: (val) => setState(() => il = val),
                      validator: (val) => val == null ? 'İl seçin' : null,
                      icon: Icons.map,
                    ),
                    _buildDropdown(
                      hint: 'İlçe seçin',
                      value: ilce,
                      items: ilceler,
                      onChanged: (val) => setState(() => ilce = val),
                      validator: (val) => val == null ? 'İlçe seçin' : null,
                      icon: Icons.location_city,
                    ),
                    _buildDropdown(
                      hint: 'Mahalle seçin',
                      value: mahalle,
                      items: mahalleler,
                      onChanged: (val) => setState(() => mahalle = val),
                      validator: (val) => val == null ? 'Mahalle seçin' : null,
                      icon: Icons.home_work,
                    ),
                    _buildInputField(
                      label: 'Sokak',
                      onSaved: (val) => sokak = val,
                      icon: Icons.route,
                    ),
                    _buildInputField(
                      label: 'Kapı No',
                      onSaved: (val) => no = val,
                      icon: Icons.door_front_door,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Fotoğraf Bölümü
              _buildImageSection(),

              SizedBox(height: 24),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _mekanKaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Mekan Kaydet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
