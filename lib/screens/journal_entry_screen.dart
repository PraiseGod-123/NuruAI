import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../utils/nuru_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';
import '../services/firebase_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class JournalEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? existingEntry;
  final String? existingId;

  const JournalEntryScreen({
    Key? key,
    this.userData,
    this.existingEntry,
    this.existingId,
  }) : super(key: key);

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  late AnimationController _starController;
  late AnimationController _entryController;

  String? selectedMood;
  DateTime selectedDate = DateTime.now();
  DateTime focusedDay = DateTime.now();

  // Colours

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
    _starController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    )..forward();

    // Pre-fill fields if editing an existing entry
    if (widget.existingEntry != null) {
      final e = widget.existingEntry!;
      _titleController.text = e['title'] as String? ?? '';
      _contentController.text = e['content'] as String? ?? '';
      selectedMood = e['mood'] as String?;
      final rawDate = e['date'];
      if (rawDate is String) {
        try {
          selectedDate = DateTime.parse(rawDate);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _starController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // Date picker

  void _showCalendarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.nuruTheme.backgroundMid.withOpacity(0.97),
                  context.nuruTheme.backgroundStart.withOpacity(0.99),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: context.nuruTheme.accentColor.withOpacity(0.35),
                ),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 6),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Calendar
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
                      color: context.nuruTheme.accentColor.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: Colors.white),
                    selectedDecoration: BoxDecoration(
                      color: context.nuruTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(color: Colors.white),
                    defaultTextStyle: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                    ),
                    weekendTextStyle: TextStyle(
                      color: context.nuruTheme.accentColor.withOpacity(0.6),
                    ),
                    outsideTextStyle: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    weekendStyle: TextStyle(
                      color: context.nuruTheme.accentColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.nuruTheme.accentColor,
                            context.nuruTheme.backgroundMid,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.nuruTheme.accentColor.withOpacity(
                            0.45,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Save

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showSnack('Please fill in title and content', const Color(0xFFEF5350));
      return;
    }
    if (selectedMood == null) {
      _showSnack('Please select your mood', const Color(0xFFFF9800));
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final uid = widget.userData?['uid'] as String? ?? '';
    final isEdit = widget.existingId != null && widget.existingId!.isNotEmpty;

    if (uid.isNotEmpty) {
      if (isEdit) {
        // Update existing entry in Firestore
        await NuruFirebaseService.instance.updateJournal(
          uid: uid,
          entryId: widget.existingId!,
          title: title,
          content: content,
          mood: selectedMood!,
          date: selectedDate,
        );
      } else {
        // Create new entry
        await NuruFirebaseService.instance.saveJournal(
          uid: uid,
          title: title,
          content: content,
          mood: selectedMood!,
          date: selectedDate,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      DateFormat('EEEE, d MMMM, yyyy').format(date);

  //  Build

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
        backgroundColor: const Color(0xFF081F44),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0D1F44), const Color(0xFF050D1A)],
                ),
              ),
            ),

            // Stars
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starController,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _EntryStarsPainter(twinkle: _starController.value),
                ),
              ),
            ),

            // Content
            SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (_, child) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(overscroll: false),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateSelector(),
                              const SizedBox(height: 22),
                              _sectionLabel('How are you feeling?'),
                              const SizedBox(height: 12),
                              _buildMoodSelector(),
                              const SizedBox(height: 22),
                              _sectionLabel('Title'),
                              const SizedBox(height: 10),
                              _buildTitleField(),
                              const SizedBox(height: 22),
                              _sectionLabel('What\'s on your mind?'),
                              const SizedBox(height: 10),
                              _buildContentField(),
                              const SizedBox(height: 28),
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
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

  // Header

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 14,
            20,
            22,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.nuruTheme.backgroundMid.withOpacity(0.65),
                context.nuruTheme.backgroundStart.withOpacity(0.55),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: context.nuruTheme.accentColor.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: _iconBtn(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'New Entry',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              // Save shortcut
              GestureDetector(
                onTap: _saveEntry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.nuruTheme.accentColor,
                        context.nuruTheme.backgroundMid,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.nuruTheme.accentColor.withOpacity(0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.nuruTheme.accentColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: context.nuruTheme.backgroundStart.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.nuruTheme.accentColor.withOpacity(0.45),
          width: 1.2,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.65),
        letterSpacing: 0.3,
      ),
    );
  }

  // Date selector

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _showCalendarPicker,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.nuruTheme.backgroundMid.withOpacity(0.7),
                  context.nuruTheme.backgroundStart.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.nuruTheme.accentColor.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.nuruTheme.accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: context.nuruTheme.accentColor.withOpacity(0.6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _formatDate(selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mood selector

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: moods.map((mood) {
        final isSelected = selectedMood == mood['value'];
        final moodColor =
            NuruColors.moodColors[mood['value']] ?? const Color(0xFF8EA2D7);

        return GestureDetector(
          onTap: () => setState(() => selectedMood = mood['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSelected
                    ? [
                        moodColor.withOpacity(0.3),
                        context.nuruTheme.backgroundStart.withOpacity(0.85),
                      ]
                    : [
                        context.nuruTheme.backgroundMid.withOpacity(0.6),
                        context.nuruTheme.backgroundStart.withOpacity(0.75),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? moodColor.withOpacity(0.7)
                    : context.nuruTheme.accentColor.withOpacity(0.3),
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: moodColor.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mood['emoji'] as String,
                  style: TextStyle(fontSize: isSelected ? 26 : 22),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                  ),
                  child: Text(mood['label'] as String),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Text fields

  Widget _buildTitleField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.nuruTheme.backgroundMid.withOpacity(0.7),
                context.nuruTheme.backgroundStart.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.nuruTheme.accentColor.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: context.nuruTheme.accentColor.withOpacity(0.6),
                selectionColor: Color(0x554569AD),
                selectionHandleColor: context.nuruTheme.accentColor.withOpacity(
                  0.6,
                ),
              ),
            ),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              cursorColor: context.nuruTheme.accentColor.withOpacity(0.6),
              decoration: InputDecoration(
                hintText: 'Entry title…',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.32),
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(minHeight: 240),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.nuruTheme.backgroundMid.withOpacity(0.7),
                context.nuruTheme.backgroundStart.withOpacity(0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.nuruTheme.accentColor.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: context.nuruTheme.accentColor.withOpacity(0.6),
                selectionColor: Color(0x554569AD),
                selectionHandleColor: context.nuruTheme.accentColor.withOpacity(
                  0.6,
                ),
              ),
            ),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.65,
                decoration: TextDecoration.none,
              ),
              cursorColor: context.nuruTheme.accentColor.withOpacity(0.6),
              decoration: InputDecoration(
                hintText: 'Write freely — this is your safe space…',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.28),
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Save button

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveEntry,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.nuruTheme.accentColor,
              context.nuruTheme.backgroundMid,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.nuruTheme.accentColor.withOpacity(0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.nuruTheme.accentColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.existingId != null ? 'Update Entry' : 'Save Entry',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Stars painter (entry screen)

class _EntryStarsPainter extends CustomPainter {
  final double twinkle;

  const _EntryStarsPainter({required this.twinkle});

  static const List<List<double>> _stars = [
    // Band 1 — top
    [0.05, 0.03, 0], [0.14, 0.06, 1], [0.27, 0.02, 2],
    [0.38, 0.08, 0], [0.50, 0.04, 1], [0.63, 0.01, 0],
    [0.74, 0.07, 2], [0.83, 0.03, 1], [0.92, 0.09, 0],
    // Band 2
    [0.08, 0.15, 1], [0.20, 0.19, 0], [0.33, 0.14, 2],
    [0.46, 0.18, 0], [0.57, 0.12, 1], [0.68, 0.20, 0],
    [0.79, 0.16, 2], [0.88, 0.22, 0], [0.97, 0.13, 1],
    // Band 3
    [0.03, 0.29, 0], [0.16, 0.33, 2], [0.29, 0.27, 0],
    [0.42, 0.35, 1], [0.54, 0.30, 0], [0.66, 0.37, 2],
    [0.77, 0.28, 0], [0.86, 0.34, 1], [0.94, 0.31, 0],
    // Band 4
    [0.07, 0.45, 1], [0.19, 0.49, 0], [0.31, 0.43, 2],
    [0.44, 0.51, 0], [0.56, 0.46, 1], [0.69, 0.53, 0],
    [0.80, 0.47, 2], [0.90, 0.54, 0], [0.98, 0.42, 1],
    // Band 5
    [0.04, 0.61, 0], [0.15, 0.66, 2], [0.26, 0.59, 1],
    [0.39, 0.64, 0], [0.52, 0.69, 2], [0.64, 0.62, 0],
    [0.75, 0.67, 1], [0.85, 0.61, 0], [0.95, 0.70, 2],
    // Band 6
    [0.09, 0.77, 1], [0.21, 0.81, 0], [0.34, 0.75, 2],
    [0.47, 0.79, 0], [0.59, 0.83, 1], [0.71, 0.76, 0],
    [0.82, 0.82, 2], [0.91, 0.78, 1], [0.99, 0.85, 0],
    // Band 7 — bottom
    [0.06, 0.90, 0], [0.18, 0.93, 2], [0.30, 0.88, 1],
    [0.43, 0.95, 0], [0.55, 0.91, 2], [0.67, 0.96, 0],
    [0.78, 0.89, 1], [0.87, 0.94, 2], [0.96, 0.92, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in _stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final type = s[2];

      final phase = (s[0] * 3.7 + s[1] * 5.3) % 1.0;
      final t = ((twinkle + phase) % 1.0);
      final op = 0.20 + t * 0.45;

      if (type == 0) {
        paint.color = Colors.white.withOpacity(op * 0.65);
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      } else if (type == 1) {
        paint.color = Colors.white.withOpacity(op * 0.18);
        canvas.drawCircle(Offset(x, y), 3.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.55);
        canvas.drawCircle(Offset(x, y), 1.4, paint);
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      } else {
        paint.color = Colors.white.withOpacity(op * 0.10);
        canvas.drawCircle(Offset(x, y), 5.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.25);
        canvas.drawCircle(Offset(x, y), 3.0, paint);
        paint.color = Colors.white.withOpacity(op * 0.65);
        canvas.drawCircle(Offset(x, y), 1.5, paint);
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_EntryStarsPainter old) => old.twinkle != twinkle;
}
