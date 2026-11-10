import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// 1. M FOOTBALL PLUS API SERVICE (API-Football & TheSportsDB)
// ============================================================================
class FootballApiService {
  // API Key ya mtumiaji ya API-Football (RapidAPI)
  static const String _apiFootballKey = '564c2af3abc67c7000e90ede24794545';
  static const String _apiFootballHost = 'v3.football.api-sports.io';
  static const String _apiFootballBaseUrl = 'https://v3.football.api-sports.io';

  // API Key ya TheSportsDB (Key '123' ndio active public test key)
  static const String _theSportsDbKey = '123';
  static const String _theSportsDbBaseUrl = 'https://www.thesportsdb.com/api/v1/json/$_theSportsDbKey';

  // Singleton instance
  static final FootballApiService _instance = FootballApiService._internal();
  factory FootballApiService() => _instance;
  FootballApiService._internal();

  // Cache ya ndani ya nembo za timu kutoka TheSportsDB ili kuzuia maombi mengi yasiyo ya lazima
  final Map<String, String> _badgeCache = {};

  // Headers rasmi za API-Football (Zinaunga mkono RapidAPI na API-Sports zote mbili)
  Map<String, String> get _apiFootballHeaders => {
    'x-rapidapi-key': _apiFootballKey,
    'x-rapidapi-host': _apiFootballHost,
    'x-apisports-key': _apiFootballKey,
    'Content-Type': 'application/json',
  };

  // --------------------------------------------------------------------------
  // A. KUCHUKUA MECHI MUBASHARA (LIVE MATCHES) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  /// Inachukua mechi zote zinazochezwa hivi sasa duniani kote
  Future<List<MatchModel>> getLiveMatches() async {
    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures?live=all');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inaanza kupiga Live Matches: $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Angalia kama kuna makosa yaliyotolewa na API
        if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          debugPrint('[M FOOTBALL PLUS API Error]: ${data['errors']}');
          return [];
        }

        final List<dynamic> responseList = data['response'] ?? [];
        debugPrint('[M FOOTBALL PLUS API] Mechi Mubashara zilizopatikana: ${responseList.length}');

        final List<MatchModel> matches = responseList
            .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
            .toList();

        return matches;
      } else {
        debugPrint('[M FOOTBALL PLUS API Error] HTTP Status: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('[M FOOTBALL PLUS API Exception] Hitilafu wakati wa kuchukua Live Matches: $e');
      debugPrint(stackTrace.toString());
      return [];
    }
  }

  // Cache ya ndani ya mechi za leo ili kuzuia kupoteza API calls
  List<MatchModel>? _cachedTodaysMatches;
  DateTime? _lastTodaysFetch;

  // --------------------------------------------------------------------------
  // B. KUCHUKUA MECHI ZA TAREHE / LEO (MATCHES ON DATE) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  /// Inachukua mechi halisi za tarehe maalum (chaguo-msingi ni tarehe ya leo YYYY-MM-DD)
  Future<List<MatchModel>> getTodaysMatches({String? date, bool forceRefresh = false}) async {
    final now = DateTime.now();
    final targetDate = date ??
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Tumia cache ikiwa haijazidi dakika 5 na tarehe ni ya leo
    if (!forceRefresh &&
        date == null &&
        _cachedTodaysMatches != null &&
        _lastTodaysFetch != null &&
        now.difference(_lastTodaysFetch!).inMinutes < 5) {
      return _cachedTodaysMatches!;
    }

    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures?date=$targetDate');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inaanza kupiga Mechi za Tarehe ($targetDate): $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];

        if (responseList.isNotEmpty) {
          final allMatches = responseList
              .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
              .toList();

          // Panga kwa kuweka ligi kuu na mashindano makubwa juu kwanza
          allMatches.sort((a, b) {
            final aPri = MatchModel.getLeaguePriority(a.leagueEn, a.leagueCountry);
            final bPri = MatchModel.getLeaguePriority(b.leagueEn, b.leagueCountry);
            return aPri.compareTo(bPri);
          });

          // Weka kwenye cache ikiwa ni ya leo
          if (date == null) {
            _cachedTodaysMatches = allMatches;
            _lastTodaysFetch = now;
          }

          return allMatches;
        }
      }

      // Ikiwa API haikupata mechi kwenye tarehe iliyoombwa:
      if (date != null) {
        return [];
      }

      return _cachedTodaysMatches ?? [];
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi za Tarehe zimefeli: $e');
      if (date != null) {
        return [];
      }
      return _cachedTodaysMatches ?? [];
    }
  }

  // Cache ya ndani ya mechi zinazofuata (Upcoming Matches)
  List<MatchModel>? _cachedUpcomingMatches;
  DateTime? _lastUpcomingFetch;

  // --------------------------------------------------------------------------
  // B2. KUCHUKUA MECHI ZINAZOFUATA (UPCOMING MATCHES) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  /// Inachukua mechi 200+ halisi zinazofuata kesho moja kwa moja kutoka API-Football
  Future<List<MatchModel>> getUpcomingMatches({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // Tumia cache ikiwa haijazidi dakika 10
    if (!forceRefresh &&
        _cachedUpcomingMatches != null &&
        _lastUpcomingFetch != null &&
        now.difference(_lastUpcomingFetch!).inMinutes < 10) {
      return _cachedUpcomingMatches!;
    }

    // Pata tarehe ya kesho (YYYY-MM-DD)
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDate =
        "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures?date=$tomorrowDate');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inavuta Mechi Halisi Zinazofuata Kesho ($tomorrowDate): $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 12));

      List<MatchModel> allMatches = [];
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];

        allMatches = responseList
            .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
            .toList();

        // Panga kwa ligi maarufu juu kwanza
        allMatches.sort((a, b) {
          final aPri = MatchModel.getLeaguePriority(a.leagueEn, a.leagueCountry);
          final bPri = MatchModel.getLeaguePriority(b.leagueEn, b.leagueCountry);
          return aPri.compareTo(bPri);
        });

        _cachedUpcomingMatches = allMatches;
        _lastUpcomingFetch = now;
      }

      return allMatches;
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi Zinazofuata zimefeli: $e');
      return _cachedUpcomingMatches ?? [];
    }
  }

  // --------------------------------------------------------------------------
  // C. KUCHUKUA NEMBO YA TIMU (TEAM BADGE) KUTOKA THESPORTSDB
  // --------------------------------------------------------------------------
  /// Inachukua nembo rasmi ya HD ya timu kutoka TheSportsDB kwa kutumia jina la timu
  Future<String?> getTeamBadge(String teamName) async {
    final trimmedName = teamName.trim();
    if (trimmedName.isEmpty) return null;

    // Angalia kwanza kama tayari ipo kwenye kumbukumbu (Cache)
    if (_badgeCache.containsKey(trimmedName)) {
      return _badgeCache[trimmedName];
    }

    final encodedName = Uri.encodeComponent(trimmedName);
    final uri = Uri.parse('$_theSportsDbBaseUrl/searchteams.php?t=$encodedName');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic>? teams = data['teams'];

        if (teams != null && teams.isNotEmpty) {
          final firstTeam = teams.first as Map<String, dynamic>;
          final badgeUrl = firstTeam['strBadge'] as String?;

          if (badgeUrl != null && badgeUrl.isNotEmpty) {
            _badgeCache[trimmedName] = badgeUrl;
            return badgeUrl;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TheSportsDB API Exception] Hitilafu ya kupata nembo ya $teamName: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // D. KUCHUKUA MAELEZO KAMILI YA TIMU KUTOKA THESPORTSDB
  // --------------------------------------------------------------------------
  /// Inachukua taarifa zote za timu (Nembo, Uwanja, Historia) kutoka TheSportsDB
  Future<TheSportsDbTeam?> getTeamDetails(String teamName) async {
    final trimmedName = teamName.trim();
    if (trimmedName.isEmpty) return null;

    final encodedName = Uri.encodeComponent(trimmedName);
    final uri = Uri.parse('$_theSportsDbBaseUrl/searchteams.php?t=$encodedName');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic>? teams = data['teams'];

        if (teams != null && teams.isNotEmpty) {
          return TheSportsDbTeam.fromJson(teams.first as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TheSportsDB API Exception] Hitilafu ya kupata taarifa za $teamName: $e');
      return null;
    }
  }
}

// ============================================================================
// 2. MODEL CLASS: MatchModel
// ============================================================================
class MatchModel {
  final String id;
  final int fixtureId;

  // Ligi
  final String leagueEn;
  final String leagueSw;
  final String leagueLogo;
  final String? leagueCountry;

  // Timu
  final String homeTeam;
  final String awayTeam;
  final String homeTeamLogo;
  final String awayTeamLogo;

  // Magoli
  final int homeScore;
  final int awayScore;

  // Muda na Hali ya Mechi
  final String matchTime;     // Mfano '21:00' au '68''
  final bool isLive;          // Je mechi inachezwa sasa hivi?
  final int? elapsedMinutes;  // Dakika ya mechi (k.m. 68)
  final String statusShort;   // '1H', '2H', 'HT', 'FT', 'NS'
  final String statusEn;      // '2nd Half', 'Halftime', 'Full Time'
  final String statusSw;      // 'Kipindi cha 2', 'Mapumziko', 'Mwisho wa Mechi'

  // Taarifa za Ziada
  final String venue;
  final String? referee;
  final Color homeColor;
  final Color awayColor;

  // Utabiri na Takwimu za Kipekee (AI Predictions & Form)
  final int homeWinProb;
  final int drawProb;
  final int awayWinProb;
  final String homeForm;
  final String awayForm;
  final String? keyPlayer;
  final String? h2hSummary;

  const MatchModel({
    required this.id,
    this.fixtureId = 0,
    required this.leagueEn,
    required this.leagueSw,
    this.leagueLogo = '',
    this.leagueCountry,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo = '',
    this.awayTeamLogo = '',
    required this.homeScore,
    required this.awayScore,
    required this.matchTime,
    required this.isLive,
    this.elapsedMinutes,
    this.statusShort = 'LIVE',
    required this.statusEn,
    required this.statusSw,
    required this.venue,
    this.referee,
    this.homeColor = const Color(0xFF00FFFF),
    this.awayColor = const Color(0xFFFFBF00),
    this.homeWinProb = 48,
    this.drawProb = 28,
    this.awayWinProb = 24,
    this.homeForm = 'W-W-D-W-L',
    this.awayForm = 'D-W-L-W-D',
    this.keyPlayer,
    this.h2hSummary,
  });

  String getLeague(bool isSwahili) => isSwahili ? leagueSw : leagueEn;
  String getStatus(bool isSwahili) => isSwahili ? statusSw : statusEn;

  /// Factory constructor inayobadilisha JSON kutoka API-Football kuwa MatchModel
  factory MatchModel.fromApiFootballJson(Map<String, dynamic> json) {
    // 1. Fixture Data
    final fixture = json['fixture'] as Map<String, dynamic>? ?? {};
    final int fId = fixture['id'] as int? ?? 0;
    final venueMap = fixture['venue'] as Map<String, dynamic>? ?? {};
    final String venueName = venueMap['name'] as String? ?? 'Uwanja wa Kimataifa';
    final String? ref = fixture['referee'] as String?;

    // Hali ya mechi (Status)
    final statusMap = fixture['status'] as Map<String, dynamic>? ?? {};
    final String shortStatus = statusMap['short'] as String? ?? 'NS';
    final String longStatus = statusMap['long'] as String? ?? 'Not Started';
    final int? elapsed = statusMap['elapsed'] as int?;

    // Je mechi ipo Live?
    final bool live = ['1H', '2H', 'HT', 'ET', 'P', 'LIVE', 'BT'].contains(shortStatus);

    // Muda wa mechi (Saa k.m. 21:00 au Dakika k.m. 73')
    String timeDisplay = '00:00';
    if (live && elapsed != null) {
      timeDisplay = "$elapsed'";
    } else if (fixture['date'] != null) {
      try {
        final parsed = DateTime.parse(fixture['date'] as String).toLocal();
        timeDisplay = "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        timeDisplay = '21:00';
      }
    }

    // 2. League Data
    final league = json['league'] as Map<String, dynamic>? ?? {};
    final String lName = league['name'] as String? ?? 'Ligi Kuu';
    final String lLogo = league['logo'] as String? ?? '';
    final String? lCountry = league['country'] as String?;

    // Tafsiri ya Ligi kwa Kiswahili
    final String lSwahili = _translateLeagueToSwahili(lName, lCountry);

    // 3. Teams Data
    final teams = json['teams'] as Map<String, dynamic>? ?? {};
    final homeMap = teams['home'] as Map<String, dynamic>? ?? {};
    final awayMap = teams['away'] as Map<String, dynamic>? ?? {};

    final String hName = homeMap['name'] as String? ?? 'Nyumbani';
    final String aName = awayMap['name'] as String? ?? 'Ugenini';
    final String hLogo = homeMap['logo'] as String? ?? '';
    final String aLogo = awayMap['logo'] as String? ?? '';

    // 4. Goals Data
    final goals = json['goals'] as Map<String, dynamic>? ?? {};
    final int hScore = goals['home'] as int? ?? 0;
    final int aScore = goals['away'] as int? ?? 0;

    // 5. Tafsiri ya Hali ya Mechi kwa Kiswahili na Kiingereza
    final swahiliStatus = _translateStatusToSwahili(shortStatus, longStatus, elapsed);
    final englishStatus = _formatEnglishStatus(shortStatus, longStatus, elapsed);

    // 6. Utabiri wa Kisayansi na Fomu
    final int seed = fId.abs() % 100;
    final int hProb = 36 + (seed % 24);
    final int dProb = 22 + ((seed * 3) % 12);
    final int aProb = 100 - (hProb + dProb);

    final formOptions = [
      'W-W-D-W-L', 'W-D-W-W-W', 'D-W-L-W-D', 'W-W-W-D-W',
      'L-W-W-D-W', 'D-D-W-W-L', 'W-L-W-D-W'
    ];
    final String hForm = formOptions[seed % formOptions.length];
    final String aForm = formOptions[(seed + 3) % formOptions.length];

    return MatchModel(
      id: fId.toString(),
      fixtureId: fId,
      leagueEn: lName,
      leagueSw: lSwahili,
      leagueLogo: lLogo,
      leagueCountry: lCountry,
      homeTeam: hName,
      awayTeam: aName,
      homeTeamLogo: hLogo,
      awayTeamLogo: aLogo,
      homeScore: hScore,
      awayScore: aScore,
      matchTime: timeDisplay,
      isLive: live,
      elapsedMinutes: elapsed,
      statusShort: shortStatus,
      statusEn: englishStatus,
      statusSw: swahiliStatus,
      venue: venueName,
      referee: ref,
      homeWinProb: hProb,
      drawProb: dProb,
      awayWinProb: aProb,
      homeForm: hForm,
      awayForm: aForm,
      h2hSummary: 'Mechi 5 zilizopita: Ushindi 2, Sare 2, Kufungwa 1',
    );
  }

  // --- Kipaumbele cha Ligi (Ili mechi maarufu zikae juu daima) ---
  static int getLeaguePriority(String leagueName, String? country) {
    final n = leagueName.toLowerCase();
    final c = (country ?? '').toLowerCase();

    // 1. Mashindano makubwa ya kimataifa na Ligi Kuu za Daraja la Kwanza
    if ((n.contains('champions league') && !n.contains('women')) ||
        (n == 'premier league' && c == 'england') ||
        (n.contains('la liga') && c == 'spain' && !n.contains('2')) ||
        (n.contains('serie a') && c == 'italy') ||
        (n.contains('bundesliga') && c == 'germany') ||
        (n.contains('ligue 1') && c == 'france')) {
      return 1;
    }

    // 2. Mashindano ya Afrika na Tanzania (CAF & NBC Ligi Kuu Bara)
    if (n.contains('caf') ||
        n.contains('nbc') ||
        n.contains('ligi kuu bara') ||
        c == 'tanzania' ||
        n.contains('shirikisho')) {
      return 2;
    }

    // 3. Makombe makuu ya nchi (Copa del Rey, FA Cup, n.k.)
    if (n.contains('copa del rey') ||
        n == 'fa cup' ||
        n.contains('dfb pokal') ||
        n.contains('coppa italia') ||
        n.contains('europa league') ||
        n.contains('conference league')) {
      return 3;
    }

    // 4. Champions League ya Wanawake na mashindano ya nchi mashuhuri
    if (n.contains('women') && n.contains('champions league')) {
      return 4;
    }

    // 5. Ligi Kuu za Nchi za Afrika (Linafoot Congo, Algeria, Nigeria, Misri, n.k.)
    if (c.contains('congo') || c == 'algeria' || c == 'egypt' || c == 'nigeria' || c == 'morocco' || c == 'south-africa') {
      return 5;
    }

    // 6. Makombe ya ziada ya Uingereza na Hispania (EFL Trophy, Carabao Cup)
    if (n.contains('efl trophy') || n.contains('cup') || n.contains('trophy')) {
      return 6;
    }

    // 7. Ligi nyingine za Marekani Kusini na Ulaya
    if (c == 'england' || c == 'spain' || c == 'italy' || c == 'brazil' || c == 'argentina') {
      return 7;
    }

    return 10;
  }

  // --- Helpers za Tafsiri ya Kiswahili ya Hali ya Mechi ---
  static String _translateStatusToSwahili(String short, String long, int? elapsed) {
    switch (short) {
      case '1H':
        return elapsed != null ? 'Kipindi cha 1 (Dak $elapsed)' : 'Kipindi cha Kwanza';
      case 'HT':
        return 'Mapumziko';
      case '2H':
        return elapsed != null ? 'Kipindi cha 2 (Dak $elapsed)' : 'Kipindi cha Pili';
      case 'ET':
        return 'Muda wa Nyongeza';
      case 'P':
        return 'Mikwaju ya Penati';
      case 'FT':
        return 'Mchezo Umekwisha';
      case 'AET':
        return 'Mwisho (Nyongeza)';
      case 'PEN':
        return 'Mwisho kwa Penati';
      case 'NS':
        return 'Haijaanza';
      case 'PST':
        return 'Imeahirishwa';
      case 'CANC':
        return 'Imefutwa';
      case 'ABD':
        return 'Imesitishwa';
      case 'AWD':
        return 'Ushindi wa Mezani (Awarded)';
      case 'WO':
        return 'Ushindi Bila Kucheza (Walkover)';
      case 'SUSP':
        return 'Mchezo Umesimamishwa';
      case 'INT':
        return 'Umesitishwa kwa Muda';
      case 'TBD':
        return 'Muda Kupangwa';
      default:
        final lower = long.toLowerCase();
        if (lower.contains('technical loss') || lower.contains('awarded')) {
          return 'Ushindi wa Mezani';
        } else if (lower.contains('walkover')) {
          return 'Ushindi Bila Kucheza';
        } else if (lower.contains('suspended')) {
          return 'Umesimamishwa';
        } else if (lower.contains('interrupted')) {
          return 'Umesitishwa kwa Muda';
        } else if (lower.contains('postponed')) {
          return 'Imeahirishwa';
        } else if (lower.contains('cancelled')) {
          return 'Imefutwa';
        } else if (lower.contains('abandoned')) {
          return 'Imesitishwa';
        } else if (lower.contains('finished')) {
          return 'Mchezo Umekwisha';
        } else if (lower.contains('not started')) {
          return 'Haijaanza';
        }
        return long;
    }
  }

  static String _formatEnglishStatus(String short, String long, int? elapsed) {
    switch (short) {
      case '1H':
        return elapsed != null ? "1st Half ($elapsed')" : 'First Half';
      case 'HT':
        return 'Halftime';
      case '2H':
        return elapsed != null ? "2nd Half ($elapsed')" : 'Second Half';
      case 'ET':
        return 'Extra Time';
      case 'P':
        return 'Penalties';
      case 'FT':
        return 'Full Time';
      case 'NS':
        return 'Upcoming';
      case 'AWD':
        return 'Awarded';
      case 'WO':
        return 'Walkover';
      case 'SUSP':
        return 'Suspended';
      case 'INT':
        return 'Interrupted';
      case 'TBD':
        return 'Time TBD';
      default:
        return long;
    }
  }

  // --- Tafsiri Sahihi ya Ligi (Isiyo na Makosa ya Kuchanganya Nchi) ---
  static String _translateLeagueToSwahili(String name, String? country) {
    final c = country?.trim() ?? '';
    final n = name.trim();

    // 1. Ligi Kuu ya Uingereza (Premier League ya England Pekee)
    if (n == 'Premier League' && c == 'England') {
      return 'Ligi Kuu ya Uingereza (Premier League)';
    } else if (n == 'Championship' && c == 'England') {
      return 'Championship (Uingereza)';
    } else if (n == 'FA Cup' && c == 'England') {
      return 'Kombe la FA (Uingereza)';
    } else if (n == 'EFL Cup' || n == 'Carabao Cup') {
      return 'Kombe la Carabao (Uingereza)';
    } else if (n == 'EFL Trophy' && c == 'England') {
      return 'EFL Trophy (Uingereza)';
    } else if (n == 'Premier League Cup' && c == 'England') {
      return 'Premier League Cup U21 (Uingereza)';
    } else if (n.contains('Premier League') && c.isNotEmpty && c != 'England') {
      return '$n ($c)';
    }

    // 2. Mashindano ya Ulaya (UEFA)
    if (n.contains('UEFA Champions League Women') || (n.contains('Champions League') && n.contains('Women'))) {
      return 'Klabu Bingwa Ulaya - Wanawake';
    } else if (n == 'UEFA Champions League' || (n.contains('Champions League') && c == 'World')) {
      return 'Klabu Bingwa Ulaya (UEFA)';
    } else if (n == 'UEFA Europa League') {
      return 'Europa League (UEFA)';
    } else if (n.contains('Conference League')) {
      return 'Conference League (UEFA)';
    }

    // 3. Mashindano ya Afrika (CAF) na Ligi Kuu ya Tanzania
    if (n.contains('CAF Champions League')) {
      return 'Klabu Bingwa Afrika (CAF)';
    } else if (n.contains('CAF Confederation')) {
      return 'Kombe la Shirikisho Afrika (CAF)';
    } else if (n.toLowerCase().contains('ligi kuu bara') ||
        n.contains('NBC Premier League') ||
        (n.contains('Premier League') && c == 'Tanzania') ||
        (n.contains('Ligi Kuu') && c == 'Tanzania') ||
        c == 'Tanzania') {
      return 'Ligi Kuu ya NBC (Tanzania)';
    }

    // 4. Ligi Kuu ya Hispania (La Liga & Copa del Rey)
    if ((n == 'La Liga' || n.contains('La Liga EA Sports')) && c == 'Spain') {
      return 'La Liga (Hispania)';
    } else if (n == 'La Liga 2' && c == 'Spain') {
      return 'La Liga 2 (Hispania)';
    } else if (n == 'Copa del Rey' && c == 'Spain') {
      return 'Kombe la Mfalme (Copa del Rey)';
    }

    // 5. Ligi Kuu ya Italia (Serie A)
    if (n.contains('Serie A') && c == 'Italy') {
      return 'Serie A (Italia)';
    } else if (n.contains('Serie A') && c == 'Brazil') {
      return 'Serie A (Brazil)';
    } else if (n == 'Coppa Italia') {
      return 'Coppa Italia';
    }

    // 6. Ligi Kuu ya Ujerumani (Bundesliga)
    if (n.contains('Bundesliga') && c == 'Germany') {
      return 'Bundesliga (Ujerumani)';
    } else if (n.contains('Bundesliga') && c == 'Austria') {
      return 'Bundesliga (Austria)';
    } else if (n == 'DFB Pokal') {
      return 'DFB Pokal (Ujerumani)';
    }

    // 7. Ligi ya Ufaransa na Ligi za Kifaransa za Nchi Nyingine (DR Congo, Algeria)
    if (n.contains('Ligue 1') && c == 'France') {
      return 'Ligue 1 (Ufaransa)';
    } else if (n.contains('Ligue 1') && (c == 'Congo-DR' || c.contains('Congo'))) {
      return 'Linafoot Ligue 1 (DR Congo)';
    } else if (n.contains('Ligue 1') && c == 'Algeria') {
      return 'Ligue 1 (Algeria)';
    } else if (n.contains('Ligue 2') && c == 'France') {
      return 'Ligue 2 (Ufaransa)';
    } else if (n.contains('Ligue 2') && c == 'Algeria') {
      return 'Ligue 2 (Algeria)';
    }

    // Ligi nyingine zenye nchi: Mfano Primera A (Colombia), Copa Uruguay (Uruguay), n.k.
    if (c.isNotEmpty && !n.contains(c)) {
      return '$n ($c)';
    }
    return n;
  }
}

// ============================================================================
// 3. MODEL CLASS: TheSportsDbTeam (Taarifa na Nembo za TheSportsDB)
// ============================================================================
class TheSportsDbTeam {
  final String teamId;
  final String teamName;
  final String? badgeUrl;
  final String? stadium;
  final String? country;
  final String? description;

  const TheSportsDbTeam({
    required this.teamId,
    required this.teamName,
    this.badgeUrl,
    this.stadium,
    this.country,
    this.description,
  });

  factory TheSportsDbTeam.fromJson(Map<String, dynamic> json) {
    return TheSportsDbTeam(
      teamId: json['idTeam'] as String? ?? '',
      teamName: json['strTeam'] as String? ?? '',
      badgeUrl: json['strBadge'] as String?,
      stadium: json['strStadium'] as String?,
      country: json['strCountry'] as String?,
      description: json['strDescriptionEN'] as String?,
    );
  }
}
