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
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedRole;
  File? _avatarFile;

  bool _isSaving = false;
  final _authRepo = AuthRepository();

  final List<String> _roleOptions = [
    'Admin',
    'Inspektur Kesling',
    'Inspektur Sanitasi & K3',
    'Koordinator Sanitasi',
    'Staf Kebersihan & Sarana',
    'Dosen Kesehatan Lingkungan',
    'Mahasiswa Kesling',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentUser.fullName);
    _emailCtrl = TextEditingController(text: widget.currentUser.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.currentUser.phone ?? '');

    if (widget.currentUser.avatarUrl != null &&
        widget.currentUser.avatarUrl!.isNotEmpty &&
        File(widget.currentUser.avatarUrl!).existsSync()) {
      _avatarFile = File(widget.currentUser.avatarUrl!);
    }

    // Select role or fallback to first option
    if (_roleOptions.contains(widget.currentUser.role)) {
      _selectedRole = widget.currentUser.role;
    } else {
      _selectedRole = _roleOptions.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _pickAvatar() {
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
                  'Ubah Foto Profil',
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
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();

    if (newName.isEmpty) {
      _showWarning('Nama lengkap wajib diisi.');
      return;
    }

    setState(() => _isSaving = true);

    final updatedUser = UserModel(
      id: widget.currentUser.id,
      username: widget.currentUser.username,
      fullName: newName,
      role: _selectedRole,
      email: newEmail.isNotEmpty ? newEmail : widget.currentUser.email,
      phone: newPhone.isNotEmpty ? newPhone : widget.currentUser.phone,
      avatarUrl: _avatarFile != null ? _avatarFile!.path : widget.currentUser.avatarUrl,
    );

    try {
      if (_avatarFile != null) {
        final prefs = await SharedPreferences.getInstance();
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
              Text('Profil berhasil diperbarui!'),
            ],
          ),
        ),
      );

      // Return updated user to ProfilView
      Navigator.pop(context, updatedUser);
    } catch (e) {
      setState(() => _isSaving = false);
      _showWarning('Gagal menyimpan profil: ${e.toString()}');
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
                // Avatar with Camera Icon (Tappable)
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
                            child: _avatarFile != null
                                ? Image.file(_avatarFile!, fit: BoxFit.cover, width: 96, height: 96)
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
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '@${widget.currentUser.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Nama Lengkap
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

                // Email
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

                // Nomor Telepon / Kontak
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

                // Peran / Jabatan Sanitasi
                Text(
                  'Peran / Jabatan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SanitaColors.textDark,
                  ),
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
                  items: _roleOptions.map((r) {
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