import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../services/self_control_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// SELF CONTROL SCREEN
enum _Visual { expand, contract, pulse, still, wave, shrink }

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

class SelfControlScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const SelfControlScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<SelfControlScreen> createState() => _SelfControlScreenState();
}

class _SelfControlScreenState extends State<SelfControlScreen>
    with TickerProviderStateMixin {
  late final AnimationController _starCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;

  bool _loading = false;
  String? _error;
  List<SelfControlItem> _items = [];
  String _tab = 'techniques';

  final _svc = SelfControlService.instance;

  _Plan? _session;
  int _stepIndex = 0;
  int _countdown = 0;
  int _cycle = 0;
  bool _running = false;
  Timer? _timer;

  // SESSION PLANS — 10 guided self-control exercises
  static final List<_Plan> _plans = [
    //  1. Urge Surfing
    _Plan(
      id: 'urge_surfing',
      title: 'Urge Surfing',
      emoji: '🌊',
      color: const Color(0xFF0984E3),
      tagline: 'Ride the urge like a wave — without acting on it',
      why:
          'Urges peak in 20–30 seconds then fall. Surfing them trains your brain to detach action from impulse.',
      repeatCycles: 1,
      steps: const [
        _Step(
          'Notice the urge. Do not judge it. Just see it.',
          5,
          _Visual.still,
        ),
        _Step('Say to yourself: "I feel an urge to ____."', 5, _Visual.still),
        _Step(
          'Now watch it. Where do you feel it in your body?',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Breathe in slowly. The urge is rising — that is okay.',
          5,
          _Visual.expand,
        ),
        _Step(
          'Breathe out. You are observing, not obeying.',
          6,
          _Visual.contract,
        ),
        _Step('The urge is at its peak. Stay with it.', 8, _Visual.pulse),
        _Step('Breathe in. The wave is about to break.', 4, _Visual.expand),
        _Step(
          'Breathe out slowly. Feel it begin to fall.',
          6,
          _Visual.contract,
        ),
        _Step('It is falling. You did not act. Notice that.', 6, _Visual.still),
        _Step('Breathe in — you chose.', 4, _Visual.expand),
        _Step('Breathe out — well done.', 5, _Visual.contract),
      ],
    ),

    // HALT Check
    _Plan(
      id: 'halt_check',
      title: 'HALT Check',
      emoji: '🛑',
      color: const Color(0xFFE17055),
      tagline: 'Before you act — are you Hungry, Angry, Lonely, or Tired?',
      why:
          'HALT is a clinical tool: most impulsive actions happen when basic needs are unmet.',
      steps: const [
        _Step('STOP before you act. Just pause.', 3, _Visual.still),
        _Step('H — Am I HUNGRY right now?', 6, _Visual.pulse),
        _Step('A — Am I ANGRY or emotionally activated?', 6, _Visual.pulse),
        _Step('L — Am I LONELY or feeling unseen?', 6, _Visual.pulse),
        _Step('T — Am I TIRED or physically depleted?', 6, _Visual.pulse),
        _Step(
          'If yes to any — that need is driving this impulse.',
          6,
          _Visual.still,
        ),
        _Step('What does your body actually need right now?', 8, _Visual.still),
        _Step(
          'Address the real need. The impulse will reduce.',
          6,
          _Visual.contract,
        ),
      ],
    ),

    // 10-Second Pause
    _Plan(
      id: 'ten_second_pause',
      title: '10-Second Pause',
      emoji: '⏸️',
      color: const Color(0xFF6C5CE7),
      tagline: 'The single most powerful habit — pause before every response',
      why:
          'A 10-second delay between urge and action gives your prefrontal cortex time to engage.',
      repeatCycles: 3,
      steps: const [
        _Step('Feel the urge. Do not act yet.', 2, _Visual.still),
        _Step('10 — breathe in.', 1, _Visual.expand),
        _Step('9', 1, _Visual.expand),
        _Step('8', 1, _Visual.still),
        _Step('7', 1, _Visual.still),
        _Step('6 — breathe out.', 1, _Visual.contract),
        _Step('5', 1, _Visual.contract),
        _Step('4', 1, _Visual.still),
        _Step('3', 1, _Visual.still),
        _Step('2 — almost there.', 1, _Visual.still),
        _Step('1. Now choose your response.', 4, _Visual.pulse),
      ],
    ),

    // If-Then Planning
    _Plan(
      id: 'if_then',
      title: 'If-Then Planning',
      emoji: '📋',
      color: const Color(0xFF00B894),
      tagline:
          'Pre-decide your response so your brain doesn\'t have to in the moment',
      why:
          'Implementation intentions (if-then plans) double the rate of successful self-control.',
      steps: const [
        _Step('Think of a situation where you lose control.', 8, _Visual.still),
        _Step('Name the trigger clearly in your head.', 6, _Visual.pulse),
        _Step('Now create your IF: "IF this happens…"', 8, _Visual.still),
        _Step('Now create your THEN: "…THEN I will ____."', 10, _Visual.pulse),
        _Step(
          'Make the THEN as specific and small as possible.',
          8,
          _Visual.still,
        ),
        _Step(
          'Example: "If I feel the urge to interrupt — I will press my feet into the floor."',
          10,
          _Visual.still,
        ),
        _Step('Run through your If-Then one more time.', 8, _Visual.pulse),
        _Step(
          'Your brain has now pre-decided. It will remember.',
          6,
          _Visual.still,
        ),
      ],
    ),

    // Stimulus Control
    _Plan(
      id: 'stimulus_control',
      title: 'Remove the Trigger',
      emoji: '🚫',
      color: const Color(0xFFD63031),
      tagline: 'Change your environment so the impulse never gets triggered',
      why:
          'Stimulus control removes the need for willpower by eliminating the trigger entirely.',
      steps: const [
        _Step(
          'Think about your strongest recurring impulse.',
          6,
          _Visual.still,
        ),
        _Step(
          'What environment or trigger activates it most?',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Can you remove that trigger from your environment?',
          8,
          _Visual.still,
        ),
        _Step(
          'Can you add distance between yourself and it?',
          8,
          _Visual.still,
        ),
        _Step(
          'Can you add friction — make it harder to access?',
          8,
          _Visual.still,
        ),
        _Step(
          'Can you replace it with something else in that spot?',
          8,
          _Visual.pulse,
        ),
        _Step(
          'Plan ONE environment change you will make today.',
          10,
          _Visual.still,
        ),
        _Step(
          'That one change removes the need for willpower.',
          6,
          _Visual.contract,
        ),
      ],
    ),

    //Delayed Gratification Training
    _Plan(
      id: 'delay_training',
      title: 'Delay Training',
      emoji: '⏳',
      color: const Color(0xFFFDCB6E),
      tagline: 'Practice tolerating the wait — builds the muscle over time',
      why:
          'Deliberately practising small delays strengthens inhibitory control in the prefrontal cortex.',
      repeatCycles: 3,
      steps: const [
        _Step(
          'Identify something you want right now but can wait for.',
          6,
          _Visual.still,
        ),
        _Step(
          'Start the wait. Feel the discomfort — that is the exercise.',
          4,
          _Visual.pulse,
        ),
        _Step(
          'Breathe in slowly. You are training, not suffering.',
          4,
          _Visual.expand,
        ),
        _Step('Hold. Sit with the wanting.', 6, _Visual.still),
        _Step('Breathe out. The discomfort is the work.', 5, _Visual.contract),
        _Step(
          'Notice: the urge did not get worse. It stayed.',
          5,
          _Visual.still,
        ),
        _Step(
          'You have waited. You did not break. That is the win.',
          4,
          _Visual.pulse,
        ),
      ],
    ),

    //Cognitive Defusion
    _Plan(
      id: 'cognitive_defusion',
      title: 'Defuse the Thought',
      emoji: '💭',
      color: const Color(0xFFA29BFE),
      tagline:
          'Separate yourself from the impulse thought — you are not your urge',
      why:
          'ACT defusion reduces the power of impulse thoughts by creating distance from them.',
      steps: const [
        _Step(
          'Notice the impulse thought. What is it saying?',
          6,
          _Visual.still,
        ),
        _Step(
          'Now say: "I notice I am having the thought that I should ____."',
          8,
          _Visual.pulse,
        ),
        _Step('Again: "I notice I am having a thought."', 5, _Visual.still),
        _Step(
          'The thought is not a command. It is just a thought.',
          6,
          _Visual.still,
        ),
        _Step(
          'Imagine the thought as a leaf floating on a river.',
          8,
          _Visual.wave,
        ),
        _Step(
          'Watch it float past. You do not have to grab it.',
          8,
          _Visual.wave,
        ),
        _Step('Let it go downstream. You stay on the bank.', 6, _Visual.still),
        _Step(
          'The thought is gone. You chose not to follow it.',
          5,
          _Visual.contract,
        ),
      ],
    ),

    //Rule-Based Thinking
    _Plan(
      id: 'rule_based',
      title: 'The Personal Rule',
      emoji: '📏',
      color: const Color(0xFF00CEC9),
      tagline: 'Pre-made rules remove the need to decide in the moment',
      why:
          'Rules reduce cognitive load by eliminating in-the-moment decision-making — which is when impulse wins.',
      steps: const [
        _Step(
          'Think of an area where impulse causes you problems.',
          6,
          _Visual.still,
        ),
        _Step(
          'Create a clear, simple rule: "I never ____."',
          10,
          _Visual.pulse,
        ),
        _Step('Or: "I always ____ before I ____."', 8, _Visual.still),
        _Step(
          'The rule must have NO exceptions — exceptions undo it.',
          8,
          _Visual.still,
        ),
        _Step(
          'Say the rule to yourself clearly one more time.',
          6,
          _Visual.pulse,
        ),
        _Step(
          'A rule does not require motivation. It is automatic.',
          6,
          _Visual.still,
        ),
        _Step(
          'Write your rule down when you finish this session.',
          6,
          _Visual.still,
        ),
      ],
    ),

    //Body Anchoring
    _Plan(
      id: 'body_anchor',
      title: 'Body Anchoring',
      emoji: '⚓',
      color: const Color(0xFF74B9FF),
      tagline:
          'Use a physical sensation to interrupt the impulse before it takes over',
      why:
          'Physical anchoring redirects attention to present sensory input, interrupting the automatic impulse pathway.',
      repeatCycles: 4,
      steps: const [
        _Step('Press BOTH feet firmly into the floor.', 5, _Visual.expand),
        _Step(
          'Feel the floor pushing back. Stay with that sensation.',
          5,
          _Visual.still,
        ),
        _Step('Press your hands flat on your thighs.', 4, _Visual.expand),
        _Step('Feel the pressure and warmth. Stay here.', 4, _Visual.still),
        _Step('Take one slow breath in through your nose.', 4, _Visual.expand),
        _Step('Breathe out slowly. You are grounded.', 5, _Visual.contract),
      ],
    ),

    //The Values Pause
    _Plan(
      id: 'values_pause',
      title: 'The Values Pause',
      emoji: '🧭',
      color: const Color(0xFFE84393),
      tagline:
          'Connect to what matters most — before acting on what feels urgent',
      why:
          'Values-based decision making activates the prefrontal cortex and provides intrinsic motivation to pause.',
      steps: const [
        _Step('Feel the impulse. Notice it clearly.', 4, _Visual.still),
        _Step('Ask: "What kind of person do I want to be?"', 8, _Visual.pulse),
        _Step('Name one value that matters to you most.', 6, _Visual.still),
        _Step('Kindness? Integrity? Calm? Reliability?', 6, _Visual.still),
        _Step(
          'Ask: "Does acting on this impulse match that value?"',
          8,
          _Visual.pulse,
        ),
        _Step(
          'What would the person I want to be choose right now?',
          8,
          _Visual.still,
        ),
        _Step(
          'Make that choice. Not the one you feel — the one you choose.',
          6,
          _Visual.contract,
        ),
        _Step(
          'You acted from your values. That is self-control.',
          5,
          _Visual.pulse,
        ),
      ],
    ),
  ];

  static const _tabs = [
    {'id': 'techniques', 'label': 'Techniques', 'emoji': '🛠️'},
    {'id': 'understanding', 'label': 'Understanding', 'emoji': '🧠'},
    {'id': 'communication', 'label': 'Communication', 'emoji': '🗣️'},
    {'id': 'books', 'label': 'Books', 'emoji': '📖'},
    {'id': 'research', 'label': 'Research', 'emoji': '🔬'},
  ];

  Color _tabColor(String id) {
    switch (id) {
      case 'techniques':
        return Color(0xFF6C5CE7);
      case 'understanding':
        return Color(0xFF00B894);
      case 'communication':
        return Color(0xFFA29BFE);
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
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
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

  List<SelfControlItem> get _filtered {
    switch (_tab) {
      case 'understanding':
        return _items.where((i) => i.subcategory == 'understanding').toList();
      case 'communication':
        return _items.where((i) => i.subcategory == 'communication').toList();
      case 'books':
        return _items
            .where((i) => i.type == SelfControlResourceType.book)
            .toList();
      case 'research':
        return _items
            .where((i) => i.type == SelfControlResourceType.research)
            .toList();
      default:
        return [];
    }
  }

  // SESSION ENGINE
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
    switch (step.visual) {
      case _Visual.expand:
        _orbCtrl.forward(from: _orbCtrl.value);
        break;
      case _Visual.contract:
        _orbCtrl.reverse(from: _orbCtrl.value);
        break;
      case _Visual.shrink:
        _orbCtrl.animateTo(0.0, duration: Duration(seconds: step.durationSec));
        break;
      default:
        break;
    }
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
      final nextCycle = _cycle + 1;
      if (nextCycle >= plan.repeatCycles) {
        _complete();
        return;
      }
      setState(() {
        _cycle = nextCycle;
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
                  'Done',
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

  // ACTIVE SESSION
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

          // Progress bar
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

          // Step dots
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                final done = i < _stepIndex;
                final cur = i == _stepIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: cur ? 20 : 8,
                  height: 8,
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

          // Orb
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_orbCtrl, _pulseCtrl, _waveCtrl]),
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
              duration: const Duration(milliseconds: 380),
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
                color: Colors.white.withOpacity(0.32),
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
        glow = 0.2 + _orbCtrl.value * 0.35;
        break;
      case _Visual.contract:
        scale = 1.2 - _orbCtrl.value * 0.55;
        glow = 0.55 - _orbCtrl.value * 0.3;
        break;
      case _Visual.shrink:
        scale = 1.0 - _orbCtrl.value * 0.4;
        glow = 0.4 - _orbCtrl.value * 0.2;
        break;
      case _Visual.pulse:
        scale = 0.8 + _pulseCtrl.value * 0.3;
        glow = 0.18 + _pulseCtrl.value * 0.3;
        break;
      case _Visual.wave:
        final wave = math.sin(_waveCtrl.value * math.pi) * 0.15;
        scale = 0.85 + wave;
        glow = 0.22 + wave * 0.5;
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

  // BROWSE
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
                      'Self Control',
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
          // Prompt header
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6C5CE7).withOpacity(0.22),
                  context.nuruTheme.backgroundStart.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Feeling the urge to act?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap any technique below. It will guide you through. No reading needed.',
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
                  // Orb
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
                                '${plan.repeatCycles} rounds',
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

  String _dur(_Plan plan) {
    final t =
        plan.steps.fold(0, (s, x) => s + x.durationSec) * plan.repeatCycles;
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

  Widget _buildList(List<SelfControlItem> items) {
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

  String _tlabel(SelfControlResourceType t) {
    switch (t) {
      case SelfControlResourceType.book:
        return '📖  Book';
      case SelfControlResourceType.research:
        return '🔬  Research';
      case SelfControlResourceType.guide:
        return '💡  Guide';
      case SelfControlResourceType.technique:
        return '🛠️  Technique';
    }
  }

  void _showSheet(SelfControlItem item, Color accent) {
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
                                item.type == SelfControlResourceType.book
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
