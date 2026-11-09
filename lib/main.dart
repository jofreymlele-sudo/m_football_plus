import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// 1. RANGI RASMI (EXACT COLOR PALETTE - LAZIMA KUTUMIA HIZI)
// ============================================================================
class MColors {
  static const Color background = Color(0xFF0A192F); // Background Kuu: Navy Blue
  static const Color surface = Color(0xFF112240);    // Deep Navy Surface
  static const Color textWhite = Color(0xFFFFFFFF);  // Rangi ya Maandishi: White
  static const Color scoresCyan = Color(0xFF00FFFF); // Rangi ya Scores / 'VS': Cyan
  static const Color highlightsGold = Color(0xFFFFBF00); // Rangi ya Muda / Kengele: Gold
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
// 3. DATA MODELS (HAKUNA TIMU ZILIZOWEKWA KWA MKONO KWENYE UI)
// ============================================================================
class MatchModel {
  final String id;
  final String leagueEn;
  final String leagueSw;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String matchTime; // e.g. "68'", "21:00", "FT"
  final bool isLive;
  final String statusEn;
  final String statusSw;
  final String venue;

  const MatchModel({
    required this.id,
    required this.leagueEn,
    required this.leagueSw,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.matchTime,
    required this.isLive,
    required this.statusEn,
    required this.statusSw,
    required this.venue,
  });

  String getLeague(bool isSwahili) => isSwahili ? leagueSw : leagueEn;
  String getStatus(bool isSwahili) => isSwahili ? statusSw : statusEn;
}

class NewsModel {
  final String id;
  final String titleEn;
  final String titleSw;
  final String summaryEn;
  final String summarySw;
  final String categoryEn;
  final String categorySw;
  final String timeAgoEn;
  final String timeAgoSw;
  final String imageUrl;
  final String author;
  final int readsCount;
  final bool isTrending;

  const NewsModel({
    required this.id,
    required this.titleEn,
    required this.titleSw,
    required this.summaryEn,
    required this.summarySw,
    required this.categoryEn,
    required this.categorySw,
    required this.timeAgoEn,
    required this.timeAgoSw,
    required this.imageUrl,
    required this.author,
    required this.readsCount,
    this.isTrending = false,
  });

  String getTitle(bool isSwahili) => isSwahili ? titleSw : titleEn;
  String getSummary(bool isSwahili) => isSwahili ? summarySw : summaryEn;
  String getCategory(bool isSwahili) => isSwahili ? categorySw : categoryEn;
  String getTimeAgo(bool isSwahili) => isSwahili ? timeAgoSw : timeAgoEn;
}

// ============================================================================
// 4. MOCK DATA REPOSITORY
// ============================================================================
class MockFootballRepository {
  // Mechi za Mubashara (Live Matches)
  static final List<MatchModel> liveMatches = [
    const MatchModel(
      id: 'm1',
      leagueEn: 'UEFA Champions League',
      leagueSw: 'Ligi ya Mabingwa Ulaya',
      homeTeam: 'Arsenal',
      awayTeam: 'Real Madrid',
      homeScore: 2,
      awayScore: 1,
      matchTime: "68'",
      isLive: true,
      statusEn: '2nd Half',
      statusSw: 'Kipindi cha 2',
      venue: 'Emirates Stadium, London',
    ),
    const MatchModel(
      id: 'm2',
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC',
      homeTeam: 'Young Africans',
      awayTeam: 'Simba SC',
      homeScore: 1,
      awayScore: 1,
      matchTime: "84'",
      isLive: true,
      statusEn: 'Kariakoo Derby',
      statusSw: 'Dabi ya Kariakoo',
      venue: 'Benjamin Mkapa Stadium',
    ),
    const MatchModel(
      id: 'm3',
      leagueEn: 'UEFA Champions League',
      leagueSw: 'Ligi ya Mabingwa Ulaya',
      homeTeam: 'Man City',
      awayTeam: 'Bayern Munich',
      homeScore: 3,
      awayScore: 2,
      matchTime: "73'",
      isLive: true,
      statusEn: '2nd Half',
      statusSw: 'Kipindi cha 2',
      venue: 'Etihad Stadium',
    ),
  ];

  // Mechi za Leo (Today's Matches)
  static final List<MatchModel> todaysMatches = [
    const MatchModel(
      id: 'tm1',
      leagueEn: 'Premier League',
      leagueSw: 'Ligi Kuu Uingereza',
      homeTeam: 'Liverpool',
      awayTeam: 'Chelsea',
      homeScore: 0,
      awayScore: 0,
      matchTime: '21:00',
      isLive: false,
      statusEn: 'Kickoff 21:00',
      statusSw: 'Kuanza 21:00',
      venue: 'Anfield, Liverpool',
    ),
    const MatchModel(
      id: 'tm2',
      leagueEn: 'Serie A Enilive',
      leagueSw: 'Serie A Italia',
      homeTeam: 'Inter Milan',
      awayTeam: 'AC Milan',
      homeScore: 0,
      awayScore: 0,
      matchTime: '21:45',
      isLive: false,
      statusEn: 'Derby della Madonnina',
      statusSw: 'Dabi ya Milan',
      venue: 'San Siro Stadium',
    ),
    const MatchModel(
      id: 'tm3',
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC',
      homeTeam: 'Azam FC',
      awayTeam: 'Singida BS',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusEn: 'Kickoff 19:00',
      statusSw: 'Kuanza 19:00',
      venue: 'Azam Complex, Chamazi',
    ),
  ];

  // Habari Zinazovuma Sana (Top Trending Stories)
  static final List<NewsModel> trendingStories = [
    const NewsModel(
      id: 'tr1',
      titleEn: 'Kylian Mbappé Fires Real Madrid To Champions League Semi-Finals With Stunner',
      titleSw: 'Kylian Mbappé Aipeleka Real Madrid Nusu Fainali ya Klabu Bingwa kwa Bao la Kipekee',
      summaryEn: 'An exhilarating display of sheer pace and clinical finishing silenced the critics.',
      summarySw: 'Kasi ya ajabu na umaliziaji wa kiwango cha juu uliwazima wakosoaji usiku wa Ulaya.',
      categoryEn: 'CHAMPIONS LEAGUE',
      categorySw: 'KLABU BINGWA ULAYA',
      timeAgoEn: '15m ago',
      timeAgoSw: 'Dak 15 zilizopita',
      imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1200&q=80',
      author: 'Tactical Desk',
      readsCount: 14820,
      isTrending: true,
    ),
    const NewsModel(
      id: 'tr2',
      titleEn: 'Kariakoo Derby: 60,000 Fans Roar As Yanga & Simba Share Thrilling Spoils',
      titleSw: 'Dabi ya Kariakoo: Mashabiki 60,000 Washangilia Yanga na Simba Zikitoshana Nguvu',
      summaryEn: 'Benjamin Mkapa Stadium shook in one of the most intense derbies in African history.',
      summarySw: 'Uwanja wa Benjamin Mkapa ulitetemeka katika moja ya dabi kali zaidi barani Afrika.',
      categoryEn: 'AFRICA ELITE',
      categorySw: 'SOKA LA AFRIKA',
      timeAgoEn: '32m ago',
      timeAgoSw: 'Dak 32 zilizopita',
      imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=1200&q=80',
      author: 'African Bureau',
      readsCount: 22450,
      isTrending: true,
    ),
  ];

  // Habari za Hivi Punde (Latest Stories)
  static final List<NewsModel> latestStories = [
    const NewsModel(
      id: 'ls1',
      titleEn: 'Mikel Arteta Promises High Intensity For North London Derby Showdown',
      titleSw: 'Mikel Arteta Aahidi Mchezo wa Kasi ya Juu Kuelekea Dabi ya London Kaskazini',
      summaryEn: 'Arsenal manager confirms key players are fully fit and focused on victory.',
      summarySw: 'Kocha wa Arsenal athibitisha wachezaji wote muhimu wako fiti kwa ushindi.',
      categoryEn: 'PREMIER LEAGUE',
      categorySw: 'LIGI KUU UINGEREZA',
      timeAgoEn: '8m ago',
      timeAgoSw: 'Dak 8 zilizopita',
      imageUrl: 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?auto=format&fit=crop&w=600&q=80',
      author: 'London Bureau',
      readsCount: 5410,
    ),
    const NewsModel(
      id: 'ls2',
      titleEn: 'CAF Confirms 40% Increase In Champions League Prize Money for 2026',
      titleSw: 'CAF Yathibitisha Nyongeza ya Asilimia 40 ya Zawadi za Klabu Bingwa Afrika 2026',
      summaryEn: 'Historic funding injection set to boost African club infrastructure.',
      summarySw: 'Uwekezaji wa kihistoria utakaoinua miundombinu ya vilabu vya soka barani Afrika.',
      categoryEn: 'CAF NEWS',
      categorySw: 'HABARI ZA CAF',
      timeAgoEn: '24m ago',
      timeAgoSw: 'Dak 24 zilizopita',
      imageUrl: 'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?auto=format&fit=crop&w=600&q=80',
      author: 'Cairo HQ',
      readsCount: 11200,
    ),
  ];
}

// ============================================================================
// 5. NEMBO YA KIPEKEE (M FOOTBALL PLUS BRAND LOGO)
// ============================================================================
class MFootballLogoWidget extends StatelessWidget {
  final double fontSize;

  const MFootballLogoWidget({super.key, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Herufi 'M' yenye Rangi ya Dhahabu (Gold)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MColors.highlightsGold, Color(0xFFFF9900)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: MColors.highlightsGold.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            'M',
            style: GoogleFonts.outfit(
              fontSize: fontSize * 1.1,
              fontWeight: FontWeight.w900,
              color: MColors.background,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Safu ya Mshale wa Cyan na FOOTBALL PLUS (Outfit Bold, White)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPaint(
              size: Size(fontSize * 5.2, 3),
              painter: _CyanArcPainter(),
            ),
            const SizedBox(height: 1),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'FOOTBALL ',
                    style: GoogleFonts.outfit(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                      letterSpacing: 0.8,
                    ),
                  ),
                  TextSpan(
                    text: 'PLUS',
                    style: GoogleFonts.outfit(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: MColors.scoresCyan,
                      letterSpacing: 1.2,
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
  late final PageController _trendingPageController;

  @override
  void initState() {
    super.initState();
    _trendingPageController = PageController(viewportFraction: 0.92);
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

      // Mwili wa Home Page
      body: _currentIndex == 0
          ? _buildHomeFeed(context, isSwahili)
          : _buildSecondaryTab(context, isSwahili),

      // 5. BOTTOM NAVIGATION: Menyu 5 zenye currentIndex
      bottomNavigationBar: _buildBottomNav(context, isSwahili),
    );
  }

  // --- AppBar yenye M FOOTBALL PLUS, Profile, Kengele ya Gold, na Switcher ---
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSwahili) {
    return AppBar(
      backgroundColor: MColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: const MFootballLogoWidget(fontSize: 18),
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
                          ? 'M FOOTBALL PLUS: Mechi za leo zimeanza kupigwa!'
                          : 'M FOOTBALL PLUS: Today\'s matches are underway!',
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

        // Profile (CircleAvatar)
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
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
      ],
    );
  }

  // --- Mwili Mkuu wa Home Page ---
  Widget _buildHomeFeed(BuildContext context, bool isSwahili) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
    );
  }

  // --- 2. Top Trending Story ---
  Widget _buildTopTrendingSection(bool isSwahili) {
    final stories = MockFootballRepository.trendingStories;

    return Column(
      children: [
        SizedBox(
          height: 235,
          child: PageView.builder(
            controller: _trendingPageController,
            itemCount: stories.length,
            onPageChanged: (index) {
              setState(() => _trendingPageIndex = index);
            },
            itemBuilder: (context, index) {
              final story = stories[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                // Kadi Inayoelea yenye Pembe Zilizokatwa (Beveled Cut Corners)
                decoration: ShapeDecoration(
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: MColors.scoresCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
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
                      errorBuilder: (_, __, ___) => Container(color: MColors.surface),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MColors.background.withValues(alpha: 0.1),
                            MColors.background.withValues(alpha: 0.8),
                            MColors.background.withValues(alpha: 0.98),
                          ],
                          stops: const [0.0, 0.45, 0.95],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: const BoxDecoration(
                          color: MColors.highlightsGold,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10)),
                        ),
                        child: Text(
                          story.getCategory(isSwahili),
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MColors.background,
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
                              color: MColors.scoresCyan, // Cyan
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textWhite, // White
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
                                story.getTimeAgo(isSwahili),
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: MColors.highlightsGold, // Gold
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${story.readsCount} ${MStrings.reads(_currentLanguage)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: MColors.textWhite.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Vipone (Dots) Chini kwa Ajili ya PageView
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            stories.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _trendingPageIndex == index ? 22 : 7,
              height: 5,
              decoration: BoxDecoration(
                color: _trendingPageIndex == index
                    ? MColors.scoresCyan // Cyan Dot
                    : MColors.textWhite.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Live Matches ---
  Widget _buildLiveMatchesSection(bool isSwahili) {
    final matches = MockFootballRepository.liveMatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
              Text(
                MStrings.viewAll(_currentLanguage),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MColors.highlightsGold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ListView.builder ya Horizontal ya Live Matches
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: matches.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final match = matches[index];
              return Container(
                width: 255,
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  // Kadi ziwe na mpaka wa Cyan (Color(0xFF00FFFF))
                  border: Border.all(
                    color: MColors.scoresCyan,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MColors.scoresCyan.withValues(alpha: 0.12),
                      blurRadius: 10,
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
                              fontWeight: FontWeight.w500,
                              color: MColors.textWhite.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        // 'LIVE' (Manrope, White)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: MColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MColors.scoresCyan, width: 0.8),
                          ),
                          child: Text(
                            MStrings.liveBadge(_currentLanguage),
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MColors.textWhite, // Manrope, White
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Timu na Alama za Magoli
                    Row(
                      children: [
                        // Timu ya Nyumbani (Home Team)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.sports_soccer, size: 16, color: MColors.textWhite), // Alama ya timu
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  match.homeTeam,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: MColors.textWhite, // Outfit Bold, White
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Alama za Magoli (Outfit Bold, Cyan)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${match.homeScore} - ${match.awayScore}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: MColors.scoresCyan, // Cyan
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
                                    color: MColors.textWhite, // Outfit Bold, White
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.sports_soccer, size: 16, color: MColors.textWhite),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Sehemu ya Chini: Muda (Manrope, Gold)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: MColors.highlightsGold),
                            const SizedBox(width: 4),
                            Text(
                              match.matchTime,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MColors.highlightsGold, // Gold
                              ),
                            ),
                          ],
                        ),
                        Text(
                          match.getStatus(isSwahili),
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: MColors.textWhite.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 4. Today's Matches ---
  Widget _buildTodaysMatchesSection(bool isSwahili) {
    final matches = MockFootballRepository.todaysMatches;

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
              Text(
                MStrings.viewAll(_currentLanguage),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MColors.highlightsGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      // Nembo Kushoto
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MColors.background,
                        ),
                        child: const Icon(Icons.sports_soccer, size: 15, color: MColors.textWhite),
                      ),
                      const SizedBox(width: 8),

                      // Jina la Timu (Outfit Bold)
                      Expanded(
                        child: Text(
                          match.homeTeam,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: MColors.textWhite,
                          ),
                        ),
                      ),

                      // 'VS' (Cyan Color(0xFF00FFFF))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: MColors.scoresCyan, // Cyan
                          ),
                        ),
                      ),

                      // Jina la Timu (Outfit Bold)
                      Expanded(
                        child: Text(
                          match.awayTeam,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: MColors.textWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Nembo ya Timu
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MColors.background,
                        ),
                        child: const Icon(Icons.sports_soccer, size: 15, color: MColors.textWhite),
                      ),
                      const SizedBox(width: 10),

                      // Muda (Manrope, Gold Color(0xFFFFBF00)) kulia
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: MColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          match.matchTime,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MColors.highlightsGold, // Gold
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Latest Stories ---
  Widget _buildLatestStoriesSection(bool isSwahili) {
    final stories = MockFootballRepository.latestStories;

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
              Text(
                MStrings.viewAll(_currentLanguage),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MColors.highlightsGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ListView.builder ya Latest Stories
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Container(
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
                        width: 90,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 75,
                          color: MColors.background,
                          child: const Icon(Icons.sports_soccer, color: MColors.scoresCyan),
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
                              color: MColors.textWhite, // Outfit Bold, White
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Maelezo ya habari (Manrope)
                          Text(
                            story.getSummary(isSwahili),
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
                                story.getTimeAgo(isSwahili),
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: MColors.highlightsGold, // Gold
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 6. Bottom Navigation Bar: Menyu 5 & currentIndex ---
  Widget _buildBottomNav(BuildContext context, bool isSwahili) {
    final navItems = [
      {'icon': Icons.sports_soccer, 'label': MStrings.navHome(_currentLanguage)},
      {'icon': Icons.event_available, 'label': MStrings.navMatches(_currentLanguage)},
      {'icon': Icons.format_list_numbered, 'label': MStrings.navStandings(_currentLanguage)},
      {'icon': Icons.article_outlined, 'label': MStrings.navNews(_currentLanguage)},
      {'icon': Icons.hub_outlined, 'label': MStrings.navInsightHub(_currentLanguage)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: MColors.background,
        border: Border(
          top: BorderSide(
            color: MColors.scoresCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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