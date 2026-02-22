import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

// ══════════════════════════════════════════════════════════════
// CALMME SCREEN - Self-regulation & Calming Tools
// Features: Journal, Breathing, Resources, Music, Poetry, Games
// ══════════════════════════════════════════════════════════════

class CalmMeScreen extends StatefulWidget {
  const CalmMeScreen({Key? key}) : super(key: key);

  @override
  State<CalmMeScreen> createState() => _CalmMeScreenState();
}

class _CalmMeScreenState extends State<CalmMeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  int _currentNavIndex = 1; // CalmMe is index 1

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
    return Scaffold(
      body: Stack(
        children: [
          // Calming gradient background - Peaceful colors
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea), // Soft purple
                  Color(0xFF764ba2), // Deep purple
                  Color(0xFF8e44ad), // Rich purple
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
                  // EDGE-TO-EDGE HEADER
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
                              // Left Icon
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
                                  Icons.spa_outlined,
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
                                      'CalmMe',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Find your peace',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w400,
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

                  // JOURNAL ENTRY
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeatureCard(
                      title: 'Journal Entry',
                      subtitle: 'Express your thoughts and feelings',
                      icon: Icons.book_outlined,
                      color: Color(0xFF9C27B0),
                      onTap: () {
                        // Navigate to journal
                        print('Navigate to Journal');
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  // BREATHING EXERCISES
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeatureCard(
                      title: 'Breathing Exercises',
                      subtitle: 'Guided techniques to calm your mind',
                      icon: Icons.air,
                      color: Color(0xFF00BCD4),
                      onTap: () {
                        // Navigate to breathing
                        print('Navigate to Breathing');
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  // RESOURCES SECTION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Self-Help Resources',
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
                        _buildResourceCard(
                          'Anger Management',
                          Icons.emoji_emotions_outlined,
                          Color(0xFFFF5722),
                        ),
                        _buildResourceCard(
                          'Self Control',
                          Icons.self_improvement,
                          Color(0xFF3F51B5),
                        ),
                        _buildResourceCard(
                          'Stress Relief',
                          Icons.beach_access,
                          Color(0xFF009688),
                        ),
                        _buildResourceCard(
                          'Mindfulness',
                          Icons.psychology_outlined,
                          Color(0xFF673AB7),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // MUSIC SECTION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Calming Music',
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
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE91E63).withOpacity(0.3),
                          Color(0xFF9C27B0).withOpacity(0.3),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 32,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Music Library',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Play music, playlists & voice recordings',
                                      style: TextStyle(
                                        fontSize: 13,
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
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMusicActionButton(
                                  'Play Music',
                                  Icons.play_circle_outline,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildMusicActionButton(
                                  'Playlists',
                                  Icons.queue_music,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildMusicActionButton(
                                  'Record Voice',
                                  Icons.mic_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // POETRY SECTION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeatureCard(
                      title: 'Poetry Corner',
                      subtitle: 'Read calming poems and verses',
                      icon: Icons.auto_stories_outlined,
                      color: Color(0xFFFF9800),
                      onTap: () {
                        // Navigate to poetry
                        print('Navigate to Poetry');
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  // GAMES SECTION (Optional)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeatureCard(
                      title: 'Calming Games',
                      subtitle: 'Simple games to relax your mind',
                      icon: Icons.games_outlined,
                      color: Color(0xFF4CAF50),
                      badge: 'Optional',
                      onTap: () {
                        // Navigate to games
                        print('Navigate to Games');
                      },
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

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassContainer(
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        print('Navigate to: $title');
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
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 32),
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

  Widget _buildMusicActionButton(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        print('Music action: $label');
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                    Color(0xFF8e44ad),
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
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 0) {
          Navigator.pop(context); // Go back to home
        }
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

    paint.color = Color(0xFFD1C4E9).withOpacity(0.12);
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

    paint.color = Color(0xFF4A148C).withOpacity(0.15);
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
