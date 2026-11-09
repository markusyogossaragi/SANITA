import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/apiDataSource.dart';
import '../models/models.dart';
import '../services/securityService.dart';
import '../utils/inputSanitizer.dart';

class LaporanRepository {
  static final ApiDataSource _api = ApiDataSource();
  static final SecurityService _security = SecurityService();
  static const String _storageKey = 'sanita_reports_storage_v2';
  static final List<LaporanModel> _memoryCache = [];

  static final List<LaporanModel> initialSeedReports = [
    LaporanModel(
      id: 'SNT-2026-0104',
      jenisMasalah: 'Pengelolaan Sampah',
      lokasi: 'Kantin Kampus UNPRI Lt. 1',
      keterangan: 'Tempat sampah organik penuh dan penutup pedal perlu perbaikan.',
      status: 'selesai',
      urgensi: 'Sedang',
      reporterName: 'ribka',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      integrityHMAC: 'sha256-verified-tamper-proof',
    ),
    LaporanModel(
      id: 'SNT-2026-0105',
      jenisMasalah: 'Kebersihan Toilet',
      lokasi: 'Toilet Barat Lantai 2',
      keterangan: 'Wastafel tersumbat ringan dan sabun cuci tangan cair habis.',
      status: 'diproses',
      urgensi: 'Mendesak',
      reporterName: 'eko_k3',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      integrityHMAC: 'sha256-verified-tamper-proof',
    ),
    LaporanModel(
      id: 'SNT-2026-0106',
      jenisMasalah: 'Sirkulasi / Ventilasi Udara',
      lokasi: 'Ruang Rapat Utama Lantai 3',
      keterangan: 'Sirkulasi udara pengap dan kisi exhaust fan perlu dibersihkan dari debu.',
      status: 'terkirim',
      urgensi: 'Rendah',
      reporterName: 'budi_kesling',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
      integrityHMAC: 'sha256-verified-tamper-proof',
    ),
  ];

  Future<LaporanModel> submitReport({
    required String jenisMasalah,
    required String lokasi,
    required String keterangan,
    String? fotoUrl,
    String urgensi = 'Sedang',
    String reporterName = 'pengguna',
  }) async {
    final cleanJenis = InputSanitizer.sanitize(jenisMasalah);
    final cleanLokasi = InputSanitizer.sanitize(lokasi);
    final cleanKeterangan = InputSanitizer.sanitize(keterangan);

    final payload = {
      'jenis_permasalahan': cleanJenis,
      'lokasi_kejadian': cleanLokasi,
      'keterangan': cleanKeterangan,
      'foto_base64': fotoUrl ?? '',
      'urgensi': urgensi,
    };

    LaporanModel? createdModel;
    try {
      final res = await _api.post('/laporan', payload);
      if (res['status'] == 201 && res['data'] != null) {
        createdModel = LaporanModel.fromJson(res['data']);
      }
    } catch (_) {}

    if (createdModel == null) {
      final id = 'SNT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final now = DateTime.now().toIso8601String();
      final hmac = _security.computeReportHMAC(
        id: id,
        category: cleanJenis,
        location: cleanLokasi,
        description: cleanKeterangan,
        timestamp: now,
      );

      createdModel = LaporanModel(
        id: id,
        jenisMasalah: cleanJenis,
        lokasi: cleanLokasi,
        keterangan: cleanKeterangan,
        fotoUrl: fotoUrl,
        status: 'terkirim',
        urgensi: urgensi,
        reporterName: reporterName,
        createdAt: now,
        integrityHMAC: hmac,
      );
    }

    final currentReports = await getReports();
    currentReports.insert(0, createdModel);
    await saveReports(currentReports);

    return createdModel;
  }

  Future<List<LaporanModel>> getReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      await saveReports(initialSeedReports);
      _memoryCache.clear();
      _memoryCache.addAll(initialSeedReports);
      return List.from(initialSeedReports);
    }

    try {
      final list = jsonDecode(raw) as List;
      final parsed = list.map((e) {
        final r = LaporanModel.fromJson(Map<String, dynamic>.from(e as Map));
        final cleanUsername = r.reporterUsername;
        if (cleanUsername != r.reporterName) {
          return LaporanModel(
            id: r.id,
            jenisMasalah: r.jenisMasalah,
            lokasi: r.lokasi,
            keterangan: r.keterangan,
            status: r.status,
            urgensi: r.urgensi,
            createdAt: r.createdAt,
            integrityHMAC: r.integrityHMAC,
            fotoUrl: r.fotoUrl,
            reporterName: cleanUsername,
            catatanDisposisi: r.catatanDisposisi,
          );
        }
        return r;
      }).toList();
      _memoryCache.clear();
      _memoryCache.addAll(parsed);
      return parsed;
    } catch (_) {
      return List.from(initialSeedReports);
    }
  }

  Future<void> saveReports(List<LaporanModel> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reports.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    _memoryCache.clear();
    _memoryCache.addAll(reports);
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final reports = await getReports();
    final index = reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = reports[index];
      reports[index] = LaporanModel(
        id: old.id,
        jenisMasalah: old.jenisMasalah,
        lokasi: old.lokasi,
        keterangan: old.keterangan,
        fotoUrl: old.fotoUrl,
        status: newStatus,
        urgensi: old.urgensi,
        reporterName: old.reporterName,
        createdAt: old.createdAt,
        integrityHMAC: old.integrityHMAC,
      );
      await saveReports(reports);
    }
  }

  Future<void> updateReport(LaporanModel updated) async {
    final reports = await getReports();
    final index = reports.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      reports[index] = updated;
      await saveReports(reports);
    }
  }

  Future<void> deleteReport(String id) async {
    final reports = await getReports();
    reports.removeWhere((r) => r.id == id);
    await saveReports(reports);
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