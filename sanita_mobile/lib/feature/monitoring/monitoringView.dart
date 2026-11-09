import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/repositories/monitoringRepository.dart';
import '../../core/utils/dateFormatter.dart';

class MonitoringView extends StatefulWidget {
  final VoidCallback onBackToHome;

  const MonitoringView({super.key, required this.onBackToHome});

  @override
  State<MonitoringView> createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  RekapSanitasiLingkungan? _rekap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await MonitoringRepository().getRekapSanitasiLingkungan();
      if (mounted) {
        setState(() {
          _rekap = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rekap = _rekap;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : SanitaColors.background,
      appBar: AppBar(
        title: const Text('Monitoring Sanitasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: isDark ? SanitaColors.darkSurface : SanitaColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToHome,
        ),
      ),
      body: _isLoading || rekap == null
          ? const Center(child: CircularProgressIndicator(color: SanitaColors.primary))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: SanitaColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // 1. BAGIAN AWAL: KESELURUHAN (AGREGAT)
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? SanitaColors.darkBorder : SanitaColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? SanitaColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              rekap.rataRataKepatuhan >= 80 ? Icons.verified : Icons.warning_amber_rounded,
                              color: rekap.rataRataKepatuhan >= 80 ? SanitaColors.primary : SanitaColors.accentAmber,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SanitaColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'AGREGAT KESELURUHAN',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: SanitaColors.primaryDark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Status Lingkungan Kerja',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rekap.statusKeseluruhan,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : SanitaColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rata-rata dari ${rekap.totalLokasiTerpantau} titik lokasi pemeriksaan harian',
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

                    const SizedBox(height: 16),

                    // Indeks Kepatuhan Sanitasi (6 Indikator Kampus)
                    Card(
                      color: isDark ? SanitaColors.darkCard : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Indeks Kepatuhan Sanitasi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : SanitaColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Kompilasi pemenuhan 6 indikator higienis',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${rekap.rataRataKepatuhan.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 6 Indikator Breakdown Progress Bar
                            ...rekap.persentaseIndikator.entries.map((entry) {
                              final val = (entry.value / 100.0).clamp(0.0, 1.0);
                              return _buildIndicatorBar(
                                entry.key,
                                val,
                                '${entry.value.toStringAsFixed(0)}%',
                                isDark,
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Laporan Metrics Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Laporan',
                            '${rekap.totalLaporan}',
                            isDark ? Colors.white : SanitaColors.textDark,
                            Icons.assignment_outlined,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Diproses',
                            '${rekap.laporanDiproses}',
                            SanitaColors.accentAmber,
                            Icons.pending_actions,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Selesai',
                            '${rekap.laporanSelesai}',
                            SanitaColors.primaryLight,
                            Icons.task_alt,
                            isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 2. BAGIAN RINCIAN: PER LOKASI TIAP HARINYA
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Sanitasi Per Lokasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : SanitaColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Perhitungan kepatuhan harian per titik lokasi kerja',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? SanitaColors.darkBorder : Colors.transparent),
                          ),
                          child: Text(
                            '${rekap.rincianPerLokasi.length} Lokasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Daftar Kartu Per Lokasi Harian
                    ...rekap.rincianPerLokasi.map((loc) => _buildLocationCard(loc, isDark)),

                    const SizedBox(height: 20),

                    // ==========================================
                    // 3. JADWAL RUTIN PEMELIHARAAN
                    // ==========================================
                    Card(
                      color: isDark ? SanitaColors.darkCard : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, color: SanitaColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Jadwal Pemeliharaan & Higiene Berkala',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : SanitaColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildScheduleItem('Pembersihan Tandon Air Utama', 'Minggu ke-1 Setiap Bulan', 'Selesai', isDark),
                            _buildScheduleItem('Inspeksi Saluran Drainase & PSN', 'Setiap Hari Jumat Pagi', 'Terjadwal', isDark),
                            _buildScheduleItem('Sterilisasi & Penggantian Filter AC', '2 Minggu Sekali', 'Terjadwal', isDark),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationCard(LokasiHarianStat loc, bool isDark) {
    final isGood = loc.persentase >= 80;
    final isWarning = loc.persentase >= 60 && loc.persentase < 80;

    final Color statusBg = isGood
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
        : (isWarning
            ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFFF8E1))
            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE)));

    final Color statusTextColor = isGood
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF2E7D32))
        : (isWarning
            ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFF57F17))
            : (isDark ? const Color(0xFFF87171) : const Color(0xFFC62828)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? SanitaColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Header Baris Lokasi & Tanggal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: SanitaColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        loc.lokasi,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : SanitaColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormatter.toIndonesian(loc.tanggal),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Baris Badge Skor Kepatuhan & Status K3
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${loc.skorTerpenuhi}/${loc.totalKondisi} Kriteria (${loc.persentase.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? SanitaColors.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? SanitaColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  loc.statusKelayakan,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Status 6 Kriteria (Chips Ceklis Hijau / Silang Merah)
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: loc.kriteria.entries.map((k) {
              final isOk = k.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isOk
                      ? (isDark ? const Color(0xFF064E3B).withOpacity(0.6) : const Color(0xFFE8F5E9))
                      : (isDark ? const Color(0xFF7F1D1D).withOpacity(0.6) : const Color(0xFFFFEBEE)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOk
                        ? (isDark ? const Color(0xFF047857) : const Color(0xFFA5D6A7))
                        : (isDark ? const Color(0xFFB91C1C) : const Color(0xFFEF9A9A)),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOk ? Icons.check_circle : Icons.cancel,
                      size: 12,
                      color: isOk ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      k.key,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : SanitaColors.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Footer: Pemeriksa & Laporan Aktif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: SanitaColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    'Inspektur: @${loc.inspectorUsername}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (loc.pendingReportsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        '${loc.pendingReportsCount} Laporan aktif',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorBar(String label, double value, String percent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : SanitaColors.textDark,
                ),
              ),
              Text(
                percent,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: isDark ? SanitaColors.darkBorder : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? SanitaColors.primaryLight : SanitaColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? SanitaColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String task, String schedule, String status, bool isDark) {
    final isDone = status == 'Selesai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                Text(
                  schedule,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDone
                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                  : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDone
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                  : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}