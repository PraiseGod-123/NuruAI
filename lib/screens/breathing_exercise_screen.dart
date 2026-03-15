import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/breathing_service.dart';
import '../utils/nuru_colors.dart';

// ══════════════════════════════════════════════════════════════
// BREATHING EXERCISE SCREEN
//
// Design language: NuruAI Night Blue — same stars + glassmorphism
// as journal and home screens. No bright coloured gradients.
//
// Flow:
//   1. Technique grid → tap to open detail sheet
//   2. Detail sheet: description, autism note, pattern, research
//   3. Start → full-screen breathing animation with animated circle
//   4. Complete → celebration + option to repeat or go back
// ══════════════════════════════════════════════════════════════

class BreathingExerciseScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const BreathingExerciseScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────
  late final AnimationController _starController;
  late final AnimationController _shapeController;
  late final AnimationController _circleController; // breathing orb
  late final AnimationController _pulseController; // outer ring pulse

  // ── Breathing state ──────────────────────────────────────
  BreathingTechnique? _active; // currently running technique
  int _phase = 0; // 0=inhale 1=hold 2=exhale 3=hold
  int _countdown = 0;
  int _cycle = 0;
  bool _running = false;
  Timer? _timer;

  // ── Star painter data ────────────────────────────────────
  final List<_Star> _stars = [];
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _shapeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Generate 63 stars
    for (int i = 0; i < 63; i++) {
      _stars.add(
        _Star(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          size: _rng.nextDouble() < 0.5
              ? 1.2
              : (_rng.nextDouble() < 0.7 ? 1.8 : 2.6),
          phase: _rng.nextDouble() * math.pi * 2,
          speed: 0.6 + _rng.nextDouble() * 0.8,
        ),
      );
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    _shapeController.dispose();
    _circleController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Breathing engine ─────────────────────────────────────

  void _start(BreathingTechnique t) {
    _timer?.cancel();
    setState(() {
      _active = t;
      _phase = 0;
      _cycle = 0;
      _running = true;
      _countdown = _firstNonZeroPhase(t.pattern);
    });
    _animatePhase();
    _tick();
  }

  int _firstNonZeroPhase(List<int> pattern) {
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] > 0) return pattern[i];
    }
    return 4;
  }

  void _animatePhase() {
    if (_active == null) return;
    final secs = _active!.pattern[_phase];
    if (secs == 0) return;

    _circleController.stop();
    _circleController.duration = Duration(seconds: secs);

    if (_phase == 0) {
      // Inhale → expand
      _circleController.forward(from: _circleController.value);
    } else if (_phase == 2) {
      // Exhale → contract
      _circleController.reverse(from: _circleController.value);
    }
    // Hold → keep value
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) _advance();
    });
  }

  void _advance() {
    if (_active == null) return;
    final pattern = _active!.pattern;

    // Move to next non-zero phase
    int next = _phase + 1;
    while (next < 4 && pattern[next] == 0) next++;

    if (next >= 4) {
      // Completed one full cycle
      final newCycle = _cycle + 1;
      if (newCycle >= _active!.cycles) {
        _complete();
        return;
      }
      setState(() {
        _cycle = newCycle;
        _phase = 0;
      });
    } else {
      setState(() => _phase = next);
    }

    setState(() => _countdown = _active!.pattern[_phase]);
    _animatePhase();
  }

  void _complete() {
    _timer?.cancel();
    _circleController.stop();
    setState(() => _running = false);
    _showCompletionSheet();
  }

  void _stop() {
    _timer?.cancel();
    _circleController.stop();
    setState(() {
      _running = false;
      _active = null;
    });
  }

  // ── Phase helpers ────────────────────────────────────────

  static const _phaseLabels = ['Breathe In', 'Hold', 'Breathe Out', 'Hold'];
  static const _phaseIcons = [
    Icons.arrow_upward_rounded,
    Icons.pause_rounded,
    Icons.arrow_downward_rounded,
    Icons.pause_rounded,
  ];

  String get _phaseLabel => _phaseLabels[_phase];
  IconData get _phaseIcon => _phaseIcons[_phase];

  Color get _phaseColour {
    switch (_phase) {
      case 0:
        return const Color(0xFF8EA2D7); // solidBlue — inhale
      case 1:
        return const Color(0xFFB7C3E8); // lilacBlue — hold
      case 2:
        return const Color(0xFF4569AD); // sailingBlue — exhale
      case 3:
        return const Color(0xFF6E7D95); // muted — hold
      default:
        return Colors.white;
    }
  }

  // ── Sheets ───────────────────────────────────────────────

  void _showDetailSheet(BreathingTechnique technique) {
    // Kick off API enrichment in background
    BreathingService.instance.enrichTechnique(technique).then((_) {
      if (mounted) setState(() {});
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        technique: technique,
        onStart: () {
          Navigator.pop(context);
          _start(technique);
        },
      ),
    );
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _CompletionSheet(
        technique: _active!,
        cyclesCompleted: _cycle + 1,
        onDone: () {
          Navigator.pop(context);
          setState(() => _active = null);
        },
        onRepeat: () {
          Navigator.pop(context);
          _start(_active!);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081F44),
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4569AD), Color(0xFF14366D)],
              ),
            ),
          ),

          // ── Stars ──
          AnimatedBuilder(
            animation: _starController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _StarsPainter(_stars, _starController.value),
            ),
          ),

          // ── Organic shapes ──
          AnimatedBuilder(
            animation: _shapeController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _ShapesPainter(_shapeController.value),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: _running ? _buildExerciseView() : _buildSelectorView(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TECHNIQUE SELECTOR
  // ══════════════════════════════════════════════════════════

  Widget _buildSelectorView() {
    final techniques = BreathingService.techniques;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              _GlassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Breathing',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Evidence-based • Autism-adapted',
                      style: TextStyle(fontSize: 13, color: Color(0xFFB7C3E8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Category legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BreathingCategory.values
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(category: c),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Technique cards
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: techniques.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _TechniqueCard(
              technique: techniques[i],
              onTap: () => _showDetailSheet(techniques[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // EXERCISE VIEW
  // ══════════════════════════════════════════════════════════

  Widget _buildExerciseView() {
    final t = _active!;
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              _GlassButton(icon: Icons.close_rounded, onTap: _stop),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Cycle pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  '${_cycle + 1} / ${t.cycles}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pattern dots
        const SizedBox(height: 24),
        _buildPatternDots(t.pattern),

        // Breathing orb
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _circleController,
                _pulseController,
              ]),
              builder: (_, __) => _buildBreathingOrb(),
            ),
          ),
        ),

        // Phase + countdown
        _buildPhaseLabel(),

        const SizedBox(height: 40),

        // Stop button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: GestureDetector(
              onTap: _stop,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF4569AD).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Stop Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternDots(List<int> pattern) {
    final labels = ['In', 'Hold', 'Out', 'Hold'];
    final active = _phase;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        if (pattern[i] == 0) return const SizedBox.shrink();
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4569AD).withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF8EA2D7)
                  : Colors.white.withOpacity(0.15),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${pattern[i]}s',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? const Color(0xFFB7C3E8) : Colors.white38,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBreathingOrb() {
    final t = _circleController.value;
    final pulse = _pulseController.value;

    // Orb scales from 120 (exhale) to 220 (inhale)
    final orbSize = 120.0 + t * 100.0;

    // Outer ring pulses gently during hold
    final ringSize = orbSize + 20 + pulse * 12;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: const Color(0xFF4569AD).withOpacity(0.25 + pulse * 0.15),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4569AD).withOpacity(0.12),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Main orb
          Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8EA2D7).withOpacity(0.9),
                  const Color(0xFF4569AD).withOpacity(0.7),
                  const Color(0xFF1F3F74).withOpacity(0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4569AD).withOpacity(0.4 + t * 0.3),
                  blurRadius: 40 + t * 20,
                  spreadRadius: 5 + t * 10,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_phaseIcon, color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 48,
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
    );
  }

  Widget _buildPhaseLabel() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _phaseLabel,
            key: ValueKey(_phase),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: _phaseColour,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TECHNIQUE CARD
// ══════════════════════════════════════════════════════════════

class _TechniqueCard extends StatelessWidget {
  final BreathingTechnique technique;
  final VoidCallback onTap;
  const _TechniqueCard({required this.technique, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F3F74), Color(0xFF081F44)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF4569AD).withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Subtle category colour strip on left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _categoryColour(technique.category),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    // Emoji circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4569AD).withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          technique.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technique.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            technique.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8EA2D7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Pattern preview
                          _PatternPreview(pattern: technique.pattern),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _DifficultyBadge(difficulty: technique.difficulty),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 20,
                        ),
                      ],
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

  Color _categoryColour(BreathingCategory cat) {
    switch (cat) {
      case BreathingCategory.regulation:
        return const Color(0xFF4569AD);
      case BreathingCategory.anxiety:
        return const Color(0xFF5C6BC0);
      case BreathingCategory.focus:
        return const Color(0xFF0277BD);
      case BreathingCategory.sleep:
        return const Color(0xFF1A237E);
      case BreathingCategory.grounding:
        return const Color(0xFF558B2F);
    }
  }
}

class _PatternPreview extends StatelessWidget {
  final List<int> pattern;
  const _PatternPreview({required this.pattern});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    final labels = ['In', 'Hold', 'Out', 'Hold'];
    for (int i = 0; i < 4; i++) {
      if (pattern[i] > 0) parts.add('${pattern[i]}s ${labels[i]}');
    }
    return Text(
      parts.join(' · '),
      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6E7D95)),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DETAIL SHEET
// ══════════════════════════════════════════════════════════════

class _DetailSheet extends StatefulWidget {
  final BreathingTechnique technique;
  final VoidCallback onStart;
  const _DetailSheet({required this.technique, required this.onStart});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  @override
  Widget build(BuildContext context) {
    final t = widget.technique;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F3F74), Color(0xFF081F44)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  // Title row
                  Row(
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              t.subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8EA2D7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _DifficultyBadge(difficulty: t.difficulty),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Breathing pattern visual
                  _buildPatternRow(t.pattern),
                  const SizedBox(height: 24),

                  // About
                  _SheetSection(
                    title: 'About',
                    child: Text(
                      t.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB7C3E8),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Why it helps autistic individuals
                  _SheetSection(
                    title: '🧩 Why it helps autistic individuals',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4569AD).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4569AD).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        t.autismNote,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFFB7C3E8),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Benefits
                  _SheetSection(
                    title: 'Benefits',
                    child: Column(
                      children: t.benefits
                          .map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8EA2D7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        color: Color(0xFFB7C3E8),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wikipedia background (if loaded)
                  if (t.wikiSummary != null && t.wikiSummary!.isNotEmpty) ...[
                    _SheetSection(
                      title: '📖 Background',
                      child: Text(
                        t.wikiSummary!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8EA2D7),
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Research (if loaded)
                  if (t.research.isNotEmpty) ...[
                    _SheetSection(
                      title: '🔬 Clinical Research',
                      child: Column(
                        children: t.research
                            .map(
                              (r) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF4569AD,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (r.authors.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        r.authors,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6E7D95),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (r.journal.isNotEmpty)
                                          Expanded(
                                            child: Text(
                                              r.journal,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF4569AD),
                                                fontStyle: FontStyle.italic,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        Text(
                                          r.pubDate,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6E7D95),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Cycles + source
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.repeat_rounded,
                          label: '${t.cycles} cycles',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.timer_outlined,
                          label: _totalTime(t),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF4569AD).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF4569AD),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.source,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E7D95),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Start button
                  GestureDetector(
                    onTap: widget.onStart,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4569AD), Color(0xFF1F3F74)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF8EA2D7).withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4569AD).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Begin Session',
                            style: TextStyle(
                              fontSize: 17,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRow(List<int> pattern) {
    final labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];
    final icons = [
      Icons.arrow_upward_rounded,
      Icons.pause_circle_outline_rounded,
      Icons.arrow_downward_rounded,
      Icons.pause_circle_outline_rounded,
    ];

    final activeSteps = <int>[];
    for (int i = 0; i < 4; i++) {
      if (pattern[i] > 0) activeSteps.add(i);
    }

    return Row(
      children: activeSteps.asMap().entries.map((e) {
        final i = e.value;
        final isLast = e.key == activeSteps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4569AD).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icons[i], color: const Color(0xFF8EA2D7), size: 20),
                      const SizedBox(height: 6),
                      Text(
                        '${pattern[i]}s',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6E7D95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF4569AD),
                    size: 12,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _totalTime(BreathingTechnique t) {
    final secs = t.pattern.fold<int>(0, (a, b) => a + b) * t.cycles;
    if (secs < 60) return '${secs}s';
    return '${(secs / 60).ceil()} min';
  }
}

// ══════════════════════════════════════════════════════════════
// COMPLETION SHEET
// ══════════════════════════════════════════════════════════════

class _CompletionSheet extends StatelessWidget {
  final BreathingTechnique technique;
  final int cyclesCompleted;
  final VoidCallback onDone;
  final VoidCallback onRepeat;

  const _CompletionSheet({
    required this.technique,
    required this.cyclesCompleted,
    required this.onDone,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F3F74), Color(0xFF081F44)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow circle
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4569AD).withOpacity(0.15),
              border: Border.all(
                color: const Color(0xFF8EA2D7).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4569AD).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Text('🌟', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Session Complete',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${technique.name} • $cyclesCompleted cycle${cyclesCompleted > 1 ? "s" : ""}',
            style: const TextStyle(fontSize: 15, color: Color(0xFF8EA2D7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Well done. Your nervous system is grateful.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDone,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4569AD).withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onRepeat,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4569AD), Color(0xFF1F3F74)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8EA2D7).withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Repeat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4569AD).withOpacity(0.4)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final colour = difficulty == 'Beginner'
        ? const Color(0xFF2E7D32)
        : difficulty == 'Intermediate'
        ? const Color(0xFFF57F17)
        : const Color(0xFF6A1B9A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colour.withOpacity(0.4)),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colour,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final BreathingCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final label = category.name[0].toUpperCase() + category.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4569AD).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8EA2D7)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF4569AD).withOpacity(0.2)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF4569AD), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8EA2D7)),
        ),
      ],
    ),
  );
}

class _SheetSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
      child,
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// PAINTERS
// ══════════════════════════════════════════════════════════════

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

    paint.color = const Color(0xFFB7C3E8).withOpacity(0.07);
    canvas.drawPath(
      Path()
        ..moveTo(0, dy)
        ..quadraticBezierTo(
          size.width * 0.35,
          size.height * 0.15 + dy,
          size.width * 0.45,
          size.height * 0.28 + dy,
        )
        ..quadraticBezierTo(
          size.width * 0.55,
          size.height * 0.42 + dy,
          size.width * 0.32,
          size.height * 0.52 + dy,
        )
        ..quadraticBezierTo(
          size.width * 0.1,
          size.height * 0.62 + dy,
          0,
          size.height * 0.42 + dy,
        )
        ..close(),
      paint,
    );

    final dx = math.cos(t * math.pi) * 25;
    paint.color = const Color(0xFF3A4FA8).withOpacity(0.1);
    canvas.drawPath(
      Path()
        ..moveTo(size.width + dx, size.height * 0.25)
        ..quadraticBezierTo(
          size.width * 0.65 + dx,
          size.height * 0.35,
          size.width * 0.55 + dx,
          size.height * 0.55,
        )
        ..quadraticBezierTo(
          size.width * 0.45 + dx,
          size.height * 0.72,
          size.width * 0.7 + dx,
          size.height * 0.8,
        )
        ..quadraticBezierTo(
          size.width * 0.9 + dx,
          size.height * 0.9,
          size.width + dx,
          size.height * 0.7,
        )
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShapesPainter o) => o.t != t;
}
