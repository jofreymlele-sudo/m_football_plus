import 'package:flutter_test/flutter_test.dart';
import 'package:m_football_plus/main.dart';

void main() {
  testWidgets('App root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MFootballPlusApp());
    expect(find.byType(MFootballPlusApp), findsOneWidget);
  });
}
