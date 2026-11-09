import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/utils/dateFormatter.dart';

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

  List<LaporanModel> get _filteredReports {
    return widget.reports.where((r) {
      final matchesFilter = _selectedFilter == 'Semua' || r.status.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          r.jenisMasalah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.lokasi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.keterangan.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar riwayat laporan diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
                  color: Colors.grey.shade300,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SanitaColors.primary),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              report.jenisMasalah,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: SanitaColors.textDark),
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: SanitaColors.primary),
                const SizedBox(width: 4),
                Text(report.lokasi, style: const TextStyle(fontSize: 13, color: SanitaColors.textDark, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: SanitaColors.textMuted),
                const SizedBox(width: 4),
                Text(_formatRelativeTime(report.createdAt), style: const TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
              ],
            ),
            const SizedBox(height: 14),

            const Text('Deskripsi Kondisi:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: SanitaColors.textDark)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SanitaColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.keterangan,
                style: const TextStyle(fontSize: 13, color: SanitaColors.textDark, height: 1.4),
              ),
            ),
            if (report.fotoUrl != null && report.fotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Bukti Foto:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: SanitaColors.textDark)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: report.fotoUrl!.startsWith('assets/')
                    ? Image.asset(report.fotoUrl!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                    : Image.file(File(report.fotoUrl!), height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
              ),
            ],
            const SizedBox(height: 18),

            // Stepper Pelacakan
            const Text('Tahapan Tindak Lanjut:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: SanitaColors.textDark)),
            const SizedBox(height: 10),
            _buildTimelineStep(1, 'Laporan Masuk', 'Tercatat di sistem monitoring SANITA', true),
            _buildTimelineStep(2, 'Verifikasi Lapangan', 'Petugas kesling memeriksa titik lokasi', report.status != 'terkirim'),
            _buildTimelineStep(3, 'Tindakan Penanganan', 'Pembersihan / perbaikan sarana sedang berjalan', report.status == 'diproses' || report.status == 'selesai'),
            _buildTimelineStep(4, 'Selesai & Divalidasi', 'Kondisi sanitasi kembali memenuhi standar', report.status == 'selesai'),

            const SizedBox(height: 20),

            // Demo status toggle
            if (widget.onUpdateStatus != null) ...[
              Row(
                children: [
                  if (report.status != 'diproses')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onUpdateStatus!(report.id, 'diproses');
                          Navigator.pop(ctx);
                        },
                        child: const Text('Tandai Diproses', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  if (report.status != 'diproses') const SizedBox(width: 8),
                  if (report.status != 'selesai')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onUpdateStatus!(report.id, 'selesai');
                          Navigator.pop(ctx);
                        },
                        child: const Text('Tandai Selesai', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(int stepNum, String title, String subtitle, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isDone ? SanitaColors.primary : Colors.grey.shade300,
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
                    color: isDone ? SanitaColors.textDark : SanitaColors.textMuted,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
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

    return Scaffold(
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
                                const Text(
                                  'Riwayat Laporan',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: SanitaColors.primarySurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${filtered.length} ditemukan',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SanitaColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pantau status tindak lanjut penanganan sanitasi lingkungan kerja.',
                              style: TextStyle(fontSize: 12, color: SanitaColors.textMuted),
                            ),
                            const SizedBox(height: 14),

                            // Search input
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Cari kategori, lokasi, atau no. tiket...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
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
                                      label: Text(f, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? SanitaColors.primaryDark : SanitaColors.textDark)),
                                      selected: isSelected,
                                      backgroundColor: Colors.white,
                                      selectedColor: SanitaColors.primarySurface,
                                      side: BorderSide(color: isSelected ? SanitaColors.primary : SanitaColors.border),
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
                                      Icon(Icons.inbox_rounded, size: 52, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Tidak ada laporan yang sesuai.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: SanitaColors.textMuted,
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
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: SanitaColors.border),
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
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SanitaColors.primary),
                                                ),
                                                _buildStatusBadge(r.status),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              r.jenisMasalah,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SanitaColors.textDark),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 14, color: SanitaColors.textMuted),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    r.lokasi,
                                                    style: const TextStyle(fontSize: 12, color: SanitaColors.textMuted),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatRelativeTime(r.createdAt),
                                                  style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              r.keterangan,
                                              style: const TextStyle(fontSize: 13, color: SanitaColors.textDark, height: 1.3),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Lihat Detail Pelacakan →',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SanitaColors.primary.withOpacity(0.9)),
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
