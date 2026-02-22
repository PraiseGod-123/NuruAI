import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int? _userAge;
  String? _selectedDiagnosis;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _addCaregiver = false;

  final _caregiverNameController = TextEditingController();
  final _caregiverEmailController = TextEditingController();
  final _caregiverPhoneController = TextEditingController();
  String? _selectedRelationship;

  late AnimationController _floatController1;
  late AnimationController _floatController2;

  final List<String> _diagnosisOptions = [
    'Autism (ASD)',
    'ADHD',
    'Both ASD & ADHD',
    'Prefer not to say',
  ];

  final List<String> _relationships = [
    'Parent',
    'Guardian',
    'Sibling',
    'Therapist',
    'Teacher',
    'Friend',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _floatController1 = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _floatController2 = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['age'] != null) {
        setState(() {
          _userAge = args['age'];
        });
      }
    });
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _caregiverPhoneController.dispose();
    super.dispose();
  }

  bool get _needsCaregiverConsent => _userAge != null && _userAge! < 16;

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      if (_needsCaregiverConsent && !_addCaregiver) {
        _showCaregiverRequiredDialog();
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/micro-expression-setup',
        arguments: {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'age': _userAge,
          'diagnosis': _selectedDiagnosis,
          'caregiver': _addCaregiver
              ? {
                  'name': _caregiverNameController.text,
                  'email': _caregiverEmailController.text,
                  'phone': _caregiverPhoneController.text,
                  'relationship': _selectedRelationship,
                }
              : null,
        },
      );
    }
  }

  void _showCaregiverRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Caregiver Required'),
        content: Text(
          'For users under 16, we need a parent or guardian to be linked to your account for safety.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _addCaregiver = true;
              });
            },
            child: Text('Add Caregiver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background (same as age verification)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4569AD), Color(0xFF1F3F74)],
              ),
            ),
          ),

          // Simple dynamic background shapes (same as age verification)
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
                        onPressed: () {
                          // Navigate back to age verification screen
                          Navigator.pushReplacementNamed(
                            context,
                            '/age-verification',
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 24),

                    // Header
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set up your NuruAI profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Form fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'your.email@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Create a strong password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    _buildDropdown(
                      label: 'Diagnosis (Optional)',
                      hint: "Select if you'd like",
                      value: _selectedDiagnosis,
                      items: _diagnosisOptions,
                      icon: Icons.medical_information_outlined,
                      onChanged: (value) {
                        setState(() {
                          _selectedDiagnosis = value;
                        });
                      },
                    ),

                    SizedBox(height: 28),

                    // Caregiver Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          'Add Caregiver',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          _needsCaregiverConsent
                              ? 'Required for users under 16'
                              : 'Link a parent/guardian (optional)',
                          style: TextStyle(
                            fontSize: 13,
                            color: _needsCaregiverConsent
                                ? Colors.white.withOpacity(0.95)
                                : Colors.white.withOpacity(0.8),
                          ),
                        ),
                        value: _addCaregiver || _needsCaregiverConsent,
                        activeColor: Colors.white,
                        checkColor: Color(0xFF4569AD),
                        onChanged: _needsCaregiverConsent
                            ? null
                            : (value) {
                                setState(() {
                                  _addCaregiver = value ?? false;
                                });
                              },
                      ),
                    ),

                    // Caregiver Fields
                    if (_addCaregiver || _needsCaregiverConsent) ...[
                      SizedBox(height: 24),
                      _buildTextField(
                        controller: _caregiverNameController,
                        label: 'Caregiver Name',
                        hint: 'Enter caregiver\'s name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if ((_addCaregiver || _needsCaregiverConsent) &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter caregiver name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _caregiverEmailController,
                        label: 'Caregiver Email',
                        hint: 'caregiver@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if ((_addCaregiver || _needsCaregiverConsent) &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter caregiver email';
                          }
                          if ((_addCaregiver || _needsCaregiverConsent) &&
                              value != null &&
                              (!value.contains('@') || !value.contains('.'))) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _caregiverPhoneController,
                        label: 'Caregiver Phone',
                        hint: 'Phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if ((_addCaregiver || _needsCaregiverConsent) &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Relationship',
                        hint: 'Select relationship',
                        value: _selectedRelationship,
                        items: _relationships,
                        icon: Icons.connect_without_contact,
                        onChanged: (value) {
                          setState(() {
                            _selectedRelationship = value;
                          });
                        },
                        validator: (value) {
                          if ((_addCaregiver || _needsCaregiverConsent) &&
                              value == null) {
                            return 'Please select relationship';
                          }
                          return null;
                        },
                      ),
                    ],

                    SizedBox(height: 40),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleSignup,
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

                    SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(color: Color(0xFF1F3F74)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Color(0xFF4569AD)),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red[300]!, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
            validator: validator,
            icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF4569AD)),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF4569AD)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: TextStyle(color: Color(0xFF1F3F74))),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Simple background painter (same as age verification)
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
