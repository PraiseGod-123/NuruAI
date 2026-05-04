import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';
import '../services/firebase_service.dart';

class HomeScreenTeen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreenTeen({Key? key, this.userData}) : super(key: key);

  @override
  State<HomeScreenTeen> createState() => _HomeScreenTeenState();
}

class _HomeScreenTeenState extends State<HomeScreenTeen>
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
    // Build star field
    for (int i = 0; i < 70; i++) {
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
  int get _liveCheckIns =>
      (_liveStats['totalCheckIns'] as num? ??
              widget.userData?['totalCheckIns'] as num? ??
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
      if (mounted && _currentNavIndex != 0)
        setState(() => _currentNavIndex = 0);
    });

    final theme = context.nuruTheme;
    final userName = widget.userData?['name'] as String? ?? 'User';
    final createdAtStr = widget.userData?['createdAt'] as String?;
    final isNewUser =
        createdAtStr != null &&
        DateTime.now().difference(DateTime.parse(createdAtStr)).inHours < 24;
    final greeting = isNewUser ? 'Welcome,' : 'Welcome back,';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF081F44),
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
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _floatController1,
                  _floatController2,
                  _floatController3,
                ]),
                builder: (ctx, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _TeenShapesPainter(
                    animation1: _floatController1.value,
                    animation2: _floatController2.value,
                    animation3: _floatController3.value,
                    accentColor: context.nuruTheme.accentColor,
                    bgColor: context.nuruTheme.backgroundStart,
                    bgEnd: context.nuruTheme.backgroundMid,
                  ),
                ),
              ),
            ),
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
                      _buildHeader(context, theme, userName, greeting),
                      _buildStatsRow(context, theme),
                      SizedBox(height: 20),
                      _buildMoodSection(context, theme),
                      SizedBox(height: 20),
                      _buildToolsSection(context, theme),
                      SizedBox(height: 20),
                      _buildNuruAICard(context, theme),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(context, theme),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic theme,
    String userName,
    String greeting,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF081F44).withOpacity(0.80),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/profile',
                    arguments: widget.userData,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
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
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    final uid = widget.userData?['uid'] as String? ?? '';
                    if (uid.isNotEmpty) {
                      NuruFirebaseService.instance.clearUnreadNotifications(
                        uid,
                      );
                    }
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.20),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _liveUnread > 0
                                  ? Icons.notifications
                                  : Icons.notifications_outlined,
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
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                _liveUnread > 99 ? '99+' : '$_liveUnread',
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
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '$_liveStreak',
              'Day Streak',
              Icons.local_fire_department,
              Color(0xFFFF9800),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              '$_liveCheckIns',
              'Check-ins',
              Icons.check_circle,
              Color(0xFF4CAF50),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              '${widget.userData?['progressPercentage']?.toInt() ?? 0}%',
              'Progress',
              Icons.trending_up,
              Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Today's Mood",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _glassContainer(
            context: context,
            theme: theme,
            padding: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMoodOption(
                      'Excellent',
                      Icons.sentiment_very_satisfied,
                      Color(0xFF4CAF50),
                    ),
                    _buildMoodOption(
                      'Good',
                      Icons.sentiment_satisfied,
                      Color(0xFF8BC34A),
                    ),
                    _buildMoodOption(
                      'Neutral',
                      Icons.sentiment_neutral,
                      Color(0xFFFFC107),
                    ),
                    _buildMoodOption(
                      'Low',
                      Icons.sentiment_dissatisfied,
                      Color(0xFFFF9800),
                    ),
                    _buildMoodOption(
                      'Difficult',
                      Icons.sentiment_very_dissatisfied,
                      Color(0xFFF44336),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                // Saved notes
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
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.white70),
                      SizedBox(width: 8),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: Colors.white70,
                              selectionColor: Colors.white24,
                            ),
                          ),
                          child: TextField(
                            controller: _moodNoteController,
                            style: TextStyle(fontSize: 13, color: Colors.white),
                            cursorColor: Colors.white70,
                            decoration: InputDecoration(
                              hintText: 'Add a note about your day...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.white60,
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
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Tools & Resources',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildToolCard(
                context,
                theme,
                'Breathing',
                'Calm your mind',
                Icons.air,
                Color(0xFF2196F3),
              ),
              _buildToolCard(
                context,
                theme,
                'Journal',
                'Express yourself',
                Icons.book_outlined,
                Color(0xFF9C27B0),
              ),
              _buildToolCard(
                context,
                theme,
                'Guidance',
                'Get support',
                Icons.psychology,
                Color(0xFF00BCD4),
              ),
              _buildToolCard(
                context,
                theme,
                'Insights',
                'Track patterns',
                Icons.insights,
                Color(0xFFFF9800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    dynamic theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
        if (title == 'Insights')
          Navigator.pushNamed(
            context,
            '/analytics',
            arguments: widget.userData,
          );
        if (title == 'Guidance')
          Navigator.pushNamed(context, '/nuru-ai', arguments: widget.userData);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.nuruTheme.backgroundMid,
                  context.nuruTheme.backgroundStart,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.nuruTheme.accentColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.nuruTheme.backgroundStart.withOpacity(0.5),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
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

  Widget _buildNuruAICard(BuildContext context, dynamic theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/nuru-ai',
          arguments: widget.userData,
        ),
        child: _glassContainer(
          context: context,
          theme: theme,
          gradient: LinearGradient(
            colors: [
              Color(0xFF667eea).withOpacity(0.3),
              Color(0xFF764ba2).withOpacity(0.3),
            ],
          ),
          padding: 20,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.nuruTheme.backgroundStart.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talk to NuruAI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "I'm here to listen and support you",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({
    required BuildContext context,
    required dynamic theme,
    required Widget child,
    LinearGradient? gradient,
    double padding = 24,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.nuruTheme.backgroundMid,
                    context.nuruTheme.backgroundStart,
                  ],
                ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.nuruTheme.accentColor.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.nuruTheme.backgroundStart.withOpacity(0.5),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMoodOption(String label, IconData icon, Color color) {
    final isSelected = _selectedMood == label;

    // Map mood labels to 1-10 scores
    const moodScores = {
      'Excellent': 10,
      'Good': 8,
      'Neutral': 6,
      'Low': 4,
      'Difficult': 2,
    };

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
            padding: EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              size: 22,
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, dynamic theme) {
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
              child: _orb(110, Colors.white.withOpacity(0.08)),
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

// RealisticStarsPainter
// Stars painter
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

class _TeenShapesPainter extends CustomPainter {
  final double animation1, animation2, animation3;
  final Color accentColor, bgColor, bgEnd;
  const _TeenShapesPainter({
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
    paint.color = accentColor.withOpacity(0.38);
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
    paint.color = bgColor.withOpacity(0.32);
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
            bgEnd.withOpacity(0.35),
            bgEnd.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c2, radius: 110)),
    );
  }

  @override
  bool shouldRepaint(_TeenShapesPainter o) =>
      o.animation1 != animation1 ||
      o.animation2 != animation2 ||
      o.animation3 != animation3 ||
      o.accentColor != accentColor ||
      o.bgColor != bgColor;
}
