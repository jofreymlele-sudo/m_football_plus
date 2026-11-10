import 'package:flutter/material.dart';
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
      // 1. Vuta Mechi za Tarehe Iliyochaguliwa kutoka API
      final todayResults = await FootballApiService().getTodaysMatches(
        date: dateStr,
        forceRefresh: forceRefresh,
      );

      // 2. Vuta Mechi Zinazofuata Kesho (200+ mechi halisi kutoka API)
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

  // Orodha inayotumika kulingana na tab iliyochaguliwa (Data Halisi za API Pekee)
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
        return m.isLive;
      } else if (_filterIndex == 2) {
        // Zinazokuja tu (Not Started)
        return !m.isLive && (m.statusShort == 'NS' || m.statusShort == 'TBD' || (m.homeScore == 0 && m.awayScore == 0 && !m.statusShort.contains('FT')));
      } else if (_filterIndex == 3) {
        // Zilizomalizika tu (Finished)
        return m.statusShort == 'FT' || m.statusShort == 'AET' || m.statusShort == 'PEN' || m.statusEn.toLowerCase().contains('full') || m.statusSw.toLowerCase().contains('mwisho');
      }

      return true;
    }).toList();
  }

  // Mechi zilizopangwa kwa makundi ya Ligi (Kila ligi na nchi yake pekee bila kuchanganywa)
  List<LeagueGroup> get _groupedMatches {
    final Map<String, LeagueGroup> map = {};

    for (final m in _filteredMatches) {
      final country = m.leagueCountry ?? '';
      final leagueSw = m.getLeague(widget.isSwahili);
      // Key ya kipekee: League Name + Country (Inazuia Ligi za nchi tofauti kuunganishwa)
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
          // 1. KICHWA CHA HABARI JUU (TOP HEADER: 'MECHI ZA LEO')
          SliverToBoxAdapter(
            child: _buildTopHeader(isSw),
          ),

          // 2. TAB YA KUCHAGUA: MECHI ZA LEO vs MECHI ZINAZOFUATA
          SliverToBoxAdapter(
            child: _buildMainTabSelector(isSw),
          ),

          // 3. MCHIRIZI WA TAREHE (DATE PICKER CAROUSEL) - Inaonekana hasa ukiwa kwenye Mechi za Leo
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
        ? (isSw ? 'Matokeo mubashara, ratiba na takwimu' : 'Live scores, schedules and match stats')
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
                        color: MColors.highlightsGold, // Gold vertical accent
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
  // 3. MCHIRIZI WA TAREHE (DATE CAROUSEL: JANA, LEO, KESHO, N.K.)
  // ============================================================================
  Widget _buildDateCarousel(bool isSw) {
    final now = DateTime.now();
    // Onyesha siku 7: Siku 2 zilizopita, Leo, na siku 4 zinazofuata
    final days = List.generate(7, (i) => now.add(Duration(days: i - 2)));

    return Container(
      height: 64,
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
          } else if (day.day == now.subtract(const Duration(days: 1)).day) {
            dayLabel = isSw ? 'JANA' : 'YEST';
          } else if (day.day == now.add(const Duration(days: 1)).day) {
            dayLabel = isSw ? 'KESHO' : 'TOM';
          } else {
            // Siku ya juma
            final weekdaysSw = ['JTT', 'JNN', 'JTN', 'ALH', 'IJM', 'JMS', 'JPL'];
            final weekdaysEn = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
            dayLabel = isSw ? weekdaysSw[day.weekday - 1] : weekdaysEn[day.weekday - 1];
          }

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
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? MColors.scoresCyan.withValues(alpha: 0.15)
                    : MColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? MColors.scoresCyan
                      : (isTodayDate
                          ? MColors.highlightsGold.withValues(alpha: 0.6)
                          : MColors.scoresCyan.withValues(alpha: 0.15)),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MColors.scoresCyan.withValues(alpha: 0.25),
                          blurRadius: 6,
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
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? MColors.scoresCyan : MColors.textWhite,
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
  // 4. SEHEMU YA UTAFUTAJI NA VICHUJIO (SEARCH & FILTER CHIPS)
  // ============================================================================
  Widget _buildSearchAndFilterBar(bool isSw) {
    final filters = [
      {'label': isSw ? 'Zote' : 'All', 'icon': Icons.grid_view_rounded},
      {'label': isSw ? 'Mubashara' : 'Live', 'icon': Icons.sensors_rounded},
      {'label': isSw ? 'Zinazokuja' : 'Upcoming', 'icon': Icons.schedule_rounded},
      {'label': isSw ? 'Zilizomalizika' : 'Finished', 'icon': Icons.check_circle_outline_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
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

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(filters.length, (idx) {
                final isSelected = _filterIndex == idx;
                final item = filters[idx];
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

  // --- Kichwa cha Ligi (League Header with Flag/Logo - Kila Ligi na Nchi Yake) ---
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

  // --- Kadi ya Mechi Moja (Match Card with Uncut Team Names & Badges) ---
  Widget _buildMatchCard(MatchModel match, bool isSw) {
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

                // 2. JINA LA TIMU YA NYUMBANI (Nafasi Kubwa, Haikatwi kirahisi)
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

                // 4. JINA LA TIMU YA UGENINI (Nafasi Kubwa, Haikatwi kirahisi)
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

            // Maelezo ya Ziada ya Chini (Venue & Status)
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
                          match.venue.isNotEmpty ? match.venue : (isSw ? 'Uwanja wa Kimataifa' : 'Main Stadium'),
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
      // Mechi ipo Mubashara (Live)
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
      // Mechi Imemalizika (Finished)
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
      // Mechi Haijaanza (Upcoming / Scheduled)
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
              color: MColors.highlightsGold, // Muda katika Gold
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
  // 6. TAARIFA ZA ZIADA ZA MECHI (MODAL BOTTOM SHEET)
  // ============================================================================
  void _showMatchDetailsModal(MatchModel match, bool isSw) {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: MColors.textWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // League Name & Country
              Text(
                match.getLeague(isSw),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MColors.highlightsGold,
                ),
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

              const SizedBox(height: 20),
              const Divider(color: Color(0x1AFFFFFF)),
              const SizedBox(height: 10),

              // Match Information list
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
              if (match.referee != null && match.referee!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildModalInfoRow(
                  Icons.person_pin_outlined,
                  isSw ? 'Mwenzeshi:' : 'Referee:',
                  match.referee!,
                ),
              ],

              const SizedBox(height: 24),

              // Funga button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.scoresCyan,
                    foregroundColor: MColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isSw ? 'Funga' : 'Close',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
