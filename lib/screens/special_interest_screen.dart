import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

// ══════════════════════════════════════════════════════════════
// SPECIAL INTEREST SCREEN
//
// Special interests are one of the most powerful sources of
// regulation, joy and calm for autistic individuals.
// This is a personal calm space where the user can:
//   • Record what their special interests are
//   • See why their interests matter (validation)
//   • Use their interest as a mindfulness anchor
//   • Access content related to their interests
// ══════════════════════════════════════════════════════════════

class SpecialInterestScreen extends StatefulWidget {
  const SpecialInterestScreen({Key? key}) : super(key: key);
  @override
  State<SpecialInterestScreen> createState() => _SpecialInterestScreenState();
}

class _SpecialInterestScreenState extends State<SpecialInterestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;

  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);
  static const Color _deep = Color(0xFF14366D);
  static const Color _gold = Color(0xFFFFD32A);

  // User's special interests — stored in memory for this session
  final List<String> _interests = [];
  final TextEditingController _interestCtrl = TextEditingController();

  // Mindfulness prompts for special interests
  static const List<String> _prompts = [
    'Think about your favourite thing about this interest. What draws you to it?',
    'What is the most fascinating detail you know about this topic?',
    'If you could explain this to someone who has never heard of it, what would you say first?',
    'Close your eyes. Picture yourself completely immersed in this interest. How does your body feel?',
    'What is one new thing you discovered about this interest recently?',
    'What does this interest give you that nothing else does?',
  ];
  int _promptIndex = 0;

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Technology', 'emoji': '💻', 'color': Color(0xFF74B9FF)},
    {'label': 'Animals', 'emoji': '🐾', 'color': Color(0xFF00B894)},
    {'label': 'Space', 'emoji': '🚀', 'color': Color(0xFF6C5CE7)},
    {'label': 'Music', 'emoji': '🎵', 'color': Color(0xFFE84393)},
    {'label': 'Art', 'emoji': '🎨', 'color': Color(0xFFFDCB6E)},
    {'label': 'History', 'emoji': '📜', 'color': Color(0xFFE17055)},
    {'label': 'Sports', 'emoji': '⚽', 'color': Color(0xFF43C6AC)},
    {'label': 'Science', 'emoji': '🔬', 'color': Color(0xFF55EFC4)},
    {'label': 'Books', 'emoji': '📚', 'color': Color(0xFFA29BFE)},
    {'label': 'Nature', 'emoji': '🌿', 'color': Color(0xFF00B894)},
    {'label': 'Gaming', 'emoji': '🎮', 'color': Color(0xFF6C5CE7)},
    {'label': 'Films & TV', 'emoji': '🎬', 'color': Color(0xFFFF7675)},
    {'label': 'Maths', 'emoji': '➗', 'color': Color(0xFF74B9FF)},
    {'label': 'Transport', 'emoji': '🚂', 'color': Color(0xFFE17055)},
    {'label': 'Cooking', 'emoji': '🍳', 'color': Color(0xFFFDCB6E)},
    {'label': 'Something else', 'emoji': '⭐', 'color': Color(0xFFFFD32A)},
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
    _interestCtrl.dispose();
    super.dispose();
  }

  void _addInterest(String interest) {
    final clean = interest.trim();
    if (clean.isEmpty || _interests.contains(clean)) return;
    setState(() => _interests.add(clean));
    _interestCtrl.clear();
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
        resizeToAvoidBottomInset: true,
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
                          // Why this matters
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _gold.withOpacity(0.18),
                                  _night.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _gold.withOpacity(0.45),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '⭐',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Your interests matter',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Special interests are not just hobbies. For autistic individuals, they are a primary source of joy, calm, identity and self-regulation.\n\nThey deserve to be celebrated — not just tolerated.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.72),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // My interests
                          const Text(
                            'My Special Interests',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Category quick-add grid
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final color = cat['color'] as Color;
                              final already = _interests.contains(cat['label']);
                              return GestureDetector(
                                onTap: () {
                                  if (!already)
                                    _addInterest(cat['label'] as String);
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    gradient: LinearGradient(
                                      colors: already
                                          ? [
                                              color.withOpacity(0.45),
                                              _night.withOpacity(0.75),
                                            ]
                                          : [
                                              _dive.withOpacity(0.5),
                                              _night.withOpacity(0.75),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: already
                                          ? color.withOpacity(0.75)
                                          : _sailing.withOpacity(0.3),
                                      width: already ? 2 : 1,
                                    ),
                                    boxShadow: already
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.22),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        cat['emoji'] as String,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat['label'] as String,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: already
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: already
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                      if (already) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: color,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),

                          // Custom interest input
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _dive.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _sailing.withOpacity(0.4),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _interestCtrl,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Add your own interest…',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                    onSubmitted: _addInterest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _addInterest(_interestCtrl.text),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _gold.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _gold.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFFFFD32A),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Current interests chips
                          if (_interests.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _interests
                                  .map(
                                    (interest) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gold.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(
                                          color: _gold.withOpacity(0.45),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            '⭐',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            interest,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () => setState(
                                              () => _interests.remove(interest),
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],

                          // Mindfulness anchor
                          if (_interests.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6C5CE7).withOpacity(0.2),
                                    _night.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withOpacity(0.45),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '🧘',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Interest Mindfulness',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _promptIndex =
                                              (_promptIndex + 1) %
                                              _prompts.length,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6C5CE7,
                                            ).withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF6C5CE7,
                                              ).withOpacity(0.4),
                                            ),
                                          ),
                                          child: Text(
                                            'Next ›',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _prompts[_promptIndex],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.78),
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Think about: ${_interests.join(', ')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_interests.isEmpty) ...[
                            const SizedBox(height: 32),
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    '⭐',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap a category above\nor type your own interest.',
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
                      'My Special Interest',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Your personal calm space',
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
