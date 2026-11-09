import 'dart:convert';
import 'package:flutter/foundation.dart';
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

        final allMatches = responseList
            .map((item) => MatchModel.fromApiFootballJson(item as Map<String, dynamic>))
            .toList();

        // Panga kwa kuweka ligi maarufu juu
        allMatches.sort((a, b) {
          final priorityLeagues = [
            'Premier League', 'Champions League', 'La Liga', 'Serie A',
            'Bundesliga', 'Ligue 1', 'CAF', 'NBC Premier League'
          ];
          final aPri = priorityLeagues.any((l) => a.leagueEn.contains(l)) ? 0 : 1;
          final bPri = priorityLeagues.any((l) => b.leagueEn.contains(l)) ? 0 : 1;
          return aPri.compareTo(bPri);
        });

        // Weka kwenye cache
        if (date == null) {
          _cachedTodaysMatches = allMatches;
          _lastTodaysFetch = now;
        }

        return allMatches;
      } else {
        debugPrint('[M FOOTBALL PLUS API Error] Mechi za Leo HTTP ${response.statusCode}: ${response.body}');
        return _cachedTodaysMatches ?? [];
      }
    } catch (e) {
      debugPrint('[M FOOTBALL PLUS API Exception] Mechi za Leo zimefeli: $e');
      return _cachedTodaysMatches ?? [];
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
    );
  }

  // --- Helpers za Tafsiri ya Kiswahili ---
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
        return 'Mwisho Baada ya Nyongeza';
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
      default:
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
      default:
        return long;
    }
  }

  static String _translateLeagueToSwahili(String name, String? country) {
    if (name.contains('Premier League') && country == 'England') {
      return 'Ligi Kuu ya Uingereza';
    } else if (name.contains('Champions League')) {
      return 'Klabu Bingwa Ulaya';
    } else if (name.contains('La Liga')) {
      return 'La Liga ya Hispania';
    } else if (name.contains('Serie A')) {
      return 'Serie A ya Italia';
    } else if (name.contains('Bundesliga')) {
      return 'Bundesliga ya Ujerumani';
    } else if (name.contains('Ligue 1')) {
      return 'Ligue 1 ya Ufaransa';
    } else if (name.contains('CAF Champions League')) {
      return 'Klabu Bingwa Afrika';
    } else if (name.contains('CAF Confederation')) {
      return 'Kombe la Shirikisho Afrika';
    } else if (name.contains('NBC Premier League')) {
      return 'Ligi Kuu ya NBC';
    }
    return name;
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
