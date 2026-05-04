import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';
import '../services/firebase_service.dart';

// HOME SCREEN FOR AGES 20-25

class HomeScreenYoungAdult extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomeScreenYoungAdult({Key? key, this.userData}) : super(key: key);

  @override
  State<HomeScreenYoungAdult> createState() => _HomeScreenYoungAdultState();
}

class _HomeScreenYoungAdultState extends State<HomeScreenYoungAdult>
    with TickerProviderStateMixin {
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  int _selectedMoodIndex = -1;
  int _currentNavIndex = 0;
  Map<String, dynamic> _liveStats = {};
  bool _moodLoggedToday = false;
  final TextEditingController _moodNoteController = TextEditingController();
  final List<String> _savedNotes = [];

  final _rng = math.Random();
  final List<_Star> _stars = [];

  @override
  void initState() {
    super.initState();
    // Build star field — same as analytics screen
    for (int i = 0; i < 90; i++) {
      _stars.add(
        _Star(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          size: _rng.nextDouble() < 0.5
              ? 1.2
              : (_rng.nextDouble() < 0.7 ? 1.8 : 2.6),
          phase: _rng.nextDouble() * math.pi * 2,
          speed: 0.5 + _rng.nextDouble() * 0.9,
        ),
      );
    }
    _loadLiveStats();

    _floatController1 = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatController2 = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _floatController3 = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _loadLiveStats() {
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isEmpty) return;
    NuruFirebaseService.instance.streamUserStats(uid).listen((stats) {
      if (mounted) setState(() => _liveStats = stats);
    });
  }

  Future<void> _logMoodCheckIn(int moodScore) async {
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isEmpty || _moodLoggedToday) return;
    setState(() => _moodLoggedToday = true);
    await NuruFirebaseService.instance.logCheckIn(
      uid: uid,
      moodScore: moodScore,
      note: _moodNoteController.text.trim().isNotEmpty
          ? _moodNoteController.text.trim()
          : null,
    );
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _moodNoteController.dispose();
    super.dispose();
  }

  // Live stat helpers
  int get _liveStreak =>
      (_liveStats['currentStreak'] as num? ??
              widget.userData?['currentStreak'] as num? ??
              0)
          .toInt();
  int get _liveCheckIns =>
      (_liveStats['totalCheckIns'] as num? ??
              widget.userData?['totalCheckIns'] as num? ??
              0)
          .toInt();
  double get _liveAvgMood =>
      (_liveStats['avgMood'] as num? ??
              widget.userData?['avgMood'] as num? ??
              0.0)
          .toDouble();
  int get _liveUnread =>
      (_liveStats['unreadNotifications'] as num? ??
              widget.userData?['unreadNotifications'] as num? ??
              0)
          .toInt();
  int get _liveStreakVal =>
      (_liveStats['currentStreak'] as num? ??
              widget.userData?['currentStreak'] as num? ??
              0)
          .toInt();

  @override
  Widget build(BuildContext context) {
    // Reset selection to Home whenever this screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentNavIndex != 0) {
        setState(() {
          _currentNavIndex = 0;
        });
      }
    });

    final userName = widget.userData?['name'] as String? ?? 'User';

    // Determine if this is a new user (account created within last 10 minutes)
    final createdAtStr = widget.userData?['createdAt'] as String?;
    final isNewUser =
        createdAtStr != null &&
        DateTime.now().difference(DateTime.parse(createdAtStr)).inHours < 24;
    final greeting = isNewUser ? 'Welcome,' : 'Welcome back,';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF081F44),
        body: Stack(
          children: [
            // Background gradient - SAME AS ONBOARDING
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.nuruTheme.gradientColors,
                ),
              ),
            ),

            // Stars layer
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _floatController1,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _StarsPainter(_stars, _floatController1.value),
                    );
                  },
                ),
              ),
            ),

            // Animated 3D shapes
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _floatController1,
                  _floatController2,
                  _floatController3,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: Animated3DShapesPainter(
                      animation1: _floatController1.value,
                      animation2: _floatController2.value,
                      animation3: _floatController3.value,
                      accentColor: context.nuruTheme.accentColor,
                      bgColor: context.nuruTheme.backgroundStart,
                    ),
                  );
                },
              ),
            ),

            // Main content
            SafeArea(
              top: false,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MAIN HEADER CARD - Edge-to-edge, extends behind status bar
                      Container(
                        margin: EdgeInsets.only(bottom: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: MediaQuery.of(context).padding.top + 16,
                                bottom: 24,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF081F44,
                                ).withOpacity(0.75),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left icon - Profile
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.20,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 16),

                                  // Center text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          greeting,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 16),

                                  // Right icon - Notifications with badge
                                  GestureDetector(
                                    onTap: () {
                                      final uid =
                                          widget.userData?['uid'] as String? ??
                                          '';
                                      if (uid.isNotEmpty) {
                                        NuruFirebaseService.instance
                                            .clearUnreadNotifications(uid);
                                      }
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 8,
                                              sigmaY: 8,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.20),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                _liveUnread > 0
                                                    ? Icons.notifications
                                                    : Icons
                                                          .notifications_outlined,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_liveUnread > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF4CAF50),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _liveUnread > 99
                                                      ? '99+'
                                                      : '$_liveUnread',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Metrics Overview - GLASSMORPHISM
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _buildGlassContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Check-ins',
                                      '$_liveCheckIns',
                                      _liveCheckIns > 0
                                          ? '↑ keep going'
                                          : 'Start today',
                                      Color(0xFF4CAF50),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Avg. Mood',
                                      _liveAvgMood > 0
                                          ? '${_liveAvgMood.toStringAsFixed(1)}/10'
                                          : '—',
                                      _liveAvgMood >= 7
                                          ? '↑ great'
                                          : _liveAvgMood >= 4
                                          ? '→ steady'
                                          : _liveAvgMood > 0
                                          ? '↓ low'
                                          : '',
                                      Color(0xFF2196F3),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Streak',
                                      _liveStreak > 0
                                          ? '$_liveStreak days'
                                          : '0 days',
                                      _liveStreak > 0
                                          ? '🔥 active'
                                          : 'Log mood to start',
                                      Color(0xFFFF9800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Mood Assessment - GLASSMORPHISM
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'How Are You Feeling?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _buildGlassContainer(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(5, (index) {
                                  final colors = [
                                    Color(0xFFF44336),
                                    Color(0xFFFF9800),
                                    Color(0xFFFFC107),
                                    Color(0xFF8BC34A),
                                    Color(0xFF4CAF50),
                                  ];
                                  final icons = [
                                    Icons.sentiment_very_dissatisfied,
                                    Icons.sentiment_dissatisfied,
                                    Icons.sentiment_neutral,
                                    Icons.sentiment_satisfied,
                                    Icons.sentiment_very_satisfied,
                                  ];
                                  return _buildMoodScale(
                                    index,
                                    colors[index],
                                    icons[index],
                                  );
                                }),
                              ),
                              SizedBox(height: 20),
                              // Saved notes list
                              if (_savedNotes.isNotEmpty) ...[
                                ..._savedNotes
                                    .map(
                                      (note) => Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 14,
                                              color: Colors.white54,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                note,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                SizedBox(height: 8),
                              ],
                              // Note input field
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.nuruTheme.backgroundStart
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: context.nuruTheme.accentColor
                                              .withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Theme(
                                              data: Theme.of(context).copyWith(
                                                textSelectionTheme:
                                                    TextSelectionThemeData(
                                                      cursorColor:
                                                          Colors.white70,
                                                      selectionColor:
                                                          Colors.white24,
                                                      selectionHandleColor:
                                                          Colors.white70,
                                                    ),
                                              ),
                                              child: TextField(
                                                controller: _moodNoteController,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                                cursorColor: Colors.white70,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Add context or notes...',
                                                  hintStyle: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white60,
                                                  ),
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                                maxLines: 1,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onSubmitted: (value) {
                                                  final trimmed = value.trim();
                                                  if (trimmed.isNotEmpty) {
                                                    setState(() {
                                                      _savedNotes.add(trimmed);
                                                      _moodNoteController
                                                          .clear();
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Quick Actions Grid - GLASSMORPHISM
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildGlassActionCard(
                                      'Journal Entry',
                                      'Document your thoughts',
                                      Icons.book_outlined,
                                      context.nuruTheme.accentColor,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGlassActionCard(
                                      'Breathing',
                                      'Guided exercises',
                                      Icons.air,
                                      context.nuruTheme.backgroundMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildGlassActionCard(
                                      'Analytics',
                                      'View detailed insights',
                                      Icons.analytics_outlined,
                                      context.nuruTheme.accentColor,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGlassActionCard(
                                      'Resources',
                                      'Self-help materials',
                                      Icons.library_books_outlined,
                                      context.nuruTheme.backgroundStart,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Need Help
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/nuru-ai',
                            arguments: widget.userData,
                          ),
                          child: _buildGlassContainer(
                            gradient: LinearGradient(
                              colors: [
                                context.nuruTheme.backgroundMid,
                                context.nuruTheme.backgroundStart,
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.nuruTheme.backgroundStart
                                        .withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: context.nuruTheme.accentColor
                                          .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.support_agent,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Need Help?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Chat with NuruAI anytime',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // BOTTOM NAVIGATION BAR WITH GLASSMORPHISM
        bottomNavigationBar: _buildGlassBottomNav(),
      ),
    );
  }

  // Glassmorphism icon button
  Widget _buildGlassIconButton(IconData icon) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  // Glassmorphism container
  Widget _buildGlassContainer({
    required Widget child,
    LinearGradient? gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF081F44).withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    String change,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (change.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMoodScale(int index, Color color, IconData icon) {
    final isSelected = _selectedMoodIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMoodIndex = index;
        });
        // Map 0-4 index to 1-10 mood score (2, 4, 6, 8, 10)
        final moodScore = (index + 1) * 2;
        _logMoodCheckIn(moodScore);
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.white.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildGlassActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'Journal Entry') {
          Navigator.pushNamed(context, '/journal', arguments: widget.userData);
        } else if (title == 'Breathing') {
          Navigator.pushNamed(
            context,
            '/breathing',
            arguments: widget.userData,
          );
        } else if (title == 'Analytics') {
          Navigator.pushNamed(
            context,
            '/analytics',
            arguments: widget.userData,
          );
        } else if (title == 'Resources') {
          Navigator.pushNamed(
            context,
            '/resources',
            arguments: widget.userData,
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF081F44).withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.nuruTheme.backgroundStart.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.nuruTheme.accentColor.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.nuruTheme.backgroundStart.withOpacity(
                          0.5,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // GLASSMORPHISM BOTTOM NAVIGATION BAR
  Widget _buildGlassBottomNav() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background matching screen gradient (NO border radius to prevent white edges)
            Container(
              height: 75,
              decoration: const BoxDecoration(color: Color(0xFF081F44)),
            ),

            // Organic shape 1
            Positioned(
              left: -40,
              bottom: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Organic shape 2
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Organic shape 3
            Positioned(
              left: constraints.maxWidth * 0.45,
              bottom: -10,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top border gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation items with better visibility
            Container(
              height: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', 0),
                  _buildNavItem(Icons.spa_outlined, 'CalmMe', 1),
                  _buildNavItem(Icons.analytics_outlined, 'Analytics', 2),
                  _buildNavItem(Icons.person_outline, 'Profile', 3),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        // Update selection to where user tapped
        setState(() {
          _currentNavIndex = index;
        });

        // Navigate to different screens
        if (index == 1) {
          Navigator.pushNamed(context, '/calmme', arguments: widget.userData);
        } else if (index == 2) {
          Navigator.pushNamed(
            context,
            '/analytics',
            arguments: widget.userData,
          );
        } else if (index == 3) {
          Navigator.pushNamed(context, '/profile', arguments: widget.userData);
        }
        // If index == 0 (Home), we're already here, do nothing
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.nuruTheme.accentColor.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: context.nuruTheme.accentColor.withOpacity(0.7),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stars painter (same as analytics screen)
class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  const _StarsPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final flicker =
          0.4 +
          0.6 * (0.5 + 0.5 * math.sin(s.phase + t * s.speed * math.pi * 2));
      paint.color = Colors.white.withOpacity(flicker * 0.85);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}

class _Star {
  final double x, y, size, phase, speed;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });
}

class Animated3DShapesPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final Color accentColor;
  final Color bgColor;

  Animated3DShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4569AD).withOpacity(0.35); // Sailing Blue
    final offsetY1 = animation1 * 40 - 20;
    final path1 = Path()
      ..moveTo(0, offsetY1)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.1 + offsetY1,
        size.width * 0.4,
        size.height * 0.25 + offsetY1,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.4 + offsetY1,
        size.width * 0.3,
        size.height * 0.5 + offsetY1,
      )
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.6 + offsetY1,
        0,
        size.height * 0.4 + offsetY1,
      )
      ..close();
    canvas.drawPath(path1, paint);

    paint.color = const Color(0xFF1F3F74).withOpacity(0.35); // Dive
    final offsetX2 = animation2 * 35 - 17;
    final path2 = Path()
      ..moveTo(size.width, size.height * 0.2 + offsetX2)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.3 + offsetX2,
        size.width * 0.6,
        size.height * 0.5 + offsetX2,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.7 + offsetX2,
        size.width * 0.7,
        size.height * 0.8 + offsetX2,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.9 + offsetX2,
        size.width,
        size.height * 0.7 + offsetX2,
      )
      ..close();
    canvas.drawPath(path2, paint);

    final spherePaint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF4569AD).withOpacity(0.40), // Sailing Blue
              const Color(0xFF4569AD).withOpacity(0.08),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.75 + (animation1 * 25 - 12),
                size.height * 0.15 + (animation2 * 20 - 10),
              ),
              radius: 90,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.75 + (animation1 * 25 - 12),
        size.height * 0.15 + (animation2 * 20 - 10),
      ),
      90,
      spherePaint1,
    );

    final spherePaint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF1F3F74).withOpacity(0.45), // Dive
              const Color(0xFF1F3F74).withOpacity(0.15),
              Colors.transparent,
            ],
            stops: [0.0, 0.6, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.3 + (animation3 * 30 - 15),
                size.height * 0.85 + (animation1 * 20 - 10),
              ),
              radius: 110,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.3 + (animation3 * 30 - 15),
        size.height * 0.85 + (animation1 * 20 - 10),
      ),
      110,
      spherePaint2,
    );
  }

  @override
  bool shouldRepaint(Animated3DShapesPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3 ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.bgColor != bgColor;
  }
}
