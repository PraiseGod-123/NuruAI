import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../services/poetry_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// ══════════════════════════════════════════════════════════════
// POETRY CORNER SCREEN
// ══════════════════════════════════════════════════════════════

class PoetryCornerScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const PoetryCornerScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<PoetryCornerScreen> createState() => _PoetryCornerScreenState();
}

class _PoetryCornerScreenState extends State<PoetryCornerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;

  bool _loading = false;
  String? _error;
  List<Poem> _poems = [];
  String _mood = 'all';

  final _svc = PoetryService.instance;

  // Mood colours as Flutter Colors (mirrors poetry_service.dart values)
  static const Map<String, Color> _moodColors = {
    'all': Color(0xFF8EA2D7),
    'calm': Color(0xFF6C5CE7),
    'hopeful': Color(0xFFFDCB6E),
    'nature': Color(0xFF00B894),
    'selfworth': Color(0xFFE84393),
    'short': Color(0xFF55EFC4),
  };

  static const Map<String, String> _moodEmojis = {
    'all': '📚',
    'calm': '🌙',
    'hopeful': '🌅',
    'nature': '🌿',
    'selfworth': '💙',
    'short': '✨',
  };

  static const Map<String, String> _moodLabels = {
    'all': 'All Poems',
    'calm': 'Calm',
    'hopeful': 'Hopeful',
    'nature': 'Nature',
    'selfworth': 'Self-Worth',
    'short': 'Quick Read',
  };

  Color get _currentColor =>
      _moodColors[_mood] ?? context.nuruTheme.accentColor.withOpacity(0.4);

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _poems = [];
    });
    try {
      final poems = await _svc.fetchMood(_mood, forceRefresh: forceRefresh);
      if (mounted)
        setState(() {
          _poems = poems;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Could not load poems. Check your connection.';
          _loading = false;
        });
    }
  }

  void _switchMood(String id) {
    if (id == _mood) return;
    setState(() => _mood = id);
    _load();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF081F44),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF081F44),
        body: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.nuruTheme.gradientColors,
                ),
              ),
            ),
            // Stars
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarsPainter(twinkle: _starCtrl.value),
                ),
              ),
            ),
            // Content
            SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  _buildMoodTabs(),
                  SizedBox(height: 6),
                  Expanded(
                    child: RefreshIndicator(
                      color: _currentColor,
                      backgroundColor: context.nuruTheme.backgroundMid,
                      onRefresh: () => _load(forceRefresh: true),
                      child: _buildBody(),
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

  // App bar

  Widget _buildAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 12,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF081F44),
            border: Border(
              bottom: BorderSide(
                color: context.nuruTheme.accentColor.withOpacity(0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: _iconBtn(Icons.arrow_back_ios_new_rounded, 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Poetry Corner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Words that heal and hold',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _load(forceRefresh: true),
                child: _iconBtn(Icons.refresh_rounded, 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, double size) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFF081F44),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: context.nuruTheme.accentColor.withOpacity(0.5),
        width: 1.2,
      ),
    ),
    child: Icon(icon, color: Colors.white, size: size),
  );

  //  Mood tabs

  Widget _buildMoodTabs() {
    final moodIds = ['all', 'calm', 'hopeful', 'nature', 'selfworth', 'short'];
    return SizedBox(
      height: 58,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: moodIds.length,
          itemBuilder: (_, i) {
            final id = moodIds[i];
            final sel = id == _mood;
            final col = _moodColors[id]!;
            return GestureDetector(
              onTap: () => _switchMood(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sel
                        ? [
                            col.withOpacity(0.45),
                            context.nuruTheme.backgroundStart.withOpacity(0.75),
                          ]
                        : [
                            context.nuruTheme.backgroundMid.withOpacity(0.6),
                            context.nuruTheme.backgroundStart.withOpacity(0.75),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel
                        ? col.withOpacity(0.7)
                        : context.nuruTheme.accentColor.withOpacity(0.3),
                    width: sel ? 1.5 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: col.withOpacity(0.22),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _moodEmojis[id]!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _moodLabels[id]!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel
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

  // Body

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_poems.isEmpty) return _buildEmpty();
    return _buildPoemList();
  }

  Widget _buildPoemList() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        itemCount: _poems.length,
        itemBuilder: (_, i) => _buildPoemCard(_poems[i]),
      ),
    );
  }

  //  Poem card

  Widget _buildPoemCard(Poem poem) {
    final col =
        _moodColors[poem.mood] ??
        context.nuruTheme.accentColor.withOpacity(0.4);

    return GestureDetector(
      onTap: () => _openPoem(poem),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  col.withOpacity(0.08),
                  context.nuruTheme.backgroundStart.withOpacity(0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: col.withOpacity(0.30), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081F44),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poem.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'by ${poem.author}',
                              style: TextStyle(
                                fontSize: 12,
                                color: col.withOpacity(0.85),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mood badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: col.withOpacity(0.35)),
                        ),
                        child: Text(
                          '${poem.moodEmoji} ${poem.lineCount} lines',
                          style: TextStyle(
                            fontSize: 10,
                            color: col,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Divider
                  Container(height: 1, color: col.withOpacity(0.18)),

                  const SizedBox(height: 14),

                  // Preview lines
                  Text(
                    poem.preview,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withOpacity(0.70),
                      height: 1.85,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Read more prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Read full poem',
                        style: TextStyle(
                          fontSize: 11,
                          color: col.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: col.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FULL POEM READING SHEET
  // ══════════════════════════════════════════════════════════

  void _openPoem(Poem poem) {
    final col =
        _moodColors[poem.mood] ??
        context.nuruTheme.accentColor.withOpacity(0.4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        maxChildSize: 0.96,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                // Mood-tinted dark gradient
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(context.nuruTheme.backgroundMid, col, 0.12) ??
                        context.nuruTheme.backgroundMid,
                    context.nuruTheme.backgroundStart.withOpacity(0.99),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(color: col.withOpacity(0.5), width: 1.5),
                ),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Mood badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: col.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: col.withOpacity(0.4)),
                              ),
                              child: Text(
                                '${poem.moodEmoji}  ${_moodLabels[poem.mood] ?? poem.mood}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: col,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Title
                            Text(
                              poem.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.25,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Author
                            Text(
                              'by ${poem.author}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: col.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Decorative divider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 1,
                                  color: col.withOpacity(0.3),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  poem.moodEmoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 32,
                                  height: 1,
                                  color: col.withOpacity(0.3),
                                ),
                              ],
                            ),

                            SizedBox(height: 32),

                            // Full poem text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.nuruTheme.backgroundStart
                                    .withOpacity(0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: col.withOpacity(0.20),
                                ),
                              ),
                              child: Text(
                                poem.fullText,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  color: Colors.white.withOpacity(0.88),
                                  height: 2.1,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.15,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Line count + source
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${poem.lineCount} lines',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                Text(
                                  'PoetryDB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 48),
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

  // States

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            color: _currentColor,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Finding poems…',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📜', style: TextStyle(fontSize: 44)),
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
          SizedBox(height: 18),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: context.nuruTheme.accentColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.nuruTheme.accentColor.withOpacity(0.55),
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

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🌸', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        Text(
          'No poems found for this mood.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _switchMood('all'),
          child: Text(
            'See all poems',
            style: TextStyle(
              color: context.nuruTheme.accentColor.withOpacity(0.4),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: context.nuruTheme.accentColor.withOpacity(0.4),
            ),
          ),
        ),
      ],
    ),
  );
}

// Stars

class _StarsPainter extends CustomPainter {
  final double twinkle;
  const _StarsPainter({required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
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
      final off = (s[0] + s[1]) % 1.0;
      final op = 0.2 + ((twinkle + off) % 1.0) * 0.35;
      p.color = Colors.white.withOpacity(op * 0.3);
      canvas.drawCircle(Offset(x, y), 2.8, p);
      p.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 1.5, p);
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.twinkle != twinkle;
}
