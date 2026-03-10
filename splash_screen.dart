import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _convergeController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  late Animation<double> _drawAnimation;
  late Animation<double> _convergeAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Phase 1: Draw neurons (8 seconds - good pace)
    _drawController = AnimationController(
      duration: Duration(milliseconds: 8000),
      vsync: this,
    );
    _drawAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _drawController, curve: Curves.easeInOut),
    );

    // Phase 2: Converge into brain (3 seconds)
    _convergeController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    _convergeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _convergeController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Phase 3: Text appears
    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Pulse animation for brain
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Floating background shape controllers
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

    // Start sequence
    _drawController.forward();

    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(Duration(milliseconds: 800), () {
          _convergeController.forward();
        });
      }
    });

    _convergeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
        Timer(Duration(milliseconds: 300), () {
          _textController.forward();
        });
      }
    });

    //Navigate - COMMENTED OUT FOR DEVELOPMENT
    Timer(Duration(seconds: 14), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _convergeController.dispose();
    _textController.dispose();
    _pulseController.dispose();
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
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4569AD), Color(0xFF14366D)],
              ),
            ),
          ),

          // Animated flowing background shapes (like onboarding)
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatController1,
              _floatController2,
              _floatController3,
            ]),
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: SplashBackgroundShapesPainter(
                  animation1: _floatController1.value,
                  animation2: _floatController2.value,
                  animation3: _floatController3.value,
                ),
              );
            },
          ),

          // Animated neurons
          AnimatedBuilder(
            animation: Listenable.merge([
              _drawAnimation,
              _convergeAnimation,
              _pulseController,
            ]),
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: NeuronBrainPainter(
                  drawProgress: _drawAnimation.value,
                  convergeProgress: _convergeAnimation.value,
                  pulseProgress: _pulseController.value,
                ),
              );
            },
          ),

          // Text (centered below brain)
          SafeArea(
            child: AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                final opacity = _textAnimation.value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Column(
                    children: [
                      Spacer(flex: 5),

                      // NuruAI - CENTERED (MORE CURSIVE)
                      Transform.translate(
                        offset: Offset(0, 30 * (1 - opacity)),
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(
                              0.08,
                            ), // Y-axis rotation for cursive slant
                          alignment: Alignment.center,
                          child: Center(
                            child: Text(
                              'NuruAI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'serif',
                                color: Colors.white,
                                letterSpacing: -0.5, // Tighter for cursive
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(0, 4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8), // Reduced from 12
                      // Autism Care - CENTERED
                      Center(
                        child: Text(
                          'Autism Care',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27, // Increased from 16
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      Spacer(flex: 2),

                      // Powered by AI
                      Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Center(
                          child: Text(
                            'Powered by AI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.6),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// NEURON BRAIN PAINTER - DETAILED ANATOMICAL BRAIN
// ══════════════════════════════════════════════════════════════
class NeuronBrainPainter extends CustomPainter {
  final double drawProgress;
  final double convergeProgress;
  final double pulseProgress;

  NeuronBrainPainter({
    required this.drawProgress,
    required this.convergeProgress,
    required this.pulseProgress,
  });

  // Well-distributed neurons across entire screen - no clustering
  static final _scatteredPositions = _generateScatteredPositions();

  static List<List<double>> _generateScatteredPositions() {
    final positions = <List<double>>[];

    // Create a grid-based distribution with randomness to avoid clustering
    // 9 rows x 6-7 columns = ~57 neurons spread evenly

    final rows = 9;
    final cols = 7;
    final random = math.Random(42);

    for (int row = 0; row < rows; row++) {
      final numInRow = (row % 2 == 0)
          ? cols
          : cols - 1; // Alternate row density

      for (int col = 0; col < numInRow; col++) {
        // Calculate base position
        final baseX = (col + 0.5) / cols;
        final baseY = (row + 0.5) / rows;

        // Add randomness (±10%) to avoid perfect grid look
        final randomX = (random.nextDouble() - 0.5) * 0.15;
        final randomY = (random.nextDouble() - 0.5) * 0.15;

        final x = (baseX + randomX).clamp(0.03, 0.97);
        final y = (baseY + randomY).clamp(0.03, 0.97);

        positions.add([x, y]);

        if (positions.length >= 57) break;
      }
      if (positions.length >= 57) break;
    }

    return positions;
  }

  // SUPER ROUND BRAIN - perfect circle-like proportions with heart curve!
  static const _brainPositions = [
    // === TOP WITH HEART CURVE (indent in the middle) ===
    [0.50, 0.32], // center dip (like heart indent)
    [0.48, 0.31], [0.52, 0.31], // slight curve up on sides of dip
    [0.45, 0.31], [0.55, 0.31], // continue curve
    [0.42, 0.32], [0.58, 0.32], // round down the sides
    [0.39, 0.33], [0.61, 0.33], // start of hemisphere curves
    // === LEFT HEMISPHERE - MAXIMUM BULGE (super wide) ===
    [0.36, 0.36], [0.33, 0.40], [0.32, 0.44], [0.33, 0.48], [0.36, 0.51],

    // === RIGHT HEMISPHERE - MAXIMUM BULGE (super wide) ===
    [0.64, 0.36], [0.67, 0.40], [0.68, 0.44], [0.67, 0.48], [0.64, 0.51],

    // === CENTER FISSURE (vertical division) ===
    [0.50, 0.35], [0.50, 0.39], [0.50, 0.43], [0.50, 0.47],

    // === LEFT INNER HEMISPHERE ===
    [0.42, 0.36], [0.40, 0.40], [0.39, 0.44], [0.40, 0.48], [0.42, 0.51],

    // === RIGHT INNER HEMISPHERE ===
    [0.58, 0.36], [0.60, 0.40], [0.61, 0.44], [0.60, 0.48], [0.58, 0.51],

    // === LEFT WRINKLE LAYER ===
    [0.37, 0.38], [0.35, 0.44], [0.37, 0.49],

    // === RIGHT WRINKLE LAYER ===
    [0.63, 0.38], [0.65, 0.44], [0.63, 0.49],

    // === BOTTOM ROUNDED (cerebellum - tight and round) ===
    [0.40, 0.53], [0.45, 0.54], [0.50, 0.55], [0.55, 0.54], [0.60, 0.53],

    // === BOTTOM CURVE LEFT ===
    [0.38, 0.52], [0.36, 0.50],

    // === BOTTOM CURVE RIGHT ===
    [0.62, 0.52], [0.64, 0.50],

    // === CENTER DEPTH (fill middle for roundness) ===
    [0.47, 0.39], [0.53, 0.39], [0.47, 0.43], [0.53, 0.43],
    [0.47, 0.47], [0.53, 0.47],

    // === BRAIN STEM (very short) ===
    [0.50, 0.56], [0.49, 0.57], [0.51, 0.57],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final totalNeurons = _brainPositions.length;
    final visibleNeurons = (totalNeurons * drawProgress).ceil();

    // Draw neurons
    for (int i = 0; i < visibleNeurons; i++) {
      final scattered = _scatteredPositions[i];
      final brain = _brainPositions[i];

      final currentX =
          scattered[0] + (brain[0] - scattered[0]) * convergeProgress;
      final currentY =
          scattered[1] + (brain[1] - scattered[1]) * convergeProgress;

      final pos = Offset(size.width * currentX, size.height * currentY);

      _drawNeuron(canvas, pos, i);

      // Draw temporary connections during draw phase
      if (i > 0 && convergeProgress < 0.2) {
        final prevScattered = _scatteredPositions[i - 1];
        final prevBrain = _brainPositions[i - 1];
        final prevX =
            prevScattered[0] +
            (prevBrain[0] - prevScattered[0]) * convergeProgress;
        final prevY =
            prevScattered[1] +
            (prevBrain[1] - prevScattered[1]) * convergeProgress;
        final prevPos = Offset(size.width * prevX, size.height * prevY);

        _drawConnection(canvas, prevPos, pos, 0.12);
      }
    }

    // Draw brain structure connections
    if (convergeProgress > 0.15) {
      _drawBrainConnections(canvas, size, visibleNeurons);
    }
  }

  void _drawNeuron(Canvas canvas, Offset center, int index) {
    final pulse = convergeProgress > 0.8
        ? (0.85 + 0.15 * pulseProgress).clamp(0.0, 1.0)
        : 1.0;

    final appearProgress = ((drawProgress * _brainPositions.length) - index)
        .clamp(0.0, 1.0);

    // Only draw if neuron has appeared
    if (appearProgress <= 0) return;

    // === DENDRITES (input branches) - draw FIRST ===
    if (appearProgress > 0.3) {
      final dendriteProgress = ((appearProgress - 0.3) / 0.7).clamp(0.0, 1.0);
      _drawDendrites(canvas, center, dendriteProgress, index);
    }

    // === AXON (output branch) - draw SECOND ===
    if (appearProgress > 0.5) {
      final axonProgress = ((appearProgress - 0.5) / 0.5).clamp(0.0, 1.0);
      _drawAxon(canvas, center, axonProgress, index);
    }

    // === SOMA (cell body) - draw LAST ===
    // Outer glow
    canvas.drawCircle(
      center,
      11 * pulse * appearProgress,
      Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6)
        ..color = Colors.white.withOpacity(
          (0.20 * pulse * appearProgress).clamp(0.0, 1.0),
        ),
    );

    // Ring
    canvas.drawCircle(
      center,
      7 * appearProgress,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(
          (0.50 * appearProgress).clamp(0.0, 1.0),
        ),
    );

    // Core
    canvas.drawCircle(
      center,
      4.5 * appearProgress,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(
          (0.70 * pulse * appearProgress).clamp(0.0, 1.0),
        ),
    );

    // Nucleus
    canvas.drawCircle(
      center,
      2 * appearProgress,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(
          (0.95 * appearProgress).clamp(0.0, 1.0),
        ),
    );
  }

  // Draw realistic dendrites (multiple branching input fibers)
  void _drawDendrites(
    Canvas canvas,
    Offset center,
    double progress,
    int index,
  ) {
    final dendritePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    // 5-7 dendrite branches at different angles
    final angles = [-2.8, -2.3, -1.8, -1.3, 2.8, 2.3, 1.8];

    for (int i = 0; i < angles.length; i++) {
      final branchProgress = ((progress * angles.length) - i).clamp(0.0, 1.0);
      if (branchProgress <= 0) continue;

      final angle = angles[i] + (index * 0.3); // vary per neuron
      final mainLength = 25.0 * branchProgress;

      // Main dendrite
      final mainEnd = Offset(
        center.dx + math.cos(angle) * mainLength,
        center.dy + math.sin(angle) * mainLength,
      );

      dendritePaint.color = Colors.white.withOpacity(
        (0.25 * branchProgress).clamp(0.0, 1.0),
      );
      canvas.drawLine(center, mainEnd, dendritePaint);

      // Sub-branches (if main branch fully drawn)
      if (branchProgress > 0.6) {
        final subProgress = ((branchProgress - 0.6) / 0.4).clamp(0.0, 1.0);
        dendritePaint.strokeWidth = 0.8;
        dendritePaint.color = Colors.white.withOpacity(
          (0.18 * subProgress).clamp(0.0, 1.0),
        );

        // Two sub-branches
        final subAngle1 = angle - 0.5;
        final subAngle2 = angle + 0.5;
        final subLength = 12.0 * subProgress;

        canvas.drawLine(
          mainEnd,
          Offset(
            mainEnd.dx + math.cos(subAngle1) * subLength,
            mainEnd.dy + math.sin(subAngle1) * subLength,
          ),
          dendritePaint,
        );

        canvas.drawLine(
          mainEnd,
          Offset(
            mainEnd.dx + math.cos(subAngle2) * subLength,
            mainEnd.dy + math.sin(subAngle2) * subLength,
          ),
          dendritePaint,
        );
      }
    }
  }

  // Draw realistic axon (single long output fiber)
  void _drawAxon(Canvas canvas, Offset center, double progress, int index) {
    final axonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    // Axon grows in opposite direction of dendrites
    final axonAngle = 1.57 + (index * 0.2); // varies per neuron
    final axonLength = 35.0 * progress;

    final axonEnd = Offset(
      center.dx + math.cos(axonAngle) * axonLength,
      center.dy + math.sin(axonAngle) * axonLength,
    );

    // Main axon
    axonPaint.color = Colors.white.withOpacity(
      (0.30 * progress).clamp(0.0, 1.0),
    );
    canvas.drawLine(center, axonEnd, axonPaint);

    // Axon terminal branches (if fully grown)
    if (progress > 0.7) {
      final terminalProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      axonPaint.strokeWidth = 1.0;
      axonPaint.color = Colors.white.withOpacity(
        (0.22 * terminalProgress).clamp(0.0, 1.0),
      );

      // Terminal branches
      final terminals = [
        axonAngle - 0.6,
        axonAngle - 0.3,
        axonAngle + 0.3,
        axonAngle + 0.6,
      ];

      for (final termAngle in terminals) {
        final termLength = 10.0 * terminalProgress;
        canvas.drawLine(
          axonEnd,
          Offset(
            axonEnd.dx + math.cos(termAngle) * termLength,
            axonEnd.dy + math.sin(termAngle) * termLength,
          ),
          axonPaint,
        );
      }
    }
  }

  void _drawConnection(Canvas canvas, Offset from, Offset to, double opacity) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0))
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawBrainConnections(Canvas canvas, Size size, int visibleNeurons) {
    final baseOpacity = (convergeProgress - 0.15) / 0.85;

    final connections = [
      // Top rounded
      [0, 1], [1, 2], [0, 2], [1, 3], [1, 4], [2, 4], [3, 0], [4, 2],

      // Left hemisphere smooth curve
      [5, 6], [6, 7], [7, 8], [8, 9], [9, 10], [10, 11], [11, 12],

      // Right hemisphere smooth curve
      [13, 14], [14, 15], [15, 16], [16, 17], [17, 18], [18, 19], [19, 20],

      // Center fissure
      [21, 22], [22, 23], [23, 24], [24, 25], [25, 26],

      // Left inner
      [27, 28], [28, 29], [29, 30], [30, 31], [31, 32],

      // Right inner
      [33, 34], [34, 35], [35, 36], [36, 37], [37, 38],

      // Left wrinkles
      [39, 40], [40, 41], [41, 42],

      // Right wrinkles
      [43, 44], [44, 45], [45, 46],

      // Bottom cerebellum
      [47, 48], [48, 49], [49, 50], [50, 51],

      // Bottom curves
      [52, 53], [54, 55],

      // Center depth neurons
      [56, 57], [58, 59], [60, 61], [62, 63], [64, 65],

      // Brain stem
      [66, 67], [67, 68],

      // === Cross connections ===
      // Top to center
      [0, 21], [1, 22], [2, 22], [3, 21], [4, 22],

      // Outer to inner LEFT
      [5, 27], [6, 28], [7, 29], [8, 30], [9, 31], [10, 32],

      // Outer to inner RIGHT
      [13, 33], [14, 34], [15, 35], [16, 36], [17, 37], [18, 38],

      // Inner to center LEFT
      [27, 21], [28, 22], [29, 23], [30, 24], [31, 25], [32, 26],

      // Inner to center RIGHT
      [33, 21], [34, 22], [35, 23], [36, 24], [37, 25], [38, 26],

      // Left-Right corpus callosum
      [27, 33], [28, 34], [29, 35], [30, 36], [31, 37], [32, 38],

      // Wrinkles to outer
      [39, 6], [40, 7], [41, 8], [42, 9],
      [43, 14], [44, 15], [45, 16], [46, 17],

      // Wrinkles to inner
      [39, 28], [40, 29], [41, 30], [42, 31],
      [43, 34], [44, 35], [45, 36], [46, 37],

      // Center depth to fissure
      [56, 22], [57, 22], [58, 23], [59, 23], [60, 24], [61, 24],
      [62, 25], [63, 25], [64, 26], [65, 26],

      // Bottom to cerebellum
      [12, 47], [20, 51], [32, 48], [38, 50],
      [47, 52], [51, 54], [48, 49], [49, 66], [52, 53], [54, 55],
    ];

    for (final conn in connections) {
      if (conn[0] >= visibleNeurons || conn[1] >= visibleNeurons) continue;
      if (conn[0] >= _brainPositions.length ||
          conn[1] >= _brainPositions.length)
        continue;

      final brain0 = _brainPositions[conn[0]];
      final brain1 = _brainPositions[conn[1]];
      final scattered0 = _scatteredPositions[conn[0]];
      final scattered1 = _scatteredPositions[conn[1]];

      final x0 = scattered0[0] + (brain0[0] - scattered0[0]) * convergeProgress;
      final y0 = scattered0[1] + (brain0[1] - scattered0[1]) * convergeProgress;
      final x1 = scattered1[0] + (brain1[0] - scattered1[0]) * convergeProgress;
      final y1 = scattered1[1] + (brain1[1] - scattered1[1]) * convergeProgress;

      _drawConnection(
        canvas,
        Offset(size.width * x0, size.height * y0),
        Offset(size.width * x1, size.height * y1),
        (0.25 * baseOpacity).clamp(0.0, 1.0),
      );
    }
  }

  @override
  bool shouldRepaint(NeuronBrainPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.convergeProgress != convergeProgress ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

// ══════════════════════════════════════════════════════════════
// SPLASH BACKGROUND SHAPES PAINTER (from onboarding style)
// ══════════════════════════════════════════════════════════════
class SplashBackgroundShapesPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;

  SplashBackgroundShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large flowing shape - top left
    paint.color = Color(0xFFB7C3E8).withOpacity(0.15);
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

    // Right side flowing shape
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

    // Floating sphere 1
    final spherePaint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.03),
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

    // Floating sphere 2
    final spherePaint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Color(0xFF14366D).withOpacity(0.25),
              Color(0xFF14366D).withOpacity(0.08),
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
  bool shouldRepaint(SplashBackgroundShapesPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3;
  }
}
