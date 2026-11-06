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
  final _usernameCtrl = TextEditingController(text: 'ribka');
  final _passwordCtrl = TextEditingController(text: 'password123');
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
        _showError('Username atau password salah. Silakan periksa kembali.');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
              const Center(
                child: Text(
                  'Masuk ke SANITA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SanitaColors.textDark),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Aplikasi Sanitasi dan Lingkungan Kerja',
                  style: TextStyle(fontSize: 13, color: SanitaColors.textMuted),
                ),
              ),
              const SizedBox(height: 36),

              // Username / Email Field
              const Text('Username atau Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  hintText: 'Masukkan username atau email Anda',
                  prefixIcon: const Icon(Icons.person_outline, size: 20, color: SanitaColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SanitaColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SanitaColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              // Password Field
              const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SanitaColors.textDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Masukkan password Anda',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: SanitaColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: SanitaColors.textMuted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SanitaColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SanitaColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 28),

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

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ', style: TextStyle(fontSize: 13, color: SanitaColors.textMuted)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
                    },
                    child: const Text('Daftar di sini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SanitaColors.primary)),
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
