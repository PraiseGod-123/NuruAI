import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../utils/nuru_colors.dart';

class FacialRecognitionSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const FacialRecognitionSetupScreen({Key? key, this.userData})
    : super(key: key);

  @override
  State<FacialRecognitionSetupScreen> createState() =>
      _FacialRecognitionSetupScreenState();
}

class _FacialRecognitionSetupScreenState
    extends State<FacialRecognitionSetupScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _captureStep = 0; // 0: front, 1: left angle, 2: right angle
  List<String> _capturedAngles = [];
  bool _isCapturing = false;

  late AnimationController _floatController1;
  late AnimationController _floatController2;

  final List<AngleCapture> _angles = [
    AngleCapture(
      title: 'Look Straight Ahead',
      instruction:
          'Position your face in the center and look directly at the camera',
      icon: Icons.face,
      emoji: '👤',
    ),
    AngleCapture(
      title: 'Turn Slightly Left',
      instruction:
          'Turn your head slightly to the left while keeping your eyes on the camera',
      icon: Icons.arrow_back,
      emoji: '↖️',
    ),
    AngleCapture(
      title: 'Turn Slightly Right',
      instruction:
          'Turn your head slightly to the right while keeping your eyes on the camera',
      icon: Icons.arrow_forward,
      emoji: '↗️',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay camera init so permission dialog renders properly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });

    _floatController1 = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatController2 = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Prevent re-entry if already initialized
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized)
      return;

    // Request camera permission first
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showError(
        'Camera permission is required for Face ID setup. Please allow camera access in your device settings.',
      );
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        _showError('No camera found on this device.');
      }
    } catch (e) {
      _showError('Failed to initialize camera. Please try again.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _floatController1.dispose();
    _floatController2.dispose();
    super.dispose();
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

  Future<void> _captureAngle() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _cameraController!.takePicture();

      setState(() {
        _capturedAngles.add(image.path);
        _isCapturing = false;
      });

      _showCaptureSuccess();

      await Future.delayed(Duration(milliseconds: 500));

      if (_captureStep < _angles.length - 1) {
        setState(() {
          _captureStep++;
        });
      } else {
        _completeSetup();
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showError('Failed to capture image. Please try again.');
    }
  }

  void _showCaptureSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Captured! Moving to next angle...'),
          ],
        ),
        backgroundColor: NuruColors.success,
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _completeSetup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: NuruColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: NuruColors.white, size: 50),
            ),
            SizedBox(height: 20),
            Text(
              'Face ID Setup Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NuruColors.dive,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You can now use facial recognition to login quickly and securely',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: NuruColors.deepSea,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: NuruColors.primaryGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () {
                // Dispose camera before navigating
                _cameraController?.dispose();
                // Now go to baseline setup for micro-expressions
                Navigator.pushReplacementNamed(
                  context,
                  '/micro-expression-setup',
                  arguments: {
                    ...?widget.userData,
                    'faceIdAngles': _capturedAngles,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Continue to Baseline Setup',
                style: TextStyle(
                  color: NuruColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _skipSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Skip Face ID Setup?',
          style: TextStyle(color: NuruColors.dive),
        ),
        content: Text(
          'Face ID allows you to login quickly and securely, just like on your smartphone. Are you sure you want to skip?',
          style: TextStyle(color: NuruColors.deepSea, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: NuruColors.darkGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                '/micro-expression-setup',
                arguments: widget.userData,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NuruColors.sailingBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Skip Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAngle = _angles[_captureStep];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [NuruColors.sailingBlue, NuruColors.dive],
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: Listenable.merge([
                _floatController1,
                _floatController2,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SimpleBackgroundPainter(
                    animation1: _floatController1.value,
                    animation2: _floatController2.value,
                  ),
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Face ID Setup',
                          style: TextStyle(
                            color: NuruColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _skipSetup,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: NuruColors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress Indicator
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(
                        _angles.length,
                        (index) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index <= _captureStep
                                  ? NuruColors.white
                                  : NuruColors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Instruction Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: NuruColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: NuruColors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentAngle.emoji,
                            style: TextStyle(fontSize: 48),
                          ),
                          SizedBox(height: 12),
                          Text(
                            currentAngle.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: NuruColors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            currentAngle.instruction,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: NuruColors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Camera Preview
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _isCameraInitialized
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreview(_cameraController!),

                                  // Face guide overlay
                                  Center(
                                    child: Container(
                                      width: 250,
                                      height: 320,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isCapturing
                                              ? NuruColors.success
                                              : NuruColors.white.withOpacity(
                                                  0.6,
                                                ),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Capture feedback
                                  if (_isCapturing)
                                    Container(
                                      color: Colors.white.withOpacity(0.3),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                NuruColors.white,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Container(
                                color: NuruColors.dive,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              NuruColors.sailingBlue,
                                            ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Opening camera...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      TextButton(
                                        onPressed: _initializeCamera,
                                        child: Text(
                                          'Tap to retry',
                                          style: TextStyle(
                                            color: NuruColors.lilacBlue,
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Capture Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NuruColors.white,
                            NuruColors.white.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isCameraInitialized && !_isCapturing
                            ? _captureAngle
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: NuruColors.sailingBlue,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Capture Face',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: NuruColors.sailingBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Progress chips
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _angles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final angle = entry.value;
                        final isCaptured = index < _captureStep;
                        final isCurrent = index == _captureStep;

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCaptured
                                ? NuruColors.success
                                : isCurrent
                                ? NuruColors.white
                                : NuruColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: isCurrent
                                ? Border.all(color: NuruColors.white, width: 2)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCaptured)
                                Icon(
                                  Icons.check,
                                  size: 14,
                                  color: NuruColors.white,
                                )
                              else
                                Icon(
                                  angle.icon,
                                  size: 14,
                                  color: isCurrent
                                      ? NuruColors.sailingBlue
                                      : NuruColors.white.withOpacity(0.7),
                                ),
                              SizedBox(width: 4),
                              Text(
                                angle.title.split(' ').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCaptured || isCurrent
                                      ? (isCaptured
                                            ? NuruColors.white
                                            : NuruColors.sailingBlue)
                                      : NuruColors.white.withOpacity(0.7),
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AngleCapture {
  final String title;
  final String instruction;
  final IconData icon;
  final String emoji;

  AngleCapture({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.emoji,
  });
}

// Simple background painter
class SimpleBackgroundPainter extends CustomPainter {
  final double animation1;
  final double animation2;

  SimpleBackgroundPainter({required this.animation1, required this.animation2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final offset1 = animation1 * 40 - 20;
    paint.color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + offset1,
        size.height * 0.15 + (animation2 * 30 - 15),
      ),
      120,
      paint,
    );

    final offset2 = animation2 * 50 - 25;
    paint.color = Color(0xFF081F44).withOpacity(0.15);
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + (animation1 * 25 - 12),
        size.height * 0.75 + offset2,
      ),
      100,
      paint,
    );

    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + (animation2 * 30 - 15),
        size.height * 0.45 + (animation1 * 35 - 17),
      ),
      80,
      paint,
    );
  }

  @override
  bool shouldRepaint(SimpleBackgroundPainter oldDelegate) => true;
}
