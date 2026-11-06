import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/services/sessionService.dart';
import '../../core/repositories/authRepository.dart';
import '../auth/loginView.dart';
import 'editProfilView.dart';

class ProfilView extends StatefulWidget {
  final VoidCallback onBackToHome;

  const ProfilView({super.key, required this.onBackToHome});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  bool _notifReminder = true;
  bool _dataSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final user = await SessionService().getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadUser();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil pengguna diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openEditProfile() async {
    final defaultUser = _currentUser ??
        UserModel(
          id: 'usr-001',
          username: 'ribka',
          fullName: 'Ribka Lusiana Harahap',
          role: 'Inspektur Sanitasi & K3',
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
          style: TextStyle(fontSize: 13, color: SanitaColors.textDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: SanitaColors.textMuted)),
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
    final displayName = _currentUser?.fullName ?? 'Ribka Lusiana Harahap';
    final displayRole = _currentUser?.role ?? 'Inspektur Sanitasi & K3';
    final displayEmail = _currentUser?.email ?? 'ribka.harahap@sanita.id';
    final displayUsername = _currentUser?.username ?? 'ribka';

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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                            ),
                            const SizedBox(height: 16),

                            // User Identity Block
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: SanitaColors.border),
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
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      color: SanitaColors.primarySurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, size: 36, color: SanitaColors.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
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
                                            color: SanitaColors.primarySurface,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            displayRole,
                                            style: const TextStyle(fontSize: 11, color: SanitaColors.primaryDark, fontWeight: FontWeight.w600),
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

                            const SizedBox(height: 20),

                            // Informasi Kontak & Detail Akun
                            const Text(
                              'Informasi Akun',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: SanitaColors.border),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.email_outlined, size: 20, color: SanitaColors.primary),
                                    title: const Text('Email Terdaftar', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                                    subtitle: Text(displayEmail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark)),
                                  ),
                                  if (_currentUser?.phone != null && _currentUser!.phone!.isNotEmpty) ...[
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                    ListTile(
                                      leading: const Icon(Icons.phone_outlined, size: 20, color: SanitaColors.primary),
                                      title: const Text('Nomor Telepon / WhatsApp', style: TextStyle(fontSize: 12, color: SanitaColors.textMuted)),
                                      subtitle: Text(_currentUser!.phone!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark)),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Pengaturan & Preferensi
                            const Text(
                              'Preferensi Aplikasi',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: SanitaColors.textDark),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: SanitaColors.border),
                              ),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Pengingat Cek Berkala', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: const Text('Notifikasi jadwal inspeksi kebersihan mingguan', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                    value: _notifReminder,
                                    activeColor: SanitaColors.primary,
                                    onChanged: (v) => setState(() => _notifReminder = v),
                                  ),
                                  const Divider(height: 1, indent: 16, endIndent: 16),
                                  SwitchListTile(
                                    title: const Text('Mode Hemat Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: const Text('Kompresi gambar bukti foto laporan', style: TextStyle(fontSize: 11, color: SanitaColors.textMuted)),
                                    value: _dataSaving,
                                    activeColor: SanitaColors.primary,
                                    onChanged: (v) => setState(() => _dataSaving = v),
                                  ),
                                  const Divider(height: 1, indent: 16, endIndent: 16),
                                  ListTile(
                                    leading: const Icon(Icons.cleaning_services_outlined, size: 20, color: SanitaColors.textDark),
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
                                color: SanitaColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: SanitaColors.primary.withOpacity(0.3)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.school_outlined, size: 18, color: SanitaColors.primaryDark),
                                      SizedBox(width: 8),
                                      Text(
                                        'Informasi Proyek Akademik',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanitaColors.primaryDark),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text('Nama: Ribka Lusiana Harahap', style: TextStyle(fontSize: 12, color: SanitaColors.textDark, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 3),
                                  Text('NIM: 243301631022', style: TextStyle(fontSize: 12, color: SanitaColors.textDark)),
                                  SizedBox(height: 3),
                                  Text('Dosen Pengampu: Riky Suherman Simanjuntak, S.K.M., M.K.M.', style: TextStyle(fontSize: 12, color: SanitaColors.textDark)),
                                  SizedBox(height: 3),
                                  Text('Mata Kuliah: Sanitasi dan Lingkungan Kerja', style: TextStyle(fontSize: 12, color: SanitaColors.textDark)),
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