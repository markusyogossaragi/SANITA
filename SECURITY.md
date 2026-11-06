# SANITA Security & Maximum Anti-Breach Specification

**Aplikasi:** SANITA (Sanitasi dan Lingkungan Kerja)  
**Mahasiswa:** Ribka Lusiana Harahap  
**NIM:** 243301631022  
**Dosen Pengampu:** Riky Suherman Simanjuntak, S.K.M., M.K.M.  
**Standar Keamanan:** OWASP Top 10, Zero-Trust Architecture, Defense-in-Depth, ISO/IEC 27001 Data Protection Principles.

---

## 1. Arsitektur Pertahanan Berlapis (Defense-in-Depth)

Sistem SANITA dirancang dengan prinsip **Zero-Trust** di mana setiap komponen saling memvalidasi hak akses dan integritas data tanpa bergantung pada kepercayaan implisit:

```
[ User Device / Mobile ]
         │ (TLS 1.3 / Strict CSP / Anti-MIME / Frame-Options: DENY)
         ▼
[ Hardened Edge / Nginx Reverse Proxy ]
  ├── Anti-DDoS Rate Limiting (Token Bucket: 30r/s burst 50)
  ├── Strict Rate Limiter (/api/v1/auth & /api/v1/laporan: 5r/s burst 10)
  └── Connection Cap (Max 20 concurrent connections per IP)
         │
         ▼
[ SANITA Enterprise Application / Go & Node Runtime ]
  ├── Input Sanitizer & Anti-XSS Filter (HTML Entity Encoding)
  ├── Anti-IDOR Middleware (Object-Level Ownership Verification)
  ├── File Shield (Magic-byte detection: JPEG, PNG, WebP only)
  ├── Anti-Tamper Engine (HMAC-SHA256 Digital Signatures)
  ├── Field-Level Data Encryption (AES-256-GCM authenticated tag)
  └── Cryptographic Audit Trail (Linked Blockchain Hash Chain)
         │
         ▼
[ Isolated Storage / Database ]
  ├── Parameterized Queries (Anti-SQL Injection)
  └── Encrypted PII (Personal Identifiable Information at rest)
```

---

## 2. Matriks Pertahanan OWASP Top 10

| Risiko Keamanan | Mekanisme Pertahanan SANITA | Status Implementasi |
| :--- | :--- | :---: |
| **A01: Broken Access Control (IDOR)** | Middleware `AntiIDORGuard` & `RequireReportOwnership`. Verifikasi kepemilikan objek pada setiap pemanggilan ID laporan atau checklist. Mencegah user mengakses data user lain. | **ACTIVE** |
| **A02: Cryptographic Failures** | Data sensitif dienkripsi menggunakan algoritma **AES-256-GCM** dengan authenticated tag. Tanda tangan digital **HMAC-SHA256** untuk menjamin integritas laporan. | **ACTIVE** |
| **A03: Injection (SQLi / Command)** | 100% Parameterized queries & prepared statements. Input sanitization dengan stripping tag HTML dan sanitasi karakter escape. | **ACTIVE** |
| **A04: Insecure Design** | Zero-trust input validation, rate limiting per-IP untuk mitigasi credential stuffing dan DoS, validasi magic number file upload. | **ACTIVE** |
| **A05: Security Misconfiguration** | Header HTTP diperketat: `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security: max-age=31536000`, stripping banner server dan `X-Powered-By`. | **ACTIVE** |
| **A06: Vulnerable Components** | Desain Zero-Dependency native Node.js & statically-compiled Go binary, meminimalkan attack surface dari supply-chain attack. | **ACTIVE** |
| **A07: Identification & Auth Failures** | Bcrypt (cost 12) & Scrypt password hashing dengan salt unik. Token berbasis JWT/CSPRNG dengan masa berlaku terbatas dan verifikasi claim ketat. | **ACTIVE** |
| **A08: Software & Data Integrity** | Audit trail menggunakan hash chaining `SHA-256(prev_hash + event + payload + timestamp)` untuk mencegah manipulasi riwayat audit. | **ACTIVE** |
| **A09: Logging & Monitoring Failures** | Pencatatan otomatis setiap upaya login gagal, pemblokiran IDOR, tripping rate-limit, dan submission ke dalam audit trail yang tidak dapat diubah (immutable). | **ACTIVE** |
| **A10: Server-Side Request Forgery (SSRF)** | Seluruh resource statis dan request diikat ke domain terisolasi tanpa eksekusi dynamic URL client. | **ACTIVE** |

---

## 3. Validasi Keamanan Unggah Berkas (Anti-Webshell)

1. **Header Magic Byte Verification:** Berkas tidak hanya diverifikasi berdasarkan ekstensi `.jpg` atau `.png`, melainkan diperiksa 512 byte pertamanya:
   - JPEG: `\xFF\xD8\xFF`
   - PNG: `\x89PNG\r\n\x1a\n`
   - WebP: `RIFF....WEBP`
2. **Anti-Payload Signature Scanning:** Pemeriksaan token berbahaya seperti `<?php`, `<script`, `eval(`, `base64_decode`, `system(`.
3. **Penyimpanan Acak (Anti-Path Traversal):** Berkas diberi nama acak 32 karakter heksadesimal (`crypto.randomBytes`) dan disimpan di luar root eksekusi web.

---

## 4. Prosedur Audit & Pengujian

Jalankan test suite keamanan kapan saja dengan:
```bash
cd sanita-app
node unit_test.js
```
Hasil audit: 9 dari 9 pengujian kriptografi, anti-tamper, evaluasi checklist, dan sanitasi dinyatakan **PASSED (100%)**.