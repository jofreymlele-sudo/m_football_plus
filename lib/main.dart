import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'matches_screen.dart';
import 'standings_screen.dart';
import 'news_screen.dart';
import 'insight_hub_screen.dart';
import 'admin_screen.dart';
import 'firebase_service.dart';

// ============================================================================
// 0. ENTRY POINT YA FLUTTER (MAIN FUNCTION & APP ROOT)
// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A192F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MFootballPlusApp());
}

class MFootballPlusApp extends StatelessWidget {
  const MFootballPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M Football Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MColors.background,
        colorScheme: const ColorScheme.dark(
          primary: MColors.scoresCyan,
          secondary: MColors.highlightsGold,
          surface: MColors.surface,
          onSurface: MColors.textWhite,
        ),
        useMaterial3: true,
      ),
      home: const MFootballPlusHomePage(),
    );
  }
}

// ============================================================================
// 1. RANGI RASMI (EXACT COLOR PALETTE - LAZIMA KUTUMIA HIZI)
// ============================================================================
class MColors {
  static const Color background = Color(0xFF0A192F); // Background Kuu: Navy Blue
  static const Color surface = Color(0xFF112240);    // Deep Navy Surface
  static const Color textWhite = Color(0xFFFFFFFF);  // Rangi ya Maandishi: White
  static const Color scoresCyan = Color(0xFF00FFFF); // Rangi ya Scores / 'VS': Cyan
  static const Color highlightsGold = Color(0xFFFFBF00); // Rangi ya Muda / Kengele: Gold
  static const Color textMuted = Color(0xFF8892B0);  // Rangi ya Maelezo / Text Muted
}

// ============================================================================
// 2. MFUMO WA LUGHA MBILI (KISWAHILI & KIINGEREZA - INABADILIKA APP NZIMA)
// ============================================================================
enum AppLanguage { english, swahili }

class MStrings {
  static const String appName = 'M FOOTBALL PLUS';

  // Menyu 5 za Chini (Bottom Navigation)
  static String navHome(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'Nyumbani' : 'Home';
  static String navMatches(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'Mechi' : 'Matches';
  static String navStandings(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'Msimamo' : 'Standings';
  static String navNews(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'Habari' : 'News';
  static String navInsightHub(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'Kituo cha Maarifa' : 'Insight Hub';

  // Vichwa vya Sehemu (Section Headers)
  static String topTrending(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'HABARI INAYOVUMA SANA' : 'TOP TRENDING STORY';
  static String liveMatches(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'MECHI MUBASHARA' : 'LIVE MATCHES';
  static String todaysMatches(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'MECHI ZA LEO' : "TODAY'S FIXTURES";
  static String latestStories(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'HABARI ZA HIVI PUNDE' : 'LATEST STORIES';
  static String viewAll(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'ONA ZOTE' : 'VIEW ALL';

  // Badges & Tafsiri Nyingine
  static String liveBadge(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'MUBASHARA' : 'LIVE';
  static String searchHint(AppLanguage lang) =>
      lang == AppLanguage.swahili
          ? 'Tafuta timu, ligi, wachezaji...'
          : 'Search clubs, leagues, matches...';
  static String reads(AppLanguage lang) =>
      lang == AppLanguage.swahili ? 'wasomaji' : 'reads';
}



// ============================================================================
// 5. NEMBO HALISI (ORIGINAL M FOOTBALL PLUS BRAND LOGO)
// ============================================================================
class MFootballLogoWidget extends StatelessWidget {
  final double height;

  const MFootballLogoWidget({
    super.key,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return _buildVectorFallback();
      },
    );
  }

  Widget _buildVectorFallback() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Herufi 'M' ya Kifahari yenye Rangi ya Dhahabu (Outfit Bold, Gold)
        Text(
          'M',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: MColors.highlightsGold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),

        // Safu ya Mshale wa Cyan na 'Football Plus'
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPaint(
              size: const Size(100, 3.5),
              painter: _CyanArcPainter(),
            ),
            const SizedBox(height: 1.5),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Football ',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                      letterSpacing: 0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Plus',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MColors.scoresCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CyanArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MColors.scoresCyan
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.8,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 6. HOME PAGE WIDGET YA M FOOTBALL PLUS
// ============================================================================
class MFootballPlusHomePage extends StatefulWidget {
  const MFootballPlusHomePage({super.key});

  @override
  State<MFootballPlusHomePage> createState() => _MFootballPlusHomePageState();
}

class _MFootballPlusHomePageState extends State<MFootballPlusHomePage> {
  // Variable ya currentIndex ya Menyu 5
  int _currentIndex = 0;

  // Lugha iliyochaguliwa (Kiswahili kikiwa msingi)
  AppLanguage _currentLanguage = AppLanguage.swahili;

  // PageView Controller ya Top Trending Story
  int _trendingPageIndex = 0;
  late PageController _trendingPageController;

  // Data Futures kutoka API Moja kwa Moja (Data Halisi Pekee - Hakuna Mock Data)
  late Future<List<MatchModel>> _liveMatchesFuture;
  late Future<List<MatchModel>> _todaysMatchesFuture;
  late Future<List<NewsArticleModel>> _newsArticlesFuture;

  @override
  void initState() {
    super.initState();
    _trendingPageController = PageController(viewportFraction: 1.0);
    _liveMatchesFuture = FootballApiService().getLiveMatches();
    _todaysMatchesFuture = FootballApiService().getTodaysMatches();
    _newsArticlesFuture = FootballApiService().getFootballNews(category: 'all');
  }

  // Kazi ya kusasisha data zote za API
  Future<void> _refreshAllData() async {
    setState(() {
      _liveMatchesFuture = FootballApiService().getLiveMatches(forceRefresh: true);
      _todaysMatchesFuture = FootballApiService().getTodaysMatches(forceRefresh: true);
      _newsArticlesFuture = FootballApiService().getFootballNews(category: 'all', forceRefresh: true);
    });
    await Future.wait([
      _liveMatchesFuture.catchError((_) => <MatchModel>[]),
      _todaysMatchesFuture.catchError((_) => <MatchModel>[]),
      _newsArticlesFuture.catchError((_) => <NewsArticleModel>[]),
    ]);
  }

  @override
  void reassemble() {
    super.reassemble();
    // Inahakikisha Hot Reload inafuta na kuunda upya controller ya 1.0 (kadi moja bila kukatwa)
    _trendingPageController.dispose();
    _trendingPageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _trendingPageController.dispose();
    super.dispose();
  }

  // Kazi ya kubadilisha lugha app nzima mara moja
  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == AppLanguage.swahili
          ? AppLanguage.english
          : AppLanguage.swahili;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = _currentLanguage == AppLanguage.swahili;

    return Scaffold(
      // Background Kuu: Color(0xFF0A192F) (Navy Blue)
      backgroundColor: MColors.background,

      // 1. APPBAR
      appBar: _buildAppBar(context, isSwahili),

      // Mwili wa App kulingana na Tab iliyochaguliwa (Bottom Navigation)
      body: _buildCurrentScreen(context, isSwahili),

      // 5. BOTTOM NAVIGATION: Menyu 5 zenye currentIndex
      bottomNavigationBar: _buildBottomNav(context, isSwahili),
    );
  }

  // --- Router ya Skrini Kuu kulingana na Menyu ya Chini ---
  Widget _buildCurrentScreen(BuildContext context, bool isSwahili) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeFeed(context, isSwahili);
      case 1:
        // Ukurasa kamili wa Mechi za Leo na Zinazofuata (MatchesScreen)
        return MatchesScreen(
          isSwahili: isSwahili,
          onBackToHome: () => setState(() => _currentIndex = 0),
        );
      case 2:
        // Ukurasa wa Msimamo wa Ligi (StandingsScreen)
        return StandingsScreen(
          isSwahili: isSwahili,
          onBackToHome: () => setState(() => _currentIndex = 0),
        );
      case 3:
        // Ukurasa wa Habari za Soka (NewsScreen)
        return NewsScreen(
          isSwahili: isSwahili,
          onBackToHome: () => setState(() => _currentIndex = 0),
        );
      case 4:
        // Ukurasa wa Kituo cha Maarifa (InsightHubScreen)
        return InsightHubScreen(
          isSwahili: isSwahili,
          onBackToHome: () => setState(() => _currentIndex = 0),
        );
      default:
        return _buildSecondaryTab(context, isSwahili);
    }
  }

  // --- AppBar yenye M FOOTBALL PLUS, Profile, Kengele ya Gold, na Switcher ---
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSwahili) {
    return AppBar(
      backgroundColor: MColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: const MFootballLogoWidget(height: 36),
      actions: [
        // Kituo cha Kubadilisha Lugha Papo Hapo [ 🇹🇿 SW | 🇬🇧 EN ]
        GestureDetector(
          onTap: _toggleLanguage,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MColors.scoresCyan.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: MColors.scoresCyan.withValues(alpha: 0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isSwahili ? '🇹🇿 ' : '🇬🇧 ', style: const TextStyle(fontSize: 12)),
                Text(
                  isSwahili ? 'SW' : 'EN',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: MColors.scoresCyan,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: MColors.highlightsGold,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Kengele (Notification, Rangi: Gold Color(0xFFFFBF00))
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: MColors.highlightsGold, // Rangi: Gold
                size: 24,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: MColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: MColors.scoresCyan),
                    ),
                    content: Text(
                      isSwahili
                          ? 'M Football Plus: Mechi za leo zimeanza kupigwa!'
                          : 'M Football Plus: Today\'s matches are underway!',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: MColors.textWhite,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Mwangaza mdogo wa Cyan
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MColors.scoresCyan,
                ),
              ),
            ),
          ],
        ),

        // Profile (CircleAvatar yenye Admin Panel & Settings)
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: GestureDetector(
            onTap: () => _openProfileModal(context, isSwahili),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: MColors.scoresCyan.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: MColors.surface,
                child: Icon(Icons.person, color: MColors.textWhite, size: 19),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Modal ya Wasifu wa Mmiliki (Profile & Admin Panel Sheet) ---
  void _openProfileModal(BuildContext context, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final auth = AuthService();
            final currentUser = auth.currentUser;
            final isOwner = auth.isOwner;

            return Container(
              decoration: const BoxDecoration(
                color: MColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: MColors.scoresCyan, width: 1.5)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MColors.textWhite.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // User Header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isOwner ? MColors.scoresCyan : Colors.white30,
                            width: 1.8,
                          ),
                          color: MColors.surface,
                        ),
                        child: Icon(
                          isOwner ? Icons.admin_panel_settings_rounded : Icons.person,
                          color: isOwner ? MColors.scoresCyan : MColors.textWhite,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentUser.displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: MColors.textWhite,
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, size: 16, color: MColors.scoresCyan),
                                ],
                              ],
                            ),
                            Text(
                              currentUser.email,
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                color: isOwner ? MColors.highlightsGold : MColors.textWhite.withValues(alpha: 0.6),
                                fontWeight: isOwner ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOwner
                                  ? (isSwahili ? 'Mmiliki wa App (Administrator)' : 'App Owner & Administrator')
                                  : (isSwahili ? 'Shabiki wa Soka (Fan Account)' : 'Football Fan (Guest)'),
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                color: isOwner ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==========================================================
                  // KITUFE CHA ADMIN PANEL: KINAONEKANA TU KWA MMILIKI!
                  // ==========================================================
                  if (isOwner) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MColors.surface,
                            MColors.scoresCyan.withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MColors.scoresCyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: MColors.scoresCyan.withValues(alpha: 0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminScreen(isSwahili: isSwahili),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: MColors.scoresCyan.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings_rounded, color: MColors.scoresCyan, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isSwahili ? 'Paneli ya Msimamizi' : 'Admin Panel',
                                            style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: MColors.textWhite,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: MColors.highlightsGold.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'OWNER ONLY',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: MColors.highlightsGold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isSwahili ? 'Dhibiti Habari, Wachambuzi, na Kura' : 'Control News, Experts & Polls',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: MColors.textWhite.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: MColors.scoresCyan, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Badili Akaunti (Tester ya Ulinzi wa Usalama)
                  Container(
                    decoration: BoxDecoration(
                      color: MColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        if (isOwner)
                          ListTile(
                            leading: const Icon(Icons.person_outline_rounded, color: Colors.amberAccent, size: 20),
                            title: Text(
                              isSwahili ? 'Jaribu kama Shabiki (Toka Admin)' : 'Test as Regular Fan (Sign Out)',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                            ),
                            subtitle: Text(
                              isSwahili ? 'Kitufe cha Admin kitajificha mara moja' : 'Hides Admin button immediately',
                              style: GoogleFonts.manrope(fontSize: 10.5, color: MColors.textWhite.withValues(alpha: 0.5)),
                            ),
                            onTap: () {
                              auth.signOut();
                              setModalState(() {});
                              setState(() {});
                            },
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.verified_user_rounded, color: MColors.scoresCyan, size: 20),
                            title: Text(
                              isSwahili ? 'Ingia kama Mmiliki (${AuthService.ownerEmail})' : 'Sign In as Owner (${AuthService.ownerEmail})',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: MColors.scoresCyan),
                            ),
                            subtitle: Text(
                              isSwahili ? 'Fungua Paneli ya Msimamizi' : 'Unlocks Admin Panel access',
                              style: GoogleFonts.manrope(fontSize: 10.5, color: MColors.textWhite.withValues(alpha: 0.5)),
                            ),
                            onTap: () {
                              auth.signInAsOwner();
                              setModalState(() {});
                              setState(() {});
                            },
                          ),
                        const Divider(color: Color(0x1AFFFFFF), height: 1),
                        ListTile(
                          leading: const Icon(Icons.translate_rounded, color: MColors.scoresCyan, size: 20),
                          title: Text(
                            isSwahili ? 'Badilisha Lugha' : 'Switch Language',
                            style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: MColors.textWhite),
                          ),
                          trailing: Text(
                            isSwahili ? 'Kiswahili 🇹🇿' : 'English 🇬🇧',
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _currentLanguage = _currentLanguage == AppLanguage.swahili
                                  ? AppLanguage.english
                                  : AppLanguage.swahili;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Mwili Mkuu wa Home Page ---
  Widget _buildHomeFeed(BuildContext context, bool isSwahili) {
    return RefreshIndicator(
      color: MColors.scoresCyan,
      backgroundColor: MColors.surface,
      onRefresh: _refreshAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Sehemu ya Utafutaji wa Kisasa (Search Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: MColors.scoresCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        MStrings.searchHint(_currentLanguage),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MColors.textWhite.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const Icon(Icons.tune, color: MColors.highlightsGold, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. TOP TRENDING STORY (PageView na Kadi inayoelea yenye Pembe Zilizokatwa)
            _buildTopTrendingSection(isSwahili),

            const SizedBox(height: 24),

            // 3. LIVE MATCHES (Horizontal ListView.builder, Mpaka wa Cyan, Scores Cyan, LIVE White)
            _buildLiveMatchesSection(isSwahili),

            const SizedBox(height: 24),

            // 4. TODAY'S MATCHES (ListView.builder, Divider, Nembo Kushoto, Timu, 'VS' Cyan, Muda Gold kulia)
            _buildTodaysMatchesSection(isSwahili),

            const SizedBox(height: 24),

            // 5. LATEST STORIES (ListView.builder, Picha ndogo kushoto, Kichwa kulia)
            _buildLatestStoriesSection(isSwahili),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // --- 2. Top Trending Story (StreamBuilder ya Firebase Firestore kwa wakati halisi) ---
  Widget _buildTopTrendingSection(bool isSwahili) {
    return StreamBuilder<List<NewsArticleModel>>(
      stream: FirestoreService().streamNews(category: 'all'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 290,
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MColors.scoresCyan.withValues(alpha: 0.15),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
                  ),
                ),
              ),
            ),
          );
        }

        final List<NewsArticleModel> stories = (snapshot.hasData && snapshot.data != null)
            ? snapshot.data!
            : [];

        if (stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(
                height: 290,
                child: Stack(
                  children: [
                    // PageView ya Kadi Moja Kamili (viewportFraction: 1.0)
                    PageView.builder(
                      clipBehavior: Clip.antiAlias,
                      padEnds: false,
                      controller: _trendingPageController,
                      itemCount: stories.length,
                      onPageChanged: (index) {
                        setState(() => _trendingPageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final story = stories[index];
                        return GestureDetector(
                          onTap: () => showArticleReaderModal(context, story, isSwahili),
                          child: Container(
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: MColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: MColors.scoresCyan.withValues(alpha: 0.45),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: MColors.scoresCyan.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  story.imageUrl,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: MColors.surface,
                                    child: const Center(
                                      child: Icon(Icons.newspaper_rounded, size: 48, color: MColors.scoresCyan),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        MColors.background.withValues(alpha: 0.65),
                                        MColors.background.withValues(alpha: 0.98),
                                      ],
                                      stops: const [0.0, 0.52, 0.82, 1.0],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                // Badge ya Nambari ya Habari (Mfano: 1 / 4)
                                Positioned(
                                  top: 12,
                                  left: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: MColors.scoresCyan.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      '${index + 1} / ${stories.length}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: MColors.scoresCyan,
                                      ),
                                    ),
                                  ),
                                ),
                                // Badge ya Kategoria Juu Kulia
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: const BoxDecoration(
                                      color: MColors.highlightsGold,
                                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
                                    ),
                                    child: Text(
                                      story.category,
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: MColors.background,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Maandishi 'TOP TRENDING STORY' (Manrope, Cyan)
                                      Text(
                                        MStrings.topTrending(_currentLanguage),
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: MColors.scoresCyan,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Kichwa cha habari (Outfit Bold, White)
                                      Text(
                                        story.getTitle(isSwahili),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: MColors.textWhite,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Maelezo ya Muda (Manrope, Gold)
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_filled, size: 12, color: MColors.highlightsGold),
                                          const SizedBox(width: 4),
                                          Text(
                                            story.publishedAt,
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: MColors.highlightsGold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            story.source,
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: MColors.textWhite.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Vitufe vya Kupita Kushoto / Kulia
                    Positioned(
                      left: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _trendingPageIndex > 0
                            ? InkWell(
                                onTap: () {
                                  _trendingPageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.5),
                                    border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: const Icon(Icons.chevron_left_rounded, color: MColors.scoresCyan, size: 20),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _trendingPageIndex < stories.length - 1
                            ? InkWell(
                                onTap: () {
                                  _trendingPageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.5),
                                    border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded, color: MColors.scoresCyan, size: 20),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Vipone (Dots) Chini kwa Ajili ya Kuslide na Kubofya
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  stories.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _trendingPageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _trendingPageIndex == index ? 24 : 7,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _trendingPageIndex == index
                            ? MColors.scoresCyan
                            : MColors.textWhite.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. Live Matches (FutureBuilder Inayovuta Mechi Mubashara Halisi Moja kwa Moja kutoka API) ---
  Widget _buildLiveMatchesSection(bool isSwahili) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: MColors.scoresCyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    MStrings.liveMatches(_currentLanguage),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _liveMatchesFuture = FootballApiService().getLiveMatches(forceRefresh: true);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: MColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MColors.scoresCyan.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 11,
                            color: MColors.scoresCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SYNC',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: MColors.scoresCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Text(
                      MStrings.viewAll(_currentLanguage),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MColors.highlightsGold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // FutureBuilder ya Mechi Mubashara Halisi kutoka API
          FutureBuilder<List<MatchModel>>(
            future: _liveMatchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLiveMatchesLoadingPlaceholder(isSwahili);
              }

              if (snapshot.hasError) {
                return _buildErrorStateCard(
                  error: snapshot.error,
                  onRetry: () {
                    setState(() {
                      _liveMatchesFuture = FootballApiService().getLiveMatches(forceRefresh: true);
                    });
                  },
                  isSwahili: isSwahili,
                  sectionName: isSwahili ? 'Mechi Mubashara' : 'Live Matches',
                );
              }

              final matches = snapshot.data ?? [];

              if (matches.isEmpty) {
                return _buildNoLiveMatchesCard(isSwahili);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final count = matches.length;
                  if (constraints.maxWidth >= 700) {
                    return Row(
                      children: [
                        if (count > 0) Expanded(child: _buildLiveMatchCard(matches[0], isSwahili)),
                        if (count > 1) const SizedBox(width: 14),
                        if (count > 1) Expanded(child: _buildLiveMatchCard(matches[1], isSwahili)),
                        if (count > 2) const SizedBox(width: 14),
                        if (count > 2) Expanded(child: _buildLiveMatchCard(matches[2], isSwahili)),
                      ],
                    );
                  } else {
                    return SizedBox(
                      height: 165,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 1.0),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          return _buildLiveMatchCard(matches[index], isSwahili);
                        },
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(MatchModel match, bool isSwahili) {
    final effectiveHomeLogo = FootballApiService.getTeamLogo(match.homeTeam, fallbackUrl: match.homeTeamLogo);
    final effectiveAwayLogo = FootballApiService.getTeamLogo(match.awayTeam, fallbackUrl: match.awayTeamLogo);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(16),
        // Kadi ziwe na mpaka wa Cyan (Color(0xFF00FFFF))
        border: Border.all(
          color: MColors.scoresCyan,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: MColors.scoresCyan.withValues(alpha: 0.16),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sehemu ya Juu: Jina la Ligi na 'LIVE'
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.getLeague(isSwahili),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MColors.textWhite.withValues(alpha: 0.7),
                  ),
                ),
              ),
              // 'LIVE' (Manrope, White) yenye Animated Glowing Beacon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MColors.scoresCyan.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: MColors.scoresCyan,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      MStrings.liveBadge(_currentLanguage),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MColors.textWhite, // Manrope, White
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Timu na Alama za Magoli
          Row(
            children: [
              // Timu ya Nyumbani (Home Team)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MColors.background,
                        border: Border.all(
                          color: match.homeColor.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: effectiveHomeLogo.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                effectiveHomeLogo,
                                width: 17,
                                height: 17,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.sports_soccer,
                                  size: 15,
                                  color: MColors.textWhite,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.sports_soccer,
                              size: 15,
                              color: MColors.textWhite,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.homeTeam,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: MColors.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Alama za Magoli (Outfit Bold, Cyan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${match.homeScore} - ${match.awayScore}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MColors.scoresCyan, // Cyan
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // Timu ya Ugenini (Away Team)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        match.awayTeam,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: MColors.textWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MColors.background,
                        border: Border.all(
                          color: match.awayColor.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: effectiveAwayLogo.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                effectiveAwayLogo,
                                width: 17,
                                height: 17,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.sports_soccer,
                                  size: 15,
                                  color: MColors.textWhite,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.sports_soccer,
                              size: 15,
                              color: MColors.textWhite,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sehemu ya Chini: Muda (Manrope, Gold) na Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: MColors.highlightsGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.matchTime,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MColors.highlightsGold, // Gold
                    ),
                  ),
                ],
              ),
              Text(
                match.getStatus(isSwahili),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MColors.textWhite.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Kadi ya taarifa sahihi pale ambapo hakuna mechi yoyote mubashara inayochezwa duniani
  Widget _buildNoLiveMatchesCard(bool isSwahili) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MColors.scoresCyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MColors.background,
              border: Border.all(
                color: MColors.scoresCyan.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.sensors_off_rounded,
              size: 22,
              color: MColors.scoresCyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? 'Hakuna Mechi Mubashara Sasa Hivi' : 'No In-Play Matches Currently',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSwahili
                      ? 'Mechi zote zinazoanza duniani zitaonekana hapa moja kwa moja. Angalia ratiba ya leo hapa chini.'
                      : 'Live fixtures will stream here in real-time once matches kick off. Check today\'s schedule below.',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: MColors.textWhite.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Today's Matches (FutureBuilder Inayovuta Mechi za Leo Moja kwa Moja kutoka API) ---
  Widget _buildTodaysMatchesSection(bool isSwahili) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: MColors.highlightsGold, // Gold
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    MStrings.todaysMatches(_currentLanguage),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                child: Text(
                  MStrings.viewAll(_currentLanguage),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MColors.highlightsGold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // FutureBuilder Inayosoma Mechi za Leo Moja kwa Moja
          FutureBuilder<List<MatchModel>>(
            future: _todaysMatchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildTodaysMatchesLoadingPlaceholder();
              }

              if (snapshot.hasError) {
                return _buildErrorStateCard(
                  error: snapshot.error,
                  onRetry: () {
                    setState(() {
                      _todaysMatchesFuture = FootballApiService().getTodaysMatches(forceRefresh: true);
                    });
                  },
                  isSwahili: isSwahili,
                  sectionName: isSwahili ? 'Mechi za Leo' : 'Today\'s Matches',
                );
              }

              // Pata orodha ya mechi kutoka API (Data Halisi Pekee)
              final List<MatchModel> rawMatches =
                  (snapshot.hasData && snapshot.data != null) ? snapshot.data! : [];

              if (rawMatches.isEmpty) {
                return _buildTodaysMatchesEmptyCard(isSwahili);
              }

              // Chukua mechi 8 za juu zilizopangwa kwa vigezo rasmi
              final matches = rawMatches.take(8).toList();

              return Container(
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.18),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matches.length,
                  // Tumia Divider
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0x1AFFFFFF),
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                  ),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildTodayMatchTile(match, isSwahili);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Loading Indicator ya Mechi za Leo
  Widget _buildTodaysMatchesLoadingPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MColors.scoresCyan.withValues(alpha: 0.18),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
          ),
        ),
      ),
    );
  }

  // Kadi ya kuonyesha pale ambapo hakuna mechi zilizopangwa leo
  Widget _buildTodaysMatchesEmptyCard(bool isSwahili) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 28,
              color: MColors.scoresCyan.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili ? 'Hakuna Mechi Zilizopangwa Leo' : 'No Scheduled Fixtures Today',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading Indicator ya Mechi Mubashara (Live Matches)
  Widget _buildLiveMatchesLoadingPlaceholder(bool isSwahili) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MColors.scoresCyan.withValues(alpha: 0.18),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSwahili ? 'Inatafuta mechi mubashara kutoka API...' : 'Searching live matches from API...',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: MColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kadi Maalum ya Kuonyesha Ujumbe wa Kosa la API (Rate Limit au Mtandao) na Kitufe cha Kujaribu Tena
  Widget _buildErrorStateCard({
    required Object? error,
    required VoidCallback onRetry,
    required bool isSwahili,
    String? sectionName,
  }) {
    final rawError = error?.toString() ?? '';
    final isRateLimit = rawError.toLowerCase().contains('request limit') ||
        rawError.toLowerCase().contains('rate limit');

    final String title = isRateLimit
        ? (isSwahili ? 'Kiwango cha API Kimefikiwa' : 'API Rate Limit Reached')
        : (isSwahili ? 'Hitilafu ya Muunganisho' : 'Connection Notice');

    final String message = isRateLimit
        ? (isSwahili
            ? 'Kiwango cha bure cha maombi ya API ya leo (100/100) kimefikiwa. Tafadhali subiri kianze upya au boresha mpango kwenye api-football.com.'
            : 'Free daily API limit (100/100 requests) reached. Please wait for the daily quota reset or upgrade on api-football.com.')
        : (isSwahili
            ? 'Imeshindwa kupakia ${sectionName ?? "mechi"}. Tafadhali hakikisha mtandao wako uko sawa na ujaribu tena.'
            : 'Failed to load ${sectionName ?? "fixtures"}. Please verify your connection and try again.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRateLimit
              ? MColors.highlightsGold.withValues(alpha: 0.4)
              : Colors.redAccent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isRateLimit ? MColors.highlightsGold : Colors.redAccent)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRateLimit ? Icons.info_outline_rounded : Icons.wifi_off_rounded,
                  size: 20,
                  color: isRateLimit ? MColors.highlightsGold : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: MColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: MColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: MColors.scoresCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: MColors.scoresCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSwahili ? 'Jaribu Tena' : 'Retry',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: MColors.scoresCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kadi ya Mechi Moja ya Leo (Yenye Nembo Mbili, Majina Yasiyojikata Sana na Muda wa Gold)
  Widget _buildTodayMatchTile(MatchModel match, bool isSwahili) {
    final effectiveHomeLogo = FootballApiService.getTeamLogo(match.homeTeam, fallbackUrl: match.homeTeamLogo);
    final effectiveAwayLogo = FootballApiService.getTeamLogo(match.awayTeam, fallbackUrl: match.awayTeamLogo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jina la Ligi juu (k.m. Ligi Kuu ya Uingereza au Premier League)
          if (match.getLeague(isSwahili).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: MColors.scoresCyan,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    match.getLeague(isSwahili),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MColors.textWhite.withValues(alpha: 0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Nembo ya Timu ya Nyumbani (Home Logo)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MColors.background,
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: effectiveHomeLogo.isNotEmpty
                    ? Image.network(
                        effectiveHomeLogo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_soccer,
                          size: 14,
                          color: MColors.textWhite,
                        ),
                      )
                    : const Icon(Icons.sports_soccer, size: 14, color: MColors.textWhite),
              ),
              const SizedBox(width: 8),

              // Jina la Timu ya Nyumbani (Outfit Bold - Nafasi Kubwa Isiyojikata kirahisi)
              Expanded(
                flex: 4,
                child: Text(
                  match.homeTeam,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
              ),

              // 'VS' au Alama za Magoli (Cyan Color(0xFF00FFFF))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: MColors.scoresCyan.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  match.isLive || match.homeScore > 0 || match.awayScore > 0
                      ? '${match.homeScore} - ${match.awayScore}'
                      : 'VS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: MColors.scoresCyan, // Cyan
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Jina la Timu ya Ugenini (Outfit Bold - Nafasi Kubwa Isiyojikata kirahisi)
              Expanded(
                flex: 4,
                child: Text(
                  match.awayTeam,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nembo ya Timu ya Ugenini (Away Logo)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MColors.background,
                  border: Border.all(
                    color: MColors.highlightsGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: effectiveAwayLogo.isNotEmpty
                    ? Image.network(
                        effectiveAwayLogo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_soccer,
                          size: 14,
                          color: MColors.textWhite,
                        ),
                      )
                    : const Icon(Icons.sports_soccer, size: 14, color: MColors.textWhite),
              ),
              const SizedBox(width: 12),

              // Muda (Manrope, Gold Color(0xFFFFBF00)) kulia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: MColors.highlightsGold.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  match.matchTime, // Muda
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MColors.highlightsGold, // Gold
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. Latest Stories ---
  Widget _buildLatestStoriesSection(bool isSwahili) {
    return StreamBuilder<List<NewsArticleModel>>(
      stream: FirestoreService().streamNews(category: 'all'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
                ),
              ),
            ),
          );
        }

        final List<NewsArticleModel> allStories = (snapshot.hasData && snapshot.data != null)
            ? snapshot.data!
            : [];

        if (allStories.isEmpty) {
          return const SizedBox.shrink();
        }

        final stories = allStories.length > 1 ? allStories.sublist(1) : allStories;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: MColors.scoresCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        MStrings.latestStories(_currentLanguage),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 3; // Nenda kwenye tab ya Habari
                      });
                    },
                    child: Text(
                      MStrings.viewAll(_currentLanguage),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MColors.highlightsGold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ListView ya Latest Stories zenye Reader Modal
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return GestureDetector(
                    onTap: () => showArticleReaderModal(context, story, isSwahili),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MColors.scoresCyan.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Picha ndogo kushoto
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              story.imageUrl,
                              width: 95,
                              height: 80,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => Container(
                                width: 95,
                                height: 80,
                                color: MColors.background,
                                child: const Icon(Icons.newspaper_rounded, color: MColors.scoresCyan),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Kichwa cha habari (Outfit Bold) kulia
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.getTitle(isSwahili),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: MColors.textWhite,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Maelezo ya habari (Manrope)
                                Text(
                                  story.getDescription(isSwahili),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: MColors.textWhite.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Muda (Manrope, Gold)
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 11, color: MColors.highlightsGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      story.publishedAt,
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: MColors.highlightsGold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      story.source,
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: MColors.textWhite.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 6. Bottom Navigation Bar: Menyu 5 & currentIndex (Icons Zilizosahihishwa) ---
  Widget _buildBottomNav(BuildContext context, bool isSwahili) {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': MStrings.navHome(_currentLanguage)},
      {'icon': Icons.sports_soccer, 'label': MStrings.navMatches(_currentLanguage)},
      {'icon': Icons.format_list_numbered_rounded, 'label': MStrings.navStandings(_currentLanguage)},
      {'icon': Icons.article_outlined, 'label': MStrings.navNews(_currentLanguage)},
      {'icon': Icons.insights_rounded, 'label': MStrings.navInsightHub(_currentLanguage)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: MColors.background,
        border: Border(
          top: BorderSide(
            color: MColors.scoresCyan.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: MColors.scoresCyan.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = _currentIndex == index;
              final item = navItems[index];

              return InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = index; // Variable ya currentIndex
                  });
                },
                splashColor: MColors.scoresCyan.withValues(alpha: 0.15),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active indicator bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 3,
                        width: isSelected ? 22 : 0,
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: MColors.scoresCyan,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: MColors.scoresCyan.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      Icon(
                        item['icon'] as IconData,
                        size: 22,
                        // Home (Cyan) na menyu iliyochaguliwa inakuwa Cyan
                        color: isSelected
                            ? MColors.scoresCyan
                            : MColors.textWhite.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? MColors.scoresCyan
                              : MColors.textWhite.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Placeholder ya Menyu nyingine 4 (Matches, Standings, News, Insight Hub)
  Widget _buildSecondaryTab(BuildContext context, bool isSwahili) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hub_outlined, size: 50, color: MColors.scoresCyan),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Kipengele Hiki Kinafunguliwa...' : 'Feature Under Deployment...',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.scoresCyan,
              foregroundColor: MColors.background,
            ),
            onPressed: () => setState(() => _currentIndex = 0),
            child: Text(
              isSwahili ? 'Rudi Nyumbani' : 'Back to Home',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
