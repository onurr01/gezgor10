# GezGör - Mekan Keşif ve İnceleme Uygulaması

## 📱 Uygulama Hakkında

**GezGör** (Go and See), İstanbul ve çevresindeki mekanları keşfetmek, incelemek ve paylaşmak için tasarlanmış bir mobil uygulamadır. Kullanıcılar mekanlar hakkında bilgi alabilir, yorum ve fotoğraf paylaşabilir, favori mekanlarını kaydedebilir ve harita üzerinden mekanları görüntüleyebilir.

## 🎯 Temel Özellikler

### 1. **Kimlik Doğrulama (Authentication)**
- Firebase Authentication ile güvenli giriş ve kayıt
- E-posta ve şifre ile kullanıcı kaydı
- Otomatik rol (user/admin) ataması
- Kullanıcı profil yönetimi

### 2. **Mekan Keşfi**
- Veritabanında kaydedilmiş mekanları görüntüleme
- Mekan adı, açıklama ve kategori bilgileri
- Mekanın konumu ve iletişim bilgileri
- Yıldız derecelendirme sistemi
- Ortalama puanları hesaplama

### 3. **Mekan Detay Sayfası**
- Mekan hakkında detaylı bilgiler
- Mekan resmi ve galeri gösterimi
- Google Haritalar entegrasyonu ile konum gösterimi
- WebView ile resmi website bağlantısı
- Kullanıcı yorumları ve fotoğrafları
- Kalıcı yer işareti (Favorite) özelliği

### 4. **Yorum ve Değerlendirme Sistemi**
- 1-5 yıldız derecelendirme
- Metin tabanlı yorum yazma
- Yorum fotoğrafları yükleme
- Kendi yorumlarını silme
- Firestore'da yorum geçmişi

### 5. **Favori Yönetimi**
- Mekanları favorilere ekleme/çıkarma
- Favori mekanları ayrı sayfada görüntüleme
- Firebase Firestore'da kalıcı olarak kaydedilme

### 6. **Admin Paneli**
- Yeni mekan ekleme
- Mekan bilgilerini düzenleme
- Mekan kategorisi seçimi (Kafe, Restoran, vb.)
- Google Maps entegrasyonu ile konum belirleme

### 7. **Konum Yönetimi**
- İstanbul ve Beykoz ilçesi odaklı mekan ekleme
- Mahalle ve sokak seviyesinde detaylı adres bilgisi
- Harita üzerinden mekan konumu gösterimi

### 8. **Kullanıcı Profili**
- Kullanıcı bilgileri ve istatistikleri
- Favoriler listesi
- Yapmış olduğu yorumlar
- Oturum kapatma (Logout)

## 📋 Ekranlar ve Navigasyon

| Ekran | Açıklama |
|-------|----------|
| **Giriş Ekranı** | Firebase Authentication ile kullanıcı girişi |
| **Kayıt Ekranı** | Yeni kullanıcı hesabı oluşturma |
| **Ana Sayfa** | Mekan listesi ve keşif alanı |
| **Mekan Detay** | Seçili mekan hakkında detaylı bilgiler |
| **Favori Sayfası** | Kaydedilmiş favori mekanlar |
| **Kullanıcı Profili** | Kullanıcı bilgileri ve hesap yönetimi |
| **Admin Profili** | Yönetici paneli - mekan ekleme/düzenleme |
| **Mekan Ekleme** | Yeni mekan kaydı oluşturma |

## 🛠️ Teknik Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget
- **UI Components**: Material Design, Cupertino Icons

### Backend & Database
- **Firebase Authentication**: Kullanıcı kimlik doğrulaması
- **Cloud Firestore**: Gerçek zamanlı veritabanı
- **Firebase Storage**: Resim ve dosya depolama

### Harici Kütüphaneler

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  image_picker: ^1.1.2              # Fotoğraf seçme
  firebase_core: ^2.27.0            # Firebase temel
  firebase_auth: ^4.17.8            # Firebase kimlik doğrulama
  cloud_firestore: ^4.17.5          # Firebase veritabanı
  firebase_storage: ^11.0.16        # Firebase depolama
  url_launcher: ^6.3.1              # Web linklerini açma
  webview_flutter: ^4.11.0          # Web sayfaları gösterme
  google_fonts: ^6.2.1              # Google Fonts
  cached_network_image: ^3.3.1      # Resim önbellekleme
  flutter_rating_bar: ^4.0.1        # Yıldız derecelendirme
  flutter_svg: ^2.1.0               # SVG resim desteği
  google_maps_flutter: ^2.5.3       # Google Haritalar
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                      # Ana giriş ve routing
├── girisyap_screen.dart          # Giriş ekranı (LoginScreen)
├── kayitol_screen.dart           # Kayıt ekranı (KayitSayfasi)
├── anasayfa_screen.dart          # Ana sayfa (SecimEkrani)
├── mekan_liste_page.dart         # Mekan listesi
├── mekan_detay_screen.dart       # Mekan detayları
├── favoriler_screen.dart         # Favori mekanlar
├── kullaniciprofil_screen.dart   # Kullanıcı profili
├── adminprofil_screen.dart       # Admin paneli
├── mekanekle_screen.dart         # Mekan ekleme
└── firebase_options.dart         # Firebase konfigürasyonu

assets/
└── images/                        # Uygulama resimleri

android/                          # Android platformu ayarları
ios/                             # iOS platformu ayarları
web/                             # Web platformu ayarları
```

## 🚀 Başlangıç

### Gereksinimler
- Flutter SDK (^3.7.2)
- Dart SDK
- Android Studio veya XCode
- Firebase hesabı
- Google Cloud Console API anahtarları

### Kurulum Adımları

1. **Repository'yi klonlayın:**
   ```bash
   git clone <repository-url>
   cd gezgor10
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Firebase'i yapılandırın:**
   - `google-services.json` dosyasını Android klasörüne koyun
   - `GoogleService-Info.plist` dosyasını iOS klasörüne koyun
   - Firebase konsolundan gerekli API anahtarlarını alın

4. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

## 📊 Firestore Veritabanı Yapısı

### Koleksiyonlar (Collections)

**Uye (Users)**
```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "role": "user|admin",
  "createdAt": "timestamp"
}
```

**Mekanlar (Locations)**
```json
{
  "mekanId": "id",
  "ad": "Mekan Adı",
  "bilgi": "Açıklama",
  "kategori": "Kafe|Restoran|...",
  "il": "İstanbul",
  "ilce": "Beykoz",
  "mahalle": "Mahalle Adı",
  "sokak": "Sokak Adı",
  "no": "123",
  "enlem": 41.1234,
  "boylam": 29.5678,
  "menuLink": "https://...",
  "resim": "gs://...",
  "ortalamaPuan": 4.5,
  "toplamYorum": 10
}
```

**Yorumlar (Reviews)**
```json
{
  "yorumId": "id",
  "mekanId": "mekan_id",
  "userId": "user_id",
  "puan": 4.5,
  "metin": "Yorum metni",
  "tarih": "timestamp"
}
```

**Fotoğraflar (Photos)**
```json
{
  "fotoId": "id",
  "mekanId": "mekan_id",
  "userId": "user_id",
  "url": "gs://...",
  "tarih": "timestamp"
}
```

**Favori (Favorites)**
```json
{
  "userId": {
    "favoriMekanlar": ["mekan_id1", "mekan_id2"]
  }
}
```

## 🔒 Güvenlik

- Firebase Authentication ile güvenli giriş
- Firestore Security Rules ile veri erişim kontrolü
- Kullanıcı rollerine dayalı yetkilendirme
- Firebase Storage güvenli dosya depolama

## 🎨 Tasarım Özellikleri

- **Renk Şeması**: Turkuaz/Teal (#00838F, #006064)
- **Tipografi**: Google Fonts ile modern yazı tipi
- **Material Design**: Google Material Design ilkeleri
- **Responsive Layout**: Farklı ekran boyutlarına uyumlu
- **Gradient Backgrounds**: Estetik gradyan arka planlar

## 📱 Platform Desteği

- ✅ Android 5.0+ 
- ✅ iOS 12.0+
- ⚠️ Web (kısıtlı destek)
- ⚠️ macOS/Windows (geliştirme aşamasında)

## 🐛 Bilinen Sorunlar ve Sınırlamalar

- Şu anda sadece İstanbul/Beykoz ilçesine yönelik
- WebView bazı telefonlarda sorun yaşayabilir
- Harita API anahtarlarının doğru konfigürasyonu gerekli

## 🔄 Güncellemeler ve İyileştirmeler (TODO)

- [ ] Çoklu dil desteği (İngilizce, vb.)
- [ ] Sosyal medya entegrasyonu
- [ ] Push bildirimleri
- [ ] Offine mod desteği
- [ ] Geliştirilmiş arama filtreleri
- [ ] Mekan kategorisine göre filtreleme
- [ ] Kullanıcı takip sistemi
- [ ] Mekan önerileri (AI tabanlı)



## 📄 Lisans

Bu proje eğitim amaçlı yapılmıştır.


