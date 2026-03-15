import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../utils/nuru_colors.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const JournalListScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _entryController;

  List<Map<String, dynamic>> journalEntries = [];

  // ── Colours ──────────────────────────────────────────────
  static const Color _bgTop = Color(0xFF4569AD);
  static const Color _bgBottom = Color(0xFF14366D);
  static const Color _cardTop = Color(0xFF1F3F74);
  static const Color _cardBot = Color(0xFF081F44);
  static const Color _border = Color(0xFF4569AD);

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────

  String _getMoodEmoji(String mood) {
    const map = {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'anxious': '😰',
      'calm': '😌',
      'tired': '😴',
    };
    return map[mood] ?? '😊';
  }

  Color _getMoodColor(String mood) {
    return NuruColors.moodColors[mood] ?? const Color(0xFF8EA2D7);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Navigation ────────────────────────────────────────────

  void _navigateToNewEntry() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0xFF081F44),
        pageBuilder: (_, __, ___) =>
            JournalEntryScreen(userData: widget.userData),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() => journalEntries.insert(0, result));
    }
  }

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
        backgroundColor: _bgBottom,
        floatingActionButton: _buildFAB(),
        body: Stack(
          children: [
            // ── Background gradient ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bgTop, _bgBottom],
                ),
              ),
            ),

            // ── Stars ──
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starController,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _JournalStarsPainter(twinkle: _starController.value),
                ),
              ),
            ),

            // ── Content ──
            SafeArea(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (_, child) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entryController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: journalEntries.isEmpty
                          ? _buildEmptyState()
                          : _buildJournalList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cardTop.withOpacity(0.65), _cardBot.withOpacity(0.55)],
            ),
            border: Border(bottom: BorderSide(color: _border.withOpacity(0.3))),
          ),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: _iconButton(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 16),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Journal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      journalEntries.isEmpty
                          ? 'No entries yet'
                          : '${journalEntries.length} entr${journalEntries.length == 1 ? 'y' : 'ies'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Search (placeholder — wire up in a later sprint)
              _iconButton(Icons.search_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _cardBot.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withOpacity(0.45), width: 1.2),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  // ── Empty state ───────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing book icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _border.withOpacity(0.12),
              border: Border.all(color: _border.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _border.withOpacity(0.15),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.book_outlined,
              size: 44,
              color: Color(0xFF8EA2D7),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ✦ to write your first entry',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── Journal list ──────────────────────────────────────────

  Widget _buildJournalList() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        itemCount: journalEntries.length,
        itemBuilder: (_, i) => _buildJournalCard(journalEntries[i], i),
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry, int index) {
    final mood = entry['mood'] as String? ?? 'happy';
    final moodColor = _getMoodColor(mood);
    final title = entry['title'] as String? ?? 'Untitled';
    final content = entry['content'] as String? ?? '';
    final date = entry['date'] as DateTime? ?? DateTime.now();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardTop.withOpacity(0.75), _cardBot.withOpacity(0.88)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _cardBot.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {},
              splashColor: _border.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: mood + title + date ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mood badge
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: moodColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: moodColor.withOpacity(0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getMoodEmoji(mood),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: Colors.white.withOpacity(0.38),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Mood colour dot
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: moodColor,
                            boxShadow: [
                              BoxShadow(
                                color: moodColor.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Divider ──
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _border.withOpacity(0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // ── Content preview ──
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.58),
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _navigateToNewEntry,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4569AD), Color(0xFF1F3F74)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF8EA2D7).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4569AD).withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Stars painter ─────────────────────────────────────────────
// 3 sizes × multiple bands covering the full screen height.
// Each star twinkles at its own independent phase.

class _JournalStarsPainter extends CustomPainter {
  final double twinkle;

  const _JournalStarsPainter({required this.twinkle});

  // [x_fraction, y_fraction, size_type(0=tiny,1=small,2=medium)]
  static const List<List<double>> _stars = [
    // Band 1 — top
    [0.05, 0.04, 0], [0.14, 0.07, 1], [0.27, 0.03, 2],
    [0.38, 0.09, 0], [0.50, 0.05, 1], [0.63, 0.02, 0],
    [0.74, 0.08, 2], [0.83, 0.04, 1], [0.92, 0.10, 0],
    // Band 2
    [0.08, 0.16, 1], [0.20, 0.20, 0], [0.33, 0.15, 2],
    [0.46, 0.19, 0], [0.57, 0.13, 1], [0.68, 0.21, 0],
    [0.79, 0.17, 2], [0.88, 0.23, 0], [0.97, 0.14, 1],
    // Band 3
    [0.03, 0.30, 0], [0.16, 0.34, 2], [0.29, 0.28, 0],
    [0.42, 0.36, 1], [0.54, 0.31, 0], [0.66, 0.38, 2],
    [0.77, 0.29, 0], [0.86, 0.35, 1], [0.94, 0.32, 0],
    // Band 4
    [0.07, 0.46, 1], [0.19, 0.50, 0], [0.31, 0.44, 2],
    [0.44, 0.52, 0], [0.56, 0.47, 1], [0.69, 0.54, 0],
    [0.80, 0.48, 2], [0.90, 0.55, 0], [0.98, 0.43, 1],
    // Band 5
    [0.04, 0.62, 0], [0.15, 0.67, 2], [0.26, 0.60, 1],
    [0.39, 0.65, 0], [0.52, 0.70, 2], [0.64, 0.63, 0],
    [0.75, 0.68, 1], [0.85, 0.62, 0], [0.95, 0.71, 2],
    // Band 6
    [0.09, 0.78, 1], [0.21, 0.82, 0], [0.34, 0.76, 2],
    [0.47, 0.80, 0], [0.59, 0.84, 1], [0.71, 0.77, 0],
    [0.82, 0.83, 2], [0.91, 0.79, 1], [0.99, 0.86, 0],
    // Band 7 — bottom
    [0.06, 0.91, 0], [0.18, 0.94, 2], [0.30, 0.89, 1],
    [0.43, 0.96, 0], [0.55, 0.92, 2], [0.67, 0.97, 0],
    [0.78, 0.90, 1], [0.87, 0.95, 2], [0.96, 0.93, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in _stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final type = s[2];

      // Each star has a unique phase offset
      final phase = (s[0] * 3.7 + s[1] * 5.3) % 1.0;
      final t = ((twinkle + phase) % 1.0);
      final op = 0.25 + t * 0.55;

      if (type == 0) {
        // Tiny — single dot
        paint.color = Colors.white.withOpacity(op * 0.7);
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      } else if (type == 1) {
        // Small — soft glow + core
        paint.color = Colors.white.withOpacity(op * 0.2);
        canvas.drawCircle(Offset(x, y), 3.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.6);
        canvas.drawCircle(Offset(x, y), 1.5, paint);
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      } else {
        // Medium — 3-layer glow
        paint.color = Colors.white.withOpacity(op * 0.12);
        canvas.drawCircle(Offset(x, y), 5.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.28);
        canvas.drawCircle(Offset(x, y), 3.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.7);
        canvas.drawCircle(Offset(x, y), 1.6, paint);
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_JournalStarsPainter old) => old.twinkle != twinkle;
}
