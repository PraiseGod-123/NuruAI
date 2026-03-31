import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/nuru_colors.dart';
import '../services/api_services.dart';
import '../services/firebase_service.dart';

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
  bool _isLoading = false;

  // Camera for facial recognition
  CameraController? _cameraController;
  bool _isCameraReady = false;

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
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await NuruFirebaseService.instance.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final userData = result.userData ?? {};
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {
          ...userData,
          'uid': result.uid,
          'email': _emailController.text.trim(),
        },
      );
    } else {
      _showError(result.error ?? 'Login failed. Please try again.');
    }
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
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F3F74),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email and we will send you a reset link.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'your@email.com',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (emailController.text.trim().isEmpty) return;
              final result = await NuruFirebaseService.instance
                  .sendPasswordReset(emailController.text.trim());
              if (!mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password reset email sent! Check your inbox.',
                    ),
                    backgroundColor: Color(0xFF4CAF50),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                _showError(result.error ?? 'Could not send reset email.');
              }
            },
            child: const Text(
              'Send Reset Link',
              style: TextStyle(
                color: Color(0xFF4569AD),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Facial recognition login ──────────────────────────────────────────────

  Future<void> _handleFacialRecognitionLogin() async {
    // Step 1 — check camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showError('Camera permission is needed for Face ID login.');
      return;
    }

    setState(() => _isUnlocking = true);
    await _unlockController.forward();

    // Step 2 — initialise front camera
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      setState(() => _isUnlocking = false);
      _unlockController.reset();
      _showError('Could not access camera. Please try again.');
      return;
    }

    // Step 3 — show camera preview sheet for the user to look at the camera
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFaceLoginSheet(),
    );

    if (confirmed != true) {
      // User dismissed without capturing
      setState(() {
        _isUnlocking = false;
        _isCameraReady = false;
      });
      _unlockController.reset();
      _cameraController?.dispose();
      _cameraController = null;
      return;
    }
  }

  Widget _buildFaceLoginSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: NuruColors.nightBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Look at the camera',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Position your face in the circle',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isCameraReady)
                      CameraPreview(_cameraController!)
                    else
                      Container(color: NuruColors.nightCard),
                    Center(
                      child: Container(
                        width: 220,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white60, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _captureAndAuthenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NuruColors.sailingBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Scan My Face',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _captureAndAuthenticate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    Navigator.pop(context, true); // close the sheet

    try {
      // Capture frame
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final imageBase64 = base64Encode(bytes);

      // Get user ID — use email as fallback until Firebase is wired
      final userId = _emailController.text.isNotEmpty
          ? _emailController.text
          : 'user_unknown';

      // Call the API
      final result = await NuruApiService.instance.login(
        userId: userId,
        imageBase64: imageBase64,
      );

      _cameraController?.dispose();
      _cameraController = null;

      if (!mounted) return;

      if (result.authenticated) {
        // Login successful
        setState(() => _isUnlocked = true);
        await Future.delayed(Duration(milliseconds: 800));

        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'email': userId,
            'emotion': result.emotionResult?.emotion ?? 'neutral',
            'supportTool': result.emotionResult?.supportTool,
            'supportMessage': result.emotionResult?.supportMessage,
          },
        );
      } else {
        // Not authenticated
        setState(() {
          _isUnlocking = false;
          _isUnlocked = false;
        });
        _unlockController.reset();
        _showError(
          result.message.isNotEmpty
              ? result.message
              : 'Face not recognised. Please try again or use email.',
        );
      }
    } catch (e) {
      _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _isUnlocking = false;
        _isUnlocked = false;
      });
      _unlockController.reset();
      _showError('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4569AD),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4569AD), Color(0xFF14366D)],
              ),
            ),
          ),

          IgnorePointer(
            child: AnimatedBuilder(
              animation: _floatController1,
              builder: (context, child) => CustomPaint(
                size: Size.infinite,
                painter: SubtleStarsPainter(twinkle: _floatController1.value),
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
              builder: (context, child) => CustomPaint(
                size: Size.infinite,
                painter: Animated3DShapesPainter(
                  animation1: _floatController1.value,
                  animation2: _floatController2.value,
                  animation3: _floatController3.value,
                ),
              ),
            ),
          ),

          SafeArea(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (n) {
                n.disallowIndicator();
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

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter your email';
                            if (!value.contains('@'))
                              return 'Please enter a valid email';
                            return null;
                          },
                        ),

                        SizedBox(height: 24),

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
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter your password';
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

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

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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

                        // Face ID unlock button
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
                                          ? 'Scanning...'
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

                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/signup',
                            ),
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

// ── Painters (unchanged) ──────────────────────────────────────────────────────

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
      final op = 0.4 + (twinkle * 0.3);
      paint.color = Colors.white.withOpacity(op * 0.4);
      canvas.drawCircle(Offset(x, y), 3.5, paint);
      paint.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 2.0, paint);
      paint.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(SubtleStarsPainter old) => old.twinkle != twinkle;
}

class Animated3DShapesPainter extends CustomPainter {
  final double animation1, animation2, animation3;
  Animated3DShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Color(0xFFB7C3E8).withOpacity(0.25);
    final oy1 = animation1 * 40 - 20;
    final path1 = Path()
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
      ..close();
    canvas.drawPath(path1, paint);

    paint.color = Color(0xFF081F44).withOpacity(0.2);
    final ox2 = animation2 * 35 - 17;
    final path2 = Path()
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
      ..close();
    canvas.drawPath(path2, paint);

    canvas.drawCircle(
      Offset(
        size.width * 0.75 + (animation1 * 25 - 12),
        size.height * 0.15 + (animation2 * 20 - 10),
      ),
      90,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.75, size.height * 0.15),
                radius: 90,
              ),
            ),
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.3 + (animation3 * 30 - 15),
        size.height * 0.85 + (animation1 * 20 - 10),
      ),
      110,
      Paint()
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
                center: Offset(size.width * 0.3, size.height * 0.85),
                radius: 110,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(Animated3DShapesPainter o) =>
      o.animation1 != animation1 ||
      o.animation2 != animation2 ||
      o.animation3 != animation3;
}
