import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../services/stress_relief_service.dart';

enum _Visual { expand, contract, pulse, still, wave, drift, float }

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

// ─────────────────────────────────────────────────────────────

class StressReliefScreen extends StatefulWidget {
  const StressReliefScreen({Key? key}) : super(key: key);
  @override
  State<StressReliefScreen> createState() => _StressReliefScreenState();
}

class _StressReliefScreenState extends State<StressReliefScreen>
    with TickerProviderStateMixin {
  late final AnimationController _starCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _driftCtrl;

  bool _loading = false;
  String? _error;
  List<StressItem> _items = [];
  String _tab = 'techniques';

  final _svc = StressReliefService.instance;

  _Plan? _session;
  int _stepIndex = 0;
  int _countdown = 0;
  int _cycle = 0;
  bool _running = false;
  Timer? _timer;

  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);
  static const Color _deep = Color(0xFF14366D);

  // ══════════════════════════════════════════════════════════
  // 10 STRESS RELIEF GUIDED SESSIONS
  // ══════════════════════════════════════════════════════════

  static final List<_Plan> _plans = [
    _Plan(
      id: 'nature_sounds',
      title: 'Sound Immersion',
      emoji: '🌊',
      color: const Color(0xFF0984E3),
      tagline: 'Focus on a single sound — shut out everything else',
      why:
          'Focused auditory attention activates the parasympathetic nervous system and reduces cortisol',
      steps: const [
        _Step(
          'Find the quietest sound in the room right now.',
          6,
          _Visual.still,
        ),
        _Step('Focus on it completely. What is its quality?', 8, _Visual.pulse),
        _Step('Does it have rhythm? Texture? Pitch?', 8, _Visual.pulse),
        _Step(
          'When your mind wanders — gently return to the sound.',
          6,
          _Visual.still,
        ),
        _Step('Now find the furthest sound you can hear.', 8, _Visual.drift),
        _Step('Hold your attention there. Float with it.', 10, _Visual.float),
        _Step(
          'Bring your attention back to the nearest sound.',
          6,
          _Visual.still,
        ),
        _Step('One slow breath in — let the sound in.', 4, _Visual.expand),
        _Step(
          'One slow breath out — let everything else go.',
          6,
          _Visual.contract,
        ),
      ],
    ),

    _Plan(
      id: 'body_scan_stress',
      title: 'Stress Body Scan',
      emoji: '🔍',
      color: const Color(0xFF6C5CE7),
      tagline: 'Find where stress lives in your body — and release it',
      why:
          'Body scanning identifies and releases held tension, reducing cortisol and activating the vagus nerve',
      steps: const [
        _Step('Close your eyes or soften your gaze.', 4, _Visual.still),
        _Step('Take one slow breath in through your nose.', 4, _Visual.expand),
        _Step('Breathe out slowly. Let your body settle.', 5, _Visual.contract),
        _Step(
          'Notice your HEAD and SCALP. Any tightness? Let it soften.',
          8,
          _Visual.drift,
        ),
        _Step(
          'Notice your JAW. Unclench it. Let it drop slightly.',
          6,
          _Visual.still,
        ),
        _Step(
          'Notice your SHOULDERS. Are they raised? Drop them.',
          6,
          _Visual.contract,
        ),
        _Step(
          'Notice your CHEST. Is your breathing shallow? Deepen it.',
          8,
          _Visual.expand,
        ),
        _Step(
          'Notice your STOMACH. Release any held tension there.',
          6,
          _Visual.still,
        ),
        _Step(
          'Notice your HANDS. Open them. Soften your fingers.',
          5,
          _Visual.contract,
        ),
        _Step(
          'Notice your LEGS and FEET. Let them be heavy.',
          6,
          _Visual.still,
        ),
        _Step('Your whole body is soft. Breathe slowly.', 8, _Visual.float),
        _Step('Take one final deep breath in.', 4, _Visual.expand),
        _Step(
          'And slowly out. Stress has left your body.',
          6,
          _Visual.contract,
        ),
      ],
    ),

    _Plan(
      id: 'sensory_reset',
      title: 'Sensory Reset',
      emoji: '🎨',
      color: const Color(0xFF00B894),
      tagline:
          'Deliberately input calming sensory information to override stress',
      why:
          'Controlled sensory input replaces chaotic sensory overload and restores nervous system regulation',
      steps: const [
        _Step(
          'Find something SOFT near you. Hold it in both hands.',
          8,
          _Visual.still,
        ),
        _Step(
          'Feel every detail of its texture. Slow down.',
          10,
          _Visual.pulse,
        ),
        _Step(
          'Close your eyes if comfortable. Stay with the texture.',
          8,
          _Visual.still,
        ),
        _Step(
          'Now find a SMELL — your drink, a plant, your clothing.',
          8,
          _Visual.drift,
        ),
        _Step(
          'Breathe it in slowly. Let it fill your awareness.',
          8,
          _Visual.expand,
        ),
        _Step(
          'Breathe out. Return to the texture in your hands.',
          6,
          _Visual.contract,
        ),
        _Step('Now focus on the TEMPERATURE of your hands.', 6, _Visual.still),
        _Step('Warm or cool? Tingling? Just notice.', 6, _Visual.pulse),
        _Step(
          'Your senses are yours. This environment is yours.',
          6,
          _Visual.float,
        ),
        _Step('Take one slow breath. You are grounded.', 8, _Visual.still),
      ],
    ),

    _Plan(
      id: 'slow_exhale',
      title: '4-7-8 Breathing',
      emoji: '🌬️',
      color: const Color(0xFF55EFC4),
      tagline: 'Extended exhale activates the relaxation response in minutes',
      why:
          'The 4-7-8 ratio maximally activates the parasympathetic nervous system via extended breath hold and exhale',
      repeatCycles: 4,
      steps: const [
        _Step('Breathe IN through your nose.', 4, _Visual.expand),
        _Step('HOLD your breath.', 7, _Visual.still),
        _Step(
          'Breathe OUT through your mouth — slowly and fully.',
          8,
          _Visual.contract,
        ),
      ],
    ),

    _Plan(
      id: 'progressive_relaxation',
      title: 'Full Body Melt',
      emoji: '🫠',
      color: const Color(0xFFFDCB6E),
      tagline: 'Release every muscle in sequence — from head to floor',
      why:
          'Systematic muscle relaxation discharges physical stress tension and signals safety to the brain',
      steps: const [
        _Step(
          'Sit or lie down. Let your weight sink into the surface.',
          5,
          _Visual.still,
        ),
        _Step('Tense your FACE — scrunch everything. Hold.', 5, _Visual.expand),
        _Step(
          'Release. Feel the difference. Let it spread.',
          5,
          _Visual.contract,
        ),
        _Step(
          'Tense your NECK and SHOULDERS — raise them to your ears.',
          5,
          _Visual.expand,
        ),
        _Step(
          'Drop them completely. Let gravity take them.',
          5,
          _Visual.contract,
        ),
        _Step('Tense your ARMS and FISTS — squeeze tight.', 5, _Visual.expand),
        _Step('Release. Feel your arms become heavy.', 5, _Visual.contract),
        _Step('Tense your STOMACH — pull it in hard.', 5, _Visual.expand),
        _Step('Release. Feel your breath deepen.', 5, _Visual.contract),
        _Step(
          'Tense your LEGS — push heels into the floor.',
          5,
          _Visual.expand,
        ),
        _Step(
          'Release. Let your legs become completely heavy.',
          5,
          _Visual.contract,
        ),
        _Step(
          'Your whole body is melting into the surface.',
          10,
          _Visual.float,
        ),
        _Step('Breathe slowly. You are completely relaxed.', 8, _Visual.still),
      ],
    ),

    _Plan(
      id: 'worry_box',
      title: 'Worry Postponement',
      emoji: '📦',
      color: const Color(0xFFE17055),
      tagline: 'Give your stress a container — then set it aside',
      why:
          'Scheduled worry time reduces rumination by giving the anxious mind a designated space rather than all-day access',
      steps: const [
        _Step(
          'Name one thing that is stressing you right now.',
          6,
          _Visual.still,
        ),
        _Step('Say it clearly in your head. See it.', 5, _Visual.pulse),
        _Step(
          'Now imagine placing it in a box. Any box you like.',
          8,
          _Visual.still,
        ),
        _Step('See yourself closing the lid.', 5, _Visual.contract),
        _Step(
          'The stress is still real. It is just stored — not forgotten.',
          6,
          _Visual.still,
        ),
        _Step(
          'Tell yourself: "I will think about this at [a specific time]."',
          8,
          _Visual.still,
        ),
        _Step(
          'Set that time. It is scheduled. It does not need attention now.',
          6,
          _Visual.still,
        ),
        _Step('Take a breath in.', 4, _Visual.expand),
        _Step(
          'Breathe out. You do not have to carry it every moment.',
          6,
          _Visual.contract,
        ),
        _Step(
          'Right now you are here. The box holds the rest.',
          6,
          _Visual.float,
        ),
      ],
    ),

    _Plan(
      id: 'cold_warm_contrast',
      title: 'Temperature Reset',
      emoji: '🌡️',
      color: const Color(0xFF74B9FF),
      tagline: 'Cold then warm — the fastest physiological stress reset',
      why:
          'Temperature contrast activates the dive reflex (cold) then promotes muscle relaxation (warmth), rapidly lowering arousal',
      steps: const [
        _Step(
          'Get to a sink or have a cold and warm drink available.',
          4,
          _Visual.still,
        ),
        _Step('Splash COLD water on your face and wrists.', 6, _Visual.expand),
        _Step(
          'Let the cold sit. Feel your heart rate respond.',
          6,
          _Visual.still,
        ),
        _Step('Splash again. Notice the clarity it brings.', 5, _Visual.pulse),
        _Step(
          'Now hold something WARM — a mug, warm water, a heat pack.',
          5,
          _Visual.still,
        ),
        _Step(
          'Feel the warmth spreading through your hands.',
          8,
          _Visual.float,
        ),
        _Step(
          'Let your shoulders drop. Your muscles are softening.',
          6,
          _Visual.contract,
        ),
        _Step('One slow breath in.', 4, _Visual.expand),
        _Step(
          'Breathe out. Your nervous system has reset.',
          6,
          _Visual.contract,
        ),
      ],
    ),

    _Plan(
      id: 'safe_place',
      title: 'Safe Place Visualisation',
      emoji: '🏡',
      color: const Color(0xFFA29BFE),
      tagline: 'Build a mental refuge — accessible anywhere, anytime',
      why:
          'Guided mental imagery activates the same brain regions as physical safety, reducing amygdala threat response',
      steps: const [
        _Step(
          'Close your eyes or soften your gaze downward.',
          4,
          _Visual.still,
        ),
        _Step(
          'Think of a place where you feel completely safe and calm.',
          8,
          _Visual.still,
        ),
        _Step(
          'It can be real or imaginary. Inside or outside.',
          5,
          _Visual.still,
        ),
        _Step(
          'See the COLOURS in this place. What do you notice?',
          8,
          _Visual.drift,
        ),
        _Step('Notice the SOUNDS. What can you hear?', 8, _Visual.pulse),
        _Step(
          'Notice what you can TOUCH. Soft, warm, cool, textured?',
          8,
          _Visual.float,
        ),
        _Step(
          'Feel the temperature of this place on your skin.',
          6,
          _Visual.still,
        ),
        _Step(
          'You are completely safe here. Nothing can reach you.',
          8,
          _Visual.float,
        ),
        _Step(
          'Breathe in — draw in the peace of this place.',
          5,
          _Visual.expand,
        ),
        _Step('Breathe out — let it fill you completely.', 6, _Visual.contract),
        _Step(
          'Remember: this place is always available. Just close your eyes.',
          6,
          _Visual.still,
        ),
      ],
    ),

    _Plan(
      id: 'movement_shake',
      title: 'Shake It Out',
      emoji: '🕺',
      color: const Color(0xFFE84393),
      tagline:
          'Let your body physically discharge stress — animals do it naturally',
      why:
          'Shaking and movement metabolise stress hormones and discharge tension stored in the muscles and fascia',
      steps: const [
        _Step('Stand up if you can.', 3, _Visual.still),
        _Step('Shake your HANDS — loose and floppy.', 8, _Visual.wave),
        _Step('Let the shaking travel up your ARMS.', 8, _Visual.wave),
        _Step(
          'Now shake your WHOLE BODY — legs, torso, everything.',
          10,
          _Visual.wave,
        ),
        _Step(
          'Let it be silly. Let it be whatever it needs to be.',
          10,
          _Visual.wave,
        ),
        _Step('Gradually slow the shaking down.', 6, _Visual.pulse),
        _Step('Come to stillness. Feel your body now.', 6, _Visual.still),
        _Step(
          'Notice the tingling, the warmth, the lightness.',
          6,
          _Visual.float,
        ),
        _Step('One deep breath in.', 4, _Visual.expand),
        _Step(
          'Slowly out. The stress has left your body.',
          6,
          _Visual.contract,
        ),
      ],
    ),

    _Plan(
      id: 'gratitude_anchor',
      title: 'Gratitude Anchor',
      emoji: '✨',
      color: const Color(0xFFFFD32A),
      tagline:
          'Shift your brain from threat mode to resource mode in 2 minutes',
      why:
          'Gratitude activates the medial prefrontal cortex and releases dopamine, directly countering the stress response',
      steps: const [
        _Step('Take one slow breath in.', 4, _Visual.expand),
        _Step('Breathe out slowly.', 5, _Visual.contract),
        _Step(
          'Think of ONE thing in your life that is working.',
          8,
          _Visual.still,
        ),
        _Step(
          'It can be small. A warm drink. A comfortable chair. A song.',
          6,
          _Visual.still,
        ),
        _Step('Hold it in your attention. Let it be real.', 8, _Visual.pulse),
        _Step('Think of ONE person who is glad you exist.', 8, _Visual.float),
        _Step(
          'Think of ONE thing your body is doing well right now.',
          8,
          _Visual.still,
        ),
        _Step(
          'Notice the shift in your chest. That is your brain changing.',
          6,
          _Visual.pulse,
        ),
        _Step(
          'Take a slow breath in — for all three things.',
          5,
          _Visual.expand,
        ),
        _Step(
          'Breathe out — let gratitude rest in your body.',
          6,
          _Visual.contract,
        ),
      ],
    ),
  ];

  static const _tabs = [
    {'id': 'techniques', 'label': 'Techniques', 'emoji': '🌿'},
    {'id': 'understanding', 'label': 'Understanding', 'emoji': '⚡'},
    {'id': 'communication', 'label': 'Communication', 'emoji': '🗣️'},
    {'id': 'books', 'label': 'Books', 'emoji': '📖'},
    {'id': 'research', 'label': 'Research', 'emoji': '🔬'},
  ];

  Color _tabColor(String id) {
    switch (id) {
      case 'techniques':
        return const Color(0xFF00B894);
      case 'understanding':
        return const Color(0xFF0984E3);
      case 'communication':
        return const Color(0xFF6C5CE7);
      case 'books':
        return const Color(0xFF8EA2D7);
      default:
        return const Color(0xFF56CCF2);
    }
  }

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _driftCtrl = AnimationController(
      duration: const Duration(seconds: 3),
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
    _driftCtrl.dispose();
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

  List<StressItem> get _filtered {
    switch (_tab) {
      case 'understanding':
        return _items.where((i) => i.subcategory == 'understanding').toList();
      case 'communication':
        return _items.where((i) => i.subcategory == 'communication').toList();
      case 'books':
        return _items.where((i) => i.type == StressResourceType.book).toList();
      case 'research':
        return _items
            .where((i) => i.type == StressResourceType.research)
            .toList();
      default:
        return [];
    }
  }

  // ── Session engine ────────────────────────────────────────

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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_dive.withOpacity(0.97), _night.withOpacity(0.99)],
              ),
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
                  'Well done',
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
                      child: _btn('Repeat', plan.color, () {
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
        backgroundColor: _night,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_sailing, _deep],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    _buildTabs(),
                    const SizedBox(height: 4),
                    Expanded(
                      child: RefreshIndicator(
                        color: _sailing,
                        backgroundColor: _dive,
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

  // ── Active session ────────────────────────────────────────

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
                      color: _night.withOpacity(0.5),
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
                  _driftCtrl,
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
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
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
        glow = 0.18 + _orbCtrl.value * 0.32;
        break;
      case _Visual.contract:
        scale = 1.2 - _orbCtrl.value * 0.55;
        glow = 0.50 - _orbCtrl.value * 0.28;
        break;
      case _Visual.pulse:
        scale = 0.82 + _pulseCtrl.value * 0.22;
        glow = 0.18 + _pulseCtrl.value * 0.25;
        break;
      case _Visual.wave:
        final w = math.sin(_waveCtrl.value * math.pi) * 0.18;
        scale = 0.88 + w;
        glow = 0.22 + w * 0.4;
        break;
      case _Visual.drift:
        scale = 0.85 + _driftCtrl.value * 0.12;
        glow = 0.20 + _driftCtrl.value * 0.15;
        break;
      case _Visual.float:
        final f = math.sin(_driftCtrl.value * math.pi) * 0.08;
        scale = 0.90 + f;
        glow = 0.30 + f * 0.5;
        break;
      case _Visual.still:
        scale = 0.92;
        glow = 0.22;
        break;
    }
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              plan.color.withOpacity(0.85),
              plan.color.withOpacity(0.3),
              Colors.transparent,
            ],
            stops: const [0.28, 0.62, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: plan.color.withOpacity(glow),
              blurRadius: 60,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: plan.color.withOpacity(glow / 2),
              blurRadius: 100,
              spreadRadius: 18,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: plan.color.withOpacity(0.9),
              boxShadow: [BoxShadow(color: plan.color, blurRadius: 18)],
            ),
          ),
        ),
      ),
    );
  }

  // ── Browse ────────────────────────────────────────────────

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
              colors: [_dive.withOpacity(0.75), _night.withOpacity(0.80)],
            ),
            border: Border(
              bottom: BorderSide(color: _sailing.withOpacity(0.4)),
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
                      'Stress Relief',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Tap a technique to start a guided session',
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
      color: _night.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _sailing.withOpacity(0.5), width: 1.2),
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
                        ? [col.withOpacity(0.45), _night.withOpacity(0.75)]
                        : [_dive.withOpacity(0.6), _night.withOpacity(0.75)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel
                        ? col.withOpacity(0.7)
                        : _sailing.withOpacity(0.3),
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
                  const Color(0xFF00B894).withOpacity(0.2),
                  _night.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00B894).withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Feeling stressed or overwhelmed?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap any technique to be guided through it. No reading needed.',
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
                  _night.withOpacity(0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: plan.color.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _night.withOpacity(0.5),
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
                          color: plan.color.withOpacity(0.28),
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

  Widget _buildList(List<StressItem> items) {
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
                        _night.withOpacity(0.88),
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
  String _tlabel(StressResourceType t) {
    switch (t) {
      case StressResourceType.book:
        return '📖  Book';
      case StressResourceType.research:
        return '🔬  Research';
      case StressResourceType.guide:
        return '💡  Guide';
      case StressResourceType.technique:
        return '🌿  Technique';
    }
  }

  void _showSheet(StressItem item, Color accent) {
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_dive.withOpacity(0.97), _night.withOpacity(0.99)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(color: _sailing.withOpacity(0.4)),
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _night.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _sailing.withOpacity(0.28)),
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
                                _night.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accent.withOpacity(0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.type == StressResourceType.book
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
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _sailing.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sailing.withOpacity(0.55)),
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
