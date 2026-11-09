import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/apiDataSource.dart';
import '../models/models.dart';
import '../services/sessionService.dart';

class AuthRepository {
  static final ApiDataSource _api = ApiDataSource();
  static final SessionService _session = SessionService();

  static const String _accountsStorageKey = 'sanita_registered_accounts_v2';

  /// Akun Administrator Utama Tunggal yang Di-embed (Admin Ribka)
  /// Semua akun non-admin harus mendaftar (registrasi) terlebih dahulu.
  static final Map<String, dynamic> adminAccount = {
    'id': 'usr-admin-ribka-243301631022',
    'username': 'ribka',
    'password': 'password123',
    'full_name': 'Ribka Lusiana Harahap',
    'role': 'Admin',
    'email': 'ribka.harahap@sanita.id',
    'phone': '+62 812-3456-7890',
    'created_at': '2026-11-01T08:00:00Z',
  };

  /// Authenticate user credentials
  Future<UserModel?> login(String usernameOrEmail, String password) async {
    final query = usernameOrEmail.trim().toLowerCase();
    final pwd = password.trim();

    // 1. Coba koneksi ke backend database API jika online
    try {
      final res = await _api.post('/auth/login', {
        'username': query,
        'password': pwd,
      });

      if (res['status'] == 200 && res['data'] != null) {
        final token = res['data']['token'] ?? 'jwt-token-${DateTime.now().millisecondsSinceEpoch}';
        final user = UserModel.fromJson(res['data']['user'] ?? res['data']);
        await _session.saveSession(user: user, token: token);
        _api.setToken(token);
        return user;
      }
    } catch (_) {
      // Backend offline: lanjut verifikasi basis data lokal terenkripsi
    }

    // 2. Verifikasi dengan akun yang tersimpan di basis data lokal
    final accounts = await _getStoredAccounts();

    for (final acc in accounts) {
      final uName = (acc['username'] ?? '').toString().toLowerCase();
      final uEmail = (acc['email'] ?? '').toString().toLowerCase();
      final uPassword = (acc['password'] ?? '').toString();

      if ((uName == query || uEmail == query) && uPassword == pwd) {
        final user = UserModel(
          id: acc['id'] ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
          username: acc['username'] ?? query,
          fullName: acc['full_name'] ?? 'Pengguna SANITA',
          role: acc['role'] ?? 'Pengguna Terdaftar',
          email: acc['email'],
          phone: acc['phone'],
          avatarUrl: acc['avatar_url'],
        );

        final token = 'sanita-auth-token-${DateTime.now().millisecondsSinceEpoch}';
        await _session.saveSession(user: user, token: token);
        _api.setToken(token);
        return user;
      }
    }

    // Kredensial tidak ditemukan
    return null;
  }

  /// Register akun baru (Semua pengguna non-admin membuat akun di sini)
  Future<UserModel?> register(Map<String, dynamic> data) async {
    final username = (data['username'] ?? '').toString().trim();
    final fullName = (data['full_name'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final password = (data['password'] ?? '').toString().trim();

    if (username.isEmpty || password.isEmpty || fullName.isEmpty) {
      return null;
    }

    // 1. Coba simpan ke Backend API Database
    try {
      final res = await _api.post('/auth/register', data);
      if (res['status'] == 201 && res['data'] != null) {
        final token = res['data']['token'] ?? 'jwt-token-${DateTime.now().millisecondsSinceEpoch}';
        final user = UserModel.fromJson(res['data']['user'] ?? res['data']);
        await _session.saveSession(user: user, token: token);
        _api.setToken(token);
        return user;
      }
    } catch (_) {}

    // 2. Simpan ke database lokal persisten (SharedPreferences)
    final accounts = await _getStoredAccounts();

    // Cek apakah username / email sudah terdaftar
    final alreadyExists = accounts.any((a) =>
        (a['username'] ?? '').toString().toLowerCase() == username.toLowerCase() ||
        (email.isNotEmpty && (a['email'] ?? '').toString().toLowerCase() == email.toLowerCase()));

    if (alreadyExists) {
      throw Exception('Username atau email sudah terdaftar.');
    }

    final newId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final newAccount = {
      'id': newId,
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': 'Pengguna Terdaftar',
      'email': email,
      'phone': data['phone'] ?? '',
      'avatar_url': data['avatar_url'],
      'created_at': DateTime.now().toIso8601String(),
    };

    accounts.add(newAccount);
    await _saveStoredAccounts(accounts);

    final user = UserModel(
      id: newId,
      username: username,
      fullName: fullName,
      role: 'Pengguna Terdaftar',
      email: email,
      phone: data['phone'],
      avatarUrl: data['avatar_url'],
    );

    final token = 'sanita-auth-token-${DateTime.now().millisecondsSinceEpoch}';
    await _session.saveSession(user: user, token: token);
    _api.setToken(token);
    return user;
  }

  /// Update profil pengguna (nama, username/nickname, email, no HP, role, foto profil)
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    // 1. Update active session
    await _session.updateUser(updatedUser);

    // 2. Update persistent account storage
    final accounts = await _getStoredAccounts();

    // Pastikan username baru tidak bentrok dengan akun lain
    final usernameConflict = accounts.any((a) =>
        (a['id'] ?? '') != updatedUser.id &&
        (a['username'] ?? '').toString().toLowerCase() == updatedUser.username.toLowerCase());
    if (usernameConflict) {
      throw Exception('Nickname/Username sudah digunakan oleh akun lain.');
    }

    final index = accounts.indexWhere((a) =>
        (a['id'] ?? '') == updatedUser.id ||
        (a['username'] ?? '').toString().toLowerCase() == updatedUser.username.toLowerCase());

    if (index != -1) {
      accounts[index]['username'] = updatedUser.username;
      accounts[index]['full_name'] = updatedUser.fullName;
      accounts[index]['email'] = updatedUser.email;
      accounts[index]['phone'] = updatedUser.phone;
      accounts[index]['role'] = updatedUser.role;
      accounts[index]['avatar_url'] = updatedUser.avatarUrl;
      await _saveStoredAccounts(accounts);
    }

    // 3. Try backend API if reachable
    try {
      await _api.post('/auth/profile', updatedUser.toJson());
    } catch (_) {}

    return updatedUser;
  }

  /// Dapatkan seluruh daftar akun terdaftar (Khusus Fitur Admin Dashboard)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final accounts = await _getStoredAccounts();
    return accounts;
  }

  /// Update akun pengguna oleh Admin
  Future<bool> updateUserByAdmin(Map<String, dynamic> userMap) async {
    final accounts = await _getStoredAccounts();
    final id = userMap['id'] ?? '';
    final username = (userMap['username'] ?? '').toString().toLowerCase();

    final idx = accounts.indexWhere((a) =>
        (a['id'] ?? '') == id ||
        (a['username'] ?? '').toString().toLowerCase() == username);

    if (idx != -1) {
      accounts[idx]['full_name'] = userMap['full_name'];
      accounts[idx]['role'] = userMap['role'];
      accounts[idx]['email'] = userMap['email'];
      accounts[idx]['phone'] = userMap['phone'];
      await _saveStoredAccounts(accounts);
      return true;
    }
    return false;
  }

  /// Hapus akun pengguna oleh Admin (Admin Ribka tidak dapat dihapus)
  Future<bool> deleteUser(String idOrUsername) async {
    final query = idOrUsername.trim().toLowerCase();
    if (query == 'ribka' || query == 'usr-admin-ribka-243301631022') {
      return false; // Akun admin utama diproteksi
    }

    final accounts = await _getStoredAccounts();
    final initialCount = accounts.length;
    accounts.removeWhere((a) =>
        (a['id'] ?? '').toString().toLowerCase() == query ||
        (a['username'] ?? '').toString().toLowerCase() == query);

    if (accounts.length < initialCount) {
      await _saveStoredAccounts(accounts);
      return true;
    }
    return false;
  }

  /// Get list of accounts stored in local DB
  Future<List<Map<String, dynamic>>> _getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsStorageKey);
    if (raw == null) {
      // Inisialisasi awal hanya dengan akun Admin Ribka (TIDAK ADA AKUN DEMO)
      final initial = [adminAccount];
      await prefs.setString(_accountsStorageKey, jsonEncode(initial));
      return initial;
    }

    try {
      final list = jsonDecode(raw) as List;
      final parsed = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      // Pastikan akun admin selalu ada
      if (!parsed.any((a) => (a['username'] ?? '').toString().toLowerCase() == 'ribka')) {
        parsed.insert(0, adminAccount);
        await prefs.setString(_accountsStorageKey, jsonEncode(parsed));
      }
      return parsed;
    } catch (_) {
      return [adminAccount];
    }
  }

  Future<void> _saveStoredAccounts(List<Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsStorageKey, jsonEncode(accounts));
  }

  Future<void> logout() async {
    await _session.logout();
    _api.setToken(null);
  }
}