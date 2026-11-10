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
            m.leagueSw.toLowerCase().contains('nbc') ||
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
  // 3. MCHIRIZI WA TAREHE (DATE CAROUSEL: 10 DAYS NOV 8 - NOV 17)
  // ============================================================================
  Widget _buildDateCarousel(bool isSw) {
    final now = DateTime.now();
    // Onyesha siku 10 kamili: Siku 2 zilizopita, Leo, na siku 7 zinazofuata (hadi 17 Nov)
    final days = List.generate(10, (i) => now.add(Duration(days: i - 2)));

    return Container(
      height: 68,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isTodayDate = _isToday(day);

          String dayLabel;
          if (isTodayDate) {
            dayLabel = isSw ? 'LEO' : 'TODAY';
          } else if (day.day == now.subtract(const Duration(days: 1)).day && day.month == now.month) {
            dayLabel = isSw ? 'JANA' : 'YEST';
          } else if (day.day == now.add(const Duration(days: 1)).day && day.month == now.month) {
            dayLabel = isSw ? 'KESHO' : 'TOM';
          } else {
            final weekdaysSw = ['JTT', 'JNN', 'JTN', 'ALH', 'IJM', 'JMS', 'JPL'];
            final weekdaysEn = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
            dayLabel = isSw ? weekdaysSw[day.weekday - 1] : weekdaysEn[day.weekday - 1];
          }

          final monthNamesSw = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
          final monthNamesEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final monthLabel = isSw ? monthNamesSw[day.month - 1] : monthNamesEn[day.month - 1];

          return GestureDetector(
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
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? MColors.scoresCyan.withValues(alpha: 0.18)
                    : MColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? MColors.scoresCyan
                      : (isTodayDate
                          ? MColors.highlightsGold.withValues(alpha: 0.7)
                          : MColors.scoresCyan.withValues(alpha: 0.15)),
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MColors.scoresCyan.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? MColors.scoresCyan
                          : (isTodayDate
                              ? MColors.highlightsGold
                              : MColors.textWhite.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? MColors.scoresCyan : MColors.textWhite,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? MColors.scoresCyan.withValues(alpha: 0.8)
                          : MColors.textWhite.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  Widget _buildTeamBadge(String logoUrl, String teamName) {
    return Container(
      width: 28,
      height: 28,
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
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.sports_soccer, size: 15, color: MColors.textWhite),
              ),
            )
          : const Center(
              child: Icon(Icons.sports_soccer, size: 15, color: MColors.textWhite),
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

  // --- Hali Tupu (Empty State) ---
  Widget _buildEmptyState(bool isSw) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sports_soccer_outlined,
            size: 48,
            color: MColors.scoresCyan,
          ),
          const SizedBox(height: 14),
          Text(
            isSw ? 'Hakuna Mechi Zilizopatikana' : 'No Fixtures Found',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? 'Hakuna mechi zilizokidhi vigezo au zilizoratibiwa tarehe hii. Jaribu kuchagua tarehe nyingine au ubonyeze kitufe cha kupakia upya.'
                : 'No fixtures match your criteria or scheduled on this date. Try another date or tap refresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: MColors.textWhite.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
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
      ),
    );
  }

  // ============================================================================
  // 6. TAARIFA ZA ZIADA NA UTABIRI WA AI (MODAL BOTTOM SHEET)
  // ============================================================================
  void _showMatchDetailsModal(MatchModel match, bool isSw) {
    final isReminderSet = _reminderMatchIds.contains(match.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: MColors.scoresCyan, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: MColors.textWhite.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // League Name & Country
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (match.leagueLogo.isNotEmpty) ...[
                      Image.network(
                        match.leagueLogo,
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        match.getLeague(isSw),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: MColors.highlightsGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Teams & Score Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home Team
                    Expanded(
                      child: Column(
                        children: [
                          _buildTeamBadge(match.homeTeamLogo, match.homeTeam),
                          const SizedBox(height: 6),
                          Text(
                            match.homeTeam,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Score / VS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: MColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        match.isLive || match.homeScore > 0 || match.awayScore > 0
                            ? '${match.homeScore} - ${match.awayScore}'
                            : 'VS',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: MColors.scoresCyan,
                        ),
                      ),
                    ),

                    // Away Team
                    Expanded(
                      child: Column(
                        children: [
                          _buildTeamBadge(match.awayTeamLogo, match.awayTeam),
                          const SizedBox(height: 6),
                          Text(
                            match.awayTeam,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ================================================================
                // KIPENGELE CHA KIPEKEE: UTABIRI WA MATOKEO WA AI (AI PREDICTION)
                // ================================================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MColors.scoresCyan.withValues(alpha: 0.25),
                      width: 1,
                    ),
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

                      // Probability Percentages
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${match.homeTeam}: ${match.homeWinProb}%',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MColors.scoresCyan,
                            ),
                          ),
                          Text(
                            '${isSw ? 'Sare' : 'Draw'}: ${match.drawProb}%',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MColors.textWhite.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${match.awayTeam}: ${match.awayWinProb}%',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MColors.highlightsGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Segmented Probability Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 7,
                          child: Row(
                            children: [
                              Expanded(
                                flex: match.homeWinProb > 0 ? match.homeWinProb : 1,
                                child: Container(color: MColors.scoresCyan),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: match.drawProb > 0 ? match.drawProb : 1,
                                child: Container(color: Colors.white38),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: match.awayWinProb > 0 ? match.awayWinProb : 1,
                                child: Container(color: MColors.highlightsGold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Form Guide (Mwenendo wa Mechi za Hivi Karibuni)
                      const SizedBox(height: 10),
                      const Divider(color: Color(0x1AFFFFFF), height: 1),
                      const SizedBox(height: 8),

                      Text(
                        isSw ? 'Mwenendo wa Mechi 5 Zilizopita:' : 'Recent Form (Last 5):',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MColors.textWhite.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildFormGuideRow(match.homeTeam, match.homeForm),
                      const SizedBox(height: 4),
                      _buildFormGuideRow(match.awayTeam, match.awayForm),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Match Information List
                _buildModalInfoRow(
                  Icons.access_time_rounded,
                  isSw ? 'Muda / Hali:' : 'Time / Status:',
                  '${match.matchTime} (${match.getStatus(isSw)})',
                ),
                const SizedBox(height: 8),
                _buildModalInfoRow(
                  Icons.stadium_outlined,
                  isSw ? 'Uwanja:' : 'Venue:',
                  match.venue.isNotEmpty ? match.venue : (isSw ? 'Uwanja wa Kimataifa' : 'Main Stadium'),
                ),
                if (match.keyPlayer != null && match.keyPlayer!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildModalInfoRow(
                    Icons.star_outline_rounded,
                    isSw ? 'Mchezaji wa Kuchunguzwa:' : 'Key Player:',
                    match.keyPlayer!,
                  ),
                ],
                if (match.h2hSummary != null && match.h2hSummary!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildModalInfoRow(
                    Icons.history_rounded,
                    isSw ? 'Historia ya Dabi:' : 'Head to Head:',
                    match.h2hSummary!,
                  ),
                ],
                if (match.referee != null && match.referee!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildModalInfoRow(
                    Icons.person_pin_outlined,
                    isSw ? 'Mwamuzi:' : 'Referee:',
                    match.referee!,
                  ),
                ],

                const SizedBox(height: 18),

                // Action Buttons: Reminder & Share
                Row(
                  children: [
                    // Reminder Toggle Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isReminderSet ? MColors.highlightsGold : MColors.scoresCyan.withValues(alpha: 0.5),
                          ),
                          backgroundColor: isReminderSet ? MColors.highlightsGold.withValues(alpha: 0.15) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleReminder(match, isSw);
                        },
                        icon: Icon(
                          isReminderSet ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 16,
                          color: isReminderSet ? MColors.highlightsGold : MColors.scoresCyan,
                        ),
                        label: Text(
                          isReminderSet
                              ? (isSw ? 'Ondoa Kikumbusho' : 'Remove Alert')
                              : (isSw ? 'Kikumbusho' : 'Remind Me'),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isReminderSet ? MColors.highlightsGold : MColors.textWhite,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Share Match Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.scoresCyan,
                          foregroundColor: MColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _shareMatchDetails(match, isSw),
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
              ],
            ),
          ),
        );
      },
    );
  }

  // Row ya Mwenendo wa Mechi (Form Guide Row W/D/L)
  Widget _buildFormGuideRow(String teamName, String form) {
    final letters = form.split('-');

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            teamName,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MColors.textWhite.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: letters.map((letter) {
            Color bg;
            if (letter == 'W') {
              bg = const Color(0xFF00C853); // Kijani
            } else if (letter == 'D') {
              bg = const Color(0xFFFFB300); // Manjano/Machungwa
            } else {
              bg = const Color(0xFFE53935); // Nyekundu
            }
            return Container(
              margin: const EdgeInsets.only(left: 3),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModalInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MColors.scoresCyan),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: MColors.textWhite.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MColors.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}
