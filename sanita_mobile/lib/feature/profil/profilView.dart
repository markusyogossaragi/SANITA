import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/themeController.dart';
import '../../core/models/models.dart';
import '../../core/services/sessionService.dart';
import '../../core/repositories/authRepository.dart';
import '../auth/loginView.dart';
import '../admin/adminView.dart';
import 'editProfilView.dart';

class ProfilView extends StatefulWidget {
  final VoidCallback onBackToHome;
  final List<LaporanModel>? reports;
  final Function(String id, String newStatus)? onUpdateReportStatus;
  final Function(LaporanModel updatedReport)? onEditReport;
  final Function(String id)? onDeleteReport;

  const ProfilView({
    super.key,
    required this.onBackToHome,
    this.reports,
    this.onUpdateReportStatus,
    this.onEditReport,
    this.onDeleteReport,
  });

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  bool _notifReminder = false;
  bool _dataSaving = true;

  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _loadUserAndPreferences();
  }

  void _loadUserAndPreferences() async {
    final user = await SessionService().getUser();
    final prefs = await SharedPreferences.getInstance();

    final reminder = prefs.getBool('sanita_pref_reminder') ?? false; // default = mati
    final dataSave = prefs.getBool('sanita_pref_data_saving') ?? true; // default = nyala

    File? loadedAvatar;
    if (user != null) {
      final savedAvatarPath = prefs.getString('sanita_avatar_${user.id}');
      if (savedAvatarPath != null && savedAvatarPath.isNotEmpty && File(savedAvatarPath).existsSync()) {
        loadedAvatar = File(savedAvatarPath);
      } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty && File(user.avatarUrl!).existsSync()) {
        loadedAvatar = File(user.avatarUrl!);
      }
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _notifReminder = reminder;
        _dataSaving = dataSave;
        _avatarFile = loadedAvatar;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadUserAndPreferences();
  }

  void _pickAvatar() {
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
              const Text('Ubah Foto Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: SanitaColors.primarySurface,
                  child: Icon(Icons.camera_alt, color: SanitaColors.primary),
                ),
                title: const Text('Ambil Foto dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _runAvatarPicker(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: SanitaColors.primarySurface,
                  child: Icon(Icons.photo_library, color: SanitaColors.primary),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _runAvatarPicker(ImageSource.gallery);
                },
              ),
              if (_avatarFile != null || (_currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty)) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: SanitaColors.alertRed),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(fontWeight: FontWeight.w600, color: SanitaColors.alertRed)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.remove('sanita_avatar_${_currentUser!.id}');
      final updatedUser = UserModel(
        id: _currentUser!.id,
        username: _currentUser!.username,
        fullName: _currentUser!.fullName,
        role: _currentUser!.role,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        avatarUrl: null,
      );
      await AuthRepository().updateProfile(updatedUser);
      if (mounted) {
        setState(() {
          _avatarFile = null;
          _currentUser = updatedUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus.'),
            backgroundColor: SanitaColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _runAvatarPicker(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (picked != null && _currentUser != null) {
        final path = picked.path;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanita_avatar_${_currentUser!.id}', path);

        final updatedUser = UserModel(
          id: _currentUser!.id,
          username: _currentUser!.username,
          fullName: _currentUser!.fullName,
          role: _currentUser!.role,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          avatarUrl: path,
        );

        await AuthRepository().updateProfile(updatedUser);

        if (mounted) {
          setState(() {
            _avatarFile = File(path);
            _currentUser = updatedUser;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: SanitaColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengganti foto profil: $e'),
            backgroundColor: SanitaColors.alertRed,
          ),
        );
      }
    }
  }

  void _openEditProfile() async {
    final defaultUser = _currentUser ??
        UserModel(
          id: 'usr-admin-ribka-243301631022',
          username: 'ribka',
          fullName: 'Ribka Lusiana Harahap',
          role: 'Admin',
          email: 'ribka.harahap@sanita.id',
          phone: '+62 812-3456-7890',
        );

    final updated = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilView(currentUser: defaultUser)),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentUser = updated;
      });
    }
  }

  void _openAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboardView(
          onBack: () => Navigator.pop(context),
          reports: widget.reports ?? [],
          onUpdateStatus: widget.onUpdateReportStatus,
          onEditReport: widget.onEditReport,
          onDeleteReport: widget.onDeleteReport,
        ),
      ),
    );
  }

  void _updateReminder(bool val) async {
    setState(() => _notifReminder = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sanita_pref_reminder', val);
  }

  void _updateDataSaving(bool val) async {
    setState(() => _dataSaving = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sanita_pref_data_saving', val);
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: SanitaColors.primary,
        content: Text('Cache lokal aplikasi berhasil dibersihkan!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: SanitaColors.alertRed, size: 22),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini? Anda harus masuk kembali untuk mengakses data.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthRepository().logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: SanitaColors.alertRed),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = _currentUser?.fullName ?? 'Ribka Lusiana Harahap';
    final displayRole = _currentUser?.role ?? 'Admin';
    final displayEmail = _currentUser?.email ?? 'ribka.harahap@sanita.id';
    final displayUsername = _currentUser?.username ?? 'ribka';
    final bool isAdmin = displayRole.toLowerCase() == 'admin' || displayUsername.toLowerCase() == 'ribka';

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
                  Text(
                    'Halo, $displayName!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                              'Profil Pengguna Terverifikasi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // User Identity Block + Foto Profil Uploadable
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? SanitaColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                              ),
                              child: Row(
                                children: [
                                  // Avatar dengan Tombol Ganti Foto
                                  GestureDetector(
                                    onTap: _pickAvatar,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: SanitaColors.primarySurface,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: SanitaColors.primary, width: 2),
                                          ),
                                          child: ClipOval(
                                            child: _avatarFile != null
                                                ? Image.file(_avatarFile!, fit: BoxFit.cover)
                                                : const Icon(Icons.person, size: 38, color: SanitaColors.primary),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: SanitaColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@$displayUsername',
                                          style: const TextStyle(fontSize: 12, color: SanitaColors.textMuted, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isAdmin ? SanitaColors.primaryDark : SanitaColors.primarySurface,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isAdmin ? 'ADMINISTRATOR UTAMA' : displayRole,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isAdmin ? Colors.white : SanitaColors.primaryDark,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: SanitaColors.primary, size: 22),
                                    tooltip: 'Edit Profil',
                                    onPressed: _openEditProfile,
                                  ),
                                ],
                              ),
                            ),

                            // Banner Khusus Admin (Halaman Admin Login Ribka)
                            if (isAdmin) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [SanitaColors.primaryDark, SanitaColors.primary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SanitaColors.primaryDark.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.admin_panel_settings, color: SanitaColors.accentAmber, size: 26),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Panel Administrator Utama',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Kelola status laporan masuk & seluruh data akun',
                                            style: TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _openAdminPanel,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SanitaColors.accentAmber,
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Buka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Informasi Kontak & Detail Akun
                            const Text(
                              'Informasi Akun',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? SanitaColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.email_outlined, size: 20, color: SanitaColors.primary),
                                    title: const Text('Email Terdaftar', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                                    subtitle: Text(displayEmail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                  if (_currentUser?.phone != null && _currentUser!.phone!.isNotEmpty) ...[
                                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                                    ListTile(
                                      leading: const Icon(Icons.phone_outlined, size: 20, color: SanitaColors.primary),
                                      title: const Text('Nomor Telepon / WhatsApp', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                                      subtitle: Text(_currentUser!.phone!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Pengaturan & Preferensi
                            const Text(
                              'Preferensi Aplikasi',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? SanitaColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                              ),
                              child: Column(
                                children: [
                                  // Switch Pengingat Cek Berkala (DEFAULT = MATI / FALSE)
                                  SwitchListTile(
                                    title: const Text('Pengingat Cek Berkala', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: const Text('Notifikasi jadwal inspeksi kebersihan mingguan', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                    value: _notifReminder,
                                    activeColor: SanitaColors.primary,
                                    onChanged: _updateReminder,
                                  ),
                                  Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? SanitaColors.darkBorder : SanitaColors.border),

                                  // Switch Mode Hemat Data (DEFAULT = NYALA / TRUE)
                                  SwitchListTile(
                                    title: const Text('Mode Hemat Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: const Text('Kompresi gambar bukti foto laporan', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                    value: _dataSaving,
                                    activeColor: SanitaColors.primary,
                                    onChanged: _updateDataSaving,
                                  ),
                                  Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? SanitaColors.darkBorder : SanitaColors.border),

                                  // Switch Dark & Light Theme (SharedPreferences)
                                  ValueListenableBuilder<ThemeMode>(
                                    valueListenable: ThemeController.instance.themeModeNotifier,
                                    builder: (context, currentMode, _) {
                                      final isDarkModeActive = currentMode == ThemeMode.dark;
                                      return SwitchListTile(
                                        title: const Text('Mode Gelap (Dark Theme)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        subtitle: const Text('Tampilan gelap untuk kenyamanan mata Anda', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                        value: isDarkModeActive,
                                        activeColor: SanitaColors.primary,
                                        onChanged: (val) {
                                          ThemeController.instance.toggleTheme(val);
                                        },
                                      );
                                    },
                                  ),
                                  Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? SanitaColors.darkBorder : SanitaColors.border),

                                  ListTile(
                                    leading: const Icon(Icons.cleaning_services_outlined, size: 20),
                                    title: const Text('Bersihkan Cache Lokal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: SanitaColors.textMuted),
                                    onTap: _clearCache,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Academic Attribution Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: SanitaColors.primary.withOpacity(0.3)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.school_outlined, size: 18, color: SanitaColors.primary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Informasi Proyek Akademik',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text('Nama: Ribka Lusiana Harahap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 3),
                                  Text('NIM: 243301631022', style: TextStyle(fontSize: 12)),
                                  SizedBox(height: 3),
                                  Text('Dosen Pengampu: Riky Suherman Simanjuntak, S.K.M., M.K.M.', style: TextStyle(fontSize: 12)),
                                  SizedBox(height: 3),
                                  Text('Mata Kuliah: Sanitasi dan Lingkungan Kerja', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _confirmLogout,
                                icon: const Icon(Icons.logout, color: SanitaColors.alertRed, size: 18),
                                label: const Text('Keluar dari Akun', style: TextStyle(color: SanitaColors.alertRed, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: SanitaColors.alertRed),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
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
}