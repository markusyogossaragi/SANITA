class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? email;
  final String? phone;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? 'Ribka Lusiana Harahap',
      role: json['role'] ?? 'Inspektur Kesling',
      email: json['email'] ?? 'ribka@sanita.id',
      phone: json['phone'] ?? '+62 812-3456-7890',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'role': role,
    'email': email,
    'phone': phone,
  };
}

class ChecklistModel {
  final String id;
  final String lokasi;
  final int skorTerpenuhi;
  final int totalKondisi;
  final double persentase;
  final String statusHasil;
  final String saranTindak;
  final List<String> poinPerbaikan;
  final String catatanSimulasi;
  final String checksumSHA256;
  final DateTime createdAt;

  ChecklistModel({
    required this.id,
    required this.lokasi,
    required this.skorTerpenuhi,
    required this.totalKondisi,
    required this.persentase,
    required this.statusHasil,
    required this.saranTindak,
    required this.poinPerbaikan,
    required this.catatanSimulasi,
    required this.checksumSHA256,
    required this.createdAt,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    var rawPoin = json['poin_perbaikan'];
    List<String> list = [];
    if (rawPoin is List) {
      list = rawPoin.map((e) => e.toString()).toList();
    }

    return ChecklistModel(
      id: json['id'] ?? '',
      lokasi: json['lokasi'] ?? '',
      skorTerpenuhi: json['skor_terpenuhi'] ?? 0,
      totalKondisi: json['total_kondisi'] ?? 6,
      persentase: (json['persentase'] is num) ? (json['persentase'] as num).toDouble() : 0.0,
      statusHasil: json['status_hasil'] ?? '',
      saranTindak: json['saran_tindak_lanjut'] ?? '',
      poinPerbaikan: list,
      catatanSimulasi: json['catatan_simulasi'] ?? 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
      checksumSHA256: json['checksum_sha256'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lokasi': lokasi,
    'skor_terpenuhi': skorTerpenuhi,
    'total_kondisi': totalKondisi,
    'persentase': persentase,
    'status_hasil': statusHasil,
    'saran_tindak_lanjut': saranTindak,
    'poin_perbaikan': poinPerbaikan,
    'catatan_simulasi': catatanSimulasi,
    'checksum_sha256': checksumSHA256,
    'created_at': createdAt.toIso8601String(),
  };
}

class LaporanModel {
  final String id;
  final String jenisMasalah;
  final String lokasi;
  final String keterangan;
  final String? fotoUrl;
  final String status;
  final String urgensi;
  final String reporterName;
  final String createdAt;
  final String integrityHMAC;

  LaporanModel({
    required this.id,
    required this.jenisMasalah,
    required this.lokasi,
    required this.keterangan,
    this.fotoUrl,
    required this.status,
    this.urgensi = 'Sedang',
    required this.reporterName,
    required this.createdAt,
    required this.integrityHMAC,
  });

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    return LaporanModel(
      id: json['id'] ?? '',
      jenisMasalah: json['jenis_permasalahan'] ?? '',
      lokasi: json['lokasi_kejadian'] ?? '',
      keterangan: json['keterangan'] ?? '',
      fotoUrl: json['foto_url'],
      status: json['status'] ?? 'terkirim',
      urgensi: json['urgensi'] ?? 'Sedang',
      reporterName: json['reporter_name'] ?? 'Sahabat SANITA',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      integrityHMAC: json['integrity_hmac'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jenis_permasalahan': jenisMasalah,
    'lokasi_kejadian': lokasi,
    'keterangan': keterangan,
    'foto_url': fotoUrl,
    'status': status,
    'urgensi': urgensi,
    'reporter_name': reporterName,
    'created_at': createdAt,
    'integrity_hmac': integrityHMAC,
  };
}

class EdukasiModel {
  final String id;
  final String judul;
  final String kategori;
  final String ringkasan;
  final String konten;
  final String ikon;
  final int urutan;
  final String referensi;

  EdukasiModel({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.ringkasan,
    required this.konten,
    required this.ikon,
    required this.urutan,
    required this.referensi,
  });

  factory EdukasiModel.fromJson(Map<String, dynamic> json) {
    return EdukasiModel(
      id: json['id'] ?? '',
      judul: json['judul'] ?? '',
      kategori: json['kategori'] ?? '',
      ringkasan: json['ringkasan'] ?? '',
      konten: json['konten'] ?? '',
      ikon: json['ikon'] ?? 'shield',
      urutan: json['urutan'] ?? 1,
      referensi: json['referensi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'judul': judul,
    'kategori': kategori,
    'ringkasan': ringkasan,
    'konten': konten,
    'ikon': ikon,
    'urutan': urutan,
    'referensi': referensi,
  };
}

class MonitoringStatsModel {
  final int totalLaporan;
  final int laporanTerkirim;
  final int laporanDiproses;
  final int laporanSelesai;
  final int totalChecklist;
  final double rataRataKepatuhan;
  final String kategoriTerbanyak;
  final List<String> lokasiRawan;
  final String statusSistem;
  final String keamananStatus;
  final bool integrityValid;

  MonitoringStatsModel({
    required this.totalLaporan,
    required this.laporanTerkirim,
    required this.laporanDiproses,
    required this.laporanSelesai,
    required this.totalChecklist,
    required this.rataRataKepatuhan,
    required this.kategoriTerbanyak,
    required this.lokasiRawan,
    required this.statusSistem,
    required this.keamananStatus,
    required this.integrityValid,
  });

  factory MonitoringStatsModel.fromJson(Map<String, dynamic> json) {
    var rawLokasi = json['lokasi_rawan'];
    List<String> list = [];
    if (rawLokasi is List) {
      list = rawLokasi.map((e) => e.toString()).toList();
    }

    return MonitoringStatsModel(
      totalLaporan: json['total_laporan'] ?? 0,
      laporanTerkirim: json['laporan_terkirim'] ?? 0,
      laporanDiproses: json['laporan_diproses'] ?? 0,
      laporanSelesai: json['laporan_selesai'] ?? 0,
      totalChecklist: json['total_checklist'] ?? 0,
      rataRataKepatuhan: (json['rata_rata_kepatuhan_persen'] is num) ? (json['rata_rata_kepatuhan_persen'] as num).toDouble() : 100.0,
      kategoriTerbanyak: json['kategori_terbanyak'] ?? 'Toilet & Sanitasi',
      lokasiRawan: list,
      statusSistem: json['status_sistem'] ?? 'Normal & Terpantau',
      keamananStatus: json['keamanan_status'] ?? 'Optimal (Anti-Breach Shield Aktif)',
      integrityValid: json['integrity_valid'] ?? true,
    );
  }
}