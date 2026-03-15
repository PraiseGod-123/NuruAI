import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

// ══════════════════════════════════════════════════════════════
// SOCIAL SCRIPTS SCREEN
//
// Pre-written scripts for difficult social situations.
// ASD Level 1 individuals often know WHAT they want to say
// but struggle with HOW to say it in the moment.
// These scripts reduce the cognitive load of social interaction.
// ══════════════════════════════════════════════════════════════

class _Script {
  final String situation;
  final String emoji;
  final List<String> scripts;
  final Color color;
  const _Script({
    required this.situation,
    required this.emoji,
    required this.scripts,
    required this.color,
  });
}

class SocialScriptsScreen extends StatefulWidget {
  const SocialScriptsScreen({Key? key}) : super(key: key);
  @override
  State<SocialScriptsScreen> createState() => _SocialScriptsScreenState();
}

class _SocialScriptsScreenState extends State<SocialScriptsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;
  int? _expandedIndex;

  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);
  static const Color _deep = Color(0xFF14366D);

  static const List<_Script> _scripts = [
    _Script(
      situation: 'I need a break',
      emoji: '⏸️',
      color: Color(0xFF74B9FF),
      scripts: [
        '"I need a few minutes to myself. I\'ll be back soon."',
        '"I\'m feeling overwhelmed. Can I step away for a moment?"',
        '"I need some quiet time right now. It\'s not personal."',
        '"Can we pause? I need to reset."',
      ],
    ),
    _Script(
      situation: 'Saying no',
      emoji: '🛑',
      color: Color(0xFFFF7675),
      scripts: [
        '"I\'m not able to do that right now."',
        '"I need to say no to this. I appreciate you asking."',
        '"That doesn\'t work for me. Thank you for understanding."',
        '"I\'m at my limit right now. I can\'t take this on."',
      ],
    ),
    _Script(
      situation: 'Asking for help',
      emoji: '🙏',
      color: Color(0xFF43C6AC),
      scripts: [
        '"I\'m struggling with this. Could you help me?"',
        '"I don\'t understand. Can you explain it differently?"',
        '"I need support with this. Is that okay?"',
        '"Can you show me rather than tell me?"',
      ],
    ),
    _Script(
      situation: 'Ending a conversation',
      emoji: '👋',
      color: Color(0xFFFDCB6E),
      scripts: [
        '"I have to go now. It was good talking with you."',
        '"I need to stop here. Thank you for the conversation."',
        '"I\'m going to head off now. Take care."',
        '"I\'ve run out of energy for talking. See you soon."',
      ],
    ),
    _Script(
      situation: 'When plans change',
      emoji: '🔄',
      color: Color(0xFFA29BFE),
      scripts: [
        '"This change is difficult for me. Can you give me a moment to adjust?"',
        '"I need a few minutes. Unexpected changes are hard for me."',
        '"Can you write down the new plan so I can see it?"',
        '"I\'m not okay with this right now. I need time."',
      ],
    ),
    _Script(
      situation: 'Explaining my autism',
      emoji: '🧩',
      color: Color(0xFF00B894),
      scripts: [
        '"I\'m autistic. That means I process things differently."',
        '"I have autism. Sometimes I need more time or quiet."',
        '"I\'m on the autism spectrum. Please be patient with me."',
        '"I process social situations differently. I\'m not being rude."',
      ],
    ),
    _Script(
      situation: 'When I\'m misunderstood',
      emoji: '😕',
      color: Color(0xFFE17055),
      scripts: [
        '"That\'s not what I meant. Can I try to explain again?"',
        '"I think there\'s been a misunderstanding. Can we slow down?"',
        '"I communicate differently. What I meant was..."',
        '"I\'m sorry if that came out wrong. I\'m trying my best."',
      ],
    ),
    _Script(
      situation: 'Sensory / environment',
      emoji: '🎧',
      color: Color(0xFF6C5CE7),
      scripts: [
        '"This environment is too loud for me. Can we move?"',
        '"I\'m very sensitive to light/sound. Could we adjust it?"',
        '"I need to wear headphones. It\'s not that I\'m ignoring you."',
        '"I\'m finding this space overwhelming. I need to step outside."',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1F3F74),
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
                  colors: [Color(0xFF4569AD), Color(0xFF14366D)],
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
                  _buildAppBar(),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(overscroll: false),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF74B9FF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF74B9FF).withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '💬',
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Tap a situation. Copy or read out any script you need. No explanation required.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.75),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ..._scripts.asMap().entries.map((entry) {
                            final i = entry.key;
                            final s = entry.value;
                            final open = _expandedIndex == i;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _expandedIndex = open ? null : i,
                                    );
                                    HapticFeedback.selectionClick();
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: open
                                                ? [
                                                    s.color.withOpacity(0.22),
                                                    _night.withOpacity(0.88),
                                                  ]
                                                : [
                                                    _dive.withOpacity(0.6),
                                                    _night.withOpacity(0.85),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: open
                                                ? s.color.withOpacity(0.6)
                                                : _sailing.withOpacity(0.3),
                                            width: open ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    s.color.withOpacity(0.5),
                                                    s.color.withOpacity(0.1),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: s.color.withOpacity(
                                                    0.45,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  s.emoji,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                s.situation,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            AnimatedRotation(
                                              turns: open ? 0.5 : 0,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Expanded scripts
                                AnimatedCrossFade(
                                  firstChild: const SizedBox(height: 0),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      children: s.scripts
                                          .map(
                                            (script) => GestureDetector(
                                              onLongPress: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: script.replaceAll(
                                                      '"',
                                                      '',
                                                    ),
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Copied to clipboard',
                                                    ),
                                                    backgroundColor: s.color
                                                        .withOpacity(0.8),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: s.color.withOpacity(
                                                    0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: s.color.withOpacity(
                                                      0.25,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        script,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white
                                                              .withOpacity(
                                                                0.85,
                                                              ),
                                                          height: 1.5,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.copy_rounded,
                                                      size: 16,
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  crossFadeState: open
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 250),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
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

  Widget _buildAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _night.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _sailing.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Social Scripts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Words for difficult moments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
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
      final op = 0.2 + ((t + off) % 1.0) * 0.35;
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
