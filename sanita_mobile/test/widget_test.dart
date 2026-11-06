import 'package:flutter_test/flutter_test.dart';
import 'package:sanita_mobile/main.dart';

void main() {
  testWidgets('SANITA Mobile App launches cleanly without error', (WidgetTester tester) async {
    await tester.pumpWidget(const SanitaApp());
    expect(find.text('SANITA'), findsWidgets);
    expect(find.text('Sanitasi dan Lingkungan Kerja'), findsWidgets);
  });
}