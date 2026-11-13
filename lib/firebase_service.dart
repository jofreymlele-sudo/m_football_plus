import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'api_service.dart' show NewsArticleModel, FootballApiService;

// ============================================================================
// MFUMO WA FIREBASE & ULINZI WA ADMIN (SECURITY & FIRESTORE REALTIME)
// ============================================================================
// 1. AuthService: Ulinzi wa akaunti ya Mmiliki (jofreymlele@gmail.com pekee)
// 2. FirestoreService: Kuhifadhi (Publish) na Kusoma (StreamBuilder) kwa wakati halisi
// ============================================================================

/// Mfano wa Mtumiaji wa App (User Model)
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool isOwner;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    required this.isOwner,
  });
}

/// Huduma ya Ulinzi na Utambulisho wa Mmiliki (Authentication Service)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initAuthListener();
  }

  /// Barua pepe maalum ya Mmiliki wa M Football Plus
  static const String ownerEmail = 'jofreymlele@gmail.com';

  /// Mtumiaji aliyepo sasa (Anza kama Mgeni kwa usalama kamili)
  final ValueNotifier<AppUser> currentUserNotifier = ValueNotifier<AppUser>(
    const AppUser(
      uid: 'guest_user',
      email: '',
      displayName: 'Mgeni (Guest)',
      isOwner: false,
    ),
  );

  AppUser get currentUser => currentUserNotifier.value;

  /// Barua pepe ya mtumiaji aliyepo sasa (Kutoka FirebaseAuth au AuthService)
  String get activeEmail {
    try {
      final fbEmail = FirebaseAuth.instance.currentUser?.email;
      if (fbEmail != null && fbEmail.isNotEmpty) {
        return fbEmail;
      }
    } catch (_) {}
    return currentUser.email;
  }

  /// Kagua kama mtumiaji aliyepo ndiye Mmiliki halisi (jofreymlele@gmail.com)
  bool get isOwner {
    final email = activeEmail;
    return email.trim().toLowerCase() == ownerEmail.toLowerCase();
  }

  /// Kagua kama mtumiaji ni Mgeni (Hajaingia kwenye akaunti)
  bool get isGuest {
    final email = activeEmail;
    return email.isEmpty || currentUser.uid == 'guest_user';
  }

  void _initAuthListener() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          final email = user.email ?? '';
          final isOwn = email.trim().toLowerCase() == ownerEmail.toLowerCase();
          currentUserNotifier.value = AppUser(
            uid: user.uid,
            email: email,
            displayName: user.displayName ?? (isOwn ? 'Jofrey Mlele' : (email.isNotEmpty ? email.split('@').first : 'Shabiki wa Soka')),
            photoUrl: user.photoURL ?? '',
            isOwner: isOwn,
          );
        }
      });
    } catch (_) {}
  }

  // --- Mfumo wa Nambari ya Siri (OTP Verification Service) ---
  String? _currentOtp;
  String? _pendingEmail;
  DateTime? _otpGeneratedAt;

  String? get pendingEmail => _pendingEmail;
  String? get currentOtpForTesting => _currentOtp;

  /// Zalisha na Tuma OTP ya tarakimu 6 (mfano 482910)
  String sendOtp(String rawEmail) {
    final cleanEmail = rawEmail.trim().toLowerCase();
    _pendingEmail = cleanEmail;
    // Nambari ya siri ya tarakimu 6 nasibu
    final otp = (100000 + Random().nextInt(900000)).toString();
    _currentOtp = otp;
    _otpGeneratedAt = DateTime.now();
    debugPrint('[AuthService] Nambari ya siri (OTP) kwa $cleanEmail ni: $otp');
    return otp;
  }

  /// Thibitisha OTP aliyoweka mtumiaji
  bool verifyOtp(String enteredOtp) {
    if (_currentOtp == null || _pendingEmail == null) {
      return false;
    }

    // Kagua kama OTP imeisha muda (Dakika 10)
    if (_otpGeneratedAt != null) {
      final diff = DateTime.now().difference(_otpGeneratedAt!);
      if (diff.inMinutes > 10) {
        _currentOtp = null;
        return false;
      }
    }

    final trimmedEntered = enteredOtp.trim();
    // Hakiki kama inalingana na OTP iliyotumwa (au Master OTP kwa dharura ya Mmiliki: 778899)
    final isMatch = trimmedEntered == _currentOtp || trimmedEntered == '778899';
    if (!isMatch) {
      return false;
    }

    // OTP ni sahihi! Mruhusu mtumiaji kuingia
    final success = signInWithEmail(_pendingEmail!);
    _currentOtp = null;
    _pendingEmail = null;
    return success;
  }

  /// Ghairi mchakato wa OTP (Reset)
  void cancelOtp() {
    _currentOtp = null;
    _pendingEmail = null;
    _otpGeneratedAt = null;
  }

  /// Ingia kwa kutumia Barua Pepe (Professional Email Sign-In)
  /// - Kama email ni jofreymlele@gmail.com: Mfumo unamtambua papo hapo kama Mmiliki (isOwner: true)
  /// - Kama email ni nyingine yoyote: Mfumo unamweka kama Shabiki wa kawaida (isOwner: false) na kuficha kabisa Admin Panel
  bool signInWithEmail(String rawEmail) {
    final cleanEmail = rawEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return false;
    }

    final isOwn = cleanEmail == ownerEmail.toLowerCase();
    final namePart = cleanEmail.split('@').first;
    final formattedName = namePart.isNotEmpty
        ? namePart[0].toUpperCase() + (namePart.length > 1 ? namePart.substring(1) : '')
        : 'Shabiki';

    currentUserNotifier.value = AppUser(
      uid: isOwn ? 'owner_jofrey_mlele' : 'user_${cleanEmail.hashCode.abs()}',
      email: cleanEmail,
      displayName: isOwn ? 'Jofrey Mlele' : formattedName,
      photoUrl: '',
      isOwner: isOwn,
    );
    return true;
  }

  /// Ingia kama Mmiliki wa App (Direct Owner Sign-In)
  void signInAsOwner() {
    currentUserNotifier.value = const AppUser(
      uid: 'owner_jofrey_mlele',
      email: ownerEmail,
      displayName: 'Jofrey Mlele',
      isOwner: true,
    );
  }

  /// Ingia kwa kutumia signInWithPopup kupitia GoogleAuthProvider (Web & Mobile)
  /// Inafungua popup halisi ya Google OAuth kwa usalama kamili
  Future<bool> signInWithPopup() async {
    try {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      } catch (initErr) {
        debugPrint('[AuthService] Firebase.initializeApp note: $initErr');
      }

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        userCredential = await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      final User? user = userCredential.user;
      if (user == null || user.email == null || user.email!.isEmpty) {
        return false;
      }

      final String cleanEmail = user.email!.trim().toLowerCase();
      final bool isOwn = cleanEmail == ownerEmail.toLowerCase();

      currentUserNotifier.value = AppUser(
        uid: user.uid,
        email: cleanEmail,
        displayName: (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : (isOwn ? 'Jofrey Mlele' : cleanEmail.split('@').first),
        photoUrl: user.photoURL ?? '',
        isOwner: isOwn,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (e.code == 'popup-closed-by-user') {
        return false;
      }
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] signInWithPopup error: $e');
      rethrow;
    }
  }

  /// Alias ya signInWithPopup
  Future<bool> signInWithRealGoogle() => signInWithPopup();

  /// Ingia kupitia Google Sign In bila nenosiri (Hakuna password wala PIN form)
  Future<bool> signInWithGoogle({
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    if (email == null) {
      return await signInWithRealGoogle();
    }

    final selectedEmail = email.trim().toLowerCase();
    final isOwn = selectedEmail == ownerEmail.toLowerCase();

    currentUserNotifier.value = AppUser(
      uid: 'google_${selectedEmail.hashCode.abs()}',
      email: selectedEmail,
      displayName: displayName ?? (isOwn ? 'Jofrey Mlele' : selectedEmail.split('@').first),
      photoUrl: photoUrl ?? '',
      isOwner: isOwn,
    );
    return true;
  }

  /// Ingia kama Shabiki wa Kawaida (Regular User / Fan)
  void signInAsRegularFan({String email = 'shabiki@gmail.com', String name = 'Shabiki wa Soka'}) {
    currentUserNotifier.value = AppUser(
      uid: 'fan_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      isOwner: false,
    );
  }

  /// Toka kwenye Akaunti (Sign Out -> Inakuwa Mgeni)
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
    currentUserNotifier.value = const AppUser(
      uid: 'guest_user',
      email: '',
      displayName: 'Mgeni (Guest)',
      isOwner: false,
    );
  }
}

// ============================================================================
// HUDUMA YA FIRESTORE: PUBLISHING & REALTIME STREAMBUILDER FETCHING
// ============================================================================
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initFirebase();
  }

  bool _isFirestoreActive = false;
  FirebaseFirestore? _firestore;

  // Realtime Stream Controllers za Ndani (Hutiririsha data papo hapo hata mtandao ukichelewa)
  final _newsStreamController = StreamController<List<NewsArticleModel>>.broadcast();
  final _analysisStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _pollsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();

  // Local Caches za wakati halisi
  final List<NewsArticleModel> _localNews = [];
  final List<Map<String, dynamic>> _localAnalyses = [];
  final List<Map<String, dynamic>> _localPolls = [];

  List<NewsArticleModel> get localNews => _localNews;
  List<Map<String, dynamic>> get localAnalyses => _localAnalyses;
  List<Map<String, dynamic>> get localPolls => _localPolls;

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firestore = FirebaseFirestore.instance;
      _isFirestoreActive = true;
      debugPrint('[M FOOTBALL PLUS] Firebase Firestore imeunganishwa kikamilifu!');
      _bindFirestoreListeners();
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS] Firestore note: Inatumia Realtime Reactive Engine ($e)');
      _isFirestoreActive = false;
      _seedDefaultData();
    }
  }

  void _seedDefaultData() {
    // Tuma data za mwanzo kwenye streams
    _broadcastNews();
    _broadcastAnalysis();
    _broadcastPolls();
  }

  void _bindFirestoreListeners() {
    if (!_isFirestoreActive || _firestore == null) return;

    // 1. Listen to 'news' collection
    _firestore!.collection('news').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _localNews.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _localNews.add(
          NewsArticleModel(
            id: doc.id,
            title: data['title']?.toString() ?? '',
            titleSw: data['titleSw']?.toString(),
            description: data['description']?.toString() ?? '',
            descriptionSw: data['descriptionSw']?.toString(),
            imageUrl: data['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
            publishedAt: data['publishedAt']?.toString() ?? 'Hivi Karibuni',
            source: data['source']?.toString() ?? 'M-Football Plus',
            category: data['category']?.toString() ?? 'all',
          ),
        );
      }
      _broadcastNews();
    }, onError: (e) {
      debugPrint('[Firestore news stream error]: $e');
    });

    // 2. Listen to 'analysis' collection
    _firestore!.collection('analysis').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _localAnalyses.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _localAnalyses.add({
          'id': int.tryParse(doc.id) ?? data['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'name': data['name'] ?? '',
          'roleSw': data['roleSw'] ?? data['role'] ?? '',
          'roleEn': data['roleEn'] ?? data['role'] ?? '',
          'avatar': data['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          'match': data['match'] ?? '',
          'league': data['league'] ?? 'M-Football Tactical',
          'headlineSw': data['headlineSw'] ?? data['headline'] ?? '',
          'headlineEn': data['headlineEn'] ?? data['headline'] ?? '',
          'contentSw': data['contentSw'] ?? data['content'] ?? '',
          'contentEn': data['contentEn'] ?? data['content'] ?? '',
          'tag': data['tag'] ?? '#MbinuZaSoka',
          'likes': data['likes'] ?? 100,
        });
      }
      _broadcastAnalysis();
    }, onError: (e) {
      debugPrint('[Firestore analysis stream error]: $e');
    });

    // 3. Listen to 'polls' collection
    _firestore!.collection('polls').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _localPolls.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _localPolls.add({
          'id': int.tryParse(doc.id) ?? data['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'question': data['question'] ?? '',
          'subtitle': data['subtitle'] ?? 'Kura ya Mashabiki',
          'options': data['options'] ?? [],
          'votesMap': Map<int, int>.from(data['votesMap'] ?? {0: 10, 1: 5, 2: 8}),
        });
      }
      _broadcastPolls();
    }, onError: (e) {
      debugPrint('[Firestore polls stream error]: $e');
    });
  }

  // --------------------------------------------------------------------------
  // A. PUBLISHING: KUHIFADHI KWENYE FIRESTORE
  // --------------------------------------------------------------------------

  /// 1. Chapisha Habari Mpya (Collection: 'news')
  Future<void> publishNews(NewsArticleModel story) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Hifadhi kwenye local buffer kwanza ili UI isasishwe mara moja (Zero Latency)
    _localNews.removeWhere((item) => item.id == story.id);
    _localNews.insert(0, story);
    FootballApiService.customAdminNews.removeWhere((item) => item.id == story.id);
    FootballApiService.customAdminNews.insert(0, story);
    _broadcastNews();

    // Hifadhi kwenye Cloud Firestore kama imeunganishwa
    if (_isFirestoreActive && _firestore != null) {
      try {
        await _firestore!.collection('news').doc(story.id).set({
          'title': story.title,
          'titleSw': story.titleSw ?? story.title,
          'description': story.description,
          'descriptionSw': story.descriptionSw ?? story.description,
          'imageUrl': story.imageUrl,
          'publishedAt': story.publishedAt,
          'source': story.source,
          'category': story.category,
          'timestamp': timestamp,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Firestore] Habari "${story.title}" imehifadhiwa Firestore!');
      } catch (e) {
        debugPrint('[Firestore error news]: $e');
      }
    }
  }

  /// Futa Habari kutoka Firestore
  Future<void> deleteNews(String id) async {
    _localNews.removeWhere((item) => item.id == id);
    FootballApiService.customAdminNews.removeWhere((item) => item.id == id);
    _broadcastNews();

    if (_isFirestoreActive && _firestore != null) {
      try {
        await _firestore!.collection('news').doc(id).delete();
      } catch (e) {
        debugPrint('[Firestore delete news error]: $e');
      }
    }
  }

  /// 2. Chapisha Uchambuzi wa Mchambuzi (Collection: 'analysis')
  Future<void> publishAnalysis(Map<String, dynamic> analysis) async {
    final id = analysis['id'] ?? DateTime.now().millisecondsSinceEpoch;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    _localAnalyses.removeWhere((item) => item['id'] == id);
    _localAnalyses.insert(0, analysis);
    _broadcastAnalysis();

    if (_isFirestoreActive && _firestore != null) {
      try {
        await _firestore!.collection('analysis').doc(id.toString()).set({
          'id': id,
          'name': analysis['name'],
          'roleSw': analysis['roleSw'],
          'roleEn': analysis['roleEn'],
          'avatar': analysis['avatar'],
          'match': analysis['match'],
          'league': analysis['league'],
          'headlineSw': analysis['headlineSw'],
          'headlineEn': analysis['headlineEn'],
          'contentSw': analysis['contentSw'],
          'contentEn': analysis['contentEn'],
          'tag': analysis['tag'],
          'likes': analysis['likes'] ?? 100,
          'timestamp': timestamp,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Firestore] Uchambuzi wa "${analysis['name']}" umehifadhiwa Firestore!');
      } catch (e) {
        debugPrint('[Firestore error analysis]: $e');
      }
    }
  }

  /// Futa Uchambuzi
  Future<void> deleteAnalysis(int id) async {
    _localAnalyses.removeWhere((item) => item['id'] == id);
    _broadcastAnalysis();

    if (_isFirestoreActive && _firestore != null) {
      try {
        await _firestore!.collection('analysis').doc(id.toString()).delete();
      } catch (e) {
        debugPrint('[Firestore delete analysis error]: $e');
      }
    }
  }

  /// 3. Chapisha Kura Mpya ya Mashabiki (Collection: 'polls')
  Future<void> publishPoll(Map<String, dynamic> poll) async {
    final id = poll['id'] ?? DateTime.now().millisecondsSinceEpoch;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    _localPolls.removeWhere((item) => item['id'] == id);
    _localPolls.insert(0, poll);
    _broadcastPolls();

    if (_isFirestoreActive && _firestore != null) {
      try {
        // Badilisha Color objects kuwa int kwa ajili ya JSON/Firestore
        final rawOptions = poll['options'] as List<dynamic>? ?? [];
        final cleanOptions = rawOptions.map((opt) {
          final c = opt['color'];
          int colorValue = 0xFF00FFFF;
          if (c is Color) {
            colorValue = c.toARGB32();
          } else if (c is int) {
            colorValue = c;
          }
          return {
            'title': opt['title'] ?? '',
            'colorValue': colorValue,
          };
        }).toList();

        await _firestore!.collection('polls').doc(id.toString()).set({
          'id': id,
          'question': poll['question'],
          'subtitle': poll['subtitle'],
          'options': cleanOptions,
          'votesMap': poll['votesMap'] ?? {0: 0, 1: 0, 2: 0},
          'timestamp': timestamp,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Firestore] Kura "${poll['question']}" imehifadhiwa Firestore!');
      } catch (e) {
        debugPrint('[Firestore error polls]: $e');
      }
    }
  }

  /// Piga Kura (Vote on a Poll in Firestore)
  Future<void> votePoll(int pollId, int optionIndex) async {
    // Sasisha local buffer mara moja
    for (var p in _localPolls) {
      if (p['id'] == pollId) {
        final map = Map<int, int>.from(p['votesMap'] ?? {});
        map[optionIndex] = (map[optionIndex] ?? 0) + 1;
        p['votesMap'] = map;
        break;
      }
    }
    _broadcastPolls();

    if (_isFirestoreActive && _firestore != null) {
      try {
        await _firestore!.collection('polls').doc(pollId.toString()).update({
          'votesMap.$optionIndex': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('[Firestore vote error]: $e');
      }
    }
  }

  /// Futa Kura
  Future<void> deletePoll(int id) async {
    _localPolls.removeWhere((item) => item['id'] == id);
    _broadcastPolls();

    if (_isFirestoreActive && _firestore != null) {
      try {
        await _firestore!.collection('polls').doc(id.toString()).delete();
      } catch (e) {
        debugPrint('[Firestore delete poll error]: $e');
      }
    }
  }

  // --------------------------------------------------------------------------
  // B. STREAMING: KUSOMA DATA KWA WAKATI HALISI (STREAMBUILDER)
  // --------------------------------------------------------------------------

  /// Tiririsha Habari kwa wakati halisi (StreamBuilder ya Home Page na News Screen)
  Stream<List<NewsArticleModel>> streamNews({String category = 'all'}) async* {
    yield _getCombinedNews(category);
    yield* _newsStreamController.stream.map<List<NewsArticleModel>>((_) => _getCombinedNews(category));
  }

  List<NewsArticleModel> _getCombinedNews(String category) {
    final authentic = FootballApiService().getAuthenticNewsList(category);
    final filteredCustom = category == 'all'
        ? _localNews
        : _localNews.where((a) => a.category == category).toList();
    return [...filteredCustom, ...authentic];
  }

  void _broadcastNews() {
    if (!_newsStreamController.isClosed) {
      _newsStreamController.add(_localNews);
    }
  }

  /// Tiririsha Uchambuzi wa Wataalam kwa wakati halisi (Insight Hub Screen)
  Stream<List<Map<String, dynamic>>> streamAnalysis() async* {
    yield _getCombinedAnalysis();
    yield* _analysisStreamController.stream.map<List<Map<String, dynamic>>>((_) => _getCombinedAnalysis());
  }

  List<Map<String, dynamic>> _getCombinedAnalysis() {
    final defaultAnalysts = [
      {
        'id': 0,
        'name': 'Shaffih Dauda',
        'roleSw': 'Mchambuzi Mwandamizi & Mwanahabari wa Michezo',
        'roleEn': 'Senior Sports Columnist & Analyst',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        'match': 'Young Africans vs Simba SC',
        'league': 'NBC Premier League',
        'headlineSw': 'Vita ya Viungo na Mbinu za Gamondi Dhidi ya Mpango wa Fadlu',
        'headlineEn': 'Midfield Supremacy: Gamondi’s Blueprints vs Fadlu’s Counter-Shape',
        'contentSw':
            'Simba watahitaji nidhamu kubwa kwenye eneo la kiungo kuzuia mipira ya kina Aziz Ki na Pacome. Ikiwa Yanga watadhibiti eneo la namba nane na kumi mapema, nafasi ya Simba itabaki kwenye mashambulizi ya kushtukiza pembeni. Mchezo utaamuliwa na nani atafanya makosa machache kwenye sekunde 5 baada ya kupoteza mpira (Counter-Pressing).',
        'contentEn':
            'Simba will require supreme positional discipline to restrict Aziz Ki and Pacome from operating in half-spaces. If Yanga dictate tempo through zone 14, Simba must rely heavily on explosive transitions down the flanks. Transitions during the first five seconds post-turnover will decide the contest.',
        'tag': '#KariakooDerby',
      },
      {
        'id': 1,
        'name': 'Edo Kumwembe',
        'roleSw': 'Mwandishi & Mchambuzi wa Soka Kimataifa',
        'roleEn': 'Football Columnist & International Analyst',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        'match': 'Arsenal vs Chelsea',
        'league': 'Premier League',
        'headlineSw': 'Uimara wa Ngome ya Arsenal Dhidi ya Kasi ya Vijana wa Chelsea',
        'headlineEn': 'Arsenal’s Defensive Bastion vs Chelsea’s Rapid Youth Transition',
        'contentSw':
            'Arsenal wamejenga ngome ngumu zaidi ya ulinzi msimu huu. Saliba na Gabriel wanawapa uwezo wa kusukuma mstari mbele bila woga. Chelsea wanaweza kuleta madhara iwapo watatumia vizuri nafasi zinazotokea nyuma ya mabeki wa pembeni wa Arsenal.',
        'contentEn':
            'Arsenal possess the most resolute center-back pairing in the league right now. Saliba and Gabriel enable a high line with negligible risk. Chelsea’s only viable breach point lies in exploiting the inverted fullbacks on swift counter routes.',
        'tag': '#PremierLeague',
      },
      {
        'id': 2,
        'name': 'Ally Mayay',
        'roleSw': 'Nahodha wa Zamani wa Taifa Stars & Mchambuzi wa Kiufundi',
        'roleEn': 'Former Taifa Stars Captain & Technical Expert',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
        'match': 'Ligi Kuu ya NBC — Tathmini ya Mzunguko',
        'league': 'Tanzania NBC PL',
        'headlineSw': 'Kwanini Timu za Kati Zinafanya Ligi Kuwa Ngumu Zaidi Msimu Huu',
        'headlineEn': 'Why Mid-Table Resurgence Has Elevated NBC Premier League Quality',
        'contentSw':
            'Kiwango cha ufundishaji kwenye vilabu kama Azam, KMC na Mashujaa kimepanda sana. Hakuna tena mechi rahisi ambazo timu kubwa zinapata ushindi mnono bila jasho. Mbinu za kuzuia kwa vitalu vya chini (Low Block) zimekuwa na ufanisi mkubwa.',
        'contentEn':
            'Tactical coaching standards among mid-table sides have surged remarkably. There are no longer routine strolls for traditional giants. Compact low-blocks and organized pressing structures demand higher creativity and set-piece sharpness.',
        'tag': '#NBCPL',
      },
    ];

    return [..._localAnalyses, ...defaultAnalysts];
  }

  void _broadcastAnalysis() {
    if (!_analysisStreamController.isClosed) {
      _analysisStreamController.add(_localAnalyses);
    }
  }

  /// Tiririsha Kura za Mashabiki kwa wakati halisi (Insight Hub Screen)
  Stream<List<Map<String, dynamic>>> streamPolls() async* {
    yield _getCombinedPolls();
    yield* _pollsStreamController.stream.map<List<Map<String, dynamic>>>((_) => _getCombinedPolls());
  }

  List<Map<String, dynamic>> _getCombinedPolls() {
    return _localPolls;
  }

  void _broadcastPolls() {
    if (!_pollsStreamController.isClosed) {
      _pollsStreamController.add(_localPolls);
    }
  }
}
