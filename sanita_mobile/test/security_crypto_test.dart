import 'package:flutter_test/flutter_test.dart';
import 'package:sanita_mobile/core/services/securityService.dart';
import 'package:sanita_mobile/core/utils/inputSanitizer.dart';

void main() {
  group('SANITA Maximum Anti-Breach & Security Tests', () {
    final security = SecurityService();

    test('HMAC-SHA256 signature generation and integrity verification', () {
      const id = 'lap-test-001';
      const cat = 'Kebersihan Toilet';
      const loc = 'kampus unpri';
      const desc = 'Lantai basah dan kotor';
      const timestamp = '2026-11-06T17:00:00Z';

      final sig = security.computeReportHMAC(
        id: id,
        category: cat,
        location: loc,
        description: desc,
        timestamp: timestamp,
      );

      expect(sig.length, 64);

      final isValid = security.verifyReportIntegrity(
        id: id,
        category: cat,
        location: loc,
        description: desc,
        timestamp: timestamp,
        signature: sig,
      );
      expect(isValid, true);

      // Tampering attempt
      final isTamperedValid = security.verifyReportIntegrity(
        id: id,
        category: cat,
        location: loc,
        description: 'Lantai BERSIH SEKALI (MODIFIED BY ATTACKER)',
        timestamp: timestamp,
        signature: sig,
      );
      expect(isTamperedValid, false);
    });

    test('Anti-XSS InputSanitizer strips malicious tags and escapes entities', () {
      const dirty = '<script>alert("pwned")</script>Kampus Unpri & Co';
      final clean = InputSanitizer.sanitize(dirty);

      expect(clean.contains('<script>'), false);
      expect(clean.contains('&amp;'), true);
      expect(clean.contains('Kampus Unpri'), true);
    });
  });
}