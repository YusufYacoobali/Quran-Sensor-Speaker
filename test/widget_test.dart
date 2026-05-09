import 'package:flutter_test/flutter_test.dart';
import 'package:quran_speaker/main.dart';

void main() {
  testWidgets('renders the Quran speaker dashboard', (tester) async {
    await tester.pumpWidget(const QuranSpeakerApp());

    expect(find.text('Quran Speaker'), findsOneWidget);
    expect(find.text('Qari Speaker 01'), findsOneWidget);
    expect(find.text('Bedroom Speaker'), findsOneWidget);
  });
}
