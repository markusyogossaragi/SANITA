import '../datasources/apiDataSource.dart';
import '../models/models.dart';
import '../services/securityService.dart';

class SanitasiRepository {
  static final ApiDataSource _api = ApiDataSource();
  static final SecurityService _security = SecurityService();
  final List<ChecklistModel> _localChecklists = [];

  Future<ChecklistModel> submitChecklist({
    required String lokasi,
    required bool airBersih,
    required bool toiletBersih,
    required bool tempatSampah,
    required bool ventilasiUdara,
    required bool bebasGenangan,
    required bool kebersihanArea,
  }) async {
    final payload = {
      'lokasi': lokasi.trim().isEmpty ? 'kampus unpri' : lokasi.trim(),
      'air_bersih': airBersih,
      'toilet_bersih': toiletBersih,
      'tempat_sampah': tempatSampah,
      'ventilasi_udara': ventilasiUdara,
      'bebas_genangan': bebasGenangan,
      'kebersihan_area': kebersihanArea,
    };

    try {
      final res = await _api.post('/sanitasi/checklist', payload);
      if (res['status'] == 200 && res['data'] != null) {
        final model = ChecklistModel.fromJson(res['data']);
        _localChecklists.insert(0, model);
        return model;
      }
    } catch (_) {}

    // Secure local fallback calculation
    int score = 0;
    List<String> perbaikan = [];
    if (airBersih) score++; else perbaikan.add('Sediakan pasokan air bersih layak guna');
    if (toiletBersih) score++; else perbaikan.add('Pembersihan toilet berkala & sabun CTPS');
    if (tempatSampah) score++; else perbaikan.add('Sediakan tempat sampah tertutup berpedal');
    if (ventilasiUdara) score++; else perbaikan.add('Buka ventilasi udara / service AC');
    if (bebasGenangan) score++; else perbaikan.add('Kuras genangan air pencegah vektor DBD');
    if (kebersihanArea) score++; else perbaikan.add('Pembersihan workstation dan lantai bersama');

    final checksum = _security.computeChecklistSHA256('$lokasi:$score:6:${DateTime.now().millisecondsSinceEpoch}');

    final fallbackModel = ChecklistModel(
      id: 'chk-${DateTime.now().millisecondsSinceEpoch}',
      lokasi: lokasi.trim().isEmpty ? 'kampus unpri' : lokasi.trim(),
      skorTerpenuhi: score,
      totalKondisi: 6,
      persentase: (score / 6.0) * 100.0,
      statusHasil: score == 6 ? 'Semua kondisi checklist terpenuhi' : 'Kondisi Sanitasi Cukup Memadai',
      saranTindak: score == 6
          ? 'Checklist terpenuhi: 6/6. Pertahankan kondisi dan lakukan pemantauan rutin.'
          : 'Checklist terpenuhi: $score/6. Segera tindak lanjuti butir yang belum terpenuhi.',
      poinPerbaikan: perbaikan,
      catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: checksum,
      createdAt: DateTime.now(),
    );

    _localChecklists.insert(0, fallbackModel);
    return fallbackModel;
  }

  Future<List<ChecklistModel>> getHistory() async {
    try {
      final res = await _api.get('/sanitasi/history');
      if (res['status'] == 200 && res['data'] is List) {
        return (res['data'] as List).map((e) => ChecklistModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _localChecklists;
  }
}