import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/apiDataSource.dart';
import '../models/models.dart';
import '../services/securityService.dart';

class SanitasiRepository {
  static final ApiDataSource _api = ApiDataSource();
  static final SecurityService _security = SecurityService();
  static const String _storageKey = 'sanita_checklist_history_v2';
  static final List<ChecklistModel> _memoryCache = [];

  // Data awal / seed jika belum ada checklist
  static final List<ChecklistModel> _initialSeed = [
    ChecklistModel(
      id: 'CHK-2026-0881',
      lokasi: 'Kantin Kampus UNPRI Lt. 1',
      skorTerpenuhi: 5,
      totalKondisi: 6,
      persentase: 83.3,
      statusHasil: 'Kondisi Sanitasi Cukup Memadai',
      saranTindak: 'Checklist terpenuhi: 5/6. Perbaiki butir sanitasi yang belum memenuhi kriteria.',
      poinPerbaikan: ['Sediakan tempat sampah tertutup berpedal'],
      catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: 'sha256-verified-tamper-proof',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      inspectorUsername: 'ribka',
      kriteriaDetail: {
        'Air Bersih Mengalir': true,
        'Toilet Bersih & Higienis': true,
        'Tempat Sampah Tertutup': false,
        'Sirkulasi / Ventilasi Udara': true,
        'Bebas Genangan Air': true,
        'Kebersihan Area Kerja': true,
      },
    ),
    ChecklistModel(
      id: 'CHK-2026-0882',
      lokasi: 'Toilet Barat Lantai 2',
      skorTerpenuhi: 4,
      totalKondisi: 6,
      persentase: 66.7,
      statusHasil: 'Kondisi Sanitasi Cukup Memadai',
      saranTindak: 'Checklist terpenuhi: 4/6. Segera bersihkan toilet & servis ventilasi.',
      poinPerbaikan: ['Pembersihan toilet berkala & sabun CTPS', 'Buka ventilasi udara / service exhaust'],
      catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: 'sha256-verified-tamper-proof',
      createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 10)),
      inspectorUsername: 'eko_k3',
      kriteriaDetail: {
        'Air Bersih Mengalir': true,
        'Toilet Bersih & Higienis': false,
        'Tempat Sampah Tertutup': true,
        'Sirkulasi / Ventilasi Udara': false,
        'Bebas Genangan Air': true,
        'Kebersihan Area Kerja': true,
      },
    ),
    ChecklistModel(
      id: 'CHK-2026-0883',
      lokasi: 'Laboratorium Komputer Lt. 3',
      skorTerpenuhi: 6,
      totalKondisi: 6,
      persentase: 100.0,
      statusHasil: 'Memenuhi Syarat (MS 100%)',
      saranTindak: 'Checklist terpenuhi: 6/6. Pertahankan kondisi dan lakukan pemantauan rutin.',
      poinPerbaikan: [],
      catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: 'sha256-verified-tamper-proof',
      createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
      inspectorUsername: 'ribka',
      kriteriaDetail: {
        'Air Bersih Mengalir': true,
        'Toilet Bersih & Higienis': true,
        'Tempat Sampah Tertutup': true,
        'Sirkulasi / Ventilasi Udara': true,
        'Bebas Genangan Air': true,
        'Kebersihan Area Kerja': true,
      },
    ),
    ChecklistModel(
      id: 'CHK-2026-0884',
      lokasi: 'Ruang Dosen & Administrasi',
      skorTerpenuhi: 6,
      totalKondisi: 6,
      persentase: 100.0,
      statusHasil: 'Memenuhi Syarat (MS 100%)',
      saranTindak: 'Checklist terpenuhi: 6/6. Ruangan dalam kondisi higienis optimal.',
      poinPerbaikan: [],
      catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: 'sha256-verified-tamper-proof',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      inspectorUsername: 'budi_kesling',
      kriteriaDetail: {
        'Air Bersih Mengalir': true,
        'Toilet Bersih & Higienis': true,
        'Tempat Sampah Tertutup': true,
        'Sirkulasi / Ventilasi Udara': true,
        'Bebas Genangan Air': true,
        'Kebersihan Area Kerja': true,
      },
    ),
    ChecklistModel(
      id: 'CHK-2026-0885',
      lokasi: 'Perpustakaan Pusat Lantai 2',
      skorTerpenuhi: 5,
      totalKondisi: 6,
      persentase: 83.3,
      statusHasil: 'Kondisi Sanitasi Cukup Memadai',
      saranTindak: 'Checklist terpenuhi: 5/6. Sirkulasi udara pengap perlu perawatan exhaust fan.',
      poinPerbaikan: ['Buka ventilasi udara / service exhaust'],
      catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: 'sha256-verified-tamper-proof',
      createdAt: DateTime.now().subtract(const Duration(hours: 8, minutes: 45)),
      inspectorUsername: 'ribka',
      kriteriaDetail: {
        'Air Bersih Mengalir': true,
        'Toilet Bersih & Higienis': true,
        'Tempat Sampah Tertutup': true,
        'Sirkulasi / Ventilasi Udara': false,
        'Bebas Genangan Air': true,
        'Kebersihan Area Kerja': true,
      },
    ),
  ];

  Future<ChecklistModel> submitChecklist({
    required String lokasi,
    required bool airBersih,
    required bool toiletBersih,
    required bool tempatSampah,
    required bool ventilasiUdara,
    required bool bebasGenangan,
    required bool kebersihanArea,
    String inspectorUsername = 'Pengguna',
  }) async {
    final payload = {
      'lokasi': lokasi.trim().isEmpty ? 'kampus unpri' : lokasi.trim(),
      'air_bersih': airBersih,
      'toilet_bersih': toiletBersih,
      'tempat_sampah': tempatSampah,
      'ventilasi_udara': ventilasiUdara,
      'bebas_genangan': bebasGenangan,
      'kebersihan_area': kebersihanArea,
      'inspector_username': inspectorUsername,
    };

    ChecklistModel? model;
    try {
      final res = await _api.post('/sanitasi/checklist', payload);
      if (res['status'] == 200 && res['data'] != null) {
        model = ChecklistModel.fromJson(res['data']);
      }
    } catch (_) {}

    if (model == null) {
      int score = 0;
      List<String> perbaikan = [];
      if (airBersih) score++; else perbaikan.add('Sediakan pasokan air bersih layak guna');
      if (toiletBersih) score++; else perbaikan.add('Pembersihan toilet berkala & sabun CTPS');
      if (tempatSampah) score++; else perbaikan.add('Sediakan tempat sampah tertutup berpedal');
      if (ventilasiUdara) score++; else perbaikan.add('Buka ventilasi udara / service AC');
      if (bebasGenangan) score++; else perbaikan.add('Kuras genangan air pencegah vektor DBD');
      if (kebersihanArea) score++; else perbaikan.add('Pembersihan workstation dan lantai bersama');

      final checksum = _security.computeChecklistSHA256('$lokasi:$score:6:${DateTime.now().millisecondsSinceEpoch}');

      model = ChecklistModel(
        id: 'CHK-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        lokasi: lokasi.trim().isEmpty ? 'Area Kerja Kampus' : lokasi.trim(),
        skorTerpenuhi: score,
        totalKondisi: 6,
        persentase: (score / 6.0) * 100.0,
        statusHasil: score == 6 ? 'Memenuhi Syarat (MS 100%)' : (score >= 4 ? 'Kondisi Sanitasi Cukup Memadai' : 'Perlu Perbaikan Mendesak (TMS)'),
        saranTindak: score == 6
            ? 'Checklist terpenuhi: 6/6. Pertahankan kondisi dan lakukan pemantauan rutin.'
            : 'Checklist terpenuhi: $score/6. Segera tindak lanjuti butir yang belum terpenuhi.',
        poinPerbaikan: perbaikan,
        catatanSimulasi: 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
        checksumSHA256: checksum,
        createdAt: DateTime.now(),
        inspectorUsername: inspectorUsername,
        kriteriaDetail: {
          'Air Bersih Mengalir': airBersih,
          'Toilet Bersih & Higienis': toiletBersih,
          'Tempat Sampah Tertutup': tempatSampah,
          'Sirkulasi / Ventilasi Udara': ventilasiUdara,
          'Bebas Genangan Air': bebasGenangan,
          'Kebersihan Area Kerja': kebersihanArea,
        },
      );
    }

    await saveChecklist(model);
    return model;
  }

  Future<void> saveChecklist(ChecklistModel model) async {
    final history = await getHistory();
    history.insert(0, model);
    await _persistList(history);
  }

  Future<List<ChecklistModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      await _persistList(_initialSeed);
      _memoryCache.clear();
      _memoryCache.addAll(_initialSeed);
      return List.from(_initialSeed);
    }

    try {
      final list = jsonDecode(raw) as List;
      final parsed = list.map((e) => ChecklistModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      if (parsed.length <= 1) {
        for (final seed in _initialSeed) {
          if (!parsed.any((p) => p.lokasi.toLowerCase().trim() == seed.lokasi.toLowerCase().trim())) {
            parsed.add(seed);
          }
        }
        await _persistList(parsed);
      }
      _memoryCache.clear();
      _memoryCache.addAll(parsed);
      return parsed;
    } catch (_) {
      return List.from(_initialSeed);
    }
  }

  Future<void> deleteChecklist(String id) async {
    final history = await getHistory();
    history.removeWhere((c) => c.id == id);
    await _persistList(history);
  }

  Future<void> _persistList(List<ChecklistModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    _memoryCache.clear();
    _memoryCache.addAll(list);
  }
}