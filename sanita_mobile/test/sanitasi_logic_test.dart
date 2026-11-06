import 'package:flutter_test/flutter_test.dart';
import 'package:sanita_mobile/core/models/models.dart';
import 'package:sanita_mobile/core/repositories/sanitasiRepository.dart';

void main() {
  group('SANITA Checklist Evaluation & Business Logic Tests', () {
    final repo = SanitasiRepository();

    test('All 6 positive checklist conditions produce 100% compliance', () async {
      final result = await repo.submitChecklist(
        lokasi: 'kampus unpri',
        airBersih: true,
        toiletBersih: true,
        tempatSampah: true,
        ventilasiUdara: true,
        bebasGenangan: true,
        kebersihanArea: true,
      );

      expect(result.skorTerpenuhi, 6);
      expect(result.totalKondisi, 6);
      expect(result.persentase, 100.0);
      expect(result.statusHasil, 'Semua kondisi checklist terpenuhi');
      expect(result.saranTindak, contains('Checklist terpenuhi: 6/6'));
      expect(result.checksumSHA256.isNotEmpty, true);
    });

    test('Partial checklist conditions identify missing items and give recommendations', () async {
      final result = await repo.submitChecklist(
        lokasi: 'Area Pantry Lantai 2',
        airBersih: true,
        toiletBersih: false,
        tempatSampah: false,
        ventilasiUdara: true,
        bebasGenangan: true,
        kebersihanArea: true,
      );

      expect(result.skorTerpenuhi, 4);
      expect(result.totalKondisi, 6);
      expect(result.poinPerbaikan.length, 2);
      expect(result.statusHasil, 'Kondisi Sanitasi Cukup Memadai');
    });
  });
}