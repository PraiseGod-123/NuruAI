import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/resource_service.dart';

// ══════════════════════════════════════════════════════════════
// RESOURCES SCREEN
// All data fetching is delegated to ResourceService.
// This screen is purely presentation.
// ══════════════════════════════════════════════════════════════

class _Category {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const _Category({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;

  String _selectedId = 'autism';
  bool _isLoading = false;
  String? _error;
  List<ResourceItem> _items = [];

  final _service = ResourceService.instance;

  static const List<_Category> _categories = [
    _Category(
      id: 'autism',
      label: 'Autism',
      emoji: '🧩',
      color: Color(0xFF5C6BC0),
    ),
    _Category(id: 'adhd', label: 'ADHD', emoji: '⚡', color: Color(0xFFFF7043)),
    _Category(
      id: 'depression',
      label: 'Depression',
      emoji: '🌧️',
      color: Color(0xFF78909C),
    ),
    _Category(id: 'love', label: 'Love', emoji: '💛', color: Color(0xFFFFB300)),
    _Category(
      id: 'baking',
      label: 'Baking',
      emoji: '🥐',
      color: Color(0xFFD4854A),
    ),
    _Category(
      id: 'poems',
      label: 'Poems',
      emoji: '🌸',
      color: Color(0xFFAB47BC),
    ),
  ];

  _Category get _current => _categories.firstWhere((c) => c.id == _selectedId);

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _loadCategory('autism');
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────

  Future<void> _loadCategory(String id, {bool forceRefresh = false}) async {
    setState(() {
      _selectedId = id;
      _isLoading = true;
      _error = null;
      _items = [];
    });

    try {
      if (forceRefresh) _service.clearCache(id);
      final items = await _service.fetchCategory(id);
      if (mounted)
        setState(() {
          _items = items;
          _isLoading = false;
        });
    } on ResourceServiceException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load resources. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1F3F74),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1F3F74),
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4569AD), Color(0xFF14366D)],
                ),
              ),
            ),

            // Stars
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starController,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarsPainter(twinkle: _starController.value),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  _buildCategoryTabs(),
                  const SizedBox(height: 6),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────

  Widget _buildAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1F3F74).withOpacity(0.6),
                const Color(0xFF081F44).withOpacity(0.5),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF4569AD).withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081F44).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4569AD).withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resources',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Books, articles, research & poems',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),

              // Refresh button
              GestureDetector(
                onTap: () => _loadCategory(_selectedId, forceRefresh: true),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081F44).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4569AD).withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category tabs ─────────────────────────────────────────

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 58,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final selected = cat.id == _selectedId;
            return GestureDetector(
              onTap: () => _loadCategory(cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: selected
                        ? [
                            cat.color.withOpacity(0.5),
                            const Color(0xFF081F44).withOpacity(0.7),
                          ]
                        : [
                            const Color(0xFF1F3F74).withOpacity(0.6),
                            const Color(0xFF081F44).withOpacity(0.7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? cat.color.withOpacity(0.7)
                        : const Color(0xFF4569AD).withOpacity(0.3),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: cat.color.withOpacity(0.22),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 7),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_items.isEmpty) return _buildEmpty();

    // Love category gets grouped subcategory sections
    if (_selectedId == 'love') return _buildLoveBody();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        itemCount: _items.length,
        itemBuilder: (_, i) => _buildCard(_items[i]),
      ),
    );
  }

  Widget _buildLoveBody() {
    // Split items into subcategory buckets
    final languages = _items
        .where((i) => i.loveSubcategory == 'love_languages')
        .toList();
    final understand = _items
        .where((i) => i.loveSubcategory == 'understand_partner')
        .toList();
    final commitment = _items
        .where((i) => i.loveSubcategory == 'commitment')
        .toList();
    final other = _items.where((i) => i.loveSubcategory == null).toList();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          if (languages.isNotEmpty) ...[
            _buildSubcategoryHeader(
              '💬',
              'Love Languages',
              'Discover how you and your partner give and receive love',
              const Color(0xFFE91E63),
            ),
            ...languages.map(_buildGuideCard),
            const SizedBox(height: 8),
          ],
          if (understand.isNotEmpty) ...[
            _buildSubcategoryHeader(
              '👂',
              'Understanding Your Partner',
              'Tools to truly know the person you love',
              const Color(0xFF9C27B0),
            ),
            ...understand.map(_buildGuideCard),
            const SizedBox(height: 8),
          ],
          if (commitment.isNotEmpty) ...[
            _buildSubcategoryHeader(
              '🏛️',
              'Staying Committed',
              'Building a relationship that lasts',
              const Color(0xFF3F51B5),
            ),
            ...commitment.map(_buildGuideCard),
            const SizedBox(height: 8),
          ],
          if (other.isNotEmpty) ...[
            _buildSubcategoryHeader(
              '📚',
              'Books & Articles',
              'Further reading on love and relationships',
              const Color(0xFFFFB300),
            ),
            ...other.map(_buildCard),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryHeader(
    String emoji,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            const Color(0xFF081F44).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Guide card — richer layout for NuruAI curated guides ──

  Widget _buildGuideCard(ResourceItem item) {
    final cat = _current;
    // Subcategory accent colour
    final accentColor = item.loveSubcategory == 'love_languages'
        ? const Color(0xFFE91E63)
        : item.loveSubcategory == 'understand_partner'
        ? const Color(0xFF9C27B0)
        : const Color(0xFF3F51B5);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.12),
                  const Color(0xFF081F44).withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081F44).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _typePill(item.type, accentColor),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NuruAI',
                              style: TextStyle(
                                fontSize: 9,
                                color: accentColor.withOpacity(0.8),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Preview first line of body
                      Text(
                        item.description?.split('\n').first ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.38),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: _current.color,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Fetching resources…',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => _loadCategory(_selectedId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4569AD).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4569AD).withOpacity(0.55),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No results found.',
        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
      ),
    );
  }

  // ── Resource card ─────────────────────────────────────────

  Widget _buildCard(ResourceItem item) {
    final cat = _current;
    return GestureDetector(
      onTap: () => _showDetail(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F3F74).withOpacity(0.75),
                  const Color(0xFF081F44).withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF4569AD).withOpacity(0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081F44).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cat.color.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _typePill(item.type, cat.color),
                          const Spacer(),
                          // Source badge
                          Text(
                            item.source,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typePill(ResourceType type, Color color) {
    const labels = {
      ResourceType.book: '📖  Book',
      ResourceType.poem: '🌸  Poem',
      ResourceType.article: '📰  Article',
      ResourceType.research: '🔬  Research',
      ResourceType.guide: '💡  Guide',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(
        labels[type] ?? 'Resource',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Detail sheet ──────────────────────────────────────────

  void _showDetail(ResourceItem item) {
    final cat = _current;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.88,
        minChildSize: 0.35,
        builder: (ctx, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1F3F74).withOpacity(0.96),
                    const Color(0xFF081F44).withOpacity(0.98),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF4569AD).withOpacity(0.4),
                  ),
                ),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cat.color.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _typePill(item.type, cat.color),
                              const SizedBox(height: 5),
                              Text(
                                item.source,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.45),
                                ),
                              ),
                              if (item.author != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.author!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Description / poem
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF081F44).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4569AD).withOpacity(0.28),
                          ),
                        ),
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.75),
                            height: item.type == ResourceType.poem ? 1.9 : 1.55,
                            fontStyle: item.type == ResourceType.poem
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),

                    const SizedBox(height: 22),

                    // CTA button
                    if (item.url != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          // Add url_launcher here: launchUrl(Uri.parse(item.url!))
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cat.color.withOpacity(0.5),
                                const Color(0xFF081F44).withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cat.color.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.type == ResourceType.book
                                    ? 'Open on Open Library'
                                    : item.type == ResourceType.research
                                    ? 'Read on PubMed'
                                    : 'Read full article on Wikipedia',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stars painter ─────────────────────────────────────────────

class _StarsPainter extends CustomPainter {
  final double twinkle;
  const _StarsPainter({required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const stars = [
      [0.08, 0.05],
      [0.22, 0.12],
      [0.40, 0.08],
      [0.58, 0.15],
      [0.72, 0.06],
      [0.88, 0.11],
      [0.14, 0.30],
      [0.35, 0.38],
      [0.55, 0.28],
      [0.75, 0.35],
      [0.92, 0.28],
      [0.20, 0.55],
      [0.48, 0.60],
      [0.68, 0.52],
      [0.85, 0.62],
      [0.10, 0.75],
      [0.38, 0.80],
      [0.62, 0.72],
      [0.80, 0.82],
      [0.95, 0.70],
    ];
    for (final s in stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final offset = (s[0] + s[1]) % 1.0;
      final op = 0.2 + ((twinkle + offset) % 1.0) * 0.35;
      paint.color = Colors.white.withOpacity(op * 0.3);
      canvas.drawCircle(Offset(x, y), 2.8, paint);
      paint.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 1.5, paint);
      paint.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.twinkle != twinkle;
}
