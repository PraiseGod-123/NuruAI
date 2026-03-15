import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';

// ══════════════════════════════════════════════════════════════
// CALMME SCREEN — Redesigned
//
// Background, stars, blobs, bottom nav: all identical to before.
//
// New layout:
//   1. Header
//   2. SOS button — "I'm overwhelmed right now"
//   3. How am I feeling? — 3-circle traffic light
//   4. Quick Access — horizontal circle scroll
//   5. Right Now — Meltdown Prevention + Sensory Toolkit
//   6. Self-Help Resources — 2×2 grid
//   7. Explore — Music wide + Poetry/Games 2-col
//   8. Support Tools — Social Scripts + Special Interest
// ══════════════════════════════════════════════════════════════

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

  // Traffic light state: 0=none selected, 1=good, 2=okay, 3=struggling
  int _feelingLevel = 0;

  // Palette
  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);
  static const Color _deep = Color(0xFF14366D);
  static const Color _solid = Color(0xFF8EA2D7);
  static const Color _lilac = Color(0xFFB7C3E8);

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
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _starController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1F3F74),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4569AD),
                    Color(0xFF4864B5),
                    Color(0xFF3A5FA8),
                    Color(0xFF2D5295),
                  ],
                ),
              ),
            ),
            // Animated blobs
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _floatController1,
                  _floatController2,
                  _floatController3,
                ]),
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: Animated3DShapesPainter(
                    animation1: _floatController1.value,
                    animation2: _floatController2.value,
                    animation3: _floatController3.value,
                  ),
                ),
              ),
            ),
            // Stars
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starController,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: SubtleStarsPainter(twinkle: _starController.value),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // ── 1. SOS Button ────────────────────────────
                    _buildSOS(),
                    const SizedBox(height: 20),

                    // ── 2. How am I feeling? ─────────────────────
                    _buildSectionLabel('How am I feeling?'),
                    const SizedBox(height: 12),
                    _buildTrafficLight(),
                    if (_feelingLevel > 0) ...[
                      const SizedBox(height: 12),
                      _buildFeelingContext(),
                    ],
                    const SizedBox(height: 24),

                    // ── 3. Quick Access circles ──────────────────
                    _buildSectionLabel('Quick Access'),
                    const SizedBox(height: 12),
                    _buildQuickAccess(),
                    const SizedBox(height: 24),

                    // ── 4. Right Now ─────────────────────────────
                    _buildSectionLabel('Right Now'),
                    const SizedBox(height: 12),
                    _buildMeltdownCard(),
                    const SizedBox(height: 12),
                    _buildSensoryToolkitCard(),
                    const SizedBox(height: 24),

                    // ── 5. Self-Help Resources ───────────────────
                    _buildSectionLabel('Self-Help'),
                    const SizedBox(height: 12),
                    _buildResourceGrid(),
                    const SizedBox(height: 24),

                    // ── 6. Explore ───────────────────────────────
                    _buildSectionLabel('Explore'),
                    const SizedBox(height: 12),
                    _buildMusicCard(),
                    const SizedBox(height: 12),
                    _buildPoetryGamesRow(),
                    const SizedBox(height: 24),

                    // ── 7. Support Tools ─────────────────────────
                    _buildSectionLabel('Support Tools'),
                    const SizedBox(height: 12),
                    _buildSocialScriptsCard(),
                    const SizedBox(height: 12),
                    _buildSpecialInterestCard(),
                    const SizedBox(height: 24),

                    // ── 8. NuruAI Chat ───────────────────────────
                    _buildNuruAICard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════

  Widget _buildHeader() {
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
              colors: [_dive.withOpacity(0.75), _night.withOpacity(0.80)],
            ),
            border: Border(
              bottom: BorderSide(color: _sailing.withOpacity(0.45), width: 1.5),
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
                      _sailing.withOpacity(0.5),
                      _night.withOpacity(0.80),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _sailing.withOpacity(0.55),
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

  // ══════════════════════════════════════════════════════════
  // SOS BUTTON
  // ══════════════════════════════════════════════════════════

  Widget _buildSOS() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/sos'),
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
                  colors: [_dive.withOpacity(0.75), _night.withOpacity(0.88)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _sailing.withOpacity(0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _night.withOpacity(0.5),
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
                      color: const Color(0xFF1F3F74).withOpacity(0.75),
                      border: Border.all(
                        color: const Color(0xFF4569AD),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4569AD).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF081F44).withOpacity(0.4),
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
                    color: const Color(0xFFFF6B6B).withOpacity(0.7),
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

  // ══════════════════════════════════════════════════════════
  // TRAFFIC LIGHT — How am I feeling?
  // ══════════════════════════════════════════════════════════

  Widget _buildTrafficLight() {
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
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    colors: sel
                        ? [_sailing.withOpacity(0.55), _night.withOpacity(0.75)]
                        : [_dive.withOpacity(0.6), _night.withOpacity(0.80)],
                  ),
                  border: Border.all(
                    color: sel ? _sailing : _sailing.withOpacity(0.35),
                    width: sel ? 2 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: _sailing.withOpacity(0.35),
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
                      color: (f['color'] as Color).withOpacity(sel ? 1.0 : 0.7),
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
    final Map<int, Map<String, dynamic>> contexts = {
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
            Icon(
              ctx['icon'] as IconData,
              size: 20,
              color: (ctx['color'] as Color),
            ),
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

  // ══════════════════════════════════════════════════════════
  // QUICK ACCESS — horizontal circle scroll
  // ══════════════════════════════════════════════════════════

  Widget _buildQuickAccess() {
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
                      color: const Color(0xFF1F3F74).withOpacity(0.75),
                      border: Border.all(
                        color: const Color(0xFF4569AD),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4569AD).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF081F44).withOpacity(0.4),
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

  // ══════════════════════════════════════════════════════════
  // MELTDOWN PREVENTION CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildMeltdownCard() {
    // Map level to suggested action
    final Map<int, Map<String, dynamic>> levelInfo = {
      1: {
        'label': 'Calm',
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'tip': 'You\'re doing well.',
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

    // Use _feelingLevel to set initial slider hint but track separately
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _MeltdownCard(
        levelInfo: levelInfo,
        onSOS: () => Navigator.pushNamed(context, '/sos'),
        onAnger: () => Navigator.pushNamed(context, '/anger-management'),
        onBreathe: () => Navigator.pushNamed(context, '/breathing'),
        onMindful: () => Navigator.pushNamed(context, '/mindfulness'),
      ),
    );
  }

  Widget _buildSensoryToolkitCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/sensory-toolkit'),
        child: _glassCard(
          accent: const Color(0xFFA29BFE),
          child: Row(
            children: [
              _iconCircle(Icons.headphones_outlined, const Color(0xFFA29BFE)),
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
                      'What\'s overwhelming me right now? Quick relief tools.',
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
                color: const Color(0xFFA29BFE).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // RESOURCE GRID
  // ══════════════════════════════════════════════════════════

  Widget _buildResourceGrid() {
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
                        _dive.withOpacity(0.75),
                        _night.withOpacity(0.88),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _sailing.withOpacity(0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _night.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1F3F74).withOpacity(0.75),
                          border: Border.all(
                            color: const Color(0xFF4569AD),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4569AD).withOpacity(0.25),
                              blurRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFF081F44).withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          r['icon'] as IconData,
                          color: r['colour'] as Color,
                          size: 26,
                        ),
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

  // ══════════════════════════════════════════════════════════
  // MUSIC CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildMusicCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/music'),
        child: _glassCard(
          accent: _lilac,
          child: Row(
            children: [
              _iconCircle(Icons.music_note_rounded, _lilac),
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
                color: _solid.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // POETRY + GAMES — side by side
  // ══════════════════════════════════════════════════════════

  Widget _buildPoetryGamesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/poetry-corner'),
              child: _smallCardIcon(
                Icons.auto_stories_outlined,
                'Poetry Corner',
                'Calming poems',
                const Color(0xFFB7C3E8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/calming-games'),
              child: _smallCardIcon(
                Icons.games_outlined,
                'Calming Games',
                '5 relaxing games',
                const Color(0xFF80C4B7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(String lottieUrl, String title, String sub, Color color) {
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
              colors: [color.withOpacity(0.18), _night.withOpacity(0.85)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.5),
                      color.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(color: color.withOpacity(0.4), width: 1.2),
                ),
                child: ClipOval(
                  child: Lottie.network(
                    lottieUrl,
                    fit: BoxFit.cover,
                    repeat: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
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

  // ══════════════════════════════════════════════════════════
  // SUPPORT TOOLS
  // ══════════════════════════════════════════════════════════

  Widget _buildSocialScriptsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/social-scripts'),
        child: _glassCard(
          accent: const Color(0xFF74B9FF),
          child: Row(
            children: [
              _iconCircle(
                Icons.chat_bubble_outline_rounded,
                const Color(0xFF74B9FF),
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
                color: const Color(0xFF74B9FF).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialInterestCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/special-interest'),
        child: _glassCard(
          accent: const Color(0xFFFFD32A),
          child: Row(
            children: [
              _iconCircle(Icons.star_outline_rounded, const Color(0xFFFFD32A)),
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
                color: const Color(0xFFFFD32A).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════
  // NURU AI CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildNuruAICard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/nuru-ai');
        },
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
                    const Color(0xFF6C5CE7).withOpacity(0.28),
                    _night.withOpacity(0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacity(0.50),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.18),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: _night.withOpacity(0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Lottie circle
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C5CE7).withOpacity(0.45),
                          const Color(0xFF4E54C8).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.5),
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
                                color: const Color(
                                  0xFF6C5CE7,
                                ).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withOpacity(0.5),
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
                      color: const Color(0xFF6C5CE7).withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.45),
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

  // ── Lottie circle widget ─────────────────────────────────
  Widget _lottieCircle(String url, Color color, {double size = 58}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.45),
            color.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
      ),
      child: ClipOval(
        child: Lottie.network(
          url,
          fit: BoxFit.cover,
          repeat: true,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.circle_outlined, color: color, size: size * 0.45),
        ),
      ),
    );
  }

  // ── Lottie icon for cards (no circle border) ──────────────
  Widget _lottieIcon(String url, Color color, {double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.50),
            color.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
      ),
      child: ClipOval(
        child: Lottie.network(
          url,
          fit: BoxFit.cover,
          repeat: true,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.circle_outlined, color: color, size: size * 0.45),
        ),
      ),
    );
  }

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

  Widget _glassCard({required Color accent, required Widget child}) {
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
              colors: [_dive.withOpacity(0.75), _night.withOpacity(0.80)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _night.withOpacity(0.5),
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

  Widget _iconCircle(IconData icon, Color color, {double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1F3F74).withOpacity(0.75),
        border: Border.all(color: const Color(0xFF4569AD), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4569AD).withOpacity(0.25),
            blurRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF081F44).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }

  Widget _smallCardIcon(IconData icon, String title, String sub, Color color) {
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
              colors: [color.withOpacity(0.18), _night.withOpacity(0.85)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconCircle(icon, color, size: 44),
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

  // ══════════════════════════════════════════════════════════
  // BOTTOM NAV — identical to before
  // ══════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return Material(
      color: _night,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Container(
              height: 75,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F3F74),
                    Color(0xFF081F44),
                    Color(0xFF081F44),
                    Color(0xFF0D2550),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
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
            Container(
              height: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', 0),
                  _buildNavItem(Icons.spa_outlined, 'CalmMe', 1),
                  _buildNavItem(Icons.analytics_outlined, 'Analytics', 2),
                  _buildNavItem(Icons.person_outline_rounded, 'Profile', 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
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
          Navigator.pushNamed(context, '/analytics').then((_) {
            if (mounted) setState(() => _currentNavIndex = 1);
          });
        if (index == 3)
          Navigator.pushNamed(context, '/profile').then((_) {
            if (mounted) setState(() => _currentNavIndex = 1);
          });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4569AD).withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF4569AD).withOpacity(0.7),
                  width: 2,
                )
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
// MELTDOWN PREVENTION CARD — stateful widget
// ══════════════════════════════════════════════════════════════

class _MeltdownCard extends StatefulWidget {
  final Map<int, Map<String, dynamic>> levelInfo;
  final VoidCallback onSOS, onAnger, onBreathe, onMindful;
  const _MeltdownCard({
    required this.levelInfo,
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

  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);

  @override
  Widget build(BuildContext context) {
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
              colors: [_dive.withOpacity(0.75), _night.withOpacity(0.88)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _sailing.withOpacity(0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _night.withOpacity(0.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F3F74).withOpacity(0.75),
                      border: Border.all(
                        color: const Color(0xFF4569AD),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4569AD).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF081F44).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      info['icon'] as IconData,
                      color: (info['color'] as Color),
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
                          'How activated am I right now?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${info['label']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5-step level selector
              Row(
                children: List.generate(5, (i) {
                  final lvl = i + 1;
                  final sel = _level == lvl;
                  final dotColors = [
                    const Color(0xFF00B894),
                    const Color(0xFF43C6AC),
                    const Color(0xFFFDCB6E),
                    const Color(0xFFE17055),
                    const Color(0xFFFF7675),
                  ];
                  final dc = dotColors[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _level = lvl);
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: sel ? 44 : 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: sel
                                ? [dc.withOpacity(0.5), _night.withOpacity(0.7)]
                                : [
                                    _dive.withOpacity(0.5),
                                    _night.withOpacity(0.7),
                                  ],
                          ),
                          border: Border.all(
                            color: sel
                                ? dc.withOpacity(0.8)
                                : _sailing.withOpacity(0.3),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$lvl',
                            style: TextStyle(
                              fontSize: sel ? 16 : 13,
                              fontWeight: sel
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 14),

              // Suggestion
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
// PAINTERS — identical to before
// ══════════════════════════════════════════════════════════════

class SubtleStarsPainter extends CustomPainter {
  final double twinkle;
  SubtleStarsPainter({required this.twinkle});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stars = [
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
    for (final star in stars) {
      final x = size.width * star[0];
      final y = size.height * star[1];
      final opacity = 0.4 + (twinkle * 0.3);
      paint.color = Colors.white.withOpacity(opacity * 0.4);
      canvas.drawCircle(Offset(x, y), 3.5, paint);
      paint.color = Colors.white.withOpacity(opacity * 0.6);
      canvas.drawCircle(Offset(x, y), 2.0, paint);
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(SubtleStarsPainter old) => old.twinkle != twinkle;
}

class Animated3DShapesPainter extends CustomPainter {
  final double animation1, animation2, animation3;
  Animated3DShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFB7C3E8).withOpacity(0.25);
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
    paint.color = const Color(0xFF081F44).withOpacity(0.2);
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
    canvas.drawCircle(
      Offset(
        size.width * 0.75 + (animation1 * 25 - 12),
        size.height * 0.15 + (animation2 * 20 - 10),
      ),
      90,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(
                  size.width * 0.75 + (animation1 * 25 - 12),
                  size.height * 0.15 + (animation2 * 20 - 10),
                ),
                radius: 90,
              ),
            ),
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.3 + (animation3 * 30 - 15),
        size.height * 0.85 + (animation1 * 20 - 10),
      ),
      110,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF14366D).withOpacity(0.35),
                const Color(0xFF14366D).withOpacity(0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ).createShader(
              Rect.fromCircle(
                center: Offset(
                  size.width * 0.3 + (animation3 * 30 - 15),
                  size.height * 0.85 + (animation1 * 20 - 10),
                ),
                radius: 110,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(Animated3DShapesPainter old) =>
      old.animation1 != animation1 ||
      old.animation2 != animation2 ||
      old.animation3 != animation3;
}
