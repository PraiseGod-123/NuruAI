import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

// ══════════════════════════════════════════════════════════════
// HOME SCREEN FOR AGES 20-25 - GLASSMORPHISM + BOTTOM NAV
// Design: Professional, data-driven, glass UI, reflective
// ══════════════════════════════════════════════════════════════

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

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.userData?['name'] ?? 'User';

    return Scaffold(
      backgroundColor: Color(0xFF4569AD),
      body: Stack(
        children: [
          // Background gradient - SAME AS ONBOARDING
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4569AD), Color(0xFF14366D)],
              ),
            ),
          ),

          // Stars layer - SAME AS ONBOARDING
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _floatController1,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SubtleStarsPainter(twinkle: _floatController1.value),
                );
              },
            ),
          ),

          // Animated 3D shapes - SAME AS ONBOARDING
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
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 100), // Only bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MAIN HEADER CARD - Edge-to-edge with curved bottom
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
                            horizontal: 24,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1F3F74).withOpacity(0.5),
                                Color(0xFF081F44).withOpacity(0.6),
                              ],
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF4569AD).withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Left icon - Profile
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF081F44).withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Color(0xFF4569AD).withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),

                              SizedBox(width: 16),

                              // Center text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
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
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF081F44).withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Color(
                                          0xFF4569AD,
                                        ).withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
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
                                          '3',
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
                                  '${widget.userData?['totalCheckIns'] ?? 0}',
                                  widget.userData?['checkInTrend'] ?? '',
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
                                  '${widget.userData?['avgMood']?.toStringAsFixed(1) ?? '0.0'}/10',
                                  widget.userData?['moodTrend'] ?? '',
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
                                  '${widget.userData?['currentStreak'] ?? 0} days',
                                  '',
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF081F44).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFF4569AD).withOpacity(0.4),
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
                                        child: Text(
                                          'Add context or notes...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white60,
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildGlassActionCard(
                                'Journal Entry',
                                'Document your thoughts',
                                Icons.book_outlined,
                                Color(0xFF4569AD),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildGlassActionCard(
                                'Breathing',
                                'Guided exercises',
                                Icons.air,
                                Color(0xFF1F3F74),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGlassActionCard(
                                'Analytics',
                                'View detailed insights',
                                Icons.analytics_outlined,
                                Color(0xFF3A5FA8),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildGlassActionCard(
                                'Resources',
                                'Self-help materials',
                                Icons.library_books_outlined,
                                Color(0xFF081F44),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Need Help - FRIENDLY APPROACH
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _buildGlassContainer(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1F3F74).withOpacity(0.75),
                          Color(0xFF081F44).withOpacity(0.85),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF081F44).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Color(0xFF4569AD).withOpacity(0.5),
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

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      // BOTTOM NAVIGATION BAR WITH GLASSMORPHISM
      bottomNavigationBar: _buildGlassBottomNav(),
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F3F74).withOpacity(0.75),
                    Color(0xFF081F44).withOpacity(0.80),
                  ],
                ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFF4569AD).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF081F44).withOpacity(0.5),
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
          Navigator.pushNamed(context, '/journal');
        } else {
          print('Navigate to: $title');
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F3F74).withOpacity(0.75),
                  Color(0xFF081F44).withOpacity(0.80),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF4569AD).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF081F44).withOpacity(0.5),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF081F44).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF4569AD).withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF081F44).withOpacity(0.5),
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
  // FIXED BOTTOM NAVIGATION BAR - Better visibility + organic shapes
  Widget _buildGlassBottomNav() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background matching screen gradient (NO border radius to prevent white edges)
            Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F3F74),
                    Color(0xFF081F44),
                    Color(0xFF081F44),
                    Color(0xFF0D2550),
                  ],
                ),
              ),
            ),

            // Organic shape 1 - Bottom left
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

            // Organic shape 2 - Top right
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

            // Organic shape 3 - Center
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
        if (index == 0) return; // already on home
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          Navigator.pushNamed(context, '/calmme').then((_) {
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        } else if (index == 2) {
          Navigator.pushNamed(context, '/analytics').then((_) {
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        } else if (index == 3) {
          Navigator.pushNamed(context, '/profile').then((_) {
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF4569AD).withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Color(0xFF4569AD).withOpacity(0.7), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white, // ALWAYS white for visibility
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white, // ALWAYS white for visibility
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stars Painter - same as onboarding
class SubtleStarsPainter extends CustomPainter {
  final double twinkle;

  SubtleStarsPainter({required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final stars = [
      [0.08, 0.05],
      [0.18, 0.15],
      [0.25, 0.08],
      [0.35, 0.20],
      [0.42, 0.12],
      [0.52, 0.18],
      [0.62, 0.08],
      [0.72, 0.22],
      [0.78, 0.14],
      [0.88, 0.10],
      [0.12, 0.48],
      [0.28, 0.55],
      [0.38, 0.62],
      [0.50, 0.58],
      [0.65, 0.52],
      [0.75, 0.65],
      [0.85, 0.58],
      [0.15, 0.82],
      [0.45, 0.88],
      [0.92, 0.85],
    ];

    for (final star in stars) {
      final x = size.width * star[0];
      final y = size.height * star[1];
      final opacity = 0.4 + (twinkle * 0.3);

      paint.color = Colors.white.withOpacity(opacity * 0.4);
      canvas.drawCircle(Offset(x, y), 3.5, paint);

      paint.color = Colors.white.withOpacity(opacity * 0.6);
      canvas.drawCircle(Offset(x, y), 2.0, paint);

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(SubtleStarsPainter oldDelegate) {
    return oldDelegate.twinkle != twinkle;
  }
}

// Animated 3D Shapes Painter - same as onboarding
class Animated3DShapesPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;

  Animated3DShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Color(0xFFB7C3E8).withOpacity(0.25);
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

    paint.color = Color(0xFF081F44).withOpacity(0.2);
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
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.05),
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
              Color(0xFF14366D).withOpacity(0.35),
              Color(0xFF14366D).withOpacity(0.1),
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
        oldDelegate.animation3 != animation3;
  }
}
