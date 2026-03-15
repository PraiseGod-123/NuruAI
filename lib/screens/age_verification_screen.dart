import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../utils/nuru_colors.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({Key? key}) : super(key: key);

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

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
    _dateController.dispose();
    super.dispose();
  }

  int? _calculateAge() {
    if (_selectedDate == null) return null;

    final today = DateTime.now();
    int age = today.year - _selectedDate!.year;

    if (today.month < _selectedDate!.month ||
        (today.month == _selectedDate!.month &&
            today.day < _selectedDate!.day)) {
      age--;
    }

    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1924),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4569AD),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMMM dd, yyyy').format(picked);
      });
    }
  }

  void _handleContinue() {
    if (_selectedDate == null) {
      _showError('Please select your birthday');
      return;
    }

    final age = _calculateAge();

    if (age == null) {
      _showError('Please enter a valid date');
      return;
    }

    if (age < 13) {
      _showAgeRestrictionDialog();
      return;
    }

    if (age > 100) {
      _showError('Please enter a valid age');
      return;
    }

    Navigator.pushReplacementNamed(context, '/signup', arguments: {'age': age});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NuruColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAgeRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Age Requirement'),
        content: Text(
          'NuruAI is designed for users aged 13-25. Please consult with a parent or guardian for appropriate resources.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4569AD), // Match gradient background
      body: Stack(
        children: [
          // FIXED BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4569AD), Color(0xFF14366D)],
              ),
            ),
          ),

          // Stars layer
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

          // 3D shapes
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

          // CONTENT
          SafeArea(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification overscroll) {
                overscroll.disallowIndicator();
                return true;
              },
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _handleBack,
                      ),
                    ),

                    SizedBox(height: 60),

                    // Birthday Cake Lottie
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        child: Lottie.asset(
                          'assets/animations/birthday celebration.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF6B9D).withOpacity(0.3),
                                    Color(0xFFC239B3).withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(35),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🎂', style: TextStyle(fontSize: 80)),
                                  SizedBox(height: 10),
                                  Text(
                                    '🎈 🎈 🎈',
                                    style: TextStyle(fontSize: 35),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Title
                    Text(
                      'Enter Your Birthday',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'NuruAI is for ages 13-25',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Date Picker
                    Text(
                      'Select Your Birthday',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 16),

                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _dateController,
                                enabled: false,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF4569AD),
                                  ),
                                  suffixIcon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF4569AD),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  hintText: 'Tap to select your birthday',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F3F74),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Info card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Your age helps us personalize your experience and ensure appropriate content',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 60),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF4569AD),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stars Painter
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

// Animated 3D Shapes Painter
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
