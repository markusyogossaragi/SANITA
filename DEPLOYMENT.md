# Panduan Build & Deployment SANITA (Sanitasi dan Lingkungan Kerja)

Dokumentasi resmi persiapan build dan deployment cloud server untuk ekosistem **SANITA** (*Sanitasi dan Lingkungan Kerja*).

---

### Identitas Proyek Akademik
- **Nama Mahasiswa:** Ribka Lusiana Harahap
- **NIM:** 243301631022
- **Dosen Pengampu:** Riky Suherman Simanjuntak, S.K.M., M.K.M.
- **Mata Kuliah:** Sanitasi dan Lingkungan Kerja
- **Institusi:** Universitas Prima Indonesia (UNPRI)

---

## 1. Arsitektur Komponen

```
                  ┌────────────────────────────────────────┐
                  │          SANITA Mobile Client          │
                  │   (Flutter Android APK / iOS / Web)    │
                  └──────────────────┬─────────────────────┘
                                     │ HTTPS / REST API
                                     ▼
                  ┌────────────────────────────────────────┐
                  │       SANITA Backend (Go Gin API)      │
                  │   Multi-Stage Hardened Alpine Docker   │
                  │          Port: 8080 (dynamic)          │
                  └──────────────────┬─────────────────────┘
                                     │
                  ┌──────────────────┴─────────────────────┐
                  ▼                                        ▼
    ┌───────────────────────────┐            ┌───────────────────────────┐
    │   PostgreSQL Database     │    ATAU    │   In-Memory Secured Cache │
    │ (Railway / Supabase/Neon) │            │  (Otomatis bila DB nihil) │
    └───────────────────────────┘            └───────────────────────────┘
```

---

## 2. Opsi A: Deployment ke Railway (Sangat Direkomendasikan)

Railway menyediakan hosting cloud modern dengan dukungan container Docker native dan sertifikat SSL/HTTPS gratis.

### Konfigurasi Otomatis yang Telah Disediakan
- File konfigurasi [`railway.json`](file:///d:/tes code/SANITA/railway.json) di root repositori.
- File konfigurasi [`sanita-backend/railway.json`](file:///d:/tes code/SANITA/sanita-backend/railway.json) di folder backend.
- Dockerfile multi-stage hardened di [`sanita-backend/Dockerfile`](file:///d:/tes code/SANITA/sanita-backend/Dockerfile).

### Langkah-Langkah Deploy via Dashboard Railway:
1. Buka [railway.app](https://railway.app/) dan login dengan akun GitHub kamu.
2. Klik **"New Project"** -> Pilih **"Deploy from GitHub repo"**.
3. Pilih repository **SANITA**.
4. Di bagian pengaturan service (Settings):
   - **Root Directory:** Atur ke `/sanita-backend` (atau biarkan default `/` karena root sudah memiliki `railway.json`).
   - Railway otomatis mendeteksi Dockerfile dan meng-compile binary Go.
5. *(Opsional)* Tambahkan Database PostgreSQL:
   - Klik **"+ New"** -> Pilih **"Database"** -> Pilih **"Add PostgreSQL"**.
   - Railway akan otomatis mengaitkan variabel `DATABASE_URL` ke backend SANITA.
   - *Catatan:* Jika tidak menambahkan PostgreSQL, backend tetap berjalan lancar menggunakan mode aman in-memory.
6. Generate Domain Publik:
   - Masuk ke service backend -> tab **Networking** -> klik **"Generate Domain"**.
   - Kamu akan mendapatkan URL publik, contoh: `https://sanita-backend-production.up.railway.app`.
7. Uji endpoint:
   - Cek `https://<domain-kamu>.up.railway.app/health` -> mengembalikan `{"status":"healthy"}`.
   - Cek `https://<domain-kamu>.up.railway.app/` -> mengembalikan informasi author & metadata aplikasi.

---

## 3. Opsi B: Deployment ke Render.com (Tier Gratis)

Render.com menyediakan Web Service gratis dengan auto-deploy langsung dari GitHub.

### Konfigurasi yang Telah Disediakan
- Blueprint file [`render.yaml`](file:///d:/tes code/SANITA/render.yaml) sudah tersedia di root.

### Langkah-Langkah:
1. Buka [render.com](https://render.com/) dan login.
2. Klik **"New +"** -> Pilih **"Web Service"**.
3. Hubungkan repositori GitHub **SANITA**.
4. Konfigurasi:
   - **Name:** `sanita-backend`
   - **Language / Runtime:** `Docker`
   - **Docker Context:** `./sanita-backend`
   - **Dockerfile Path:** `./sanita-backend/Dockerfile`
   - **Region:** `Singapore` (terdekat dengan Indonesia)
   - **Instance Type:** `Free`
5. Environment Variables:
   - `GIN_MODE` = `release`
   - `PORT` = `8080`
   - `TZ` = `Asia/Jakarta`
   - `JWT_SECRET` = `(generate string acak)`
6. Klik **"Create Web Service"**.
7. Render akan melakukan build dan memberikan URL aktif (misal: `https://sanita-backend.onrender.com`).

---

## 4. Opsi C: Deployment ke Fly.io / Koyeb (Alternatif Bebas Biaya)

### Fly.io:
File [`sanita-backend/fly.toml`](file:///d:/tes code/SANITA/sanita-backend/fly.toml) sudah disiapkan:
```bash
cd sanita-backend
fly launch --no-deploy
fly deploy
```

### Koyeb:
1. Buka [koyeb.com](https://koyeb.com/).
2. Buat App baru -> Pilih **GitHub**.
3. Atur builder ke **Dockerfile** dengan context `/sanita-backend`.
4. Pilih tier **Nano (Free)**.

---

## 5. Menghubungkan Flutter Mobile (`sanita_mobile`) ke Backend Cloud

Setelah backend aktif di cloud (misalnya di URL Railway `https://sanita-backend.up.railway.app`), hubungkan aplikasi Flutter kamu.

### Cara 1: Mengatur URL saat Build APK (Compile-Time Definition)
Jalankan perintah ini di terminal:
```powershell
cd sanita_mobile
flutter build apk --release --dart-define=SANITA_API_URL=https://sanita-backend.up.railway.app/api/v1 --android-skip-build-dependency-validation
```

File APK release yang siap di-install ke HP Android kamu akan berada di:
`sanita_mobile/build/app/outputs/flutter-apk/app-release.apk`

### Cara 2: Mengubah Langsung di File Kode
Buka [`sanita_mobile/lib/core/constants/apiConstants.dart`](file:///d:/tes code/SANITA/sanita_mobile/lib/core/constants/apiConstants.dart):
```dart
class ApiConstants {
  static const String _envBaseUrl = String.fromEnvironment(
    'SANITA_API_URL',
    defaultValue: 'https://sanita-backend.up.railway.app/api/v1', // <-- Masukkan URL Railway kamu di sini
  );
...
```

---

## 6. Pengujian & Verifikasi Lokal Sebelum Deploy

Jalankan skrip build otomatis yang sudah menguji seluruh 29 test suite dan kompilasi backend:

**Di Windows:**
```powershell
.\build.bat
```

**Di Linux / macOS:**
```bash
./build.sh
```

**Hasil Pengujian:**
- Kompilasi Go Backend: **100% SUKSES (Clean Build)**
- Mobile Architecture & Test Suite: **29 / 29 PASSED (100%)**
- HMAC-SHA256 & Cryptographic Tamper Shield: **VERIFIED**