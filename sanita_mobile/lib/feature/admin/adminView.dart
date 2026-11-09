import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/repositories/authRepository.dart';

class AdminDashboardView extends StatefulWidget {
  final VoidCallback onBack;
  final List<LaporanModel> reports;
  final Function(String id, String newStatus)? onUpdateStatus;

  const AdminDashboardView({
    super.key,
    required this.onBack,
    required this.reports,
    this.onUpdateStatus,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _registeredUsers = [];
  bool _isLoadingUsers = true;
  String _selectedStatusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRegisteredUsers();
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

  void _updateStatus(String id, String newStatus) {
    if (widget.onUpdateStatus != null) {
      widget.onUpdateStatus!(id, newStatus);
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status laporan $id berhasil diubah menjadi: ${newStatus.toUpperCase()}'),
        backgroundColor: SanitaColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddAdminNoteDialog(LaporanModel report) {
    final TextEditingController noteCtrl = TextEditingController(text: report.keterangan);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: SanitaColors.primary),
            const SizedBox(width: 8),
            Text('Disposisi Petugas (${report.id})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokasi: ${report.lokasi}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Instruksi / Catatan Tindak Lanjut Admin:', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tuliskan tindakan penanganan sanitasi...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Disposisi tindakan sanitasi berhasil dicatat!'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalReports = widget.reports.length;
    final pendingCount = widget.reports.where((r) => r.status.toLowerCase() == 'terkirim').length;
    final processCount = widget.reports.where((r) => r.status.toLowerCase() == 'diproses').length;
    final resolvedCount = widget.reports.where((r) => r.status.toLowerCase() == 'selesai').length;

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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: 'Kelola Laporan'),
            Tab(icon: Icon(Icons.people_alt_outlined, size: 20), text: 'Database Akun'),
            Tab(icon: Icon(Icons.admin_panel_settings_outlined, size: 20), text: 'Info Sistem'),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Ribka Lusiana Harahap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(width: 6),
                          Chip(
                            label: Text('ADMIN UTAMA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            backgroundColor: SanitaColors.primaryDark,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      Text('NIM: 243301631022 • Sanitasi & Lingkungan Kerja UNPRI', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
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
                _buildMetricTile('Total Akun', _registeredUsers.length.toString(), SanitaColors.infoBlue),
              ],
            ),
          ),

          // Tab Bar View Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: KELOLA LAPORAN
                _buildReportManagementTab(isDark),

                // TAB 2: DATABASE PENGGUNA
                _buildUserDatabaseTab(isDark),

                // TAB 3: INFO SISTEM & STANDAR
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
    final filtered = widget.reports.where((r) {
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
                    label: Text(status, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    selectedColor: SanitaColors.primary,
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

        // Daftar Laporan
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('Tidak ada laporan pada status ini.', style: TextStyle(color: SanitaColors.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final report = filtered[index];
                    return _buildAdminReportCard(report, isDark);
                  },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
      color: isDark ? SanitaColors.darkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(report.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primary)),
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
            Text(report.jenisMasalah, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: SanitaColors.textMuted),
                const SizedBox(width: 4),
                Expanded(child: Text(report.lokasi, style: const TextStyle(fontSize: 12, color: SanitaColors.textMuted))),
                Text('Urgensi: ${report.urgensi}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(report.keterangan, style: const TextStyle(fontSize: 12)),
            
            // Bukti Foto jika ada
            if (report.fotoUrl != null && report.fotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: report.fotoUrl!.startsWith('assets/')
                        ? Image.asset(report.fotoUrl!, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                        : Image.file(File(report.fotoUrl!), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Bukti Foto Lapangan Terlampir', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                ],
              ),
            ],

            const Divider(height: 18),

            // Baris Tombol Aksi Admin
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, size: 14, color: SanitaColors.primary),
                    const SizedBox(width: 4),
                    const Text('HMAC Verified', style: TextStyle(fontSize: 10, color: SanitaColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    if (report.status.toLowerCase() != 'diproses' && report.status.toLowerCase() != 'selesai')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                        icon: const Icon(Icons.autorenew, size: 14, color: SanitaColors.accentAmber),
                        label: const Text('Proses', style: TextStyle(fontSize: 11, color: SanitaColors.accentAmber)),
                        onPressed: () => _updateStatus(report.id, 'diproses'),
                      ),
                    if (report.status.toLowerCase() != 'selesai')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.primary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                        icon: const Icon(Icons.check, size: 14, color: Colors.white),
                        label: const Text('Selesaikan', style: TextStyle(fontSize: 11, color: Colors.white)),
                        onPressed: () => _updateStatus(report.id, 'selesai'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined, size: 18),
                      tooltip: 'Beri Catatan Disposisi',
                      onPressed: () => _showAddAdminNoteDialog(report),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDatabaseTab(bool isDark) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: SanitaColors.primary));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registeredUsers.length,
      itemBuilder: (ctx, idx) {
        final u = _registeredUsers[idx];
        final bool isAdmin = (u['username'] ?? '').toString().toLowerCase() == 'ribka' || (u['role'] ?? '') == 'Admin';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
          color: isDark ? SanitaColors.darkCard : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdmin ? SanitaColors.primaryDark : SanitaColors.primarySurface,
              foregroundColor: isAdmin ? Colors.white : SanitaColors.primary,
              child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
            ),
            title: Row(
              children: [
                Expanded(child: Text(u['full_name'] ?? 'Pengguna', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                if (isAdmin)
                  const Chip(
                    label: Text('ADMIN', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: SanitaColors.primary,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('@${u['username']} • Role: ${u['role'] ?? 'Pengguna Terdaftar'}', style: const TextStyle(fontSize: 11)),
                if (u['email'] != null && (u['email'] as String).isNotEmpty)
                  Text('Email: ${u['email']}', style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                if (u['phone'] != null && (u['phone'] as String).isNotEmpty)
                  Text('Telp: ${u['phone']}', style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemInfoTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dasar Hukum & Standar K3 Sanitasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInfoTile('Permenkes No. 70 Tahun 2016', 'Standar dan Persyaratan Kesehatan Lingkungan Kerja Industri.'),
          _buildInfoTile('Permenaker No. 5 Tahun 2018', 'Keselamatan dan Kesehatan Kerja Lingkungan Kerja.'),
          _buildInfoTile('Kepmenkes No. 1405/Menkes/SK/XI/2002', 'Persyaratan Kesehatan Lingkungan Kerja Perkantoran dan Kampus.'),
          const SizedBox(height: 16),
          const Text('Integritas Kriptografi & Basis Data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInfoTile('HMAC-SHA256 Anti-Tamper', 'Setiap tiket laporan dijamin keaslian isinya dari manipulasi.'),
          _buildInfoTile('Zero-Trust Architecture', 'Verifikasi identitas berkesinambungan dan audit log real-time.'),
          _buildInfoTile('Multi-Tier Storage', 'Sinkronisasi hybrid: PostgreSQL Cloud & Local Encrypted Database.'),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SanitaColors.primarySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SanitaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primaryDark)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 11, color: SanitaColors.textDark)),
        ],
      ),
    );
  }
}

