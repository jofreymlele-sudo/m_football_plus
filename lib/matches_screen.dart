import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart' show MColors;

// ============================================================================
// UKURASA WA MECHI (MATCHES SCREEN - MECHI ZA LEO NA ZINAZOFUATA)
// ============================================================================
class LeagueGroup {
  final String leagueName;
  final String? country;
  final String logo;
  final List<MatchModel> matches;

  LeagueGroup({
    required this.leagueName,
    this.country,
    required this.logo,
    required this.matches,
  });
}

class MatchesScreen extends StatefulWidget {
  final bool isSwahili;
  final VoidCallback? onBackToHome;

  const MatchesScreen({
    super.key,
    required this.isSwahili,
    this.onBackToHome,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // 0 = Mechi za Leo (Today's Matches), 1 = Mechi Zinazofuata (Upcoming Matches)
  int _activeTab = 0;

  // Filter ya Hali: 0 = Zote, 1 = Mubashara, 2 = Zinazokuja, 3 = Zilizomalizika
  int _filterIndex = 0;

  // Filter ya Mashindano: 0 = Zote, 1 = NBC Ligi Kuu, 2 = UEFA / Kimataifa, 3 = Uingereza, 4 = Hispania, 5 = Italia
  int _competitionFilterIndex = 0;

  // Vikumbusho vya Mechi (Active Match Reminder IDs)
  final Set<String> _reminderMatchIds = {};

  // Tarehe iliyochaguliwa (Chaguo-msingi ni Leo)
  late DateTime _selectedDate;

  // Utafutaji wa haraka (Search query)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data za Mechi kutoka API
  List<MatchModel> _todaysMatches = [];
  List<MatchModel> _upcomingMatches = [];
  bool _isLoading = false;
  bool _isApiConnected = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadMatchesFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Ubadilishaji wa tarehe kuwa format ya API (YYYY-MM-DD)
  String _formatApiDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  // Kazi ya kupakia mechi za leo na zinazofuata kutoka API
  Future<void> _loadMatchesFromApi({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final dateStr = _formatApiDate(_selectedDate);

    try {
      // 1. Vuta Mechi za Tarehe Iliyochaguliwa kutoka API au Hifadhidata ya Ratiba
      final todayResults = await FootballApiService().getTodaysMatches(
        date: dateStr,
        forceRefresh: forceRefresh,
      );

      // 2. Vuta Mechi Zinazofuata Kesho na Wiki Nzima
      final upcomingResults = await FootballApiService().getUpcomingMatches(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _todaysMatches = todayResults;
        _upcomingMatches = upcomingResults;
        _isApiConnected = todayResults.isNotEmpty || upcomingResults.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  // Orodha inayotumika kulingana na tab iliyochaguliwa
  List<MatchModel> get _currentSourceList {
    return _activeTab == 0 ? _todaysMatches : _upcomingMatches;
  }

  // Mechi zilizochujwa kulingana na filter na search
  List<MatchModel> get _filteredMatches {
    final query = _searchQuery.trim().toLowerCase();
    return _currentSourceList.where((m) {
      // 1. Filter ya maandishi (Search)
      if (query.isNotEmpty) {
        final h = m.homeTeam.toLowerCase();
        final a = m.awayTeam.toLowerCase();
        final lEn = m.leagueEn.toLowerCase();
        final lSw = m.leagueSw.toLowerCase();
        if (!h.contains(query) && !a.contains(query) && !lEn.contains(query) && !lSw.contains(query)) {
          return false;
        }
      }

      // 2. Filter ya Hali (Status)
      if (_filterIndex == 1) {
        // Mubashara tu (Live)
        if (!m.isLive) return false;
      } else if (_filterIndex == 2) {
        // Zinazokuja tu (Not Started)
        final isUpcoming = !m.isLive &&
            (m.statusShort == 'NS' ||
                m.statusShort == 'TBD' ||
                (m.homeScore == 0 && m.awayScore == 0 && !m.statusShort.contains('FT')));
        if (!isUpcoming) return false;
      } else if (_filterIndex == 3) {
        // Zilizomalizika tu (Finished)
        final isFinished = m.statusShort == 'FT' ||
            m.statusShort == 'AET' ||
            m.statusShort == 'PEN' ||
            m.statusEn.toLowerCase().contains('full') ||
            m.statusSw.toLowerCase().contains('mwisho');
        if (!isFinished) return false;
      }

      // 3. Filter ya Mashindano (Competition Quick Filter)
      if (_competitionFilterIndex == 1) {
        // NBC Ligi Kuu ya Tanzania
        final isNbc = m.leagueEn.toLowerCase().contains('nbc') ||
            m.leagueEn.toLowerCase().contains('ligi kuu bara') ||
            m.leagueSw.toLowerCase().contains('nbc') ||
            m.leagueSw.toLowerCase().contains('tanzania') ||
            (m.leagueCountry != null && m.leagueCountry!.toLowerCase().contains('tanzania'));
        if (!isNbc) return false;
      } else if (_competitionFilterIndex == 2) {
        // UEFA & Kimataifa
        final isUefa = m.leagueEn.toLowerCase().contains('uefa') ||
            m.leagueEn.toLowerCase().contains('nations league') ||
            m.leagueEn.toLowerCase().contains('champions league') ||
            m.leagueEn.toLowerCase().contains('world cup') ||
            m.leagueEn.toLowerCase().contains('afcon') ||
            m.leagueCountry == 'World' ||
            m.leagueCountry == 'Europe';
        if (!isUefa) return false;
      } else if (_competitionFilterIndex == 3) {
        // Ligi Kuu Uingereza (Premier League)
        final isEpl = (m.leagueEn.toLowerCase().contains('premier league') ||
                m.leagueSw.toLowerCase().contains('uingereza')) &&
            (m.leagueCountry == null || m.leagueCountry == 'England' || m.leagueCountry == 'Uingereza');
        if (!isEpl) return false;
      } else if (_competitionFilterIndex == 4) {
        // La Liga Hispania
        final isLaLiga = m.leagueEn.toLowerCase().contains('la liga') ||
            m.leagueSw.toLowerCase().contains('hispania') ||
            m.leagueCountry == 'Spain' ||
            m.leagueCountry == 'Hispania';
        if (!isLaLiga) return false;
      } else if (_competitionFilterIndex == 5) {
        // Serie A Italia
        final isSerieA = m.leagueEn.toLowerCase().contains('serie a') ||
            m.leagueSw.toLowerCase().contains('italia') ||
            m.leagueCountry == 'Italy' ||
            m.leagueCountry == 'Italia';
        if (!isSerieA) return false;
      }

      return true;
    }).toList();
  }

  // Mechi zilizopangwa kwa makundi ya Ligi
  List<LeagueGroup> get _groupedMatches {
    final Map<String, LeagueGroup> map = {};

    for (final m in _filteredMatches) {
      final country = m.leagueCountry ?? '';
      final leagueSw = m.getLeague(widget.isSwahili);
      final key = "${leagueSw}__$country";

      if (!map.containsKey(key)) {
        map[key] = LeagueGroup(
          leagueName: leagueSw,
          country: m.leagueCountry,
          logo: m.leagueLogo,
          matches: [],
        );
      }
      map[key]!.matches.add(m);
    }

    return map.values.toList();
  }

  // Toggle Reminder kwa mechi moja
  void _toggleReminder(MatchModel match, bool isSw) {
    final matchId = match.id;
    final isCurrentlySet = _reminderMatchIds.contains(matchId);

    setState(() {
      if (isCurrentlySet) {
        _reminderMatchIds.remove(matchId);
      } else {
        _reminderMatchIds.add(matchId);
      }
    });

    final message = !isCurrentlySet
        ? (isSw
            ? '🔔 Kikumbusho kimewekwa kwa mechi ya ${match.homeTeam} vs ${match.awayTeam} (${match.matchTime})!'
            : '🔔 Reminder set for ${match.homeTeam} vs ${match.awayTeam} (${match.matchTime})!')
        : (isSw
            ? '🔕 Kikumbusho kimeondolewa.'
            : '🔕 Reminder removed.');

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              !isCurrentlySet ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
              color: !isCurrentlySet ? MColors.highlightsGold : MColors.scoresCyan,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MColors.textWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: MColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: !isCurrentlySet ? MColors.highlightsGold : MColors.scoresCyan.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Nakili na Shiriki Taarifa za Mechi (Share Match)
  void _shareMatchDetails(MatchModel match, bool isSw) {
    final text = '''⚽ M FOOTBALL PLUS
🏆 ${match.getLeague(isSw)}
🆚 ${match.homeTeam} vs ${match.awayTeam}
⏰ ${match.matchTime} (${match.getStatus(isSw)})
🏟️ ${match.venue.isNotEmpty ? match.venue : 'Uwanja wa Kimataifa'}
${match.keyPlayer != null ? '⭐ Mchezaji Muhimu: ${match.keyPlayer}\n' : ''}📊 Utabiri wa Ushindi: ${match.homeTeam} (${match.homeWinProb}%) | Sare (${match.drawProb}%) | ${match.awayTeam} (${match.awayWinProb}%)
Pakua M Football Plus kupata matokeo mubashara na takwimu zote!''';

    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: MColors.scoresCyan, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSw ? 'Taarifa za mechi zimenakiliwa tayari kushiriki!' : 'Match details copied to clipboard!',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: MColors.textWhite),
              ),
            ),
          ],
        ),
        backgroundColor: MColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: MColors.scoresCyan, width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = widget.isSwahili;

    return RefreshIndicator(
      color: MColors.scoresCyan,
      backgroundColor: MColors.surface,
      onRefresh: () => _loadMatchesFromApi(forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 1. KICHWA CHA HABARI JUU (TOP HEADER)
          SliverToBoxAdapter(
            child: _buildTopHeader(isSw),
          ),

          // 2. TAB YA KUCHAGUA: MECHI ZA LEO vs MECHI ZINAZOFUATA
          SliverToBoxAdapter(
            child: _buildMainTabSelector(isSw),
          ),

          // 3. MCHIRIZI WA TAREHE (DATE PICKER CAROUSEL 10 DAYS: NOV 8 - NOV 17)
          if (_activeTab == 0)
            SliverToBoxAdapter(
              child: _buildDateCarousel(isSw),
            ),

          // 4. SEHEMU YA UTAFUTAJI NA VICHUJIO (SEARCH & FILTER CHIPS)
          SliverToBoxAdapter(
            child: _buildSearchAndFilterBar(isSw),
          ),

          // 5. ORODHA YA MECHI (MATCHES LIST BY LEAGUE)
          _buildMatchesContent(isSw),

          // Nafasi ya chini ili isigongane na BottomNavigationBar
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 1. KICHWA CHA HABARI CHA JUU (TOP HEADER)
  // ============================================================================
  Widget _buildTopHeader(bool isSw) {
    final title = _activeTab == 0
        ? (_isToday(_selectedDate)
            ? (isSw ? 'Mechi za Leo' : "Today's Matches")
            : (isSw ? 'Mechi za Tarehe' : 'Matches on Date'))
        : (isSw ? 'Mechi Zinazofuata' : 'Upcoming Matches');

    final subtitle = _activeTab == 0
        ? (isSw ? 'Matokeo mubashara, ratiba na utabiri wa AI' : 'Live scores, schedules and AI match predictions')
        : (isSw ? 'Ratiba kamili ya mechi zijazo duniani' : 'Upcoming fixture schedule worldwide');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kichwa na Maelezo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: MColors.highlightsGold,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: MColors.highlightsGold.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: MColors.textWhite,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: MColors.textWhite.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Kitufe cha Sync / API Live Status
          InkWell(
            onTap: _isLoading ? null : () => _loadMatchesFromApi(forceRefresh: true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isApiConnected
                      ? MColors.scoresCyan.withValues(alpha: 0.5)
                      : MColors.highlightsGold.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isApiConnected ? MColors.scoresCyan : MColors.highlightsGold)
                        .withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
                      ),
                    )
                  else
                    Icon(
                      _isApiConnected ? Icons.wifi : Icons.refresh_rounded,
                      size: 14,
                      color: _isApiConnected ? MColors.scoresCyan : MColors.highlightsGold,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    _isLoading
                        ? (isSw ? 'Inavuta...' : 'Syncing...')
                        : (_isApiConnected ? 'API LIVE' : (isSw ? 'LIA' : 'SYNC')),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isApiConnected ? MColors.scoresCyan : MColors.highlightsGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 2. KIBADILISHAJI KIKUU: MECHI ZA LEO vs MECHI ZINAZOFUATA (MAIN TAB SWITCHER)
  // ============================================================================
  Widget _buildMainTabSelector(bool isSw) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: MColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MColors.scoresCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Tab 1: Mechi za Leo (Today's Matches)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_activeTab != 0) {
                    setState(() {
                      _activeTab = 0;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? MColors.scoresCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _activeTab == 0
                        ? [
                            BoxShadow(
                              color: MColors.scoresCyan.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 16,
                          color: _activeTab == 0 ? MColors.background : MColors.textWhite,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSw ? 'Mechi za Leo' : "Today's Matches",
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 0 ? MColors.background : MColors.textWhite,
                          ),
                        ),
                        if (_todaysMatches.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _activeTab == 0
                                  ? MColors.background.withValues(alpha: 0.2)
                                  : MColors.scoresCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_todaysMatches.length}',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 0 ? MColors.background : MColors.scoresCyan,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Tab 2: Mechi Zinazofuata (Upcoming Matches)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_activeTab != 1) {
                    setState(() {
                      _activeTab = 1;
                    });
                    if (_upcomingMatches.isEmpty) {
                      _loadMatchesFromApi();
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? MColors.highlightsGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _activeTab == 1
                        ? [
                            BoxShadow(
                              color: MColors.highlightsGold.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: _activeTab == 1 ? MColors.background : MColors.textWhite,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSw ? 'Mechi Zinazofuata' : 'Upcoming Matches',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 1 ? MColors.background : MColors.textWhite,
                          ),
                        ),
                        if (_upcomingMatches.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _activeTab == 1
                                  ? MColors.background.withValues(alpha: 0.2)
                                  : MColors.highlightsGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_upcomingMatches.length}',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 1 ? MColors.background : MColors.highlightsGold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 3. MCHIRIZI WA TAREHE (DATE SELECTOR: SIKU 3 ZA UHAKIKA - JANA, LEO, KESHO)
  // ============================================================================
  Widget _buildDateCarousel(bool isSw) {
    final now = DateTime.now();
    final days = [
      now.subtract(const Duration(days: 1)),
      now,
      now.add(const Duration(days: 1)),
    ];

    final monthNamesSw = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    final monthNamesEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: days.map((day) {
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isTodayDate = _isToday(day);

          String dayLabel;
          String subLabel;
          if (isTodayDate) {
            dayLabel = isSw ? 'LEO' : 'TODAY';
            subLabel = isSw ? 'Mubashara' : 'Live & Sched';
          } else if (day.isBefore(now)) {
            dayLabel = isSw ? 'JANA' : 'YEST';
            subLabel = isSw ? 'Matokeo' : 'Results';
          } else {
            dayLabel = isSw ? 'KESHO' : 'TOM';
            subLabel = isSw ? 'Ratiba' : 'Upcoming';
          }

          final monthLabel = isSw ? monthNamesSw[day.month - 1] : monthNamesEn[day.month - 1];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  setState(() {
                    _selectedDate = day;
                  });
                  _loadMatchesFromApi();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MColors.scoresCyan.withValues(alpha: 0.16)
                      : MColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? MColors.scoresCyan
                        : (isTodayDate
                            ? MColors.highlightsGold.withValues(alpha: 0.6)
                            : MColors.scoresCyan.withValues(alpha: 0.15)),
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: MColors.scoresCyan.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isTodayDate) ...[
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: MColors.highlightsGold,
                            ),
                          ),
                        ],
                        Text(
                          dayLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected
                                ? MColors.scoresCyan
                                : (isTodayDate
                                    ? MColors.highlightsGold
                                    : MColors.textWhite.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day} $monthLabel',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? MColors.scoresCyan : MColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? MColors.scoresCyan.withValues(alpha: 0.85)
                            : MColors.textWhite.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================================
  // 4. SEHEMU YA UTAFUTAJI NA VICHUJIO (SEARCH, STATUS & COMPETITION FILTERS)
  // ============================================================================
  Widget _buildSearchAndFilterBar(bool isSw) {
    final statusFilters = [
      {'label': isSw ? 'Zote' : 'All', 'icon': Icons.grid_view_rounded},
      {'label': isSw ? 'Mubashara' : 'Live', 'icon': Icons.sensors_rounded},
      {'label': isSw ? 'Zinazokuja' : 'Upcoming', 'icon': Icons.schedule_rounded},
      {'label': isSw ? 'Zilizomalizika' : 'Finished', 'icon': Icons.check_circle_outline_rounded},
    ];

    final competitionFilters = [
      {'label': isSw ? 'Zote' : 'All', 'badge': '🌐'},
      {'label': 'NBC Ligi Kuu', 'badge': '🇹🇿'},
      {'label': 'UEFA / Kimataifa', 'badge': '🏆'},
      {'label': 'Ligi Kuu Uingereza', 'badge': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
      {'label': 'La Liga', 'badge': '🇪🇸'},
      {'label': 'Serie A', 'badge': '🇮🇹'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: MColors.scoresCyan.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: MColors.textWhite,
              ),
              decoration: InputDecoration(
                icon: const Icon(Icons.search, size: 18, color: MColors.scoresCyan),
                hintText: isSw ? 'Tafuta timu au ligi...' : 'Search clubs or leagues...',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  color: MColors.textWhite.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16, color: MColors.textWhite),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Status Filter Chips (Zote, Mubashara, Zinazokuja, Zilizomalizika)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(statusFilters.length, (idx) {
                final isSelected = _filterIndex == idx;
                final item = statusFilters[idx];
                final isLiveChip = idx == 1;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _filterIndex = idx;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isLiveChip
                              ? Colors.redAccent.withValues(alpha: 0.25)
                              : MColors.scoresCyan.withValues(alpha: 0.2))
                          : MColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? (isLiveChip ? Colors.redAccent : MColors.scoresCyan)
                            : MColors.scoresCyan.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isLiveChip ? Colors.redAccent : MColors.scoresCyan)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLiveChip && isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                          )
                        else
                          Icon(
                            item['icon'] as IconData,
                            size: 13,
                            color: isSelected
                                ? (isLiveChip ? Colors.redAccent : MColors.scoresCyan)
                                : MColors.textWhite.withValues(alpha: 0.6),
                          ),
                        const SizedBox(width: 5),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isLiveChip ? Colors.redAccent : MColors.scoresCyan)
                                : MColors.textWhite.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Competition Quick Filters (NBC Ligi Kuu, UEFA, n.k.)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(competitionFilters.length, (idx) {
                final isSelected = _competitionFilterIndex == idx;
                final item = competitionFilters[idx];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _competitionFilterIndex = idx;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MColors.highlightsGold.withValues(alpha: 0.2)
                          : MColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? MColors.highlightsGold
                            : MColors.textWhite.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: MColors.highlightsGold.withValues(alpha: 0.25),
                                blurRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['badge'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? MColors.highlightsGold
                                : MColors.textWhite.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 5. ORODHA YA MECHI (MATCHES CONTENT BY LEAGUE)
  // ============================================================================
  Widget _buildMatchesContent(bool isSw) {
    if (_isLoading && _todaysMatches.isEmpty && _upcomingMatches.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isSw ? 'Inavuta mechi rasmi kutoka API...' : 'Fetching live fixtures from API...',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: MColors.textWhite.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _groupedMatches;

    if (groups.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(isSw),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = groups[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: MColors.scoresCyan.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // League Header (Kichwa cha Ligi chenye Nchi na Nembo Rasmi)
                  _buildLeagueHeader(group, isSw),

                  const Divider(
                    color: Color(0x1AFFFFFF),
                    height: 1,
                  ),

                  // Orodha ya Mechi za Ligi Hiyo Pekee
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.matches.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Color(0x12FFFFFF),
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                    ),
                    itemBuilder: (context, mIdx) {
                      final match = group.matches[mIdx];
                      return _buildMatchCard(match, isSw);
                    },
                  ),
                ],
              ),
            );
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  // --- Kichwa cha Ligi (League Header with Flag/Logo) ---
  Widget _buildLeagueHeader(LeagueGroup group, bool isSw) {
    final country = group.country?.trim() ?? '';
    final showCountryBadge = country.isNotEmpty && !group.leagueName.contains(country);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MColors.background.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          // Nembo ya Ligi au Icon
          if (group.logo.isNotEmpty)
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 8),
              child: Image.network(
                group.logo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: MColors.highlightsGold,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.emoji_events_outlined, size: 16, color: MColors.highlightsGold),
            ),

          // Jina la Ligi (Bold & Clean)
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    group.leagueName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                    ),
                  ),
                ),
                if (showCountryBadge) ...[
                  const SizedBox(width: 6),
                  Text(
                    '($country)',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: MColors.textWhite.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Idadi ya mechi katika ligi hii
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: MColors.scoresCyan.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              '${group.matches.length} ${isSw ? 'mechi' : 'fixtures'}',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: MColors.scoresCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Kadi ya Mechi Moja (Match Card with Uncut Team Names, Badges & Reminder Bell) ---
  Widget _buildMatchCard(MatchModel match, bool isSw) {
    final isReminderSet = _reminderMatchIds.contains(match.id);

    return InkWell(
      onTap: () => _showMatchDetailsModal(match, isSw),
      splashColor: MColors.scoresCyan.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mstari Mkuu wa Mechi (Home Team - Score/Time - Away Team)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. NEMBO YA TIMU YA NYUMBANI
                _buildTeamBadge(match.homeTeamLogo, match.homeTeam),
                const SizedBox(width: 8),

                // 2. JINA LA TIMU YA NYUMBANI
                Expanded(
                  flex: 4,
                  child: Text(
                    match.homeTeam,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                      height: 1.15,
                    ),
                  ),
                ),

                // 3. SEHEMU YA KATIKATI (SCORE, TIME AU 'VS')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  constraints: const BoxConstraints(minWidth: 64),
                  child: _buildCenterScoreOrTime(match, isSw),
                ),

                // 4. JINA LA TIMU YA UGENINI
                Expanded(
                  flex: 4,
                  child: Text(
                    match.awayTeam,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                      height: 1.15,
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                // 5. NEMBO YA TIMU YA UGENINI
                _buildTeamBadge(match.awayTeamLogo, match.awayTeam),
              ],
            ),

            // Maelezo ya Ziada ya Chini (Venue, Status & Interactive Reminder Bell)
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Uwanja (Venue)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: MColors.textWhite.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          match.venue.isNotEmpty
                              ? match.venue
                              : (isSw ? 'Uwanja wa Kimataifa' : 'Main Stadium'),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            color: MColors.textWhite.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Hali ya Mechi (Status)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: match.isLive
                        ? Colors.redAccent.withValues(alpha: 0.15)
                        : MColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    match.getStatus(isSw),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: match.isLive
                          ? Colors.redAccent
                          : MColors.textWhite.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Interactive Golden Reminder Bell
                GestureDetector(
                  onTap: () => _toggleReminder(match, isSw),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isReminderSet
                          ? MColors.highlightsGold.withValues(alpha: 0.2)
                          : MColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isReminderSet
                            ? MColors.highlightsGold
                            : MColors.textWhite.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      isReminderSet
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 13,
                      color: isReminderSet
                          ? MColors.highlightsGold
                          : MColors.textWhite.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Nembo ya Timu yenye Fallback ya Soka
  Widget _buildTeamBadge(String logoUrl, String teamName, {double size = 28}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MColors.background,
        border: Border.all(
          color: MColors.scoresCyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.sports_soccer, size: size * 0.55, color: MColors.textWhite),
              ),
            )
          : Center(
              child: Icon(Icons.sports_soccer, size: size * 0.55, color: MColors.textWhite),
            ),
    );
  }

  // Sehemu ya Katikati: Alama (Scores) au Muda wa Kuanza (Kickoff)
  Widget _buildCenterScoreOrTime(MatchModel match, bool isSw) {
    if (match.isLive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1),
            ),
            child: Text(
              '${match.homeScore} - ${match.awayScore}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: MColors.scoresCyan,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                match.matchTime,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: MColors.highlightsGold,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (match.statusShort == 'FT' ||
        match.statusShort == 'AET' ||
        match.statusShort == 'PEN' ||
        match.homeScore > 0 ||
        match.awayScore > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
              '${match.homeScore} - ${match.awayScore}',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: MColors.scoresCyan,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isSw ? 'Mwisho' : 'FT',
            style: GoogleFonts.manrope(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: MColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: MColors.scoresCyan.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              'VS',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: MColors.scoresCyan,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            match.matchTime,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MColors.highlightsGold,
            ),
          ),
        ],
      );
    }
  }

  // --- Hali Tupu (Empty State - Data Halisi Pekee Bila Za Kutunga) ---
  Widget _buildEmptyState(bool isSw) {
    final now = DateTime.now();
    final isYesterday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.subtract(const Duration(days: 1)).day;
    final isTodayDate = _isToday(_selectedDate);
    final isTomorrow = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.add(const Duration(days: 1)).day;
    final isApiSupportedDate = isYesterday || isTodayDate || isTomorrow;

    String title;
    String message;

    if (_competitionFilterIndex == 1) {
      title = isSw ? 'Hakuna Mechi za Ligi Kuu ya NBC' : 'No NBC Premier League Fixtures';
      message = isSw
          ? 'Hakuna mechi za Ligi Kuu ya NBC (Tanzania) zilizoratibiwa tarehe hii kwenye kalenda rasmi ya michezo. Gusa kitufe cha chini kuona mechi zote zinazoendelea.'
          : 'No NBC Premier League fixtures scheduled on this date in the official calendar. Tap below to view all other matches.';
    } else if (!isApiSupportedDate) {
      title = isSw ? 'Data za Tarehe Hii Nje ya Mpango wa API' : 'Date Outside Free API Plan';
      message = isSw
          ? 'Mpango wa sasa wa API unatoa data halisi za Jana, Leo, na Kesho (zaidi ya mechi 400 halisi zinapatikana). Chagua Jana, Leo, au Kesho kuona mechi zote halisi.'
          : 'The current API plan provides authentic fixtures for Yesterday, Today, and Tomorrow (400+ real matches). Select Yesterday, Today, or Tomorrow.';
    } else {
      title = isSw ? 'Hakuna Mechi Zilizopatikana' : 'No Fixtures Found';
      message = isSw
          ? 'Hakuna mechi zilizokidhi vigezo vyako kwenye tarehe hii. Jaribu kubadilisha kichujio au ubonyeze kitufe cha kupakia upya.'
          : 'No fixtures found matching your criteria on this date. Try another filter or tap refresh.';
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            !isApiSupportedDate ? Icons.calendar_today_rounded : Icons.sports_soccer_outlined,
            size: 44,
            color: !isApiSupportedDate ? MColors.highlightsGold : MColors.scoresCyan,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: MColors.textWhite.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (_competitionFilterIndex != 0) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.scoresCyan,
                foregroundColor: MColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _competitionFilterIndex = 0;
                });
              },
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: Text(
                isSw ? 'Onyesha Mashindano Yote' : 'Show All Competitions',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (!isApiSupportedDate) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.scoresCyan,
                    foregroundColor: MColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _loadMatchesFromApi();
                  },
                  icon: const Icon(Icons.today, size: 15),
                  label: Text(
                    isSw ? 'Mechi za Leo (115+)' : "Today's Matches (115+)",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MColors.highlightsGold,
                    side: const BorderSide(color: MColors.highlightsGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now().add(const Duration(days: 1));
                    });
                    _loadMatchesFromApi();
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: Text(
                    isSw ? 'Kesho (204+)' : 'Tomorrow (204+)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.scoresCyan,
                foregroundColor: MColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _loadMatchesFromApi(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                isSw ? 'Pakia Upya Mechi' : 'Refresh Fixtures',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // 6. TAARIFA ZA ZIADA NA UTABIRI WA AI (MODAL BOTTOM SHEET)
  // ============================================================================
  void _showMatchDetailsModal(MatchModel match, bool isSw) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _MatchCenterModalSheet(
          match: match,
          isSw: isSw,
          isReminderSet: _reminderMatchIds.contains(match.id),
          onToggleReminder: () => _toggleReminder(match, isSw),
          onShareMatch: () => _shareMatchDetails(match, isSw),
          buildTeamBadge: _buildTeamBadge,
        );
      },
    );
  }

}

// ============================================================================
// MODAL SHEET YA KIPEKEE YA MECHI (MATCH CENTER: STATS, LINEUPS, H2H & PREDICTIONS)
// ============================================================================
class _MatchCenterModalSheet extends StatefulWidget {
  final MatchModel match;
  final bool isSw;
  final bool isReminderSet;
  final VoidCallback onToggleReminder;
  final VoidCallback onShareMatch;
  final Widget Function(String logoUrl, String teamName, {double size}) buildTeamBadge;

  const _MatchCenterModalSheet({
    required this.match,
    required this.isSw,
    required this.isReminderSet,
    required this.onToggleReminder,
    required this.onShareMatch,
    required this.buildTeamBadge,
  });

  @override
  State<_MatchCenterModalSheet> createState() => _MatchCenterModalSheetState();
}

class _MatchCenterModalSheetState extends State<_MatchCenterModalSheet> {
  int _activeTab = 0; // 0 = Takwimu, 1 = Vikosi, 2 = H2H, 3 = Utabiri

  List<FixtureTeamStats> _stats = [];
  bool _statsLoading = false;

  List<FixtureLineupModel> _lineups = [];
  bool _lineupsLoading = false;

  List<MatchModel> _h2h = [];
  bool _h2hLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() {
    final fId = widget.match.fixtureId;
    if (fId > 0) {
      _statsLoading = true;
      _lineupsLoading = true;
      FootballApiService().getFixtureStatistics(fId).then((data) {
        if (mounted) setState(() { _stats = data; _statsLoading = false; });
      });
      FootballApiService().getFixtureLineups(fId).then((data) {
        if (mounted) setState(() { _lineups = data; _lineupsLoading = false; });
      });
    }

    if (widget.match.homeTeamId > 0 && widget.match.awayTeamId > 0) {
      _h2hLoading = true;
      FootballApiService().getHeadToHead(widget.match.homeTeamId, widget.match.awayTeamId).then((data) {
        if (mounted) setState(() { _h2h = data; _h2hLoading = false; });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final isSw = widget.isSw;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: MColors.scoresCyan, width: 1.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: MColors.textWhite.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 2. League Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (m.leagueLogo.isNotEmpty) ...[
                  Image.network(
                    m.leagueLogo,
                    width: 18,
                    height: 18,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    m.getLeague(isSw),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: MColors.highlightsGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Scoreboard & Teams
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Home Team
                Expanded(
                  child: Column(
                    children: [
                      widget.buildTeamBadge(m.homeTeamLogo, m.homeTeam, size: 44),
                      const SizedBox(height: 6),
                      Text(
                        m.homeTeam,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: MColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Score / Status
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: m.isLive ? Colors.redAccent : MColors.scoresCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (m.isLive || m.homeScore > 0 || m.awayScore > 0)
                            ? '${m.homeScore} - ${m.awayScore}'
                            : (m.matchTime.isNotEmpty ? m.matchTime : 'VS'),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: m.isLive ? Colors.redAccent : MColors.scoresCyan,
                        ),
                      ),
                      Text(
                        m.getStatus(isSw),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: m.isLive ? Colors.redAccent : MColors.highlightsGold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Away Team
                Expanded(
                  child: Column(
                    children: [
                      widget.buildTeamBadge(m.awayTeamLogo, m.awayTeam, size: 44),
                      const SizedBox(height: 6),
                      Text(
                        m.awayTeam,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: MColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Segmented Control Tabs (Takwimu, Vikosi, H2H, Utabiri)
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: MColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _buildSegmentTab(0, isSw ? 'Takwimu' : 'Stats', Icons.bar_chart_rounded),
                _buildSegmentTab(1, isSw ? 'Vikosi' : 'Lineups', Icons.people_outline_rounded),
                _buildSegmentTab(2, isSw ? 'Uso kwa Uso' : 'H2H', Icons.compare_arrows_rounded),
                _buildSegmentTab(3, isSw ? 'Utabiri' : 'Prediction', Icons.auto_awesome),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 5. Scrollable Tab Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: _buildActiveTabContent(isSw),
            ),
          ),

          // 6. Action Buttons Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: MColors.surface,
              border: Border(
                top: BorderSide(color: MColors.scoresCyan.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: widget.isReminderSet ? MColors.highlightsGold : MColors.scoresCyan.withValues(alpha: 0.5),
                      ),
                      backgroundColor: widget.isReminderSet ? MColors.highlightsGold.withValues(alpha: 0.15) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onToggleReminder();
                    },
                    icon: Icon(
                      widget.isReminderSet ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      size: 16,
                      color: widget.isReminderSet ? MColors.highlightsGold : MColors.scoresCyan,
                    ),
                    label: Text(
                      widget.isReminderSet ? (isSw ? 'Ondoa Kikumbusho' : 'Remove Alert') : (isSw ? 'Kikumbusho' : 'Remind Me'),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isReminderSet ? MColors.highlightsGold : MColors.textWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.scoresCyan,
                      foregroundColor: MColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: widget.onShareMatch,
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: Text(
                      isSw ? 'Shiriki Mechi' : 'Share Match',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? MColors.scoresCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? MColors.background : MColors.textWhite.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? MColors.background : MColors.textWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isSw) {
    switch (_activeTab) {
      case 0:
        return _buildStatsTab(isSw);
      case 1:
        return _buildLineupsTab(isSw);
      case 2:
        return _buildH2hTab(isSw);
      case 3:
      default:
        return _buildPredictionsTab(isSw);
    }
  }

  // --- 1. TAB YA TAKWIMU (MATCH STATS) ---
  Widget _buildStatsTab(bool isSw) {
    if (_statsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator(color: MColors.scoresCyan)),
      );
    }

    if (_stats.length < 2) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.sports_soccer, size: 36, color: MColors.scoresCyan),
            const SizedBox(height: 10),
            Text(
              isSw
                  ? 'Takwimu za moja kwa moja zitaanza kuonekana mchezo ukianza mubashara.'
                  : 'Live statistics will be displayed once the match kicks off.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: MColors.textWhite.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    final home = _stats[0];
    final away = _stats[1];

    return Column(
      children: [
        _buildStatComparisonRow(isSw ? 'Umiliki wa Mpira' : 'Ball Possession', home.ballPossession, away.ballPossession),
        _buildStatComparisonRow(isSw ? 'Mashuti Yote' : 'Total Shots', '${home.totalShots}', '${away.totalShots}'),
        _buildStatComparisonRow(isSw ? 'Mashuti Yaliyolenga' : 'Shots on Target', '${home.shotsOnGoal}', '${away.shotsOnGoal}'),
        _buildStatComparisonRow(isSw ? 'Mashuti Yaliyotoka' : 'Shots off Target', '${home.shotsOffGoal}', '${away.shotsOffGoal}'),
        _buildStatComparisonRow(isSw ? 'Kona' : 'Corner Kicks', '${home.cornerKicks}', '${away.cornerKicks}'),
        _buildStatComparisonRow(isSw ? 'Faulo' : 'Fouls', '${home.fouls}', '${away.fouls}'),
        _buildStatComparisonRow(isSw ? 'Kuotea (Offsides)' : 'Offsides', '${home.offsides}', '${away.offsides}'),
        _buildStatComparisonRow(isSw ? 'Kadi za Njano' : 'Yellow Cards', '${home.yellowCards}', '${away.yellowCards}', accentColor: Colors.amber),
        _buildStatComparisonRow(isSw ? 'Kadi Nyekundu' : 'Red Cards', '${home.redCards}', '${away.redCards}', accentColor: Colors.redAccent),
      ],
    );
  }

  Widget _buildStatComparisonRow(String label, String homeVal, String awayVal, {Color? accentColor}) {
    final int hNum = int.tryParse(homeVal.replaceAll('%', '').trim()) ?? 0;
    final int aNum = int.tryParse(awayVal.replaceAll('%', '').trim()) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeVal,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentColor ?? MColors.scoresCyan,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: MColors.textWhite.withValues(alpha: 0.7),
                ),
              ),
              Text(
                awayVal,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentColor ?? MColors.highlightsGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  Expanded(
                    flex: hNum > 0 ? hNum : 1,
                    child: Container(color: accentColor ?? MColors.scoresCyan),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: aNum > 0 ? aNum : 1,
                    child: Container(color: accentColor ?? MColors.highlightsGold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. TAB YA VIKOSI (LINEUPS) ---
  Widget _buildLineupsTab(bool isSw) {
    if (_lineupsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator(color: MColors.scoresCyan)),
      );
    }

    if (_lineups.length < 2) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, size: 36, color: MColors.highlightsGold),
            const SizedBox(height: 10),
            Text(
              isSw
                  ? 'Vikosi rasmi vya mechi vinatarajiwa kutangazwa saa 1 kabla ya kuanza kwa mchezo.'
                  : 'Official lineups will be confirmed 1 hour before kick-off.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: MColors.textWhite.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    final home = _lineups[0];
    final away = _lineups[1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formation & Coach Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${home.formation} (${home.teamName})',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MColors.scoresCyan,
                    ),
                  ),
                  if (home.coachName.isNotEmpty)
                    Text(
                      '${isSw ? 'Kocha:' : 'Coach:'} ${home.coachName}',
                      style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.6)),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${away.formation} (${away.teamName})',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MColors.highlightsGold,
                    ),
                  ),
                  if (away.coachName.isNotEmpty)
                    Text(
                      '${isSw ? 'Kocha:' : 'Coach:'} ${away.coachName}',
                      style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.6)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Starting XI Header
        Text(
          isSw ? 'Kikosi cha Kwanza (Starting XI)' : 'Starting XI',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: MColors.textWhite,
          ),
        ),
        const SizedBox(height: 8),

        // Starting XI Lists Side-by-Side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: home.startXI.map((p) => _buildPlayerTile(p, MColors.scoresCyan)).toList(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: away.startXI.map((p) => _buildPlayerTile(p, MColors.highlightsGold)).toList(),
              ),
            ),
          ],
        ),

        if (home.substitutes.isNotEmpty || away.substitutes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            isSw ? 'Wachezaji wa Akiba (Substitutes)' : 'Substitutes',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: home.substitutes.take(7).map((p) => _buildPlayerTile(p, MColors.textWhite.withValues(alpha: 0.5))).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: away.substitutes.take(7).map((p) => _buildPlayerTile(p, MColors.textWhite.withValues(alpha: 0.5))).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerTile(LineupPlayer player, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: MColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                '${player.number}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              player.name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MColors.textWhite,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.pos,
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: MColors.textWhite.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. TAB YA USO KWA USO (H2H) ---
  Widget _buildH2hTab(bool isSw) {
    if (_h2hLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator(color: MColors.scoresCyan)),
      );
    }

    if (_h2h.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_rounded, size: 36, color: MColors.scoresCyan),
            const SizedBox(height: 10),
            Text(
              isSw
                  ? 'Historia ya dabi: Timu hizi zina rekodi thabiti za mashindano ya kitaifa na kimataifa.'
                  : 'Head to Head: Both clubs maintain a competitive historical record.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: MColors.textWhite.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Mechi Zilizopita Kati ya Timu Hizi' : 'Previous Encounters',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: MColors.highlightsGold,
          ),
        ),
        const SizedBox(height: 8),
        ..._h2h.map((m) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    m.homeTeam,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: MColors.textWhite,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${m.homeScore} - ${m.awayScore}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MColors.scoresCyan,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    m.awayTeam,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: MColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- 4. TAB YA UTABIRI (PREDICTIONS & VENUE) ---
  Widget _buildPredictionsTab(bool isSw) {
    final m = widget.match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Prediction Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: MColors.highlightsGold),
                  const SizedBox(width: 6),
                  Text(
                    isSw ? 'Utabiri wa Ushindi wa AI' : 'AI Win Probability',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: MColors.highlightsGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${m.homeTeam}: ${m.homeWinProb}%',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MColors.scoresCyan,
                    ),
                  ),
                  Text(
                    '${isSw ? 'Sare' : 'Draw'}: ${m.drawProb}%',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MColors.textWhite.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '${m.awayTeam}: ${m.awayWinProb}%',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MColors.highlightsGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 7,
                  child: Row(
                    children: [
                      Expanded(
                        flex: m.homeWinProb > 0 ? m.homeWinProb : 1,
                        child: Container(color: MColors.scoresCyan),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: m.drawProb > 0 ? m.drawProb : 1,
                        child: Container(color: Colors.white38),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: m.awayWinProb > 0 ? m.awayWinProb : 1,
                        child: Container(color: MColors.highlightsGold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Form Guide Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSw ? 'Mwenendo wa Mechi 5 Zilizopita:' : 'Recent Form (Last 5):',
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: MColors.textWhite.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildFormRow(m.homeTeam, m.homeForm),
              const SizedBox(height: 6),
              _buildFormRow(m.awayTeam, m.awayForm),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Match Info List
        _buildInfoTile(
          Icons.access_time_rounded,
          isSw ? 'Muda / Hali:' : 'Time / Status:',
          '${m.matchTime} (${m.getStatus(isSw)})',
        ),
        const SizedBox(height: 6),
        _buildInfoTile(
          Icons.stadium_outlined,
          isSw ? 'Uwanja:' : 'Venue:',
          m.venue.isNotEmpty ? m.venue : (isSw ? 'Uwanja wa Kimataifa' : 'Main Stadium'),
        ),
        if (m.referee != null && m.referee!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildInfoTile(
            Icons.person_pin_outlined,
            isSw ? 'Mwamuzi:' : 'Referee:',
            m.referee!,
          ),
        ],
      ],
    );
  }

  Widget _buildFormRow(String teamName, String form) {
    final letters = form.split('-');
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: MColors.textWhite,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: letters.map((l) {
            Color c = const Color(0xFF00C853);
            if (l == 'D') c = const Color(0xFFFFB300);
            if (l == 'L') c = const Color(0xFFE53935);
            return Container(
              margin: const EdgeInsets.only(left: 3),
              width: 17,
              height: 17,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
              child: Center(
                child: Text(
                  l,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: MColors.scoresCyan),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 12, color: MColors.textWhite.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: MColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}
