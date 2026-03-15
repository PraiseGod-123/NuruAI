import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../services/analytics_service.dart';

// ══════════════════════════════════════════════════════════════════════════
// NuruAI — AnalyticsScreen
//
// Renders ONLY real data from UserAnalytics (Firebase + ML backend).
// Every section has a proper empty state for when:
//   - The user is new and has no data yet
//   - The ML backend is not yet connected
//   - The user is offline
//
// Sections:
//   1. Header           — greeting, points, streak (from Firebase)
//   2. Today's Insight  — ML-generated wellbeing summary
//   3. Wellbeing Score  — animated ring, 7-day sparkline (from backend)
//   4. Mood Journey     — real logged moods from Firestore
//   5. This Week        — real activity counts from Firestore
//   6. Streak Calendar  — real 30-day activity from Firestore
//   7. Weekly Report    — ML-generated weekly analysis
//   8. Awards           — unlocked by real totalPoints from Firestore
// ══════════════════════════════════════════════════════════════════════════

class AnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const AnalyticsScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _starController;
  late final AnimationController _shapeController;
  late final AnimationController _scoreController;
  late final AnimationController _entranceController;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  Animation<double>? _scoreAnim;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  UserAnalytics? _analytics;

  final List<_Star> _stars = [];
  final math.Random _rng = math.Random();
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _shapeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );

    for (int i = 0; i < 63; i++) {
      _stars.add(
        _Star(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          size: _rng.nextDouble() < 0.5
              ? 1.2
              : (_rng.nextDouble() < 0.7 ? 1.8 : 2.6),
          phase: _rng.nextDouble() * math.pi * 2,
          speed: 0.5 + _rng.nextDouble() * 0.9,
        ),
      );
    }

    _loadData();
  }

  @override
  void dispose() {
    _starController.dispose();
    _shapeController.dispose();
    _scoreController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = widget.userData?['id'] as String? ?? '';
    final analytics = await AnalyticsService.instance.loadUserAnalytics(userId);

    if (!mounted) return;

    // Only animate the score ring if we actually have a score from the backend.
    final score = analytics.todayInsight?.wellbeingScore;
    if (score != null) {
      _scoreAnim = Tween<double>(begin: 0, end: score).animate(
        CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
      );
      _scoreController.forward();
    }

    setState(() {
      _analytics = analytics;
      _loading = false;
    });

    _entranceController.forward();
  }

  // ── Colour helpers ────────────────────────────────────────────────────────

  Color _scoreColour(double score) {
    if (score >= 8) return const Color(0xFF43E97B);
    if (score >= 6) return const Color(0xFF8EA2D7);
    if (score >= 4) return const Color(0xFFFFA751);
    return const Color(0xFFFA709A);
  }

  Color _moodColour(MoodValue mood) {
    switch (mood) {
      case MoodValue.happy:
        return const Color(0xFF43E97B);
      case MoodValue.excited:
        return const Color(0xFFFFA751);
      case MoodValue.calm:
        return const Color(0xFF8EA2D7);
      case MoodValue.tired:
        return const Color(0xFF6E7D95);
      case MoodValue.anxious:
        return const Color(0xFFFFC107);
      case MoodValue.sad:
        return const Color(0xFF4569AD);
      case MoodValue.angry:
        return const Color(0xFFFA709A);
      case MoodValue.overwhelmed:
        return const Color(0xFFE040FB);
    }
  }

  Color _tierColour(AwardTier tier) {
    switch (tier) {
      case AwardTier.bronze:
        return const Color(0xFFCD7F32);
      case AwardTier.silver:
        return const Color(0xFFB0BEC5);
      case AwardTier.gold:
        return const Color(0xFFFFD700);
      case AwardTier.platinum:
        return const Color(0xFF4FC3F7);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    final name = widget.userData?['name'] as String? ?? '';
    final first = name.isNotEmpty ? name.split(' ').first : 'there';
    if (h < 12) return 'Good morning, $first';
    if (h < 17) return 'Good afternoon, $first';
    return 'Good evening, $first';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081F44),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4569AD), Color(0xFF14366D)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _starController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _StarsPainter(_stars, _starController.value),
            ),
          ),
          AnimatedBuilder(
            animation: _shapeController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _ShapesPainter(_shapeController.value),
            ),
          ),
          SafeArea(child: _loading ? _buildLoader() : _buildContent()),
        ],
      ),
    );
  }

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: Color(0xFF8EA2D7), strokeWidth: 2),
  );

  Widget _buildContent() {
    final a = _analytics!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(a)),
            SliverToBoxAdapter(child: _buildPeriodSelector()),
            SliverToBoxAdapter(child: _buildTodayInsight(a)),
            SliverToBoxAdapter(child: _buildWellbeingScore(a)),
            SliverToBoxAdapter(child: _buildMoodJourney(a)),
            SliverToBoxAdapter(child: _buildWeekStats(a)),
            SliverToBoxAdapter(child: _buildStreakSection(a)),
            SliverToBoxAdapter(child: _buildWeeklyReport(a)),
            SliverToBoxAdapter(child: _buildAwardsSection(a)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(UserAnalytics a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button — screen is pushed via Navigator.pushNamed from bottom nav
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4569AD).withOpacity(0.4),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your wellbeing at a glance',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          _GlassChip(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u2728', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '${a.totalPoints} pts',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GlassChip(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\ud83d\udd25', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '${a.streakData.currentStreak} days',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PERIOD SELECTOR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: ['Today', 'Week', 'Month'].map((p) {
          final active = _selectedPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF4569AD).withOpacity(0.45)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFF8EA2D7)
                      : Colors.white.withOpacity(0.12),
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.white : Colors.white54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════════════════════
  // TODAY'S INSIGHT  — activity radar chart + mood distribution chart
  // Shows real data when available; clean empty chart skeleton when not.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTodayInsight(UserAnalytics a) {
    final insight = a.todayInsight;
    final moods = a.recentMoods;
    final activities = a.recentActivities;

    // Count today's activity types from real data
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final todayActs = activities
        .where((e) => e.timestamp.isAfter(todayStart))
        .toList();

    final int journals = todayActs
        .where((e) => e.type == ActivityType.journalEntry)
        .length;
    final int breaths = todayActs
        .where((e) => e.type == ActivityType.breathingSession)
        .length;
    final int chats = todayActs
        .where((e) => e.type == ActivityType.nuruChat)
        .length;
    final int calmMes = todayActs
        .where((e) => e.type == ActivityType.calmMe)
        .length;
    final int moodLogs = todayActs
        .where((e) => e.type == ActivityType.moodLog)
        .length;

    // Today's mood from most recent entry
    final todayMood =
        moods.isNotEmpty && moods.first.timestamp.isAfter(todayStart)
        ? moods.first
        : null;

    final hasData = todayActs.isNotEmpty || todayMood != null;
    final score = insight?.wellbeingScore;

    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4569AD).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF8EA2D7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Insight",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (insight?.isMLGenerated == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43E97B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.memory_rounded,
                        size: 10,
                        color: Color(0xFF43E97B),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'NuruAI',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF43E97B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Activity radar chart ────────────────────────────────────────
          // Shows real counts for today's 5 activity types.
          // Renders as an empty skeleton with axis labels when no data yet.
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _RadarChartPainter(
                values: [
                  hasData ? journals.clamp(0, 5).toDouble() : 0,
                  hasData ? breaths.clamp(0, 5).toDouble() : 0,
                  hasData ? chats.clamp(0, 5).toDouble() : 0,
                  hasData ? calmMes.clamp(0, 5).toDouble() : 0,
                  hasData ? moodLogs.clamp(0, 5).toDouble() : 0,
                ],
                labels: const [
                  'Journal',
                  'Breathing',
                  'Chat',
                  'Calm Me',
                  'Mood',
                ],
                maxValue: 5,
                colour: score != null
                    ? _scoreColour(score)
                    : const Color(0xFF8EA2D7),
                isEmpty: !hasData,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Mood + score row ────────────────────────────────────────────
          Row(
            children: [
              // Today's mood pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mood today',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6E7D95),
                        ),
                      ),
                      const SizedBox(height: 6),
                      todayMood != null
                          ? Row(
                              children: [
                                Text(
                                  todayMood.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  todayMood.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Not logged yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E7D95),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Score pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wellbeing',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6E7D95),
                        ),
                      ),
                      const SizedBox(height: 6),
                      score != null
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  score.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _scoreColour(score),
                                  ),
                                ),
                                const Text(
                                  ' /10',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6E7D95),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E7D95),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Activities today pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activities',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6E7D95),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        todayActs.isNotEmpty ? '${todayActs.length}' : '0',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── ML summary text (only when backend is live) ─────────────────
          if (insight?.isMLGenerated == true && insight?.summary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Text(
                insight!.summary!,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFFB7C3E8),
                  height: 1.6,
                ),
              ),
            ),
          ],

          // ── Suggestions (only when backend is live) ─────────────────────
          if (insight?.isMLGenerated == true &&
              (insight?.suggestions.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            ...insight!.suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8EA2D7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8EA2D7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WELLBEING SCORE  — from ML backend
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWellbeingScore(UserAnalytics a) {
    final score = a.todayInsight?.wellbeingScore;
    final scores = a.weeklyReport?.dailyScores ?? [];

    return _GlassSection(
      title: 'Wellbeing Score',
      child: score == null
          ? _buildScorePending()
          : Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _scoreController,
                        builder: (_, __) => CustomPaint(
                          size: const Size(130, 130),
                          painter: _ScoreRingPainter(
                            progress: (_scoreAnim?.value ?? 0) / 10,
                            colour: _scoreColour(score),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _scoreController,
                        builder: (_, __) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (_scoreAnim?.value ?? score).toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: _scoreColour(score),
                              ),
                            ),
                            const Text(
                              'out of 10',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6E7D95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scoreLabel(score),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _scoreColour(score),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Based on your mood,\njournal & activity today',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7D95),
                          height: 1.5,
                        ),
                      ),
                      if (scores.length == 7) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: CustomPaint(
                            size: const Size(double.infinity, 44),
                            painter: _SparklinePainter(
                              scores,
                              _scoreColour(score),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '7-day trend',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6E7D95),
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

  Widget _buildScorePending() => const _PendingBlock(
    icon: '\ud83d\udcca',
    title: 'Score not yet available',
    body:
        'Your wellbeing score will be calculated by NuruAI after it has '
        'enough data from your mood logs, journal entries, and activity.',
  );

  String _scoreLabel(double s) {
    if (s >= 9) return 'Excellent';
    if (s >= 7.5) return 'Great';
    if (s >= 6) return 'Good';
    if (s >= 4) return 'Fair';
    return 'Needs attention';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOOD JOURNEY  — real logged moods from Firestore
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMoodJourney(UserAnalytics a) {
    final moods = a.recentMoods;

    return _GlassSection(
      title: 'Mood Journey',
      subtitle: 'Last 7 days',
      child: moods.isEmpty
          ? const _PendingBlock(
              icon: '\ud83d\ude0c',
              title: 'No mood logs yet',
              body:
                  'Log your mood each day from the home screen or when '
                  'writing a journal entry. Your 7-day mood history will appear here.',
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final entry = i < moods.length ? moods[i] : null;
                    final dayLabel = _dayLabel(i, moods.length);
                    return Column(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 60),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entry != null
                                ? _moodColour(entry.mood).withOpacity(0.18)
                                : Colors.white.withOpacity(0.04),
                            border: Border.all(
                              color: entry != null
                                  ? _moodColour(entry.mood).withOpacity(0.55)
                                  : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              entry?.emoji ?? '\u2014',
                              style: TextStyle(
                                fontSize: entry != null ? 18 : 10,
                                color: entry != null ? null : Colors.white24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6E7D95),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
    );
  }

  String _dayLabel(int index, int totalMoods) {
    final daysAgo = 6 - index;
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // THIS WEEK STATS  — real counts from Firestore
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWeekStats(UserAnalytics a) {
    final report = a.weeklyReport;
    final journals = report?.totalJournalEntries ?? a.totalJournals;
    final breaths = report?.totalBreathingSessions ?? a.totalBreaths;
    final chats = report?.totalNuruChats ?? a.totalChats;
    final calmMe = report?.totalCalmMeSessions ?? a.totalCalmMe;
    final hasData = journals + breaths + chats + calmMe > 0;

    return _GlassSection(
      title: 'This Week',
      child: hasData
          ? GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _StatTile(
                  label: 'Journals',
                  value: '$journals',
                  icon: Icons.book_outlined,
                  colour: const Color(0xFF8EA2D7),
                ),
                _StatTile(
                  label: 'Breaths',
                  value: '$breaths',
                  icon: Icons.air_rounded,
                  colour: const Color(0xFF43E97B),
                ),
                _StatTile(
                  label: 'Chats',
                  value: '$chats',
                  icon: Icons.chat_bubble_outline_rounded,
                  colour: const Color(0xFFFFA751),
                ),
                _StatTile(
                  label: 'Calm Me',
                  value: '$calmMe',
                  icon: Icons.spa_outlined,
                  colour: const Color(0xFFE040FB),
                ),
              ],
            )
          : const _PendingBlock(
              icon: '\ud83d\uddd3\ufe0f',
              title: 'No activity this week',
              body:
                  'Your weekly activity counts will appear here as you '
                  'journal, practise breathing, and use the app each day.',
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STREAK CALENDAR  — real data from Firestore
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStreakSection(UserAnalytics a) {
    final s = a.streakData;

    return _GlassSection(
      title: 'Streak',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StreakCounter(
                  label: 'Current',
                  value: s.currentStreak,
                  icon: '\ud83d\udd25',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakCounter(
                  label: 'Longest',
                  value: s.longestStreak,
                  icon: '\ud83c\udfc6',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakCounter(
                  label: 'Total Days',
                  value: s.totalDaysActive,
                  icon: '\u2b50',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Last 30 days',
              style: TextStyle(fontSize: 12, color: Color(0xFF6E7D95)),
            ),
          ),
          const SizedBox(height: 10),
          s.last30Days.isEmpty
              ? const _PendingBlock(
                  icon: '\ud83d\udcc5',
                  title: 'Start your streak today',
                  body:
                      'Open the app each day to build your streak. '
                      'Your 30-day calendar will fill in as you go.',
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 1,
                  ),
                  itemCount: 30,
                  itemBuilder: (_, i) {
                    final active = i < s.last30Days.length && s.last30Days[i];
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? const Color(0xFF4569AD).withOpacity(0.65)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF8EA2D7).withOpacity(0.45)
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WEEKLY REPORT  — ML backend content or pending state
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWeeklyReport(UserAnalytics a) {
    final report = a.weeklyReport;

    return _GlassSection(
      title: 'Weekly Report',
      subtitle: _weekRangeLabel(),
      child: report == null || !report.isMLGenerated
          ? const _PendingBlock(
              icon: '\ud83d\udcdd',
              title: 'Report not yet generated',
              body:
                  'NuruAI will generate your weekly report once it has '
                  'analysed a full week of your mood logs, journal entries, '
                  'breathing sessions, and micro-expression data.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.wellbeingTrend != null)
                  Row(
                    children: [
                      Icon(
                        report.wellbeingTrend! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: report.wellbeingTrend! >= 0
                            ? const Color(0xFF43E97B)
                            : const Color(0xFFFA709A),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.wellbeingTrend! >= 0
                            ? '+${report.wellbeingTrend!.toStringAsFixed(1)} from last week'
                            : '${report.wellbeingTrend!.toStringAsFixed(1)} from last week',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: report.wellbeingTrend! >= 0
                              ? const Color(0xFF43E97B)
                              : const Color(0xFFFA709A),
                        ),
                      ),
                    ],
                  ),
                if (report.overallSummary != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    report.overallSummary!,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFFB7C3E8),
                      height: 1.6,
                    ),
                  ),
                ],
                if (report.dailyScores.length == 7) ...[
                  const SizedBox(height: 20),
                  _buildDailyBars(report.dailyScores),
                ],
                if (report.weeklyHighlights.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...report.weeklyHighlights.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4569AD),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF8EA2D7),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _weekRangeLabel() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]}';
  }

  Widget _buildDailyBars(List<double> scores) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxS = scores.reduce(math.max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final s = scores[i];
        final isToday = i == DateTime.now().weekday - 1;
        final ratio = maxS > 0 ? s / maxS : 0.0;
        final colour = isToday ? _scoreColour(s) : const Color(0xFF4569AD);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isToday)
                  Text(
                    s.toStringAsFixed(1),
                    style: TextStyle(fontSize: 9, color: colour),
                  ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 80),
                  curve: Curves.easeOut,
                  height: 60 * ratio.clamp(0.08, 1.0),
                  decoration: BoxDecoration(
                    color: colour.withOpacity(isToday ? 0.75 : 0.32),
                    borderRadius: BorderRadius.circular(5),
                    border: isToday
                        ? Border.all(color: colour, width: 1)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  days[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6E7D95),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AWARDS  — unlock status driven by real totalPoints
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAwardsSection(UserAnalytics a) {
    final unlocked = a.awards.where((x) => x.isUnlocked).toList();
    final locked = a.awards.where((x) => !x.isUnlocked).toList();

    return _GlassSection(
      title: 'Awards',
      subtitle: '${unlocked.length} of ${a.awards.length} unlocked',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unlocked.isEmpty)
            const _PendingBlock(
              icon: '\ud83c\udfc5',
              title: 'No awards yet',
              body:
                  'Awards are earned through real engagement. '
                  'Keep journaling, logging your mood, and using '
                  'breathing exercises to unlock your first award.',
            )
          else ...[
            const Text(
              'Earned',
              style: TextStyle(fontSize: 12, color: Color(0xFF6E7D95)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unlocked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _AwardTile(
                  award: unlocked[i],
                  tierColour: _tierColour(unlocked[i].tier),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (locked.isNotEmpty) ...[
            const Text(
              'Coming up',
              style: TextStyle(fontSize: 12, color: Color(0xFF6E7D95)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: locked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _AwardTile(
                  award: locked[i],
                  tierColour: _tierColour(locked[i].tier),
                  locked: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════

/// Standard glass card section.
class _GlassSection extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;

  const _GlassSection({required this.child, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F3F74), Color(0xFF081F44)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF4569AD).withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7D95),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

/// Empty / pending state block shown when no real data is available yet.
class _PendingBlock extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _PendingBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6E7D95),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GlassChip extends StatelessWidget {
  final Widget child;
  const _GlassChip({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF4569AD).withOpacity(0.3)),
    ),
    child: child,
  );
}

class _StreakCounter extends StatelessWidget {
  final String label;
  final int value;
  final String icon;
  const _StreakCounter({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF4569AD).withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6E7D95)),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color colour;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colour.withOpacity(0.22)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: colour, size: 20),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6E7D95)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _AwardTile extends StatelessWidget {
  final Award award;
  final Color tierColour;
  final bool locked;
  const _AwardTile({
    required this.award,
    required this.tierColour,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 90,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: locked
          ? Colors.white.withOpacity(0.03)
          : tierColour.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: locked
            ? Colors.white.withOpacity(0.07)
            : tierColour.withOpacity(0.38),
        width: 1.5,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Text(
              locked ? '\ud83d\udd12' : award.emoji,
              style: const TextStyle(fontSize: 26),
            ),
            if (!locked)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: tierColour,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 8, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          award.title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: locked ? Colors.white24 : Colors.white,
          ),
        ),
        if (!locked) ...[
          const SizedBox(height: 4),
          Text(
            award.tier.name[0].toUpperCase() + award.tier.name.substring(1),
            style: TextStyle(fontSize: 9, color: tierColour),
          ),
        ],
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════════════════

/// Radar / spider chart for today's activity breakdown.
/// Renders a 5-axis polygon (journal, breathing, chat, calmMe, mood).
/// When isEmpty=true, draws only the empty skeleton grid with labels.
/// All values are normalised 0–maxValue (real data from Firestore).
class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final Color colour;
  final bool isEmpty;

  const _RadarChartPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.colour,
    this.isEmpty = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final radius = math.min(cx, cy) - 30;
    final n = values.length;
    final step = (2 * math.pi) / n;

    // ── Grid rings ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.08);

    for (int ring = 1; ring <= 5; ring++) {
      final r = radius * ring / 5;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = step * i - math.pi / 2;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.1);

    for (int i = 0; i < n; i++) {
      final angle = step * i - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
        axisPaint,
      );
    }

    // ── Data polygon (only when we have real data) ─────────────────────
    if (!isEmpty) {
      final fillPath = Path();
      final strokePath = Path();

      for (int i = 0; i < n; i++) {
        final ratio = (values[i] / maxValue).clamp(0.0, 1.0);
        final angle = step * i - math.pi / 2;
        final x = cx + radius * ratio * math.cos(angle);
        final y = cy + radius * ratio * math.sin(angle);
        if (i == 0) {
          fillPath.moveTo(x, y);
          strokePath.moveTo(x, y);
        } else {
          fillPath.lineTo(x, y);
          strokePath.lineTo(x, y);
        }
      }
      fillPath.close();
      strokePath.close();

      canvas.drawPath(fillPath, Paint()..color = colour.withOpacity(0.18));
      canvas.drawPath(
        strokePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colour.withOpacity(0.85),
      );

      // Data point dots
      for (int i = 0; i < n; i++) {
        final ratio = (values[i] / maxValue).clamp(0.0, 1.0);
        final angle = step * i - math.pi / 2;
        canvas.drawCircle(
          Offset(
            cx + radius * ratio * math.cos(angle),
            cy + radius * ratio * math.sin(angle),
          ),
          4,
          Paint()..color = colour,
        );
      }
    }

    // ── Axis labels ───────────────────────────────────────────────────────
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final angle = step * i - math.pi / 2;
      final labelR = radius + 22;
      final lx = cx + labelR * math.cos(angle);
      final ly = cy + labelR * math.sin(angle);
      final hasValue = !isEmpty && values[i] > 0;

      labelPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          color: hasValue ? colour : Colors.white.withOpacity(0.35),
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(lx - labelPainter.width / 2, ly - labelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarChartPainter o) =>
      o.values != values || o.isEmpty != isEmpty;
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color colour;
  const _ScoreRingPainter({required this.progress, required this.colour});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 16) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withOpacity(0.08);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = colour;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter o) => o.progress != progress;
}

class _SparklinePainter extends CustomPainter {
  final List<double> scores;
  final Color colour;
  const _SparklinePainter(this.scores, this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;
    final min = scores.reduce(math.min);
    final max = scores.reduce(math.max);
    final range = (max - min).clamp(0.5, double.infinity);
    final pts = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      pts.add(
        Offset(
          i / (scores.length - 1) * size.width,
          size.height - ((scores[i] - min) / range) * size.height,
        ),
      );
    }
    final fill = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) fill.lineTo(p.dx, p.dy);
    fill
      ..lineTo(pts.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colour.withOpacity(0.28), colour.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp = Offset(
        (pts[i - 1].dx + pts[i].dx) / 2,
        (pts[i - 1].dy + pts[i].dy) / 2,
      );
      line.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, cp.dx, cp.dy);
    }
    line.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = colour,
    );
    canvas.drawCircle(pts.last, 3.5, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_SparklinePainter o) => false;
}

class _Star {
  final double x, y, size, phase, speed;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  const _StarsPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final flicker =
          0.4 +
          0.6 * (0.5 + 0.5 * math.sin(s.phase + t * s.speed * math.pi * 2));
      paint.color = Colors.white.withOpacity(flicker * 0.85);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}

class _ShapesPainter extends CustomPainter {
  final double t;
  const _ShapesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final dy = math.sin(t * math.pi) * 30;
    paint.color = const Color(0xFFB7C3E8).withOpacity(0.06);
    canvas.drawPath(
      Path()
        ..moveTo(0, dy)
        ..quadraticBezierTo(
          size.width * 0.35,
          size.height * 0.12 + dy,
          size.width * 0.45,
          size.height * 0.27 + dy,
        )
        ..quadraticBezierTo(
          size.width * 0.55,
          size.height * 0.4 + dy,
          size.width * 0.30,
          size.height * 0.5 + dy,
        )
        ..quadraticBezierTo(
          size.width * 0.1,
          size.height * 0.6 + dy,
          0,
          size.height * 0.42 + dy,
        )
        ..close(),
      paint,
    );
    final dx = math.cos(t * math.pi) * 25;
    paint.color = const Color(0xFF3A4FA8).withOpacity(0.09);
    canvas.drawPath(
      Path()
        ..moveTo(size.width + dx, size.height * 0.22)
        ..quadraticBezierTo(
          size.width * 0.65 + dx,
          size.height * 0.35,
          size.width * 0.55 + dx,
          size.height * 0.55,
        )
        ..quadraticBezierTo(
          size.width * 0.48 + dx,
          size.height * 0.72,
          size.width * 0.72 + dx,
          size.height * 0.82,
        )
        ..quadraticBezierTo(
          size.width * 0.9 + dx,
          size.height * 0.91,
          size.width + dx,
          size.height * 0.72,
        )
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShapesPainter o) => o.t != t;
}
