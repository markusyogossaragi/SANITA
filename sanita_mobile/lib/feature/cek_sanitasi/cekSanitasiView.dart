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
  // Default kosong, placeholder "Masukkan nama lokasi" abu-abu, ketika diisi jadi hitam
  final TextEditingController _lokasiController = TextEditingController();

  bool _airBersih = true;
  bool _toiletBersih = true;
  bool _tempatSampah = true;
  bool _ventilasiUdara = true;
  bool _bebasGenangan = true;
  bool _kebersihanArea = true;

  bool _showResult = false;
  bool _isLoading = false;
  Map<String, dynamic>? _evalResult;

  final List<String> _quickLocations = [
    'Pantry Lantai 2',
    'Toilet Barat',
    'Ruang Rapat A',
    'Laboratorium Kesling',
    'Kantin Kampus',
  ];

  int get _checkedCount {
    int c = 0;
    if (_airBersih) c++;
    if (_toiletBersih) c++;
    if (_tempatSampah) c++;
    if (_ventilasiUdara) c++;
    if (_bebasGenangan) c++;
    if (_kebersihanArea) c++;
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

  List<String> _getUncheckedPoints() {
    final list = <String>[];
    if (!_airBersih) list.add('Pasokan air bersih perlu diperiksa kejernihan dan kelancaran alirannya.');
    if (!_toiletBersih) list.add('Toilet membutuhkan pembersihan berkala dan pengisian sabun cair antiseptik.');
    if (!_tempatSampah) list.add('Sediakan tempat sampah bertutup injak (pedal) dan terpilah organik/anorganik.');
    if (!_ventilasiUdara) list.add('Buka ventilasi atau aktifkan exhaust fan untuk melancarkan sirkulasi udara.');
    if (!_bebasGenangan) list.add('Bersihkan genangan air atau sampah berserakan guna mencegah vektor penyakit.');
    if (!_kebersihanArea) list.add('Sapu dan pel area kerja agar bebas dari penumpukan debu dan kotoran.');
    return list;
  }

  void _evaluasi() async {
    setState(() {
      _isLoading = true;
    });

    final targetLokasi = _lokasiController.text.trim().isEmpty ? 'Area Kerja (Belum diisi)' : _lokasiController.text.trim();

    final payload = {
      'lokasi': targetLokasi,
      'air_bersih': _airBersih,
      'toilet_bersih': _toiletBersih,
      'tempat_sampah': _tempatSampah,
      'ventilasi_udara': _ventilasiUdara,
      'bebas_genangan': _bebasGenangan,
      'kebersihan_area': _kebersihanArea,
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
            Text(
              'Lokasi: $displayLokasi',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: SanitaColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isFull ? SanitaColors.primarySurface : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFull ? 'MEMENUHI STANDAR' : 'PERLU PERBAIKAN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isFull ? SanitaColors.primaryDark : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count dari 6 butir terpenuhi ($percent%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isFull ? SanitaColors.primaryDark : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isFull ? SanitaColors.primary : const Color(0xFFB45309),
                    ),
                  ),
                ],
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
    final progress = count / 6.0;

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
                            const Text(
                              'Cek Sanitasi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Periksa 6 standar kondisi sanitasi fisik lingkungan kerja.',
                              style: TextStyle(fontSize: 12, color: SanitaColors.textMuted),
                            ),
                            const SizedBox(height: 16),

                            // Lokasi Pemeriksaan
                            const Text(
                              'Lokasi pemeriksaan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _lokasiController,
                              style: const TextStyle(
                                color: SanitaColors.textDark, // Warna hitam saat diketik
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Masukkan nama lokasi', // Placeholder default abu-abu
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400, // Abu-abu saat kosong
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: SanitaColors.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Quick location chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _quickLocations.map((loc) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text(loc, style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: SanitaColors.border),
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
                                const Text(
                                  'Kriteria Pemeriksaan (6 Butir)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _selectAll(true),
                                      child: const Text('Pilih Semua', style: TextStyle(fontSize: 12, color: SanitaColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                    const Text(' | ', style: TextStyle(color: SanitaColors.textMuted)),
                                    GestureDetector(
                                      onTap: () => _selectAll(false),
                                      child: const Text('Reset', style: TextStyle(fontSize: 12, color: SanitaColors.alertRed, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 6 Checkbox Items
                            _buildCheckCard(
                              icon: Icons.water_drop_outlined,
                              title: 'Air bersih tersedia dan layak digunakan',
                              subtitle: 'Jernih, tidak berbau, rasa tawar, dan mengalir kontinu.',
                              value: _airBersih,
                              onChanged: (v) => setState(() => _airBersih = v!),
                            ),
                            _buildCheckCard(
                              icon: Icons.wc_outlined,
                              title: 'Toilet bersih dan berfungsi',
                              subtitle: 'Kloset higienis, pembilas lancar, dan tersedia sabun cuci tangan.',
                              value: _toiletBersih,
                              onChanged: (v) => setState(() => _toiletBersih = v!),
                            ),
                            _buildCheckCard(
                              icon: Icons.delete_outline,
                              title: 'Tempat sampah tersedia dan tertutup',
                              subtitle: 'Wadah kedap air, berpedal injak, serta terpilah rapi.',
                              value: _tempatSampah,
                              onChanged: (v) => setState(() => _tempatSampah = v!),
                            ),
                            _buildCheckCard(
                              icon: Icons.air,
                              title: 'Ventilasi udara memadai',
                              subtitle: 'Sirkulasi udara segar, jendela/exhaust fan aktif, tidak pengap.',
                              value: _ventilasiUdara,
                              onChanged: (v) => setState(() => _ventilasiUdara = v!),
                            ),
                            _buildCheckCard(
                              icon: Icons.water_damage_outlined,
                              title: 'Tidak ada genangan air atau sampah berserakan',
                              subtitle: 'Lantai kering, drainase lancar, bebas jentik nyamuk.',
                              value: _bebasGenangan,
                              onChanged: (v) => setState(() => _bebasGenangan = v!),
                            ),
                            _buildCheckCard(
                              icon: Icons.cleaning_services_outlined,
                              title: 'Area kerja terjaga kebersihannya',
                              subtitle: 'Bebas penumpukan debu, tertata rapi, dan nyaman untuk beraktivitas.',
                              value: _kebersihanArea,
                              onChanged: (v) => setState(() => _kebersihanArea = v!),
                            ),

                            const SizedBox(height: 16),

                            // Penanda Progres
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$count dari 6 kondisi terpenuhi',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                                ),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SanitaColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  count == 6 ? SanitaColors.primary : (count >= 4 ? SanitaColors.accentAmber : SanitaColors.alertRed),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Button Evaluasi
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _evaluasi,
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Lihat Hasil Pemeriksaan'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Catatan Simulasi Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.',
                                style: TextStyle(fontSize: 11, color: SanitaColors.textMuted, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
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

  Widget _buildCheckCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? SanitaColors.primary.withOpacity(0.5) : SanitaColors.border,
            width: value ? 1.5 : 1.0,
          ),
        ),
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          activeColor: SanitaColors.primary,
          dense: false,
          secondary: Icon(icon, color: value ? SanitaColors.primary : SanitaColors.textMuted),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: SanitaColors.textDark,
              fontWeight: value ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: SanitaColors.textMuted),
          ),
        ),
      ),
    );
  }
}
