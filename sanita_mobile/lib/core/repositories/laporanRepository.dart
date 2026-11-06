import '../datasources/apiDataSource.dart';
import '../models/models.dart';
import '../services/securityService.dart';
import '../utils/inputSanitizer.dart';

class LaporanRepository {
  static final ApiDataSource _api = ApiDataSource();
  static final SecurityService _security = SecurityService();
  final List<LaporanModel> _localReports = [];

  Future<LaporanModel> submitReport({
    required String jenisMasalah,
    required String lokasi,
    required String keterangan,
    String? fotoUrl,
  }) async {
    final cleanJenis = InputSanitizer.sanitize(jenisMasalah);
    final cleanLokasi = InputSanitizer.sanitize(lokasi);
    final cleanKeterangan = InputSanitizer.sanitize(keterangan);

    final payload = {
      'jenis_permasalahan': cleanJenis,
      'lokasi_kejadian': cleanLokasi,
      'keterangan': cleanKeterangan,
      'foto_base64': fotoUrl ?? '',
    };

    try {
      final res = await _api.post('/laporan', payload);
      if (res['status'] == 201 && res['data'] != null) {
        final model = LaporanModel.fromJson(res['data']);
        _localReports.insert(0, model);
        return model;
      }
    } catch (_) {}

    // Offline / fallback creation with cryptographic HMAC signature
    final id = 'lap-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    final hmac = _security.computeReportHMAC(
      id: id,
      category: cleanJenis,
      location: cleanLokasi,
      description: cleanKeterangan,
      timestamp: now,
    );

    final fallback = LaporanModel(
      id: id,
      jenisMasalah: cleanJenis,
      lokasi: cleanLokasi,
      keterangan: cleanKeterangan,
      fotoUrl: fotoUrl,
      status: 'terkirim',
      reporterName: 'Sahabat SANITA',
      createdAt: now,
      integrityHMAC: hmac,
    );

    _localReports.insert(0, fallback);
    return fallback;
  }

  Future<List<LaporanModel>> getReports() async {
    try {
      final res = await _api.get('/laporan');
      if (res['status'] == 200 && res['data'] is List) {
        final list = (res['data'] as List).map((e) => LaporanModel.fromJson(e)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return _localReports;
  }

  bool verifyReport(LaporanModel report) {
    return _security.verifyReportIntegrity(
      id: report.id,
      category: report.jenisMasalah,
      location: report.lokasi,
      description: report.keterangan,
      timestamp: report.createdAt,
      signature: report.integrityHMAC,
    );
  }
}