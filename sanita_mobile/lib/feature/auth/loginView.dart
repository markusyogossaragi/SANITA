import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/repositories/authRepository.dart';
import '../../main.dart';
import 'registerView.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authRepo = AuthRepository();

  void _login() async {
    final query = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (query.isEmpty || password.isEmpty) {
      _showError('Username/email dan password wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authRepo.login(query, password);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SanitaColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('Selamat datang kembali, ${user.fullName}!'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        _showError('Username atau password tidak cocok dalam basis data.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal masuk: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SanitaColors.alertRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: isDark ? SanitaColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: SanitaColors.primary.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: SanitaColors.primary, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Masuk ke SANITA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Aplikasi Sanitasi dan Lingkungan Kerja',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Username / Email Field
              Text(
                'Username atau Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : SanitaColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameCtrl,
                style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan username atau email Anda',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(Icons.person_outline, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : SanitaColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan password Anda',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: SanitaColors.primary),
                  filled: true,
                  fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: SanitaColors.textMuted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 26),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SanitaColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Masuk ke Aplikasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style: TextStyle(fontSize: 13, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
                    },
                    child: const Text('Daftar Akun Baru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SanitaColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}