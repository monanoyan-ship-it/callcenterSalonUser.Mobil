# callcenterSalonUser.Mobil — AI ekibi için yönergeler

Bu dosya hem Claude (Anthropic) hem ChatGPT/Codex (OpenAI) ekibinin okuduğu **paylaşılan** referans.

## Kapsam (DEĞİŞMEZ)

Bu Flutter uygulaması **SALON KULLANICILARI** için: salon **owner / admin / personnel / staff**. Müşteri tarafı **AYRI uygulamada** yaşar (`callcenterSalon.Mobil`, project id 126) — bu repo'ya **müşteri ekranı/feature EKLEMEYIN**.

Yeni özellik isteğinde önce sor: "Bu *salon staff* için mi *müşteri* için mi?" Müşteri ise kapsam dışı, ayrı projeye gönder.

## Referans proje

`C:\Users\Ahmet\source\repos\monanoyan-ship-it\callcenter\src\CallCenter.Salon` (Razor MVC + KnockoutJS + Bootstrap admin panel). Mobil tarafı bu web panelin **müşteri/uçtan-uça** mobil eşi olacak.

Web salon panelindeki ana modüller (mobil tarafa zamanla aktarılacak):

| Web modül | Route | Mobil karşılığı |
|---|---|---|
| Login | `/Account/Login` | Login + email verify + forgot/reset (zaten backend hazır, commits 0f90d5a + AUTH-1..10) |
| Dashboard | `/Home` | Bugünün randevuları, basit metrikler |
| Appointments | `/Appointments` | Takvim + liste + edit + onay (status workflow 1→2→3→4) |
| Clients | `/Clients` | Müşteri listesi, detay, geçmiş randevular |
| Personnel | `/Personnel` | Personel CRUD + çalışma saatleri |
| Services | `/Services` | Hizmet kategorileri + fiyat + süre |
| Memberships | `/Memberships` | Üyelik plan tasarımı |
| Reviews | `/Reviews` | Yorum moderasyonu (approve/reject) |
| Reports | `/Reports` | Aylık ciro, hizmet dağılımı, sadakat |
| Settings | `/Settings` | Salon profili, görsel, sosyal, sayfa görünürlük flag'leri |
| PaymentInfo | `/PaymentInfo` | iyzico Pazaryeri sub-merchant onboarding (IBAN/TCKN/VKN) — sadece Owner |
| Translations | `/Translations` | i18n key yönetimi (servera çevirdiği gibi) |
| CallCenter | `/CallCenter` | PBX entegrasyonu (advanced, sonraki sürüm) |

## Auth

- Endpoint: `POST /api/auth/login` (NOT `/api/platform/login`)
- Response: JWT + claim'lerde `Role` (CustomerUser veya alt roller — SalonOwner/SalonAdmin/Personnel)
- Roller: `SalonRolePermissions` matrisi (web tarafında `CallCenter.Salon\Infrastructure\SalonRolePermissions.cs`); aynı matrisi mobile aksiyonları gizleme/gösterme için kullan.
- Forgot password / verify-email: `/api/auth/forgot-password`, `/api/auth/reset-password`, `/api/auth/send-verification-email`, `/api/auth/verify-email` (User tablosu için, commit d979b29).

## Mimari konvansiyon (callcenterSalon.Mobil ile paralel)

- `dio` HTTP client + interceptor
- `provider` state management
- `flutter_secure_storage` token kalıcılığı
- `intl` Türkçe locale (DatePicker dahil)
- `flutter_localizations` (`Locale('tr','TR')` + Material/Cupertino/Widgets delegate'leri)
- Tema: light + dark, `ThemeMode.system`
- ResponsiveCenter: Row+Spacer+SizedBox pattern (Center+ConstrainedBox antipattern'ine **dikkat** — ListView'da 0 yükseklik bug yaşanmıştı, callcenterSalon.Mobil pattern dosyasına bak)
- API base: `--dart-define=API_BASE_URL=http://localhost:5041` (HTTPS 7147 değil — bkz. callcenter pattern #518)

## ClaudeManager — proje takibi

Bu projenin ClaudeManager **project_id = 127**. Tüm planlar manager'dan takip edilir.

API base: `http://127.0.0.1:41847`

```bash
# Faz + task özeti
curl -s http://127.0.0.1:41847/api/projects/127/roadmap/summary

# Yeni faz
curl -X POST http://127.0.0.1:41847/api/projects/127/phases -H "Content-Type: application/json" \
  -d '{"phase_no":"X","title":"...","description":"..."}'

# Faza task ekle (PHASE_ID önce alınır)
curl -X POST http://127.0.0.1:41847/api/phases/PHASE_ID/tasks -H "Content-Type: application/json" \
  -d '{"task_no":"X.Y","title":"...","detail":"..."}'

# Karar günlüğü
curl -X POST http://127.0.0.1:41847/api/projects/127/journal -H "Content-Type: application/json" \
  -d '{"title":"...","content":"...","category":"karar"}'
```

Backend (callcenter) için **project_id = 15**, müşteri mobil **126**.

## Build ve çalıştırma

Flutter SDK: `C:\Users\Ahmet\flutter_sdk_stable\bin\flutter.bat` (PATH'te değil, doğrudan çağır).

```powershell
.\scripts\dev.ps1 -Mode web -ApiUrl http://localhost:5041
.\scripts\dev.ps1 -Mode android -ApiUrl http://10.0.2.2:5041
```

(Müşteri mobilden uyarlanan dev.ps1 + build.ps1 ileride buraya gelecek.)

## Kuralları

- **Memory'ye not düşme** — Claude'a özel kalır, ChatGPT okumaz. Kural/tercih → bu CLAUDE.md veya ClaudeManager journal/pattern.
- Build'de Windows symlink desteği için **Developer Mode ON** gerekir (callcenterSalon.Mobil deneyiminden).
- `salon.xml` dosyası **YOK** — salon çevirileri `callcenter/src/CallCenter.Salon/wwwroot/translations-salon.xml`.
- Her yeni model/endpoint için backend tarafında karşılığını mutlaka doğrula (yoksa ekleme talebi pattern olarak yaz).
