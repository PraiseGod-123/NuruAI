import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../utils/nuru_colors.dart';

class MicroExpressionSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const MicroExpressionSetupScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<MicroExpressionSetupScreen> createState() =>
      _MicroExpressionSetupScreenState();
}

class _MicroExpressionSetupScreenState
    extends State<MicroExpressionSetupScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  int _recordingProgress = 0;
  Timer? _progressTimer;

  final List<ExpressionPrompt> _prompts = [
    ExpressionPrompt(
      title: 'Relax & Look Natural',
      instruction: 'Just look at the camera and relax your face',
      emoji: '😌',
      duration: 3,
      color: NuruColors.sailingBlue,
    ),
    ExpressionPrompt(
      title: 'Think Happy Thoughts',
      instruction: 'Think of something that makes you smile',
      emoji: '😊',
      duration: 3,
      color: NuruColors.solidBlue,
    ),
    ExpressionPrompt(
      title: 'Remember a Tough Day',
      instruction: 'Think about a time you felt down',
      emoji: '😔',
      duration: 3,
      color: NuruColors.dive,
    ),
    ExpressionPrompt(
      title: 'Imagine Stress',
      instruction: 'Picture yourself in a crowded, noisy place',
      emoji: '😰',
      duration: 3,
      color: NuruColors.deepSea,
    ),
  ];

  int _currentPromptIndex = 0;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    // Delay camera init to after first frame so permission dialog renders properly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    // Check permission status first, only request if not already granted
    PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted) {
      if (mounted) {
        _showError(
          'Camera permission is required. Please enable it in your device Settings > Apps > NuruAI > Permissions.',
        );
      }
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
        if (mounted) _showError('No camera found on this device.');
      }
    } catch (e) {
      _showError('Failed to initialize camera. Please try again.');
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NuruColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _showInstructions = false;
      _isRecording = true;
      _recordingProgress = 0;
    });

    // Simulate recording with progress
    final duration = _prompts[_currentPromptIndex].duration;
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _recordingProgress += 100;
      });

      if (_recordingProgress >= duration * 1000) {
        timer.cancel();
        _completeRecording();
      }
    });

    // TODO: Actual video recording implementation
    // await _cameraController!.startVideoRecording();
  }

  Future<void> _completeRecording() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    // TODO: Stop recording and process
    // final video = await _cameraController!.stopVideoRecording();

    // Simulate processing delay
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isProcessing = false;
    });

    // Move to next prompt or finish
    if (_currentPromptIndex < _prompts.length - 1) {
      setState(() {
        _currentPromptIndex++;
        _showInstructions = true;
        _recordingProgress = 0;
      });
    } else {
      _completeSetup();
    }
  }

  void _completeSetup() {
    // Show success message
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
              'Baseline Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NuruColors.dive,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your micro-expression baseline has been captured successfully',
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
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                  context,
                  '/home',
                  arguments: widget.userData,
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
                'Continue to Home',
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
          'Skip Baseline Setup?',
          style: TextStyle(color: NuruColors.dive),
        ),
        content: Text(
          'Capturing your baseline helps NuruAI understand your unique expressions and provide better support. Are you sure you want to skip?',
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
                '/home',
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
    final currentPrompt = _prompts[_currentPromptIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [NuruColors.nightTime.withOpacity(0.8), NuruColors.dive],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Baseline Setup',
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
                          color: NuruColors.lilacBlue,
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
                    _prompts.length,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPromptIndex
                              ? NuruColors.sailingBlue
                              : NuruColors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Current Prompt Info
              if (_showInstructions) ...[
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
                          currentPrompt.emoji,
                          style: TextStyle(fontSize: 60),
                        ),
                        SizedBox(height: 16),
                        Text(
                          currentPrompt.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: NuruColors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          currentPrompt.instruction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: NuruColors.lilacBlue,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Camera Preview
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: currentPrompt.color.withOpacity(0.3),
                        blurRadius: 30,
                        offset: Offset(0, 15),
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

                              // Face oval guide
                              Center(
                                child: Container(
                                  width: 280,
                                  height: 350,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isRecording
                                          ? NuruColors.success
                                          : NuruColors.white.withOpacity(0.5),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),

                              // Recording overlay
                              if (_isRecording || _isProcessing)
                                Container(
                                  color: Colors.black.withOpacity(0.3),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_isRecording) ...[
                                          Text(
                                            currentPrompt.emoji,
                                            style: TextStyle(fontSize: 80),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            currentPrompt.instruction,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: NuruColors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 30),
                                          // Progress bar
                                          Container(
                                            width: 200,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: NuruColors.white
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor:
                                                  _recordingProgress /
                                                  (currentPrompt.duration *
                                                      1000),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      NuruColors.sailingBlue,
                                                      NuruColors.success,
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else if (_isProcessing) ...[
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  NuruColors.sailingBlue,
                                                ),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            'Processing...',
                                            style: TextStyle(
                                              color: NuruColors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
                                        decoration: TextDecoration.underline,
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
              if (_showInstructions && !_isRecording && !_isProcessing)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: NuruColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: NuruColors.buttonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _isCameraInitialized ? _startRecording : null,
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
                            Icons.play_circle_filled,
                            color: NuruColors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Start Recording (${currentPrompt.duration}s)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: NuruColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Progress chips
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _prompts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final prompt = entry.value;
                    final isCompleted = index < _currentPromptIndex;
                    final isCurrent = index == _currentPromptIndex;

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? NuruColors.success
                            : isCurrent
                            ? NuruColors.sailingBlue
                            : NuruColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: isCurrent
                            ? Border.all(color: NuruColors.white, width: 2)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(prompt.emoji, style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          if (isCompleted)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: NuruColors.white,
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
      ),
    );
  }
}

class ExpressionPrompt {
  final String title;
  final String instruction;
  final String emoji;
  final int duration;
  final Color color;

  ExpressionPrompt({
    required this.title,
    required this.instruction,
    required this.emoji,
    required this.duration,
    required this.color,
  });
}
