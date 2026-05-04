import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../services/mindfulness_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

enum _Visual { expand, contract, pulse, still, wave, float, drift, glow }

class _Step {
  final String instruction;
  final int durationSec;
  final _Visual visual;
  const _Step(this.instruction, this.durationSec, this.visual);
}

class _Plan {
  final String id;
  final String title;
  final String emoji;
  final String tagline;
  final String why;
  final Color color;
  final List<_Step> steps;
  final int repeatCycles;
  const _Plan({
    required this.id,
    required this.title,
    required this.emoji,
    required this.tagline,
    required this.why,
    required this.color,
    required this.steps,
    this.repeatCycles = 1,
  });
}

class MindfulnessScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const MindfulnessScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _starCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _glowCtrl;

  bool _loading = false;
  String? _error;
  List<MindfulnessItem> _items = [];
  String _tab = 'techniques';

  final _svc = MindfulnessService.instance;

  _Plan? _session;
  int _stepIndex = 0;
  int _countdown = 0;
  int _cycle = 0;
  bool _running = false;
  Timer? _timer;

  // ══════════════════════════════════════════════════════════
  // MINDFULNESS GUIDED SESSIONS
  // ══════════════════════════════════════════════════════════

  static final List<_Plan> _plans = [
    _Plan(
      id: 'texture_anchor',
      title: 'Texture Mindfulness',
      emoji: '✋',
      color: const Color(0xFFA29BFE),
      tagline: 'Use touch as your anchor — no breath-focus needed',
      why:
          'Tactile focus activates the somatosensory cortex, quieting the default mode network and reducing rumination',
      repeatCycles: 1,
      steps: const [
        _Step(
          'Find something textured near you — fabric, wood, paper, skin.',
          5,
          _Visual.still,
        ),
        _Step(
          'Hold it with both hands. Press your fingertips in.',
          6,
          _Visual.expand,
        ),
        _Step(
          'What is the texture? Rough? Smooth? Bumpy? Describe it.',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Move your fingers slowly. Find a new texture area.',
          8,
          _Visual.pulse,
        ),
        _Step('Notice temperature. Warm? Cool? Neutral?', 6, _Visual.still),
        _Step('Notice weight. Light? Heavy? Solid?', 6, _Visual.still),
        _Step(
          'When your mind wanders — bring it back to the texture.',
          6,
          _Visual.still,
        ),
        _Step(
          'You do not need to think about anything else right now.',
          6,
          _Visual.float,
        ),
        _Step(
          'Stay with the sensation for these last seconds.',
          8,
          _Visual.pulse,
        ),
        _Step('Gently release. Notice your hands.', 5, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'sound_mindfulness',
      title: 'Mindful Listening',
      emoji: '🎧',
      color: const Color(0xFF0984E3),
      tagline: 'Sound as your anchor — notice without labelling',
      why:
          'Auditory mindfulness develops attention control and reduces reactivity to overwhelming sounds over time',
      steps: const [
        _Step(
          'Sit still. Let your eyes rest softly on one point.',
          5,
          _Visual.still,
        ),
        _Step('Listen. What is the first sound you notice?', 6, _Visual.pulse),
        _Step(
          'Do not label it — just notice its quality. Pitch. Rhythm.',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Now expand your listening outward. Find a further sound.',
          8,
          _Visual.float,
        ),
        _Step(
          'Notice how sounds overlap without fighting each other.',
          8,
          _Visual.wave,
        ),
        _Step(
          'Sounds are just vibrations. They cannot harm you.',
          6,
          _Visual.still,
        ),
        _Step(
          'When a sound startles or bothers you — notice that reaction.',
          8,
          _Visual.pulse,
        ),
        _Step(
          'You are observing your reactions. Not being controlled by them.',
          6,
          _Visual.still,
        ),
        _Step('Return to the gentlest sound you can find.', 8, _Visual.float),
        _Step('Rest there. Breathe slowly.', 8, _Visual.still),
      ],
    ),

    _Plan(
      id: 'five_senses',
      title: 'Five Senses Check-In',
      emoji: '🌟',
      color: const Color(0xFF55EFC4),
      tagline: 'A 2-minute full presence reset — works anywhere',
      why:
          'Multi-sensory attention anchors the mind in the present moment, interrupting anxiety loops instantly',
      steps: const [
        _Step('Take one slow breath. You are here now.', 5, _Visual.expand),
        _Step(
          'SEE — find 3 things and look at each one for 2 seconds.',
          10,
          _Visual.pulse,
        ),
        _Step(
          'TOUCH — press your hands on your thighs. Feel the texture.',
          8,
          _Visual.still,
        ),
        _Step('HEAR — name 2 sounds you can hear right now.', 8, _Visual.wave),
        _Step(
          'SMELL — take a breath through your nose. What do you smell?',
          6,
          _Visual.expand,
        ),
        _Step(
          'TASTE — notice any taste in your mouth right now.',
          5,
          _Visual.still,
        ),
        _Step(
          'All five senses checked. You are fully present.',
          6,
          _Visual.glow,
        ),
        _Step('Take a slow breath in.', 4, _Visual.expand),
        _Step('Breathe out. You are here.', 5, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'slow_walking',
      title: 'Slow Walking',
      emoji: '🚶',
      color: const Color(0xFFE17055),
      tagline: 'Movement as meditation — mindfulness without sitting still',
      why:
          'Walking mindfulness provides proprioceptive and vestibular input that regulates the nervous system while training attention',
      steps: const [
        _Step(
          'Stand up. Find a space to take 10 slow steps.',
          4,
          _Visual.still,
        ),
        _Step(
          'Begin walking very slowly — each step taking 3 seconds.',
          8,
          _Visual.pulse,
        ),
        _Step('Notice your HEEL lifting from the floor.', 8, _Visual.expand),
        _Step('Notice your FOOT moving through the air.', 8, _Visual.float),
        _Step(
          'Notice your FOOT landing. Feel the weight shift.',
          8,
          _Visual.expand,
        ),
        _Step('Notice your other HEEL lifting.', 8, _Visual.pulse),
        _Step(
          'Feel your body\'s weight shifting with each step.',
          8,
          _Visual.still,
        ),
        _Step(
          'If your mind goes elsewhere — return to the feeling of your foot.',
          6,
          _Visual.still,
        ),
        _Step(
          'Continue slowly. You are not going anywhere — just being.',
          8,
          _Visual.float,
        ),
        _Step(
          'Come to stillness. Notice how your body feels.',
          6,
          _Visual.still,
        ),
      ],
    ),

    _Plan(
      id: 'breath_counting',
      title: 'Counted Breathing',
      emoji: '🔢',
      color: const Color(0xFF6C5CE7),
      tagline: 'Count breaths to 10 — a structured focus for busy minds',
      why:
          'Counting occupies the verbal mind, preventing the wandering that makes pure breath-focus difficult for many autistic individuals',
      repeatCycles: 3,
      steps: const [
        _Step('Breathe IN naturally.', 3, _Visual.expand),
        _Step('Breathe OUT — count "ONE" in your mind.', 4, _Visual.contract),
        _Step('Breathe IN.', 3, _Visual.expand),
        _Step('Breathe OUT — count "TWO."', 4, _Visual.contract),
        _Step(
          'If you lose count — start again at ONE. No judgment.',
          3,
          _Visual.still,
        ),
        _Step('Breathe IN.', 3, _Visual.expand),
        _Step('Breathe OUT — counting continues.', 4, _Visual.contract),
        _Step('Reach TEN, then start again.', 3, _Visual.still),
        _Step('Breathe IN — aware.', 3, _Visual.expand),
        _Step('Breathe OUT — present.', 4, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'object_focus',
      title: 'Single Object Focus',
      emoji: '🔮',
      color: const Color(0xFF74B9FF),
      tagline:
          'Spend 3 minutes really seeing one object — as if for the first time',
      why:
          'Single-object focus strengthens selective attention and the ability to resist distraction — a key mindfulness skill',
      steps: const [
        _Step(
          'Find ONE object near you. Hold it or place it in front of you.',
          4,
          _Visual.still,
        ),
        _Step(
          'Look at it as if you have never seen it before.',
          6,
          _Visual.pulse,
        ),
        _Step('Notice its SHAPE. Every edge. Every curve.', 8, _Visual.still),
        _Step(
          'Notice its COLOUR. Every shade. Every variation.',
          8,
          _Visual.glow,
        ),
        _Step(
          'Notice its SURFACE. Smooth? Matte? Shiny? Worn?',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Turn it if you can. Notice what you could not see before.',
          8,
          _Visual.float,
        ),
        _Step(
          'Notice any LIGHT falling on it. Where is the shadow?',
          8,
          _Visual.glow,
        ),
        _Step(
          'This object exists. You are here with it. Nothing else needed.',
          6,
          _Visual.still,
        ),
        _Step(
          'Take a breath. Look one more time — as if for the last time.',
          8,
          _Visual.pulse,
        ),
        _Step('Set it down. Notice how you feel.', 5, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'loving_kindness',
      title: 'Loving Kindness',
      emoji: '💙',
      color: const Color(0xFFE84393),
      tagline:
          'Send compassion outward — reduces social anxiety and self-criticism',
      why:
          'Loving-kindness meditation activates the caregiving system in the brain, reducing threat responses and building emotional resilience',
      steps: const [
        _Step(
          'Breathe in slowly. Place a hand on your chest.',
          5,
          _Visual.expand,
        ),
        _Step(
          'Think of yourself. Offer yourself kindness: "May I be safe."',
          8,
          _Visual.glow,
        ),
        _Step('"May I be well."', 6, _Visual.glow),
        _Step('"May I be calm and at ease."', 6, _Visual.float),
        _Step('Now think of someone you care about.', 5, _Visual.still),
        _Step('"May you be safe."', 6, _Visual.glow),
        _Step('"May you be well."', 6, _Visual.glow),
        _Step('"May you be calm and at ease."', 6, _Visual.float),
        _Step(
          'Now extend it to everyone you know — all at once.',
          8,
          _Visual.glow,
        ),
        _Step('"May all beings be safe, well, and at ease."', 8, _Visual.float),
        _Step(
          'Breathe in — feel the warmth you have generated.',
          5,
          _Visual.expand,
        ),
        _Step('Breathe out — let it radiate outward.', 6, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'thought_clouds',
      title: 'Watching Thoughts',
      emoji: '☁️',
      color: const Color(0xFFB7C3E8),
      tagline:
          'Watch your thoughts like clouds — without getting pulled into them',
      why:
          'Defused observation of thoughts reduces rumination and breaks the identification with anxious or repetitive thinking',
      steps: const [
        _Step('Close your eyes or soften your gaze.', 4, _Visual.still),
        _Step('Imagine a clear blue sky.', 6, _Visual.float),
        _Step(
          'Notice thoughts appearing — like clouds drifting in.',
          6,
          _Visual.wave,
        ),
        _Step(
          'Do not follow any cloud. Just watch it drift by.',
          8,
          _Visual.wave,
        ),
        _Step(
          'If a thought catches you — notice that, and return to the sky.',
          8,
          _Visual.still,
        ),
        _Step('You are the sky. Not the clouds.', 6, _Visual.float),
        _Step('Thoughts come. Thoughts go. You remain.', 8, _Visual.float),
        _Step('Watch another cloud drift in and out.', 8, _Visual.wave),
        _Step('The sky is unchanged by any cloud.', 6, _Visual.still),
        _Step('Breathe in — sky-like awareness.', 4, _Visual.expand),
        _Step('Breathe out — still and spacious.', 5, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'special_interest',
      title: 'Interest Immersion',
      emoji: '🌟',
      color: const Color(0xFFFFD32A),
      tagline: 'Use your special interest as a mindfulness anchor',
      why:
          'Autistic flow states in areas of special interest produce the same neurological benefits as formal mindfulness practice',
      steps: const [
        _Step(
          'Think of your favourite topic, interest, or subject.',
          5,
          _Visual.still,
        ),
        _Step(
          'Let your mind go fully into it — no holding back.',
          8,
          _Visual.glow,
        ),
        _Step('What is the most fascinating thing about it?', 8, _Visual.pulse),
        _Step('Think about one specific detail you love.', 8, _Visual.pulse),
        _Step(
          'Why does this interest call to you? What does it give you?',
          8,
          _Visual.float,
        ),
        _Step(
          'Notice how your body feels when you think about it.',
          6,
          _Visual.still,
        ),
        _Step(
          'This feeling — aliveness, focus, joy — is your anchor.',
          6,
          _Visual.glow,
        ),
        _Step(
          'You can access this state intentionally, whenever you need it.',
          6,
          _Visual.still,
        ),
        _Step('Take a breath. Stay in this feeling.', 5, _Visual.expand),
        _Step('Breathe out. Carry this with you.', 5, _Visual.contract),
      ],
    ),

    _Plan(
      id: 'body_gratitude',
      title: 'Body Appreciation',
      emoji: '💚',
      color: const Color(0xFF00B894),
      tagline: 'Appreciate what your body is doing right now — as it is',
      why:
          'Body appreciation activates positive interoception, improving the mind-body connection and reducing negative self-perception',
      steps: const [
        _Step(
          'Close your eyes. Turn your attention to your body.',
          4,
          _Visual.still,
        ),
        _Step(
          'Your HEART is beating right now. It has not stopped for you.',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Your LUNGS are breathing without you having to think about it.',
          6,
          _Visual.expand,
        ),
        _Step(
          'Your BRAIN is processing all of this — without instruction.',
          6,
          _Visual.glow,
        ),
        _Step(
          'Your SKIN is protecting you entirely, right now.',
          6,
          _Visual.still,
        ),
        _Step(
          'Your EYES will carry you through the rest of this day.',
          6,
          _Visual.float,
        ),
        _Step(
          'Notice any part of your body that feels okay right now.',
          8,
          _Visual.still,
        ),
        _Step('Your body is doing its best. Always.', 6, _Visual.glow),
        _Step('Breathe in — for your body.', 4, _Visual.expand),
        _Step('Breathe out — thank you.', 6, _Visual.contract),
      ],
    ),
  ];

  static const _tabs = [
    {'id': 'techniques', 'label': 'Techniques', 'emoji': '🧘'},
    {'id': 'understanding', 'label': 'Understanding', 'emoji': '🧩'},
    {'id': 'communication', 'label': 'Communication', 'emoji': '👂'},
    {'id': 'books', 'label': 'Books', 'emoji': '📖'},
    {'id': 'research', 'label': 'Research', 'emoji': '🔬'},
  ];

  Color _tabColor(String id) {
    switch (id) {
      case 'techniques':
        return Color(0xFFA29BFE);
      case 'understanding':
        return Color(0xFF55EFC4);
      case 'communication':
        return Color(0xFF74B9FF);
      case 'books':
        return context.nuruTheme.accentColor.withOpacity(0.6);
      default:
        return const Color(0xFF56CCF2);
    }
  }

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _starCtrl.dispose();
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _svc.fetchAll(forceRefresh: forceRefresh);
      if (mounted)
        setState(() {
          _items = all;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Could not load. Pull to refresh.';
          _loading = false;
        });
    }
  }

  List<MindfulnessItem> get _filtered {
    switch (_tab) {
      case 'understanding':
        return _items.where((i) => i.subcategory == 'understanding').toList();
      case 'communication':
        return _items.where((i) => i.subcategory == 'communication').toList();
      case 'books':
        return _items
            .where((i) => i.type == MindfulnessResourceType.book)
            .toList();
      case 'research':
        return _items
            .where((i) => i.type == MindfulnessResourceType.research)
            .toList();
      default:
        return [];
    }
  }

  // Session engine

  void _startSession(_Plan plan) {
    _timer?.cancel();
    _orbCtrl.stop();
    _orbCtrl.value = 0;
    setState(() {
      _session = plan;
      _stepIndex = 0;
      _cycle = 0;
      _countdown = plan.steps[0].durationSec;
      _running = true;
    });
    _animateStep(plan.steps[0]);
    _tick();
  }

  void _animateStep(_Step step) {
    _orbCtrl.stop();
    _orbCtrl.duration = Duration(seconds: step.durationSec);
    if (step.visual == _Visual.expand) _orbCtrl.forward(from: _orbCtrl.value);
    if (step.visual == _Visual.contract) _orbCtrl.reverse(from: _orbCtrl.value);
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
    final plan = _session!;
    final next = _stepIndex + 1;
    if (next >= plan.steps.length) {
      final nc = _cycle + 1;
      if (nc >= plan.repeatCycles) {
        _complete();
        return;
      }
      setState(() {
        _cycle = nc;
        _stepIndex = 0;
      });
    } else {
      setState(() => _stepIndex = next);
    }
    final step = plan.steps[_stepIndex];
    setState(() => _countdown = step.durationSec);
    _animateStep(step);
  }

  void _complete() {
    _timer?.cancel();
    _orbCtrl.stop();
    setState(() => _running = false);
    _showCompletion(_session!);
  }

  void _stopSession() {
    _timer?.cancel();
    _orbCtrl.stop();
    setState(() {
      _session = null;
      _running = false;
    });
  }

  void _showCompletion(_Plan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
            decoration: BoxDecoration(
              color: const Color(0xFF081F44),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border(
                top: BorderSide(color: plan.color.withOpacity(0.5), width: 1.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(plan.emoji, style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 16),
                const Text(
                  'Present',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You completed ${plan.title}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: plan.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: plan.color.withOpacity(0.35)),
                  ),
                  child: Text(
                    plan.why,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _btn('Again', plan.color, () {
                        Navigator.pop(context);
                        _startSession(plan);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _btn('Done', Colors.white.withOpacity(0.15), () {
                        Navigator.pop(context);
                        setState(() => _session = null);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );

  // Build

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
        backgroundColor: context.nuruTheme.backgroundStart,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.nuruTheme.gradientColors,
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarsPainter(twinkle: _starCtrl.value),
                ),
              ),
            ),
            if (_running && _session != null)
              _buildSession(_session!)
            else
              SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    _buildTabs(),
                    SizedBox(height: 4),
                    Expanded(
                      child: RefreshIndicator(
                        color: context.nuruTheme.accentColor,
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

  Widget _buildSession(_Plan plan) {
    final step = plan.steps[_stepIndex];
    final total = plan.steps.length;
    final progress =
        (_stepIndex + (1 - _countdown / step.durationSec.toDouble())).clamp(
          0.0,
          total.toDouble(),
        ) /
        total;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _stopSession,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF081F44),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: plan.color.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan.emoji}  ${plan.title}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (plan.repeatCycles > 1)
                        Text(
                          'Round ${_cycle + 1} of ${plan.repeatCycles}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(plan.color),
                minHeight: 4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                final done = i < _stepIndex;
                final cur = i == _stepIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: cur ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: cur
                        ? plan.color
                        : (done
                              ? plan.color.withOpacity(0.45)
                              : Colors.white.withOpacity(0.13)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _orbCtrl,
                  _pulseCtrl,
                  _waveCtrl,
                  _glowCtrl,
                ]),
                builder: (_, __) => _buildOrb(plan, step),
              ),
            ),
          ),
          Text(
            '$_countdown',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: plan.color,
              letterSpacing: -2,
            ),
          ),
          Text(
            'seconds',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                step.instruction,
                key: ValueKey('$_cycle-$_stepIndex'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.45,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              plan.why,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withOpacity(0.3),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GestureDetector(
              onTap: _stopSession,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Stop session',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.38),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(_Plan plan, _Step step) {
    double scale;
    double glow;
    switch (step.visual) {
      case _Visual.expand:
        scale = 0.65 + _orbCtrl.value * 0.55;
        glow = 0.15 + _orbCtrl.value * 0.30;
        break;
      case _Visual.contract:
        scale = 1.2 - _orbCtrl.value * 0.55;
        glow = 0.45 - _orbCtrl.value * 0.25;
        break;
      case _Visual.pulse:
        scale = 0.80 + _pulseCtrl.value * 0.25;
        glow = 0.15 + _pulseCtrl.value * 0.28;
        break;
      case _Visual.wave:
        final w = math.sin(_waveCtrl.value * math.pi) * 0.15;
        scale = 0.88 + w;
        glow = 0.20 + w * 0.5;
        break;
      case _Visual.float:
        final f = math.sin(_waveCtrl.value * math.pi * 0.7) * 0.1;
        scale = 0.90 + f;
        glow = 0.28 + f * 0.4;
        break;
      case _Visual.drift:
        scale = 0.85 + _glowCtrl.value * 0.12;
        glow = 0.22 + _glowCtrl.value * 0.15;
        break;
      case _Visual.glow:
        scale = 0.92;
        glow = 0.25 + _glowCtrl.value * 0.35;
        break;
      case _Visual.still:
        scale = 0.92;
        glow = 0.20;
        break;
    }
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 210,
        height: 210,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              plan.color.withOpacity(0.80),
              plan.color.withOpacity(0.25),
              Colors.transparent,
            ],
            stops: const [0.25, 0.60, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: plan.color.withOpacity(glow),
              blurRadius: 70,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: plan.color.withOpacity(glow * 0.5),
              blurRadius: 120,
              spreadRadius: 24,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: plan.color.withOpacity(0.88),
              boxShadow: [BoxShadow(color: plan.color, blurRadius: 20)],
            ),
          ),
        ),
      ),
    );
  }

  // Browse

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
                      'Mindfulness',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Tap a session to begin — no experience needed',
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

  Widget _buildTabs() {
    return SizedBox(
      height: 58,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _tabs.length,
          itemBuilder: (_, i) {
            final t = _tabs[i];
            final id = t['id'] as String;
            final sel = id == _tab;
            final col = _tabColor(id);
            return GestureDetector(
              onTap: () => setState(() => _tab = id),
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
                    Text(t['emoji']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 7),
                    Text(
                      t['label']!,
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

  Widget _buildBody() {
    if (_tab == 'techniques') return _buildGrid();
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();
    final items = _filtered;
    if (items.isEmpty) return _emptyState();
    return _buildList(items);
  }

  Widget _buildGrid() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFA29BFE).withOpacity(0.2),
                  context.nuruTheme.backgroundStart.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFA29BFE).withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                const Text('🧘', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '10 sessions adapted for ASD',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'No "clear your mind." No sitting still. Just present-moment awareness — your way.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ..._plans.map(_buildCard).toList(),
        ],
      ),
    );
  }

  Widget _buildCard(_Plan plan) {
    return GestureDetector(
      onTap: () => _startSession(plan),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  plan.color.withOpacity(0.10),
                  context.nuruTheme.backgroundStart.withOpacity(0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: plan.color.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081F44),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          plan.color.withOpacity(0.7),
                          plan.color.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: plan.color.withOpacity(0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        plan.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.tagline,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.5),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _badge('⏱ ${_dur(plan)}', plan.color),
                            if (plan.repeatCycles > 1) ...[
                              const SizedBox(width: 8),
                              _badge(
                                '${plan.repeatCycles}×',
                                Colors.white.withOpacity(0.25),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: plan.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: plan.color.withOpacity(0.5)),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: plan.color,
                      size: 22,
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

  String _dur(_Plan p) {
    final t = p.steps.fold(0, (s, x) => s + x.durationSec) * p.repeatCycles;
    if (t < 60) return '~${t}s';
    final m = t ~/ 60;
    final s = t % 60;
    return s > 0 ? '~${m}m ${s}s' : '~${m}m';
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10.5,
        color: color == Colors.white.withOpacity(0.25)
            ? Colors.white.withOpacity(0.45)
            : color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildList(List<MindfulnessItem> items) {
    final accent = _tabColor(_tab);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _showSheet(item, accent),
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
                        accent.withOpacity(0.10),
                        context.nuruTheme.backgroundStart.withOpacity(0.88),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.coverUrl != null
                            ? Image.network(
                                item.coverUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _ebox(item.emoji, accent),
                              )
                            : _ebox(item.emoji, accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _pill(_tlabel(item.type), accent),
                                const Spacer(),
                                Text(
                                  item.source,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.3),
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
        },
      ),
    );
  }

  Widget _ebox(String emoji, Color accent) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: accent.withOpacity(0.14),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
    ),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
  );
  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.16),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.32)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: Colors.white.withOpacity(0.85),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  String _tlabel(MindfulnessResourceType t) {
    switch (t) {
      case MindfulnessResourceType.book:
        return '📖  Book';
      case MindfulnessResourceType.research:
        return '🔬  Research';
      case MindfulnessResourceType.guide:
        return '💡  Guide';
      case MindfulnessResourceType.technique:
        return '🧘  Technique';
    }
  }

  void _showSheet(MindfulnessItem item, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.88,
        minChildSize: 0.35,
        builder: (_, sc) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF081F44),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.nuruTheme.accentColor.withOpacity(0.4),
                  ),
                ),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  children: [
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
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    if (item.description != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF081F44),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.nuruTheme.accentColor.withOpacity(
                              0.28,
                            ),
                          ),
                        ),
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.78),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                    if (item.url != null) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withOpacity(0.5),
                                context.nuruTheme.backgroundStart.withOpacity(
                                  0.6,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accent.withOpacity(0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.type == MindfulnessResourceType.book
                                    ? 'Open on Open Library'
                                    : 'Read on PubMed',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            color: _tabColor(_tab),
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Loading…',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    ),
  );
  Widget _errorState() => Center(
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
  Widget _emptyState() => Center(
    child: Text(
      'No results.',
      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
    ),
  );
}

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
