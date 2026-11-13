import 'package:flutter_test/flutter_test.dart';
import 'package:m_football_plus/firebase_service.dart';
import 'package:m_football_plus/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Panel End-To-End Verification Tests', () {
    test('1. Security & AuthService Authentication', () async {
      final auth = AuthService();
      // Starts as guest for complete security
      await auth.signOut();
      expect(auth.isOwner, isFalse);
      expect(auth.isGuest, isTrue);

      // Test regular fan Google Sign In (e.g. shabiki@gmail.com)
      await auth.signInWithGoogle(email: 'shabiki@gmail.com', displayName: 'Shabiki Soka');
      expect(auth.isOwner, isFalse);
      expect(auth.isGuest, isFalse);
      expect(auth.activeEmail, equals('shabiki@gmail.com'));

      // Test owner Google Sign In (jofreymlele@gmail.com) - Password/PIN free
      await auth.signInWithGoogle(email: AuthService.ownerEmail, displayName: 'Jofrey Mlele');
      expect(auth.isOwner, isTrue);
      expect(auth.isGuest, isFalse);
      expect(auth.activeEmail, equals('jofreymlele@gmail.com'));

      // Test sign out back to guest
      await auth.signOut();
      expect(auth.isOwner, isFalse);
      expect(auth.isGuest, isTrue);
    });

    test('2. Publishing Top Story to Firestore & Realtime Streaming', () async {
      final firestore = FirestoreService();

      final story = NewsArticleModel(
        id: 'test_story_777',
        title: 'Yanga Sign Top Striker',
        titleSw: 'Yanga Yasajili Mshambuliaji Hatari',
        description: 'Detailed English description',
        descriptionSw: 'Maelezo ya kina ya Kiswahili',
        imageUrl: 'https://i.postimg.cc/test/image.jpg',
        publishedAt: 'Sasa Hivi',
        source: 'M-Football Plus (Mmiliki)',
        category: 'tanzania',
      );

      await firestore.publishNews(story);
      expect(firestore.localNews.any((s) => s.id == 'test_story_777'), isTrue);

      // Verify combined news includes the story
      final combined = firestore.localNews;
      expect(combined.first.id, equals('test_story_777'));

      // Test Deletion
      await firestore.deleteNews('test_story_777');
      expect(firestore.localNews.any((s) => s.id == 'test_story_777'), isFalse);
    });

    test('3. Publishing Expert Analysis & Realtime Streaming', () async {
      final firestore = FirestoreService();

      final analysis = {
        'id': 123456,
        'name': 'Jofrey Mlele',
        'roleSw': 'Mchambuzi wa Kimbinu',
        'roleEn': 'Tactical Analyst',
        'avatar': 'https://i.postimg.cc/test/avatar.jpg',
        'match': 'Yanga vs Simba',
        'league': 'NBC PL',
        'headlineSw': 'Uchambuzi wa Mbinu za Kariakoo Derby',
        'headlineEn': 'Tactical Analysis of Kariakoo Derby',
        'contentSw': 'Mbinu za viungo...',
        'contentEn': 'Midfield battle...',
        'tag': '#KariakooDerby',
      };

      await firestore.publishAnalysis(analysis);
      expect(firestore.localAnalyses.any((a) => a['id'] == 123456), isTrue);

      // Test Deletion
      await firestore.deleteAnalysis(123456);
      expect(firestore.localAnalyses.any((a) => a['id'] == 123456), isFalse);
    });

    test('4. Launching Fan Poll, Voting & Realtime Tallying', () async {
      final firestore = FirestoreService();

      final poll = {
        'id': 654321,
        'question': 'Nani atachukua Ubingwa wa NBC PL?',
        'subtitle': 'Ligi Kuu ya NBC 2024/2025',
        'options': [
          {'title': 'Yanga', 'color': 0xFF00FFFF},
          {'title': 'Simba', 'color': 0xFFFFBF00},
          {'title': 'Azam FC', 'color': 0xFF64FFDA},
        ],
        'votesMap': {0: 10, 1: 5, 2: 2},
      };

      await firestore.publishPoll(poll);
      expect(firestore.localPolls.any((p) => p['id'] == 654321), isTrue);

      // Test voting
      await firestore.votePoll(654321, 0);
      final updated = firestore.localPolls.firstWhere((p) => p['id'] == 654321);
      expect(updated['votesMap'][0], equals(11));

      // Test Deletion
      await firestore.deletePoll(654321);
      expect(firestore.localPolls.any((p) => p['id'] == 654321), isFalse);
    });
  });
}
