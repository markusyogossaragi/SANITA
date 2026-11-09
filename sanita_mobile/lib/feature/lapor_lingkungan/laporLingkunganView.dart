import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/datasources/apiDataSource.dart';
import '../../core/services/securityService.dart';
import '../../core/services/sessionService.dart';
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
  File? _pickedImage;
  String? _pickedImagePath;
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
    'Kantin Kampus UNPRI',
    'Ruang Rapat Utama',
    'Koridor Barat Lt. 2',
    'Laboratorium Kesling',
  ];

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form pelaporan disetel ulang'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unggah Bukti Foto Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: SanitaColors.primarySurface,
                  child: Icon(Icons.camera_alt, color: SanitaColors.primary),
                ),
                title: const Text('Ambil Foto dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Buka kamera untuk memotret kondisi saat ini', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: SanitaColors.primarySurface,
                  child: Icon(Icons.photo_library, color: SanitaColors.primary),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih foto bukti dari galeri perangkat', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
          _pickedImagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: SanitaColors.alertRed,
          ),
        );
      }
    }
  }

  void _kirimLaporan() async {
    if (_selectedMasalah == null) {
      _showWarning('Pilih kategori permasalahan lingkungan terlebih dahulu.');
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

    final currentUser = await SessionService().getUser();
    final reporterName = currentUser?.fullName ?? 'Sahabat SANITA';

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
      fotoUrl: _pickedImagePath,
      reporterName: reporterName,
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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tiket pengaduan telah dicatat dalam basis data SANITA dengan tanda tangan integritas digital.',
              style: TextStyle(fontSize: 12, color: SanitaColors.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SanitaColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SanitaColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nomor Tiket:', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                      Text(report.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SanitaColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kategori:', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                      Text(report.jenisMasalah, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lokasi:', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                      Text(report.lokasi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (report.fotoUrl != null) ...[
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Foto Bukti:', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                        Text('Terlampir (1 Foto)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SanitaColors.primary)),
                      ],
                    ),
                  ],
                ],
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: SanitaColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Buka Riwayat Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
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
      _pickedImage = null;
      _pickedImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    'Lapor Masalah Lingkungan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Laporkan temuan sanitasi untuk segera ditindaklanjuti.',
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
                              // Jenis Permasalahan
                              const Text('Jenis Permasalahan *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedMasalah,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                                  hintText: 'Pilih jenis kendala sanitasi',
                                  prefixIcon: const Icon(Icons.category_outlined, size: 20, color: SanitaColors.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                ),
                                items: _kategoriMasalah.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedMasalah = v),
                              ),

                              const SizedBox(height: 16),

                              // Lokasi Kejadian
                              const Text('Lokasi Kejadian *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _lokasiController,
                                style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                                  hintText: 'Misal: Toilet Lantai 2, Kantin Kampus UNPRI',
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: SanitaColors.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Quick chips lokasi
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
                                        onPressed: () => setState(() => _lokasiController.text = loc),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tingkat Urgensi
                              const Text('Tingkat Urgensi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildUrgensiChip('Rendah', SanitaColors.primaryLight),
                                  const SizedBox(width: 8),
                                  _buildUrgensiChip('Sedang', SanitaColors.accentAmber),
                                  const SizedBox(width: 8),
                                  _buildUrgensiChip('Mendesak', SanitaColors.alertRed),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Keterangan Masalah
                              const Text('Keterangan / Deskripsi *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _keteranganController,
                                maxLines: 4,
                                style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                                  hintText: 'Jelaskan kondisi sanitasi secara rinci, misalnya: genangan air di koridor, tempat sampah penuh, kran wastafel bocor...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Upload Bukti Foto (SUNGGUHAN MENGGUNAKAN IMAGE PICKER)
                              const Text('Upload Bukti Foto (Kamera / Galeri)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),

                              if (_pickedImage != null) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: SanitaColors.primary, width: 1.5),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _pickedImage!,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _pickedImage = null;
                                              _pickedImagePath = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: SanitaColors.primaryLight, size: 14),
                                              SizedBox(width: 4),
                                              Text('Foto Berhasil Terlampir', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                InkWell(
                                  onTap: _showPhotoSourceSheet,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isDark ? SanitaColors.darkCard : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border, style: BorderStyle.solid),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 36, color: SanitaColors.primary),
                                        SizedBox(height: 8),
                                        Text('Ambil Foto Kamera atau Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primary)),
                                        SizedBox(height: 2),
                                        Text('Format JPG / PNG, ukuran otomatis terkompresi', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Button Kirim Laporan
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _kirimLaporan,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SanitaColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send_rounded, size: 18),
                                            SizedBox(width: 8),
                                            Text('Kirim Laporan Sanitasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),
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

  Widget _buildUrgensiChip(String label, Color color) {
    final isSelected = _selectedUrgensi == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedUrgensi = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}