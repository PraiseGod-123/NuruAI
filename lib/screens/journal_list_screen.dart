import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/nuru_colors.dart';
import '../utils/nuru_theme.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const JournalListScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  List<Map<String, dynamic>> journalEntries = [];

  String themeMode = 'auto';
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _updateTheme();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  void _updateTheme() {
    setState(() {
      if (themeMode == 'auto') {
        isDarkMode = _isNightTime();
      } else if (themeMode == 'night') {
        isDarkMode = true;
      } else {
        isDarkMode = false;
      }
    });
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(NuruTheme.spacingL),
          decoration: BoxDecoration(
            color: isDarkMode ? NuruColors.nightCard : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Theme Mode',
                style: isDarkMode ? NuruTheme.darkH2 : NuruTheme.lightH2,
              ),
              SizedBox(height: NuruTheme.spacingL),
              _buildThemeOption('🌓 Auto', 'auto', 'Switches based on time'),
              _buildThemeOption('☀️ Day', 'day', 'Always light theme'),
              _buildThemeOption('🌙 Night', 'night', 'Always dark theme'),
              SizedBox(height: NuruTheme.spacingL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(String title, String mode, String subtitle) {
    final isSelected = themeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          themeMode = mode;
          _updateTheme();
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
                    ? NuruColors.softBlue.withOpacity(0.2)
                    : NuruColors.softBlue.withOpacity(0.1))
              : (isDarkMode
                    ? NuruColors.nightElevated
                    : NuruColors.morningCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? NuruColors.softBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        (isDarkMode
                                ? NuruTheme.darkBody1
                                : NuruTheme.lightBody1)
                            .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: isDarkMode
                        ? NuruTheme.darkCaption
                        : NuruTheme.lightCaption,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: NuruColors.softBlue, size: 24),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    const moodEmojis = {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'anxious': '😰',
      'calm': '😌',
      'tired': '😴',
    };
    return moodEmojis[mood] ?? '😊';
  }

  Color _getMoodColor(String mood) {
    return NuruColors.moodColors[mood] ?? NuruColors.softBlue;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return 'Just now';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(userData: widget.userData),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        journalEntries.insert(0, result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? NuruColors.nightBackgroundGradient
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4569AD),
                    Color(0xFF597DD4),
                    Color(0xFF7EA9E8),
                  ],
                ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: isDarkMode
                      ? NightSkyPainter(animation: _animationController.value)
                      : DaySkyPainter(animation: _animationController.value),
                );
              },
            ),
            SafeArea(
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
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(NuruTheme.spacingL),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: isDarkMode
                  ? NuruTheme.darkGlassCard()
                  : NuruTheme.lightGlassCard(),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: NuruTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Journal', style: NuruTheme.darkH2),
                Text(
                  '${journalEntries.length} entries',
                  style: NuruTheme.darkCaption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showThemeSelector,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: isDarkMode
                  ? NuruTheme.darkGlassCard()
                  : NuruTheme.lightGlassCard(),
              child: Text(
                isDarkMode ? '🌙' : '☀️',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(NuruTheme.spacingXL),
            decoration: BoxDecoration(
              color: NuruColors.softBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.book_outlined,
              size: 64,
              color: NuruColors.softBlue,
            ),
          ),
          SizedBox(height: NuruTheme.spacingL),
          Text('No entries yet', style: NuruTheme.darkH3),
          SizedBox(height: NuruTheme.spacingS),
          Text(
            'Tap the + button to start journaling',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: NuruTheme.spacingL,
        vertical: NuruTheme.spacingM,
      ),
      itemCount: journalEntries.length,
      itemBuilder: (context, index) {
        final entry = journalEntries[index];
        return _buildJournalCard(entry);
      },
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry) {
    final moodColor = _getMoodColor(entry['mood'] ?? 'happy');

    return Container(
      margin: EdgeInsets.only(bottom: NuruTheme.spacingL),
      child: GestureDetector(
        onTap: () {
          print('Open entry: ${entry['title']}');
        },
        child: Container(
          padding: EdgeInsets.all(NuruTheme.spacingL),
          decoration: isDarkMode ? NuruTheme.darkCard() : NuruTheme.lightCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getMoodEmoji(entry['mood'] ?? 'happy'),
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  SizedBox(width: NuruTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['title'] ?? 'Untitled',
                          style:
                              (isDarkMode
                                      ? NuruTheme.darkBody1
                                      : NuruTheme.lightBody1)
                                  .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(entry['date'] ?? DateTime.now()),
                          style: isDarkMode
                              ? NuruTheme.darkCaption
                              : NuruTheme.lightCaption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode
                        ? NuruColors.nightTextMuted
                        : NuruColors.morningTextMuted,
                    size: 16,
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: NuruTheme.spacingM),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      (isDarkMode
                              ? NuruColors.nightTextMuted
                              : NuruColors.morningTextMuted)
                          .withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Text(
                entry['content'] ?? '',
                style: isDarkMode ? NuruTheme.darkBody2 : NuruTheme.lightBody2,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: _navigateToNewEntry,
      child: Container(
        width: 64,
        height: 64,
        decoration: NuruTheme.button(isDark: isDarkMode),
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// Night Sky Painter
class NightSkyPainter extends CustomPainter {
  final double animation;
  NightSkyPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    _drawStars(canvas, size);
    _drawMoon(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final stars = [
      {'x': 0.1, 'y': 0.15, 'size': 2.0},
      {'x': 0.25, 'y': 0.08, 'size': 1.5},
      {'x': 0.4, 'y': 0.12, 'size': 2.5},
      {'x': 0.6, 'y': 0.18, 'size': 1.8},
      {'x': 0.75, 'y': 0.1, 'size': 2.2},
      {'x': 0.85, 'y': 0.2, 'size': 1.6},
      {'x': 0.15, 'y': 0.35, 'size': 1.4},
      {'x': 0.3, 'y': 0.28, 'size': 2.0},
      {'x': 0.5, 'y': 0.32, 'size': 1.7},
      {'x': 0.7, 'y': 0.38, 'size': 2.3},
      {'x': 0.9, 'y': 0.42, 'size': 1.5},
    ];

    for (var star in stars) {
      final x = (star['x'] as double) * size.width;
      final y = (star['y'] as double) * size.height;
      final baseSize = star['size'] as double;
      final twinkle = (math.sin(animation * math.pi * 2 + x) + 1) / 2;
      final starSize = baseSize * (0.5 + twinkle * 0.5);
      paint.color = Colors.white.withOpacity(0.6 + twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  void _drawMoon(Canvas canvas, Size size) {
    final moonX = size.width * 0.85;
    final moonY = size.height * 0.08;
    final moonRadius = 25.0;
    canvas.drawCircle(
      Offset(moonX, moonY),
      moonRadius * 1.8,
      Paint()..color = NuruColors.softYellow.withOpacity(0.1),
    );
    canvas.drawCircle(
      Offset(moonX, moonY),
      moonRadius,
      Paint()..color = NuruColors.softYellow,
    );
    canvas.drawCircle(
      Offset(moonX + moonRadius * 0.5, moonY),
      moonRadius * 0.95,
      Paint()..color = NuruColors.nightBackground,
    );
  }

  @override
  bool shouldRepaint(NightSkyPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// Day Sky Painter
class DaySkyPainter extends CustomPainter {
  final double animation;
  DaySkyPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    _drawSun(canvas, size);
    _drawClouds(canvas, size);
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunX = size.width * 0.85;
    final sunY = size.height * 0.08;
    final sunRadius = 32.0;

    final outerGlowPaint = Paint()
      ..color = Color(0xFFFFE5B4).withOpacity(0.04)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 2.5, outerGlowPaint);

    final middleGlowPaint = Paint()
      ..color = Color(0xFFFFF4D6).withOpacity(0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 1.8, middleGlowPaint);

    final innerGlowPaint = Paint()
      ..color = NuruColors.softYellow.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 1.3, innerGlowPaint);

    final rect = Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius);
    final sunGradient = Paint()
      ..shader = RadialGradient(
        colors: [Color(0xFFFFF9E6), Color(0xFFFED98B), Color(0xFFFDC870)],
        stops: [0.0, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, sunGradient);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(sunX - sunRadius * 0.3, sunY - sunRadius * 0.3),
      sunRadius * 0.35,
      highlightPaint,
    );

    final rayPaint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);

    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) + (animation * math.pi / 6);
      final rayLength = (i % 2 == 0) ? sunRadius + 16 : sunRadius + 12;
      final opacity = (i % 3 == 0) ? 0.5 : 0.35;
      rayPaint.color = NuruColors.softYellow.withOpacity(opacity);
      final startX = sunX + math.cos(angle) * (sunRadius + 5);
      final startY = sunY + math.sin(angle) * (sunRadius + 5);
      final endX = sunX + math.cos(angle) * rayLength;
      final endY = sunY + math.sin(angle) * rayLength;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }

    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animation * math.pi / 2);
      final sparkleLength =
          sunRadius + 18 + (math.sin(animation * math.pi * 2 + i) * 4);
      final startX = sunX + math.cos(angle) * (sunRadius + 8);
      final startY = sunY + math.sin(angle) * (sunRadius + 8);
      final endX = sunX + math.cos(angle) * sparkleLength;
      final endY = sunY + math.sin(angle) * sparkleLength;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), sparklePaint);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final offset1 = (animation * 30).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.2 + offset1,
      size.height * 0.15,
      1.2,
    );
    final offset2 = (animation * 20).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.6 - offset2,
      size.height * 0.25,
      0.9,
    );
    final offset3 = (animation * 25).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.4 + offset3,
      size.height * 0.35,
      0.7,
    );
    final offset4 = (animation * 15).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.1 - offset4,
      size.height * 0.45,
      1.0,
    );
  }

  void _drawRealisticCloud(Canvas canvas, double x, double y, double scale) {
    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
    _drawCloudShape(canvas, x + 2, y + 3, scale, shadowPaint);

    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    _drawCloudShape(canvas, x, y, scale, cloudPaint);

    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(
      Offset(x + (30 * scale), y - (8 * scale)),
      10 * scale,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(x + (50 * scale), y - (5 * scale)),
      8 * scale,
      highlightPaint,
    );
  }

  void _drawCloudShape(
    Canvas canvas,
    double x,
    double y,
    double scale,
    Paint paint,
  ) {
    canvas.drawCircle(Offset(x, y + (8 * scale)), 18 * scale, paint);
    canvas.drawCircle(
      Offset(x + (25 * scale), y + (12 * scale)),
      20 * scale,
      paint,
    );
    canvas.drawCircle(
      Offset(x + (50 * scale), y + (10 * scale)),
      18 * scale,
      paint,
    );
    canvas.drawCircle(
      Offset(x + (70 * scale), y + (8 * scale)),
      16 * scale,
      paint,
    );
    canvas.drawCircle(Offset(x + (15 * scale), y), 22 * scale, paint);
    canvas.drawCircle(
      Offset(x + (40 * scale), y - (5 * scale)),
      25 * scale,
      paint,
    );
    canvas.drawCircle(Offset(x + (60 * scale), y), 20 * scale, paint);
    canvas.drawCircle(
      Offset(x + (30 * scale), y - (10 * scale)),
      28 * scale,
      paint,
    );
    canvas.drawCircle(
      Offset(x + (50 * scale), y - (8 * scale)),
      24 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(DaySkyPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
