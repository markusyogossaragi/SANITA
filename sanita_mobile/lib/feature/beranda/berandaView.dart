import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/repositories/monitoringRepository.dart';
import '../../core/theme/theme.dart';

class BerandaView extends StatefulWidget {
  final Function(int) onTabSelect;
  final int reportCount;
  final VoidCallback onOpenEdukasi;
  final VoidCallback onOpenMonitoring;

  const BerandaView({
    super.key,
    required this.onTabSelect,
    required this.reportCount,
    required this.onOpenEdukasi,
    required this.onOpenMonitoring,
  });

  @override
  State<BerandaView> createState() => _BerandaViewState();
}

class _BerandaViewState extends State<BerandaView> {
  int _currentTipIndex = 0;
  RekapSanitasiLingkungan? _rekap;

  @override
  void initState() {
    super.initState();
    _loadRekap();
  }

  Future<void> _loadRekap() async {
    try {
      final data = await MonitoringRepository().getRekapSanitasiLingkungan();
      if (mounted) {
        setState(() {
          _rekap = data;
        });
      }
    } catch (_) {}
  }

  final List<Map<String, String>> _tipsSanitasi = [
    {
      'title': 'Sirkulasi & Ventilasi Udara',
      'desc': 'Buka jendela atau aktifkan exhaust fan minimal 15 menit setiap pagi untuk mengganti udara pengap di ruang kerja.',
      'icon': 'air',
    },
    {
      'title': 'Kebersihan Fasilitas Cuci Tangan',
      'desc': 'Pastikan sabun cair dan air mengalir selalu tersedia di wastafel untuk mencegah transmisi kuman kontak fisik.',
      'icon': 'wash',
    },
    {
      'title': 'Pemilahan Tempat Sampah',
      'desc': 'Gunakan tempat sampah bertutup injak (pedal) agar tangan tetap steril, dan kosongkan wadah sebelum meluap.',
      'icon': 'delete_outline',
    },
    {
      'title': 'Cegah Genangan Air di Pantry',
      'desc': 'Segera seka percikan air di sekitar bak cuci piring guna mencegah lumut licin dan berkembangbiaknya serangga.',
      'icon': 'water_damage_outlined',
    },
  ];

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _loadRekap();
    if (mounted) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tipsSanitasi.length;
      });
    }
  }

  void _nextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _tipsSanitasi.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeTip = _tipsSanitasi[_currentTipIndex];
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SANITA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Sanitasi dan Lingkungan Kerja',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Halo, Sahabat SANITA!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Yuk, jaga tempat kerja tetap bersih, sehat, dan aman bersama.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Indeks Kepatuhan Sanitasi Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: widget.onOpenMonitoring,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? SanitaColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: SanitaColors.primarySurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.health_and_safety, color: SanitaColors.primary, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status Lingkungan Kerja',
                                        style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '${(_rekap?.rataRataKepatuhan ?? 86.7).toStringAsFixed(0)}% Kepatuhan Sanitasi',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _rekap != null
                                            ? '${_rekap!.totalLokasiTerpantau} Lokasi Terpantau • ${_rekap!.statusKeseluruhan}'
                                            : 'Perhitungan Terpusat 6 Indikator Higiene',
                                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: SanitaColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Menu Utama Section Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menu Utama',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : SanitaColors.textDark,
                              ),
                            ),
                            Text(
                              '4 Layanan Sanitasi',
                              style: TextStyle(fontSize: 12, color: SanitaColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 4 Cards Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.25,
                          children: [
                            _buildMenuCard(
                              icon: Icons.checklist_rounded,
                              iconColor: SanitaColors.primary,
                              title: 'Cek Sanitasi',
                              desc: '6 kriteria inspeksi tempat kerja',
                              onTap: () => widget.onTabSelect(1), // Tab Cek
                            ),
                            _buildMenuCard(
                              icon: Icons.campaign_rounded,
                              iconColor: SanitaColors.alertRed,
                              title: 'Lapor Lingkungan',
                              desc: 'Laporkan kendala & sarana',
                              onTap: () => widget.onTabSelect(2), // Tab Lapor
                            ),
                            _buildMenuCard(
                              icon: Icons.menu_book_rounded,
                              iconColor: SanitaColors.infoBlue,
                              title: 'Edukasi Kesling',
                              desc: 'Pedoman kesehatan lingkungan',
                              onTap: widget.onOpenEdukasi,
                            ),
                            _buildMenuCard(
                              icon: Icons.bar_chart_rounded,
                              iconColor: SanitaColors.accentAmber,
                              title: 'Monitoring',
                              desc: 'Analisis kepatuhan & statistik',
                              onTap: widget.onOpenMonitoring,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Tip Kesling Harian Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? SanitaColors.darkCard : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? SanitaColors.darkBorder : const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, size: 18, color: isDark ? SanitaColors.accentAmber : const Color(0xFF16A34A)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tip Sanitasi Harian',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? SanitaColors.primaryLight : const Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.refresh, size: 16, color: isDark ? SanitaColors.primaryLight : const Color(0xFF16A34A)),
                                    onPressed: _nextTip,
                                    tooltip: 'Tip Berikutnya',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                activeTip['title']!,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : SanitaColors.textDark),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activeTip['desc']!,
                                style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : const Color(0xFF334155), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Ringkasan Aktivitas Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ringkasan Aktivitas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : SanitaColors.textDark,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? SanitaColors.primary.withOpacity(0.2) : SanitaColors.primarySurface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${widget.reportCount} laporan aktif',
                                        style: TextStyle(
                                          color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Mulai dari pemeriksaan sanitasi atau periksa riwayat laporan masalah lingkungan kerja yang sedang diproses.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => widget.onTabSelect(1), // Tab Cek Sanitasi
                                        child: const Text('Cek Sanitasi', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => widget.onTabSelect(3), // Tab Riwayat
                                        child: const Text('Riwayat Laporan', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
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

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? SanitaColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : SanitaColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}