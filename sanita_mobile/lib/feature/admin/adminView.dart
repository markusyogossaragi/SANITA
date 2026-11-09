import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/repositories/authRepository.dart';
import '../../core/repositories/laporanRepository.dart';
import '../../core/repositories/sanitasiRepository.dart';
import '../../core/utils/dateFormatter.dart';

class AdminDashboardView extends StatefulWidget {
  final VoidCallback onBack;
  final List<LaporanModel> reports;
  final Function(String id, String newStatus)? onUpdateStatus;
  final Function(LaporanModel updatedReport)? onEditReport;
  final Function(String id)? onDeleteReport;

  const AdminDashboardView({
    super.key,
    required this.onBack,
    required this.reports,
    this.onUpdateStatus,
    this.onEditReport,
    this.onDeleteReport,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<LaporanModel> _reportsList;
  List<Map<String, dynamic>> _registeredUsers = [];
  List<ChecklistModel> _checklistHistory = [];
  bool _isLoadingUsers = true;
  bool _isLoadingChecklist = true;
  String _selectedStatusFilter = 'Semua';
  String _checklistStatusFilter = 'Semua';
  String _checklistSearchQuery = '';
  final TextEditingController _checklistSearchController = TextEditingController();

  // Fitur Pilih Banyak (Batch Selection)
  bool _isBatchReports = false;
  final Set<String> _selectedReportIds = {};

  bool _isBatchChecklist = false;
  final Set<String> _selectedChecklistIds = {};

  // Filtering per tanggal untuk Hasil Cek Sanitasi
  DateTime? _checklistDateFilter;
  String _checklistDatePreset = 'Semua Tanggal';

  final List<String> _kategoriMasalahOptions = [
    'Kebersihan Toilet',
    'Pengelolaan Sampah',
    'Kualitas Air Bersih',
    'Sirkulasi / Ventilasi Udara',
    'Pencahayaan Ruang Kerja',
    'Pengendalian Vektor & Hama',
    'Lainnya',
  ];

  final List<String> _roleOptions = [
    'Admin',
    'Inspektur Kesling',
    'Inspektur Sanitasi & K3',
    'Koordinator Sanitasi',
    'Staf Kebersihan & Sarana',
    'Dosen Kesehatan Lingkungan',
    'Mahasiswa Kesling',
    'Pengguna Terdaftar',
  ];

  @override
  void initState() {
    super.initState();
    // 4 Tab: Kelola Laporan, Hasil Cek Sanitasi (Khusus Admin), Database Akun, Info Sistem
    _tabController = TabController(length: 4, vsync: this);
    _reportsList = List.from(widget.reports);
    _loadRegisteredUsers();
    _loadChecklistHistory();
  }

  Future<void> _refreshAllData() async {
    final freshReports = await LaporanRepository().getReports();
    final freshHistory = await SanitasiRepository().getHistory();
    final freshUsers = await AuthRepository().getAllUsers();

    if (mounted) {
      setState(() {
        _reportsList = freshReports;
        _checklistHistory = freshHistory;
        _registeredUsers = freshUsers;
        _selectedReportIds.clear();
        _selectedChecklistIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data panel admin berhasil diperbarui.'),
          backgroundColor: SanitaColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _setChecklistDatePreset(String preset, [DateTime? customDate]) {
    setState(() {
      _checklistDatePreset = preset;
      if (preset == 'Hari Ini') {
        _checklistDateFilter = DateTime.now();
      } else if (preset == 'Kemarin') {
        _checklistDateFilter = DateTime.now().subtract(const Duration(days: 1));
      } else if (preset == 'Semua Tanggal') {
        _checklistDateFilter = null;
      } else if (customDate != null) {
        _checklistDateFilter = customDate;
      }
    });
  }

  Future<void> _pickChecklistDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checklistDateFilter ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: 'PILIH TANGGAL HASIL CEK SANITASI',
    );
    if (picked != null) {
      _setChecklistDatePreset('Pilih Tanggal', picked);
    }
  }

  void _batchUpdateReportStatus(String newStatus) async {
    if (_selectedReportIds.isEmpty) return;
    final ids = List<String>.from(_selectedReportIds);
    for (final id in ids) {
      await LaporanRepository().updateStatus(id, newStatus);
      final idx = _reportsList.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final old = _reportsList[idx];
        final updated = LaporanModel(
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
          catatanDisposisi: old.catatanDisposisi,
        );
        _reportsList[idx] = updated;
      }
      if (widget.onUpdateStatus != null) {
        widget.onUpdateStatus!(id, newStatus);
      }
    }
    setState(() {
      _selectedReportIds.clear();
      _isBatchReports = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ids.length} laporan diubah ke: ${newStatus.toUpperCase()}'),
        backgroundColor: SanitaColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _batchDeleteReports() async {
    if (_selectedReportIds.isEmpty) return;
    final count = _selectedReportIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Banyak Laporan?'),
        content: Text('Apakah Anda yakin ingin menghapus $count laporan yang dipilih secara massal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.alertRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ids = List<String>.from(_selectedReportIds);
      for (final id in ids) {
        await LaporanRepository().deleteReport(id);
        _reportsList.removeWhere((r) => r.id == id);
        if (widget.onDeleteReport != null) {
          widget.onDeleteReport!(id);
        }
      }
      setState(() {
        _selectedReportIds.clear();
        _isBatchReports = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count laporan berhasil dihapus.'),
          backgroundColor: SanitaColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _batchDeleteChecklists() async {
    if (_selectedChecklistIds.isEmpty) return;
    final count = _selectedChecklistIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Banyak Hasil Cek?'),
        content: Text('Apakah Anda yakin ingin menghapus $count catatan hasil cek sanitasi yang dipilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.alertRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ids = List<String>.from(_selectedChecklistIds);
      for (final id in ids) {
        await SanitasiRepository().deleteChecklist(id);
        _checklistHistory.removeWhere((c) => c.id == id);
      }
      setState(() {
        _selectedChecklistIds.clear();
        _isBatchChecklist = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count catatan hasil cek berhasil dihapus.'),
          backgroundColor: SanitaColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadRegisteredUsers() async {
    final users = await AuthRepository().getAllUsers();
    if (mounted) {
      setState(() {
        _registeredUsers = users;
        _isLoadingUsers = false;
      });
    }
  }

  void _loadChecklistHistory() async {
    final history = await SanitasiRepository().getHistory();
    if (mounted) {
      setState(() {
        _checklistHistory = history;
        _isLoadingChecklist = false;
      });
    }
  }

  void _updateStatus(String id, String newStatus) {
    final idx = _reportsList.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _reportsList[idx];
      final updated = LaporanModel(
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
        catatanDisposisi: old.catatanDisposisi,
      );
      _reportsList[idx] = updated;

      final widgetIdx = widget.reports.indexWhere((r) => r.id == id);
      if (widgetIdx != -1) {
        widget.reports[widgetIdx] = updated;
      }
    }

    if (widget.onUpdateStatus != null) {
      widget.onUpdateStatus!(id, newStatus);
    }
    LaporanRepository().updateStatus(id, newStatus);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status laporan $id berhasil diubah menjadi: ${newStatus.toUpperCase()}'),
        backgroundColor: SanitaColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- FITUR KELOLA LAPORAN: EDIT LAPORAN ---
  void _showEditReportDialog(LaporanModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final lokasiCtrl = TextEditingController(text: report.lokasi);
    final keteranganCtrl = TextEditingController(text: report.keterangan);

    String selectedJenis = _kategoriMasalahOptions.contains(report.jenisMasalah)
        ? report.jenisMasalah
        : _kategoriMasalahOptions.first;
    String selectedUrgensi = report.urgensi;
    String selectedStatus = report.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: SanitaColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Edit Laporan (${report.id})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lokasi Pemeriksaan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: lokasiCtrl,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    Text('Jenis Masalah Sanitasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedJenis,
                      dropdownColor: isDark ? SanitaColors.darkCard : Colors.white,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _kategoriMasalahOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedJenis = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tingkat Urgensi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: ['Rendah', 'Sedang', 'Mendesak'].contains(selectedUrgensi) ? selectedUrgensi : 'Sedang',
                                dropdownColor: isDark ? SanitaColors.darkCard : Colors.white,
                                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: ['Rendah', 'Sedang', 'Mendesak'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedUrgensi = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status Laporan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: ['terkirim', 'diproses', 'selesai'].contains(selectedStatus.toLowerCase()) ? selectedStatus.toLowerCase() : 'terkirim',
                                dropdownColor: isDark ? SanitaColors.darkCard : Colors.white,
                                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'terkirim', child: Text('Terkirim')),
                                  const DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
                                  const DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedStatus = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text('Keterangan / Temuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: keteranganCtrl,
                      maxLines: 3,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Keterangan wajib diisi' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SanitaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final updated = LaporanModel(
                    id: report.id,
                    jenisMasalah: selectedJenis,
                    lokasi: lokasiCtrl.text.trim(),
                    keterangan: keteranganCtrl.text.trim(),
                    fotoUrl: report.fotoUrl,
                    status: selectedStatus,
                    urgensi: selectedUrgensi,
                    reporterName: report.reporterName,
                    createdAt: report.createdAt,
                    integrityHMAC: report.integrityHMAC,
                    catatanDisposisi: report.catatanDisposisi,
                  );

                  final idx = _reportsList.indexWhere((r) => r.id == report.id);
                  if (idx != -1) {
                    _reportsList[idx] = updated;
                  }

                  final widgetIdx = widget.reports.indexWhere((r) => r.id == report.id);
                  if (widgetIdx != -1) {
                    widget.reports[widgetIdx] = updated;
                  }

                  if (widget.onEditReport != null) {
                    widget.onEditReport!(updated);
                  }
                  await LaporanRepository().updateReport(updated);

                  if (!mounted) return;
                  Navigator.pop(ctx);
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Laporan ${report.id} berhasil diperbarui!'),
                      backgroundColor: SanitaColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FITUR KELOLA LAPORAN: HAPUS LAPORAN ---
  void _confirmDeleteReport(LaporanModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: SanitaColors.alertRed),
            const SizedBox(width: 8),
            Text('Hapus Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus laporan "${report.id}" (${report.jenisMasalah} di ${report.lokasi}) secara permanen?',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : SanitaColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Hapus Laporan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SanitaColors.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              _reportsList.removeWhere((r) => r.id == report.id);
              widget.reports.removeWhere((r) => r.id == report.id);

              if (widget.onDeleteReport != null) {
                widget.onDeleteReport!(report.id);
              }
              await LaporanRepository().deleteReport(report.id);

              if (!mounted) return;
              Navigator.pop(ctx);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Laporan ${report.id} berhasil dihapus dari sistem!'),
                  backgroundColor: SanitaColors.alertRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- FITUR KELOLA AKUN: EDIT AKUN PENGGUNA ---
  void _showEditUserDialog(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');

    String selectedRole = _roleOptions.contains(user['role']) ? user['role'] : _roleOptions.last;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.manage_accounts, color: SanitaColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Edit Akun (@${user['username']})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Lengkap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameCtrl,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    Text('Peran / Jabatan Sanitasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: isDark ? SanitaColors.darkCard : Colors.white,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    Text('Email Pengguna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: emailCtrl,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Nomor Telepon / WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: phoneCtrl,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Simpan Akun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SanitaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final updatedUserMap = {
                    'id': user['id'],
                    'username': user['username'],
                    'full_name': nameCtrl.text.trim(),
                    'role': selectedRole,
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  };

                  await AuthRepository().updateUserByAdmin(updatedUserMap);
                  _loadRegisteredUsers();

                  if (!mounted) return;
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Akun @${user['username']} berhasil diperbarui!'),
                      backgroundColor: SanitaColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FITUR KELOLA AKUN: HAPUS AKUN PENGGUNA ---
  void _confirmDeleteUser(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = (user['username'] ?? '').toString().toLowerCase();

    // Lindungi akun Admin utama Ribka
    if (username == 'ribka' || (user['role'] ?? '') == 'Admin') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.security, color: SanitaColors.primary),
              const SizedBox(width: 8),
              Text('Akun Utama Dilindungi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark)),
            ],
          ),
          content: Text(
            'Akun Administrator Utama (${user['full_name']}) dilindungi dan tidak dapat dihapus dari sistem demi integritas aplikasi.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : SanitaColors.textDark),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.primary, foregroundColor: Colors.white),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_remove, color: SanitaColors.alertRed),
            const SizedBox(width: 8),
            Text('Hapus Akun Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun @${user['username']} (${user['full_name']}) dari database sistem?',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : SanitaColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Hapus Akun'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SanitaColors.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await AuthRepository().deleteUser(user['id'] ?? user['username']);
              _loadRegisteredUsers();

              if (!mounted) return;
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Akun @${user['username']} berhasil dihapus!'),
                  backgroundColor: SanitaColors.alertRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- FITUR DISPOSISI ADMIN (TERSIMPAN & REAL-TIME UPDATE) ---
  void _showAddAdminNoteDialog(LaporanModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController noteCtrl = TextEditingController(text: report.catatanDisposisi ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: SanitaColors.primary),
            const SizedBox(width: 8),
            Text('Disposisi Petugas (${report.id})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokasi: ${report.lokasi}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark)),
            const SizedBox(height: 8),
            Text('Instruksi / Catatan Tindak Lanjut Admin:', style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark),
              decoration: InputDecoration(
                hintText: 'Tuliskan tindakan penanganan sanitasi...',
                hintStyle: TextStyle(color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? SanitaColors.darkSurface : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final newNote = noteCtrl.text.trim();
              final updated = LaporanModel(
                id: report.id,
                jenisMasalah: report.jenisMasalah,
                lokasi: report.lokasi,
                keterangan: report.keterangan,
                fotoUrl: report.fotoUrl,
                status: report.status,
                urgensi: report.urgensi,
                reporterName: report.reporterName,
                createdAt: report.createdAt,
                integrityHMAC: report.integrityHMAC,
                catatanDisposisi: newNote,
              );

              final idx = _reportsList.indexWhere((r) => r.id == report.id);
              if (idx != -1) _reportsList[idx] = updated;

              final widgetIdx = widget.reports.indexWhere((r) => r.id == report.id);
              if (widgetIdx != -1) widget.reports[widgetIdx] = updated;

              if (widget.onEditReport != null) {
                widget.onEditReport!(updated);
              }
              await LaporanRepository().updateReport(updated);

              if (!mounted) return;
              Navigator.pop(ctx);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Disposisi untuk laporan ${report.id} berhasil diperbarui!'),
                  backgroundColor: SanitaColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Simpan Disposisi'),
          ),
        ],
      ),
    );
  }

  // --- MODAL EXPAND / FULLSCREEN BUKTI FOTO ---
  void _showFullImageDialog(LaporanModel report) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti Foto: ${report.jenisMasalah}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${report.id} • ${report.lokasi}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: report.fotoUrl!.startsWith('assets/')
                        ? Image.asset(report.fotoUrl!, fit: BoxFit.contain)
                        : Image.file(File(report.fotoUrl!), fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch, color: Colors.white70, size: 14),
                    SizedBox(width: 6),
                    Text('Cubit layar untuk memperbesar & geser foto', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DETAIL MODAL HASIL CEK SANITASI ---
  void _showChecklistDetailDialog(ChecklistModel check) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kriteria = check.kriteriaDetail ?? {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fact_check, color: SanitaColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hasil Cek (${check.id})',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lokasi: ${check.lokasi}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : SanitaColors.textDark)),
              const SizedBox(height: 2),
              Text('Inspektur / Pengunggah: @${check.inspectorUsername}', style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.primaryLight : SanitaColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Waktu Pengiriman: ${check.createdAt.toLocal().toString().substring(0, 19)}', style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: check.skorTerpenuhi == 6 ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(check.skorTerpenuhi == 6 ? Icons.check_circle : Icons.warning_amber, size: 16, color: check.skorTerpenuhi == 6 ? const Color(0xFF047857) : const Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Skor: ${check.skorTerpenuhi}/6 (${check.persentase.round()}%) • ${check.statusHasil}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: check.skorTerpenuhi == 6 ? const Color(0xFF047857) : const Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Rincian 6 Butir Pemeriksaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : SanitaColors.textDark)),
              const SizedBox(height: 6),
              ...kriteria.entries.map((entry) {
                final passed = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(passed ? Icons.check_circle : Icons.cancel, size: 16, color: passed ? SanitaColors.primary : SanitaColors.alertRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.key, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : SanitaColors.textDark)),
                      ),
                      Text(passed ? 'Terpenuhi' : 'Belum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: passed ? SanitaColors.primary : SanitaColors.alertRed)),
                    ],
                  ),
                );
              }),
              if (check.poinPerbaikan.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Catatan Rekomendasi / Tindak Lanjut:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : SanitaColors.textDark)),
                const SizedBox(height: 4),
                ...check.poinPerbaikan.map((p) => Text('• $p', style: const TextStyle(fontSize: 11, color: SanitaColors.alertRed))),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalReports = _reportsList.length;
    final pendingCount = _reportsList.where((r) => r.status.toLowerCase() == 'terkirim').length;
    final processCount = _reportsList.where((r) => r.status.toLowerCase() == 'diproses').length;
    final resolvedCount = _reportsList.where((r) => r.status.toLowerCase() == 'selesai').length;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : SanitaColors.background,
      appBar: AppBar(
        title: const Text('Panel Administrator SANITA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: SanitaColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SanitaColors.accentAmber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Kelola Laporan'),
            Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'Hasil Cek Sanitasi'),
            Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Database Akun'),
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Info Sistem'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Identitas Admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? SanitaColors.darkSurface : SanitaColors.primarySurface,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SanitaColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ribka Lusiana Harahap',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : SanitaColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Chip(
                            label: Text('ADMIN UTAMA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            backgroundColor: SanitaColors.primaryDark,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      Text(
                        'NIM: 243301631022 • Sanitasi & Lingkungan Kerja UNPRI',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ringkasan Counter Metrik
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? SanitaColors.darkCard : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricTile('Total Laporan', totalReports.toString(), SanitaColors.primary),
                _buildMetricTile('Pending', pendingCount.toString(), SanitaColors.alertRed),
                _buildMetricTile('Diproses', processCount.toString(), SanitaColors.accentAmber),
                _buildMetricTile('Selesai', resolvedCount.toString(), SanitaColors.primaryLight),
                _buildMetricTile('Cek Sanitasi', _checklistHistory.length.toString(), SanitaColors.infoBlue),
              ],
            ),
          ),

          // Tab Bar View Body (4 Tab)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: KELOLA LAPORAN (DILENGKAPI EDIT, HAPUS, DISPOSISI & PERBESAR FOTO)
                _buildReportManagementTab(isDark),

                // TAB 2: HASIL CEK SANITASI (HANYA BISA DILIHAT ADMIN)
                _buildChecklistResultsTab(isDark),

                // TAB 3: DATABASE PENGGUNA (DILENGKAPI EDIT & HAPUS)
                _buildUserDatabaseTab(isDark),

                // TAB 4: INFO SISTEM & STANDAR REGULASI
                _buildSystemInfoTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: SanitaColors.textMuted)),
      ],
    );
  }

  Widget _buildReportManagementTab(bool isDark) {
    final filtered = _reportsList.where((r) {
      if (_selectedStatusFilter == 'Semua') return true;
      return r.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Filter status chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Terkirim', 'Diproses', 'Selesai'].map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : SanitaColors.textDark),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: SanitaColors.primary,
                    backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
                    side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    onSelected: (val) {
                      setState(() {
                        _selectedStatusFilter = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Toolbar Fitur Pilih Banyak (Batch Selection)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                icon: Icon(_isBatchReports ? Icons.close : Icons.checklist_rtl, size: 16),
                label: Text(_isBatchReports ? 'Batal Pilih' : 'Pilih Banyak', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _isBatchReports = !_isBatchReports;
                    _selectedReportIds.clear();
                  });
                },
              ),
              if (_isBatchReports) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedReportIds.length == filtered.length) {
                        _selectedReportIds.clear();
                      } else {
                        _selectedReportIds.addAll(filtered.map((r) => r.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedReportIds.length == filtered.length ? 'Batal Semua' : 'Pilih Semua',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '${_selectedReportIds.length} dipilih',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Action Bar saat ada item dipilih
        if (_isBatchReports && _selectedReportIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? SanitaColors.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? SanitaColors.darkBorder : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: (status) => _batchUpdateReportStatus(status),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'terkirim', child: Text('Tandai Terkirim (Pending)')),
                      const PopupMenuItem(value: 'diproses', child: Text('Tandai Diproses')),
                      const PopupMenuItem(value: 'selesai', child: Text('Tandai Selesai')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: SanitaColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Ubah Status Terpilih', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SanitaColors.alertRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                  label: Text('Hapus (${_selectedReportIds.length})', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _batchDeleteReports,
                ),
              ],
            ),
          ),

        // Daftar Laporan dengan Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            color: SanitaColors.primary,
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Text(
                          'Tidak ada laporan pada status ini.',
                          style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final report = filtered[index];
                      return _buildAdminReportCard(report, isDark);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminReportCard(LaporanModel report, bool isDark) {
    Color statusColor;
    String statusLabel;
    switch (report.status.toLowerCase()) {
      case 'selesai':
        statusColor = SanitaColors.primary;
        statusLabel = 'SELESAI';
        break;
      case 'diproses':
        statusColor = SanitaColors.accentAmber;
        statusLabel = 'DIPROSES';
        break;
      default:
        statusColor = SanitaColors.alertRed;
        statusLabel = 'TERKIRIM (PENDING)';
    }

    final isSelected = _selectedReportIds.contains(report.id);

    return InkWell(
      onTap: _isBatchReports
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedReportIds.remove(report.id);
                } else {
                  _selectedReportIds.add(report.id);
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? SanitaColors.primary
                : (isDark ? SanitaColors.darkBorder : SanitaColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? (isDark ? SanitaColors.primaryDark.withOpacity(0.2) : const Color(0xFFE8F5E9))
            : (isDark ? SanitaColors.darkCard : Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_isBatchReports) ...[
                        Checkbox(
                          value: isSelected,
                          activeColor: SanitaColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedReportIds.add(report.id);
                              } else {
                                _selectedReportIds.remove(report.id);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(report.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.jenisMasalah,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : SanitaColors.textDark),
            ),
            const SizedBox(height: 4),

            // Baris Pengunggah, Lokasi, dan Urgensi
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: SanitaColors.primary),
                const SizedBox(width: 3),
                Text(
                  '@${report.reporterUsername}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? SanitaColors.primaryLight : SanitaColors.primary),
                ),
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                const SizedBox(width: 6),
                const Icon(Icons.location_on_outlined, size: 13, color: SanitaColors.textMuted),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    report.lokasi,
                    style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Urgensi: ${report.urgensi}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : SanitaColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.keterangan,
              style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkText : SanitaColors.textDark),
            ),

            // BUKTI FOTO LAPANGAN (BISA DI-EXPAND / DIPERBESAR OLEH ADMIN)
            if (report.fotoUrl != null && report.fotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showFullImageDialog(report),
                child: Container(
                  height: 135,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: report.fotoUrl!.startsWith('assets/')
                              ? Image.asset(report.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                              : Image.file(File(report.fotoUrl!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Ketuk untuk perbesar foto', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // CATATAN DISPOSISI ADMIN JIKA SUDAH DIISI
            if (report.catatanDisposisi != null && report.catatanDisposisi!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? SanitaColors.darkSurface : SanitaColors.primarySurface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SanitaColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.rate_review, size: 16, color: SanitaColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disposisi / Instruksi Admin:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report.catatanDisposisi!,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : SanitaColors.textDark, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 18),

            // Baris Tombol Aksi Admin (Edit, Hapus, Status, Catatan Disposisi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Kelola: Edit & Hapus
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19, color: SanitaColors.infoBlue),
                      tooltip: 'Edit Laporan',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditReportDialog(report),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 19, color: SanitaColors.alertRed),
                      tooltip: 'Hapus Laporan',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteReport(report),
                    ),
                  ],
                ),

                // Tombol Status & Disposisi
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (report.status.toLowerCase() != 'diproses' && report.status.toLowerCase() != 'selesai')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          side: const BorderSide(color: SanitaColors.accentAmber),
                        ),
                        icon: const Icon(Icons.autorenew, size: 13, color: SanitaColors.accentAmber),
                        label: const Text('Proses', style: TextStyle(fontSize: 11, color: SanitaColors.accentAmber)),
                        onPressed: () => _updateStatus(report.id, 'diproses'),
                      ),
                    if (report.status.toLowerCase() != 'selesai')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SanitaColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.check, size: 13, color: Colors.white),
                        label: const Text('Selesaikan', style: TextStyle(fontSize: 11, color: Colors.white)),
                        onPressed: () => _updateStatus(report.id, 'selesai'),
                      ),
                    IconButton(
                      icon: Icon(
                        report.catatanDisposisi != null && report.catatanDisposisi!.isNotEmpty
                            ? Icons.rate_review
                            : Icons.rate_review_outlined,
                        size: 19,
                        color: SanitaColors.primary,
                      ),
                      tooltip: 'Beri / Ubah Catatan Disposisi',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showAddAdminNoteDialog(report),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // --- TAB 2: HASIL CEK SANITASI (ARSIP INSPEKSI KHUSUS ADMIN) ---
  Widget _buildChecklistResultsTab(bool isDark) {
    if (_isLoadingChecklist) {
      return const Center(child: CircularProgressIndicator(color: SanitaColors.primary));
    }

    final query = _checklistSearchQuery.toLowerCase().trim();
    final filtered = _checklistHistory.where((c) {
      final bool isMS = c.skorTerpenuhi == 6;
      bool matchesStatus = true;
      if (_checklistStatusFilter == 'Memenuhi Syarat') {
        matchesStatus = isMS;
      } else if (_checklistStatusFilter == 'TMS / Perlu Perbaikan') {
        matchesStatus = !isMS;
      }

      bool matchesDate = true;
      if (_checklistDateFilter != null) {
        final cd = c.createdAt.toLocal();
        matchesDate = cd.year == _checklistDateFilter!.year &&
            cd.month == _checklistDateFilter!.month &&
            cd.day == _checklistDateFilter!.day;
      }

      bool matchesSearch = true;
      if (query.isNotEmpty) {
        matchesSearch = c.lokasi.toLowerCase().contains(query) ||
            c.id.toLowerCase().contains(query) ||
            c.inspectorUsername.toLowerCase().contains(query) ||
            c.statusHasil.toLowerCase().contains(query);
      }

      return matchesStatus && matchesDate && matchesSearch;
    }).toList();

    final msCount = _checklistHistory.where((c) => c.skorTerpenuhi == 6).length;
    final tmsCount = _checklistHistory.where((c) => c.skorTerpenuhi < 6).length;
    final bool isChecklistFiltered = _checklistDateFilter != null || _checklistStatusFilter != 'Semua';

    return Column(
      children: [
        // ==========================================
        // FILTER & SEARCH BAR UNTUK CEK SANITASI
        // ==========================================
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: isDark ? SanitaColors.darkCard : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar + Ikon Filter (Tidak langsung tampil semua agar UI bersih)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checklistSearchController,
                      onChanged: (val) {
                        setState(() {
                          _checklistSearchQuery = val;
                        });
                      },
                      style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi, ID cek, atau @username inspektur...',
                        hintStyle: TextStyle(color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 20, color: SanitaColors.textMuted),
                        suffixIcon: _checklistSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _checklistSearchController.clear();
                                  setState(() {
                                    _checklistSearchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? SanitaColors.darkSurface : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ikon Filter (Buka Modal Bottom Sheet Filter)
                  Material(
                    color: isChecklistFiltered
                        ? SanitaColors.primary
                        : (isDark ? SanitaColors.darkSurface : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showChecklistFilterBottomSheet(isDark, msCount, tmsCount),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChecklistFiltered
                                ? SanitaColors.primary
                                : (isDark ? SanitaColors.darkBorder : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: isChecklistFiltered ? Colors.white : (isDark ? Colors.white70 : SanitaColors.textDark),
                            ),
                            if (isChecklistFiltered)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: SanitaColors.accentAmber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Indikator ringkas jika filter aktif
              if (isChecklistFiltered) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_checklistDateFilter != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? SanitaColors.primaryDark.withOpacity(0.3) : SanitaColors.primarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: SanitaColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 11, color: SanitaColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              _checklistDatePreset == 'Pilih Tanggal'
                                  ? DateFormatter.toIndonesian(_checklistDateFilter!)
                                  : _checklistDatePreset,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SanitaColors.primary),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _checklistDateFilter = null;
                                  _checklistDatePreset = 'Semua Tanggal';
                                });
                              },
                              child: const Icon(Icons.close, size: 13, color: SanitaColors.primary),
                            ),
                          ],
                        ),
                      ),
                    if (_checklistStatusFilter != 'Semua')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? SanitaColors.primaryDark.withOpacity(0.3) : SanitaColors.primarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: SanitaColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.label_outline, size: 11, color: SanitaColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              _checklistStatusFilter,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SanitaColors.primary),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _checklistStatusFilter = 'Semua';
                                });
                              },
                              child: const Icon(Icons.close, size: 13, color: SanitaColors.primary),
                            ),
                          ],
                        ),
                      ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _checklistDateFilter = null;
                          _checklistDatePreset = 'Semua Tanggal';
                          _checklistStatusFilter = 'Semua';
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Reset',
                          style: TextStyle(fontSize: 11, color: SanitaColors.alertRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Toolbar Pilih Banyak (Batch Selection) & Info Hasil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(_isBatchChecklist ? Icons.close : Icons.checklist_rtl, size: 15),
                    label: Text(_isBatchChecklist ? 'Batal Pilih' : 'Pilih Banyak', style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      setState(() {
                        _isBatchChecklist = !_isBatchChecklist;
                        _selectedChecklistIds.clear();
                      });
                    },
                  ),
                  if (_isBatchChecklist) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedChecklistIds.length == filtered.length) {
                            _selectedChecklistIds.clear();
                          } else {
                            _selectedChecklistIds.addAll(filtered.map((c) => c.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedChecklistIds.length == filtered.length ? 'Batal Semua' : 'Pilih Semua',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    if (_selectedChecklistIds.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SanitaColors.alertRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
                        label: Text('Hapus (${_selectedChecklistIds.length})', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _batchDeleteChecklists,
                      ),
                  ] else ...[
                    Text(
                      '${filtered.length} dari ${_checklistHistory.length} data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ==========================================
        // DAFTAR KARTU HASIL CEK SANITASI
        // ==========================================
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            color: SanitaColors.primary,
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fact_check_outlined, size: 48, color: isDark ? SanitaColors.darkBorder : Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _checklistHistory.isEmpty
                                    ? 'Belum ada hasil cek sanitasi yang dikirim.'
                                    : 'Tidak ada hasil pemeriksaan yang sesuai dengan filter.',
                                style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              if (_checklistSearchQuery.isNotEmpty || _checklistStatusFilter != 'Semua' || _checklistDateFilter != null) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.filter_alt_off, size: 16),
                                  label: const Text('Reset Filter Pencarian', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    _checklistSearchController.clear();
                                    setState(() {
                                      _checklistSearchQuery = '';
                                      _checklistStatusFilter = 'Semua';
                                      _checklistDateFilter = null;
                                      _checklistDatePreset = 'Semua Tanggal';
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final c = filtered[idx];
                      final bool isMS = c.skorTerpenuhi == 6;
                      final isSelected = _selectedChecklistIds.contains(c.id);

                      return InkWell(
                        onTap: _isBatchChecklist
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedChecklistIds.remove(c.id);
                                  } else {
                                    _selectedChecklistIds.add(c.id);
                                  }
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? SanitaColors.primary
                                  : (isDark ? SanitaColors.darkBorder : SanitaColors.border),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          color: isSelected
                              ? (isDark ? SanitaColors.primaryDark.withOpacity(0.2) : const Color(0xFFE8F5E9))
                              : (isDark ? SanitaColors.darkCard : Colors.white),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (_isBatchChecklist) ...[
                                          Checkbox(
                                            value: isSelected,
                                            activeColor: SanitaColors.primary,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedChecklistIds.add(c.id);
                                                } else {
                                                  _selectedChecklistIds.remove(c.id);
                                                }
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(c.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primary)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isMS ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isMS ? 'MEMENUHI SYARAT (100%)' : 'TMS (${c.persentase.round()}%)',
                                        style: TextStyle(
                                          color: isMS ? const Color(0xFF047857) : const Color(0xFFB45309),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.lokasi,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : SanitaColors.textDark),
                                ),
                                const SizedBox(height: 4),

                                // Info Waktu Kirim & Inspektur
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 14, color: SanitaColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '@${c.inspectorUsername}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? SanitaColors.primaryLight : SanitaColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('•', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.access_time, size: 13, color: SanitaColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Dikirim: ${DateFormatter.toIndonesianDateTime(c.createdAt)}',
                                        style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Skor Kelaikan: ${c.skorTerpenuhi} dari 6 butir checklist terpenuhi.',
                                  style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkText : SanitaColors.textDark),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.list_alt, size: 15),
                                      label: const Text('Rincian 6 Kriteria', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _showChecklistDetailDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: SanitaColors.alertRed),
                                      tooltip: 'Hapus Catatan Hasil Cek',
                                      onPressed: () async {
                                        await SanitasiRepository().deleteChecklist(c.id);
                                        _loadChecklistHistory();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Catatan hasil cek ${c.id} dihapus.'),
                                              backgroundColor: SanitaColors.alertRed,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showChecklistFilterBottomSheet(bool isDark, int msCount, int tmsCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18, color: SanitaColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Filter Hasil Cek Sanitasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : SanitaColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (_checklistDateFilter != null || _checklistStatusFilter != 'Semua')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _checklistDateFilter = null;
                              _checklistDatePreset = 'Semua Tanggal';
                              _checklistStatusFilter = 'Semua';
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 12, color: SanitaColors.alertRed)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // SEKSI 1: RENTANG TANGGAL
                  Text(
                    'Rentang Tanggal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChecklistFilterOptionChip(
                        label: 'Semua Tanggal',
                        isSelected: _checklistDatePreset == 'Semua Tanggal',
                        icon: Icons.all_inclusive,
                        isDark: isDark,
                        onTap: () {
                          _setChecklistDatePreset('Semua Tanggal');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChecklistFilterOptionChip(
                        label: 'Hari Ini',
                        isSelected: _checklistDatePreset == 'Hari Ini',
                        icon: Icons.today,
                        isDark: isDark,
                        onTap: () {
                          _setChecklistDatePreset('Hari Ini');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChecklistFilterOptionChip(
                        label: 'Kemarin',
                        isSelected: _checklistDatePreset == 'Kemarin',
                        icon: Icons.history,
                        isDark: isDark,
                        onTap: () {
                          _setChecklistDatePreset('Kemarin');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChecklistFilterOptionChip(
                        label: _checklistDatePreset == 'Pilih Tanggal' && _checklistDateFilter != null
                            ? DateFormatter.toIndonesian(_checklistDateFilter!)
                            : 'Pilih Tanggal...',
                        isSelected: _checklistDatePreset == 'Pilih Tanggal',
                        icon: Icons.calendar_month,
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickChecklistDate();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // SEKSI 2: STATUS KELAYAKAN
                  Text(
                    'Status Kelayakan Sanitasi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChecklistFilterOptionChip(
                        label: 'Semua Status (${_checklistHistory.length})',
                        isSelected: _checklistStatusFilter == 'Semua',
                        icon: Icons.fact_check_outlined,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _checklistStatusFilter = 'Semua';
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChecklistFilterOptionChip(
                        label: 'Memenuhi Syarat / MS ($msCount)',
                        isSelected: _checklistStatusFilter == 'Memenuhi Syarat',
                        icon: Icons.check_circle_outline,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _checklistStatusFilter = 'Memenuhi Syarat';
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChecklistFilterOptionChip(
                        label: 'TMS / Perlu Perbaikan ($tmsCount)',
                        isSelected: _checklistStatusFilter == 'TMS / Perlu Perbaikan',
                        icon: Icons.warning_amber_rounded,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _checklistStatusFilter = 'TMS / Perlu Perbaikan';
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistFilterOptionChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? SanitaColors.primaryDark.withOpacity(0.3) : SanitaColors.primarySurface)
              : (isDark ? SanitaColors.darkSurface : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? SanitaColors.primary
                : (isDark ? SanitaColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? SanitaColors.primary : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? SanitaColors.primary : (isDark ? Colors.white : SanitaColors.textDark),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 14, color: SanitaColors.primary),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserDatabaseTab(bool isDark) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: SanitaColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _refreshAllData,
      color: SanitaColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _registeredUsers.length,
        itemBuilder: (ctx, idx) {
        final u = _registeredUsers[idx];
        final bool isAdmin = (u['username'] ?? '').toString().toLowerCase() == 'ribka' || (u['role'] ?? '') == 'Admin';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
          ),
          color: isDark ? SanitaColors.darkCard : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAdmin ? SanitaColors.primaryDark : SanitaColors.primarySurface,
                  foregroundColor: isAdmin ? Colors.white : SanitaColors.primary,
                  child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              u['full_name'] ?? 'Pengguna',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : SanitaColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            const Chip(
                              label: Text('ADMIN', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: SanitaColors.primary,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${u['username']} • ${u['role'] ?? 'Pengguna Terdaftar'}',
                        style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                      ),
                      if (u['email'] != null && (u['email'] as String).isNotEmpty)
                        Text(
                          'Email: ${u['email']}',
                          style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                        ),
                      if (u['phone'] != null && (u['phone'] as String).isNotEmpty)
                        Text(
                          'Telp: ${u['phone']}',
                          style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                        ),
                    ],
                  ),
                ),

                // Tombol Kelola Pengguna: Edit & Hapus
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19, color: SanitaColors.infoBlue),
                      tooltip: 'Edit Akun',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditUserDialog(u),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: isAdmin ? Colors.grey.shade400 : SanitaColors.alertRed,
                      ),
                      tooltip: isAdmin ? 'Akun Admin Dilindungi' : 'Hapus Akun',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteUser(u),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildSystemInfoTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      color: SanitaColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dasar Hukum & Standar K3 Sanitasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SanitaColors.textDark),
            ),
            const SizedBox(height: 8),
            _buildInfoTile('Permenkes No. 70 Tahun 2016', 'Standar dan Persyaratan Kesehatan Lingkungan Kerja Industri.', isDark),
            _buildInfoTile('Permenaker No. 5 Tahun 2018', 'Keselamatan dan Kesehatan Kerja Lingkungan Kerja.', isDark),
            _buildInfoTile('Kepmenkes No. 1405/Menkes/SK/XI/2002', 'Persyaratan Kesehatan Lingkungan Kerja Perkantoran dan Sekolah.', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkText : SanitaColors.textDark),
          ),
        ],
      ),
    );
  }
}