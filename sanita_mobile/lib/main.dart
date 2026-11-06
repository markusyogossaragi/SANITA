import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'core/models/models.dart';
import 'core/services/sessionService.dart';
import 'feature/beranda/berandaView.dart';
import 'feature/cek_sanitasi/cekSanitasiView.dart';
import 'feature/lapor_lingkungan/laporLingkunganView.dart';
import 'feature/riwayat_laporan/riwayatLaporanView.dart';
import 'feature/profil/profilView.dart';
import 'feature/edukasi_kesling/edukasiView.dart';
import 'feature/monitoring/monitoringView.dart';
import 'core/widgets/navbar.dart';
import 'feature/splash/splashView.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SanitaApp());
}

class SanitaApp extends StatelessWidget {
  const SanitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SANITA',
      debugShowCheckedModeBanner: false,
      theme: SanitaTheme.lightTheme,
      home: const SplashView(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<LaporanModel> _reports = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _seedInitialReports();
  }

  void _loadCurrentUser() async {
    final user = await SessionService().getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void _seedInitialReports() {
    _reports.addAll([
      LaporanModel(
        id: 'SNT-2026-0104',
        jenisMasalah: 'Pengelolaan Sampah',
        lokasi: 'Kantin Kampus Lt. 1',
        keterangan: 'Tempat sampah organik penuh dan penutup pedal perlu perbaikan.',
        status: 'selesai',
        urgensi: 'Sedang',
        reporterName: 'Ribka Lusiana',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        integrityHMAC: 'sha256-verified-tamper-proof',
      ),
      LaporanModel(
        id: 'SNT-2026-0105',
        jenisMasalah: 'Kebersihan Toilet',
        lokasi: 'Toilet Barat Lantai 2',
        keterangan: 'Wastafel tersumbat ringan dan sabun cuci tangan cair habis.',
        status: 'diproses',
        urgensi: 'Mendesak',
        reporterName: 'Sahabat SANITA',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        integrityHMAC: 'sha256-verified-tamper-proof',
      ),
      LaporanModel(
        id: 'SNT-2026-0106',
        jenisMasalah: 'Sirkulasi / Ventilasi Udara',
        lokasi: 'Ruang Rapat Utama Lantai 3',
        keterangan: 'Sirkulasi udara pengap dan kisi exhaust fan perlu dibersihkan dari debu.',
        status: 'terkirim',
        urgensi: 'Rendah',
        reporterName: 'Sahabat SANITA',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
        integrityHMAC: 'sha256-verified-tamper-proof',
      ),
    ]);
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openEdukasi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EdukasiView(onBackToHome: () => Navigator.pop(context))),
    );
  }

  void _openMonitoring() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MonitoringView(onBackToHome: () => Navigator.pop(context))),
    );
  }

  void _addNewReport(LaporanModel newReport) {
    setState(() {
      _reports.insert(0, newReport);
      _currentIndex = 3; // Switch to Riwayat Laporan tab
    });
  }

  void _updateReportStatus(String id, String newStatus) {
    setState(() {
      final index = _reports.indexWhere((r) => r.id == id);
      if (index != -1) {
        final old = _reports[index];
        _reports[index] = LaporanModel(
          id: old.id,
          jenisMasalah: old.jenisMasalah,
          lokasi: old.lokasi,
          keterangan: old.keterangan,
          fotoUrl: old.fotoUrl,
          status: newStatus,
          urgensi: old.urgensi,
          reporterName: old.reporterName,
          createdAt: old.createdAt,
          integrityHMAC: old.integrityHMAC,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BerandaView(
        onTabSelect: _onTabTapped,
        reportCount: _reports.length,
        onOpenEdukasi: _openEdukasi,
        onOpenMonitoring: _openMonitoring,
      ),
      CekSanitasiView(
        onBackToHome: () => _onTabTapped(0),
      ),
      LaporLingkunganView(
        onBackToHome: () => _onTabTapped(0),
        onReportSubmitted: _addNewReport,
      ),
      RiwayatLaporanView(
        onBackToHome: () => _onTabTapped(0),
        reports: _reports,
        onUpdateStatus: _updateReportStatus,
      ),
      ProfilView(
        onBackToHome: () => _onTabTapped(0),
      ),
    ];

    // PopScope intercepts device back button:
    // - If not on tab 0 (Beranda), returns to Beranda (tab 0)
    // - If on tab 0, allows pop / exit
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0; // Return to Beranda / Dashboard
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: SanitaNavBar(
          currentIndex: _currentIndex,
          onTabSelected: _onTabTapped,
        ),
      ),
    );
  }
}