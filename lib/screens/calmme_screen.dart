import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';
import '../services/firebase_service.dart';

class CalmMeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const CalmMeScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<CalmMeScreen> createState() => _CalmMeScreenState();
}

class _CalmMeScreenState extends State<CalmMeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;
  late AnimationController _starController;

  int _currentNavIndex = 1;
  int _feelingLevel = 0;

  // ── Todo state ────────────────────────────────────────────
  final List<_TodoItem> _todos = [];
  final TextEditingController _todoController = TextEditingController();
  String _todoFilter = 'Today'; // 'Today' or 'This Week'

  @override
  void initState() {
    super.initState();
    _floatController1 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _floatController2 = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _floatController3 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _starController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _loadTodos();
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _starController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  // ── Todo helpers ──────────────────────────────────────────

  void _addTodo() {
    final text = _todoController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _todos.insert(
        0,
        _TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          createdAt: DateTime.now(),
          filter: _todoFilter,
        ),
      );
      _todoController.clear();
    });
    _saveTodos();
  }

  void _toggleTodo(String id) {
    setState(() {
      final i = _todos.indexWhere((t) => t.id == id);
      if (i != -1) _todos[i] = _todos[i].copyWith(done: !_todos[i].done);
    });
    _saveTodos();
  }

  void _deleteTodo(String id) {
    setState(() => _todos.removeWhere((t) => t.id == id));
    _saveTodos();
  }

  Future<void> _saveTodos() async {
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isEmpty) return;
    try {
      await NuruFirebaseService.instance.updateUserProfile(
        uid: uid,
        fields: {'todos': _todos.map((t) => t.toMap()).toList()},
      );
    } catch (_) {}
  }

  Future<void> _loadTodos() async {
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isEmpty) return;
    try {
      final data = await NuruFirebaseService.instance.getUserData(uid);
      final saved = data?['todos'];
      if (saved is List && mounted) {
        setState(() {
          _todos.clear();
          _todos.addAll(
            saved.map((e) => _TodoItem.fromMap(e as Map<String, dynamic>)),
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.nuruTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF4569AD),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [Color(0xFF4569AD), Color(0xFF14366D)],
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _floatController1,
                  _floatController2,
                  _floatController3,
                ]),
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _CalmShapesPainter(
                    animation1: _floatController1.value,
                    animation2: _floatController2.value,
                    animation3: _floatController3.value,
                    accentColor: const Color(0xFF4569AD),
                    bgColor: const Color(0xFF081F44),
                    bgEnd: const Color(0xFF14366D),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starController,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _CalmStarsPainter(twinkle: _starController.value),
                ),
              ),
            ),
            SafeArea(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 16),
                      _buildSOS(theme),
                      const SizedBox(height: 20),
                      _buildSectionLabel('How am I feeling?'),
                      const SizedBox(height: 12),
                      _buildTrafficLight(theme),
                      if (_feelingLevel > 0) ...[
                        const SizedBox(height: 12),
                        _buildFeelingContext(),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionLabel('Quick Access'),
                      const SizedBox(height: 12),
                      _buildQuickAccess(theme),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Right Now'),
                      const SizedBox(height: 12),
                      _buildMeltdownCard(theme),
                      const SizedBox(height: 12),
                      _buildSensoryToolkitCard(theme),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Self-Help'),
                      const SizedBox(height: 12),
                      _buildResourceGrid(theme),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Explore'),
                      const SizedBox(height: 12),
                      _buildMusicCard(theme),
                      const SizedBox(height: 12),
                      _buildPoetryGamesRow(theme),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Support Tools'),
                      const SizedBox(height: 12),
                      _buildSocialScriptsCard(theme),
                      const SizedBox(height: 12),
                      _buildSpecialInterestCard(theme),
                      const SizedBox(height: 24),
                      _buildSectionLabel('My Goals & To-Dos'),
                      const SizedBox(height: 12),
                      _buildTodoSection(theme),
                      const SizedBox(height: 24),
                      _buildNuruAICard(theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(theme),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(dynamic theme) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1F3F74).withOpacity(0.75),
                Color(0xFF081F44).withOpacity(0.80),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF4569AD).withOpacity(0.45),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4569AD).withOpacity(0.5),
                      Color(0xFF081F44).withOpacity(0.80),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF4569AD).withOpacity(0.55),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CalmMe',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your safe space',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SOS ───────────────────────────────────────────────────
  Widget _buildSOS(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/sos', arguments: widget.userData),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F3F74).withOpacity(0.75),
                    Color(0xFF081F44).withOpacity(0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFF4569AD).withOpacity(0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF081F44).withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1F3F74).withOpacity(0.75),
                      border: Border.all(
                        color: const Color(0xFF4569AD),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4569AD).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Color(0xFF081F44).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "I'm overwhelmed right now",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap for immediate calm — no reading needed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF6B6B).withOpacity(0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Traffic light ─────────────────────────────────────────
  Widget _buildTrafficLight(dynamic theme) {
    final feelings = [
      {
        'level': 1,
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'label': 'Good',
        'color': const Color(0xFF00B894),
      },
      {
        'level': 2,
        'icon': Icons.sentiment_neutral_rounded,
        'label': 'Okay',
        'color': const Color(0xFFFDCB6E),
      },
      {
        'level': 3,
        'icon': Icons.sentiment_very_dissatisfied_rounded,
        'label': 'Struggling',
        'color': const Color(0xFFFF7675),
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: feelings.map((f) {
          final level = f['level'] as int;
          final color = f['color'] as Color;
          final sel = _feelingLevel == level;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _feelingLevel = sel ? 0 : level);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    colors: sel
                        ? [
                            Color(0xFF4569AD).withOpacity(0.55),
                            Color(0xFF081F44).withOpacity(0.75),
                          ]
                        : [
                            Color(0xFF1F3F74).withOpacity(0.6),
                            Color(0xFF081F44).withOpacity(0.80),
                          ],
                  ),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF4569AD)
                        : Color(0xFF4569AD).withOpacity(0.35),
                    width: sel ? 2 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: Color(0xFF4569AD).withOpacity(0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: sel ? 30 : 24,
                      color: color.withOpacity(sel ? 1.0 : 0.7),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
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

  Widget _buildFeelingContext() {
    final contexts = {
      1: {
        'text': 'Great! Keep going.',
        'color': const Color(0xFF00B894),
        'icon': Icons.star_rounded,
      },
      2: {
        'text': 'Try breathing or music.',
        'color': const Color(0xFFFDCB6E),
        'icon': Icons.spa_outlined,
      },
      3: {
        'text': 'Try the SOS button above.',
        'color': const Color(0xFFFF7675),
        'icon': Icons.favorite_outline_rounded,
      },
    };
    final ctx = contexts[_feelingLevel]!;
    final color = ctx['color'] as Color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(ctx['icon'] as IconData, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ctx['text'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.78),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick access ──────────────────────────────────────────
  Widget _buildQuickAccess(dynamic theme) {
    final items = [
      {
        'icon': Icons.book_outlined,
        'label': 'Journal',
        'route': '/journal',
        'color': const Color(0xFF8EA2D7),
      },
      {
        'icon': Icons.air_rounded,
        'label': 'Breathe',
        'route': '/breathing',
        'color': const Color(0xFF43C6AC),
      },
      {
        'icon': Icons.music_note_rounded,
        'label': 'Music',
        'route': '/music',
        'color': const Color(0xFF6C5CE7),
      },
      {
        'icon': Icons.auto_stories_outlined,
        'label': 'Poetry',
        'route': '/poetry-corner',
        'color': const Color(0xFFB7C3E8),
      },
      {
        'icon': Icons.games_outlined,
        'label': 'Games',
        'route': '/calming-games',
        'color': const Color(0xFF80C4B7),
      },
      {
        'icon': Icons.emoji_emotions_outlined,
        'label': 'Anger',
        'route': '/anger-management',
        'color': const Color(0xFFFA709A),
      },
      {
        'icon': Icons.self_improvement_rounded,
        'label': 'Self Control',
        'route': '/self-control',
        'color': const Color(0xFF00B894),
      },
      {
        'icon': Icons.waves_rounded,
        'label': 'Stress',
        'route': '/stress-relief',
        'color': const Color(0xFF0984E3),
      },
    ];
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final color = item['color'] as Color;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, item['route'] as String),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1F3F74).withOpacity(0.75),
                      border: Border.all(
                        color: const Color(0xFF4569AD),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4569AD).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Color(0xFF081F44).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Meltdown card ─────────────────────────────────────────
  Widget _buildMeltdownCard(dynamic theme) {
    final levelInfo = {
      1: {
        'label': 'Calm',
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'tip': "You're doing well.",
        'color': const Color(0xFF00B894),
      },
      2: {
        'label': 'Slightly tense',
        'icon': Icons.sentiment_neutral_rounded,
        'tip': 'Try a breathing exercise.',
        'color': const Color(0xFF43C6AC),
      },
      3: {
        'label': 'Stressed',
        'icon': Icons.sentiment_dissatisfied_rounded,
        'tip': 'Mindfulness or music may help.',
        'color': const Color(0xFFFDCB6E),
      },
      4: {
        'label': 'Very activated',
        'icon': Icons.sentiment_very_dissatisfied_rounded,
        'tip': 'Try anger management tools.',
        'color': const Color(0xFFE17055),
      },
      5: {
        'label': 'Overwhelmed',
        'icon': Icons.crisis_alert_rounded,
        'tip': 'Press the SOS button above.',
        'color': const Color(0xFFFF7675),
      },
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _MeltdownCard(
        levelInfo: levelInfo,
        theme: theme,
        onSOS: () =>
            Navigator.pushNamed(context, '/sos', arguments: widget.userData),
        onAnger: () => Navigator.pushNamed(
          context,
          '/anger-management',
          arguments: widget.userData,
        ),
        onBreathe: () => Navigator.pushNamed(
          context,
          '/breathing',
          arguments: widget.userData,
        ),
        onMindful: () => Navigator.pushNamed(
          context,
          '/mindfulness',
          arguments: widget.userData,
        ),
      ),
    );
  }

  // ── Sensory toolkit ───────────────────────────────────────
  Widget _buildSensoryToolkitCard(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/sensory-toolkit',
          arguments: widget.userData,
        ),
        child: _glassCard(
          theme: theme,
          accent: const Color(0xFFA29BFE),
          child: Row(
            children: [
              _iconCircle(
                theme: theme,
                icon: Icons.headphones_outlined,
                color: const Color(0xFFA29BFE),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensory Toolkit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "What's overwhelming me right now? Quick relief tools.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFA29BFE).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Resource grid ─────────────────────────────────────────
  Widget _buildResourceGrid(dynamic theme) {
    final resources = [
      {
        'title': 'Anger Management',
        'icon': Icons.emoji_emotions_outlined,
        'colour': const Color(0xFFFA709A),
        'route': '/anger-management',
      },
      {
        'title': 'Self Control',
        'icon': Icons.self_improvement_rounded,
        'colour': const Color(0xFF43C6AC),
        'route': '/self-control',
      },
      {
        'title': 'Stress Relief',
        'icon': Icons.waves_rounded,
        'colour': const Color(0xFF0984E3),
        'route': '/stress-relief',
      },
      {
        'title': 'Mindfulness',
        'icon': Icons.psychology_outlined,
        'colour': const Color(0xFFB7C3E8),
        'route': '/mindfulness',
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: resources.map((r) {
          final colour = r['colour'] as Color;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, r['route'] as String),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1F3F74).withOpacity(0.75),
                        Color(0xFF081F44).withOpacity(0.88),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF4569AD).withOpacity(0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF081F44).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconCircle(
                        theme: theme,
                        icon: r['icon'] as IconData,
                        color: colour,
                        size: 52,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Music card ────────────────────────────────────────────
  Widget _buildMusicCard(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/music', arguments: widget.userData),
        child: _glassCard(
          theme: theme,
          accent: Color(0xFF4569AD).withOpacity(0.4),
          child: Row(
            children: [
              _iconCircle(
                theme: theme,
                icon: Icons.music_note_rounded,
                color: Color(0xFF4569AD).withOpacity(0.4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Music Library',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lofi, calming music · Voice recordings · Favourites',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF4569AD).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Poetry + Games row ────────────────────────────────────
  Widget _buildPoetryGamesRow(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/poetry-corner',
                arguments: widget.userData,
              ),
              child: _smallCardIcon(
                theme: theme,
                icon: Icons.auto_stories_outlined,
                title: 'Poetry Corner',
                sub: 'Calming poems',
                color: const Color(0xFFB7C3E8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/calming-games'),
              child: _smallCardIcon(
                theme: theme,
                icon: Icons.games_outlined,
                title: 'Calming Games',
                sub: '5 relaxing games',
                color: const Color(0xFF80C4B7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Social scripts ────────────────────────────────────────
  Widget _buildSocialScriptsCard(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/social-scripts',
          arguments: widget.userData,
        ),
        child: _glassCard(
          theme: theme,
          accent: const Color(0xFF74B9FF),
          child: Row(
            children: [
              _iconCircle(
                theme: theme,
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF74B9FF),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Social Scripts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pre-written words for difficult social moments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF74B9FF).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Special interest ──────────────────────────────────────
  Widget _buildSpecialInterestCard(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/special-interest',
          arguments: widget.userData,
        ),
        child: _glassCard(
          theme: theme,
          accent: const Color(0xFFFFD32A),
          child: Row(
            children: [
              _iconCircle(
                theme: theme,
                icon: Icons.star_outline_rounded,
                color: const Color(0xFFFFD32A),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Special Interest',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your personal calm space — explore what you love',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFFFD32A).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── NuruAI card ───────────────────────────────────────────
  // ── Todo Section ──────────────────────────────────────────
  Widget _buildTodoSection(dynamic theme) {
    final filtered = _todos.where((t) => t.filter == _todoFilter).toList();
    final pending = filtered.where((t) => !t.done).toList();
    final done = filtered.where((t) => t.done).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F3F74).withOpacity(0.75),
                  const Color(0xFF081F44).withOpacity(0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4569AD).withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'My To-Dos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Filter toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4569AD).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Today', 'This Week'].map((f) {
                          final active = _todoFilter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _todoFilter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF4569AD).withOpacity(0.5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input field
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4569AD).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: Color(0xFF4569AD),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: const TextSelectionThemeData(
                              cursorColor: Colors.white70,
                              selectionColor: Color(0x444569AD),
                            ),
                          ),
                          child: TextField(
                            controller: _todoController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            cursorColor: Colors.white70,
                            decoration: const InputDecoration(
                              hintText: 'Add a goal or task...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.white38,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            maxLines: 1,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addTodo(),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _addTodo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4569AD).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pending todos
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...pending.map((todo) => _buildTodoTile(todo)),
                ],

                // Done todos
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Completed (${done.length})',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...done.map((todo) => _buildTodoTile(todo)),
                ],

                // Empty state
                if (filtered.isEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _todoFilter == 'Today'
                          ? 'No tasks for today yet.\nAdd something you want to achieve!'
                          : 'No tasks for this week yet.\nSet a goal to work towards!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.45),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoTile(_TodoItem todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTodo(todo.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.done
                    ? const Color(0xFF4569AD).withOpacity(0.7)
                    : Colors.transparent,
                border: Border.all(
                  color: todo.done
                      ? const Color(0xFF4569AD)
                      : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: todo.done
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              todo.text,
              style: TextStyle(
                fontSize: 14,
                color: todo.done ? Colors.white.withOpacity(0.4) : Colors.white,
                decoration: todo.done ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteTodo(todo.id),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNuruAICard(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/nuru-ai',
          arguments: widget.userData,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C5CE7).withOpacity(0.28),
                    Color(0xFF081F44).withOpacity(0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Color(0xFF6C5CE7).withOpacity(0.50),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C5CE7).withOpacity(0.18),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Color(0xFF081F44).withOpacity(0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF6C5CE7).withOpacity(0.45),
                          Color(0xFF6C5CE7).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: Color(0xFF6C5CE7).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_ysrn2iwp.json',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.smart_toy_outlined,
                          color: Color(0xFFA29BFE),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'NuruAI',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF6C5CE7).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Color(0xFF6C5CE7).withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFA29BFE),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Talk to me anytime.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(0xFF6C5CE7).withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFF6C5CE7).withOpacity(0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFA29BFE),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────

  Widget _glassCard({
    required dynamic theme,
    required Color accent,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1F3F74).withOpacity(0.75),
                Color(0xFF081F44).withOpacity(0.80),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF081F44).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _iconCircle({
    required dynamic theme,
    required IconData icon,
    required Color color,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1F3F74).withOpacity(0.75),
        border: Border.all(color: const Color(0xFF4569AD), width: 2.0),
        boxShadow: [
          BoxShadow(color: Color(0xFF4569AD).withOpacity(0.25), blurRadius: 10),
          BoxShadow(
            color: Color(0xFF081F44).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }

  Widget _smallCardIcon({
    required dynamic theme,
    required IconData icon,
    required String title,
    required String sub,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.18),
                Color(0xFF081F44).withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconCircle(theme: theme, icon: icon, color: color, size: 44),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────

  Widget _buildBottomNav(dynamic theme) {
    return Material(
      color: const Color(0xFF081F44),
      child: LayoutBuilder(
        builder: (ctx, constraints) => Stack(
          children: [
            Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.gradientColors,
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -20,
              child: _orb(140, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              right: -30,
              top: -40,
              child: _orb(130, Colors.white.withOpacity(0.10)),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(theme, Icons.home_rounded, 'Home', 0),
                  _buildNavItem(theme, Icons.spa_outlined, 'CalmMe', 1),
                  _buildNavItem(
                    theme,
                    Icons.analytics_outlined,
                    'Analytics',
                    2,
                  ),
                  _buildNavItem(
                    theme,
                    Icons.person_outline_rounded,
                    'Profile',
                    3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color, color.withOpacity(0.3), Colors.transparent],
      ),
    ),
  );

  Widget _buildNavItem(dynamic theme, IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) return;
        if (index == 0) {
          Navigator.pop(context);
          return;
        }
        setState(() => _currentNavIndex = index);
        if (index == 2)
          Navigator.pushNamed(
            context,
            '/analytics',
            arguments: widget.userData,
          ).then((_) {
            if (mounted) setState(() => _currentNavIndex = 1);
          });
        if (index == 3)
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: widget.userData,
          ).then((_) {
            if (mounted) setState(() => _currentNavIndex = 1);
          });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF4569AD).withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Color(0xFF4569AD).withOpacity(0.7), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MELTDOWN CARD — separate StatefulWidget
// Theme passed via constructor — no context.nuruTheme inside
// ══════════════════════════════════════════════════════════════

class _MeltdownCard extends StatefulWidget {
  final Map<int, Map<String, dynamic>> levelInfo;
  final dynamic theme;
  final VoidCallback onSOS, onAnger, onBreathe, onMindful;
  const _MeltdownCard({
    required this.levelInfo,
    required this.theme,
    required this.onSOS,
    required this.onAnger,
    required this.onBreathe,
    required this.onMindful,
  });
  @override
  State<_MeltdownCard> createState() => _MeltdownCardState();
}

class _MeltdownCardState extends State<_MeltdownCard> {
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final info = widget.levelInfo[_level]!;
    final color = info['color'] as Color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1F3F74).withOpacity(0.75),
                Color(0xFF081F44).withOpacity(0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Color(0xFF4569AD).withOpacity(0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF081F44).withOpacity(0.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1F3F74).withOpacity(0.75),
                      border: Border.all(
                        color: const Color(0xFF4569AD),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4569AD).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Color(0xFF081F44).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      info['icon'] as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meltdown Prevention',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          info['label'] as String,
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Level $_level / 5',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  activeTrackColor: color,
                  inactiveTrackColor: Color(0xFF4569AD).withOpacity(0.2),
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                ),
                child: Slider(
                  value: _level.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => setState(() => _level = v.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calm',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  Text(
                    'Overwhelmed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFFDCB6E),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        info['tip'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.78),
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (_level >= 4) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _level == 5
                            ? widget.onSOS
                            : (_level == 4 ? widget.onAnger : widget.onBreathe),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.5)),
                          ),
                          child: Text(
                            'Go →',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAINTERS — NO BuildContext, colours passed as constructor params
// ══════════════════════════════════════════════════════════════

class _CalmStarsPainter extends CustomPainter {
  final double twinkle;
  const _CalmStarsPainter({required this.twinkle});
  static const _stars = [
    [0.08, 0.05],
    [0.18, 0.15],
    [0.25, 0.08],
    [0.35, 0.20],
    [0.42, 0.12],
    [0.52, 0.18],
    [0.62, 0.08],
    [0.72, 0.22],
    [0.78, 0.14],
    [0.88, 0.10],
    [0.12, 0.48],
    [0.28, 0.55],
    [0.38, 0.62],
    [0.50, 0.58],
    [0.65, 0.52],
    [0.75, 0.65],
    [0.85, 0.58],
    [0.15, 0.82],
    [0.45, 0.88],
    [0.92, 0.85],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final op = 0.4 + (twinkle * 0.3);
      p.color = Colors.white.withOpacity(op * 0.4);
      canvas.drawCircle(Offset(x, y), 3.5, p);
      p.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 2.0, p);
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 1.3, p);
    }
  }

  @override
  bool shouldRepaint(_CalmStarsPainter o) => o.twinkle != twinkle;
}

class _CalmShapesPainter extends CustomPainter {
  final double animation1, animation2, animation3;
  final Color accentColor, bgColor, bgEnd;
  const _CalmShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.accentColor,
    required this.bgColor,
    required this.bgEnd,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = accentColor.withOpacity(0.25);
    final oy1 = animation1 * 40 - 20;
    canvas.drawPath(
      Path()
        ..moveTo(0, oy1)
        ..quadraticBezierTo(
          size.width * 0.3,
          size.height * 0.1 + oy1,
          size.width * 0.4,
          size.height * 0.25 + oy1,
        )
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.4 + oy1,
          size.width * 0.3,
          size.height * 0.5 + oy1,
        )
        ..quadraticBezierTo(
          size.width * 0.1,
          size.height * 0.6 + oy1,
          0,
          size.height * 0.4 + oy1,
        )
        ..close(),
      paint,
    );
    paint.color = bgColor.withOpacity(0.2);
    final ox2 = animation2 * 35 - 17;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height * 0.2 + ox2)
        ..quadraticBezierTo(
          size.width * 0.7,
          size.height * 0.3 + ox2,
          size.width * 0.6,
          size.height * 0.5 + ox2,
        )
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.7 + ox2,
          size.width * 0.7,
          size.height * 0.8 + ox2,
        )
        ..quadraticBezierTo(
          size.width * 0.9,
          size.height * 0.9 + ox2,
          size.width,
          size.height * 0.7 + ox2,
        )
        ..close(),
      paint,
    );
    final c1 = Offset(
      size.width * 0.75 + (animation1 * 25 - 12),
      size.height * 0.15 + (animation2 * 20 - 10),
    );
    canvas.drawCircle(
      c1,
      90,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ).createShader(Rect.fromCircle(center: c1, radius: 90)),
    );
    final c2 = Offset(
      size.width * 0.3 + (animation3 * 30 - 15),
      size.height * 0.85 + (animation1 * 20 - 10),
    );
    canvas.drawCircle(
      c2,
      110,
      Paint()
        ..shader = RadialGradient(
          colors: [
            bgEnd.withOpacity(0.35),
            bgEnd.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c2, radius: 110)),
    );
  }

  @override
  bool shouldRepaint(_CalmShapesPainter o) =>
      o.animation1 != animation1 ||
      o.animation2 != animation2 ||
      o.animation3 != animation3 ||
      o.accentColor != accentColor ||
      o.bgColor != bgColor;
}

// ── Todo model ────────────────────────────────────────────────────────────────

class _TodoItem {
  final String id;
  final String text;
  final bool done;
  final DateTime createdAt;
  final String filter; // 'Today' or 'This Week'

  const _TodoItem({
    required this.id,
    required this.text,
    this.done = false,
    required this.createdAt,
    required this.filter,
  });

  _TodoItem copyWith({bool? done}) => _TodoItem(
    id: id,
    text: text,
    done: done ?? this.done,
    createdAt: createdAt,
    filter: filter,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
    'filter': filter,
  };

  factory _TodoItem.fromMap(Map<String, dynamic> m) => _TodoItem(
    id: m['id'] as String,
    text: m['text'] as String,
    done: m['done'] as bool? ?? false,
    createdAt: DateTime.parse(m['createdAt'] as String),
    filter: m['filter'] as String? ?? 'Today',
  );
}
