import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart' show MColors;

// ============================================================================
// UKURASA WA HABARI ZA SOKA (NEWS SCREEN - UNIQUE & PREMIUM DESIGN)
// ============================================================================
class NewsCategory {
  final String key;
  final String nameSw;
  final String nameEn;
  final IconData icon;

  const NewsCategory({
    required this.key,
    required this.nameSw,
    required this.nameEn,
    required this.icon,
  });

  String getName(bool isSw) => isSw ? nameSw : nameEn;
}

class NewsScreen extends StatefulWidget {
  final bool isSwahili;
  final VoidCallback? onBackToHome;

  const NewsScreen({
    super.key,
    required this.isSwahili,
    this.onBackToHome,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const List<NewsCategory> _categories = [
    NewsCategory(key: 'all', nameSw: 'Zote', nameEn: 'All News', icon: Icons.public_rounded),
    NewsCategory(key: 'ucl', nameSw: 'Klabu Bingwa', nameEn: 'Champions League', icon: Icons.emoji_events_outlined),
    NewsCategory(key: 'epl', nameSw: 'Uingereza', nameEn: 'Premier League', icon: Icons.sports_soccer),
    NewsCategory(key: 'laliga', nameSw: 'Hispania', nameEn: 'La Liga', icon: Icons.shield_outlined),
    NewsCategory(key: 'transfer', nameSw: 'Usajili & Tetesi', nameEn: 'Transfers', icon: Icons.swap_horiz_rounded),
  ];

  int _selectedCategoryIndex = 0;
  bool _isLoading = false;
  List<NewsArticleModel> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  NewsCategory get _currentCategory => _categories[_selectedCategoryIndex];

  Future<void> _loadNews({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await FootballApiService().getFootballNews(
        category: _currentCategory.key,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        _articles = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onCategorySelected(int index) {
    if (_selectedCategoryIndex != index) {
      setState(() => _selectedCategoryIndex = index);
      _loadNews();
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
            // 1. Kichwa cha Habari (Header)
            _buildHeader(isSw),

            // 2. Makundi ya Habari (Category Selector Chips)
            _buildCategoryTabs(isSw),

            const SizedBox(height: 8),

            // 3. Orodha ya Habari zenye Kadi Kubwa ya Kwanza (Featured Hero)
            Expanded(
              child: RefreshIndicator(
                color: MColors.scoresCyan,
                backgroundColor: MColors.surface,
                onRefresh: () => _loadNews(forceRefresh: true),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: MColors.scoresCyan),
                      )
                    : _articles.isEmpty
                        ? _buildEmptyState(isSw)
                        : _buildNewsList(isSw),
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
                isSw ? 'Habari za Soka' : 'Football News',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, size: 14, color: MColors.highlightsGold),
                const SizedBox(width: 4),
                Text(
                  isSw ? 'Mubashara' : 'Live Feeds',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: MColors.highlightsGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Category Tabs ---
  Widget _buildCategoryTabs(bool isSw) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () => _onCategorySelected(index),
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
                  Icon(
                    cat.icon,
                    size: 14,
                    color: isSelected ? MColors.scoresCyan : MColors.textWhite.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.getName(isSw),
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

  // --- 3. News List with Hero Featured Card ---
  Widget _buildNewsList(bool isSw) {
    final featured = _articles.first;
    final remaining = _articles.skip(1).toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: remaining.length + 1, // +1 kwa Featured Hero Card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildFeaturedHeroCard(featured, isSw);
        }

        final article = remaining[index - 1];
        return _buildArticleTile(article, isSw);
      },
    );
  }

  // Kadi Kubwa ya Kwanza (Featured Hero Card)
  Widget _buildFeaturedHeroCard(NewsArticleModel article, bool isSw) {
    return GestureDetector(
      onTap: () => _showArticleReaderModal(article, isSw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.4), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image yenye fallback
            Positioned.fill(
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: MColors.surface,
                  child: const Center(
                    child: Icon(Icons.newspaper_rounded, size: 48, color: MColors.scoresCyan),
                  ),
                ),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Badges na Headline
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Featured Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MColors.highlightsGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSw ? 'HABARI KUU' : 'TOP STORY',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: MColors.background,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.source,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MColors.textWhite.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Headline Bold Outfit
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description Manrope
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: MColors.textWhite.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kadi ya Habari za Kawaida (List Tile with Thumbnail)
  Widget _buildArticleTile(NewsArticleModel article, bool isSw) {
    return GestureDetector(
      onTap: () => _showArticleReaderModal(article, isSw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MColors.scoresCyan.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 95,
                height: 80,
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: MColors.background,
                    child: const Icon(Icons.sports_soccer, size: 24, color: MColors.scoresCyan),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Source Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MColors.scoresCyan.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.category,
                          style: GoogleFonts.manrope(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: MColors.scoresCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          article.source,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            color: MColors.textWhite.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Headline in Outfit
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: MColors.textWhite,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description in Manrope
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: MColors.textWhite.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modal Bottom Sheet ya Kusoma Habari Kamili ---
  void _showArticleReaderModal(NewsArticleModel article, bool isSw) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: MColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: MColors.scoresCyan, width: 1.6),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: MColors.textWhite.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Article Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: MColors.background,
                      child: const Center(
                        child: Icon(Icons.newspaper_rounded, size: 40, color: MColors.scoresCyan),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Source & Category Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MColors.scoresCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.source,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: MColors.scoresCyan,
                      ),
                    ),
                  ),
                  Text(
                    isSw ? 'Habari ya Uhakika' : 'Verified Sports Report',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: MColors.highlightsGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Full Title
              Text(
                article.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Full Description
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    article.description.isNotEmpty
                        ? article.description
                        : (isSw
                            ? 'Maelezo kamili ya habari hii yanapatikana kwenye mtandao rasmi wa ripoti hii ya soka.'
                            : 'Full details of this report are available on the official sports publication.'),
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      color: MColors.textWhite.withValues(alpha: 0.85),
                      height: 1.55,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.scoresCyan,
                        foregroundColor: MColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isSw ? 'Sawa, Nimeelewa' : 'Done',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSw) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.newspaper_rounded, size: 48, color: MColors.scoresCyan),
          const SizedBox(height: 12),
          Text(
            isSw ? 'Hakuna habari zilizopatikana kwa sasa' : 'No news articles available',
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
        ],
      ),
    );
  }
}
