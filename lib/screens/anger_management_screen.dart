import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../services/anger_management_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// ANGER MANAGEMENT SCREEN
//  Session data model

enum _Visual { expand, contract, pulse, still, shake }

class _Step {
  final String instruction;
  final int durationSec;
  final _Visual visual;
  const _Step(this.instruction, this.durationSec, this.visual);
}

class _SessionPlan {
  final String id;
  final String title;
  final String emoji;
  final String why;
  final Color color;
  final List<_Step> steps;
  final int repeatCycles;
  const _SessionPlan({
    required this.id,
    required this.title,
    required this.emoji,
    required this.why,
    required this.color,
    required this.steps,
    this.repeatCycles = 1,
  });
}

class AngerManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const AngerManagementScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<AngerManagementScreen> createState() => _AngerManagementScreenState();
}

class _AngerManagementScreenState extends State<AngerManagementScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _starCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;

  // Data
  bool _loading = false;
  String? _error;
  List<AngerResourceItem> _items = [];
  String _tab = 'techniques';

  final _svc = AngerManagementService.instance;

  // Active session state
  _SessionPlan? _session;
  int _stepIndex = 0;
  int _countdown = 0;
  int _cycle = 0;
  bool _running = false;
  Timer? _timer;

  // Palette

  // SESSION PLANS
  static final List<_SessionPlan> _plans = [
    _SessionPlan(
      id: 'physiological_sigh',
      title: 'Physiological Sigh',
      emoji: '🌬️',
      color: const Color(0xFF43C6AC),
      why:
          'Long exhale activates your parasympathetic nervous system instantly',
      repeatCycles: 3,
      steps: const [
        _Step('Breathe IN fully through your nose', 4, _Visual.expand),
        _Step('One more short sniff — top up your lungs', 2, _Visual.expand),
        _Step('Breathe OUT slowly through your mouth', 8, _Visual.contract),
        _Step('Feel your heart rate drop', 2, _Visual.still),
      ],
    ),

    _SessionPlan(
      id: 'box_breathing',
      title: 'Box Breathing',
      emoji: '📦',
      color: const Color(0xFF56CCF2),
      why:
          'Equal-ratio breathing resets CO₂ balance and calms the threat response',
      repeatCycles: 4,
      steps: const [
        _Step('Breathe IN — 4 counts', 4, _Visual.expand),
        _Step('HOLD — 4 counts', 4, _Visual.still),
        _Step('Breathe OUT — 4 counts', 4, _Visual.contract),
        _Step('HOLD — 4 counts', 4, _Visual.still),
      ],
    ),

    _SessionPlan(
      id: 'cold_water',
      title: 'Cold Water Reset',
      emoji: '🧊',
      color: const Color(0xFF74B9FF),
      why:
          'Cold water triggers the dive reflex — your heart rate drops in 30 seconds',
      steps: const [
        _Step('Go to a sink or get a cold drink', 3, _Visual.still),
        _Step('Splash cold water on your face and wrists', 5, _Visual.pulse),
        _Step('Keep splashing — feel the cold', 10, _Visual.pulse),
        _Step('Hold a cold cup or ice with both hands', 15, _Visual.still),
        _Step('Take a slow breath. Feel the difference.', 5, _Visual.contract),
      ],
    ),

    _SessionPlan(
      id: 'progressive_muscle',
      title: 'Muscle Release',
      emoji: '💪',
      color: const Color(0xFFFD79A8),
      why: 'Releasing tension physically signals safety to your nervous system',
      steps: const [
        _Step('Squeeze your FISTS as tight as you can', 5, _Visual.expand),
        _Step('Release — let your hands fall open', 4, _Visual.contract),
        _Step('Raise your SHOULDERS to your ears, tense', 5, _Visual.expand),
        _Step('Drop them — let go completely', 4, _Visual.contract),
        _Step('Scrunch your FACE — eyes, jaw, everything', 5, _Visual.expand),
        _Step('Release your face — jaw open, eyes soft', 4, _Visual.contract),
        _Step('Tighten your STOMACH — pull it in hard', 5, _Visual.expand),
        _Step('Release and breathe out slowly', 6, _Visual.contract),
        _Step('Push HEELS into the floor hard', 5, _Visual.expand),
        _Step(
          'Release legs — feel the ground support you',
          4,
          _Visual.contract,
        ),
        _Step('Your body is calm now. Breathe slowly.', 8, _Visual.still),
      ],
    ),

    _SessionPlan(
      id: 'grounding_54321',
      title: '5-4-3-2-1 Grounding',
      emoji: '🌱',
      color: const Color(0xFF55EFC4),
      why:
          'Sensory focus interrupts the anger loop by activating your rational brain',
      steps: const [
        _Step('Look around. Name 5 things you can SEE.', 12, _Visual.pulse),
        _Step('Touch 4 things near you. Feel the texture.', 12, _Visual.pulse),
        _Step('Listen. Name 3 things you can HEAR.', 12, _Visual.still),
        _Step('Name 2 things you can SMELL right now.', 10, _Visual.still),
        _Step('Notice 1 thing you can TASTE.', 8, _Visual.still),
        _Step('Take one slow breath. You\'re here now.', 6, _Visual.contract),
      ],
    ),

    _SessionPlan(
      id: 'stop_skill',
      title: 'STOP Skill',
      emoji: '🛑',
      color: const Color(0xFFE17055),
      why: 'DBT\'s emergency brake — creates a pause before you react',
      steps: const [
        _Step('STOP — freeze. Do not move. Do not speak.', 5, _Visual.still),
        _Step('Take one step back physically if you can.', 3, _Visual.still),
        _Step('Take a slow breath in through your nose.', 4, _Visual.expand),
        _Step('Breathe out slowly through your mouth.', 6, _Visual.contract),
        _Step('OBSERVE — what is actually happening here?', 8, _Visual.pulse),
        _Step('What does your body feel like right now?', 6, _Visual.pulse),
        _Step('What is the most EFFECTIVE thing to do?', 8, _Visual.still),
        _Step('Not the most satisfying. Most effective.', 5, _Visual.still),
      ],
    ),

    _SessionPlan(
      id: 'vagal_humming',
      title: 'Vagal Humming',
      emoji: '🎵',
      color: const Color(0xFFA29BFE),
      why: 'Humming vibrates the vagus nerve directly — forces the body calm',
      repeatCycles: 5,
      steps: const [
        _Step('Breathe IN deeply through your nose.', 3, _Visual.expand),
        _Step('Close your lips. HUM on the exhale.', 6, _Visual.contract),
        _Step('Feel the vibration in your throat and chest.', 3, _Visual.pulse),
      ],
    ),

    _SessionPlan(
      id: 'heavy_work',
      title: 'Heavy Work Discharge',
      emoji: '🏋️',
      color: const Color(0xFFFDCB6E),
      why:
          'Proprioceptive input grounds your nervous system and burns off adrenaline',
      steps: const [
        _Step('Stand up. Push BOTH hands against a wall.', 10, _Visual.expand),
        _Step('Push with full strength — don\'t move it.', 10, _Visual.expand),
        _Step('Release. Shake your arms out.', 5, _Visual.shake),
        _Step('Do 10 SLOW press-ups or wall push-ups.', 20, _Visual.pulse),
        _Step('Stand. Do 10 slow, heavy SQUATS.', 20, _Visual.pulse),
        _Step('Stop. Breathe slowly. Feel your body.', 8, _Visual.still),
      ],
    ),

    _SessionPlan(
      id: 'eft_tapping',
      title: 'EFT Tapping',
      emoji: '✋',
      color: const Color(0xFFE84393),
      why: 'Tapping acupressure points sends calming signals to the amygdala',
      steps: const [
        _Step('Rate your anger 0–10. Remember the number.', 5, _Visual.still),
        _Step(
          'Tap KARATE CHOP: side of your hand. Say: "Even though I\'m angry, I accept myself."',
          10,
          _Visual.pulse,
        ),
        _Step('Tap TOP OF HEAD — 7 times. "This anger."', 5, _Visual.pulse),
        _Step('Tap EYEBROW — inner edge. 7 times.', 5, _Visual.pulse),
        _Step('Tap SIDE OF EYE — outer corner. 7 times.', 5, _Visual.pulse),
        _Step('Tap UNDER EYE — cheekbone. 7 times.', 5, _Visual.pulse),
        _Step('Tap UNDER NOSE. 7 times.', 5, _Visual.pulse),
        _Step('Tap CHIN crease. 7 times.', 5, _Visual.pulse),
        _Step('Tap COLLARBONE — just below. 7 times.', 5, _Visual.pulse),
        _Step('Tap UNDER ARM — side of chest. 7 times.', 5, _Visual.pulse),
        _Step(
          'Take a breath. Rate your anger again 0–10.',
          8,
          _Visual.contract,
        ),
      ],
    ),

    _SessionPlan(
      id: 'deep_pressure',
      title: 'Deep Pressure',
      emoji: '🫂',
      color: const Color(0xFF6C5CE7),
      why: 'Firm pressure activates receptors that directly reduce cortisol',
      steps: const [
        _Step('Sit or lie down comfortably.', 3, _Visual.still),
        _Step(
          'Cross your arms and SQUEEZE yourself firmly.',
          10,
          _Visual.expand,
        ),
        _Step('Hold the pressure. Breathe slowly in.', 5, _Visual.expand),
        _Step('Breathe slowly out. Keep holding.', 6, _Visual.contract),
        _Step('Now wrap in a blanket if one is nearby.', 5, _Visual.still),
        _Step('Feel the weight and pressure on your body.', 10, _Visual.still),
        _Step('Breathe in slowly.', 4, _Visual.expand),
        _Step('Breathe out slowly. You are safe.', 6, _Visual.contract),
        _Step('Stay in this position for as long as needed.', 8, _Visual.still),
      ],
    ),
  ];

  // Tabs

  static const _tabs = [
    {'id': 'techniques', 'label': 'Techniques', 'emoji': '🛠️'},
    {'id': 'understanding', 'label': 'Understanding', 'emoji': '🔥'},
    {'id': 'communication', 'label': 'Communication', 'emoji': '💬'},
    {'id': 'books', 'label': 'Books', 'emoji': '📖'},
    {'id': 'research', 'label': 'Research', 'emoji': '🔬'},
  ];

  Color _tabColor(String id) {
    switch (id) {
      case 'techniques':
        return Color(0xFF43C6AC);
      case 'understanding':
        return Color(0xFFFA709A);
      case 'communication':
        return context.nuruTheme.accentColor.withOpacity(0.4);
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
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _starCtrl.dispose();
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // Data loading

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

  List<AngerResourceItem> get _filtered {
    switch (_tab) {
      case 'understanding':
        return _items.where((i) => i.subcategory == 'understanding').toList();
      case 'communication':
        return _items.where((i) => i.subcategory == 'communication').toList();
      case 'books':
        return _items.where((i) => i.type == AngerResourceType.book).toList();
      case 'research':
        return _items
            .where((i) => i.type == AngerResourceType.research)
            .toList();
      default:
        return [];
    }
  }

  // SESSION ENGINE
  void _startSession(_SessionPlan plan) {
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
    _tickTimer();
  }

  void _animateStep(_Step step) {
    _orbCtrl.stop();
    _orbCtrl.duration = Duration(seconds: step.durationSec);
    switch (step.visual) {
      case _Visual.expand:
        _orbCtrl.forward(from: _orbCtrl.value);
        break;
      case _Visual.contract:
        _orbCtrl.reverse(from: _orbCtrl.value);
        break;
      case _Visual.shake:
        _shakeCtrl.repeat(reverse: true);
        Future.delayed(Duration(seconds: step.durationSec), () {
          if (mounted) _shakeCtrl.stop();
        });
        break;
      case _Visual.pulse:
      case _Visual.still:
        break;
    }
  }

  void _tickTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) _advanceStep();
    });
  }

  void _advanceStep() {
    final plan = _session!;
    final nextIndex = _stepIndex + 1;

    if (nextIndex >= plan.steps.length) {
      // End of one cycle
      final nextCycle = _cycle + 1;
      if (nextCycle >= plan.repeatCycles) {
        _completeSession();
        return;
      }
      setState(() {
        _cycle = nextCycle;
        _stepIndex = 0;
      });
    } else {
      setState(() => _stepIndex = nextIndex);
    }

    final step = plan.steps[_stepIndex];
    setState(() => _countdown = step.durationSec);
    _animateStep(step);
  }

  void _completeSession() {
    _timer?.cancel();
    _orbCtrl.stop();
    setState(() {
      _running = false;
    });
    _showCompletionSheet(_session!);
  }

  void _stopSession() {
    _timer?.cancel();
    _orbCtrl.stop();
    _shakeCtrl.stop();
    setState(() {
      _session = null;
      _running = false;
    });
  }

  void _showCompletionSheet(_SessionPlan plan) {
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
                      child: _sheetBtn('Repeat', plan.color, () {
                        Navigator.pop(context);
                        _startSession(plan);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sheetBtn(
                        'Done',
                        Colors.white.withOpacity(0.15),
                        () {
                          Navigator.pop(context);
                          setState(() => _session = null);
                        },
                      ),
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

  Widget _sheetBtn(String label, Color bg, VoidCallback onTap) {
    return GestureDetector(
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
  }

  // BUILD
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
            // Active session overlays the whole screen
            if (_running && _session != null)
              _buildActiveSession(_session!)
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

  // ACTIVE SESSION UI
  Widget _buildActiveSession(_SessionPlan plan) {
    final step = plan.steps[_stepIndex];
    final totalSteps = plan.steps.length;
    final progress =
        (_stepIndex + (1 - _countdown / step.durationSec)).clamp(
          0.0,
          totalSteps.toDouble(),
        ) /
        totalSteps;

    return SafeArea(
      child: Column(
        children: [
          // Top bar
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
                        plan.emoji + '  ' + plan.title,
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
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

          //  Step dots
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (i) {
                final done = i < _stepIndex;
                final current = i == _stepIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: current ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: current
                        ? plan.color
                        : (done
                              ? plan.color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Orb
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_orbCtrl, _pulseCtrl, _shakeCtrl]),
                builder: (_, __) => _buildOrb(plan, step),
              ),
            ),
          ),

          // Countdown
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

          // Instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Why it works note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              plan.why,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.35),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Stop button
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
                    color: Colors.white.withOpacity(0.4),
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

  Widget _buildOrb(_SessionPlan plan, _Step step) {
    double scale;
    double glowOpacity;

    switch (step.visual) {
      case _Visual.expand:
        scale = 0.7 + _orbCtrl.value * 0.55;
        glowOpacity = 0.2 + _orbCtrl.value * 0.35;
        break;
      case _Visual.contract:
        scale = 1.25 - _orbCtrl.value * 0.55;
        glowOpacity = 0.55 - _orbCtrl.value * 0.35;
        break;
      case _Visual.pulse:
        scale = 0.85 + _pulseCtrl.value * 0.25;
        glowOpacity = 0.2 + _pulseCtrl.value * 0.3;
        break;
      case _Visual.shake:
        final shake = math.sin(_shakeCtrl.value * math.pi * 4) * 8;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: _orbWidget(plan.color, 0.95, 0.3),
        );
      case _Visual.still:
        scale = 0.95;
        glowOpacity = 0.25;
    }

    return _orbWidget(plan.color, scale, glowOpacity);
  }

  Widget _orbWidget(Color color, double scale, double glow) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.85),
              color.withOpacity(0.3),
              Colors.transparent,
            ],
            stops: const [0.3, 0.65, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(glow),
              blurRadius: 60,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: color.withOpacity(glow / 2),
              blurRadius: 100,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.9),
              boxShadow: [BoxShadow(color: color, blurRadius: 20)],
            ),
          ),
        ),
      ),
    );
  }

  // BROWSE UI
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
                child: _iconBtn(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anger Management',
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
                child: _iconBtn(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required double size}) => Container(
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
    if (_tab == 'techniques') return _buildTechniqueGrid();
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();
    final items = _filtered;
    if (items.isEmpty) return _emptyState();
    return _buildGenericList(items);
  }

  // Technique grid

  Widget _buildTechniqueGrid() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          // Urgency header
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE17055).withOpacity(0.2),
                  context.nuruTheme.backgroundStart.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE17055).withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Feel angry right now?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap any technique below to start immediately. No reading needed.',
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

          // Technique cards
          ..._plans.map(_buildTechniqueCard).toList(),
        ],
      ),
    );
  }

  Widget _buildTechniqueCard(_SessionPlan plan) {
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
                  // Orb preview
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
                          color: plan.color.withOpacity(0.3),
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

                  // Info
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
                          plan.why,
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
                            // Duration badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: plan.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: plan.color.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                '⏱ ${_totalDuration(plan)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: plan.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (plan.repeatCycles > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${plan.repeatCycles} rounds',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Start arrow
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

  String _totalDuration(_SessionPlan plan) {
    final total =
        plan.steps.fold(0, (s, step) => s + step.durationSec) *
        plan.repeatCycles;
    if (total < 60) return '~${total}s';
    final m = total ~/ 60;
    final s = total % 60;
    return s > 0 ? '~${m}m ${s}s' : '~${m}m';
  }

  // Generic list (guides, books, research)

  Widget _buildGenericList(List<AngerResourceItem> items) {
    final accent = _tabColor(_tab);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _showInfoSheet(item, accent),
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
                                    _emojiBox(item.emoji, accent),
                              )
                            : _emojiBox(item.emoji, accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _pill(_typeLabel(item.type), accent),
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

  Widget _emojiBox(String emoji, Color accent) => Container(
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

  String _typeLabel(AngerResourceType t) {
    switch (t) {
      case AngerResourceType.book:
        return '📖  Book';
      case AngerResourceType.research:
        return '🔬  Research';
      case AngerResourceType.guide:
        return '💡  Guide';
      case AngerResourceType.technique:
        return '🛠️  Technique';
    }
  }

  void _showInfoSheet(AngerResourceItem item, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.88,
        minChildSize: 0.35,
        builder: (ctx, sc) => ClipRRect(
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
                          Navigator.pop(context); /* launchUrl */
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
                                item.type == AngerResourceType.book
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
