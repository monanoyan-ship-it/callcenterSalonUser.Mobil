# Production hazırlık — callcenter_salonuser_mobil

Salon staff (admin/owner/personnel) uygulamasını mağazaya çıkarmak için tamamlanması gereken konfigürasyon ve hesap aksiyonları.

## 1. Production API URL

`scripts/build.ps1` içinde `prod.ApiUrl` varsayılanı `https://api.corplynk.com`. Gerçek prod domaini güncelle.

```powershell
.\scripts\build.ps1 -Target appbundle -Env prod -ApiUrl "https://api.corplynk.com"
```

## 2. App icon ve splash

```yaml
# pubspec.yaml dev_dependencies
flutter_launcher_icons: ^0.14.0
flutter_native_splash: ^2.4.0
```

`assets/icon/icon.png` (1024×1024) ekle, sonra:

```powershell
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## 3. Android signing

```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties`:
```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

`android/app/build.gradle` `signingConfigs` bloğu eklenmeli:
<https://docs.flutter.dev/deployment/android#signing-the-app>

## 4. iOS signing + Info.plist

- Apple Developer hesabı (yıllık $99)
- Xcode → Runner → Signing & Capabilities → Team seç
- `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

## 5. Mağaza listing

### Google Play
- Geliştirici hesabı (\$25 tek seferlik)
- Privacy policy URL (KVKK + Google'ın istediği)
- Screenshot (telefon: en az 2)
- Feature graphic 1024×500
- Açıklama (kısa 80 + uzun 4000)

### App Store
- App Store Connect kayıt
- Privacy policy URL + Privacy nutrition label
- Screenshot her cihaz boyutu için
- App icon 1024×1024

## 6. Push notifications (Phase 7.2)

Backend'de salon-staff için push token API'si **henüz yok**. Eklenince bu uygulamaya:

```yaml
dependencies:
  firebase_core: ^3.x
  firebase_messaging: ^15.x
```

Adımlar:
1. Firebase projesi oluştur (`corplynk-salon-staff`)
2. Android: package `com.corplynk.salonuser.callcenter_salonuser_mobil` için google-services.json
3. iOS: bundle ID için GoogleService-Info.plist
4. APNs auth key Apple Developer'dan al
5. `main.dart`'ta `Firebase.initializeApp()` + `FirebaseMessaging.instance.getToken()` → backend'e POST

## 7. Sentry crash reporting (opsiyonel)

`scripts/build.ps1 -SentryDsn https://...` ile DSN geçirilince main.dart'ta init edilebilir (henüz scaffold yok; ihtiyaç olursa eklenir).
