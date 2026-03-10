import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

// ══════════════════════════════════════════════════════════════
// HOME SCREEN FOR AGES 13-15 - FRIENDLY & ENCOURAGING
// Unique content: Streak card, 4 moods, 4 activities
// ══════════════════════════════════════════════════════════════

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
          // Background gradient - BRIGHTER for young kids
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5782C9), // Soft blue
                  Color(0xFF597DD4), // Blue with gentle purple hint
                  Color(0xFF4569AD), // Medium blue
                  Color(0xFF3A5FA8), // Deeper blue
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
              padding: EdgeInsets.only(bottom: 90),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EDGE-TO-EDGE WELCOME HEADER - Same across all ages
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

                  // UNIQUE CONTENT FOR YOUNG (13-15) STARTS HERE

                  // Daily Streak Card - BIG & ENCOURAGING
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGlassContainer(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFF6B35), // Red-orange
                                  Color(0xFFFF9800), // Bright orange
                                  Color(0xFFFFD54F), // Yellow
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
                                  '${widget.userData?['currentStreak'] ?? 0} Day Streak!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.userData?['currentStreak'] != null &&
                                          widget.userData!['currentStreak'] > 0
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

                  // How are you feeling today? - 4 BIG MOODS
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

                  SizedBox(height: 32),

                  // Quick Activities - 4 CARDS
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
                      childAspectRatio: 1.1,
                      children: [
                        _buildActivityCard(
                          'Daily Check-in',
                          Icons.check_circle_outline,
                          Color(0xFF4CAF50),
                        ),
                        _buildActivityCard(
                          'Breathing',
                          Icons.air,
                          Color(0xFF2196F3),
                        ),
                        _buildActivityCard(
                          'Journal',
                          Icons.book_outlined,
                          Color(0xFF9C27B0),
                        ),
                        _buildActivityCard(
                          'Progress',
                          Icons.trending_up,
                          Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Support Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGlassContainer(
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

                  SizedBox(height: 20),
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
      borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
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

  Widget _buildMoodButton(String label, IconData icon, Color color) {
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
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
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

  Widget _buildActivityCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        if (title == 'Journal') {
          Navigator.pushNamed(context, '/journal');
        } else {
          print('Navigate to: $title');
        }
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
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
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
                    Color(0xFF5782C9),
                    Color(0xFF597DD4),
                    Color(0xFF4569AD),
                    Color(0xFF3A5FA8),
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
          Navigator.pushNamed(context, '/calmme');
        } else if (index == 2) {
          print('Navigate to Analytics');
        } else if (index == 3) {
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
