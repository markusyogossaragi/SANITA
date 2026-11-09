import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/datasources/apiDataSource.dart';

class CekSanitasiView extends StatefulWidget {
  final VoidCallback onBackToHome;

  const CekSanitasiView({super.key, required this.onBackToHome});

  @override
  State<CekSanitasiView> createState() => _CekSanitasiViewState();
}

class _CekSanitasiViewState extends State<CekSanitasiView> {
  // Input lokasi bebas: default kosong, placeholder abu-abu "Masukkan nama lokasi"
  final TextEditingController _lokasiController = TextEditingController();

  // 6 Butir Kriteria Pemeriksaan: DEFAULT = BELUM TERISI (null)
  bool? _airBersih;
  bool? _toiletBersih;
  bool? _tempatSampah;
  bool? _ventilasiUdara;
  bool? _bebasGenangan;
  bool? _kebersihanArea;

  bool _showResult = false;
  bool _isLoading = false;
  Map<String, dynamic>? _evalResult;

  final List<String> _quickLocations = [
    'Kantin UNPRI',
    'Toilet Barat Lt. 2',
    'Pantry Dosen',
    'Laboratorium Kesling',
    'Perpustakaan Lt. 3',
    'Area Parkir Kampus',
  ];

  /// Jumlah butir yang sudah diisi (tidak null)
  int get _filledCount {
    int c = 0;
    if (_airBersih != null) c++;
    if (_toiletBersih != null) c++;
    if (_tempatSampah != null) c++;
    if (_ventilasiUdara != null) c++;
    if (_bebasGenangan != null) c++;
    if (_kebersihanArea != null) c++;
    return c;
  }

  /// Jumlah butir yang bernilai Memenuhi (true)
  int get _checkedCount {
    int c = 0;
    if (_airBersih == true) c++;
    if (_toiletBersih == true) c++;
    if (_tempatSampah == true) c++;
    if (_ventilasiUdara == true) c++;
    if (_bebasGenangan == true) c++;
    if (_kebersihanArea == true) c++;
    return c;
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showResult = false;
        _evalResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form inspeksi sanitasi diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectAll(bool val) {
    setState(() {
      _airBersih = val;
      _toiletBersih = val;
      _tempatSampah = val;
      _ventilasiUdara = val;
      _bebasGenangan = val;
      _kebersihanArea = val;
    });
  }

  void _resetAll() {
    setState(() {
      _airBersih = null;
      _toiletBersih = null;
      _tempatSampah = null;
      _ventilasiUdara = null;
      _bebasGenangan = null;
      _kebersihanArea = null;
    });
  }

  List<String> _getUncheckedPoints() {
    final list = <String>[];
    if (_airBersih != true) list.add('Pasokan air bersih perlu diperiksa kejernihan dan kelancaran alirannya.');
    if (_toiletBersih != true) list.add('Toilet membutuhkan pembersihan berkala dan pengisian sabun cair antiseptik.');
    if (_tempatSampah != true) list.add('Sediakan tempat sampah bertutup injak (pedal) dan terpilah organik/anorganik.');
    if (_ventilasiUdara != true) list.add('Buka ventilasi atau aktifkan exhaust fan untuk melancarkan sirkulasi udara.');
    if (_bebasGenangan != true) list.add('Bersihkan genangan air atau sampah berserakan guna mencegah vektor penyakit.');
    if (_kebersihanArea != true) list.add('Sapu dan pel area kerja agar bebas dari penumpukan debu dan kotoran.');
    return list;
  }

  void _evaluasi() async {
    if (_filledCount < 6) {
      // Peringatan butir belum terisi
      final uncompleted = 6 - _filledCount;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: SanitaColors.accentAmber, size: 24),
              SizedBox(width: 8),
              Text('Kriteria Belum Lengkap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Terdapat $uncompleted kriteria pemeriksaan yang belum terisi (belum ditentukan statusnya). Apakah ingin melanjutkan evaluasi parsial atau melengkapinya?',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Lengkapi Dulu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _runEvaluasiProcess();
              },
              style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.primary),
              child: const Text('Tetap Evaluasi'),
            ),
          ],
        ),
      );
      return;
    }

    _runEvaluasiProcess();
  }

  void _runEvaluasiProcess() async {
    setState(() {
      _isLoading = true;
    });

    final targetLokasi = _lokasiController.text.trim().isEmpty ? 'Area Kerja (Belum diisi)' : _lokasiController.text.trim();

    final payload = {
      'lokasi': targetLokasi,
      'air_bersih': _airBersih == true,
      'toilet_bersih': _toiletBersih == true,
      'tempat_sampah': _tempatSampah == true,
      'ventilasi_udara': _ventilasiUdara == true,
      'bebas_genangan': _bebasGenangan == true,
      'kebersihan_area': _kebersihanArea == true,
    };

    try {
      final res = await ApiDataSource().post('/sanitasi/checklist', payload);
      setState(() {
        _evalResult = res['data'];
        _showResult = true;
        _isLoading = false;
      });
    } catch (_) {
      final count = _checkedCount;
      setState(() {
        _evalResult = {
          'skor_terpenuhi': count,
          'total_kondisi': 6,
          'persentase': (count / 6.0 * 100).round(),
          'status_hasil': count == 6 ? 'Semua kondisi checklist terpenuhi' : 'Pemeriksaan Selesai Dievaluasi',
          'saran_tindak_lanjut': count == 6
              ? 'Checklist terpenuhi: 6/6. Pertahankan kondisi dan lakukan pemantauan rutin.'
              : 'Checklist terpenuhi: $count/6. Perbaiki butir sanitasi yang belum memenuhi kriteria.',
          'catatan_simulasi': 'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
        };
        _showResult = true;
        _isLoading = false;
      });
    }

    _showSummaryDialog();
  }

  void _showSummaryDialog() {
    final count = _checkedCount;
    final percent = (count / 6.0 * 100).round();
    final isFull = count == 6;
    final displayLokasi = _lokasiController.text.trim().isEmpty ? 'Area Kerja' : _lokasiController.text.trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isFull ? Icons.verified : Icons.info_outline,
              color: isFull ? SanitaColors.primary : SanitaColors.accentAmber,
            ),
            const SizedBox(width: 8),
            const Text('Lembar Evaluasi Sanitasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokasi: $displayLokasi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Skor Pemenuhan: $count / 6', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$percent%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isFull ? SanitaColors.primary : SanitaColors.accentAmber)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / 6.0,
                minHeight: 8,
                backgroundColor: SanitaColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(isFull ? SanitaColors.primary : SanitaColors.accentAmber),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _evalResult?['saran_tindak_lanjut'] ?? '',
              style: const TextStyle(fontSize: 12, color: SanitaColors.textDark, height: 1.4),
            ),
            if (!isFull) ...[
              const SizedBox(height: 10),
              const Text('Poin Tindak Lanjut:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              ..._getUncheckedPoints().map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: SanitaColors.alertRed)),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 11, color: SanitaColors.textDark))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _checkedCount;
    final filled = _filledCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : SanitaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // HEADER STATIS
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
                    'Cek Standar Sanitasi Fisik',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Periksa 6 standar kondisi kebersihan lingkungan kerja.',
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
                            // Lokasi Pemeriksaan Bebas
                            const Text(
                              'Lokasi pemeriksaan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _lokasiController,
                              style: TextStyle(
                                color: isDark ? Colors.white : SanitaColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                                hintText: 'Masukkan nama lokasi',
                                hintStyle: TextStyle(
                                  color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: SanitaColors.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Tulisan Lokasi Cepat ("Rekomendasi:")
                            Row(
                              children: [
                                Text(
                                  'Rekomendasi:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Quick location chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _quickLocations.map((loc) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text(loc, style: const TextStyle(fontSize: 11)),
                                      backgroundColor: isDark ? SanitaColors.darkCard : Colors.white,
                                      side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                                      onPressed: () {
                                        setState(() {
                                          _lokasiController.text = loc;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Checklist Controls Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kriteria Pemeriksaan (6 Butir)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '$filled dari 6 kriteria telah ditentukan',
                                      style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _selectAll(true),
                                      child: const Text('Pilih Semua', style: TextStyle(fontSize: 12, color: SanitaColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                    const Text(' | ', style: TextStyle(color: SanitaColors.textMuted)),
                                    GestureDetector(
                                      onTap: _resetAll,
                                      child: const Text('Reset', style: TextStyle(fontSize: 12, color: SanitaColors.alertRed, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 6 Kriteria Cards (Default: Belum Terisi / null)
                            _buildCriteriaCard(
                              icon: Icons.water_drop_outlined,
                              title: 'Air bersih tersedia dan layak digunakan',
                              subtitle: 'Jernih, tidak berbau, rasa tawar, dan mengalir kontinu.',
                              value: _airBersih,
                              onSelect: (v) => setState(() => _airBersih = v),
                              isDark: isDark,
                            ),
                            _buildCriteriaCard(
                              icon: Icons.wc_outlined,
                              title: 'Toilet bersih dan berfungsi',
                              subtitle: 'Tersedia air bilas, sabun cair antiseptik, dan kloset higienis.',
                              value: _toiletBersih,
                              onSelect: (v) => setState(() => _toiletBersih = v),
                              isDark: isDark,
                            ),
                            _buildCriteriaCard(
                              icon: Icons.delete_outline,
                              title: 'Tempat sampah tersedia dan tertutup',
                              subtitle: 'Tertutup rapat (pedal injak) dan terpilah organik/anorganik.',
                              value: _tempatSampah,
                              onSelect: (v) => setState(() => _tempatSampah = v),
                              isDark: isDark,
                            ),
                            _buildCriteriaCard(
                              icon: Icons.air_outlined,
                              title: 'Ventilasi udara memadai',
                              subtitle: 'Sirkulasi udara segar lancar, tidak pengap dan berdebu.',
                              value: _ventilasiUdara,
                              onSelect: (v) => setState(() => _ventilasiUdara = v),
                              isDark: isDark,
                            ),
                            _buildCriteriaCard(
                              icon: Icons.waves_outlined,
                              title: 'Tidak ada genangan air atau sampah berserakan',
                              subtitle: 'Saluran drainase lancar, bebas vektor jentik nyamuk dan lalat.',
                              value: _bebasGenangan,
                              onSelect: (v) => setState(() => _bebasGenangan = v),
                              isDark: isDark,
                            ),
                            _buildCriteriaCard(
                              icon: Icons.cleaning_services_outlined,
                              title: 'Area kerja terjaga kebersihannya',
                              subtitle: 'Lantai, meja, dan fasilitas tertata rapi serta rutin dibersihkan.',
                              value: _kebersihanArea,
                              onSelect: (v) => setState(() => _kebersihanArea = v),
                              isDark: isDark,
                            ),

                            const SizedBox(height: 16),

                            // Evaluasi Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _evaluasi,
                                icon: _isLoading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.analytics_outlined),
                                label: Text(
                                  filled < 6 ? 'Evaluasi Sanitasi ($filled/6 Kriteria Terisi)' : 'Lihat Hasil Evaluasi Lengkap',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SanitaColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
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

  Widget _buildCriteriaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool? value,
    required Function(bool) onSelect,
    required bool isDark,
  }) {
    Color cardBorder;
    Widget statusBadge;

    if (value == null) {
      cardBorder = isDark ? SanitaColors.darkBorder : SanitaColors.border;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Belum Terisi',
          style: TextStyle(fontSize: 10, color: SanitaColors.textMuted, fontWeight: FontWeight.bold),
        ),
      );
    } else if (value == true) {
      cardBorder = SanitaColors.primary.withOpacity(0.5);
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: SanitaColors.primarySurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '✓ Memenuhi',
          style: TextStyle(fontSize: 10, color: SanitaColors.primary, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      cardBorder = SanitaColors.alertRed.withOpacity(0.5);
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: SanitaColors.alertRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '✗ Belum Memenuhi',
          style: TextStyle(fontSize: 10, color: SanitaColors.alertRed, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? SanitaColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cardBorder, width: value != null ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: value == true ? SanitaColors.primary : (value == false ? SanitaColors.alertRed : SanitaColors.textMuted), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                statusBadge,
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onSelect(true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: value == true ? SanitaColors.primary : null,
                      foregroundColor: value == true ? Colors.white : (isDark ? Colors.white70 : SanitaColors.textDark),
                      side: BorderSide(color: value == true ? SanitaColors.primary : (isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('✓ Memenuhi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onSelect(false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: value == false ? SanitaColors.alertRed : null,
                      foregroundColor: value == false ? Colors.white : (isDark ? Colors.white70 : SanitaColors.textDark),
                      side: BorderSide(color: value == false ? SanitaColors.alertRed : (isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('✗ Belum Memenuhi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}