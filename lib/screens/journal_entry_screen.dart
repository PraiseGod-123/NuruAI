import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../utils/nuru_colors.dart';
import '../utils/nuru_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class JournalEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const JournalEntryScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  late AnimationController _animationController;

  String? selectedMood;
  DateTime selectedDate = DateTime.now();
  DateTime focusedDay = DateTime.now();

  String themeMode = 'auto';
  bool isDarkMode = false;

  final List<Map<String, dynamic>> moods = [
    {'emoji': '😊', 'label': 'Happy', 'value': 'happy'},
    {'emoji': '😢', 'label': 'Sad', 'value': 'sad'},
    {'emoji': '😠', 'label': 'Angry', 'value': 'angry'},
    {'emoji': '😰', 'label': 'Anxious', 'value': 'anxious'},
    {'emoji': '😌', 'label': 'Calm', 'value': 'calm'},
    {'emoji': '😴', 'label': 'Tired', 'value': 'tired'},
  ];

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
    _titleController.dispose();
    _contentController.dispose();
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

  void _showCalendarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDarkMode ? NuruColors.nightCard : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Select Date',
                style: isDarkMode ? NuruTheme.darkH2 : NuruTheme.lightH2,
              ),
              SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now(),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDate = selected;
                    focusedDay = focused;
                  });
                  Navigator.pop(context);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: NuruColors.softBlue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: NuruColors.softBlue,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Colors.white),
                  defaultTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  weekendTextStyle: TextStyle(color: NuruColors.softCyan),
                  outsideTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white30 : Colors.black26,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: isDarkMode
                      ? NuruTheme.darkH3
                      : NuruTheme.lightH3,
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: isDarkMode
                        ? NuruColors.nightTextSecondary
                        : NuruColors.morningTextSecondary,
                  ),
                  weekendStyle: TextStyle(color: NuruColors.softCyan),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: NuruTheme.button(isDark: isDarkMode),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text('Done', style: NuruTheme.buttonText),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _saveEntry() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: NuruColors.softRed,
        ),
      );
      return;
    }

    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your mood'),
          backgroundColor: NuruColors.softOrange,
        ),
      );
      return;
    }

    final journalData = {
      'title': _titleController.text,
      'content': _contentController.text,
      'mood': selectedMood,
      'date': selectedDate,
      'createdAt': DateTime.now(),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Journal entry saved!'),
        backgroundColor: NuruColors.softGreen,
      ),
    );

    Navigator.pop(context, journalData);
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM, yyyy').format(date);
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(NuruTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateSelector(),
                          SizedBox(height: NuruTheme.spacingXL),
                          Text(
                            'How do you feel?',
                            style: isDarkMode
                                ? NuruTheme.darkH3
                                : NuruTheme.darkH3.copyWith(
                                    color: Colors.white,
                                  ),
                          ),
                          SizedBox(height: NuruTheme.spacingM),
                          _buildMoodSelector(),
                          SizedBox(height: NuruTheme.spacingXL),
                          Text(
                            'Title',
                            style: isDarkMode
                                ? NuruTheme.darkH3
                                : NuruTheme.darkH3.copyWith(
                                    color: Colors.white,
                                  ),
                          ),
                          SizedBox(height: NuruTheme.spacingM),
                          _buildTitleField(),
                          SizedBox(height: NuruTheme.spacingXL),
                          Text(
                            'What\'s on your mind?',
                            style: isDarkMode
                                ? NuruTheme.darkH3
                                : NuruTheme.darkH3.copyWith(
                                    color: Colors.white,
                                  ),
                          ),
                          SizedBox(height: NuruTheme.spacingM),
                          _buildContentField(),
                          SizedBox(height: NuruTheme.spacingXL),
                          _buildSaveButton(),
                          SizedBox(height: NuruTheme.spacingL),
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
          Text('New Entry', style: NuruTheme.darkH2),
          Spacer(),
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
          SizedBox(width: NuruTheme.spacingM),
          GestureDetector(
            onTap: _saveEntry,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: NuruTheme.spacingL,
                vertical: 12,
              ),
              decoration: isDarkMode
                  ? NuruTheme.darkGlassCard()
                  : NuruTheme.lightGlassCard(),
              child: Text(
                'Save',
                style: NuruTheme.darkBody1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _showCalendarPicker,
      child: Container(
        padding: EdgeInsets.all(NuruTheme.spacingL),
        decoration: isDarkMode ? NuruTheme.darkCard() : NuruTheme.lightCard(),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: NuruColors.softBlue, size: 20),
            SizedBox(width: NuruTheme.spacingM),
            Text(
              _formatDate(selectedDate),
              style: isDarkMode ? NuruTheme.darkBody1 : NuruTheme.lightBody1,
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: isDarkMode
                  ? NuruColors.nightTextMuted
                  : NuruColors.morningTextMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = selectedMood == mood['value'];
          return GestureDetector(
            onTap: () => setState(() => selectedMood = mood['value'] as String),
            child: Container(
              width: 80,
              margin: EdgeInsets.only(right: NuruTheme.spacingM),
              decoration: isSelected
                  ? (isDarkMode ? NuruTheme.darkCard() : NuruTheme.lightCard())
                  : (isDarkMode
                        ? NuruTheme.darkGlassCard()
                        : NuruTheme.lightGlassCard()),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mood['emoji'] as String, style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    mood['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      padding: EdgeInsets.all(NuruTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NuruTheme.radiusXL),
      ),
      child: TextField(
        controller: _titleController,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: NuruColors.softBlue,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      height: 280,
      padding: EdgeInsets.all(NuruTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NuruTheme.radiusXL),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
        cursorColor: NuruColors.softBlue,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NuruTheme.radiusM),
          ),
        ),
        child: Ink(
          decoration: NuruTheme.button(isDark: isDarkMode),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 22, color: Colors.white),
                SizedBox(width: 8),
                Text('Save Entry', style: NuruTheme.buttonText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

    // Outer glow (much softer)
    final outerGlowPaint = Paint()
      ..color = Color(0xFFFFE5B4).withOpacity(0.04)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 2.5, outerGlowPaint);

    // Middle glow layer (reduced)
    final middleGlowPaint = Paint()
      ..color = Color(0xFFFFF4D6).withOpacity(0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 1.8, middleGlowPaint);

    // Inner glow (softer)
    final innerGlowPaint = Paint()
      ..color = NuruColors.softYellow.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 1.3, innerGlowPaint);

    // Sun core with softer gradient
    final rect = Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius);
    final sunGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFFFF9E6), // Softer center
          Color(0xFFFED98B), // NuruAI yellow
          Color(0xFFFDC870), // Slightly darker edge
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, sunGradient);

    // Subtle highlight (less bright)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(sunX - sunRadius * 0.3, sunY - sunRadius * 0.3),
      sunRadius * 0.35,
      highlightPaint,
    );

    // Softer sun rays
    final rayPaint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);

    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) + (animation * math.pi / 6);

      // Shorter, subtler rays
      final rayLength = (i % 2 == 0) ? sunRadius + 16 : sunRadius + 12;

      // Lower opacity
      final opacity = (i % 3 == 0) ? 0.5 : 0.35;
      rayPaint.color = NuruColors.softYellow.withOpacity(opacity);

      final startX = sunX + math.cos(angle) * (sunRadius + 5);
      final startY = sunY + math.sin(angle) * (sunRadius + 5);
      final endX = sunX + math.cos(angle) * rayLength;
      final endY = sunY + math.sin(angle) * rayLength;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }

    // Subtle sparkle effect (much less bright)
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
    // Cloud 1 - Large fluffy cloud
    final offset1 = (animation * 30).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.2 + offset1,
      size.height * 0.15,
      1.2,
    );

    // Cloud 2 - Medium cloud
    final offset2 = (animation * 20).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.6 - offset2,
      size.height * 0.25,
      0.9,
    );

    // Cloud 3 - Small cloud
    final offset3 = (animation * 25).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.4 + offset3,
      size.height * 0.35,
      0.7,
    );

    // Cloud 4 - Large cloud
    final offset4 = (animation * 15).remainder(size.width + 200) - 100;
    _drawRealisticCloud(
      canvas,
      size.width * 0.1 - offset4,
      size.height * 0.45,
      1.0,
    );
  }

  void _drawRealisticCloud(Canvas canvas, double x, double y, double scale) {
    // Shadow layer (softer, more subtle)
    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);

    _drawCloudShape(canvas, x + 2, y + 3, scale, shadowPaint);

    // Main cloud layer (less bright)
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    _drawCloudShape(canvas, x, y, scale, cloudPaint);

    // Highlight layer (much subtler)
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.85);

    // Fewer, smaller highlights
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
    // Bottom puffs
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

    // Middle puffs
    canvas.drawCircle(Offset(x + (15 * scale), y), 22 * scale, paint);
    canvas.drawCircle(
      Offset(x + (40 * scale), y - (5 * scale)),
      25 * scale,
      paint,
    );
    canvas.drawCircle(Offset(x + (60 * scale), y), 20 * scale, paint);

    // Top puffs (largest)
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
