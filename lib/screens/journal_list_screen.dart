import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import '../utils/nuru_colors.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';
import '../services/firebase_service.dart';
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
  StreamSubscription<List<Map<String, dynamic>>>? _journalSub;
  bool _loading = true;

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

    _subscribeToJournals();
  }

  void _subscribeToJournals() {
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    _journalSub = NuruFirebaseService.instance
        .streamJournals(uid)
        .listen(
          (entries) {
            if (mounted) {
              setState(() {
                journalEntries = entries;
                _loading = false;
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  @override
  void dispose() {
    _journalSub?.cancel();
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
    await Navigator.push(
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
    // No need to manually insert — Firestore stream updates the list automatically
  }

  void _confirmDelete(String entryId, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F3F74),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete "$title"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final uid = widget.userData?['uid'] as String? ?? '';
              if (uid.isNotEmpty) {
                NuruFirebaseService.instance.deleteJournal(
                  uid: uid,
                  entryId: entryId,
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        floatingActionButton: _buildFAB(),
        body: Stack(
          children: [
            // ── Background gradient ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0D1F44), const Color(0xFF050D1A)],
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
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4569AD),
                                ),
                              ),
                            )
                          : journalEntries.isEmpty
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
              colors: [
                Color(0xFF1F3F74).withOpacity(0.65),
                Color(0xFF081F44).withOpacity(0.55),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Color(0xFF4569AD).withOpacity(0.3)),
            ),
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
        color: Color(0xFF081F44).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(0xFF4569AD).withOpacity(0.45),
          width: 1.2,
        ),
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
              color: Color(0xFF4569AD).withOpacity(0.12),
              border: Border.all(
                color: Color(0xFF4569AD).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4569AD).withOpacity(0.15),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.book_outlined,
              size: 44,
              color: Color(0xFF4569AD).withOpacity(0.6),
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
    final entryId = entry['id'] as String? ?? '';

    // Date can come from Firestore as a String or from memory as a DateTime
    DateTime date;
    final rawDate = entry['date'];
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      try {
        date = DateTime.parse(rawDate);
      } catch (_) {
        date = DateTime.now();
      }
    } else {
      final rawCreated = entry['createdAt'];
      if (rawCreated is DateTime) {
        date = rawCreated;
      } else if (rawCreated is String) {
        try {
          date = DateTime.parse(rawCreated);
        } catch (_) {
          date = DateTime.now();
        }
      } else {
        date = DateTime.now();
      }
    }

    return GestureDetector(
      onLongPress: () => _confirmDelete(entryId, title),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F3F74).withOpacity(0.75),
                  Color(0xFF081F44).withOpacity(0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Color(0xFF4569AD).withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF081F44).withOpacity(0.45),
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
                splashColor: Color(0xFF4569AD).withOpacity(0.08),
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
                              Color(0xFF4569AD).withOpacity(0.22),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF4569AD), const Color(0xFF1F3F74)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF4569AD).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4569AD).withOpacity(0.45),
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
      final op = 0.45 + t * 0.55; // brighter on dark bg

      if (type == 0) {
        paint.color = Colors.white.withOpacity(op * 0.9);
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      } else if (type == 1) {
        paint.color = Colors.white.withOpacity(op * 0.2);
        canvas.drawCircle(Offset(x, y), 2.5, paint);
        paint.color = Colors.white.withOpacity(op * 0.65);
        canvas.drawCircle(Offset(x, y), 1.3, paint);
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      } else {
        paint.color = Colors.white.withOpacity(op * 0.12);
        canvas.drawCircle(Offset(x, y), 4.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.3);
        canvas.drawCircle(Offset(x, y), 2.5, paint);
        paint.color = Colors.white.withOpacity(op * 0.75);
        canvas.drawCircle(Offset(x, y), 1.4, paint);
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_JournalStarsPainter old) => old.twinkle != twinkle;
}
