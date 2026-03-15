import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

// ══════════════════════════════════════════════════════════════
// SOS SCREEN — Immediate Calm
//
// Minimal. No reading required. No decisions.
// One breathing animation. One comforting message.
// Option to play a recorded voice or access quick tools.
// ══════════════════════════════════════════════════════════════

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);
  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  late AnimationController _breatheCtrl;
  late AnimationController _starCtrl;
  late AnimationController _pulseCtrl;
  int _phase = 0; // 0=inhale 1=hold 2=exhale

  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);
  static const Color _deep = Color(0xFF14366D);

  final List<String> _messages = [
    'You are safe right now.',
    'This feeling will pass.',
    'You have survived this before.',
    'You are not in danger.',
    'Just breathe. Nothing else needed.',
    'You are doing the right thing.',
  ];
  int _msgIndex = 0;

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _breatheCtrl = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    _breatheCtrl.addListener(() {
      final t = _breatheCtrl.value;
      final newPhase = t < 0.4 ? 0 : (t < 0.55 ? 1 : 2);
      if (newPhase != _phase) {
        setState(() => _phase = newPhase);
        if (newPhase == 0) {
          setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
        }
      }
    });
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _starCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _phaseLabel {
    switch (_phase) {
      case 0:
        return 'Breathe in…';
      case 1:
        return 'Hold…';
      case 2:
        return 'Breathe out…';
      default:
        return '';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case 0:
        return const Color(0xFF74B9FF);
      case 1:
        return const Color(0xFFA29BFE);
      case 2:
        return const Color(0xFF43C6AC);
      default:
        return const Color(0xFF74B9FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
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
                  colors: [Color(0xFF0F2A5C), _night, _deep],
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _SP(t: _starCtrl.value),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Back button — top left
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _dive.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _sailing.withOpacity(0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'You\'re safe',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 42),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Big breathing orb
                  AnimatedBuilder(
                    animation: Listenable.merge([_breatheCtrl, _pulseCtrl]),
                    builder: (_, __) {
                      final t = _breatheCtrl.value;
                      double scale;
                      if (t < 0.4)
                        scale = 0.6 + (t / 0.4) * 0.5; // inhale: 0.6 → 1.1
                      else if (t < 0.55)
                        scale = 1.1; // hold
                      else
                        scale =
                            1.1 -
                            ((t - 0.55) / 0.45) * 0.5; // exhale: 1.1 → 0.6

                      final glow = 0.2 + scale * 0.2 + _pulseCtrl.value * 0.05;
                      final col = _phaseColor;

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                col.withOpacity(0.75),
                                col.withOpacity(0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.3, 0.65, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: col.withOpacity(glow),
                                blurRadius: 80,
                                spreadRadius: 12,
                              ),
                              BoxShadow(
                                color: col.withOpacity(glow * 0.4),
                                blurRadius: 120,
                                spreadRadius: 24,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '💙',
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Phase label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _phaseLabel,
                      key: ValueKey(_phase),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reassurance message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        _messages[_msgIndex],
                        key: ValueKey(_msgIndex),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withOpacity(0.65),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Quick tool buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        Text(
                          'When you\'re ready',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _quickBtn(
                                '🎵',
                                'Music',
                                () => Navigator.pushNamed(context, '/music'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickBtn(
                                '🌬️',
                                'Breathe',
                                () =>
                                    Navigator.pushNamed(context, '/breathing'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickBtn(
                                '📓',
                                'Journal',
                                () => Navigator.pushNamed(context, '/journal'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickBtn(
                                '🎮',
                                'Games',
                                () => Navigator.pushNamed(
                                  context,
                                  '/calming-games',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _quickBtn(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _dive.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _sailing.withOpacity(0.4), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SP extends CustomPainter {
  final double t;
  const _SP({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    const s = [
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
    for (final st in s) {
      final x = size.width * st[0];
      final y = size.height * st[1];
      final off = (st[0] + st[1]) % 1.0;
      final op = 0.15 + ((t + off) % 1.0) * 0.25;
      p.color = Colors.white.withOpacity(op * 0.3);
      canvas.drawCircle(Offset(x, y), 2.8, p);
      p.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 1.5, p);
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_SP o) => o.t != t;
}
