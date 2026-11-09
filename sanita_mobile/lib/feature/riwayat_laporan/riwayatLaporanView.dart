import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/utils/dateFormatter.dart';
import '../../core/repositories/laporanRepository.dart';

class RiwayatLaporanView extends StatefulWidget {
  final VoidCallback onBackToHome;
  final List<LaporanModel> reports;
  final Function(String id, String newStatus)? onUpdateStatus;

  const RiwayatLaporanView({
    super.key,
    required this.onBackToHome,
    required this.reports,
    this.onUpdateStatus,
  });

  @override
  State<RiwayatLaporanView> createState() => _RiwayatLaporanViewState();
}

class _RiwayatLaporanViewState extends State<RiwayatLaporanView> {
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void didUpdateWidget(covariant RiwayatLaporanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {});
  }

  List<LaporanModel> get _filteredReports {
    return widget.reports.where((r) {
      final matchesFilter = _selectedFilter == 'Semua' || r.status.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          r.jenisMasalah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.lokasi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.reporterUsername.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.keterangan.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    final fresh = await LaporanRepository().getReports();
    if (mounted) {
      setState(() {
        widget.reports.clear();
        widget.reports.addAll(fresh);
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  String _formatRelativeTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return DateFormatter.toIndonesian(date);
    } catch (_) {
      return isoString;
    }
  }

  void _showReportDetail(LaporanModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = report.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? SanitaColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? SanitaColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report.id,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                      ),
                    ),
                    _buildStatusBadge(currentStatus),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  report.jenisMasalah,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.person_outline, size: 15, color: isDark ? SanitaColors.primaryLight : SanitaColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '@${report.reporterUsername}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, size: 15, color: isDark ? SanitaColors.primaryLight : SanitaColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.lokasi,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : SanitaColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, size: 14, color: SanitaColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_formatRelativeTime(report.createdAt), style: const TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'Deskripsi Kondisi:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? SanitaColors.darkSurface : SanitaColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                  ),
                  child: Text(
                    report.keterangan,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? SanitaColors.darkText : SanitaColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
                if (report.catatanDisposisi != null && report.catatanDisposisi!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Instruksi Disposisi Admin:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : SanitaColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? SanitaColors.darkSurface : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SanitaColors.primary.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.rate_review, size: 16, color: SanitaColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.catatanDisposisi!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : SanitaColors.primaryDark,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (report.fotoUrl != null && report.fotoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Bukti Foto:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : SanitaColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: report.fotoUrl!.startsWith('assets/')
                        ? Image.asset(report.fotoUrl!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                        : Image.file(File(report.fotoUrl!), height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                  ),
                ],
                const SizedBox(height: 18),

                // Stepper Pelacakan Real-Time
                Text(
                  'Tahapan Tindak Lanjut:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTimelineStep(1, 'Laporan Masuk', 'Tercatat di sistem monitoring SANITA', true, isDark),
                _buildTimelineStep(2, 'Verifikasi Lapangan', 'Petugas kesling memeriksa titik lokasi', currentStatus.toLowerCase() != 'terkirim', isDark),
                _buildTimelineStep(3, 'Tindakan Penanganan', 'Pembersihan / perbaikan sarana sedang berjalan', currentStatus.toLowerCase() == 'diproses' || currentStatus.toLowerCase() == 'selesai', isDark),
                _buildTimelineStep(4, 'Selesai & Divalidasi', 'Kondisi sanitasi kembali memenuhi standar', currentStatus.toLowerCase() == 'selesai', isDark),

                const SizedBox(height: 18),

                // Info Status Pelacakan (Admin Only Management)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? SanitaColors.darkSurface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? SanitaColors.darkBorder : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pembaruan status & disposisi penanganan ditangani langsung oleh Administrator Sanitasi.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? SanitaColors.darkTextMuted : const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep(int stepNum, String title, String subtitle, bool isDone, [bool isDark = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isDone ? SanitaColors.primary : (isDark ? SanitaColors.darkBorder : Colors.grey.shade300),
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text('$stepNum', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                    color: isDone ? (isDark ? Colors.white : SanitaColors.textDark) : (isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                  ),
                ),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : SanitaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // HEADER STATIS (Posisi Tetap di Atas)
            // ==========================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [SanitaColors.primaryDark, SanitaColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x281B6E4E),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SANITA',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Sanitasi dan Lingkungan Kerja',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Halo, Sahabat SANITA!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Yuk, jaga tempat kerja tetap bersih, sehat, dan aman.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ==========================================
            // KONTEN SCROLLABLE DENGAN PULL-TO-REFRESH
            // ==========================================
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: SanitaColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back to Home Link
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: widget.onBackToHome,
                            icon: const Icon(Icons.arrow_back, size: 16, color: SanitaColors.primary),
                            label: const Text(
                              'Kembali ke Beranda',
                              style: TextStyle(color: SanitaColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Riwayat Laporan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : SanitaColors.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? SanitaColors.darkBorder : Colors.transparent),
                                  ),
                                  child: Text(
                                    '${filtered.length} ditemukan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pantau status tindak lanjut penanganan sanitasi lingkungan kerja.',
                              style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                            ),
                            const SizedBox(height: 14),

                            // Search input
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Cari kategori, lokasi, atau no. tiket...',
                                hintStyle: TextStyle(color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400, fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 20, color: SanitaColors.textMuted),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['Semua', 'Terkirim', 'Diproses', 'Selesai'].map((f) {
                                  final isSelected = _selectedFilter == f;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: FilterChip(
                                      label: Text(
                                        f,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? (isDark ? Colors.white : SanitaColors.primaryDark)
                                              : (isDark ? Colors.white70 : SanitaColors.textDark),
                                        ),
                                      ),
                                      selected: isSelected,
                                      backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
                                      selectedColor: isDark ? SanitaColors.primaryDark : SanitaColors.primarySurface,
                                      side: BorderSide(color: isSelected ? SanitaColors.primary : (isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedFilter = f;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (filtered.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_rounded, size: 52, color: isDark ? SanitaColors.darkBorder : Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tidak ada laporan yang sesuai.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final r = filtered[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => _showReportDetail(r),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark ? SanitaColors.darkCard : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  r.id,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                                  ),
                                                ),
                                                _buildStatusBadge(r.status),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              r.jenisMasalah,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark ? Colors.white : SanitaColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                               children: [
                                                 const Icon(Icons.person_outline, size: 14, color: SanitaColors.primary),
                                                 const SizedBox(width: 3),
                                                 Text(
                                                   '@${r.reporterUsername}',
                                                   style: TextStyle(
                                                     fontSize: 11,
                                                     fontWeight: FontWeight.bold,
                                                     color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                                   ),
                                                 ),
                                                 const SizedBox(width: 6),
                                                 Text('•', style: TextStyle(color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted, fontSize: 11)),
                                                 const SizedBox(width: 6),
                                                 const Icon(Icons.location_on_outlined, size: 13, color: SanitaColors.textMuted),
                                                 const SizedBox(width: 3),
                                                 Expanded(
                                                   child: Text(
                                                     r.lokasi,
                                                     style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                                                     overflow: TextOverflow.ellipsis,
                                                   ),
                                                 ),
                                                 const SizedBox(width: 6),
                                                 Text(
                                                   _formatRelativeTime(r.createdAt),
                                                   style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                                                 ),
                                               ],
                                             ),
                                            const SizedBox(height: 8),
                                            Text(
                                              r.keterangan,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? SanitaColors.darkText : SanitaColors.textDark,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Lihat Detail Pelacakan →',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primary.withOpacity(0.9),
                                                  ),
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

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'selesai':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        label = 'SELESAI';
        break;
      case 'diproses':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'DIPROSES';
        break;
      case 'terkirim':
      default:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'TERKIRIM';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}