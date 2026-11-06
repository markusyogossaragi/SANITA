# SANITA (Sanitasi dan Lingkungan Kerja)

Aplikasi pemantauan sanitasi tempat kerja dan kampus dengan standar keamanan tinggi (**Maximum Anti-Breach & Zero-Trust Architecture**).

**Identitas Proyek Akademik:**
- **Nama Mahasiswa:** Ribka Lusiana Harahap
- **NIM:** 243301631022
- **Dosen Pengampu:** Riky Suherman Simanjuntak, S.K.M., M.K.M.
- **Mata Kuliah:** Sanitasi dan Lingkungan Kerja
---

## Ringkasan Fitur
1. **Beranda (Home - Halaman 2):**
   - Header hijau khas SANITA: *"Halo, Sahabat SANITA! Yuk, jaga tempat kerja tetap bersih, sehat, dan aman."*
   - **Menu Utama:** 4 card akses cepat (Cek Sanitasi, Lapor Lingkungan, Edukasi Kesling, Monitoring).
   - **Ringkasan Aktivitas:** Counter laporan aktif (*X laporan*), petunjuk memulai, dan tombol *Lihat Riwayat Laporan*.
   - **Navigasi Bawah (Bottom Navigation Bar):** 5 menu tetap: Beranda, Cek, Lapor, Riwayat, dan Profil.

2. **Cek Sanitasi (Halaman 3):**
   - Kolom isian *Lokasi pemeriksaan* (default: `kampus unpri`).
   - 6 checklist butir kondisi sanitasi:
     1. Air bersih tersedia dan layak digunakan
     2. Toilet bersih dan berfungsi
     3. Tempat sampah tersedia dan tertutup
     4. Ventilasi udara memadai
     5. Tidak ada genangan air atau sampah berserakan
     6. Area kerja terjaga kebersihannya
   - **Penanda Progres:** Teks dan progress bar interaktif (*X dari 6 kondisi terpenuhi*).
   - **Lihat Hasil Pemeriksaan:** Evaluasi dinamis yang memunculkan rekomendasi tindakan dan poin perbaikan.
   - **Catatan Simulasi:** *"Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi."*

3. **Lapor Lingkungan (Halaman 4):**
   - Dropdown *Jenis permasalahan* terklasifikasi.
   - Kolom isian *Lokasi kejadian* (contoh: `area pantry`).
   - Kolom teks bebas *Keterangan* untuk konteks detail masalah.
   - Upload *Foto (opsional)* dengan validasi magic-byte dan batas ukuran 5 MB.
   - Tombol *Kirim Laporan* yang menyertakan tanda tangan digital HMAC-SHA256 untuk mendeteksi manipulasi data.

4. **Riwayat Laporan (Halaman 5):**
   - Menampilkan daftar laporan yang pernah dikirim beserta status (*Terkirim*, *Diproses*, *Selesai*), lokasi, waktu, dan foto.
   - Menampilkan status *"Belum ada laporan."* bila data masih kosong.
   - Badge verifikasi integritas data (*HMAC SHA-256 Verified*).

5. **Profil Pengguna (Halaman 5):**
   - Identitas pengguna default: *Sahabat SANITA (Pengguna demo)*.
   - Keterangan prototipe kesehatan.
   - Identitas akademik lengkap mahasiswa dan dosen pengampu.
   - Panel audit dan status pertahanan keamanan.

6. **Edukasi Kesling & Monitoring (Halaman 6):**
   - 6 modul kurikulum kesehatan lingkungan kerja (Air Bersih, Sanitasi Toilet, 3R Sampah, Kualitas Udara, Pengendalian Vektor, Ergonomi 5R).
   - Dashboard monitoring status, persentase kepatuhan checklist, dan metrik operasional.

---

## Struktur Repositori Clean-Layered Architecture
```
SANITA/
├── sanita_mobile/               # Full Flutter Application
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── android/                 # Android Native Platform Layer
│   ├── ios/                     # iOS Native Platform Layer
│   ├── web/                     # Web Platform Layer
│   ├── lib/
│   │   ├── main.dart            # Root App Entry & 5-Tab Navigation Shell
│   │   ├── core/
│   │   │   ├── constants/       # ApiConstants
│   │   │   ├── datasources/     # ApiDataSource (Bearer token, network handling)
│   │   │   ├── errors/          # Failures (NetworkFailure, ServerFailure, SecurityFailure)
│   │   │   ├── models/          # UserModel, ChecklistModel, LaporanModel, EdukasiModel, MonitoringStatsModel
│   │   │   ├── repositories/    # AuthRepository, SanitasiRepository, LaporanRepository, EdukasiRepository, MonitoringRepository
│   │   │   ├── services/        # SessionService (SharedPreferences), SecurityService (HMAC-SHA256, Checksums)
│   │   │   ├── theme/           # SanitaTheme, SanitaColors (Emerald Green Palette #1b6e4e)
│   │   │   ├── utils/           # DateFormatter, InputSanitizer (Anti-XSS)
│   │   │   └── widgets/         # SanitaAppHeader, SanitaNavBar (5-tab navigation)
│   │   └── feature/
│   │       ├── splash/          # SplashView with animated transitions
│   │       ├── auth/            # LoginView, RegisterView
│   │       ├── beranda/         # BerandaView
│   │       ├── cek_sanitasi/    # CekSanitasiView
│   │       ├── lapor_lingkungan/# LaporLingkunganView
│   │       ├── riwayat_laporan/ # RiwayatLaporanView
│   │       ├── profil/          # ProfilView
│   │       ├── edukasi_kesling/ # EdukasiView
│   │       ├── monitoring/      # MonitoringView
│   │       └── security/        # SecurityAuditView (Anti-Breach Diagnostic Matrix)
│   ├── test/                    # Flutter Test Suite
│   │   ├── widget_test.dart
│   │   ├── sanitasi_logic_test.dart
│   │   └── security_crypto_test.dart
│   └── test_runner.js           # Automated Clean-Architecture & Logic Suite
│
├── sanita-backend/              # Backend Go Clean Architecture
│   ├── cmd/sanita-service/main.go
│   ├── config/ (db.go, env.go)
│   ├── controller/ (auth, sanitasi, lapor, edukasi, monitoring, security)
│   ├── database/migrations/ (PostgreSQL SQL migrations)
│   ├── dto/ (auth_dto, sanitasi_dto, lapor_dto)
│   ├── middleware/ (security, rate_limit, jwt_middleware, anti_idor, audit_logger)
│   ├── models/ (user, checklist, laporan, edukasi, audit_log)
│   ├── repository/ (user, checklist, laporan, edukasi, audit)
│   ├── routes/sanita_routes.go
│   ├── service/ (auth, sanitasi, lapor, edukasi, monitoring)
│   └── utils/ (crypto, jwt, validator, file_shield, response)
│
├── build.bat                    # Skrip Verifikasi & Build Otomatis
└── README.md
```