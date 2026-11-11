import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart' show MColors;
import 'firebase_service.dart';

// ============================================================================
// UKURASA WA MSIMAMIZI (ADMIN PANEL - M FOOTBALL PLUS)
// ============================================================================
// Maalum kwa ajili ya Mmiliki (Jofrey Mlele - jofreymlele@gmail.com):
// 1. Fomu ya Habari Mpya (Top Story -> Firebase Firestore)
// 2. Fomu ya Uchambuzi wa Wataalam (Expert Analysis -> Firebase Firestore)
// 3. Fomu ya Kura za Mashabiki (Fan Polls -> Firebase Firestore)
// 4. Sehemu ya Kudhibiti Akaunti ya Mmiliki & Usalama wa Mfumo
// ============================================================================

/// Huduma ya Kuunganisha Admin Panel na Firebase Firestore
class AdminDataService {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // Habari Maalum zilizochapishwa na Admin
  List<NewsArticleModel> get customStories => _firestoreService.localNews;

  // Uchambuzi wa Wataalam uliowekwa na Admin
  List<Map<String, dynamic>> get customAnalyses => _firestoreService.localAnalyses;

  // Kura za Mashabiki zilizowekwa na Admin
  List<Map<String, dynamic>> get customPolls => _firestoreService.localPolls;

  // 1. Chapisha Habari Mpya kwenye Firestore
  Future<void> publishStory(NewsArticleModel story) async {
    await _firestoreService.publishNews(story);
  }

  // 2. Futa Habari kutoka Firestore
  Future<void> deleteStory(String id) async {
    await _firestoreService.deleteNews(id);
  }

  // 3. Chapisha Uchambuzi wa Mchambuzi kwenye Firestore
  Future<void> publishAnalysis(Map<String, dynamic> analysis) async {
    await _firestoreService.publishAnalysis(analysis);
  }

  // 4. Futa Uchambuzi
  Future<void> deleteAnalysis(int id) async {
    await _firestoreService.deleteAnalysis(id);
  }

  // 5. Chapisha Kura ya Mashabiki kwenye Firestore
  Future<void> publishPoll(Map<String, dynamic> poll) async {
    await _firestoreService.publishPoll(poll);
  }

  // 6. Futa Kura
  Future<void> deletePoll(int id) async {
    await _firestoreService.deletePoll(id);
  }
}

class AdminScreen extends StatefulWidget {
  final bool isSwahili;

  const AdminScreen({
    super.key,
    required this.isSwahili,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Global Keys za fomu
  final _storyFormKey = GlobalKey<FormState>();
  final _analysisFormKey = GlobalKey<FormState>();
  final _pollFormKey = GlobalKey<FormState>();

  // --- 1. Controllers za Fomu ya Habari (Story) ---
  final _storyTitleSwController = TextEditingController();
  final _storyTitleEnController = TextEditingController();
  final _storyImageController = TextEditingController();
  final _storyDescSwController = TextEditingController();
  final _storyDescEnController = TextEditingController();
  String _selectedStoryCategory = 'all';
  bool _isTopTrending = true;

  // --- 2. Controllers za Fomu ya Mchambuzi (Expert Analysis) ---
  final _analystNameController = TextEditingController();
  final _analystRoleController = TextEditingController();
  final _analystAvatarController = TextEditingController();
  final _analysisHeadlineController = TextEditingController();
  final _analysisMatchController = TextEditingController();
  final _analysisContentController = TextEditingController();
  final _analysisTagController = TextEditingController(text: '#MbinuZaSoka');

  // --- 3. Controllers za Fomu ya Kura (Fan Poll) ---
  final _pollQuestionController = TextEditingController();
  final _pollSubtitleController = TextEditingController();
  final _pollOptionAController = TextEditingController();
  final _pollOptionBController = TextEditingController();
  final _pollOptionCController = TextEditingController();

  final AdminDataService _adminService = AdminDataService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storyTitleSwController.dispose();
    _storyTitleEnController.dispose();
    _storyImageController.dispose();
    _storyDescSwController.dispose();
    _storyDescEnController.dispose();

    _analystNameController.dispose();
    _analystRoleController.dispose();
    _analystAvatarController.dispose();
    _analysisHeadlineController.dispose();
    _analysisMatchController.dispose();
    _analysisContentController.dispose();
    _analysisTagController.dispose();

    _pollQuestionController.dispose();
    _pollSubtitleController.dispose();
    _pollOptionAController.dispose();
    _pollOptionBController.dispose();
    _pollOptionCController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ACTION: CHAPISHA HABARI MPYA (FIREBASE FIRESTORE)
  // ==========================================================================
  Future<void> _submitStory() async {
    if (!_storyFormKey.currentState!.validate()) return;

    final id = 'admin_story_${DateTime.now().millisecondsSinceEpoch}';
    final titleSw = _storyTitleSwController.text.trim();
    final titleEn = _storyTitleEnController.text.trim().isNotEmpty ? _storyTitleEnController.text.trim() : titleSw;
    final descSw = _storyDescSwController.text.trim();
    final descEn = _storyDescEnController.text.trim().isNotEmpty ? _storyDescEnController.text.trim() : descSw;
    final img = _storyImageController.text.trim().isNotEmpty
        ? _storyImageController.text.trim()
        : 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800';

    final newStory = NewsArticleModel(
      id: id,
      title: titleEn,
      titleSw: titleSw,
      description: descEn,
      descriptionSw: descSw,
      imageUrl: img,
      publishedAt: 'Sasa Hivi (Firestore)',
      source: 'M-Football Plus (Mmiliki)',
      category: _selectedStoryCategory,
    );

    await _adminService.publishStory(newStory);
    if (!mounted) return;
    setState(() {});

    _storyTitleSwController.clear();
    _storyTitleEnController.clear();
    _storyImageController.clear();
    _storyDescSwController.clear();
    _storyDescEnController.clear();

    _showSuccessSnackBar(
      widget.isSwahili
          ? 'Habari Kuu imechapishwa kwenye Firestore! Inaonekana moja kwa moja.'
          : 'Top story published to Firestore! Real-time stream updated.',
    );
  }

  // ==========================================================================
  // ACTION: CHAPISHA UCHAMBUZI WA MCHAMBUZI (FIREBASE FIRESTORE)
  // ==========================================================================
  Future<void> _submitAnalysis() async {
    if (!_analysisFormKey.currentState!.validate()) return;

    final id = DateTime.now().millisecondsSinceEpoch;
    final name = _analystNameController.text.trim();
    final role = _analystRoleController.text.trim();
    final headline = _analysisHeadlineController.text.trim();
    final match = _analysisMatchController.text.trim();
    final content = _analysisContentController.text.trim();
    final tag = _analysisTagController.text.trim().isNotEmpty ? _analysisTagController.text.trim() : '#MbinuZaSoka';
    final avatar = _analystAvatarController.text.trim().isNotEmpty
        ? _analystAvatarController.text.trim()
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';

    final analysisItem = {
      'id': id,
      'name': name,
      'roleSw': role,
      'roleEn': role,
      'avatar': avatar,
      'match': match,
      'league': 'M-Football Tactical',
      'headlineSw': headline,
      'headlineEn': headline,
      'contentSw': content,
      'contentEn': content,
      'tag': tag,
    };

    await _adminService.publishAnalysis(analysisItem);
    if (!mounted) return;
    setState(() {});

    _analystNameController.clear();
    _analystRoleController.clear();
    _analystAvatarController.clear();
    _analysisHeadlineController.clear();
    _analysisMatchController.clear();
    _analysisContentController.clear();

    _showSuccessSnackBar(
      widget.isSwahili
          ? 'Uchambuzi umehifadhiwa Firestore na unaonekana Kituo cha Maarifa!'
          : 'Expert analysis published to Firestore and live in Insight Hub!',
    );
  }

  // ==========================================================================
  // ACTION: ANZISHA KURA YA MASHABIKI (FIREBASE FIRESTORE)
  // ==========================================================================
  Future<void> _submitPoll() async {
    if (!_pollFormKey.currentState!.validate()) return;

    final id = DateTime.now().millisecondsSinceEpoch;
    final question = _pollQuestionController.text.trim();
    final subtitle = _pollSubtitleController.text.trim().isNotEmpty
        ? _pollSubtitleController.text.trim()
        : 'Kura ya Mashabiki • M-Football Plus';
    final optA = _pollOptionAController.text.trim();
    final optB = _pollOptionBController.text.trim();
    final optC = _pollOptionCController.text.trim();

    final pollItem = {
      'id': id,
      'question': question,
      'subtitle': subtitle,
      'options': [
        {'title': optA, 'color': MColors.scoresCyan},
        {'title': optB, 'color': const Color(0xFF64FFDA)},
        {'title': optC, 'color': MColors.highlightsGold},
      ],
      'votesMap': {0: 10, 1: 5, 2: 8},
    };

    await _adminService.publishPoll(pollItem);
    if (!mounted) return;
    setState(() {});

    _pollQuestionController.clear();
    _pollSubtitleController.clear();
    _pollOptionAController.clear();
    _pollOptionBController.clear();
    _pollOptionCController.clear();

    _showSuccessSnackBar(
      widget.isSwahili
          ? 'Kura Mpya ya Mashabiki imezinduliwa kwenye Firestore!'
          : 'New Fan Poll launched to Firestore in real-time!',
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: MColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E676), width: 1.2),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = widget.isSwahili;

    // ULINZI WA ADMIN: Ni Mmiliki pekee (jofreymlele@gmail.com) anayeruhusiwa
    if (!AuthService().isOwner) {
      return _buildAccessDeniedScreen(isSw);
    }

    return Scaffold(
      backgroundColor: MColors.background,
      appBar: AppBar(
        backgroundColor: MColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MColors.scoresCyan, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isSw ? 'Paneli ya Msimamizi' : 'Admin Panel',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MColors.textWhite,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: MColors.highlightsGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: MColors.highlightsGold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'MMILIKI',
                    style: GoogleFonts.manrope(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: MColors.highlightsGold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Jofrey Mlele (jofreymlele@gmail.com)',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: MColors.textWhite.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MColors.scoresCyan,
          indicatorWeight: 3,
          labelColor: MColors.scoresCyan,
          unselectedLabelColor: MColors.textWhite.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: [
            Tab(icon: const Icon(Icons.newspaper_rounded, size: 19), text: isSw ? 'Habari' : 'Top Story'),
            Tab(icon: const Icon(Icons.record_voice_over_rounded, size: 19), text: isSw ? 'Uchambuzi' : 'Analysis'),
            Tab(icon: const Icon(Icons.how_to_vote_rounded, size: 19), text: isSw ? 'Kura' : 'Polls'),
            Tab(icon: const Icon(Icons.manage_accounts_rounded, size: 19), text: isSw ? 'Akaunti' : 'Account'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoryTab(isSw),
          _buildAnalysisTab(isSw),
          _buildPollTab(isSw),
          _buildAccountTab(isSw),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: FOMU YA KUINGIZA HABARI MPYA (TOP STORY)
  // ==========================================================================
  Widget _buildStoryTab(bool isSw) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          icon: Icons.edit_note_rounded,
          title: isSw ? 'Chapisha Habari Mpya (Top Story)' : 'Publish Top Story',
          subtitle: isSw
              ? 'Habari hii itaonekana mara moja kwenye Dashboard na Ukurasa wa Habari'
              : 'This story will appear immediately on Dashboard and News Feed',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
          ),
          child: Form(
            key: _storyFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _storyTitleSwController,
                  label: isSw ? 'Kichwa cha Habari (Kiswahili) *' : 'Headline (Swahili) *',
                  hint: 'Mfano: Yanga Yatangaza Kikosi cha Maangamizi Kariakoo Derby',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Tafadhali weka kichwa cha habari' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _storyTitleEnController,
                  label: isSw ? 'Kichwa cha Habari (English - Hiari)' : 'Headline (English - Optional)',
                  hint: 'Example: Yanga Announce Lethal Lineup Ahead of Kariakoo Derby',
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _storyImageController,
                  label: isSw ? 'Link ya Picha (Image URL) *' : 'Image URL *',
                  hint: 'https://i.postimg.cc/... au link yoyote halisi ya picha (.jpg, .png, .jpeg)',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isSw ? 'Tafadhali weka link ya picha' : 'Please enter an image URL';
                    }
                    final trimmed = val.trim();
                    final isHttp = trimmed.toLowerCase().startsWith('http://') ||
                        trimmed.toLowerCase().startsWith('https://');
                    if (!isHttp) {
                      return isSw
                          ? 'Link lazima ianze na http:// au https://'
                          : 'URL must start with http:// or https://';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                if (_storyImageController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSw ? 'Muonekano Kamili wa Picha (Preview):' : 'Full Image Preview:',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: MColors.scoresCyan,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MColors.highlightsGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: MColors.highlightsGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          isSw ? 'Urefu 240px • BoxFit.contain' : 'Height 240px • Contain',
                          style: GoogleFonts.manrope(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: MColors.highlightsGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: MColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MColors.scoresCyan.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _storyImageController.text.trim(),
                            fit: BoxFit.contain,
                            alignment: Alignment.topCenter,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(MColors.scoresCyan),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 32),
                                  const SizedBox(height: 6),
                                  Text(
                                    isSw
                                        ? '⚠️ Link hii ya picha haipatikani au imekosewa'
                                        : '⚠️ Image link unavailable or invalid',
                                    style: GoogleFonts.manrope(color: Colors.redAccent, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                Text(
                  isSw ? 'Kategoria ya Habari:' : 'News Category:',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStoryCategory,
                  dropdownColor: MColors.surface,
                  style: GoogleFonts.outfit(color: MColors.textWhite),
                  decoration: _buildInputDecoration(hint: 'Chagua Kategoria'),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(isSw ? 'Zote / Trending' : 'All / Trending')),
                    DropdownMenuItem(value: 'tanzania', child: Text(isSw ? 'NBC Ligi Kuu (Tanzania)' : 'NBC PL (Tanzania)')),
                    DropdownMenuItem(value: 'epl', child: Text('Premier League (Uingereza)')),
                    DropdownMenuItem(value: 'ucl', child: Text('Klabu Bingwa (UCL)')),
                    DropdownMenuItem(value: 'laliga', child: Text('La Liga (Hispania)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStoryCategory = val);
                  },
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _storyDescSwController,
                  label: isSw ? 'Maelezo Kamili ya Habari (Kiswahili) *' : 'Article Description (Swahili) *',
                  hint: 'Andika maelezo ya kina ya habari hii...',
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Tafadhali andika maelezo ya habari' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _storyDescEnController,
                  label: isSw ? 'Maelezo Kamili (English - Hiari)' : 'Article Description (English - Optional)',
                  hint: 'Write detailed English description...',
                  maxLines: 3,
                ),

                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: MColors.scoresCyan,
                  activeTrackColor: MColors.scoresCyan.withValues(alpha: 0.5),
                  value: _isTopTrending,
                  onChanged: (val) => setState(() => _isTopTrending = val),
                  title: Text(
                    isSw ? 'Weka kama Habari Inayovuma (Top Trending)' : 'Set as Top Trending Story',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: MColors.textWhite),
                  ),
                  subtitle: Text(
                    isSw ? 'Itawekwa kwenye kadi kubwa ya juu mwanzo mwa App' : 'Appears in top featured carousel on home feed',
                    style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.5)),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitStory,
                    icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                    label: Text(
                      isSw ? 'CHAPISHA HABARI SASA (FIRESTORE)' : 'PUBLISH TO FIRESTORE',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.scoresCyan,
                      foregroundColor: MColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildRecentAdminStories(isSw),
      ],
    );
  }

  Widget _buildRecentAdminStories(bool isSw) {
    final stories = _adminService.customStories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSw ? 'Habari Zilizochapishwa (Firestore)' : 'Stories in Firestore',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
            ),
            Text(
              '${stories.length} ${isSw ? 'Habari' : 'Stories'}',
              style: GoogleFonts.manrope(fontSize: 11.5, color: MColors.textWhite.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (stories.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                isSw ? 'Bado hujachapisha habari mpya kupitia fomu hii.' : 'No stories published yet.',
                style: GoogleFonts.manrope(fontSize: 12, color: MColors.textWhite.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final story = stories[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        story.imageUrl,
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => Container(
                          width: 55,
                          height: 55,
                          color: MColors.background,
                          child: const Icon(Icons.broken_image, size: 20, color: MColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.titleSw ?? story.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: MColors.textWhite),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${story.category.toUpperCase()} • ${story.publishedAt}',
                            style: GoogleFonts.manrope(fontSize: 10, color: MColors.scoresCyan),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() => _adminService.deleteStory(story.id));
                        _showSuccessSnackBar(isSw ? 'Habari imefutwa.' : 'Story deleted.');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================================================
  // TAB 2: FOMU YA KUINGIZA UCHAMBUZI WA WATAALAM
  // ==========================================================================
  Widget _buildAnalysisTab(bool isSw) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          icon: Icons.record_voice_over_rounded,
          title: isSw ? 'Weka Uchambuzi wa Mchambuzi' : 'Add Expert Tactical Analysis',
          subtitle: isSw
              ? 'Uchambuzi huu utaonekana kwenye Kituo cha Maarifa (Insight Hub)'
              : 'Analysis will appear in the Insight Hub section',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
          ),
          child: Form(
            key: _analysisFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _analystNameController,
                  label: isSw ? 'Jina la Mchambuzi *' : 'Analyst Name *',
                  hint: 'Mfano: Shaffih Dauda au Jofrey Mlele',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Tafadhali weka jina la mchambuzi' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _analystRoleController,
                  label: isSw ? 'Wadhifa / Cheo cha Mchambuzi *' : 'Role / Title *',
                  hint: 'Mfano: Mchambuzi Mwandamizi & Mtaalamu wa Mbinu za Soka',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka wadhifa wa mchambuzi' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _analystAvatarController,
                  label: isSw ? 'Link ya Picha ya Mchambuzi (Avatar URL)' : 'Analyst Avatar URL',
                  hint: 'https://i.postimg.cc/... au link yoyote halisi ya picha (.jpg, .png, .jpeg)',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final trimmed = val.trim();
                    final isHttp = trimmed.toLowerCase().startsWith('http://') ||
                        trimmed.toLowerCase().startsWith('https://');
                    if (!isHttp) {
                      return isSw
                          ? 'Link lazima ianze na http:// au https://'
                          : 'URL must start with http:// or https://';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                if (_analystAvatarController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MColors.background,
                            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Image.network(
                            _analystAvatarController.text.trim(),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: MColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isSw ? 'Muonekano wa Picha ya Mchambuzi' : 'Analyst Avatar Preview',
                        style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _analysisHeadlineController,
                  label: isSw ? 'Kichwa cha Uchambuzi (Headline) *' : 'Analysis Headline *',
                  hint: 'Mfano: Kwanini Mfumo wa 4-3-3 wa Gamondi Ni Hatari kwa Simba',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka kichwa cha uchambuzi' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _analysisMatchController,
                  label: isSw ? 'Mechi au Ligi Husika *' : 'Target Match or League *',
                  hint: 'Mfano: Young Africans vs Simba SC (NBC Ligi Kuu)',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka mechi husika' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _analysisContentController,
                  label: isSw ? 'Aya ya Uchambuzi wa Kimbinu *' : 'Tactical Analysis Content *',
                  hint: 'Eleza kwa undani mbinu, ubora na udhaifu wa timu husika...',
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka maelezo ya uchambuzi' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _analysisTagController,
                  label: isSw ? 'Hashtag / Tag' : 'Hashtag / Tag',
                  hint: '#MbinuZaSoka #KariakooDerby',
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitAnalysis,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      isSw ? 'HIFADHI KWENYE FIRESTORE' : 'SAVE TO FIRESTORE',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.highlightsGold,
                      foregroundColor: MColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildRecentAdminAnalyses(isSw),
      ],
    );
  }

  Widget _buildRecentAdminAnalyses(bool isSw) {
    final analyses = _adminService.customAnalyses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSw ? 'Uchambuzi Uliochapishwa (Firestore)' : 'Analyses in Firestore',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: MColors.scoresCyan),
            ),
            Text(
              '${analyses.length} ${isSw ? 'Wachambuzi' : 'Items'}',
              style: GoogleFonts.manrope(fontSize: 11.5, color: MColors.textWhite.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (analyses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                isSw ? 'Bado hakuna uchambuzi uliowekwa.' : 'No analyses added yet.',
                style: GoogleFonts.manrope(fontSize: 12, color: MColors.textWhite.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: analyses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final a = analyses[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: MColors.background,
                      backgroundImage: NetworkImage(a['avatar'] as String),
                      onBackgroundImageError: (_, __) {},
                      child: const Icon(Icons.person, color: MColors.scoresCyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['name'] as String,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
                          ),
                          Text(
                            a['headlineSw'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: MColors.textWhite),
                          ),
                          Text(
                            a['match'] as String,
                            style: GoogleFonts.manrope(fontSize: 10.5, color: MColors.scoresCyan),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() => _adminService.deleteAnalysis(a['id'] as int));
                        _showSuccessSnackBar(isSw ? 'Uchambuzi umefutwa.' : 'Analysis deleted.');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================================================
  // TAB 3: FOMU YA KUINGIZA KURA ZA MASHABIKI
  // ==========================================================================
  Widget _buildPollTab(bool isSw) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          icon: Icons.how_to_vote_rounded,
          title: isSw ? 'Anzisha Kura Mpya (Firebase Firestore)' : 'Launch Fan Poll to Firestore',
          subtitle: isSw
              ? 'Weka swali na machaguo matatu (A, B, C) ili mashabiki wapige kura'
              : 'Add poll question and 3 selectable options for fans to vote',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
          ),
          child: Form(
            key: _pollFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _pollQuestionController,
                  label: isSw ? 'Swali Kuu la Kura *' : 'Poll Question *',
                  hint: 'Mfano: Nani atashinda Kariakoo Derby msimu huu?',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Tafadhali weka swali la kura' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _pollSubtitleController,
                  label: isSw ? 'Maelezo Mafupi au Ligi' : 'Subtitle or League Context',
                  hint: 'Mfano: Ligi Kuu ya NBC • Benjamin Mkapa Stadium',
                ),
                const SizedBox(height: 16),

                Text(
                  isSw ? 'Machaguo ya Kura (Options A, B, C):' : 'Poll Choices (A, B, C):',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
                ),
                const SizedBox(height: 8),

                _buildTextField(
                  controller: _pollOptionAController,
                  label: isSw ? 'Chaguo A (Option 1) *' : 'Option A *',
                  hint: 'Mfano: Young Africans (Yanga)',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka chaguo A' : null,
                  prefixIcon: const Icon(Icons.looks_one_rounded, color: MColors.scoresCyan, size: 20),
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _pollOptionBController,
                  label: isSw ? 'Chaguo B (Option 2) *' : 'Option B *',
                  hint: 'Mfano: Suluhu (Draw)',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka chaguo B' : null,
                  prefixIcon: const Icon(Icons.looks_two_rounded, color: Color(0xFF64FFDA), size: 20),
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _pollOptionCController,
                  label: isSw ? 'Chaguo C (Option 3) *' : 'Option C *',
                  hint: 'Mfano: Simba SC',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Weka chaguo C' : null,
                  prefixIcon: const Icon(Icons.looks_3_rounded, color: MColors.highlightsGold, size: 20),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitPoll,
                    icon: const Icon(Icons.ballot_rounded, size: 20),
                    label: Text(
                      isSw ? 'ZINDUA KURA KWENYE FIRESTORE' : 'LAUNCH POLL TO FIRESTORE',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: MColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildRecentAdminPolls(isSw),
      ],
    );
  }

  Widget _buildRecentAdminPolls(bool isSw) {
    final polls = _adminService.customPolls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSw ? 'Kura Zilizoundwa (Firestore)' : 'Polls in Firestore',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
            ),
            Text(
              '${polls.length} ${isSw ? 'Kura' : 'Polls'}',
              style: GoogleFonts.manrope(fontSize: 11.5, color: MColors.textWhite.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (polls.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                isSw ? 'Bado hakuna kura maalum uliyounda.' : 'No custom polls created yet.',
                style: GoogleFonts.manrope(fontSize: 12, color: MColors.textWhite.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: polls.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final p = polls[idx];
              final options = p['options'] as List<dynamic>? ?? [];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p['question'] as String,
                            style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: MColors.textWhite),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setState(() => _adminService.deletePoll(p['id'] as int));
                            _showSuccessSnackBar(isSw ? 'Kura imefutwa.' : 'Poll deleted.');
                          },
                        ),
                      ],
                    ),
                    Text(
                      p['subtitle'] as String,
                      style: GoogleFonts.manrope(fontSize: 10.5, color: MColors.textWhite.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: options.map((opt) {
                        return Chip(
                          label: Text(opt['title'] as String),
                          labelStyle: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite),
                          backgroundColor: MColors.background,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================================================
  // TAB 4: KUDHIBITI AKAUNTI YA MMILIKI
  // ==========================================================================
  Widget _buildAccountTab(bool isSw) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MColors.surface,
                MColors.scoresCyan.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MColors.scoresCyan, width: 2),
                  color: MColors.background,
                ),
                child: const Icon(Icons.person, color: MColors.scoresCyan, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Jofrey Mlele',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MColors.textWhite,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 16, color: MColors.scoresCyan),
                      ],
                    ),
                    Text(
                      isSw ? 'Mmiliki & Msimamizi Mkuu' : 'Founder & Lead Administrator',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MColors.highlightsGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AuthService.ownerEmail,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: MColors.scoresCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          isSw ? 'Takwimu za Mfumo & Firestore' : 'System Overview & Firestore',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: MColors.textWhite,
          ),
        ),
        const SizedBox(height: 10),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _buildStatCard(
              title: isSw ? 'Habari Zilizochapishwa' : 'Published Stories',
              value: '${_adminService.customStories.length}',
              icon: Icons.newspaper_rounded,
              color: MColors.scoresCyan,
            ),
            _buildStatCard(
              title: isSw ? 'Uchambuzi wa Wataalam' : 'Expert Analyses',
              value: '${_adminService.customAnalyses.length}',
              icon: Icons.record_voice_over_rounded,
              color: MColors.highlightsGold,
            ),
            _buildStatCard(
              title: isSw ? 'Kura Zilizoundwa' : 'Active Polls',
              value: '${_adminService.customPolls.length}',
              icon: Icons.how_to_vote_rounded,
              color: Colors.purpleAccent,
            ),
            _buildStatCard(
              title: isSw ? 'Hali ya Firestore' : 'Firestore Realtime',
              value: 'Active',
              icon: Icons.cloud_done_rounded,
              color: const Color(0xFF00E676),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          isSw ? 'Vidhibiti vya Kiutawala' : 'Administrative Controls',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: MColors.textWhite,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: MColors.scoresCyan),
                title: Text(
                  isSw ? 'Safisha Kumbukumbu ya Cache' : 'Clear Temporary Cache',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: MColors.textWhite),
                ),
                subtitle: Text(
                  isSw ? 'Inafuta cache ya mechi na msimamo ili kuvuta upya kutoka API' : 'Refreshes cached fixtures & standings from API',
                  style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.5)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: MColors.scoresCyan),
                onTap: () {
                  FootballApiService().clearAllCache();
                  _showSuccessSnackBar(isSw ? 'Kumbukumbu ya Cache imesafishwa kikamilifu!' : 'All caches cleared successfully!');
                },
              ),
              const Divider(color: Color(0x1AFFFFFF), height: 1),
              ListTile(
                leading: const Icon(Icons.security_rounded, color: MColors.highlightsGold),
                title: Text(
                  isSw ? 'Ulinzi wa Mmiliki (Owner Security)' : 'Owner Security Active',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: MColors.textWhite),
                ),
                subtitle: Text(
                  '${AuthService.ownerEmail} pekee anayeweza kuingia hapa',
                  style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.5)),
                ),
                trailing: const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF00E676)),
                onTap: () {
                  _showSuccessSnackBar('Akaunti ya Msimamizi iko salama kwa 100%!');
                },
              ),
              const Divider(color: Color(0x1AFFFFFF), height: 1),
              ListTile(
                leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                title: Text(
                  isSw ? 'Toka kwenye Paneli ya Msimamizi' : 'Exit Admin Panel',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ACCESS DENIED SCREEN (KAMA MTU SIO MMILIKI)
  // ==========================================================================
  Widget _buildAccessDeniedScreen(bool isSw) {
    return Scaffold(
      backgroundColor: MColors.background,
      appBar: AppBar(
        backgroundColor: MColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MColors.scoresCyan, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 2),
                ),
                child: const Icon(Icons.lock_rounded, size: 48, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              Text(
                isSw ? 'Ufikiaji Umezuiwa (Security Alert)' : 'Access Restricted (Security Alert)',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isSw
                    ? 'Sehemu hii ni ya Mmiliki wa App pekee (${AuthService.ownerEmail}). Huna ruhusa ya kuingia kwenye Paneli ya Msimamizi.'
                    : 'This area is restricted to the App Owner (${AuthService.ownerEmail}) only. You do not have administrator permissions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: MColors.textWhite.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(isSw ? 'Rudi Nyuma' : 'Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.scoresCyan,
                  foregroundColor: MColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MColors.scoresCyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: MColors.scoresCyan),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  color: MColors.textWhite.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: MColors.highlightsGold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.outfit(fontSize: 13.5, color: MColors.textWhite),
          decoration: _buildInputDecoration(hint: hint, prefixIcon: prefixIcon),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      hintStyle: GoogleFonts.manrope(fontSize: 12, color: MColors.textWhite.withValues(alpha: 0.35)),
      filled: true,
      fillColor: const Color(0xFF0D1B2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: MColors.scoresCyan.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: MColors.scoresCyan.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MColors.scoresCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }
}
