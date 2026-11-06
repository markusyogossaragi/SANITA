import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

enum SessionType { none, user, admin }

class SessionService {
  SessionService._();
  static final SessionService _instance = SessionService._();
  factory SessionService() => _instance;

  static const String _typeKey = 'sanita_session_type';
  static const String _userKey = 'sanita_session_user';
  static const String _tokenKey = 'sanita_session_token';
  static const String _expiryKey = 'sanita_session_expiry';

  Future<void> saveSession({
    required UserModel user,
    required String token,
    Duration duration = const Duration(days: 7),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_typeKey, user.role == 'admin' ? 'admin' : 'user');
    await prefs.setString(_expiryKey, DateTime.now().add(duration).toIso8601String());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_expiryKey);
    if (expiryStr != null) {
      final expiryDate = DateTime.tryParse(expiryStr);
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        await logout();
        return null;
      }
    }
    return prefs.getString(_tokenKey);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<SessionType> getSessionType() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();
    if (token == null) return SessionType.none;

    final type = prefs.getString(_typeKey);
    if (type == 'admin') return SessionType.admin;
    if (type == 'user') return SessionType.user;
    return SessionType.none;
  }

  Future<void> updateUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_typeKey);
    await prefs.remove(_expiryKey);
  }
}