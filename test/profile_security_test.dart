import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_football_plus/profile_screen.dart';
import 'package:m_football_plus/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile & Admin Panel Security Tests', () {
    testWidgets('Regular fan (shabiki@gmail.com) cannot see Admin Panel', (tester) async {
      final auth = AuthService();
      await auth.signInWithGoogle(email: 'shabiki@gmail.com', displayName: 'Shabiki Soka');

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(isSwahili: true),
        ),
      );
      await tester.pumpAndSettle();

      // Admin Panel should be completely hidden
      expect(find.text('Paneli ya Msimamizi'), findsNothing);
      expect(find.text('OWNER ONLY'), findsNothing);

      // Should only see Badilisha Lugha and Kuhusu App
      expect(find.text('Badilisha Lugha'), findsOneWidget);
      expect(find.text('Kuhusu App'), findsOneWidget);
    });

    testWidgets('Owner (jofreymlele@gmail.com) sees Admin Panel', (tester) async {
      final auth = AuthService();
      await auth.signInWithGoogle(email: AuthService.ownerEmail, displayName: 'Jofrey Mlele');

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(isSwahili: true),
        ),
      );
      await tester.pumpAndSettle();

      // Admin Panel MUST be visible
      expect(find.text('Paneli ya Msimamizi'), findsOneWidget);
      expect(find.text('OWNER ONLY'), findsOneWidget);

      // Also sees standard settings
      expect(find.text('Badilisha Lugha'), findsOneWidget);
      expect(find.text('Kuhusu App'), findsOneWidget);
    });
  });
}
