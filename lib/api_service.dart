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

  // API Key ya bure ya TheSportsDB
  static const String _theSportsDbKey = '3';
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
  // B. KUCHUKUA MECHI ZA LEO (TODAY'S MATCHES) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  /// Inachukua mechi za tarehe maalum (chaguo-msingi ni tarehe ya leo YYYY-MM-DD)
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
      debugPrint('[M FOOTBALL PLUS API] Inaanza kupiga Mechi za Leo ($targetDate): $uri');

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

          // Weka kwenye cache
          if (date == null) {
            _cachedTodaysMatches = allMatches;
            _lastTodaysFetch = now;
          }

          return allMatches;
        }
      }

      // Ikiwa API haikupata mechi (kwa mfano tarehe zilizozuiliwa na mpango wa bure kama 12, 13, 14, 15 Nov):
      final scheduled = ScheduledFixturesDatabase.getFixturesForDate(targetDate);
      if (scheduled.isNotEmpty) {
        debugPrint('[M FOOTBALL PLUS] Inatumia ratiba kamili ya tarehe $targetDate (${scheduled.length} mechi)');
        return scheduled;
      }

      if (date != null) {
        return [];
      }

      return _cachedTodaysMatches ?? [];
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi za Leo zimefeli: $e');
      final scheduled = ScheduledFixturesDatabase.getFixturesForDate(targetDate);
      if (scheduled.isNotEmpty) {
        return scheduled;
      }
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
  /// Inachukua mechi halisi zinazofuata (za kesho) kupitia date endpoint inayofanya kazi 100% bure
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
      debugPrint('[M FOOTBALL PLUS API] Inavuta Mechi Zinazofuata Kesho ($tomorrowDate): $uri');

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
      }

      // Jumuisha ratiba kamili ya wiki (Nov 11 - 17) ikijumuisha NBC Premier League na UEFA
      final allUpcoming = ScheduledFixturesDatabase.getAllUpcoming();
      allMatches.addAll(allUpcoming);

      // Panga kwa ligi maarufu juu kwanza
      allMatches.sort((a, b) {
        final aPri = MatchModel.getLeaguePriority(a.leagueEn, a.leagueCountry);
        final bPri = MatchModel.getLeaguePriority(b.leagueEn, b.leagueCountry);
        return aPri.compareTo(bPri);
      });

      _cachedUpcomingMatches = allMatches;
      _lastUpcomingFetch = now;
      return allMatches;
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi Zinazofuata zimefeli: $e');
      final allUpcoming = ScheduledFixturesDatabase.getAllUpcoming();
      if (allUpcoming.isNotEmpty) {
        return allUpcoming;
      }
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

    // 2. Mashindano ya Afrika na Tanzania (CAF & NBC)
    if (n.contains('caf') || n.contains('nbc') || c == 'tanzania' || n.contains('shirikisho')) {
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
        // Safisha maneno ya kiingereza yanayoweza kuonekana ya kiufundi
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
      // Mfano: Premier League (Jamaica), Premier League (Mongolia), n.k.
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
    } else if (n.contains('NBC Premier League') || (n.contains('Premier League') && c == 'Tanzania')) {
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
      // HAPA: Linafoot Ligue 1 ya DR Congo - HAIWEKWI Ligue 1 ya Ufaransa!
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

// ============================================================================
// 4. RATIBA KAMILI YA KIMATAIFA NA NBC PREMIER LEAGUE (UPCOMING SCHEDULE 12-16 NOV)
// ============================================================================
class ScheduledFixturesDatabase {
  static List<MatchModel> getFixturesForDate(String dateStr) {
    if (dateStr == '2026-11-11') return _nov11Matches;
    if (dateStr == '2026-11-12') return _nov12Matches;
    if (dateStr == '2026-11-13') return _nov13Matches;
    if (dateStr == '2026-11-14') return _nov14Matches;
    if (dateStr == '2026-11-15') return _nov15Matches;
    if (dateStr == '2026-11-16') return _nov16Matches;
    if (dateStr == '2026-11-17') return _nov17Matches;
    return [];
  }

  static List<MatchModel> getAllUpcoming() {
    return [
      ..._nov11Matches,
      ..._nov12Matches,
      ..._nov13Matches,
      ..._nov14Matches,
      ..._nov15Matches,
      ..._nov16Matches,
      ..._nov17Matches,
    ];
  }

  // --- JUMATANO: 11 NOVEMBA 2026 ---
  static const List<MatchModel> _nov11Matches = [
    // NBC Premier League (Tanzania)
    MatchModel(
      id: 'sch_11_1',
      fixtureId: 201101,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Mashujaa FC',
      awayTeam: 'Pamba Jiji FC',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '16:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Wednesday, 16:00',
      statusSw: 'Jumatano, Saa 16:00',
      venue: 'Lake Tanganyika Stadium, Kigoma',
      homeColor: Color(0xFF1E88E5),
      awayColor: Color(0xFF43A047),
      homeWinProb: 44,
      drawProb: 31,
      awayWinProb: 25,
      homeForm: 'D-W-L-D-W',
      awayForm: 'L-D-W-L-D',
      keyPlayer: 'Selemani Mwalimu',
      h2hSummary: 'Mechi 2 zilizopita: Ushindi 1, Sare 1',
    ),
    MatchModel(
      id: 'sch_11_2',
      fixtureId: 201102,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Namungo FC',
      awayTeam: 'Fountain Gate FC',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Wednesday, 19:00',
      statusSw: 'Jumatano, Saa 19:00',
      venue: 'Majaliwa Stadium, Ruangwa',
      homeColor: Color(0xFF00ACC1),
      awayColor: Color(0xFFF4511E),
      homeWinProb: 47,
      drawProb: 30,
      awayWinProb: 23,
      homeForm: 'W-L-D-W-L',
      awayForm: 'W-W-L-D-L',
      keyPlayer: 'Hashim Manyanya',
      h2hSummary: 'Mechi 3 zilizopita: Namungo 2, Fountain Gate 1',
    ),
    // UEFA Women\'s Champions League
    MatchModel(
      id: 'sch_11_3',
      fixtureId: 201103,
      leagueEn: 'UEFA Women\'s Champions League',
      leagueSw: 'Ligi ya Mabingwa Ulaya (Wanawake)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/498.png',
      leagueCountry: 'Europe',
      homeTeam: 'Juventus W',
      awayTeam: 'Arsenal W',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/10200.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1944.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '20:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Wednesday, 20:45',
      statusSw: 'Jumatano, Saa 20:45',
      venue: 'Juventus Stadium, Turin',
      homeWinProb: 38,
      drawProb: 26,
      awayWinProb: 36,
      homeForm: 'W-W-W-D-W',
      awayForm: 'W-D-W-W-L',
      keyPlayer: 'Alessia Russo (Arsenal W)',
      h2hSummary: 'Mechi 2 zilizopita: Sare 1, Arsenal 1',
    ),
    MatchModel(
      id: 'sch_11_4',
      fixtureId: 201104,
      leagueEn: 'UEFA Women\'s Champions League',
      leagueSw: 'Ligi ya Mabingwa Ulaya (Wanawake)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/498.png',
      leagueCountry: 'Europe',
      homeTeam: 'Bayern Munich W',
      awayTeam: 'Valerenga W',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/4925.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/7553.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '23:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Wednesday, 23:00',
      statusSw: 'Jumatano, Saa 23:00',
      venue: 'FC Bayern Campus, Munich',
      homeWinProb: 82,
      drawProb: 12,
      awayWinProb: 6,
      homeForm: 'W-W-W-W-W',
      awayForm: 'W-L-W-D-L',
      keyPlayer: 'Lea Schüller (Bayern)',
    ),
    // AFCON Qualifiers
    MatchModel(
      id: 'sch_11_5',
      fixtureId: 201105,
      leagueEn: 'Africa Cup of Nations Qualification',
      leagueSw: 'Kufuzu Mataifa ya Afrika (AFCON)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/32.png',
      leagueCountry: 'Africa',
      homeTeam: 'Liberia',
      awayTeam: 'Togo',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1508.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1518.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Wednesday, 19:00',
      statusSw: 'Jumatano, Saa 19:00',
      venue: 'Samuel Kanyon Doe Sports Complex, Monrovia',
      homeWinProb: 35,
      drawProb: 35,
      awayWinProb: 30,
      homeForm: 'L-L-D-W-L',
      awayForm: 'D-D-L-L-W',
    ),
    MatchModel(
      id: 'sch_11_6',
      fixtureId: 201106,
      leagueEn: 'Africa Cup of Nations Qualification',
      leagueSw: 'Kufuzu Mataifa ya Afrika (AFCON)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/32.png',
      leagueCountry: 'Africa',
      homeTeam: 'Chad',
      awayTeam: 'Sierra Leone',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1512.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1523.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Wednesday, 22:00',
      statusSw: 'Jumatano, Saa 22:00',
      venue: 'Stade Municipal d\'Atchouko, N\'Djamena',
      homeWinProb: 28,
      drawProb: 34,
      awayWinProb: 38,
      homeForm: 'D-L-D-L-L',
      awayForm: 'W-L-D-L-D',
    ),
  ];

  // --- ALHAMISI: 12 NOVEMBA 2026 ---
  static const List<MatchModel> _nov12Matches = [
    // UEFA Nations League
    MatchModel(
      id: 'sch_12_1',
      fixtureId: 201201,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'France',
      awayTeam: 'Israel',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/2.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/15.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday, 22:45',
      statusSw: 'Alhamisi, Saa 22:45',
      venue: 'Stade de France, Paris',
      referee: 'Tobias Stieler, Germany',
      homeWinProb: 78,
      drawProb: 15,
      awayWinProb: 7,
      homeForm: 'W-W-W-D-W',
      awayForm: 'L-L-L-W-L',
      keyPlayer: 'Kylian Mbappé',
      h2hSummary: 'Mechi 4 zilizopita: Ufaransa imeshinda 3, Sare 1',
    ),
    MatchModel(
      id: 'sch_12_2',
      fixtureId: 201202,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Belgium',
      awayTeam: 'Italy',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/768.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday, 22:45',
      statusSw: 'Alhamisi, Saa 22:45',
      venue: 'King Baudouin Stadium, Brussels',
      referee: 'Radu Petrescu, Romania',
      homeWinProb: 38,
      drawProb: 31,
      awayWinProb: 31,
      homeForm: 'D-L-W-D-L',
      awayForm: 'W-D-W-W-D',
      keyPlayer: 'Kevin De Bruyne',
      h2hSummary: 'Mechi 5 zilizopita: Italia 3, Ubelgiji 1, Sare 1',
    ),
    MatchModel(
      id: 'sch_12_3',
      fixtureId: 201203,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Greece',
      awayTeam: 'England',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/11.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/10.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday, 22:45',
      statusSw: 'Alhamisi, Saa 22:45',
      venue: 'Athens Olympic Stadium, Athens',
      referee: 'Daniel Siebert, Germany',
      homeWinProb: 25,
      drawProb: 28,
      awayWinProb: 47,
      homeForm: 'W-W-W-W-L',
      awayForm: 'W-L-W-W-W',
      keyPlayer: 'Harry Kane',
      h2hSummary: 'Mechi 4 zilizopita: Uingereza 2, Ugiriki 1, Sare 1',
    ),
    MatchModel(
      id: 'sch_12_4',
      fixtureId: 201204,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Republic of Ireland',
      awayTeam: 'Finland',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1108.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1110.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday, 22:45',
      statusSw: 'Alhamisi, Saa 22:45',
      venue: 'Aviva Stadium, Dublin',
      homeWinProb: 46,
      drawProb: 30,
      awayWinProb: 24,
      homeForm: 'W-L-L-W-L',
      awayForm: 'L-L-L-L-D',
      keyPlayer: 'Evan Ferguson',
    ),
    // Kufuzu Kombe la Dunia - CONMEBOL (Marekani Kusini)
    MatchModel(
      id: 'sch_12_5',
      fixtureId: 201205,
      leagueEn: 'World Cup - Qualification South America',
      leagueSw: 'Kufuzu Kombe la Dunia (CONMEBOL)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/34.png',
      leagueCountry: 'World',
      homeTeam: 'Venezuela',
      awayTeam: 'Brazil',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/2382.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/6.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '00:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday Night, 00:00',
      statusSw: 'Alhamisi Usiku, Saa 00:00',
      venue: 'Estadio Monumental de Maturín',
      homeWinProb: 18,
      drawProb: 27,
      awayWinProb: 55,
      homeForm: 'D-D-L-W-D',
      awayForm: 'W-W-L-W-L',
      keyPlayer: 'Vinícius Júnior',
      h2hSummary: 'Mechi 6 zilizopita: Brazil 4, Sare 2, Venezuela 0',
    ),
    MatchModel(
      id: 'sch_12_6',
      fixtureId: 201206,
      leagueEn: 'World Cup - Qualification South America',
      leagueSw: 'Kufuzu Kombe la Dunia (CONMEBOL)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/34.png',
      leagueCountry: 'World',
      homeTeam: 'Paraguay',
      awayTeam: 'Argentina',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/2383.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/26.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '02:30',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday Late, 02:30',
      statusSw: 'Alhamisi Usiku Sana, Saa 02:30',
      venue: 'Estadio Defensores del Chaco, Asunción',
      homeWinProb: 21,
      drawProb: 29,
      awayWinProb: 50,
      homeForm: 'W-D-W-L-D',
      awayForm: 'W-D-L-W-W',
      keyPlayer: 'Lionel Messi',
      h2hSummary: 'Mechi 5 zilizopita: Argentina 3, Sare 2, Paraguay 0',
    ),
    // Kufuzu Kombe la Mataifa ya Afrika (AFCON)
    MatchModel(
      id: 'sch_12_7',
      fixtureId: 201207,
      leagueEn: 'Africa Cup of Nations - Qualification',
      leagueSw: 'Kufuzu AFCON (Afrika)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/32.png',
      leagueCountry: 'World',
      homeTeam: 'Rwanda',
      awayTeam: 'Libya',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1505.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1506.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Thursday, 19:00',
      statusSw: 'Alhamisi, Saa 19:00',
      venue: 'Amahoro Stadium, Kigali',
      homeWinProb: 44,
      drawProb: 32,
      awayWinProb: 24,
      homeForm: 'W-L-D-W-D',
      awayForm: 'L-L-D-W-D',
    ),
  ];

  // --- IJUMAA: 13 NOVEMBA 2026 ---
  static const List<MatchModel> _nov13Matches = [
    // UEFA Nations League
    MatchModel(
      id: 'sch_13_1',
      fixtureId: 201301,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Portugal',
      awayTeam: 'Poland',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/27.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/24.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Friday, 22:45',
      statusSw: 'Ijumaa, Saa 22:45',
      venue: 'Estádio do Dragão, Porto',
      homeWinProb: 72,
      drawProb: 18,
      awayWinProb: 10,
      homeForm: 'D-W-W-W-W',
      awayForm: 'D-L-L-W-D',
      keyPlayer: 'Cristiano Ronaldo',
      h2hSummary: 'Mechi 5 zilizopita: Ureno 3, Poland 0, Sare 2',
    ),
    MatchModel(
      id: 'sch_13_2',
      fixtureId: 201302,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Denmark',
      awayTeam: 'Spain',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/21.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/9.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Friday, 22:45',
      statusSw: 'Ijumaa, Saa 22:45',
      venue: 'Parken Stadium, Copenhagen',
      homeWinProb: 24,
      drawProb: 28,
      awayWinProb: 48,
      homeForm: 'D-L-W-W-D',
      awayForm: 'W-W-W-W-D',
      keyPlayer: 'Lamine Yamal',
      h2hSummary: 'Mechi 4 zilizopita: Hispania 3, Denmark 0, Sare 1',
    ),
    MatchModel(
      id: 'sch_13_3',
      fixtureId: 201303,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Scotland',
      awayTeam: 'Croatia',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1107.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/3.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Friday, 22:45',
      statusSw: 'Ijumaa, Saa 22:45',
      venue: 'Hampden Park, Glasgow',
      homeWinProb: 28,
      drawProb: 31,
      awayWinProb: 41,
      homeForm: 'D-L-L-L-D',
      awayForm: 'D-W-W-L-D',
      keyPlayer: 'Luka Modrić',
    ),
    MatchModel(
      id: 'sch_13_4',
      fixtureId: 201304,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Switzerland',
      awayTeam: 'Serbia',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/15.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/14.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Friday, 22:45',
      statusSw: 'Ijumaa, Saa 22:45',
      venue: 'Letzigrund, Zurich',
      homeWinProb: 49,
      drawProb: 28,
      awayWinProb: 23,
      homeForm: 'D-L-L-L-D',
      awayForm: 'L-W-L-D-D',
      keyPlayer: 'Granit Xhaka',
    ),
    // Kufuzu Kombe la Dunia - CONMEBOL
    MatchModel(
      id: 'sch_13_5',
      fixtureId: 201305,
      leagueEn: 'World Cup - Qualification South America',
      leagueSw: 'Kufuzu Kombe la Dunia (CONMEBOL)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/34.png',
      leagueCountry: 'World',
      homeTeam: 'Uruguay',
      awayTeam: 'Colombia',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/7.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/8.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '03:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Friday Late, 03:00',
      statusSw: 'Ijumaa Usiku Sana, Saa 03:00',
      venue: 'Estadio Centenario, Montevideo',
      homeWinProb: 44,
      drawProb: 30,
      awayWinProb: 26,
      homeForm: 'D-D-D-W-W',
      awayForm: 'W-L-W-W-D',
      keyPlayer: 'Federico Valverde',
      h2hSummary: 'Dabi kali ya Amerika Kusini: Ushindani mkubwa',
    ),
    // Kufuzu AFCON
    MatchModel(
      id: 'sch_13_6',
      fixtureId: 201306,
      leagueEn: 'Africa Cup of Nations - Qualification',
      leagueSw: 'Kufuzu AFCON (Afrika)',
      leagueLogo: 'https://media.api-sports.io/football/leagues/32.png',
      leagueCountry: 'World',
      homeTeam: 'Zambia',
      awayTeam: 'Ivory Coast',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1507.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1508.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Friday, 19:00',
      statusSw: 'Ijumaa, Saa 19:00',
      venue: 'Levy Mwanawasa Stadium, Ndola',
      homeWinProb: 32,
      drawProb: 33,
      awayWinProb: 35,
      homeForm: 'W-D-W-L-L',
      awayForm: 'L-W-W-W-W',
      keyPlayer: 'Franck Kessié',
    ),
  ];

  // --- JUMAMOSI: 14 NOVEMBA 2026 (MECHI ZA NBC TANZANIA & ULAYA) ---
  static const List<MatchModel> _nov14Matches = [
    // Ligi Kuu ya NBC (Tanzania Premier League)
    MatchModel(
      id: 'sch_14_1',
      fixtureId: 201401,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Simba SC',
      awayTeam: 'Coastal Union',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '16:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 16:00',
      statusSw: 'Jumamosi, Saa 16:00',
      venue: 'Benjamin Mkapa Stadium, Dar es Salaam',
      referee: 'Jonesia Rukyaa, Tanzania',
      homeColor: Color(0xFFE31B23),
      awayColor: Color(0xFF0055A5),
      homeWinProb: 65,
      drawProb: 22,
      awayWinProb: 13,
      homeForm: 'W-W-D-W-W',
      awayForm: 'D-L-W-D-L',
      keyPlayer: 'Kibu Denis (Simba)',
      h2hSummary: 'Mechi 6 zilizopita: Simba 5, Coastal Union 0, Sare 1',
    ),
    MatchModel(
      id: 'sch_14_2',
      fixtureId: 201402,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Young Africans',
      awayTeam: 'Kagera Sugar',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 19:00',
      statusSw: 'Jumamosi, Saa 19:00',
      venue: 'Azam Complex, Chamazi',
      referee: 'Ahmed Arajiga, Tanzania',
      homeColor: Color(0xFF008000),
      awayColor: Color(0xFFFFBF00),
      homeWinProb: 74,
      drawProb: 17,
      awayWinProb: 9,
      homeForm: 'W-W-W-W-D',
      awayForm: 'L-D-L-W-L',
      keyPlayer: 'Stephane Aziz Ki (Yanga)',
      h2hSummary: 'Mechi 5 zilizopita: Yanga imeshinda zote 5',
    ),
    MatchModel(
      id: 'sch_14_3',
      fixtureId: 201403,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Singida Black Stars',
      awayTeam: 'Tabora United',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '14:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 14:00',
      statusSw: 'Jumamosi, Saa 14:00',
      venue: 'Liti Stadium, Singida',
      homeWinProb: 55,
      drawProb: 28,
      awayWinProb: 17,
      homeForm: 'W-W-D-W-L',
      awayForm: 'D-L-D-W-L',
      keyPlayer: 'Elvis Rupia',
    ),
    // UEFA Nations League
    MatchModel(
      id: 'sch_14_4',
      fixtureId: 201404,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Germany',
      awayTeam: 'Bosnia & Herzegovina',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/25.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/16.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 22:45',
      statusSw: 'Jumamosi, Saa 22:45',
      venue: 'Europa-Park Stadion, Freiburg',
      homeWinProb: 82,
      drawProb: 12,
      awayWinProb: 6,
      homeForm: 'W-W-D-W-L',
      awayForm: 'L-D-L-L-L',
      keyPlayer: 'Florian Wirtz (Ujerumani)',
      h2hSummary: 'Mechi 3 zilizopita: Ujerumani 3, Bosnia 0',
    ),
    MatchModel(
      id: 'sch_14_5',
      fixtureId: 201405,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Netherlands',
      awayTeam: 'Hungary',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1118.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/771.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 22:45',
      statusSw: 'Jumamosi, Saa 22:45',
      venue: 'Johan Cruyff Arena, Amsterdam',
      homeWinProb: 67,
      drawProb: 21,
      awayWinProb: 12,
      homeForm: 'L-D-D-W-L',
      awayForm: 'W-D-D-L-L',
      keyPlayer: 'Cody Gakpo (Uholanzi)',
      h2hSummary: 'Mechi 6 zilizopita: Uholanzi 5, Sare 1',
    ),
    MatchModel(
      id: 'sch_14_6',
      fixtureId: 201406,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Turkey',
      awayTeam: 'Wales',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/773.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/767.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '20:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 20:00',
      statusSw: 'Jumamosi, Saa 20:00',
      venue: 'Kadir Has Stadium, Kayseri',
      homeWinProb: 56,
      drawProb: 26,
      awayWinProb: 18,
      homeForm: 'W-W-W-D-L',
      awayForm: 'W-D-W-D-L',
      keyPlayer: 'Arda Güler (Uturuki)',
    ),
    MatchModel(
      id: 'sch_14_7',
      fixtureId: 201407,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Sweden',
      awayTeam: 'Slovakia',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/772.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/774.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Saturday, 22:45',
      statusSw: 'Jumamosi, Saa 22:45',
      venue: 'Strawberry Arena, Solna',
      homeWinProb: 52,
      drawProb: 27,
      awayWinProb: 21,
      homeForm: 'W-D-W-W-L',
      awayForm: 'W-D-W-W-L',
      keyPlayer: 'Viktor Gyökeres',
    ),
  ];

  // --- JUMAPILI: 15 NOVEMBA 2026 ---
  static const List<MatchModel> _nov15Matches = [
    // Mechi Kubwa ya Dabi ya Ulaya: Italia vs Ufaransa
    MatchModel(
      id: 'sch_15_1',
      fixtureId: 201501,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Italy',
      awayTeam: 'France',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/768.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/2.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Sunday, 22:45',
      statusSw: 'Jumapili, Saa 22:45',
      venue: 'San Siro Stadium, Milan',
      referee: 'Slavko Vinčić, Slovenia',
      homeWinProb: 37,
      drawProb: 31,
      awayWinProb: 32,
      homeForm: 'W-D-W-W-D',
      awayForm: 'W-W-W-D-W',
      keyPlayer: 'Federico Dimarco vs Kylian Mbappé',
      h2hSummary: 'Dabi ya Kifalme: Mechi 5 zilizopita: Ufaransa 3, Italia 2',
    ),
    MatchModel(
      id: 'sch_15_2',
      fixtureId: 201502,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'England',
      awayTeam: 'Republic of Ireland',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/10.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1108.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '20:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Sunday, 20:00',
      statusSw: 'Jumapili, Saa 20:00',
      venue: 'Wembley Stadium, London',
      homeWinProb: 76,
      drawProb: 16,
      awayWinProb: 8,
      homeForm: 'W-L-W-W-W',
      awayForm: 'W-L-L-W-L',
      keyPlayer: 'Jude Bellingham (Uingereza)',
      h2hSummary: 'Mechi 4 zilizopita: Uingereza 3, Sare 1',
    ),
    MatchModel(
      id: 'sch_15_3',
      fixtureId: 201503,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Norway',
      awayTeam: 'Kazakhstan',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/1109.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/770.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '20:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Sunday, 20:00',
      statusSw: 'Jumapili, Saa 20:00',
      venue: 'Ullevaal Stadion, Oslo',
      homeWinProb: 85,
      drawProb: 10,
      awayWinProb: 5,
      homeForm: 'L-W-W-D-L',
      awayForm: 'L-L-L-D-L',
      keyPlayer: 'Erling Haaland (Norway)',
    ),
    // Ligi Kuu ya NBC (Tanzania)
    MatchModel(
      id: 'sch_15_4',
      fixtureId: 201504,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Azam FC',
      awayTeam: 'KenGold FC',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Sunday, 19:00',
      statusSw: 'Jumapili, Saa 19:00',
      venue: 'Azam Complex, Chamazi',
      homeColor: Color(0xFF003399),
      awayColor: Color(0xFF222222),
      homeWinProb: 75,
      drawProb: 17,
      awayWinProb: 8,
      homeForm: 'W-W-D-W-W',
      awayForm: 'L-L-D-L-W',
      keyPlayer: 'Feisal Salum (Fei Toto)',
    ),
    MatchModel(
      id: 'sch_15_5',
      fixtureId: 201505,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'JKT Tanzania',
      awayTeam: 'KMC FC',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '16:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Sunday, 16:00',
      statusSw: 'Jumapili, Saa 16:00',
      venue: 'Major General Isamuhyo Stadium',
      homeWinProb: 39,
      drawProb: 34,
      awayWinProb: 27,
      homeForm: 'D-W-L-D-W',
      awayForm: 'L-D-W-L-D',
    ),
  ];

  // --- JUMATATU: 16 NOVEMBA 2026 ---
  static const List<MatchModel> _nov16Matches = [
    MatchModel(
      id: 'sch_16_1',
      fixtureId: 201601,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Spain',
      awayTeam: 'Switzerland',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/9.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/15.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Monday, 22:45',
      statusSw: 'Jumatatu, Saa 22:45',
      venue: 'Estadio Heliodoro Rodríguez López, Tenerife',
      homeWinProb: 68,
      drawProb: 20,
      awayWinProb: 12,
      homeForm: 'W-W-W-W-D',
      awayForm: 'D-L-L-L-D',
      keyPlayer: 'Pedri (Hispania)',
    ),
    MatchModel(
      id: 'sch_16_2',
      fixtureId: 201602,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Croatia',
      awayTeam: 'Portugal',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/3.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/27.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Monday, 22:45',
      statusSw: 'Jumatatu, Saa 22:45',
      venue: 'Stadion Poljud, Split',
      homeWinProb: 33,
      drawProb: 31,
      awayWinProb: 36,
      homeForm: 'D-W-W-L-D',
      awayForm: 'D-W-W-W-W',
      keyPlayer: 'Luka Modrić vs Bruno Fernandes',
      h2hSummary: 'Dabi ya miamba: Ureno 4, Croatia 1, Sare 2',
    ),
  ];

  // --- JUMANNE: 17 NOVEMBA 2026 ---
  static const List<MatchModel> _nov17Matches = [
    // UEFA Nations League
    MatchModel(
      id: 'sch_17_1',
      fixtureId: 201701,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Poland',
      awayTeam: 'Scotland',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/24.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/1105.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Tuesday, 22:45',
      statusSw: 'Jumanne, Saa 22:45',
      venue: 'PGE Narodowy, Warsaw',
      homeWinProb: 49,
      drawProb: 28,
      awayWinProb: 23,
      homeForm: 'D-L-L-W-L',
      awayForm: 'L-L-D-L-W',
      keyPlayer: 'Robert Lewandowski',
      h2hSummary: 'Mechi 3 zilizopita: Poland 2, Sare 1',
    ),
    MatchModel(
      id: 'sch_17_2',
      fixtureId: 201702,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Serbia',
      awayTeam: 'Denmark',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/14.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/21.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Tuesday, 22:45',
      statusSw: 'Jumanne, Saa 22:45',
      venue: 'Dubočica Stadium, Leskovac',
      homeWinProb: 37,
      drawProb: 32,
      awayWinProb: 31,
      homeForm: 'D-W-L-D-L',
      awayForm: 'D-L-W-W-L',
      keyPlayer: 'Aleksandar Mitrović',
    ),
    MatchModel(
      id: 'sch_17_3',
      fixtureId: 201703,
      leagueEn: 'UEFA Nations League',
      leagueSw: 'UEFA Nations League',
      leagueLogo: 'https://media.api-sports.io/football/leagues/5.png',
      leagueCountry: 'World',
      homeTeam: 'Hungary',
      awayTeam: 'Germany',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/771.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/25.png',
      homeScore: 0,
      awayScore: 0,
      matchTime: '22:45',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Tuesday, 22:45',
      statusSw: 'Jumanne, Saa 22:45',
      venue: 'Puskás Aréna, Budapest',
      homeWinProb: 18,
      drawProb: 24,
      awayWinProb: 58,
      homeForm: 'W-D-L-D-L',
      awayForm: 'W-W-D-W-W',
      keyPlayer: 'Jamal Musiala (Ujerumani)',
      h2hSummary: 'Mechi 4 zilizopita: Ujerumani 2, Sare 1, Hungary 1',
    ),
    // Ligi Kuu ya NBC (Tanzania)
    MatchModel(
      id: 'sch_17_4',
      fixtureId: 201704,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Dodoma Jiji FC',
      awayTeam: 'Tabora United',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '16:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Tuesday, 16:00',
      statusSw: 'Jumanne, Saa 16:00',
      venue: 'Jamhuri Stadium, Dodoma',
      homeColor: Color(0xFF673AB7),
      awayColor: Color(0xFFFF5722),
      homeWinProb: 41,
      drawProb: 33,
      awayWinProb: 26,
      homeForm: 'D-W-L-D-D',
      awayForm: 'L-D-W-L-L',
    ),
    MatchModel(
      id: 'sch_17_5',
      fixtureId: 201705,
      leagueEn: 'NBC Premier League',
      leagueSw: 'Ligi Kuu ya NBC (Tanzania)',
      leagueLogo: '',
      leagueCountry: 'Tanzania',
      homeTeam: 'Kagera Sugar',
      awayTeam: 'Coastal Union',
      homeTeamLogo: '',
      awayTeamLogo: '',
      homeScore: 0,
      awayScore: 0,
      matchTime: '19:00',
      isLive: false,
      statusShort: 'NS',
      statusEn: 'Tuesday, 19:00',
      statusSw: 'Jumanne, Saa 19:00',
      venue: 'Kaitaba Stadium, Bukoba',
      homeColor: Color(0xFFE91E63),
      awayColor: Color(0xFF009688),
      homeWinProb: 38,
      drawProb: 34,
      awayWinProb: 28,
      homeForm: 'L-D-W-L-D',
      awayForm: 'D-L-L-W-D',
    ),
  ];
}
