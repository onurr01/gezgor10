import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kayitol_screen.dart';
import 'anasayfa_screen.dart';
import 'adminprofil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GezGör',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const KayitSayfasi(),
        '/mainScreen': (context) => const SecimEkrani(isAdmin: false),
        '/admin': (context) => const AdminProfilSayfasi(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _obscurePassword = true; // Şifre görünürlüğünü kontrol etmek için

  // Kullanıcı rolünü kontrol eden yardımcı fonksiyon
  Future<String> _getUserRole(String uid) async {
    try {
      final userDoc = await _firestore.collection('Uye').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['role'] ?? 'user'; // Varsayılan olarak 'user'
      } else {
        // Kullanıcı belgesi yoksa oluştur
        await _createUserDocument(uid);
        return 'user';
      }
    } catch (e) {
      debugPrint('Kullanıcı rolü alınırken hata: $e');
      return 'user'; // Hata durumunda varsayılan rol
    }
  }

  // Kullanıcı belgesi oluşturma (role ile)
  Future<void> _createUserDocument(String uid) async {
    final userDoc = _firestore.collection('Uye').doc(uid);
    await userDoc.set({
      'email': _emailController.text.trim(),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'role':
          'user', // Varsayılan olarak user, admin için manuel değiştirilecek
    }, SetOptions(merge: true));
    debugPrint('Uye/$uid belgesi oluşturuldu');
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showCenterDialog('Lütfen e-posta ve şifre girin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Authentication ile giriş yap
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _showCenterDialog('Kullanıcı bulunamadı.');
        setState(() => _isLoading = false);
        return;
      }

      // Kullanıcı rolünü kontrol et
      final role = await _getUserRole(user.uid);
      debugPrint('Kullanıcı rolü: $role');

      // Rolüne göre yönlendirme yap, ama her durumda SecimEkrani'na git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SecimEkrani(isAdmin: role == 'admin'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showCenterDialog('Giriş yapılamadı: ${e.message}');
    } catch (e) {
      _showCenterDialog('Bir hata oluştu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sifreSifirla() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showCenterDialog('Lütfen e-posta adresinizi girin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlama e-postası gönderildi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showCenterDialog('Hata: ${e.message}');
    } catch (e) {
      setState(() => _isLoading = false);
      _showCenterDialog('Beklenmeyen bir hata oluştu: $e');
    }
  }

  void _showCenterDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Uyarı', textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAFE2E8), Color(0xFF0E9AA7)],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Logonun arkasındaki beyaz alanı kaldır
                  Container(
                    width: 200,
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Hoş Geldiniz',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hesabınıza giriş yapın',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  _buildInputField(
                    controller: _emailController,
                    hint: 'E-posta',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  // Şifre alanı için görünürlük eklenmiş versiyon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      keyboardType: TextInputType.text,
                      obscureText: _obscurePassword, // Görünürlük kontrolü
                      decoration: InputDecoration(
                        hintText: 'Şifre',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _sifreSifirla,
                      child: const Text(
                        'Şifremi Unuttum?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'GİRİŞ YAP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Hesabınız yok mu?',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
