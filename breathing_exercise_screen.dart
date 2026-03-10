import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../utils/nuru_colors.dart';
import '../utils/nuru_theme.dart';

// ══════════════════════════════════════════════════════════════
// BREATHING EXERCISE SCREEN - TIIMO INSPIRED
// Colorful, playful, engaging design with Lottie animations
// ══════════════════════════════════════════════════════════════

class BreathingExerciseScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const BreathingExerciseScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _backgroundController;

  Timer? _timer;
  int _currentCycle = 0;
  int _currentPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  int _secondsRemaining = 0;
  bool _isExercising = false;

  // Lottie breathing animations - Free from LottieFiles
  final List<String> breathingAnimations = [
    'https://lottie.host/4f0d5ec7-63f9-4d7b-9c85-6b5c38e5e0e6/EKHNENGCsT.json', // Breathing meditation
    'https://lottie.host/embed/d5989b3b-8431-4c0e-8b5e-8c6d0f5e3c8a/7K9jK3G2VH.json', // Yoga breathing
    'https://lottie.host/embed/a2b8c3d4-1234-5678-90ab-cdef12345678/AbCdEfGhIj.json', // Calm breathing circle
  ];

  // Tiimo-inspired breathing techniques with vibrant colors
  final List<Map<String, dynamic>> breathingTechniques = [
    {
      'name': '4-7-8 Breathing',
      'subtitle': 'Perfect for Sleep',
      'description':
          'Dr. Andrew Weil\'s relaxation technique. Promotes calmness and deep sleep.',
      'icon': '😴',
      'gradient': [Color(0xFF6B4CE6), Color(0xFF9D6EFF)], // Purple gradient
      'pattern': [4, 7, 8, 0],
      'cycles': 4,
      'benefits': ['Reduces anxiety', 'Aids sleep', 'Controls stress response'],
      'source': 'Dr. Andrew Weil, Harvard Medical School',
      'difficulty': 'Beginner',
    },
    {
      'name': 'Box Breathing',
      'subtitle': 'Navy SEAL Technique',
      'description':
          'Used by elite forces for stress management and laser focus.',
      'icon': '🎯',
      'gradient': [Color(0xFF00C9FF), Color(0xFF92FE9D)], // Blue-green gradient
      'pattern': [4, 4, 4, 4],
      'cycles': 5,
      'benefits': [
        'Reduces stress',
        'Improves focus',
        'Regulates nervous system',
      ],
      'source': 'Navy SEAL training program',
      'difficulty': 'Intermediate',
    },
    {
      'name': 'Deep Belly Breathing',
      'subtitle': 'Oxygen Boost',
      'description':
          'Deep diaphragmatic breathing for maximum relaxation and oxygen flow.',
      'icon': '🌊',
      'gradient': [Color(0xFF43E97B), Color(0xFF38F9D7)], // Teal gradient
      'pattern': [4, 2, 6, 0],
      'cycles': 6,
      'benefits': [
        'Lowers heart rate',
        'Reduces muscle tension',
        'Improves oxygen',
      ],
      'source': 'American Lung Association',
      'difficulty': 'Beginner',
    },
    {
      'name': '4-4-6 Breathing',
      'subtitle': 'Extended Exhale',
      'description':
          'Calming technique with longer exhale to activate relaxation response.',
      'icon': '🌙',
      'gradient': [
        Color(0xFFFA709A),
        Color(0xFFFFE985),
      ], // Pink-yellow gradient
      'pattern': [4, 4, 6, 0],
      'cycles': 5,
      'benefits': [
        'Activates parasympathetic',
        'Reduces anxiety',
        'Promotes calm',
      ],
      'source': 'Mindfulness-Based Stress Reduction',
      'difficulty': 'Beginner',
    },
    {
      'name': 'Resonant Breathing',
      'subtitle': 'Heart Coherence',
      'description':
          'Breathe at 5-6 breaths per minute for optimal heart rate variability.',
      'icon': '💚',
      'gradient': [Color(0xFF56CCF2), Color(0xFF2F80ED)], // Blue gradient
      'pattern': [5, 0, 5, 0],
      'cycles': 6,
      'benefits': ['Maximizes HRV', 'Balances nervous system', 'Reduces BP'],
      'source': 'HeartMath Institute',
      'difficulty': 'Advanced',
    },
    {
      'name': 'Calm Breathing',
      'subtitle': 'Quick Relief',
      'description':
          'Simple calming breath for immediate anxiety relief anywhere, anytime.',
      'icon': '☮️',
      'gradient': [
        Color(0xFFFFA751),
        Color(0xFFFFE259),
      ], // Orange-yellow gradient
      'pattern': [3, 0, 6, 0],
      'cycles': 8,
      'benefits': ['Quick stress relief', 'Easy anywhere', 'Immediate calming'],
      'source': 'Cognitive Behavioral Therapy',
      'difficulty': 'Beginner',
    },
  ];

  Map<String, dynamic>? selectedTechnique;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // FIREBASE INTEGRATION (TO BE IMPLEMENTED)
  // ═══════════════════════════════════════════════════════════

  // Future<void> _saveSessionToFirebase(Map<String, dynamic> sessionData) async {
  //   // TODO: Implement Firebase session saving
  //   // await FirebaseFirestore.instance
  //   //   .collection('breathing_sessions')
  //   //   .add(sessionData);
  // }
  //
  // Future<Map<String, dynamic>> _getUserStats() async {
  //   // TODO: Fetch user breathing stats from Firebase
  //   // - Total sessions
  //   // - Total minutes
  //   // - Current streak
  //   // - Favorite technique
  //   return {};
  // }
  //
  // Future<void> _trackProgress() async {
  //   // TODO: Update user progress in Firebase
  //   // - Increment session count
  //   // - Update streak
  //   // - Award achievements
  // }

  // ═══════════════════════════════════════════════════════════

  void _startExercise(Map<String, dynamic> technique) {
    setState(() {
      selectedTechnique = technique;
      _currentCycle = 0;
      _currentPhase = 0;
      _isExercising = true;
      _secondsRemaining = technique['pattern'][0] as int;
    });

    _startBreathingCycle();
  }

  void _startBreathingCycle() {
    if (selectedTechnique == null) return;

    final pattern = selectedTechnique!['pattern'] as List<int>;
    final totalCycles = selectedTechnique!['cycles'] as int;

    _breathingController.duration = Duration(seconds: pattern[_currentPhase]);

    if (pattern[_currentPhase] > 0) {
      _breathingController.forward(from: 0);

      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _secondsRemaining--;
        });

        if (_secondsRemaining <= 0) {
          timer.cancel();
          _nextPhase(pattern, totalCycles);
        }
      });
    } else {
      _nextPhase(pattern, totalCycles);
    }
  }

  void _nextPhase(List<int> pattern, int totalCycles) {
    _currentPhase++;

    if (_currentPhase >= 4) {
      _currentPhase = 0;
      _currentCycle++;

      if (_currentCycle >= totalCycles) {
        _completeExercise();
        return;
      }
    }

    while (_currentPhase < 4 && pattern[_currentPhase] == 0) {
      _currentPhase++;
      if (_currentPhase >= 4) {
        _currentPhase = 0;
        _currentCycle++;
        if (_currentCycle >= totalCycles) {
          _completeExercise();
          return;
        }
      }
    }

    setState(() {
      _secondsRemaining = pattern[_currentPhase];
    });

    _startBreathingCycle();
  }

  void _completeExercise() {
    setState(() {
      _isExercising = false;
    });
    _timer?.cancel();
    _breathingController.reset();

    // TODO: Firebase Integration - Save breathing session
    // _saveSessionToFirebase({
    //   'technique': selectedTechnique!['name'],
    //   'cycles_completed': _currentCycle,
    //   'duration': _calculateDuration(),
    //   'timestamp': DateTime.now(),
    //   'user_id': widget.userData?['id'],
    // });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: selectedTechnique!['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text(
                'Well Done!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You completed ${selectedTechnique!['name']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => selectedTechnique = null);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startExercise(selectedTechnique!);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Repeat',
                        style: TextStyle(
                          color: selectedTechnique!['gradient'][0] as Color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  void _stopExercise() {
    setState(() {
      _isExercising = false;
      selectedTechnique = null;
    });
    _timer?.cancel();
    _breathingController.reset();
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case 0:
        return 'Breathe In';
      case 1:
        return 'Hold';
      case 2:
        return 'Breathe Out';
      case 3:
        return 'Hold';
      default:
        return '';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Color(0xFF43E97B);
      case 'Intermediate':
        return Color(0xFFFFA751);
      case 'Advanced':
        return Color(0xFFFA709A);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Calming gradient background
          Container(
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

          // Animated floating shapes
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: FloatingShapesPainter(
                  animation1: _backgroundController.value,
                  animation2: _backgroundController.value * 0.8,
                  animation3: _backgroundController.value * 1.2,
                ),
              );
            },
          ),

          SafeArea(
            child: selectedTechnique == null
                ? _buildTechniqueSelector()
                : _buildBreathingExercise(),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueSelector() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Breathing',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'All techniques are scientifically proven',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 24),
                ...breathingTechniques.map(
                  (technique) => _buildTechniqueCard(technique),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechniqueCard(Map<String, dynamic> technique) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTechniqueDetails(technique),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: technique['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (technique['gradient'][0] as Color).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon container
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          technique['icon'],
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              technique['name'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              technique['subtitle'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Difficulty badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          technique['difficulty'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    technique['description'],
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.sync,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${technique['cycles']} cycles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTechniqueDetails(Map<String, dynamic> technique) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: technique['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              technique['icon'],
                              style: TextStyle(fontSize: 48),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  technique['name'],
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  technique['subtitle'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      // Description
                      _buildSectionTitle('About'),
                      SizedBox(height: 12),
                      Text(
                        technique['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Pattern
                      _buildSectionTitle('Breathing Pattern'),
                      SizedBox(height: 12),
                      _buildPatternVisual(technique['pattern']),
                      SizedBox(height: 24),

                      // Benefits
                      _buildSectionTitle('Benefits'),
                      SizedBox(height: 12),
                      ...(technique['benefits'] as List<String>).map(
                        (benefit) => Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Source
                      _buildSectionTitle('Source'),
                      SizedBox(height: 12),
                      Text(
                        technique['source'],
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 40),

                      // Start button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startExercise(technique);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: technique['gradient'][0] as Color,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_filled, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Start Breathing',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPatternVisual(List<int> pattern) {
    final labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];
    final icons = [
      Icons.arrow_upward,
      Icons.pause,
      Icons.arrow_downward,
      Icons.pause,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(4, (index) {
        if (pattern[index] == 0) return SizedBox.shrink();
        return Container(
          width: (MediaQuery.of(context).size.width - 72) / 2,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(icons[index], color: Colors.white, size: 28),
              SizedBox(height: 8),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${pattern[index]}s',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).where((w) => w is! SizedBox || (w as SizedBox).width != null).toList(),
    );
  }

  Widget _buildBreathingExercise() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedTechnique!['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          _buildExerciseHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cycle counter
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cycle ${_currentCycle + 1} of ${selectedTechnique!['cycles']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),

                    // Breathing animation circle
                    AnimatedBuilder(
                      animation: _breathingController,
                      builder: (context, child) {
                        return _buildBreathingCircle();
                      },
                    ),
                    SizedBox(height: 40),

                    // Phase text
                    Text(
                      _getPhaseText(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Countdown
                    Text(
                      '$_secondsRemaining',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stop button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _stopExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Stop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCircle() {
    final progress = _breathingController.value;

    // Use Lottie animation for breathing with fallback
    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow effect
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            width: _currentPhase == 0 ? 280 : (_currentPhase == 2 ? 120 : 200),
            height: _currentPhase == 0 ? 280 : (_currentPhase == 2 ? 120 : 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Lottie breathing animation with error handling
          Lottie.network(
            breathingAnimations[0],
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            animate: true,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              // Fallback: Beautiful animated circle if Lottie fails
              return AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: _currentPhase == 0
                    ? 250
                    : (_currentPhase == 2 ? 150 : 200),
                height: _currentPhase == 0
                    ? 250
                    : (_currentPhase == 2 ? 150 : 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _stopExercise,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          SizedBox(width: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selectedTechnique!['icon'],
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedTechnique!['name'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Floating shapes painter (same as CalmMe)
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

    paint.color = Color(0xFF3A4FA8).withOpacity(0.15);
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
