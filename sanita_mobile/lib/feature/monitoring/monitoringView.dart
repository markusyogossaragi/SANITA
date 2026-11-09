import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/datasources/apiDataSource.dart';

class MonitoringView extends StatefulWidget {
  final VoidCallback onBackToHome;

  const MonitoringView({super.key, required this.onBackToHome});

  @override
  State<MonitoringView> createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiDataSource().get('/monitoring/stats');
      setState(() {
        _stats = res['data'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _stats = {
          'total_laporan': 3,
          'laporan_terkirim': 1,
          'laporan_diproses': 1,
          'laporan_selesai': 1,
          'rata_rata_kepatuhan_persen': 94.2,
          'status_sistem': 'Normal & Terpantau',
          'status_lingkungan': 'Memenuhi Standar K3 Kesling (Zona Hijau)',
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      body: _isLoading
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
                    // Status Lingkungan Badge Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? SanitaColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.verified, color: SanitaColors.primary, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Sanitasi Lingkungan Kerja',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _stats?['status_lingkungan'] ?? 'Memenuhi Standar K3 Kesling (Zona Hijau)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : SanitaColors.textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kepatuhan Card
                    Card(
                      color: isDark ? SanitaColors.darkCard : Colors.white,
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
                                      'Rata-rata 6 indikator inspeksi berkala',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(_stats?['rata_rata_kepatuhan_persen'] ?? 94.2).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Indikator Breakdown Progress
                            _buildIndicatorBar('Pasokan Air Bersih', 0.98, '98%', isDark),
                            _buildIndicatorBar('Kebersihan Fasilitas Toilet', 0.92, '92%', isDark),
                            _buildIndicatorBar('Pengelolaan Tempat Sampah', 0.90, '90%', isDark),
                            _buildIndicatorBar('Ventilasi & Kualitas Udara', 0.95, '95%', isDark),
                            _buildIndicatorBar('Bebas Genangan & Vektor', 0.96, '96%', isDark),
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
                            '${_stats?['total_laporan'] ?? 3}',
                            isDark ? Colors.white : SanitaColors.textDark,
                            Icons.assignment_outlined,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Diproses',
                            '${_stats?['laporan_diproses'] ?? 1}',
                            SanitaColors.accentAmber,
                            Icons.pending_actions,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Selesai',
                            '${_stats?['laporan_selesai'] ?? 1}',
                            SanitaColors.primaryLight,
                            Icons.task_alt,
                            isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Jadwal Rutin Sanitasi Kampus
                    Card(
                      color: isDark ? SanitaColors.darkCard : Colors.white,
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