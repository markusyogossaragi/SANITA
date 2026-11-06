import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/apiDataSource.dart';
import '../models/models.dart';
import '../services/sessionService.dart';

class AuthRepository {
  static final ApiDataSource _api = ApiDataSource();
  static final SessionService _session = SessionService();

  static const String _accountsStorageKey = 'sanita_registered_accounts_v1';

  /// Pre-seeded default real account
  static final Map<String, dynamic> _defaultAccount = {
    'id': 'usr-001',
    'username': 'ribka',
    'password': 'password123',
    'full_name': 'Ribka Lusiana Harahap',
    'role': 'Inspektur Sanitasi & K3',
    'email': 'ribka.harahap@sanita.id',
    'phone': '+62 812-3456-7890',
  };

  /// Authenticate user credentials
  Future<UserModel?> login(String usernameOrEmail, String password) async {
    final query = usernameOrEmail.trim().toLowerCase();
    final pwd = password.trim();

    // 1. Try backend API first
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
      // Backend offline: proceed with local database verification
    }

    // 2. Verify with stored accounts
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
          role: acc['role'] ?? 'Inspektur Sanitasi',
          email: acc['email'],
          phone: acc['phone'],
        );

        final token = 'sanita-auth-token-${DateTime.now().millisecondsSinceEpoch}';
        await _session.saveSession(user: user, token: token);
        _api.setToken(token);
        return user;
      }
    }

    // Credentials do not match
    return null;
  }

  /// Register a new account
  Future<UserModel?> register(Map<String, dynamic> data) async {
    final username = (data['username'] ?? '').toString().trim();
    final fullName = (data['full_name'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final password = (data['password'] ?? '').toString().trim();

    if (username.isEmpty || password.isEmpty || fullName.isEmpty) {
      return null;
    }

    // 1. Try backend API
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

    // 2. Save into local persistent storage
    final accounts = await _getStoredAccounts();

    // Check if username/email already exists
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
      'role': 'Inspektur Kesling',
      'email': email,
      'phone': data['phone'] ?? '',
    };

    accounts.add(newAccount);
    await _saveStoredAccounts(accounts);

    final user = UserModel(
      id: newId,
      username: username,
      fullName: fullName,
      role: 'Inspektur Kesling',
      email: email,
      phone: data['phone'],
    );

    final token = 'sanita-auth-token-${DateTime.now().millisecondsSinceEpoch}';
    await _session.saveSession(user: user, token: token);
    _api.setToken(token);
    return user;
  }

  /// Update profile details for current user
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    // 1. Update active session
    await _session.updateUser(updatedUser);

    // 2. Update persistent account storage
    final accounts = await _getStoredAccounts();
    final index = accounts.indexWhere((a) =>
        (a['id'] ?? '') == updatedUser.id ||
        (a['username'] ?? '').toString().toLowerCase() == updatedUser.username.toLowerCase());

    if (index != -1) {
      accounts[index]['full_name'] = updatedUser.fullName;
      accounts[index]['email'] = updatedUser.email;
      accounts[index]['phone'] = updatedUser.phone;
      accounts[index]['role'] = updatedUser.role;
      await _saveStoredAccounts(accounts);
    }

    // 3. Try backend API if reachable
    try {
      await _api.post('/auth/profile', updatedUser.toJson());
    } catch (_) {}

    return updatedUser;
  }

  /// Get list of accounts stored
  Future<List<Map<String, dynamic>>> _getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsStorageKey);
    if (raw == null) {
      // First time: initialize with pre-seeded account
      final initial = [_defaultAccount];
      await prefs.setString(_accountsStorageKey, jsonEncode(initial));
      return initial;
    }

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [_defaultAccount];
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
