import '../datasources/apiDataSource.dart';
import '../models/models.dart';

class EdukasiRepository {
  static final ApiDataSource _api = ApiDataSource();

  Future<List<EdukasiModel>> getMateri() async {
    try {
      final res = await _api.get('/edukasi');
      if (res['status'] == 200 && res['data'] is List) {
        return (res['data'] as List).map((e) => EdukasiModel.fromJson(e)).toList();
      }
    } catch (_) {}

    // Built-in standard curriculum
    return [
      EdukasiModel(
        id: 'edu-01',
        judul: 'Standar Kualitas & Higiene Air Bersih',
        kategori: 'Air Bersih',
        ringkasan: 'Kriteria fisik, kimiawi, dan mikrobiologis air layak guna di tempat kerja.',
        konten: 'Air bersih wajib tidak berwarna, tidak berbau, dan bebas patogen sesuai Permenkes No. 2/2023. Toren wajib dibersihkan secara rutin.',
        ikon: 'water_drop',
        urutan: 1,
        referensi: 'Permenkes No. 2 Tahun 2023',
      ),
      EdukasiModel(
        id: 'edu-02',
        judul: 'Sanitasi Toilet & Fasilitas CTPS',
        kategori: 'Sanitasi Dasar',
        ringkasan: 'Protokol pembersihan toilet dan pentingnya Cuci Tangan Pakai Sabun.',
        konten: 'Toilet wajib memiliki ventilasi silang, lantai tidak licin, air mengalir kontinu, dan tempat sampah pembalut tertutup.',
        ikon: 'wash',
        urutan: 2,
        referensi: 'Pedoman K3 Sanitasi Tempat Kerja',
      ),
      EdukasiModel(
        id: 'edu-03',
        judul: 'Manajemen Sampah & Prinsip 3R',
        kategori: 'Pengelolaan Sampah',
        ringkasan: 'Pemilahan sampah organik, anorganik, dan B3.',
        konten: 'Tempat sampah wajib tertutup berpedal dan dikosongkan maksimal 1x24 jam untuk mencegah lalat dan bau menyengat.',
        ikon: 'delete_outline',
        urutan: 3,
        referensi: 'UU No. 18 Tahun 2008',
      ),
      EdukasiModel(
        id: 'edu-04',
        judul: 'Ventilasi & Sirkulasi Udara Sehat',
        kategori: 'Kualitas Udara',
        ringkasan: 'Pencegahan Sick Building Syndrome (SBS) dan penyebaran droplet saluran napas.',
        konten: 'Pergantian udara minimal 6-12 kali per jam (ACH). Buka jendela di pagi hari dan bersihkan filter AC setiap bulan.',
        ikon: 'air',
        urutan: 4,
        referensi: 'Permenaker No. 5 Tahun 2018',
      ),
      EdukasiModel(
        id: 'edu-05',
        judul: 'Pengendalian Vektor & Binatang Penyakit',
        kategori: 'Pengendalian Vektor',
        ringkasan: 'Eliminasi tempat perindukan nyamuk (DBD) dan tikus.',
        konten: 'Keringkan genangan air di talang dan wadah terbuka. Terapkan 3M Plus untuk mencegah transmisi DBD dan Leptospirosis.',
        ikon: 'pest_control',
        urutan: 5,
        referensi: 'Permenkes No. 50 Tahun 2017',
      ),
      EdukasiModel(
        id: 'edu-06',
        judul: 'Pencegahan Kecelakaan & Higiene Ruang Kerja',
        kategori: 'Ergonomi & Kerapian',
        ringkasan: 'Prinsip 5R (Ringkas, Rapi, Resik, Rawat, Rajin) dalam kebersihan workstation.',
        konten: 'Seka meja kerja secara berkala. Rapikan kabel listrik agar tidak menjuntai dan memicu bahaya kebakaran atau tersandung.',
        ikon: 'cleaning_services',
        urutan: 6,
        referensi: 'Pedoman Higiene Industri Perkantoran',
      ),
    ];
  }
}