import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({Key? key}) : super(key: key);

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Using dropdown for easier selection
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  late AnimationController _floatController1;
  late AnimationController _floatController2;

  @override
  void initState() {
    super.initState();

    // Initialize simple floating animations
    _floatController1 = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _floatController2 = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    super.dispose();
  }

  int? _calculateAge() {
    if (_selectedDay == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      return null;
    }

    try {
      final birthDate = DateTime(
        _selectedYear!,
        _selectedMonth!,
        _selectedDay!,
      );
      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }

  void _handleContinue() {
    if (_selectedDay == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      _showError('Please select your complete birthday');
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
    Navigator.pushReplacementNamed(context, '/', arguments: {'initialPage': 3});
  }

  // Generate list of days (1-31)
  List<int> get _days => List.generate(31, (index) => index + 1);

  // Generate list of years (current year - 100 to current year - 10)
  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(91, (index) => currentYear - 10 - index);
  }

  // Month names for easier understanding
  final List<Map<String, dynamic>> _months = [
    {'value': 1, 'name': 'January'},
    {'value': 2, 'name': 'February'},
    {'value': 3, 'name': 'March'},
    {'value': 4, 'name': 'April'},
    {'value': 5, 'name': 'May'},
    {'value': 6, 'name': 'June'},
    {'value': 7, 'name': 'July'},
    {'value': 8, 'name': 'August'},
    {'value': 9, 'name': 'September'},
    {'value': 10, 'name': 'October'},
    {'value': 11, 'name': 'November'},
    {'value': 12, 'name': 'December'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4569AD), Color(0xFF1F3F74)],
              ),
            ),
          ),

          // Simple dynamic background shapes
          AnimatedBuilder(
            animation: Listenable.merge([_floatController1, _floatController2]),
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
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

                    // Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.cake_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Title
                    Text(
                      'When is your birthday?',
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

                    SizedBox(height: 48),

                    // Easy-to-use dropdown fields
                    Text(
                      'Select Your Birthday',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Month Dropdown (Full names for clarity)
                    _buildDropdown(
                      label: 'Month',
                      value: _selectedMonth,
                      items: _months.map((month) {
                        return DropdownMenuItem<int>(
                          value: month['value'],
                          child: Text(
                            month['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                      icon: Icons.calendar_month,
                    ),

                    SizedBox(height: 16),

                    // Day Dropdown
                    _buildDropdown(
                      label: 'Day',
                      value: _selectedDay,
                      items: _days.map((day) {
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                      icon: Icons.today,
                    ),

                    SizedBox(height: 16),

                    // Year Dropdown
                    _buildDropdown(
                      label: 'Year',
                      value: _selectedYear,
                      items: _years.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                      icon: Icons.event,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        SizedBox(height: 8),
        Container(
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
                child: DropdownButtonFormField<int>(
                  value: value,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: Color(0xFF4569AD)),
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
                    hintText: 'Select $label',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  dropdownColor: Colors.white,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF4569AD),
                    size: 30,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F3F74),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 300,
                  items: items,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Simple background painter with gentle floating shapes
class SimpleBackgroundPainter extends CustomPainter {
  final double animation1;
  final double animation2;

  SimpleBackgroundPainter({required this.animation1, required this.animation2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large gentle circle - top left
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

    // Medium circle - bottom right
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

    // Small accent circle - center
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + (animation2 * 30 - 15),
        size.height * 0.45 + (animation1 * 35 - 17),
      ),
      80,
      paint,
    );

    // Soft wave at bottom
    paint.color = Color(0xFF14366D).withOpacity(0.12);
    final wavePath = Path()
      ..moveTo(0, size.height * 0.85 + (animation1 * 20 - 10))
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8 + (animation2 * 25 - 12),
        size.width,
        size.height * 0.85 + (animation1 * 15 - 7),
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wavePath, paint);
  }

  @override
  bool shouldRepaint(SimpleBackgroundPainter oldDelegate) => true;
}
