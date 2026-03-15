import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isUnlocking = false;
  bool _isUnlocked = false;

  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;
  late AnimationController _unlockController;

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

    _unlockController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _unlockController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // TODO: Implement actual login logic
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'email': _emailController.text},
    );
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

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password'),
        content: Text('Password reset functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleFacialRecognitionLogin() async {
    setState(() {
      _isUnlocking = true;
    });

    // Start unlock animation
    await _unlockController.forward();

    // Simulate facial recognition process
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isUnlocked = true;
    });

    // Wait a moment to show unlocked state
    await Future.delayed(Duration(milliseconds: 800));

    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4569AD),
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
                child: Container(
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacer(flex: 2),

                        // Welcome Back Title
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: 12),

                        Text(
                          'Sign in to continue your journey',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.3,
                          ),
                        ),

                        SizedBox(height: 60),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 24),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Color(0xFF4569AD),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF4569AD),
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Apple-style Padlock Unlock
                        Center(
                          child: GestureDetector(
                            onTap: _isUnlocking
                                ? null
                                : _handleFacialRecognitionLogin,
                            child: AnimatedBuilder(
                              animation: _unlockController,
                              builder: (context, child) {
                                return Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: _isUnlocked
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isUnlocked
                                              ? Colors.green
                                              : Colors.white.withOpacity(0.4),
                                          width: 2,
                                        ),
                                        boxShadow: _isUnlocked
                                            ? [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.4),
                                                  blurRadius: 20,
                                                  spreadRadius: 5,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          _unlockController.value * -8,
                                        ),
                                        child: Transform.rotate(
                                          angle: _unlockController.value * 0.3,
                                          child: Icon(
                                            _isUnlocked
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_rounded,
                                            color: _isUnlocked
                                                ? Colors.green
                                                : Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _isUnlocking
                                          ? 'Unlocking...'
                                          : _isUnlocked
                                          ? 'Unlocked!'
                                          : 'Tap to unlock with Face ID',
                                      style: TextStyle(
                                        color: _isUnlocked
                                            ? Colors.green
                                            : Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        Spacer(flex: 3),

                        // Divider with "OR"
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Sign Up Link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                                children: [
                                  TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      fontSize: 17,
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F3F74),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                    prefixIcon: Icon(icon, color: Color(0xFF4569AD), size: 22),
                    suffixIcon: suffixIcon,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    errorStyle: TextStyle(color: Colors.red[300], fontSize: 12),
                  ),
                  validator: validator,
                ),
              ),
            ),
          ),
        ),
      ],
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
