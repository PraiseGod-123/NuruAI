import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/nuru_colors.dart';

// ══════════════════════════════════════════════════════════════
// SIGNUP SCREEN
//
// Caregiver logic:
//   Age 13–19 → caregiver section is REQUIRED, auto-checked,
//               cannot be unchecked, must fill all fields
//   Age 20–25 → caregiver section is OPTIONAL, unchecked by
//               default, can be toggled on/off
//
// Caregiver types: Parent, Guardian, Doctor, Therapist,
//                  Sibling, Nanny, Teacher, Other
// ══════════════════════════════════════════════════════════════

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // User fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Caregiver fields
  final _caregiverNameController = TextEditingController();
  final _caregiverEmailController = TextEditingController();
  final _caregiverPhoneController = TextEditingController();

  int? _userAge;
  String? _selectedDiagnosis;
  String? _caregiverType;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _addCaregiver = false; // toggled by user (20–25) or forced (13–19)

  bool get _isMinor => (_userAge ?? 0) >= 13 && (_userAge ?? 0) <= 19;
  bool get _showCaregiver => _isMinor || _addCaregiver;

  static const List<Map<String, dynamic>> _caregiverTypes = [
    {
      'value': 'parent',
      'label': 'Parent',
      'icon': Icons.family_restroom_rounded,
    },
    {'value': 'guardian', 'label': 'Guardian', 'icon': Icons.shield_rounded},
    {
      'value': 'doctor',
      'label': 'Doctor',
      'icon': Icons.medical_services_outlined,
    },
    {
      'value': 'therapist',
      'label': 'Therapist',
      'icon': Icons.psychology_outlined,
    },
    {
      'value': 'sibling',
      'label': 'Sibling',
      'icon': Icons.people_outline_rounded,
    },
    {'value': 'nanny', 'label': 'Nanny', 'icon': Icons.child_care_rounded},
    {'value': 'teacher', 'label': 'Teacher', 'icon': Icons.school_outlined},
    {'value': 'other', 'label': 'Other', 'icon': Icons.person_outline_rounded},
  ];

  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  @override
  void initState() {
    super.initState();
    _floatController1 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _floatController2 = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _floatController3 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['age'] != null) {
        setState(() {
          _userAge = args!['age'] as int;
          // Auto-enable caregiver for minors
          if (_isMinor) _addCaregiver = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _caregiverPhoneController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDiagnosis == null) {
      _showError('Please select your diagnosis');
      return;
    }

    if (_showCaregiver) {
      if (_caregiverType == null) {
        _showError('Please select the caregiver type');
        return;
      }
      if (_caregiverNameController.text.trim().isEmpty) {
        _showError('Please enter the caregiver\'s name');
        return;
      }
    }

    Navigator.pushReplacementNamed(
      context,
      '/facial-recognition-setup',
      arguments: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': _userAge,
        'diagnosis': _selectedDiagnosis,
        if (_showCaregiver) ...{
          'caregiverType': _caregiverType,
          'caregiverName': _caregiverNameController.text.trim(),
          'caregiverEmail': _caregiverEmailController.text.trim(),
          'caregiverPhone': _caregiverPhoneController.text.trim(),
        },
      },
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

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4569AD),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
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
              builder: (_, __) => CustomPaint(
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
              builder: (_, __) => CustomPaint(
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(24),
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/age-verification',
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join NuruAI and start your journey',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── User fields ──────────────────────────────
                      _field(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_rounded,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _field(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter your email',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _field(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a password',
                        icon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF4569AD),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter a password';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _field(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF4569AD),
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please confirm your password';
                          if (v != _passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Diagnosis ────────────────────────────────
                      const Text(
                        'Select Your Diagnosis *',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This helps us personalise your experience',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _diagnosisCard(
                        'asd',
                        'Autism (ASD)',
                        Icons.psychology_rounded,
                        const Color(0xFF6B9DFF),
                      ),
                      const SizedBox(height: 10),
                      _diagnosisCard(
                        'adhd',
                        'ADHD',
                        Icons.flash_on_rounded,
                        const Color(0xFFFF9D6B),
                      ),
                      const SizedBox(height: 10),
                      _diagnosisCard(
                        'both',
                        'Both ASD & ADHD',
                        Icons.sync_rounded,
                        const Color(0xFF9D6BFF),
                      ),
                      const SizedBox(height: 10),
                      _diagnosisCard(
                        'other',
                        'Other / Prefer not to say',
                        Icons.more_horiz_rounded,
                        const Color(0xFF6BFFA1),
                      ),

                      const SizedBox(height: 32),

                      // ── Caregiver section ────────────────────────
                      _buildCaregiverSection(),

                      const SizedBox(height: 36),

                      // ── Create account button ────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4569AD),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                const TextSpan(
                                  text: 'Log In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CAREGIVER SECTION
  // ══════════════════════════════════════════════════════════

  Widget _buildCaregiverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isMinor
                ? const Color(0xFF4569AD).withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isMinor
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMinor
                          ? Colors.white.withOpacity(0.25)
                          : Colors.white.withOpacity(0.12),
                    ),
                    child: Icon(
                      _isMinor
                          ? Icons.shield_rounded
                          : Icons.person_add_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Caregiver',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _isMinor
                                    ? Colors.red.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isMinor
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _isMinor ? 'Required' : 'Optional',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isMinor
                                      ? Colors.red[200]
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMinor
                              ? 'A caregiver is required for users aged 13-19'
                              : 'Add a caregiver who supports you',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle — only for 20–25
                  if (!_isMinor)
                    Switch(
                      value: _addCaregiver,
                      onChanged: (v) => setState(() => _addCaregiver = v),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF4569AD),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white24,
                    ),
                  // Lock icon for minors
                  if (_isMinor)
                    Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Caregiver form — shown when toggled or required
        if (_showCaregiver) ...[
          const SizedBox(height: 16),

          // Caregiver type dropdown
          Text(
            'Caregiver Type *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _caregiverType,
              hint: const Text(
                'Select caregiver type',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF4569AD),
              ),
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.people_outline_rounded,
                  color: Color(0xFF4569AD),
                  size: 22,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F3F74),
                fontWeight: FontWeight.w500,
              ),
              items: _caregiverTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type['value'] as String,
                      child: Row(
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: const Color(0xFF4569AD),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(type['label'] as String),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _caregiverType = v),
            ),
          ),

          const SizedBox(height: 18),

          // Caregiver name — required
          _field(
            controller: _caregiverNameController,
            label: 'Caregiver Full Name *',
            hint: 'Enter their full name',
            icon: Icons.person_outline_rounded,
            validator: _showCaregiver
                ? (v) => (v == null || v.isEmpty)
                      ? 'Please enter the caregiver\'s name'
                      : null
                : null,
          ),

          const SizedBox(height: 14),

          // Caregiver email — optional
          _field(
            controller: _caregiverEmailController,
            label: 'Caregiver Email (optional)',
            hint: 'Enter their email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          // Caregiver phone — optional
          _field(
            controller: _caregiverPhoneController,
            label: 'Caregiver Phone (optional)',
            hint: 'Enter their phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════

  Widget _diagnosisCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final sel = _selectedDiagnosis == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDiagnosis = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? Colors.white : Colors.white.withOpacity(0.3),
            width: sel ? 2.5 : 1.5,
          ),
          gradient: sel
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                )
              : null,
          color: sel ? null : Colors.white.withOpacity(0.1),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sel ? 10 : 5,
              sigmaY: sel ? 10 : 5,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sel ? color : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (sel)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F3F74),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(
                      icon,
                      color: const Color(0xFF4569AD),
                      size: 22,
                    ),
                    suffixIcon: suffix,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
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

// ── Painters (identical to original) ─────────────────────────

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
  bool shouldRepaint(SubtleStarsPainter o) => o.twinkle != twinkle;
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
    paint.color = const Color(0xFFB7C3E8).withOpacity(0.25);
    final oy1 = animation1 * 40 - 20;
    canvas.drawPath(
      Path()
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
        ..close(),
      paint,
    );
    paint.color = const Color(0xFF081F44).withOpacity(0.2);
    final ox2 = animation2 * 35 - 17;
    canvas.drawPath(
      Path()
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
        ..close(),
      paint,
    );
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
                center: Offset(
                  size.width * 0.75 + (animation1 * 25 - 12),
                  size.height * 0.15 + (animation2 * 20 - 10),
                ),
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
                const Color(0xFF14366D).withOpacity(0.35),
                const Color(0xFF14366D).withOpacity(0.1),
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
            ),
    );
  }

  @override
  bool shouldRepaint(Animated3DShapesPainter o) =>
      o.animation1 != animation1 ||
      o.animation2 != animation2 ||
      o.animation3 != animation3;
}
