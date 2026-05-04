import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';
import '../services/firebase_service.dart';

// HOME SCREEN FOR AGES 13-15

class HomeScreenYoung extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreenYoung({Key? key, this.userData}) : super(key: key);

  @override
  State<HomeScreenYoung> createState() => _HomeScreenYoungState();
}

class _HomeScreenYoungState extends State<HomeScreenYoung>
    with TickerProviderStateMixin {
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  String? _selectedMood;
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

  // Live stat helpers
  int get _liveStreak =>
      (_liveStats['currentStreak'] as num? ??
              widget.userData?['currentStreak'] as num? ??
              0)
          .toInt();

  int get _liveUnread =>
      (_liveStats['unreadNotifications'] as num? ??
              widget.userData?['unreadNotifications'] as num? ??
              0)
          .toInt();

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _moodNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentNavIndex != 0) {
        setState(() => _currentNavIndex = 0);
      }
    });

    final theme = context.nuruTheme;
    final userName = widget.userData?['name'] as String? ?? 'User';
    final createdAtStr = widget.userData?['createdAt'] as String?;
    final isNewUser =
        createdAtStr != null &&
        DateTime.now().difference(DateTime.parse(createdAtStr)).inHours < 24;
    final greeting = isNewUser ? 'Welcome,' : 'Welcome back,';

    return Scaffold(
      backgroundColor: theme.backgroundStart,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
            ),
          ),

          // Stars
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _floatController1,
                builder: (ctx, _) => CustomPaint(
                  painter: _StarsPainter(_stars, _floatController1.value),
                ),
              ),
            ),
          ),

          // Animated shapes
          IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _floatController1,
                _floatController2,
                _floatController3,
              ]),
              builder: (ctx, _) => CustomPaint(
                size: Size.infinite,
                painter: _YoungShapesPainter(
                  animation1: _floatController1.value,
                  animation2: _floatController2.value,
                  animation3: _floatController3.value,
                  accentColor: theme.accentColor,
                  bgColor: theme.backgroundStart,
                  bgEnd: theme.backgroundEnd,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(overscroll: false),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 90),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      margin: EdgeInsets.only(bottom: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF081F44).withOpacity(0.80),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(0.22),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Profile icon
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/profile',
                                    arguments: widget.userData,
                                  ),
                                  child: ClipRRect(
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
                                ),

                                SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        greeting,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 16),

                                // Notification icon
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
                                        borderRadius: BorderRadius.circular(16),
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
                                                color: Colors.white.withOpacity(
                                                  0.20,
                                                ),
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

                    // Streak card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _buildGlassContainer(
                        context: context,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.backgroundStart.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFFFF9800).withOpacity(0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFFF9800),
                                    Color(0xFFFFD54F),
                                  ],
                                ).createShader(bounds),
                                child: Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_liveStreak Day Streak!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _liveStreak > 0
                                        ? 'Keep up the great work!'
                                        : 'Start your streak today!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Mood section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _buildGlassContainer(
                        context: context,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMoodButton(
                              'Great',
                              Icons.sentiment_very_satisfied,
                              Color(0xFF4CAF50),
                            ),
                            _buildMoodButton(
                              'Good',
                              Icons.sentiment_satisfied,
                              Color(0xFF2196F3),
                            ),
                            _buildMoodButton(
                              'Okay',
                              Icons.sentiment_neutral,
                              Color(0xFFFFC107),
                            ),
                            _buildMoodButton(
                              'Down',
                              Icons.sentiment_dissatisfied,
                              Color(0xFFFF9800),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Notes field below mood buttons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _buildGlassContainer(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_savedNotes.isNotEmpty) ...[
                              ..._savedNotes
                                  .map(
                                    (note) => Padding(
                                      padding: EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 13,
                                            color: Colors.white54,
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              note,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              SizedBox(height: 6),
                            ],
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Colors.white60,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        textSelectionTheme:
                                            TextSelectionThemeData(
                                              cursorColor: Colors.white70,
                                              selectionColor: Colors.white24,
                                            ),
                                      ),
                                      child: TextField(
                                        controller: _moodNoteController,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white70,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Add a note about your day...',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        maxLines: 1,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (value) {
                                          final trimmed = value.trim();
                                          if (trimmed.isNotEmpty) {
                                            setState(() {
                                              _savedNotes.add(trimmed);
                                              _moodNoteController.clear();
                                            });
                                          }
                                        },
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

                    SizedBox(height: 32),

                    // Activities
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Activities',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        children: [
                          _buildActivityCard(
                            context,
                            'Daily Check-in',
                            Icons.check_circle_outline,
                            Color(0xFF4CAF50),
                          ),
                          _buildActivityCard(
                            context,
                            'Breathing',
                            Icons.air,
                            Color(0xFF2196F3),
                          ),
                          _buildActivityCard(
                            context,
                            'Journal',
                            Icons.book_outlined,
                            Color(0xFF9C27B0),
                          ),
                          _buildActivityCard(
                            context,
                            'Progress',
                            Icons.trending_up,
                            Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Support card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/nuru-ai',
                          arguments: widget.userData,
                        ),
                        child: _buildGlassContainer(
                          context: context,
                          child: Row(
                            children: [
                              Icon(
                                Icons.support_agent,
                                color: Colors.white,
                                size: 32,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  // Helpers

  Widget _buildGlassContainer({
    required BuildContext context,
    required Widget child,
    double padding = 24,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF081F44).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMoodButton(String label, IconData icon, Color color) {
    final isSelected = _selectedMood == label;

    // Map mood labels to 1-10 scores
    const moodScores = {'Great': 10, 'Good': 8, 'Okay': 6, 'Down': 3};

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMood = label);
        final score = moodScores[label] ?? 6;
        _logMoodCheckIn(score);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.white.withOpacity(0.3),
                width: 2.5,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 32,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    final theme = context.nuruTheme;
    return GestureDetector(
      onTap: () {
        if (title == 'Journal')
          Navigator.pushNamed(context, '/journal', arguments: widget.userData);
        if (title == 'Breathing')
          Navigator.pushNamed(
            context,
            '/breathing',
            arguments: widget.userData,
          );
        if (title == 'Progress')
          Navigator.pushNamed(
            context,
            '/analytics',
            arguments: widget.userData,
          );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.backgroundMid.withOpacity(0.75),
                  theme.backgroundStart.withOpacity(0.80),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.accentColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.backgroundStart.withOpacity(0.5),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.14),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    final theme = context.nuruTheme;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Stack(
          children: [
            Container(
              height: 75,
              decoration: const BoxDecoration(color: Color(0xFF081F44)),
            ),
            Positioned(
              left: -40,
              bottom: -20,
              child: _orb(140, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              right: -30,
              top: -40,
              child: _orb(130, Colors.white.withOpacity(0.10)),
            ),
            Positioned(
              left: constraints.maxWidth * 0.45,
              bottom: -10,
              child: _orb(110, Colors.white.withOpacity(0.14)),
            ),
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
            SizedBox(
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

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color, color.withOpacity(0.3), Colors.transparent],
      ),
    ),
  );

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 1)
          Navigator.pushNamed(context, '/calmme', arguments: widget.userData);
        if (index == 2)
          Navigator.pushNamed(
            context,
            '/analytics',
            arguments: widget.userData,
          );
        if (index == 3)
          Navigator.pushNamed(context, '/profile', arguments: widget.userData);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
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

class _YoungShapesPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final Color accentColor;
  final Color bgColor;
  final Color bgEnd;

  const _YoungShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.accentColor,
    required this.bgColor,
    required this.bgEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blob 1
    paint.color = const Color(0xFF4569AD).withOpacity(0.55); // Sailing Blue
    final oy1 = animation1 * 40 - 20;
    canvas.drawPath(
      Path()
        ..moveTo(0, oy1)
        ..quadraticBezierTo(
          size.width * 0.3,
          size.height * 0.1 + oy1,
          size.width * 0.4,
          size.height * 0.25 + oy1,
        )
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.4 + oy1,
          size.width * 0.3,
          size.height * 0.5 + oy1,
        )
        ..quadraticBezierTo(
          size.width * 0.1,
          size.height * 0.6 + oy1,
          0,
          size.height * 0.4 + oy1,
        )
        ..close(),
      paint,
    );

    // Blob 2
    paint.color = const Color(0xFF1F3F74).withOpacity(0.55); // Dive
    final ox2 = animation2 * 35 - 17;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height * 0.2 + ox2)
        ..quadraticBezierTo(
          size.width * 0.7,
          size.height * 0.3 + ox2,
          size.width * 0.6,
          size.height * 0.5 + ox2,
        )
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.7 + ox2,
          size.width * 0.7,
          size.height * 0.8 + ox2,
        )
        ..quadraticBezierTo(
          size.width * 0.9,
          size.height * 0.9 + ox2,
          size.width,
          size.height * 0.7 + ox2,
        )
        ..close(),
      paint,
    );

    // Sphere 1
    final c1 = Offset(
      size.width * 0.75 + (animation1 * 25 - 12),
      size.height * 0.15 + (animation2 * 20 - 10),
    );
    canvas.drawCircle(
      c1,
      90,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ).createShader(Rect.fromCircle(center: c1, radius: 90)),
    );

    // Sphere 2
    final c2 = Offset(
      size.width * 0.3 + (animation3 * 30 - 15),
      size.height * 0.85 + (animation1 * 20 - 10),
    );
    canvas.drawCircle(
      c2,
      110,
      Paint()
        ..shader = RadialGradient(
          colors: [
            bgEnd.withOpacity(0.55), // Dive
            const Color(0xFF1F3F74).withOpacity(0.22),
            Colors.transparent,
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c2, radius: 110)),
    );
  }

  @override
  bool shouldRepaint(_YoungShapesPainter o) =>
      o.animation1 != animation1 ||
      o.animation2 != animation2 ||
      o.animation3 != animation3 ||
      o.accentColor != accentColor ||
      o.bgColor != bgColor;
}
