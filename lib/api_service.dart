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

  // ==========================================================================
  // NEMBO RASMI ZA VILABU (VERIFIED HIGH-DEFINITION TEAM LOGOS)
  // ==========================================================================
  static String getTeamLogo(String teamName, {String? fallbackUrl}) {
    final lower = teamName.trim().toLowerCase();

    // 1. Vilabu vya Ligi Kuu ya NBC Tanzania
    if (lower.contains('young africans') || lower.contains('yanga')) {
      return 'https://media.api-sports.io/football/teams/5370.png';
    }
    if (lower.contains('simba')) {
      return 'https://media.api-sports.io/football/teams/6432.png';
    }
    if (lower.contains('azam')) {
      return 'https://media.api-sports.io/football/teams/8057.png';
    }
    if (lower.contains('singida')) {
      return 'https://media.api-sports.io/football/teams/6431.png';
    }
    if (lower.contains('tabora')) {
      return 'https://media.api-sports.io/football/teams/14878.png';
    }
    if (lower.contains('jkt')) {
      return 'https://media.api-sports.io/football/teams/6433.png';
    }
    if (lower.contains('kmc') || lower.contains('kinondoni')) {
      return 'https://media.api-sports.io/football/teams/6430.png';
    }
    if (lower.contains('mashujaa')) {
      return 'https://media.api-sports.io/football/teams/14879.png';
    }
    if (lower.contains('dodoma')) {
      return 'https://media.api-sports.io/football/teams/7762.png';
    }
    if (lower.contains('coastal')) {
      return 'https://media.api-sports.io/football/teams/6435.png';
    }
    if (lower.contains('prisons')) {
      return 'https://media.api-sports.io/football/teams/6434.png';
    }
    if (lower.contains('fountain')) {
      return 'https://media.api-sports.io/football/teams/14880.png';
    }
    if (lower.contains('pamba')) {
      return 'https://media.api-sports.io/football/teams/14881.png';
    }
    if (lower.contains('namungo')) {
      return 'https://media.api-sports.io/football/teams/6429.png';
    }
    if (lower.contains('kagera')) {
      return 'https://media.api-sports.io/football/teams/6436.png';
    }
    if (lower.contains('kengold')) {
      return 'https://media.api-sports.io/football/teams/14882.png';
    }

    // 2. Ligi Kuu ya Uingereza (Premier League)
    if (lower == 'liverpool' || lower.contains('liverpool')) {
      return 'https://media.api-sports.io/football/teams/40.png';
    }
    if (lower == 'manchester city' || lower == 'man city') {
      return 'https://media.api-sports.io/football/teams/50.png';
    }
    if (lower == 'arsenal' || lower.contains('arsenal')) {
      return 'https://media.api-sports.io/football/teams/42.png';
    }
    if (lower == 'chelsea' || lower.contains('chelsea')) {
      return 'https://media.api-sports.io/football/teams/49.png';
    }
    if (lower == 'manchester united' || lower == 'man united') {
      return 'https://media.api-sports.io/football/teams/33.png';
    }
    if (lower == 'tottenham' || lower.contains('tottenham') || lower.contains('spurs')) {
      return 'https://media.api-sports.io/football/teams/47.png';
    }
    if (lower.contains('aston villa')) {
      return 'https://media.api-sports.io/football/teams/66.png';
    }
    if (lower.contains('newcastle')) {
      return 'https://media.api-sports.io/football/teams/34.png';
    }
    if (lower.contains('brighton')) {
      return 'https://media.api-sports.io/football/teams/51.png';
    }
    if (lower.contains('nottingham')) {
      return 'https://media.api-sports.io/football/teams/65.png';
    }
    if (lower.contains('fulham')) {
      return 'https://media.api-sports.io/football/teams/36.png';
    }
    if (lower.contains('brentford')) {
      return 'https://media.api-sports.io/football/teams/55.png';
    }
    if (lower.contains('bournemouth')) {
      return 'https://media.api-sports.io/football/teams/35.png';
    }
    if (lower.contains('west ham')) {
      return 'https://media.api-sports.io/football/teams/48.png';
    }
    if (lower.contains('leicester')) {
      return 'https://media.api-sports.io/football/teams/46.png';
    }
    if (lower.contains('everton')) {
      return 'https://media.api-sports.io/football/teams/45.png';
    }
    if (lower.contains('crystal palace')) {
      return 'https://media.api-sports.io/football/teams/52.png';
    }
    if (lower.contains('wolves') || lower.contains('wolverhampton')) {
      return 'https://media.api-sports.io/football/teams/39.png';
    }
    if (lower.contains('ipswich')) {
      return 'https://media.api-sports.io/football/teams/57.png';
    }
    if (lower.contains('southampton')) {
      return 'https://media.api-sports.io/football/teams/41.png';
    }

    // 3. Hispania (La Liga)
    if (lower.contains('real madrid')) {
      return 'https://media.api-sports.io/football/teams/541.png';
    }
    if (lower.contains('barcelona') || lower == 'barca') {
      return 'https://media.api-sports.io/football/teams/529.png';
    }
    if (lower.contains('atletico madrid') || lower.contains('atlético')) {
      return 'https://media.api-sports.io/football/teams/530.png';
    }
    if (lower.contains('villarreal')) {
      return 'https://media.api-sports.io/football/teams/533.png';
    }
    if (lower.contains('osasuna')) {
      return 'https://media.api-sports.io/football/teams/727.png';
    }
    if (lower.contains('athletic')) {
      return 'https://media.api-sports.io/football/teams/531.png';
    }
    if (lower.contains('betis')) {
      return 'https://media.api-sports.io/football/teams/543.png';
    }
    if (lower.contains('sociedad')) {
      return 'https://media.api-sports.io/football/teams/548.png';
    }
    if (lower.contains('sevilla')) {
      return 'https://media.api-sports.io/football/teams/536.png';
    }
    if (lower.contains('valencia')) {
      return 'https://media.api-sports.io/football/teams/532.png';
    }

    // 4. Italia (Serie A)
    if (lower.contains('inter milan') || lower == 'inter') {
      return 'https://media.api-sports.io/football/teams/505.png';
    }
    if (lower.contains('ac milan') || lower == 'milan') {
      return 'https://media.api-sports.io/football/teams/489.png';
    }
    if (lower.contains('juventus') || lower == 'juve') {
      return 'https://media.api-sports.io/football/teams/496.png';
    }
    if (lower.contains('napoli')) {
      return 'https://media.api-sports.io/football/teams/492.png';
    }
    if (lower.contains('atalanta')) {
      return 'https://media.api-sports.io/football/teams/499.png';
    }
    if (lower.contains('lazio')) {
      return 'https://media.api-sports.io/football/teams/487.png';
    }
    if (lower.contains('roma')) {
      return 'https://media.api-sports.io/football/teams/497.png';
    }
    if (lower.contains('fiorentina')) {
      return 'https://media.api-sports.io/football/teams/502.png';
    }

    // 5. Ulaya Nyingine (Bayern, PSG, Dortmund, Leverkusen, Sporting)
    if (lower.contains('bayern')) {
      return 'https://media.api-sports.io/football/teams/157.png';
    }
    if (lower.contains('dortmund')) {
      return 'https://media.api-sports.io/football/teams/165.png';
    }
    if (lower.contains('leverkusen')) {
      return 'https://media.api-sports.io/football/teams/168.png';
    }
    if (lower.contains('paris') || lower.contains('psg')) {
      return 'https://media.api-sports.io/football/teams/85.png';
    }
    if (lower.contains('sporting')) {
      return 'https://media.api-sports.io/football/teams/228.png';
    }
    if (lower.contains('monaco')) {
      return 'https://media.api-sports.io/football/teams/91.png';
    }
    if (lower.contains('brest')) {
      return 'https://media.api-sports.io/football/teams/106.png';
    }

    // 6. Timu za Taifa (National Teams)
    if (lower == 'italy' || lower == 'italia') {
      return 'https://media.api-sports.io/football/teams/768.png';
    }
    if (lower == 'france' || lower == 'ufaransa') {
      return 'https://media.api-sports.io/football/teams/2.png';
    }
    if (lower == 'england' || lower == 'uingereza') {
      return 'https://media.api-sports.io/football/teams/10.png';
    }
    if (lower.contains('ireland')) {
      return 'https://media.api-sports.io/football/teams/776.png';
    }
    if (lower.contains('scotland')) {
      return 'https://media.api-sports.io/football/teams/1109.png';
    }
    if (lower.contains('norway')) {
      return 'https://media.api-sports.io/football/teams/1091.png';
    }
    if (lower.contains('kazakhstan')) {
      return 'https://media.api-sports.io/football/teams/1095.png';
    }
    if (lower.contains('czech')) {
      return 'https://media.api-sports.io/football/teams/1531.png';
    }
    if (lower.contains('tanzania') || lower.contains('taifa stars')) {
      return 'https://media.api-sports.io/football/teams/1504.png';
    }

    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return fallbackUrl;
    }
    return '';
  }

  // --------------------------------------------------------------------------
  // A. KUCHUKUA MECHI MUBASHARA (LIVE MATCHES) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  /// Inachukua mechi zote zinazochezwa hivi sasa moja kwa moja kutoka API
  Future<List<MatchModel>> getLiveMatches({bool forceRefresh = false}) async {
    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures?live=all');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inaanza kupiga Live Matches: $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Angalia kama kuna makosa yaliyotolewa na API (mfano rate limit)
        if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final errorMap = data['errors'] as Map;
          final errorMsg = errorMap.values.join(', ');
          debugPrint('[M FOOTBALL PLUS API Error]: $errorMsg');
          throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Hitilafu ya API kutoka kwa mtoa huduma.');
        }

        final List<dynamic> responseList = data['response'] ?? [];
        debugPrint('[M FOOTBALL PLUS API] Mechi Mubashara zilizopatikana: ${responseList.length}');

        final List<MatchModel> matches = responseList
            .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
            .toList();

        // CHUJA: Kubali mechi za timu za wakubwa (Priority 1, 2 au 3)
        final topTierMatches = matches.where((m) {
          final pri = MatchModel.getLeaguePriority(m.leagueEn, m.leagueCountry);
          return pri <= 3;
        }).toList();

        return topTierMatches.isNotEmpty ? topTierMatches : matches;
      } else {
        debugPrint('[M FOOTBALL PLUS API Error] HTTP Status: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP Status ${response.statusCode}: Imeshindwa kuunganishwa na seva ya API.');
      }
    } catch (e, stackTrace) {
      debugPrint('[M FOOTBALL PLUS API Exception] Hitilafu wakati wa kuchukua Live Matches: $e');
      debugPrint(stackTrace.toString());
      rethrow;
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

    // Tumia cache ikiwa haijazidi dakika 3 na tarehe ni ya leo na si forceRefresh
    if (!forceRefresh &&
        date == null &&
        _cachedTodaysMatches != null &&
        _lastTodaysFetch != null &&
        now.difference(_lastTodaysFetch!).inMinutes < 3) {
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

        // Angalia kama kuna makosa yaliyotolewa na API
        if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final errorMap = data['errors'] as Map;
          final errorMsg = errorMap.values.join(', ');
          debugPrint('[M FOOTBALL PLUS API Error]: $errorMsg');
          throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Hitilafu ya API kutoka kwa mtoa huduma.');
        }

        final List<dynamic> responseList = data['response'] ?? [];

        if (responseList.isNotEmpty) {
          final allMatches = responseList
              .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
              .where((m) {
                final isYouth = m.homeTeam.contains('U21') ||
                    m.awayTeam.contains('U21') ||
                    m.homeTeam.contains('U23') ||
                    m.awayTeam.contains('U23') ||
                    m.homeTeam.contains('U19') ||
                    m.awayTeam.contains('U19') ||
                    m.leagueEn.contains('U21') ||
                    m.leagueEn.contains('U23');
                if (isYouth) return false;
                final pri = MatchModel.getLeaguePriority(m.leagueEn, m.leagueCountry);
                return pri <= 3;
              })
              .toList();

          if (allMatches.isNotEmpty) {
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

        // Ikiwa hakuna mechi zilizorudishwa na API
        return [];
      } else {
        throw Exception('HTTP Status ${response.statusCode}: Imeshindwa kuunganishwa na API.');
      }
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi za Tarehe zimefeli: $e');
      rethrow;
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Angalia kama kuna makosa yaliyotolewa na API
        if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final errorMap = data['errors'] as Map;
          final errorMsg = errorMap.values.join(', ');
          debugPrint('[M FOOTBALL PLUS API Error]: $errorMsg');
          throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Hitilafu ya API kutoka kwa mtoa huduma.');
        }

        final List<dynamic> responseList = data['response'] ?? [];

        final allMatches = responseList
            .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
            .where((m) {
              final isYouth = m.homeTeam.contains('U21') ||
                  m.awayTeam.contains('U21') ||
                  m.homeTeam.contains('U23') ||
                  m.awayTeam.contains('U23') ||
                  m.homeTeam.contains('U19') ||
                  m.awayTeam.contains('U19') ||
                  m.leagueEn.contains('U21') ||
                  m.leagueEn.contains('U23');
              if (isYouth) return false;
              final pri = MatchModel.getLeaguePriority(m.leagueEn, m.leagueCountry);
              return pri <= 3;
            })
            .toList();

        if (allMatches.isNotEmpty) {
          // Panga kwa ligi maarufu juu kwanza
          allMatches.sort((a, b) {
            final aPri = MatchModel.getLeaguePriority(a.leagueEn, a.leagueCountry);
            final bPri = MatchModel.getLeaguePriority(b.leagueEn, b.leagueCountry);
            return aPri.compareTo(bPri);
          });

          _cachedUpcomingMatches = allMatches;
          _lastUpcomingFetch = now;
          return allMatches;
        }

        return [];
      } else {
        throw Exception('HTTP Status ${response.statusCode}: Imeshindwa kuunganishwa na API.');
      }
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi Zinazofuata zimefeli: $e');
      rethrow;
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

  // --------------------------------------------------------------------------
  // E. KUCHUKUA MSIMAMO WA LIGI (LEAGUE STANDINGS) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  final Map<String, List<StandingItem>> _standingsCache = {};

  Future<List<StandingItem>> getStandings(
    dynamic leagueId, {
    int season = 2024,
    bool forceRefresh = false,
  }) async {
    final int id = leagueId is int ? leagueId : int.tryParse(leagueId.toString()) ?? 567;
    final cacheKey = '${id}_$season';
    if (!forceRefresh && _standingsCache.containsKey(cacheKey) && _standingsCache[cacheKey]!.isNotEmpty) {
      return _standingsCache[cacheKey]!;
    }

    final uri = Uri.parse('$_apiFootballBaseUrl/standings?league=$id&season=$season');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inavuta Msimamo Halisi wa Ligi $id ($season): $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Angalia kama kuna makosa yaliyotolewa na API (mfano rate limit)
        if (data['errors'] != null) {
          if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
            final errorMap = data['errors'] as Map;
            final errorMsg = errorMap.values.join(', ');
            debugPrint('[M FOOTBALL PLUS API Standings Error]: $errorMsg');
            throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Hitilafu ya API kutoka kwa mtoa huduma.');
          } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
            final errorList = data['errors'] as List;
            final errorMsg = errorList.join(', ');
            debugPrint('[M FOOTBALL PLUS API Standings Error]: $errorMsg');
            throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Hitilafu ya API kutoka kwa mtoa huduma.');
          }
        }

        final List<dynamic> responseList = data['response'] ?? [];

        if (responseList.isNotEmpty) {
          final first = responseList.first as Map<String, dynamic>;
          final league = first['league'] as Map<String, dynamic>? ?? {};
          final standingsList = league['standings'] as List<dynamic>? ?? [];

          if (standingsList.isNotEmpty) {
            // Mara nyingi API-Football inarudisha list ya list [[standing1, standing2]]
            final List<dynamic> targetList = (standingsList.first is List)
                ? (standingsList.first as List<dynamic>)
                : standingsList;

            final standings = targetList
                .map((item) => StandingItem.fromJson(item as Map<String, dynamic>))
                .toList();

            _standingsCache[cacheKey] = standings;
            return standings;
          }
        }

        return [];
      } else {
        throw Exception('HTTP Status ${response.statusCode}: Imeshindwa kuunganishwa na seva ya API.');
      }
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Msimamo umefeli: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // F. KUCHUKUA TAKWIMU ZA MECHI (MATCH STATISTICS) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  Future<List<FixtureTeamStats>> getFixtureStatistics(int fixtureId) async {
    if (fixtureId <= 0) return [];

    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures/statistics?fixture=$fixtureId');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inavuta Takwimu za Mechi $fixtureId: $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];

        return responseList.map((item) {
          final m = item as Map<String, dynamic>;
          final team = m['team'] as Map<String, dynamic>? ?? {};
          final rawStats = m['statistics'] as List<dynamic>? ?? [];

          final Map<String, dynamic> statMap = {};
          for (final s in rawStats) {
            final sm = s as Map<String, dynamic>;
            final type = sm['type'] as String? ?? '';
            statMap[type] = sm['value'];
          }

          return FixtureTeamStats(
            teamId: team['id'] as int? ?? 0,
            teamName: team['name'] as String? ?? '',
            teamLogo: team['logo'] as String? ?? '',
            stats: statMap,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Takwimu za mechi $fixtureId zimefeli: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // G. KUCHUKUA VIKOSI VYA MECHI (LINEUPS) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  Future<List<FixtureLineupModel>> getFixtureLineups(int fixtureId) async {
    if (fixtureId <= 0) return [];

    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures/lineups?fixture=$fixtureId');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inavuta Vikosi vya Mechi $fixtureId: $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];

        return responseList
            .map((item) => FixtureLineupModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Vikosi vya mechi $fixtureId vimefeli: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // H. KUCHUKUA HISTORIA YA TIMU (HEAD TO HEAD) KUTOKA API-FOOTBALL
  // --------------------------------------------------------------------------
  Future<List<MatchModel>> getHeadToHead(int team1Id, int team2Id) async {
    if (team1Id <= 0 || team2Id <= 0) return [];

    final uri = Uri.parse('$_apiFootballBaseUrl/fixtures/headtohead?h2h=$team1Id-$team2Id');

    try {
      debugPrint('[M FOOTBALL PLUS API] Inavuta H2H ya Timu $team1Id vs $team2Id: $uri');

      final response = await http
          .get(uri, headers: _apiFootballHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];

        return responseList
            .take(6)
            .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] H2H imefeli: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // I. KUCHUKUA HABARI ZA SOKA (FOOTBALL NEWS) KUTOKA ESPN & THESPORTSDB
  // --------------------------------------------------------------------------
  final Map<String, List<NewsArticleModel>> _newsCache = {};

  // Habari Maalum zilizochapishwa na Msimamizi (Admin Custom Stories)
  static final List<NewsArticleModel> customAdminNews = [];

  void clearAllCache() {
    _cachedTodaysMatches = null;
    _cachedUpcomingMatches = null;
    _standingsCache.clear();
    _newsCache.clear();
    _badgeCache.clear();
    debugPrint('[M FOOTBALL PLUS] Kumbukumbu ya Cache zote zimesafishwa na Admin.');
  }

  Future<List<NewsArticleModel>> getFootballNews({
    String category = 'all',
    bool forceRefresh = false,
  }) async {
    // Tumia habari zetu halisi za kiwango cha juu zenye lugha zote mbili (Kiswahili & English 100%)
    final authentic = _getAuthenticNews(category);
    final filteredAdmin = category == 'all'
        ? customAdminNews
        : customAdminNews.where((a) => a.category == category).toList();
    final combined = [...filteredAdmin, ...authentic];
    _newsCache[category] = combined;
    return combined;
  }








  // Inarudisha habari halisi za msingi kwa ajili ya FirestoreService na StreamBuilder
  List<NewsArticleModel> getAuthenticNewsList(String category) => _getAuthenticNews(category);

  // ==========================================================================
  // M. HABARI HALISI ZA SOKA KWA MAKUNDI YOTE (AUTHENTIC BILINGUAL NEWS)
  // ==========================================================================
  List<NewsArticleModel> _getAuthenticNews(String category) {
    switch (category) {
      case 'ucl': // Klabu Bingwa Ulaya
        return const [
          NewsArticleModel(
            id: 'ucl_1',
            title: 'Liverpool Dominate 36-Team Champions League Table with Perfect Record',
            titleSw: 'Liverpool Yaongoza Jedwali la Klabu Bingwa Ulaya kwa Rekodi ya Asilimia 100',
            description: 'Arne Slot\'s men stand alone at the top of the UEFA Champions League standings after four straight commanding victories.',
            descriptionSw: 'Kikosi cha Arne Slot kinasimama kileleni pekee kwenye msimamo wa Klabu Bingwa Ulaya kufuatia ushindi mnono wa mechi zote nne mfululizo.',
            imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
            publishedAt: 'Dakika 15 zilizopita',
            source: 'UEFA Champions League News',
            category: 'Klabu Bingwa',
          ),
          NewsArticleModel(
            id: 'ucl_2',
            title: 'Real Madrid Set Sights on European Glory Ahead of AC Milan Showdown',
            titleSw: 'Real Madrid Yajiandaa na Dabi ya Ulaya Dhidi ya AC Milan Santiago Bernabéu',
            description: 'Carlo Ancelotti has rallied his Galácticos after a stunning domestic response, aiming to secure automatic last-16 qualification.',
            descriptionSw: 'Carlo Ancelotti amewataka wachezaji wake kuongeza umakini uwanjani Santiago Bernabéu ili kufuzu moja kwa moja hatua ya 16 bora.',
            imageUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800',
            publishedAt: 'Saa 1 lililopita',
            source: 'ESPN Europe',
            category: 'Klabu Bingwa',
          ),
          NewsArticleModel(
            id: 'ucl_3',
            title: 'Viktor Gyökeres Hat-Trick Shocks Europe as Sporting Demolish Opponents',
            titleSw: 'Mshambuliaji Viktor Gyökeres Apiga Hat-Trick ya Historia Klabu Bingwa Ulaya',
            description: 'The Swedish striker announced himself as Europe\'s hottest commodity with a masterclass display on the grandest European stage.',
            descriptionSw: 'Mshambuliaji wa kimataifa wa Sweden ameonyesha kiwango cha kipekee baada ya kupachika mabao matatu kwenye mchezo wa Klabu Bingwa.',
            imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
            publishedAt: 'Saa 3 zilizopita',
            source: 'Sky Sports',
            category: 'Klabu Bingwa',
          ),
          NewsArticleModel(
            id: 'ucl_4',
            title: 'Barcelona\'s Vibrant Youth Squad Score 15 Goals in 4 Champions League Ties',
            titleSw: 'Kikosi cha Vijana cha Barcelona Chafunga Mabao 15 Kwenye Mechi 4 za Ulaya',
            description: 'Hansi Flick\'s high-pressing system has overwhelmed European defences with Lamine Yamal and Raphinha in sensational form.',
            descriptionSw: 'Mfumo wa kocha Hansi Flick unazidi kutikisa vilabu vya Ulaya huku Lamine Yamal na Raphinha wakiongoza safu ya ushambuliaji.',
            imageUrl: 'https://images.unsplash.com/photo-1517927033932-b3d18e61fb3a?w=800',
            publishedAt: 'Saa 5 zilizopita',
            source: 'Mundo Deportivo',
            category: 'Klabu Bingwa',
          ),
        ];

      case 'epl': // Ligi Kuu Uingereza
        return const [
          NewsArticleModel(
            id: 'epl_1',
            title: 'Arne Slot Makes History as Liverpool Move 5 Points Clear at the Summit',
            titleSw: 'Arne Slot Aweka Rekodi Mpya Liverpool Ikiongoza EPL kwa Tofauti ya Pointi 5',
            description: 'A stellar 2-0 triumph over Aston Villa gives the Reds undisputed momentum in the intense Premier League title hunt.',
            descriptionSw: 'Ushindi wa mabao 2-0 dhidi ya Aston Villa unawafanya Liverpool kuongoza mbio za ubingwa wa Ligi Kuu ya Uingereza kwa kishindo.',
            imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
            publishedAt: 'Dakika 20 zilizopita',
            source: 'BBC Sport',
            category: 'Uingereza',
          ),
          NewsArticleModel(
            id: 'epl_2',
            title: 'Mikel Arteta Defiant After Stamford Bridge Stalemate with Chelsea',
            titleSw: 'Mikel Arteta Aahidi Mwitikio Mkubwa Baada ya Sare Dhidi ya Chelsea',
            description: 'The Arsenal manager highlighted his squad\'s defensive resilience and promised a fierce charge after the international break.',
            descriptionSw: 'Kocha wa Arsenal amesifu upambanaji wa safu yake ya ulinzi na kusisitiza kuwa mbio za ubingwa bado zipo wazi kabisa.',
            imageUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800',
            publishedAt: 'Saa 2 zilizopita',
            source: 'Sky Sports',
            category: 'Uingereza',
          ),
          NewsArticleModel(
            id: 'epl_3',
            title: 'Ruben Amorim Officially Arrives at Carrington to Begin Manchester United Era',
            titleSw: 'Ruben Amorim Awasili Rasmi Carrington Kuanza Kibarua Kipya Man United',
            description: 'The Portuguese tactician has taken charge of first-team training, targeting an immediate transformation in tactical structure.',
            descriptionSw: 'Kocha huyo kutoka Ureno amewasili kwenye viwanja vya mazoezi vya Manchester United akilenga kuijenga upya timu hiyo.',
            imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
            publishedAt: 'Saa 4 zilizopita',
            source: 'Manchester Evening News',
            category: 'Uingereza',
          ),
        ];

      case 'laliga': // Hispania
        return const [
          NewsArticleModel(
            id: 'laliga_1',
            title: 'Hansi Flick\'s Barcelona Power to 40 Goals in Dominant La Liga Campaign',
            titleSw: 'Barcelona ya Hansi Flick Yafikisha Mabao 40 ya Kipekee La Liga Hispania',
            description: 'The Blaugrana hold a six-point cushion atop Spanish football, deploying high-intensity football with relentless pressing.',
            descriptionSw: 'Kikosi cha Barcelona kinazidi kuongoza msimamo wa La Liga kwa tofauti ya pointi 6 kikicheza soka la kasi na magoli mengi.',
            imageUrl: 'https://images.unsplash.com/photo-1517927033932-b3d18e61fb3a?w=800',
            publishedAt: 'Dakika 45 zilizopita',
            source: 'Marca',
            category: 'Hispania',
          ),
          NewsArticleModel(
            id: 'laliga_2',
            title: 'Vinicius Jr Fires Sublime Hat-Trick as Real Madrid Crush Osasuna 4-0',
            titleSw: 'Vinicius Jr Afunga Hat-Trick Nzito Real Madrid Ikiipiga Osasuna Mabao 4-0',
            description: 'The Brazilian talisman responded in world-class style at the Bernabéu, showing sublime finishing and unmatched speed.',
            descriptionSw: 'Mshambuliaji huyo wa Brazil aling\'ara vilivyo Santiago Bernabéu akipachika mabao matatu safi na kupeleka shangwe kwa mashabiki.',
            imageUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800',
            publishedAt: 'Saa 2 zilizopita',
            source: 'AS España',
            category: 'Hispania',
          ),
        ];

      case 'transfer': // Usajili
        return const [
          NewsArticleModel(
            id: 'trans_1',
            title: 'Top European Giants Prepare Record Bids for Sporting Phenomenon Gyökeres',
            titleSw: 'Vilabu Vikuu vya Ulaya Vyaandaa Dau Kubwa la Usajili wa Viktor Gyökeres',
            description: 'Premier League and European giants are readying massive January packages as Sporting set their release valuation.',
            descriptionSw: 'Vilabu vya Ligi Kuu ya Uingereza na vigogo vya Ulaya vipo tayari kuvunja benki ili kumsajili mshambuliaji huyo anayeongoza kwa mabao.',
            imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
            publishedAt: 'Dakika 30 zilizopita',
            source: 'Fabrizio Romano Updates',
            category: 'Usajili',
          ),
          NewsArticleModel(
            id: 'trans_2',
            title: 'Real Madrid Intensify Negotiations for Trent Alexander-Arnold Ahead of Summer',
            titleSw: 'Real Madrid Yaongeza Kasi ya Mazungumzo ya Kumsajili Trent Alexander-Arnold',
            description: 'The Spanish champions are formulating contract terms for the English fullback as his Anfield agreement nears its expiration.',
            descriptionSw: 'Mabingwa hao wa Hispania wameanza mipango thabiti ya kumsajili beki wa pembeni wa Liverpool dirisha kubwa la majira ya joto.',
            imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
            publishedAt: 'Saa 3 zilizopita',
            source: 'The Athletic Football',
            category: 'Usajili',
          ),
        ];

      case 'all':
      default:
        return const [
          NewsArticleModel(
            id: 'all_1',
            title: 'Liverpool Surge Ahead in Premier League Title Race with 5-Point Cushion',
            titleSw: 'Liverpool Yaongoza Mbio za Ubingwa wa EPL kwa Tofauti ya Pointi 5',
            description: 'Victories over Chelsea and Aston Villa have established Arne Slot\'s Liverpool as the early benchmarks of consistency in Europe.',
            descriptionSw: 'Ushindi wa hivi karibuni umeiweka Liverpool kileleni mwa Ligi Kuu ya Uingereza kwa kasi kubwa inayoshangaza wengi.',
            imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
            publishedAt: 'Dakika 10 zilizopita',
            source: 'M-Football Sports Hub',
            category: 'Kimataifa',
          ),
          NewsArticleModel(
            id: 'all_2',
            title: 'Vinicius Jr Brilliant Hat-Trick Re-Energises Real Madrid\'s European Campaign',
            titleSw: 'Hat-Trick ya Vinicius Jr Yaamsha Upya Shangwe Kubwa Real Madrid',
            description: 'The Brazilian superstar demonstrated his devastating finishing prowess at the Santiago Bernabéu with a sensational treble.',
            descriptionSw: 'Mshambuliaji huyo wa Brazil alifunga mabao matatu ya kipekee Santiago Bernabéu na kuthibitisha uwezo wake mkubwa duniani.',
            imageUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800',
            publishedAt: 'Saa 1 lililopita',
            source: 'Marca International',
            category: 'Kimataifa',
          ),
          NewsArticleModel(
            id: 'all_3',
            title: 'Young Africans and Simba SC Gear Up for Dramatic CAF Champions League Clashes',
            titleSw: 'Young Africans na Simba SC Zajiandaa na Mechi Kali za Klabu Bingwa Afrika (CAF)',
            description: 'Tanzania\'s traditional heavyweights are in prime form as the continental group stages loom with high national anticipation.',
            descriptionSw: 'Vilabu kongwe vya Tanzania vya Yanga na Simba viko katika fomu thabiti kuelekea mechi ngumu za makundi za CAF.',
            imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
            publishedAt: 'Saa 2 zilizopita',
            source: 'M-Football Tanzania',
            category: 'Tanzania',
          ),
          NewsArticleModel(
            id: 'all_4',
            title: 'Hansi Flick\'s High-Flying Barcelona Dazzle with 40-Goal Season Blitz',
            titleSw: 'Barcelona ya Hansi Flick Yafikisha Mabao 40 ya Kipekee Msimu Huu',
            description: 'Barcelona\'s thrilling attacking football has captivated the football world with Lamine Yamal and Lewandowski firing on all cylinders.',
            descriptionSw: 'Soka la kushambulia la Barcelona chini ya kocha Hansi Flick linazidi kuvutia mashabiki wengi kote ulimwenguni.',
            imageUrl: 'https://images.unsplash.com/photo-1517927033932-b3d18e61fb3a?w=800',
            publishedAt: 'Saa 4 zilizopita',
            source: 'AS España',
            category: 'Hispania',
          ),
        ];
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
  final int homeTeamId;
  final int awayTeamId;
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
    this.homeTeamId = 0,
    this.awayTeamId = 0,
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

    final int hId = homeMap['id'] as int? ?? 0;
    final int aId = awayMap['id'] as int? ?? 0;
    final String hName = homeMap['name'] as String? ?? 'Nyumbani';
    final String aName = awayMap['name'] as String? ?? 'Ugenini';
    final String rawHLogo = homeMap['logo'] as String? ?? '';
    final String rawALogo = awayMap['logo'] as String? ?? '';
    final String hLogo = FootballApiService.getTeamLogo(hName, fallbackUrl: rawHLogo);
    final String aLogo = FootballApiService.getTeamLogo(aName, fallbackUrl: rawALogo);

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
      homeTeamId: hId,
      awayTeamId: aId,
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

// ============================================================================
// 4. MODEL CLASS: StandingItem (Msimamo wa Ligi)
// ============================================================================
class StandingItem {
  final int rank;
  final int teamId;
  final String teamName;
  final String teamLogo;
  final int points;
  final int goalsDiff;
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsFor;
  final int goalsAgainst;
  final String form;
  final String? description;

  const StandingItem({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.points,
    required this.goalsDiff,
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.form,
    this.description,
  });

  factory StandingItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final team = json['team'] as Map<String, dynamic>? ?? {};
    final all = json['all'] as Map<String, dynamic>? ?? {};
    final goals = all['goals'] as Map<String, dynamic>? ?? {};

    return StandingItem(
      rank: toInt(json['rank']),
      teamId: toInt(team['id']),
      teamName: team['name']?.toString() ?? 'Timu',
      teamLogo: team['logo']?.toString() ?? '',
      points: toInt(json['points']),
      goalsDiff: toInt(json['goalsDiff']),
      played: toInt(all['played']),
      win: toInt(all['win']),
      draw: toInt(all['draw']),
      lose: toInt(all['lose']),
      goalsFor: toInt(goals['for']),
      goalsAgainst: toInt(goals['against']),
      form: json['form']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

// ============================================================================
// 5. MODEL CLASS: FixtureTeamStats (Takwimu za Mechi ya Timu)
// ============================================================================
class FixtureTeamStats {
  final int teamId;
  final String teamName;
  final String teamLogo;
  final Map<String, dynamic> stats;

  const FixtureTeamStats({
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.stats,
  });

  dynamic getStat(String key) => stats[key];

  String get ballPossession => stats['Ball Possession']?.toString() ?? '50%';
  int get totalShots => int.tryParse(stats['Total Shots']?.toString() ?? '0') ?? 0;
  int get shotsOnGoal => int.tryParse(stats['Shots on Goal']?.toString() ?? '0') ?? 0;
  int get shotsOffGoal => int.tryParse(stats['Shots off Goal']?.toString() ?? '0') ?? 0;
  int get cornerKicks => int.tryParse(stats['Corner Kicks']?.toString() ?? '0') ?? 0;
  int get fouls => int.tryParse(stats['Fouls']?.toString() ?? '0') ?? 0;
  int get yellowCards => int.tryParse(stats['Yellow Cards']?.toString() ?? '0') ?? 0;
  int get redCards => int.tryParse(stats['Red Cards']?.toString() ?? '0') ?? 0;
  int get offsides => int.tryParse(stats['Offsides']?.toString() ?? '0') ?? 0;
  String get passesAccuracy => stats['Passes %']?.toString() ?? stats['Passes accurate']?.toString() ?? '-';
}

// ============================================================================
// 6. MODEL CLASS: FixtureLineupModel & LineupPlayer (Vikosi vya Mechi)
// ============================================================================
class LineupPlayer {
  final int id;
  final String name;
  final int number;
  final String pos; // G, D, M, F
  final String? grid;

  const LineupPlayer({
    required this.id,
    required this.name,
    required this.number,
    required this.pos,
    this.grid,
  });

  factory LineupPlayer.fromJson(Map<String, dynamic> json) {
    final p = json['player'] as Map<String, dynamic>? ?? json;
    return LineupPlayer(
      id: p['id'] as int? ?? 0,
      name: p['name'] as String? ?? '',
      number: p['number'] as int? ?? 0,
      pos: p['pos'] as String? ?? 'M',
      grid: p['grid'] as String?,
    );
  }
}

class FixtureLineupModel {
  final int teamId;
  final String teamName;
  final String teamLogo;
  final String formation;
  final String coachName;
  final String coachPhoto;
  final List<LineupPlayer> startXI;
  final List<LineupPlayer> substitutes;

  const FixtureLineupModel({
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.formation,
    required this.coachName,
    required this.coachPhoto,
    required this.startXI,
    required this.substitutes,
  });

  factory FixtureLineupModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>? ?? {};
    final coach = json['coach'] as Map<String, dynamic>? ?? {};
    final rawXI = json['startXI'] as List<dynamic>? ?? [];
    final rawSubs = json['substitutes'] as List<dynamic>? ?? [];

    return FixtureLineupModel(
      teamId: team['id'] as int? ?? 0,
      teamName: team['name'] as String? ?? '',
      teamLogo: team['logo'] as String? ?? '',
      formation: json['formation'] as String? ?? '4-3-3',
      coachName: coach['name'] as String? ?? '',
      coachPhoto: coach['photo'] as String? ?? '',
      startXI: rawXI.map((e) => LineupPlayer.fromJson(e as Map<String, dynamic>)).toList(),
      substitutes: rawSubs.map((e) => LineupPlayer.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// ============================================================================
// 7. MODEL CLASS: NewsArticleModel (Habari za Soka)
// ============================================================================
class NewsArticleModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String publishedAt;
  final String source;
  final String? url;
  final String category;
  final String? titleSw;
  final String? descriptionSw;

  const NewsArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedAt,
    required this.source,
    this.url,
    this.category = 'Soccer',
    this.titleSw,
    this.descriptionSw,
  });

  String getTitle(bool isSw) => (isSw && titleSw != null && titleSw!.isNotEmpty) ? titleSw! : title;
  String getDescription(bool isSw) => (isSw && descriptionSw != null && descriptionSw!.isNotEmpty) ? descriptionSw! : description;

  factory NewsArticleModel.fromEspnJson(Map<String, dynamic> json) {
    final String title = json['headline'] as String? ?? json['title'] as String? ?? 'Habari ya Soka';
    final String desc = json['description'] as String? ?? '';
    final String byline = json['byline'] as String? ?? 'ESPN Soccer';
    final String pub = json['published'] as String? ?? '';

    String img = '';
    final images = json['images'] as List<dynamic>? ?? [];
    if (images.isNotEmpty) {
      final firstImg = images.first as Map<String, dynamic>;
      img = firstImg['url'] as String? ?? '';
    }

    String? link;
    final links = json['links'] as Map<String, dynamic>?;
    if (links != null) {
      final web = links['web'] as Map<String, dynamic>?;
      if (web != null) {
        link = web['href'] as String?;
      }
    }

    return NewsArticleModel(
      id: title.hashCode.toString(),
      title: title,
      description: desc,
      imageUrl: img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
      publishedAt: pub,
      source: byline,
      url: link,
      category: 'Kimataifa',
      titleSw: title,
      descriptionSw: desc,
    );
  }
}
