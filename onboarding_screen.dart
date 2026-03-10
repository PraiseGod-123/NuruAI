import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'Welcome to NuruAI',
      subtitle: 'AI-Powered Autism Care',
      description:
          'Your personal companion for understanding and supporting your journey',
      imagePath: 'assets/images/pic 1.jpg',
      gradientColors: [
        Color(0xFF7B9FD8),
        Color(0xFF5782C9),
      ], // Lighter blue gradient
    ),
    OnboardingContent(
      title: 'Track Your Emotions',
      subtitle: 'Micro-Expression Analysis',
      description:
          'Advanced AI technology that understands your unique expressions and mood patterns',
      imagePath: 'assets/images/pic 2.jpg',
      gradientColors: [Color(0xFF8EA2D7), Color(0xFF4569AD)],
    ),
    OnboardingContent(
      title: 'Get Personalized Support',
      subtitle: 'Real-Time Assistance',
      description:
          'Receive tailored coping strategies and therapeutic feedback when you need it most',
      imagePath: 'assets/images/pic 3.jpg',
      gradientColors: [Color(0xFF4569AD), Color(0xFF14366D)],
    ),
    OnboardingContent(
      title: 'Your Safe Space',
      subtitle: 'Private & Secure',
      description:
          'Complete privacy guaranteed. Your data stays on your device, always under your control',
      imagePath: 'assets/images/pic 4.jpg',
      gradientColors: [
        Color(0xFF3A5FA8),
        Color(0xFF1E4A8C),
      ], // Deeper rich blue gradient
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize PageController after getting the initialPage from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final initialPage = args?['initialPage'] ?? 0;

      setState(() {
        _currentPage = initialPage;
      });

      // Jump to the initial page without animation
      if (_pageController.hasClients && initialPage > 0) {
        _pageController.jumpToPage(initialPage);
      }
    });

    // Initialize PageController with initialPage
    _pageController = PageController(
      initialPage: 0, // Will be updated in postFrameCallback
    );

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
    _pageController.dispose();
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToAgeVerification() {
    Navigator.pushReplacementNamed(context, '/age-verification');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAgeVerification();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pages[_currentPage].gradientColors,
              ),
            ),
          ),

          // Animated 3D flowing shapes - changes design per page
          AnimatedBuilder(
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
                  currentPage:
                      _currentPage, // Pass current page for different designs
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: _navigateToAgeVerification,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(content: _pages[index]);
                    },
                  ),
                ),

                // Dots Indicator
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        width: _currentPage == index ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation Buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Row(
                    children: [
                      // Previous Button - Only show if not on first page
                      if (_currentPage > 0)
                        Expanded(
                          child: Container(
                            height: 60,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ElevatedButton(
                              onPressed: _previousPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Icon(Icons.arrow_back, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Previous',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Next/Get Started Button
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  _pages[_currentPage].gradientColors[0],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_currentPage != _pages.length - 1) ...[
                                  SizedBox(width: 8),
                                  //Icon(Icons.arrow_forward, size: 20),
                                ],
                              ],
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
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Image with beautiful blending - FIXED SIZE
          Container(
            height: 280,
            width: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow behind image
                Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Image container with CIRCULAR shape
                ClipOval(
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.3),
                          ],
                          stops: [0.0, 0.5, 0.8, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        content.imagePath,
                        height: 280,
                        width: 280,
                        fit: BoxFit.cover,
                        color: Colors.white.withOpacity(0.95),
                        colorBlendMode: BlendMode.modulate,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image not found: ${content.imagePath}');
                          return Container(
                            height: 280,
                            width: 280,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Image not found',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          // Title
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Subtitle
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(height: 24),

          // Description in glass card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
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
                child: Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final List<Color> gradientColors;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.gradientColors,
  });
}

// Animated 3D Shapes Painter with position changes per page
class Animated3DShapesPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final int currentPage;

  Animated3DShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.currentPage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Get position multipliers based on current page
    final positions = _getPositionsForPage(currentPage);

    // Large flowing shape - top left (position changes per page)
    paint.color = Color(0xFFB7C3E8).withOpacity(0.25);
    final offsetY1 = animation1 * 40 - 20;
    final path1 = Path()
      ..moveTo(0, offsetY1 + positions['topShape']!)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.1 + offsetY1 + positions['topShape']!,
        size.width * 0.4,
        size.height * 0.25 + offsetY1 + positions['topShape']!,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.4 + offsetY1 + positions['topShape']!,
        size.width * 0.3,
        size.height * 0.5 + offsetY1 + positions['topShape']!,
      )
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.6 + offsetY1 + positions['topShape']!,
        0,
        size.height * 0.4 + offsetY1 + positions['topShape']!,
      )
      ..close();
    canvas.drawPath(path1, paint);

    // Right side shape (position changes per page)
    paint.color = Color(0xFF081F44).withOpacity(0.2);
    final offsetX2 = animation2 * 35 - 17;
    final path2 = Path()
      ..moveTo(
        size.width,
        size.height * 0.2 + offsetX2 + positions['rightShape']!,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.3 + offsetX2 + positions['rightShape']!,
        size.width * 0.6,
        size.height * 0.5 + offsetX2 + positions['rightShape']!,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.7 + offsetX2 + positions['rightShape']!,
        size.width * 0.7,
        size.height * 0.8 + offsetX2 + positions['rightShape']!,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.9 + offsetX2 + positions['rightShape']!,
        size.width,
        size.height * 0.7 + offsetX2 + positions['rightShape']!,
      )
      ..close();
    canvas.drawPath(path2, paint);

    // Floating sphere 1 (position changes per page)
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
                size.width * positions['sphere1X']! + (animation1 * 25 - 12),
                size.height * positions['sphere1Y']! + (animation2 * 20 - 10),
              ),
              radius: 90,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * positions['sphere1X']! + (animation1 * 25 - 12),
        size.height * positions['sphere1Y']! + (animation2 * 20 - 10),
      ),
      90,
      spherePaint1,
    );

    // Floating sphere 2 (position changes per page)
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
                size.width * positions['sphere2X']! + (animation3 * 30 - 15),
                size.height * positions['sphere2Y']! + (animation1 * 20 - 10),
              ),
              radius: 110,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * positions['sphere2X']! + (animation3 * 30 - 15),
        size.height * positions['sphere2Y']! + (animation1 * 20 - 10),
      ),
      110,
      spherePaint2,
    );
  }

  // Define different positions for each page
  Map<String, double> _getPositionsForPage(int page) {
    switch (page) {
      case 0: // Page 1 - Original positions
        return {
          'topShape': 0.0,
          'rightShape': 0.0,
          'sphere1X': 0.75,
          'sphere1Y': 0.15,
          'sphere2X': 0.3,
          'sphere2Y': 0.85,
        };

      case 1: // Page 2 - Shifted positions
        return {
          'topShape': 80.0, // Move down
          'rightShape': -60.0, // Move up
          'sphere1X': 0.25, // Move to left
          'sphere1Y': 0.45, // Move down
          'sphere2X': 0.7, // Move to right
          'sphere2Y': 0.6, // Move up
        };

      case 2: // Page 3 - Different positions
        return {
          'topShape': -40.0, // Move up
          'rightShape': 100.0, // Move down
          'sphere1X': 0.6, // Center-right
          'sphere1Y': 0.75, // Lower position
          'sphere2X': 0.15, // Far left
          'sphere2Y': 0.3, // Upper position
        };

      case 3: // Page 4 - Final positions
        return {
          'topShape': 120.0, // Move way down
          'rightShape': -90.0, // Move way up
          'sphere1X': 0.4, // Center
          'sphere1Y': 0.25, // Upper-center
          'sphere2X': 0.8, // Far right
          'sphere2Y': 0.7, // Lower-right
        };

      default:
        return {
          'topShape': 0.0,
          'rightShape': 0.0,
          'sphere1X': 0.75,
          'sphere1Y': 0.15,
          'sphere2X': 0.3,
          'sphere2Y': 0.85,
        };
    }
  }

  @override
  bool shouldRepaint(Animated3DShapesPainter oldDelegate) {
    return oldDelegate.currentPage != currentPage ||
        oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3;
  }
}
