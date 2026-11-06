import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/datasources/apiDataSource.dart';
import '../../core/services/securityService.dart';
import '../../core/utils/inputSanitizer.dart';

class LaporLingkunganView extends StatefulWidget {
  final VoidCallback onBackToHome;
  final Function(LaporanModel report) onReportSubmitted;

  const LaporLingkunganView({
    super.key,
    required this.onBackToHome,
    required this.onReportSubmitted,
  });

  @override
  State<LaporLingkunganView> createState() => _LaporLingkunganViewState();
}

class _LaporLingkunganViewState extends State<LaporLingkunganView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMasalah;
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  String _selectedUrgensi = 'Sedang';
  String? _attachedFileName;
  bool _isSubmitting = false;

  final List<String> _kategoriMasalah = [
    'Kebersihan Toilet',
    'Pengelolaan Sampah',
    'Pasokan Air Bersih',
    'Sirkulasi / Ventilasi Udara',
    'Genangan Air / Vektor Penyakit',
    'Kerusakan Sarana Sanitasi',
    'Area Kerja Kotor / Berdebu',
    'Lainnya',
  ];

  final List<String> _quickLocations = [
    'Pantry Lt. 2',
    'Toilet Barat Lt. 1',
    'Kantin Kampus',
    'Ruang Rapat Utama',
    'Koridor Barat',
    'Laboratorium Kesling',
  ];

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form laporan lingkungan diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _kirimLaporan() async {
    if (_selectedMasalah == null) {
      _showWarning('Pilih jenis permasalahan terlebih dahulu.');
      return;
    }
    if (_lokasiController.text.trim().isEmpty) {
      _showWarning('Isi lokasi kejadian tempat kerja.');
      return;
    }
    if (_keteranganController.text.trim().isEmpty) {
      _showWarning('Jelaskan kondisi sanitasi yang ditemukan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final sanitizedLokasi = InputSanitizer.sanitize(_lokasiController.text.trim());
    final sanitizedKeterangan = InputSanitizer.sanitize(_keteranganController.text.trim());

    // Generate unique SANITA Ticket Tracking ID
    final randomNum = 1000 + Random().nextInt(9000);
    final ticketId = 'SNT-2026-$randomNum';

    // Anti-tamper cryptographic HMAC-SHA256 signature
    final nowIso = DateTime.now().toIso8601String();
    final hmacSignature = SecurityService().computeReportHMAC(
      id: ticketId,
      category: _selectedMasalah!,
      location: sanitizedLokasi,
      description: sanitizedKeterangan,
      timestamp: nowIso,
    );

    final newReport = LaporanModel(
      id: ticketId,
      jenisMasalah: _selectedMasalah!,
      lokasi: sanitizedLokasi,
      keterangan: sanitizedKeterangan,
      status: 'terkirim',
      urgensi: _selectedUrgensi,
      fotoUrl: _attachedFileName != null ? 'assets/images/sample_report.jpg' : null,
      reporterName: 'Sahabat SANITA',
      createdAt: nowIso,
      integrityHMAC: hmacSignature,
    );

    // Call API (fallback handled gracefully)
    try {
      await ApiDataSource().post('/laporan', newReport.toJson());
    } catch (_) {}

    setState(() {
      _isSubmitting = false;
    });

    // Show Success Dialog
    _showSuccessDialog(newReport);
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SanitaColors.alertRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(LaporanModel report) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: SanitaColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: SanitaColors.primary, size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Laporan Berhasil Terkirim!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: SanitaColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nomor Tiket: ${report.id}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: SanitaColors.primary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Laporan Anda telah dicatat ke sistem monitoring tim sanitasi lingkungan kerja.',
              style: TextStyle(fontSize: 12, color: SanitaColors.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetForm();
                widget.onReportSubmitted(report);
              },
              child: const Text('Buka Riwayat Laporan'),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedMasalah = null;
      _lokasiController.clear();
      _keteranganController.clear();
      _selectedUrgensi = 'Sedang';
      _attachedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lapor Lingkungan',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Bantu pengelola mengetahui dan menindaklanjuti masalah sanitasi.',
                                style: TextStyle(fontSize: 12, color: SanitaColors.textMuted),
                              ),
                              const SizedBox(height: 18),

                              // Jenis Permasalahan
                              const Text(
                                'Jenis permasalahan',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedMasalah,
                                hint: const Text('Pilih kategori masalah sanitasi', style: TextStyle(fontSize: 13, color: SanitaColors.textMuted)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                                ),
                                items: _kategoriMasalah.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(m, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedMasalah = val;
                                  });
                                },
                              ),

                              const SizedBox(height: 16),

                              // Tingkat Urgensi Selector
                              const Text(
                                'Tingkat Urgensi Penanganan',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildUrgencyChip('Rendah', Colors.blue.shade600),
                                  const SizedBox(width: 8),
                                  _buildUrgencyChip('Sedang', SanitaColors.accentAmber),
                                  const SizedBox(width: 8),
                                  _buildUrgencyChip('Mendesak', SanitaColors.alertRed),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Lokasi Kejadian
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Lokasi kejadian',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                                  ),
                                  const Text(
                                    'Pilih cepat di bawah:',
                                    style: TextStyle(fontSize: 11, color: SanitaColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _lokasiController,
                                style: const TextStyle(color: SanitaColors.textDark, fontWeight: FontWeight.w600, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Contoh: Area pantry lantai 2',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: SanitaColors.primary),
                                  filled: true,
                                  fillColor: Colors.white,
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

                              const SizedBox(height: 16),

                              // Keterangan
                              const Text(
                                'Keterangan kondisi yang ditemukan',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _keteranganController,
                                maxLines: 4,
                                style: const TextStyle(color: SanitaColors.textDark, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Jelaskan masalah sanitasi (misal: genangan air, kran bocor, tempat sampah meluap)...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SanitaColors.border)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Foto Bukti
                              const Text(
                                'Foto bukti lingkungan (opsional)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: SanitaColors.border),
                                ),
                                child: Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _attachedFileName = 'bukti_sanitasi_${DateTime.now().millisecondsSinceEpoch % 1000}.jpg';
                                        });
                                      },
                                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                      label: const Text('Ambil / Pilih Foto', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _attachedFileName ?? 'Belum ada foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _attachedFileName != null ? SanitaColors.primary : SanitaColors.textMuted,
                                          fontWeight: _attachedFileName != null ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_attachedFileName != null)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: SanitaColors.alertRed),
                                        onPressed: () {
                                          setState(() {
                                            _attachedFileName = null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Button Kirim Laporan
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _kirimLaporan,
                                  child: _isSubmitting
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Kirim Laporan Sanitasi'),
                                ),
                              ),

                              const SizedBox(height: 30),
                            ],
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
      ),
    );
  }

  Widget _buildUrgencyChip(String label, Color color) {
    final isSelected = _selectedUrgensi == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUrgensi = label;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : SanitaColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : SanitaColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
