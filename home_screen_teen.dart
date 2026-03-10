import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

// ══════════════════════════════════════════════════════════════
// HOME SCREEN FOR AGES 16-19 - NEW DESIGN
// Design: Icon-Text-Icon header layout
// ══════════════════════════════════════════════════════════════

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
    // Reset selection to Home whenever this screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentNavIndex != 0) {
        setState(() {
          _currentNavIndex = 0;
        });
      }
    });

    final userName = widget.userData?['name'] ?? 'User';

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4569AD), // Base blue
                  Color(0xFF4864B5), // Blue with purple hint
                  Color(0xFF3A5FA8), // Medium blue
                  Color(0xFF2D5295), // Deeper blue
                ],
              ),
            ),
          ),

          // Animated background shapes
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatController1,
              _floatController2,
              _floatController3,
            ]),
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: FloatingShapesPainter(
                  animation1: _floatController1.value,
                  animation2: _floatController2.value,
                  animation3: _floatController3.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 90), // Only bottom padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MAIN HEADER CARD - Edge-to-edge with curved bottom
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Left Profile Icon
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
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

                              // Center Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
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

                              // Right Notification Icon with Badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
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

                  // Stats Row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildGlassStatCard(
                            '${widget.userData?['currentStreak'] ?? 0}',
                            'Day Streak',
                            Icons.local_fire_department,
                            Color(0xFFFF9800),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildGlassStatCard(
                            '${widget.userData?['totalCheckIns'] ?? 0}',
                            'Check-ins',
                            Icons.check_circle,
                            Color(0xFF4CAF50),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildGlassStatCard(
                            '${widget.userData?['progressPercentage']?.toInt() ?? 0}%',
                            'Progress',
                            Icons.trending_up,
                            Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Today's Mood
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Today\'s Mood',
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
                    child: _buildGlassContainer(
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add a note about your day...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white60,
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

                  SizedBox(height: 20),

                  // Tools & Resources
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
                      childAspectRatio: 1.4,
                      children: [
                        _buildGlassToolCard(
                          'Breathing',
                          'Calm your mind',
                          Icons.air,
                          Color(0xFF2196F3),
                        ),
                        _buildGlassToolCard(
                          'Journal',
                          'Express yourself',
                          Icons.book_outlined,
                          Color(0xFF9C27B0),
                        ),
                        _buildGlassToolCard(
                          'Guidance',
                          'Get support',
                          Icons.psychology,
                          Color(0xFF00BCD4),
                        ),
                        _buildGlassToolCard(
                          'Insights',
                          'Track patterns',
                          Icons.insights,
                          Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // AI Chat Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGlassContainer(
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
                              color: Colors.white.withOpacity(0.2),
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
                                  'I\'m here to listen and support you',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassContainer({
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
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(
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

  Widget _buildMoodOption(String label, IconData icon, Color color) {
    final isSelected = _selectedMood == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = label;
        });
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

  Widget _buildGlassToolCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'Journal') {
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
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

  Widget _buildGlassBottomNav() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4569AD),
                    Color(0xFF4864B5),
                    Color(0xFF3A5FA8),
                    Color(0xFF2D5295),
                  ],
                ),
              ),
            ),
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
          // Navigate to CalmMe screen
          Navigator.pushNamed(context, '/calmme');
        } else if (index == 2) {
          // Navigate to Analytics screen (future)
          print('Navigate to Analytics');
        } else if (index == 3) {
          // Navigate to Profile screen (future)
          print('Navigate to Profile');
        }
        // If index == 0 (Home), we're already here, do nothing
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

class FloatingShapesPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;

  FloatingShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Color(0xFFB7C3E8).withOpacity(0.12);
    final offsetY1 = animation1 * 40 - 20;
    canvas.drawPath(
      Path()
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
        ..close(),
      paint,
    );

    paint.color = Color(0xFF081F44).withOpacity(0.18);
    final offsetX2 = animation2 * 35 - 17;
    canvas.drawPath(
      Path()
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
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(FloatingShapesPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3;
  }
}
