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

  // Filter per tanggal (default reset per hari: Hari Ini)
  DateTime? _selectedDate;
  String _datePreset = 'Hari Ini';

  // Search lokasi / inspektur
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset per hari: selalu mulai dari tanggal hari ini saat halaman dibuka
    _selectedDate = DateTime.now();
    _datePreset = 'Hari Ini';
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await MonitoringRepository().getRekapSanitasiLingkungan(
        targetDate: _selectedDate,
      );
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

  void _setDatePreset(String preset, [DateTime? customDate]) {
    setState(() {
      _datePreset = preset;
      if (preset == 'Hari Ini') {
        _selectedDate = DateTime.now();
      } else if (preset == 'Kemarin') {
        _selectedDate = DateTime.now().subtract(const Duration(days: 1));
      } else if (preset == 'Semua Riwayat') {
        _selectedDate = null;
      } else if (customDate != null) {
        _selectedDate = customDate;
      }
    });
    _loadStats();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: 'PILIH TANGGAL MONITORING',
    );

    if (picked != null) {
      _setDatePreset('Pilih Tanggal', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rekap = _rekap;
    final bool isFiltered = _datePreset != 'Hari Ini';

    // Filter per pencarian nama lokasi atau inspektur
    final filteredLocations = (rekap?.rincianPerLokasi ?? []).where((loc) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return loc.lokasi.toLowerCase().contains(q) ||
          loc.inspectorUsername.toLowerCase().contains(q) ||
          loc.statusKelayakan.toLowerCase().contains(q);
    }).toList();

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
      body: Column(
        children: [
          // ==========================================
          // BILAH PENCARIAN & IKON FILTER TANGGAL
          // ==========================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? SanitaColors.darkCard : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Pencarian + Ikon Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari titik lokasi atau @inspektur...',
                          hintStyle: TextStyle(color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 20, color: SanitaColors.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
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
                    // Ikon Filter (Tidak langsung tampil semua chip agar UI rapi & bersih)
                    Material(
                      color: isFiltered
                          ? SanitaColors.primary
                          : (isDark ? SanitaColors.darkSurface : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showFilterBottomSheet(isDark),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFiltered
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
                                color: isFiltered ? Colors.white : (isDark ? Colors.white70 : SanitaColors.textDark),
                              ),
                              if (isFiltered)
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

                // Hanya tampil ringkas jika filter kustom aktif (TIDAK langsung tampil semua chip)
                if (isFiltered) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? SanitaColors.primaryDark.withOpacity(0.3) : SanitaColors.primarySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SanitaColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: SanitaColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _datePreset == 'Pilih Tanggal' && _selectedDate != null
                                  ? 'Tanggal: ${DateFormatter.toIndonesian(_selectedDate!)}'
                                  : 'Filter: $_datePreset',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SanitaColors.primary),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _setDatePreset('Hari Ini'),
                              child: const Icon(Icons.close, size: 14, color: SanitaColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _setDatePreset('Hari Ini'),
                        child: Text(
                          'Reset Harian',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ==========================================
          // KONTEN MONITORING DENGAN REFRESH INDICATOR
          // ==========================================
          Expanded(
            child: _isLoading || rekap == null
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
                          // ------------------------------------------
                          // 1. BAGIAN AWAL: KESELURUHAN (AGREGAT HARIAN)
                          // ------------------------------------------
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
                                    rekap.totalLokasiTerpantau == 0
                                        ? Icons.info_outline
                                        : (rekap.rataRataKepatuhan >= 80 ? Icons.verified : Icons.warning_amber_rounded),
                                    color: rekap.totalLokasiTerpantau == 0
                                        ? SanitaColors.textMuted
                                        : (rekap.rataRataKepatuhan >= 80 ? SanitaColors.primary : SanitaColors.accentAmber),
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
                                            child: Text(
                                              'AGREGAT ${_datePreset.toUpperCase()}',
                                              style: const TextStyle(
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
                                        rekap.totalLokasiTerpantau > 0
                                            ? 'Rata-rata dari ${rekap.totalLokasiTerpantau} titik lokasi pemeriksaan pada tanggal ini'
                                            : 'Belum ada data pemeriksaan checklist yang tercatat pada tanggal ini.',
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

                          // ------------------------------------------
                          // 2. BAGIAN RINCIAN: PER LOKASI TIAP HARINYA
                          // ------------------------------------------
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
                                    'Pemeriksaan 6 kriteria sanitasi pada periode tanggal ini',
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
                                  '${filteredLocations.length} Lokasi',
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

                          if (filteredLocations.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? SanitaColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.fact_check_outlined, size: 48, color: isDark ? SanitaColors.darkBorder : Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada lokasi yang cocok dengan kata kunci "$_searchQuery".'
                                        : 'Belum ada riwayat cek sanitasi pada tanggal ini.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Text('Hapus Pencarian', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else
                            ...filteredLocations.map((loc) => _buildLocationCard(loc, isDark)),

                          const SizedBox(height: 20),

                          // ------------------------------------------
                          // 3. JADWAL RUTIN PEMELIHARAAN
                          // ------------------------------------------
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
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          'Filter Tanggal Inspeksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : SanitaColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    if (_datePreset != 'Hari Ini')
                      TextButton(
                        onPressed: () {
                          _setDatePreset('Hari Ini');
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset Harian', style: TextStyle(fontSize: 12, color: SanitaColors.alertRed)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih rentang tanggal untuk melihat kepatuhan sanitasi per lokasi.',
                  style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                ),
                const SizedBox(height: 14),
                _buildModalFilterOption(
                  title: 'Hari Ini (Reset Harian)',
                  subtitle: 'Pantau hasil sanitasi shift/inspeksi hari ini',
                  icon: Icons.today,
                  isSelected: _datePreset == 'Hari Ini',
                  isDark: isDark,
                  onTap: () {
                    _setDatePreset('Hari Ini');
                    Navigator.pop(ctx);
                  },
                ),
                _buildModalFilterOption(
                  title: 'Kemarin',
                  subtitle: 'Rekap audit sanitasi 1 hari sebelumnya',
                  icon: Icons.history,
                  isSelected: _datePreset == 'Kemarin',
                  isDark: isDark,
                  onTap: () {
                    _setDatePreset('Kemarin');
                    Navigator.pop(ctx);
                  },
                ),
                _buildModalFilterOption(
                  title: _datePreset == 'Pilih Tanggal' && _selectedDate != null
                      ? 'Tanggal: ${DateFormatter.toIndonesian(_selectedDate!)}'
                      : 'Pilih Tanggal Tertentu...',
                  subtitle: 'Tentukan tanggal audit secara manual via kalender',
                  icon: Icons.calendar_month,
                  isSelected: _datePreset == 'Pilih Tanggal',
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickCustomDate();
                  },
                ),
                _buildModalFilterOption(
                  title: 'Semua Riwayat',
                  subtitle: 'Tampilkan seluruh riwayat tanpa batasan tanggal',
                  icon: Icons.all_inclusive,
                  isSelected: _datePreset == 'Semua Riwayat',
                  isDark: isDark,
                  onTap: () {
                    _setDatePreset('Semua Riwayat');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? SanitaColors.primaryDark.withOpacity(0.3) : SanitaColors.primarySurface)
              : (isDark ? SanitaColors.darkSurface : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SanitaColors.primary
                : (isDark ? SanitaColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? SanitaColors.primary : (isDark ? Colors.white60 : Colors.grey.shade600)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? SanitaColors.primary : (isDark ? Colors.white : SanitaColors.textDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 18, color: SanitaColors.primary),
          ],
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
                DateFormatter.toIndonesianDateTime(loc.tanggal),
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
