import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService _instance = SecurityService._();
  factory SecurityService() => _instance;

  static const String _hmacSecret = 'sanita-tamper-proof-hmac-key-2026';

  /// Computes HMAC-SHA256 signature for environmental report payload
  String computeReportHMAC({
    required String id,
    required String category,
    required String location,
    required String description,
    required String timestamp,
  }) {
    final raw = '$id|$category|$location|$description|$timestamp';
    return generateHMAC(raw);
  }

  /// Generates HMAC-SHA256 string for any raw payload
  String generateHMAC(String raw) {
    final hmac = Hmac(sha256, utf8.encode(_hmacSecret));
    return hmac.convert(utf8.encode(raw)).toString();
  }

  /// Verifies if report payload matches its HMAC signature
  bool verifyReportIntegrity({
    required String id,
    required String category,
    required String location,
    required String description,
    required String timestamp,
    required String signature,
  }) {
    final expected = computeReportHMAC(
      id: id,
      category: category,
      location: location,
      description: description,
      timestamp: timestamp,
    );
    return expected == signature;
  }

  /// Computes SHA-256 Checksum for checklist inspection
  String computeChecklistSHA256(String rawData) {
    return sha256.convert(utf8.encode(rawData)).toString();
  }
}