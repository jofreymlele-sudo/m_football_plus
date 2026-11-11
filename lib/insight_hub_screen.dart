import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart' show MColors;
import 'admin_screen.dart';
import 'firebase_service.dart';

// ============================================================================
// UKURASA WA KITUO CHA MAARIFA (INSIGHT HUB SCREEN)
// ============================================================================
// 1. Utabiri wa AI (AI Predictions) wenye LinearProgressIndicator ya Cyan na Gold
// 2. Uchambuzi wa Wataalam (Expert Tactical Analysis) wenye kadi za wachambuzi
// 3. Kura za Mashabiki (Interactive Fan Polls) zenye asilimia baada ya kupiga kura
// ============================================================================

class InsightHubScreen extends StatefulWidget {
  final bool isSwahili;
  final VoidCallback? onBackToHome;

  const InsightHubScreen({
    super.key,
    required this.isSwahili,
    this.onBackToHome,
  });

  @override
  State<InsightHubScreen> createState() => _InsightHubScreenState();
}

class _InsightHubScreenState extends State<InsightHubScreen> {
  // Filter tab iliyochaguliwa (0 = Yote, 1 = Utabiri wa AI, 2 = Uchambuzi, 3 = Kura za Mashabiki)
  int _selectedFilterIndex = 0;

  // Mechi ya Utabiri wa AI iliyochaguliwa (0 = Yanga vs Simba, 1 = Arsenal vs Chelsea, 2 = Real Madrid vs Barcelona)
  int _selectedAiMatchIndex = 0;

  // Kura za Mashabiki - Hali ya Upigaji Kura
  int? _poll1SelectedOption; // null = hajapiga, 0 = Yanga, 1 = Draw, 2 = Simba
  final Map<int, int> _poll1Votes = {0: 3240, 1: 998, 2: 1142};

  int? _poll2SelectedOption; // null = hajapiga, 0 = Pacome, 1 = Jean Ahoua, 2 = Fei Toto
  final Map<int, int> _poll2Votes = {0: 2150, 1: 1780, 2: 1420};

  // Wachambuzi - Expand & Likes state
  final Set<int> _expandedAnalysts = {};
  final Set<int> _likedAnalysts = {};
  final Map<int, int> _analystLikes = {0: 348, 1: 214, 2: 179};

  @override
  Widget build(BuildContext context) {
    final isSw = widget.isSwahili;

    return Scaffold(
      backgroundColor: MColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Kichwa cha Habari (Header & Back Button)
            _buildHeader(isSw),

            // 2. Filter Tabs (Yote, Utabiri wa AI, Uchambuzi, Kura)
            _buildFilterTabs(isSw),

            const SizedBox(height: 6),

            // 3. Orodha Kuu ya Yaliyomo (Scrollable Feed)
            Expanded(
              child: RefreshIndicator(
                color: MColors.scoresCyan,
                backgroundColor: MColors.surface,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 600));
                  if (mounted) setState(() {});
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  children: [
                    // A. KIPENGELE CHA 1: UTABIRI WA AI (AI PREDICTIONS)
                    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
                      _buildAiPredictionsSection(isSw),
                      const SizedBox(height: 24),
                    ],

                    // B. KIPENGELE CHA 2: UCHAMBUZI WA WATAALAM (EXPERT ANALYSIS)
                    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
                      _buildExpertAnalysisSection(isSw),
                      const SizedBox(height: 24),
                    ],

                    // C. KIPENGELE CHA 3: KURA ZA MASHABIKI (FAN POLLS)
                    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) ...[
                      _buildFanPollsSection(isSw),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 1. HEADER YA UKURASA
  // ==========================================================================
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
                isSw ? 'Kituo cha Maarifa' : 'Insight Hub',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // AI Badge / Tactic Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MColors.scoresCyan.withValues(alpha: 0.2),
                  MColors.highlightsGold.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 13, color: MColors.highlightsGold),
                const SizedBox(width: 5),
                Text(
                  'AI & TACTICS',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: MColors.scoresCyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. FILTER TABS (YOTE, UTABIRI WA AI, UCHAMBUZI, KURA)
  // ==========================================================================
  Widget _buildFilterTabs(bool isSw) {
    final tabs = [
      {'title': isSw ? 'Yote' : 'All', 'icon': Icons.dashboard_customize_outlined},
      {'title': isSw ? 'Utabiri wa AI' : 'AI Predictions', 'icon': Icons.psychology_rounded},
      {'title': isSw ? 'Wachambuzi' : 'Expert Analysis', 'icon': Icons.record_voice_over_rounded},
      {'title': isSw ? 'Kura za Mashabiki' : 'Fan Polls', 'icon': Icons.how_to_vote_rounded},
    ];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          final tab = tabs[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? MColors.scoresCyan.withValues(alpha: 0.18) : MColors.surface,
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
                  Icon(
                    tab['icon'] as IconData,
                    size: 15,
                    color: isSelected ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab['title'] as String,
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

  // ==========================================================================
  // A. KIPENGELE CHA 1: UTABIRI WA AI (AI PREDICTIONS)
  // ==========================================================================
  Widget _buildAiPredictionsSection(bool isSw) {
    // Mechi za Utabiri wa AI
    final aiMatches = [
      {
        'id': 'dar_derby',
        'league': isSw ? 'Ligi Kuu ya NBC' : 'NBC Premier League',
        'country': 'Tanzania',
        'flag': '🇹🇿',
        'venue': 'Benjamin Mkapa Stadium, Dar es Salaam',
        'date': isSw ? 'Jumamosi, 19:00' : 'Saturday, 19:00',
        'homeTeam': 'Young Africans (Yanga)',
        'homeLogo': FootballApiService.getTeamLogo('Young Africans'),
        'awayTeam': 'Simba SC',
        'awayLogo': FootballApiService.getTeamLogo('Simba SC'),
        'homeWin': 65,
        'draw': 20,
        'awayWin': 15,
        'xG': 'Yanga 2.1 — 0.9 Simba',
        'confidence': '89%',
        'summarySw': 'Mfumo wa AI unatabiri ushindi wa Yanga kwa 65% kutokana na umiliki mkubwa wa kiungo na fomu ya hivi karibuni ya kushambulia.',
        'summaryEn': 'AI predicts a 65% win probability for Yanga backed by midfield territorial dominance and recent high attacking momentum.',
        'keyStatSw': 'Yanga hawajapoteza mechi 8 za nyumbani; Simba wanapata wastani wa magoli 1.1 ugenini.',
        'keyStatEn': 'Yanga are unbeaten in 8 home matches; Simba average 1.1 goals scored away.',
      },
      {
        'id': 'london_derby',
        'league': 'Premier League',
        'country': 'England',
        'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
        'venue': 'Emirates Stadium, London',
        'date': isSw ? 'Jumapili, 19:30' : 'Sunday, 19:30',
        'homeTeam': 'Arsenal',
        'homeLogo': FootballApiService.getTeamLogo('Arsenal'),
        'awayTeam': 'Chelsea',
        'awayLogo': FootballApiService.getTeamLogo('Chelsea'),
        'homeWin': 58,
        'draw': 24,
        'awayWin': 18,
        'xG': 'Arsenal 1.8 — 1.1 Chelsea',
        'confidence': '84%',
        'summarySw': 'Arsenal ina nafasi kubwa (58%) kwa sababu ya rekodi imara ya ulinzi (Clean Sheets 7) na uwezo wa mipira iliyokufa.',
        'summaryEn': 'Arsenal hold a 58% edge driven by defensive stability (7 clean sheets) and superior set-piece conversion.',
        'keyStatSw': 'Arsenal wanamiliki wastani wa 61% mpira nyumbani dhidi ya timu 6 za juu.',
        'keyStatEn': 'Arsenal average 61% possession at home against top-six opponents.',
      },
      {
        'id': 'el_clasico',
        'league': 'La Liga',
        'country': 'Spain',
        'flag': '🇪🇸',
        'venue': 'Santiago Bernabéu, Madrid',
        'date': isSw ? 'Jumapili, 22:00' : 'Sunday, 22:00',
        'homeTeam': 'Real Madrid',
        'homeLogo': FootballApiService.getTeamLogo('Real Madrid'),
        'awayTeam': 'Barcelona',
        'awayLogo': FootballApiService.getTeamLogo('Barcelona'),
        'homeWin': 48,
        'draw': 26,
        'awayWin': 26,
        'xG': 'Real Madrid 2.0 — 1.7 Barcelona',
        'confidence': '81%',
        'summarySw': 'Mchezo mkali wenye mashambulizi ya kasi. Real Madrid wanapewa nafasi ya 48% kutokana na faida ya uwanja wa nyumbani.',
        'summaryEn': 'High-octane duel with Madrid slightly favored at 48% powered by home advantage and transitional speed.',
        'keyStatSw': 'Wastani wa magoli 3.4 kwenye mechi 5 zilizopita za El Clasico.',
        'keyStatEn': '3.4 goals per game across the last 5 El Clasico meetings.',
      },
    ];

    final currentMatch = aiMatches[_selectedAiMatchIndex.clamp(0, aiMatches.length - 1)];
    final homePct = currentMatch['homeWin'] as int;
    final drawPct = currentMatch['draw'] as int;
    final awayPct = currentMatch['awayWin'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kichwa cha Sehemu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MColors.scoresCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology_rounded, size: 20, color: MColors.scoresCyan),
                ),
                const SizedBox(width: 8),
                Text(
                  isSw ? 'Utabiri wa AI' : 'AI Match Predictions',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
              ],
            ),

            // AI Algorithm Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MColors.highlightsGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'M-AI Model v2.4',
                style: GoogleFonts.manrope(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: MColors.highlightsGold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horizontal Match Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(aiMatches.length, (idx) {
              final m = aiMatches[idx];
              final isSel = _selectedAiMatchIndex == idx;
              final shortLabel = '${m['homeTeam'].toString().split(' ').first} vs ${m['awayTeam'].toString().split(' ').first}';

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${m['flag']} $shortLabel'),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedAiMatchIndex = idx),
                  selectedColor: MColors.scoresCyan.withValues(alpha: 0.22),
                  backgroundColor: MColors.surface,
                  side: BorderSide(
                    color: isSel ? MColors.scoresCyan : MColors.scoresCyan.withValues(alpha: 0.15),
                  ),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.75),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),

        // Kadi Kuu ya Utabiri wa AI (AI Spotlight Card)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: MColors.scoresCyan.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League & Venue Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(currentMatch['flag'] as String, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        currentMatch['league'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: MColors.highlightsGold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      currentMatch['date'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MColors.scoresCyan,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                currentMatch['venue'] as String,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: MColors.textWhite.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 16),

              // Matchup Row (Team Logos & Names)
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamBadge(currentMatch['homeLogo'] as String),
                        const SizedBox(height: 8),
                        Text(
                          currentMatch['homeTeam'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: MColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center "VS" & Confidence
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: MColors.scoresCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'VS',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: MColors.scoresCyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'xG: ${currentMatch['xG']}',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: MColors.textWhite.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamBadge(currentMatch['awayLogo'] as String),
                        const SizedBox(height: 8),
                        Text(
                          currentMatch['awayTeam'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
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

              // ================================================================
              // MCHORO WA LINEAR PROGRESS INDICATOR (CYAN & GOLD)
              // ================================================================
              Text(
                isSw ? 'Uwezekano wa Ushindi (AI Probability)' : 'Win Probability (AI Analysis)',
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: MColors.textWhite.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),

              // 1. Stacked Segmented Progress Bar yenye Rangi za Cyan & Gold
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      // Home Win (Cyan)
                      Expanded(
                        flex: homePct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E5FF), MColors.scoresCyan],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Draw (Muted Cyan / Slate)
                      Expanded(
                        flex: drawPct,
                        child: Container(
                          color: const Color(0xFF2E6F8F),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Away Win (Gold)
                      Expanded(
                        flex: awayPct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [MColors.highlightsGold, Color(0xFFFF9100)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Viwango vya Asilimia na LinearProgressIndicators Mahsusi
              Row(
                children: [
                  // Team A (Home Win - Cyan)
                  Expanded(
                    child: _buildPercentageBlock(
                      label: currentMatch['homeTeam'].toString().split(' ').first,
                      subLabel: isSw ? 'Ushindi' : 'Win',
                      pct: homePct,
                      color: MColors.scoresCyan,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Draw (Suluhu - Blue/Slate)
                  Expanded(
                    child: _buildPercentageBlock(
                      label: isSw ? 'Suluhu' : 'Draw',
                      subLabel: isSw ? 'Sare' : 'Tie',
                      pct: drawPct,
                      color: const Color(0xFF64FFDA),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Team B (Away Win - Gold)
                  Expanded(
                    child: _buildPercentageBlock(
                      label: currentMatch['awayTeam'].toString().split(' ').first,
                      subLabel: isSw ? 'Ushindi' : 'Win',
                      pct: awayPct,
                      color: MColors.highlightsGold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0x1AFFFFFF), height: 1),
              const SizedBox(height: 12),

              // AI Breakdown Summary Text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 16, color: MColors.highlightsGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSw ? currentMatch['summarySw'] as String : currentMatch['summaryEn'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: MColors.textWhite.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Key Insight Footnote
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: MColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 ${isSw ? currentMatch['keyStatSw'] : currentMatch['keyStatEn']}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: MColors.textWhite.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Visual Block yenye LinearProgressIndicator ya asilimia husika
  Widget _buildPercentageBlock({
    required String label,
    required String subLabel,
    required int pct,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: MColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$pct%',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite,
            ),
          ),
          Text(
            subLabel,
            style: GoogleFonts.manrope(
              fontSize: 9.5,
              color: MColors.textWhite.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 4,
              backgroundColor: MColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // B. KIPENGELE CHA 2: UCHAMBUZI WA WATAALAM (EXPERT ANALYSIS - STREAMBUILDER)
  // ==========================================================================
  Widget _buildExpertAnalysisSection(bool isSw) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().streamAnalysis(),
      builder: (context, snapshot) {
        final analysts = snapshot.data ?? [];
        if (analysts.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kichwa cha Sehemu
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MColors.highlightsGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.record_voice_over_rounded, size: 20, color: MColors.highlightsGold),
                ),
                const SizedBox(width: 8),
                Text(
                  isSw ? 'Uchambuzi wa Wataalam' : 'Expert Tactical Analysis',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Orodha ya Kadi za Wachambuzi (Live Stream)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: analysts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
            final a = analysts[idx];
            final analystId = a['id'] as int;
            final isExpanded = _expandedAnalysts.contains(analystId);
            final isLiked = _likedAnalysts.contains(analystId);
            final likeCount = _analystLikes[analystId] ?? 200;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mchambuzi Profile Row
                  Row(
                    children: [
                      // Analyst Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: MColors.scoresCyan, width: 1.5),
                            shape: BoxShape.circle,
                          ),
                          child: Image.network(
                            a['avatar'] as String,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => Container(
                              color: MColors.background,
                              child: const Icon(Icons.person, color: MColors.scoresCyan, size: 24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name and Role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  a['name'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: MColors.textWhite,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: MColors.scoresCyan),
                              ],
                            ),
                            Text(
                              isSw ? a['roleSw'] as String : a['roleEn'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                color: MColors.textWhite.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tag Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MColors.highlightsGold.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          a['tag'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: MColors.highlightsGold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Headline
                  Text(
                    isSw ? a['headlineSw'] as String : a['headlineEn'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MColors.scoresCyan,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Match Context
                  Row(
                    children: [
                      const Icon(Icons.sports_soccer, size: 12, color: MColors.highlightsGold),
                      const SizedBox(width: 5),
                      Text(
                        '${a['league']} • ${a['match']}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MColors.textWhite.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Paragraph ya Uchambuzi
                  Text(
                    isSw ? a['contentSw'] as String : a['contentEn'] as String,
                    maxLines: isExpanded ? null : 3,
                    overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      color: MColors.textWhite.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Action Row (Soma Zaidi & Like Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Read More Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedAnalysts.remove(analystId);
                            } else {
                              _expandedAnalysts.add(analystId);
                            }
                          });
                        },
                        child: Text(
                          isExpanded ? (isSw ? 'Funga' : 'Show Less') : (isSw ? 'Soma Zaidi...' : 'Read Full Analysis...'),
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: MColors.scoresCyan,
                          ),
                        ),
                      ),

                      // Interactive Like / Agree Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isLiked) {
                              _likedAnalysts.remove(analystId);
                              _analystLikes[analystId] = likeCount - 1;
                            } else {
                              _likedAnalysts.add(analystId);
                              _analystLikes[analystId] = likeCount + 1;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLiked ? MColors.scoresCyan.withValues(alpha: 0.15) : MColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLiked ? MColors.scoresCyan : MColors.scoresCyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                                size: 13,
                                color: isLiked ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$likeCount',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isLiked ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  },
);
  }

  // ==========================================================================
  // C. KIPENGELE CHA 3: KURA ZA MASHABIKI (FAN POLLS)
  // ==========================================================================
  Widget _buildFanPollsSection(bool isSw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kichwa cha Sehemu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded, size: 20, color: Colors.purpleAccent),
                ),
                const SizedBox(width: 8),
                Text(
                  isSw ? 'Kura za Mashabiki' : 'Fan Polls',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // KADI YA 1: Derby ya Kariakoo - Nani Atashinda?
        _buildPollCard(
          question: isSw ? 'Nani ataibuka na ushindi katika Kariakoo Derby ya msimu huu?' : 'Who will emerge victorious in the Kariakoo Derby this season?',
          subtitle: 'Ligi Kuu ya NBC • Benjamin Mkapa Stadium',
          options: [
            {'title': 'Young Africans (Yanga)', 'icon': Icons.shield_rounded, 'color': MColors.scoresCyan},
            {'title': isSw ? 'Suluhu (Draw)' : 'Draw', 'icon': Icons.handshake_outlined, 'color': const Color(0xFF64FFDA)},
            {'title': 'Simba SC', 'icon': Icons.shield_rounded, 'color': MColors.highlightsGold},
          ],
          selectedOption: _poll1SelectedOption,
          votesMap: _poll1Votes,
          onVote: (idx) {
            setState(() {
              if (_poll1SelectedOption == null) {
                _poll1Votes[idx] = (_poll1Votes[idx] ?? 0) + 1;
                _poll1SelectedOption = idx;
              }
            });
          },
          onChangeVote: () {
            setState(() {
              if (_poll1SelectedOption != null) {
                _poll1Votes[_poll1SelectedOption!] = (_poll1Votes[_poll1SelectedOption!] ?? 1) - 1;
                _poll1SelectedOption = null;
              }
            });
          },
          isSw: isSw,
        ),

        const SizedBox(height: 16),

        // KADI YA 2: Mchezaji Bora wa Mwezi
        _buildPollCard(
          question: isSw ? 'Nani anastahili tuzo ya Mchezaji Bora wa Mwezi Ligi Kuu ya NBC?' : 'Who deserves Player of the Month in the NBC Premier League?',
          subtitle: 'Kura za Mashabiki • Mwezi wa Novemba',
          options: [
            {'title': 'Pacome Zouzoua (Yanga)', 'icon': Icons.star_rounded, 'color': MColors.scoresCyan},
            {'title': 'Jean Ahoua (Simba)', 'icon': Icons.star_rounded, 'color': MColors.highlightsGold},
            {'title': 'Feisal Salum (Azam FC)', 'icon': Icons.star_rounded, 'color': const Color(0xFF64FFDA)},
          ],
          selectedOption: _poll2SelectedOption,
          votesMap: _poll2Votes,
          onVote: (idx) {
            setState(() {
              if (_poll2SelectedOption == null) {
                _poll2Votes[idx] = (_poll2Votes[idx] ?? 0) + 1;
                _poll2SelectedOption = idx;
              }
            });
          },
          onChangeVote: () {
            setState(() {
              if (_poll2SelectedOption != null) {
                _poll2Votes[_poll2SelectedOption!] = (_poll2Votes[_poll2SelectedOption!] ?? 1) - 1;
                _poll2SelectedOption = null;
              }
            });
          },
          isSw: isSw,
        ),

        // Kura Maalum zilizoundwa na Admin (Zikiwepo)
        // Kura Maalum zilizoundwa kwenye Firebase Firestore (StreamBuilder)
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().streamPolls(),
          builder: (context, snapshot) {
            final customPolls = snapshot.data ?? [];
            if (customPolls.isEmpty) return const SizedBox();

            return Column(
              children: customPolls.map((cp) {
                final rawOptions = cp['options'] as List<dynamic>? ?? [];
                final options = rawOptions.map((item) {
                  Color c = MColors.scoresCyan;
                  final rawColor = item['color'] ?? item['colorValue'];
                  if (rawColor is Color) {
                    c = rawColor;
                  } else if (rawColor is int) {
                    c = Color(rawColor);
                  }
                  return {
                    'title': item['title']?.toString() ?? '',
                    'color': c,
                    'icon': Icons.how_to_vote_rounded,
                  };
                }).toList();

                final pollId = cp['id'] as int? ?? 0;
                final votesMap = Map<int, int>.from(cp['votesMap'] ?? {0: 10, 1: 5, 2: 8});

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildPollCard(
                    question: cp['question'] as String,
                    subtitle: cp['subtitle'] as String,
                    options: options,
                    selectedOption: null,
                    votesMap: votesMap,
                    onVote: (idx) {
                      FirestoreService().votePoll(pollId, idx);
                    },
                    onChangeVote: () {},
                    isSw: isSw,
                  ),
                );
              }).toList(),
            );
          },
        ),

        // Kitufe cha Haraka cha Kuingia Admin Panel (KINAONEKANA TU KAMA isOwner == TRUE!)
        if (AuthService().isOwner) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdminScreen(isSwahili: isSw)),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MColors.scoresCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: MColors.scoresCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSw ? 'Paneli ya Msimamizi (Admin Panel)' : 'Owner Admin Control Panel',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: MColors.textWhite,
                              ),
                            ),
                            Text(
                              isSw ? 'Weka habari, wachambuzi, na kura mpya' : 'Add stories, expert analysis & fan polls',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: MColors.textWhite.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: MColors.scoresCyan, size: 15),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Widget ya Kadi Moja ya Kura (Poll Card)
  Widget _buildPollCard({
    required String question,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required int? selectedOption,
    required Map<int, int> votesMap,
    required ValueChanged<int> onVote,
    required VoidCallback onChangeVote,
    required bool isSw,
  }) {
    final bool hasVoted = selectedOption != null;

    // Jumla ya kura zote
    int totalVotes = 0;
    votesMap.forEach((_, count) => totalVotes += count);
    if (totalVotes == 0) totalVotes = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasVoted ? MColors.scoresCyan.withValues(alpha: 0.35) : MColors.scoresCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question & Subtitle
          Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MColors.textWhite,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: MColors.textWhite.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 14),

          // Vitufe vya Chaguo 3 (Options)
          Column(
            children: List.generate(options.length, (idx) {
              final opt = options[idx];
              final String title = opt['title'] as String;
              final Color color = opt['color'] as Color;
              final IconData icon = opt['icon'] as IconData;
              final isChosen = selectedOption == idx;

              final voteCount = votesMap[idx] ?? 0;
              final pct = ((voteCount / totalVotes) * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onVote(idx),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: hasVoted
                          ? (isChosen ? color.withValues(alpha: 0.15) : MColors.background.withValues(alpha: 0.6))
                          : MColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChosen
                            ? color
                            : (hasVoted ? Colors.transparent : MColors.scoresCyan.withValues(alpha: 0.18)),
                        width: isChosen ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              isChosen ? Icons.check_circle_rounded : icon,
                              size: 18,
                              color: isChosen ? color : MColors.textWhite.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: isChosen ? FontWeight.bold : FontWeight.w600,
                                  color: isChosen ? color : MColors.textWhite,
                                ),
                              ),
                            ),
                            if (hasVoted) ...[
                              Text(
                                '$pct%',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isChosen ? color : MColors.textWhite.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Animated Progress Bar ikisha pigwa kura
                        if (hasVoted) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100.0,
                              minHeight: 5,
                              backgroundColor: MColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isChosen ? color : MColors.textWhite.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // Footer ya Kura (Jumla ya Kura & Badilisha Kura)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasVoted
                    ? (isSw ? 'Kura $totalVotes • Kura yako imehesabiwa!' : '$totalVotes votes • Your vote was counted!')
                    : (isSw ? 'Kura $totalVotes zimepigwa • Gusa kupiga kura' : '$totalVotes votes • Tap to vote'),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasVoted ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.5),
                ),
              ),
              if (hasVoted)
                GestureDetector(
                  onTap: onChangeVote,
                  child: Text(
                    isSw ? 'Badilisha' : 'Change',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: MColors.highlightsGold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper Widget ya Team Badge
  Widget _buildTeamBadge(String logoUrl) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: MColors.scoresCyan.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shield_outlined,
                size: 26,
                color: MColors.scoresCyan,
              ),
            )
          : const Icon(Icons.shield_outlined, size: 26, color: MColors.scoresCyan),
    );
  }
}
