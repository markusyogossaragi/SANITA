import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/repositories/authRepository.dart';

class EditProfilView extends StatefulWidget {
  final UserModel currentUser;

  const EditProfilView({super.key, required this.currentUser});

  @override
  State<EditProfilView> createState() => _EditProfilViewState();
}

class _EditProfilViewState extends State<EditProfilView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedRole;
  late List<String> _availableRoles;
  late bool _isRibkaAdmin;

  File? _avatarFile;
  bool _isAvatarRemoved = false;
  bool _isSaving = false;
  final _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentUser.fullName);
    _usernameCtrl = TextEditingController(text: widget.currentUser.username);
    _emailCtrl = TextEditingController(text: widget.currentUser.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.currentUser.phone ?? '');

    // Cek apakah akun adalah Ribka (Admin Utama)
    final usernameLower = widget.currentUser.username.toLowerCase();
    final nameLower = widget.currentUser.fullName.toLowerCase();
    _isRibkaAdmin = usernameLower == 'ribka' || nameLower.contains('ribka') || widget.currentUser.id.contains('ribka');

    // Role options: Admin HANYA dapat diatur/dipilih oleh Ribka. Pengguna lain bebas memilih peran sanitasi lainnya.
    if (_isRibkaAdmin) {
      _availableRoles = [
        'Admin',
        'Inspektur Kesling',
        'Inspektur Sanitasi & K3',
        'Koordinator Sanitasi',
        'Staf Kebersihan & Sarana',
        'Dosen Kesehatan Lingkungan',
        'Mahasiswa Kesling',
        'Pengguna Terdaftar',
      ];
    } else {
      _availableRoles = [
        'Inspektur Kesling',
        'Inspektur Sanitasi & K3',
        'Koordinator Sanitasi',
        'Staf Kebersihan & Sarana',
        'Dosen Kesehatan Lingkungan',
        'Mahasiswa Kesling',
        'Pengguna Terdaftar',
      ];
    }

    if (_availableRoles.contains(widget.currentUser.role)) {
      _selectedRole = widget.currentUser.role;
    } else {
      _selectedRole = _availableRoles.first;
    }

    if (widget.currentUser.avatarUrl != null &&
        widget.currentUser.avatarUrl!.isNotEmpty &&
        File(widget.currentUser.avatarUrl!).existsSync()) {
      _avatarFile = File(widget.currentUser.avatarUrl!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _pickAvatar() {
    final hasPhoto = !_isAvatarRemoved && (_avatarFile != null || (widget.currentUser.avatarUrl != null && widget.currentUser.avatarUrl!.isNotEmpty));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            color: isDark ? SanitaColors.darkSurface : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kelola Foto Profil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: SanitaColors.primary),
                  title: Text(
                    'Ambil Foto Kamera',
                    style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: SanitaColors.primary),
                  title: Text(
                    'Pilih dari Galeri',
                    style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectImage(ImageSource.gallery);
                  },
                ),
                if (hasPhoto) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: SanitaColors.alertRed),
                    title: const Text(
                      'Hapus Foto Profil',
                      style: TextStyle(color: SanitaColors.alertRed, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _avatarFile = null;
                        _isAvatarRemoved = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Foto profil ditandai untuk dihapus saat disimpan.'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 600, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _avatarFile = File(picked.path);
          _isAvatarRemoved = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameCtrl.text.trim();
    final newUsername = _usernameCtrl.text.trim().toLowerCase();
    final newEmail = _emailCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();

    if (newName.isEmpty) {
      _showWarning('Nama lengkap wajib diisi.');
      return;
    }
    if (newUsername.isEmpty) {
      _showWarning('Nickname/Username wajib diisi.');
      return;
    }

    setState(() => _isSaving = true);

    String? finalAvatarUrl;
    if (_isAvatarRemoved) {
      finalAvatarUrl = null;
    } else if (_avatarFile != null) {
      finalAvatarUrl = _avatarFile!.path;
    } else {
      finalAvatarUrl = widget.currentUser.avatarUrl;
    }

    final updatedUser = UserModel(
      id: widget.currentUser.id,
      username: newUsername,
      fullName: newName,
      role: _selectedRole,
      email: newEmail.isNotEmpty ? newEmail : widget.currentUser.email,
      phone: newPhone.isNotEmpty ? newPhone : widget.currentUser.phone,
      avatarUrl: finalAvatarUrl,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isAvatarRemoved) {
        await prefs.remove('sanita_avatar_${updatedUser.id}');
      } else if (_avatarFile != null) {
        await prefs.setString('sanita_avatar_${updatedUser.id}', _avatarFile!.path);
      }

      await _authRepo.updateProfile(updatedUser);
      setState(() => _isSaving = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: SanitaColors.primary,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profil & Nickname berhasil diperbarui!'),
            ],
          ),
        ),
      );

      // Kembalikan objek user yang diperbarui ke ProfilView
      Navigator.pop(context, updatedUser);
    } catch (e) {
      setState(() => _isSaving = false);
      _showWarning(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SanitaColors.alertRed,
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool hasValidAvatar = !_isAvatarRemoved && (
      _avatarFile != null || (
        widget.currentUser.avatarUrl != null &&
        widget.currentUser.avatarUrl!.isNotEmpty &&
        File(widget.currentUser.avatarUrl!).existsSync()
      )
    );

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : SanitaColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? SanitaColors.darkSurface : SanitaColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Profil Pengguna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar with Camera Icon (Tappable: Edit / Hapus)
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: isDark ? SanitaColors.darkCard : SanitaColors.primarySurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? SanitaColors.darkBorder : SanitaColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: hasValidAvatar
                                ? (_avatarFile != null
                                    ? Image.file(_avatarFile!, fit: BoxFit.cover, width: 96, height: 96)
                                    : Image.file(File(widget.currentUser.avatarUrl!), fit: BoxFit.cover, width: 96, height: 96))
                                : const Icon(Icons.person, size: 54, color: SanitaColors.primary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: SanitaColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    hasValidAvatar ? 'Ketuk foto untuk ganti atau hapus' : 'Ketuk untuk menambahkan foto profil',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 1. Username
                Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usernameCtrl,
                  style: TextStyle(
                    color: isDark ? Colors.white : SanitaColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alternate_email, size: 20, color: SanitaColors.primary),
                    hintText: 'Masukkan username',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400),
                    filled: true,
                    fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SanitaColors.primary, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Username tidak boleh kosong';
                    if (val.trim().length < 3) return 'Minimal 3 karakter';
                    if (val.trim().contains(' ')) return 'Username tidak boleh menggunakan spasi';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 2. Nama Lengkap
                Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(
                    color: isDark ? Colors.white : SanitaColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: SanitaColors.primary),
                    filled: true,
                    fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SanitaColors.primary, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Nama tidak boleh kosong';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 3. Email
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : SanitaColors.textDark,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, size: 20, color: SanitaColors.primary),
                    filled: true,
                    fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SanitaColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Nomor Telepon / Kontak
                Text(
                  'Nomor Telepon / WhatsApp',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: isDark ? Colors.white : SanitaColors.textDark,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: SanitaColors.primary),
                    filled: true,
                    fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SanitaColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Peran / Jabatan Sanitasi
                Row(
                  children: [
                    Text(
                      'Peran / Jabatan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : SanitaColors.textDark,
                      ),
                    ),
                    if (!_isRibkaAdmin) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Pilih peran Anda)',
                        style: TextStyle(fontSize: 11, color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: isDark ? SanitaColors.darkCard : Colors.white,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.verified_outlined, size: 20, color: SanitaColors.primary),
                    filled: true,
                    fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SanitaColors.primary, width: 2),
                    ),
                  ),
                  items: _availableRoles.map((r) {
                    return DropdownMenuItem<String>(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : SanitaColors.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                    }
                  },
                ),

                const SizedBox(height: 30),

                // Tombol Simpan Perubahan
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Simpan Perubahan Profil',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SanitaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol Batal
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}