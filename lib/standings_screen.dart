import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart' show MColors;

// ============================================================================
// UKURASA WA MSIMAMO WA LIGI (LEAGUE STANDINGS SCREEN)
// ============================================================================
class LeagueMeta {
  final int id;
  final String nameSw;
  final String nameEn;
  final String flag;
  final String country;

  const LeagueMeta({
    required this.id,
    required this.nameSw,
    required this.nameEn,
    required this.flag,
    required this.country,
  });

  String getName(bool isSw) => isSw ? nameSw : nameEn;
}

class StandingsScreen extends StatefulWidget {
  final bool isSwahili;
  final VoidCallback? onBackToHome;

  const StandingsScreen({
    super.key,
    required this.isSwahili,
    this.onBackToHome,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  // Ligi Kuu Zinazoungwa Mkono
  static const List<LeagueMeta> _leagues = [
    LeagueMeta(id: 567, nameSw: 'NBC Ligi Kuu', nameEn: 'NBC Premier League', flag: '🇹🇿', country: 'Tanzania'),
    LeagueMeta(id: 39, nameSw: 'Premier League', nameEn: 'Premier League', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', country: 'England'),
    LeagueMeta(id: 140, nameSw: 'La Liga', nameEn: 'La Liga', flag: '🇪🇸', country: 'Spain'),
    LeagueMeta(id: 135, nameSw: 'Serie A', nameEn: 'Serie A', flag: '🇮🇹', country: 'Italy'),
    LeagueMeta(id: 2, nameSw: 'Klabu Bingwa', nameEn: 'Champions League', flag: '🏆', country: 'Europe'),
  ];

  int _selectedLeagueIndex = 0;
  final int _selectedSeason = 2024;
  late Future<List<StandingItem>> _standingsFuture;
  int? _expandedTeamId;

  @override
  void initState() {
    super.initState();
    _fetchStandings();
  }

  LeagueMeta get _currentLeague => _leagues[_selectedLeagueIndex];

  void _fetchStandings({bool forceRefresh = false}) {
    _standingsFuture = FootballApiService().getStandings(
      _currentLeague.id.toString(),
      season: _selectedSeason,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _refreshStandings() async {
    setState(() {
      _fetchStandings(forceRefresh: true);
    });
    try {
      await _standingsFuture;
    } catch (_) {}
  }

  void _onLeagueSelected(int index) {
    if (_selectedLeagueIndex != index) {
      setState(() {
        _selectedLeagueIndex = index;
        _expandedTeamId = null;
        _fetchStandings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = widget.isSwahili;

    return Scaffold(
      backgroundColor: MColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Kichwa cha Habari na Back Button
            _buildHeader(isSw),

            // 2. League Selector Tabs (Horizontal Chips)
            _buildLeagueSelectorTabs(isSw),

            const SizedBox(height: 8),

            // 3. Jedwali la Msimamo (Standings Table Header & Body) kupitia FutureBuilder
            Expanded(
              child: RefreshIndicator(
                color: MColors.scoresCyan,
                backgroundColor: MColors.surface,
                onRefresh: _refreshStandings,
                child: FutureBuilder<List<StandingItem>>(
                  future: _standingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: MColors.scoresCyan),
                            const SizedBox(height: 14),
                            Text(
                              isSw ? 'Inapakia msimamo halisi kutoka API...' : 'Loading real standings from API...',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: MColors.scoresCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error, isSw);
                    }

                    final standings = snapshot.data ?? [];
                    if (standings.isEmpty) {
                      return _buildEmptyState(isSw);
                    }

                    return _buildStandingsList(standings, isSw);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Header ---
  Widget _buildHeader(bool isSw) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBackToHome != null) ...[
                IconButton(
                  onPressed: widget.onBackToHome,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: MColors.scoresCyan),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                isSw ? 'Msimamo wa Ligi' : 'League Standings',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          // Season Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.3)),
            ),
            child: Text(
              '2024/2025',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: MColors.highlightsGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. League Selector Tabs ---
  Widget _buildLeagueSelectorTabs(bool isSw) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _leagues.length,
        itemBuilder: (context, index) {
          final league = _leagues[index];
          final isSelected = _selectedLeagueIndex == index;

          return GestureDetector(
            onTap: () => _onLeagueSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? MColors.scoresCyan.withValues(alpha: 0.18)
                    : MColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? MColors.scoresCyan : MColors.scoresCyan.withValues(alpha: 0.15),
                  width: isSelected ? 1.6 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MColors.scoresCyan.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(league.flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    league.getName(isSw),
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.8),
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

  // --- 3. Standings Table & Rows ---
  Widget _buildStandingsList(List<StandingItem> standings, bool isSw) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: standings.length + 1, // +1 kwa Table Header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTableHeader(isSw);
        }

        final standing = standings[index - 1];
        final isExpanded = _expandedTeamId == standing.teamId;

        return _buildTeamStandingRow(standing, index - 1, isExpanded, isSw, standings.length);
      },
    );
  }

  // Table Column Headers (#, TIMU, P, GD, PTS, FOMU)
  Widget _buildTableHeader(bool isSw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MColors.textWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isSw ? 'TIMU' : 'TEAM',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MColors.textWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              'P',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MColors.textWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              'GD',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MColors.textWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              'PTS',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: MColors.scoresCyan,
              ),
            ),
          ),
          const SizedBox(width: 44, child: Text('')),
        ],
      ),
    );
  }

  // Row ya Timu Moja
  Widget _buildTeamStandingRow(
    StandingItem item,
    int index,
    bool isExpanded,
    bool isSw,
    int totalTeams,
  ) {
    // Alama Maalum:
    // Nafasi ya 1 = Gold Mbingwa
    // Nafasi 2 na 3 = Cyan Klabu Bingwa
    // Nafasi za chini (3 za mwisho) = Red Kushuka Daraja
    final isTop1 = item.rank == 1;
    final isTop3 = item.rank <= 3;
    final isRelegation = totalTeams > 6 && item.rank > (totalTeams - 3);

    Color rankColor;
    if (isTop1) {
      rankColor = MColors.highlightsGold;
    } else if (isTop3) {
      rankColor = MColors.scoresCyan;
    } else if (isRelegation) {
      rankColor = Colors.redAccent;
    } else {
      rankColor = MColors.textWhite.withValues(alpha: 0.7);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isTop1
                ? MColors.highlightsGold
                : (isTop3
                    ? MColors.scoresCyan
                    : (isRelegation ? Colors.redAccent.withValues(alpha: 0.7) : Colors.transparent)),
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedTeamId = isExpanded ? null : item.teamId;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  // 1. Rank Number
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.rank}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                        color: rankColor,
                      ),
                    ),
                  ),

                  // 2. Team Logo
                  Builder(
                    builder: (context) {
                      final effectiveLogo = FootballApiService.getTeamLogo(item.teamName, fallbackUrl: item.teamLogo);
                      return Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        child: effectiveLogo.isNotEmpty
                            ? Image.network(
                                effectiveLogo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: MColors.textWhite,
                                ),
                              )
                            : const Icon(Icons.shield_outlined, size: 16, color: MColors.textWhite),
                      );
                    },
                  ),

                  // 3. Team Name (Uncut)
                  Expanded(
                    child: Text(
                      item.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                        color: isTop1 ? MColors.highlightsGold : MColors.textWhite,
                      ),
                    ),
                  ),

                  // 4. Played (P)
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${item.played}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MColors.textWhite.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  // 5. Goal Difference (GD)
                  SizedBox(
                    width: 38,
                    child: Text(
                      item.goalsDiff > 0 ? '+${item.goalsDiff}' : '${item.goalsDiff}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: item.goalsDiff > 0
                            ? const Color(0xFF00E676)
                            : (item.goalsDiff < 0
                                ? Colors.redAccent.withValues(alpha: 0.8)
                                : MColors.textWhite.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),

                  // 6. Points (PTS)
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${item.points}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isTop1
                            ? MColors.highlightsGold
                            : (isTop3 ? MColors.scoresCyan : MColors.textWhite),
                      ),
                    ),
                  ),

                  // 7. Form mini dots
                  SizedBox(
                    width: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: item.form.split('').take(3).map((letter) {
                        Color c = const Color(0xFF00E676);
                        if (letter == 'D') c = const Color(0xFFFFB300);
                        if (letter == 'L') c = const Color(0xFFE53935);
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Breakdown Card ukigusa timu (Expanded Details)
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              decoration: BoxDecoration(
                color: MColors.background.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Column(
                children: [
                  const Divider(color: Color(0x1AFFFFFF), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(isSw ? 'Ushindi' : 'Won', '${item.win}', const Color(0xFF00E676)),
                      _buildMiniStat(isSw ? 'Sare' : 'Drawn', '${item.draw}', const Color(0xFFFFB300)),
                      _buildMiniStat(isSw ? 'Kufungwa' : 'Lost', '${item.lose}', const Color(0xFFE53935)),
                      _buildMiniStat(isSw ? 'Magoli Ya' : 'Goals For', '${item.goalsFor}', MColors.scoresCyan),
                      _buildMiniStat(isSw ? 'Yaliyofungwa' : 'Against', '${item.goalsAgainst}', Colors.white70),
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MColors.highlightsGold.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: MColors.textWhite.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSw) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_chart_outlined, size: 48, color: MColors.scoresCyan),
              const SizedBox(height: 12),
              Text(
                isSw ? 'Msimamo haujapatikana kwa sasa' : 'No standings data available right now',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSw ? 'Vuta chini ili kupakia upya' : 'Pull down to refresh',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: MColors.textWhite.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshStandings,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  isSw ? 'Pakia Upya' : 'Reload',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.surface,
                  foregroundColor: MColors.scoresCyan,
                  side: const BorderSide(color: MColors.scoresCyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error, bool isSw) {
    final errorMsg = error?.toString() ?? '';
    final isRateLimit = errorMsg.contains('quota') ||
        errorMsg.contains('requests per day') ||
        errorMsg.contains('request limit') ||
        errorMsg.contains('Too Many Requests');

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isRateLimit
                        ? Colors.amberAccent.withValues(alpha: 0.4)
                        : Colors.redAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  isRateLimit ? Icons.hourglass_empty_rounded : Icons.cloud_off_rounded,
                  size: 40,
                  color: isRateLimit ? Colors.amberAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isRateLimit
                    ? (isSw ? 'Kikomo cha Maombi ya API Kimefikiwa' : 'API Request Limit Reached')
                    : (isSw ? 'Hitilafu ya Kupakia Msimamo' : 'Failed to Load Standings'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isRateLimit
                    ? (isSw
                        ? 'Kikomo cha maombi 100/siku ya mpango wa bure wa API-Sports kimefikiwa. Tafadhali jaribu tena baadaye au ongeza ukomo.'
                        : 'Free tier quota of 100 requests/day on API-Sports reached. Please try again later.')
                    : (isSw
                        ? 'Tafadhali kagua muunganisho wako wa intaneti kisha ujaribu tena.'
                        : 'Please check your internet connection and try again.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  color: MColors.textWhite.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refreshStandings,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  isSw ? 'Jaribu Tena' : 'Retry',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.scoresCyan,
                  foregroundColor: MColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
