import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// ══════════════════════════════════════════════════════════════
// SENSORY TOOLKIT SCREEN
//
// For ASD Level 1, sensory overload is one of the primary
// sources of distress. This screen lets the user:
//   1. Identify what is overwhelming them right now
//   2. Get immediate sensory relief suggestions
//   3. Build their personal sensory profile over time
// ══════════════════════════════════════════════════════════════

class SensoryToolkitScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const SensoryToolkitScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<SensoryToolkitScreen> createState() => _SensoryToolkitScreenState();
}

class _SensoryToolkitScreenState extends State<SensoryToolkitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;
  // What is overwhelming me right now — multi-select
  final Set<String> _active = {};

  static const List<Map<String, dynamic>> _triggers = [
    {
      'id': 'noise',
      'emoji': '🔊',
      'label': 'Too much noise',
      'color': Color(0xFFFF7675),
    },
    {
      'id': 'light',
      'emoji': '💡',
      'label': 'Bright lights',
      'color': Color(0xFFFDCB6E),
    },
    {
      'id': 'crowd',
      'emoji': '👥',
      'label': 'Too many people',
      'color': Color(0xFFE17055),
    },
    {
      'id': 'touch',
      'emoji': '🤚',
      'label': 'Uncomfortable touch',
      'color': Color(0xFFA29BFE),
    },
    {
      'id': 'smell',
      'emoji': '👃',
      'label': 'Strong smell',
      'color': Color(0xFF55EFC4),
    },
    {
      'id': 'change',
      'emoji': '🔄',
      'label': 'Unexpected change',
      'color': Color(0xFF74B9FF),
    },
    {
      'id': 'social',
      'emoji': '😟',
      'label': 'Social pressure',
      'color': Color(0xFFFA709A),
    },
    {
      'id': 'texture',
      'emoji': '👕',
      'label': 'Clothing texture',
      'color': Color(0xFF43C6AC),
    },
    {
      'id': 'overload',
      'emoji': '🤯',
      'label': 'Everything at once',
      'color': Color(0xFFFF6B6B),
    },
    {
      'id': 'fatigue',
      'emoji': '😴',
      'label': 'Too tired to cope',
      'color': Color(0xFF6C5CE7),
    },
  ];

  // Relief tools mapped to trigger types
  static const Map<String, List<Map<String, dynamic>>> _reliefMap = {
    'noise': [
      {'emoji': '🎧', 'tip': 'Put on noise-cancelling headphones or earbuds'},
      {
        'emoji': '🤫',
        'tip': 'Find a quiet room or a corner away from the sound',
      },
      {'emoji': '🎵', 'tip': 'Play a familiar calming sound to mask the noise'},
    ],
    'light': [
      {'emoji': '😎', 'tip': 'Wear sunglasses or dim the screen brightness'},
      {'emoji': '🌑', 'tip': 'Move to a dimmer area or close blinds'},
      {'emoji': '👁️', 'tip': 'Focus your eyes on one neutral spot'},
    ],
    'crowd': [
      {'emoji': '🚶', 'tip': 'Find an exit and step outside for a few minutes'},
      {
        'emoji': '🧱',
        'tip': 'Stand with your back to a wall — reduces 360° input',
      },
      {
        'emoji': '🎧',
        'tip': 'Headphones signal you are not available to interact',
      },
    ],
    'touch': [
      {
        'emoji': '🧥',
        'tip': 'Remove or adjust the uncomfortable item if possible',
      },
      {'emoji': '🤲', 'tip': 'Apply firm pressure to your own arms or legs'},
      {
        'emoji': '🌡️',
        'tip': 'Try temperature contrast — cold water on wrists',
      },
    ],
    'smell': [
      {'emoji': '🌿', 'tip': 'Get fresh air — step outside if possible'},
      {
        'emoji': '👃',
        'tip': 'Carry a small familiar scent to focus on instead',
      },
      {
        'emoji': '💨',
        'tip': 'Breathe through your mouth until the smell passes',
      },
    ],
    'change': [
      {'emoji': '📋', 'tip': 'Write down the new plan so you can see it'},
      {'emoji': '🔁', 'tip': 'Name three things that have NOT changed'},
      {
        'emoji': '⏰',
        'tip': 'Give yourself a time window — this change is temporary',
      },
    ],
    'social': [
      {'emoji': '📱', 'tip': 'Send a text instead of speaking if possible'},
      {'emoji': '🚶', 'tip': 'It is okay to excuse yourself and take a break'},
      {'emoji': '💬', 'tip': 'Use a prepared script from Social Scripts'},
    ],
    'texture': [
      {'emoji': '🧴', 'tip': 'Apply lotion to create a barrier sensation'},
      {'emoji': '👕', 'tip': 'Change into softer clothing as soon as you can'},
      {'emoji': '🤲', 'tip': 'Run fingers over a smooth, comforting texture'},
    ],
    'overload': [
      {'emoji': '🆘', 'tip': 'Use the SOS screen — no decisions needed'},
      {'emoji': '🌑', 'tip': 'Reduce inputs: dark, quiet, alone if possible'},
      {'emoji': '⏸️', 'tip': 'Give yourself permission to stop everything'},
    ],
    'fatigue': [
      {'emoji': '😌', 'tip': 'Reduce all unnecessary demands immediately'},
      {'emoji': '🛋️', 'tip': 'Sit or lie down — even 10 minutes helps'},
      {
        'emoji': '💧',
        'tip': 'Drink water. Dehydration worsens sensory sensitivity',
      },
    ],
  };

  List<Map<String, dynamic>> get _reliefSuggestions {
    final suggestions = <Map<String, dynamic>>[];
    for (final id in _active) {
      final tips = _reliefMap[id] ?? [];
      for (final tip in tips) {
        if (!suggestions.any((s) => s['tip'] == tip['tip'])) {
          suggestions.add(tip);
        }
      }
    }
    return suggestions.take(6).toList();
  }

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
                          // What is overwhelming you?
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA29BFE).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFA29BFE).withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What is overwhelming me right now?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap everything that applies. Your toolkit will update.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.55),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trigger grid — mixed shapes: circles for sensory, pills for cognitive
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _triggers.map((t) {
                              final id = t['id'] as String;
                              final color = t['color'] as Color;
                              final sel = _active.contains(id);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (sel)
                                      _active.remove(id);
                                    else
                                      _active.add(id);
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    gradient: LinearGradient(
                                      colors: sel
                                          ? [
                                              color.withOpacity(0.45),
                                              context.nuruTheme.backgroundStart
                                                  .withOpacity(0.75),
                                            ]
                                          : [
                                              context.nuruTheme.backgroundMid
                                                  .withOpacity(0.6),
                                              context.nuruTheme.backgroundStart
                                                  .withOpacity(0.8),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: sel
                                          ? color.withOpacity(0.8)
                                          : context.nuruTheme.accentColor
                                                .withOpacity(0.3),
                                      width: sel ? 2 : 1,
                                    ),
                                    boxShadow: sel
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.25),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        t['emoji'] as String,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t['label'] as String,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: sel
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // Relief suggestions
                          if (_active.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'What to do right now:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._reliefSuggestions
                                .map(
                                  (tip) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          context.nuruTheme.backgroundMid
                                              .withOpacity(0.6),
                                          context.nuruTheme.backgroundStart
                                              .withOpacity(0.85),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: context.nuruTheme.accentColor
                                            .withOpacity(0.35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          tip['emoji'] as String,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            tip['tip'] as String,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: Colors.white.withOpacity(
                                                0.82,
                                              ),
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),

                            // Quick links
                            const SizedBox(height: 8),
                            if (_active.contains('overload') ||
                                _active.contains('social') ||
                                _active.contains('noise'))
                              _quickLink(
                                '🆘 Go to SOS Screen',
                                () => Navigator.pushNamed(context, '/sos'),
                              ),
                            if (_active.contains('social'))
                              _quickLink(
                                '💬 Open Social Scripts',
                                () => Navigator.pushNamed(
                                  context,
                                  '/social-scripts',
                                ),
                              ),
                          ],

                          if (_active.isEmpty) ...[
                            const SizedBox(height: 32),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    '🎧',
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap what\'s overwhelming you\nand your toolkit will appear.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.45),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
              colors: [
                context.nuruTheme.backgroundMid.withOpacity(0.75),
                context.nuruTheme.backgroundStart.withOpacity(0.80),
              ],
            ),
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
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.nuruTheme.backgroundStart.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.nuruTheme.accentColor.withOpacity(0.5),
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
                      'Sensory Toolkit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'What\'s overwhelming me right now?',
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

  Widget _quickLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.nuruTheme.accentColor.withOpacity(0.3),
              context.nuruTheme.backgroundStart.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.nuruTheme.accentColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 14,
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
