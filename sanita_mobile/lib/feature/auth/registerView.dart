import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/repositories/authRepository.dart';
import '../../main.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authRepo = AuthRepository();

  void _register() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      _showWarning('Lengkapi semua kolom formulir pendaftaran.');
      return;
    }

    if (password.length < 6) {
      _showWarning('Password minimal 6 karakter.');
      return;
    }

    if (password != confirmPassword) {
      _showWarning('Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authRepo.register({
        'username': username,
        'full_name': name,
        'email': email,
        'password': password,
      });

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SanitaColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('Selamat datang, ${user.fullName}! Akun berhasil dibuat.'),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        _showWarning('Pendaftaran gagal. Silakan coba kembali.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showWarning(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SanitaColors.alertRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelColor = isDark ? Colors.white : SanitaColors.textDark;
    final hintColor = isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400;
    final fieldFillColor = isDark ? SanitaColors.darkCard : Colors.white;
    final borderColor = isDark ? SanitaColors.darkBorder : SanitaColors.border;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Akun SANITA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: isDark ? SanitaColors.darkSurface : SanitaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrasi Pengguna Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: labelColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Daftar untuk mengakses sistem pelaporan dan sanitasi kerja.',
                style: TextStyle(fontSize: 12, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Nama Lengkap
              Text('Nama Lengkap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: labelColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap Anda',
                  hintStyle: TextStyle(fontSize: 13, color: hintColor),
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: fieldFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Username
              Text('Username', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameCtrl,
                style: TextStyle(color: labelColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan username Anda',
                  hintStyle: TextStyle(fontSize: 13, color: hintColor),
                  prefixIcon: const Icon(Icons.person_outline, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: fieldFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: labelColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan alamat email Anda',
                  hintStyle: TextStyle(fontSize: 13, color: hintColor),
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: fieldFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: TextStyle(color: labelColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan password Anda',
                  hintStyle: TextStyle(fontSize: 13, color: hintColor),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: fieldFillColor,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: SanitaColors.textMuted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Konfirmasi Password
              Text('Konfirmasi Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscurePassword,
                style: TextStyle(color: labelColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ketik ulang password Anda',
                  hintStyle: TextStyle(fontSize: 13, color: hintColor),
                  prefixIcon: const Icon(Icons.lock_reset, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: fieldFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 28),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SanitaColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftar Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}