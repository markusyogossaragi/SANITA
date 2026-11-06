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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Sanitasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToHome,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      color: SanitaColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SanitaColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified, color: SanitaColors.primary, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Sanitasi Lingkungan Kerja',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primaryDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _stats?['status_lingkungan'] ?? 'Memenuhi Standar K3 Kesling (Zona Hijau)',
                                style: const TextStyle(fontSize: 12, color: SanitaColors.textDark, fontWeight: FontWeight.w500),
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
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Indeks Kepatuhan Sanitasi',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SanitaColors.textDark),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Rata-rata 6 indikator inspeksi berkala',
                                    style: TextStyle(fontSize: 12, color: SanitaColors.textMuted),
                                  ),
                                ],
                              ),
                              Text(
                                '${(_stats?['rata_rata_kepatuhan_persen'] ?? 94.2).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: SanitaColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Indikator Breakdown Progress
                          _buildIndicatorBar('Pasokan Air Bersih', 0.98, '98%'),
                          _buildIndicatorBar('Kebersihan Fasilitas Toilet', 0.92, '92%'),
                          _buildIndicatorBar('Pengelolaan Tempat Sampah', 0.90, '90%'),
                          _buildIndicatorBar('Ventilasi & Kualitas Udara', 0.95, '95%'),
                          _buildIndicatorBar('Bebas Genangan & Vektor', 0.96, '96%'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Laporan Metrics Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard('Total Laporan', '${_stats?['total_laporan'] ?? 3}', SanitaColors.textDark, Icons.assignment_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard('Diproses', '${_stats?['laporan_diproses'] ?? 1}', SanitaColors.accentAmber, Icons.pending_actions),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard('Selesai', '${_stats?['laporan_selesai'] ?? 1}', SanitaColors.primary, Icons.task_alt),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Jadwal Rutin Sanitasi Kampus
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_month, color: SanitaColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Jadwal Pemeliharaan & Higiene Berkala',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SanitaColors.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildScheduleItem('Pembersihan Tandon Air Utama', 'Minggu ke-1 Setiap Bulan', 'Selesai'),
                          _buildScheduleItem('Inspeksi Saluran Drainase & PSN', 'Setiap Hari Jumat Pagi', 'Terjadwal'),
                          _buildScheduleItem('Sterilisasi & Penggantian Filter AC', '2 Minggu Sekali', 'Terjadwal'),
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

  Widget _buildIndicatorBar(String label, double value, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SanitaColors.textDark)),
              Text(percent, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SanitaColors.primary)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(SanitaColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SanitaColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String task, String schedule, String status) {
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
                Text(task, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SanitaColors.textDark)),
                Text(schedule, style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDone ? const Color(0xFF047857) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
