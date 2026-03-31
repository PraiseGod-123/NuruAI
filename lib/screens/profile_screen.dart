import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/nuru_colors.dart';
import '../utils/nuru_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/text_size_provider.dart';
import '../services/notification_service.dart';
import '../services/api_services.dart';
import '../services/firebase_service.dart';

// ══════════════════════════════════════════════════════════════
// PROFILE SCREEN — fully wired
//   • Notifications: toggles + time pickers → NuruNotificationService
//   • Text Size: slider → TextSizeProvider (persisted)
//   • Theme: picker → NuruThemeProvider
//   • Help & Support: FAQ + contact sheet
// ══════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfileScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  // User data
  String _name = 'User';
  String _email = '';
  String _diagnosis = 'asd';
  int _age = 20;

  // Caregiver
  String? _caregiverName;
  String? _caregiverType;
  String? _caregiverEmail;
  String? _caregiverPhone;

  // Live stats from Firestore
  Map<String, dynamic> _liveStats = {};

  // Notification toggles
  bool _notificationsOn = true;
  bool _moodReminders = true;
  bool _streakReminder = true;
  bool _journalReminder = true;

  // Notification times
  TimeOfDay _moodMorningTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _moodEveningTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _journalTime = const TimeOfDay(hour: 20, minute: 30);
  TimeOfDay _streakMorningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _streakEveningTime = const TimeOfDay(hour: 21, minute: 0);

  static const Map<String, String> _diagnosisLabels = {
    'asd': 'Autism (ASD)',
    'adhd': 'ADHD',
    'both': 'ASD & ADHD',
    'other': 'Other',
  };

  static const Map<String, String> _caregiverLabels = {
    'parent': 'Parent',
    'guardian': 'Guardian',
    'doctor': 'Doctor',
    'therapist': 'Therapist',
    'sibling': 'Sibling',
    'nanny': 'Nanny',
    'teacher': 'Teacher',
    'other': 'Other',
  };

  String get _diagnosisLabel =>
      _diagnosisLabels[_diagnosis] ?? _diagnosis.toUpperCase();
  String get _caregiverTypeLabel =>
      _caregiverLabels[_caregiverType ?? ''] ?? (_caregiverType ?? '');
  bool get _hasCaregiver =>
      _caregiverName != null && _caregiverName!.isNotEmpty;

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'U';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    final d = widget.userData;
    if (d != null) {
      _name = d['name'] as String? ?? 'User';
      _email = d['email'] as String? ?? '';
      _diagnosis = d['diagnosis'] as String? ?? 'asd';
      _age = d['age'] as int? ?? 20;
      _caregiverName = d['caregiverName'] as String?;
      _caregiverType = d['caregiverType'] as String?;
      _caregiverEmail = d['caregiverEmail'] as String?;
      _caregiverPhone = d['caregiverPhone'] as String?;
    }

    // Register FCM token with Flask backend
    _registerFCMToken();

    // Stream live stats from Firestore
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isNotEmpty) {
      NuruFirebaseService.instance.streamUserStats(uid).listen((stats) {
        if (mounted) setState(() => _liveStats = stats);
      });
    }
  }

  Future<void> _registerFCMToken() async {
    try {
      final token = await NuruNotificationService.instance.getFCMToken();
      final userId = widget.userData?['uid'] as String? ?? _email;
      if (token != null && userId.isNotEmpty) {
        await NuruApiService.instance.registerFCMToken(
          userId: userId,
          fcmToken: token,
        );
      }
    } catch (e) {
      debugPrint('FCM token registration skipped: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1F44), Color(0xFF050D1A)],
            ),
          ),
          child: Stack(
            children: [
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, __) => CustomPaint(
                    size: Size.infinite,
                    painter: _ProfileStarsPainter(
                      t: _animationController.value,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(overscroll: false),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                          children: [
                            _buildAvatarCard(),
                            const SizedBox(height: 20),
                            _sectionLabel('PERSONAL INFO'),
                            const SizedBox(height: 10),
                            _buildPersonalInfoCard(),
                            const SizedBox(height: 20),
                            _sectionLabel('CAREGIVER'),
                            const SizedBox(height: 10),
                            _buildCaregiverCard(),
                            const SizedBox(height: 20),
                            _sectionLabel('NOTIFICATIONS'),
                            const SizedBox(height: 10),
                            _buildNotificationsCard(),
                            const SizedBox(height: 20),
                            _sectionLabel('APPEARANCE'),
                            const SizedBox(height: 10),
                            _buildAppearanceCard(),
                            const SizedBox(height: 20),
                            _sectionLabel('SUPPORT'),
                            const SizedBox(height: 10),
                            _buildSupportCard(),
                            const SizedBox(height: 24),
                            _buildLogoutButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(NuruTheme.spacingL),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: NuruTheme.darkGlassCard(),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: NuruTheme.spacingM),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Your account & settings',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileSheet(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: NuruTheme.darkGlassCard(),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(NuruTheme.spacingL),
      decoration: NuruTheme.darkCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NuruColors.dive.withOpacity(0.8), NuruColors.nightCard],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [NuruColors.sailingBlue, NuruColors.dive],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: NuruColors.sailingBlue.withOpacity(0.4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                if (_email.isNotEmpty)
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _pill(_diagnosisLabel, NuruColors.sailingBlue),
                    const SizedBox(width: 8),
                    _pill('$_age yrs', NuruColors.solidBlue.withOpacity(0.6)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Personal info ─────────────────────────────────────────

  Widget _buildPersonalInfoCard() {
    // Format member since date from createdAt
    final createdAtStr =
        widget.userData?['createdAt'] as String? ??
        _liveStats['createdAt'] as String?;
    String memberSince = 'Unknown';
    if (createdAtStr != null) {
      try {
        final dt = DateTime.parse(createdAtStr);
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        memberSince = '${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }

    final streak = (_liveStats['currentStreak'] as num? ?? 0).toInt();
    final checkIns = (_liveStats['totalCheckIns'] as num? ?? 0).toInt();
    final avgMood = (_liveStats['avgMood'] as num? ?? 0.0).toDouble();

    return Container(
      decoration: NuruTheme.darkCard(),
      child: Column(
        children: [
          _editableTile(Icons.person_rounded, 'Full Name', _name, _editName),
          _cardDivider(),
          _infoTile(Icons.cake_rounded, 'Age', '$_age years old'),
          _cardDivider(),
          _infoTile(
            Icons.email_outlined,
            'Email',
            _email.isNotEmpty ? _email : 'Not provided',
          ),
          _cardDivider(),
          _infoTile(Icons.psychology_outlined, 'Diagnosis', _diagnosisLabel),
          _cardDivider(),
          _infoTile(Icons.calendar_today_outlined, 'Member since', memberSince),
          _cardDivider(),
          _infoTile(
            Icons.local_fire_department_outlined,
            'Current streak',
            streak > 0 ? '$streak day${streak == 1 ? '' : 's'}' : 'Not started',
          ),
          _cardDivider(),
          _infoTile(
            Icons.check_circle_outline,
            'Total check-ins',
            checkIns > 0
                ? '$checkIns check-in${checkIns == 1 ? '' : 's'}'
                : 'None yet',
          ),
          _cardDivider(),
          _infoTile(
            Icons.mood_outlined,
            'Average mood',
            avgMood > 0 ? '${avgMood.toStringAsFixed(1)} / 10' : 'No data yet',
          ),
        ],
      ),
    );
  }

  void _editName() {
    final ctrl = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F3F74),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Name',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: NuruColors.sailingBlue,
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: NuruColors.sailingBlue.withOpacity(0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NuruColors.sailingBlue),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              setState(() => _name = newName);
              final uid = widget.userData?['uid'] as String? ?? '';
              if (uid.isNotEmpty) {
                await NuruFirebaseService.instance.updateUserProfile(
                  uid: uid,
                  fields: {'name': newName},
                );
                // Also update Firebase Auth display name
                await NuruFirebaseService.instance.currentUser
                    ?.updateDisplayName(newName);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: NuruColors.sailingBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Profile Sheet ────────────────────────────────────

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _name);
    final ageCtrl = TextEditingController(text: '$_age');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1F3F74),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _sheetField('Full Name', nameCtrl, TextInputType.name),
              const SizedBox(height: 14),
              _sheetField('Age', ageCtrl, TextInputType.number),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NuruColors.sailingBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        final newAge =
                            int.tryParse(ageCtrl.text.trim()) ?? _age;
                        if (newName.isEmpty) return;
                        Navigator.pop(context);
                        setState(() {
                          _name = newName;
                          _age = newAge;
                        });
                        final uid = widget.userData?['uid'] as String? ?? '';
                        if (uid.isNotEmpty) {
                          await NuruFirebaseService.instance.updateUserProfile(
                            uid: uid,
                            fields: {'name': newName, 'age': newAge},
                          );
                          await NuruFirebaseService.instance.currentUser
                              ?.updateDisplayName(newName);
                        }
                        _showSnack('Profile updated');
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  // ── Privacy & Security Sheet ──────────────────────────────

  void _showPrivacyAndSecurity() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1F3F74),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Change your password',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 20),
                _passwordField(
                  'Current password',
                  currentCtrl,
                  obscureCurrent,
                  () => setSheetState(() => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  'New password',
                  newCtrl,
                  obscureNew,
                  () => setSheetState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  'Confirm new password',
                  confirmCtrl,
                  obscureConfirm,
                  () => setSheetState(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NuruColors.sailingBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (newCtrl.text != confirmCtrl.text) {
                            _showSnack('New passwords do not match');
                            return;
                          }
                          if (newCtrl.text.length < 6) {
                            _showSnack(
                              'Password must be at least 6 characters',
                            );
                            return;
                          }
                          try {
                            final user =
                                NuruFirebaseService.instance.currentUser;
                            if (user == null) return;
                            // Re-authenticate then change password
                            final cred = EmailAuthProvider.credential(
                              email: user.email ?? _email,
                              password: currentCtrl.text,
                            );
                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(newCtrl.text);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSnack('Password changed successfully');
                          } catch (e) {
                            _showSnack('Incorrect current password');
                          }
                        },
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  // ── Add Caregiver Sheet ───────────────────────────────────

  void _showAddCaregiverSheet() {
    final nameCtrl = TextEditingController(text: _caregiverName ?? '');
    final emailCtrl = TextEditingController(text: _caregiverEmail ?? '');
    final phoneCtrl = TextEditingController(text: _caregiverPhone ?? '');
    String? selectedType = _caregiverType;

    const types = [
      'Parent',
      'Guardian',
      'Doctor',
      'Therapist',
      'Sibling',
      'Nanny',
      'Teacher',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1F3F74),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caregiver Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sheetField('Caregiver Name', nameCtrl, TextInputType.name),
                  const SizedBox(height: 14),
                  // Type dropdown
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    hint: const Text(
                      'Caregiver type',
                      style: TextStyle(color: Colors.white60),
                    ),
                    dropdownColor: const Color(0xFF1F3F74),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  const SizedBox(height: 14),
                  _sheetField(
                    'Email (optional)',
                    emailCtrl,
                    TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _sheetField(
                    'Phone (optional)',
                    phoneCtrl,
                    TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NuruColors.sailingBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                selectedType == null) {
                              _showSnack('Please enter name and type');
                              return;
                            }
                            Navigator.pop(context);
                            setState(() {
                              _caregiverName = nameCtrl.text.trim();
                              _caregiverType = selectedType;
                              _caregiverEmail = emailCtrl.text.trim().isEmpty
                                  ? null
                                  : emailCtrl.text.trim();
                              _caregiverPhone = phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim();
                            });
                            final uid =
                                widget.userData?['uid'] as String? ?? '';
                            if (uid.isNotEmpty) {
                              await NuruFirebaseService.instance
                                  .updateUserProfile(
                                    uid: uid,
                                    fields: {
                                      'caregiverName': _caregiverName,
                                      'caregiverType': _caregiverType,
                                      if (_caregiverEmail != null)
                                        'caregiverEmail': _caregiverEmail,
                                      if (_caregiverPhone != null)
                                        'caregiverPhone': _caregiverPhone,
                                    },
                                  );
                            }
                            _showSnack('Caregiver saved');
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  // ── Sheet helpers ─────────────────────────────────────────

  Widget _sheetField(
    String hint,
    TextEditingController ctrl,
    TextInputType type,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: NuruColors.sailingBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: NuruColors.sailingBlue.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NuruColors.sailingBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _passwordField(
    String hint,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: NuruColors.sailingBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: NuruColors.sailingBlue.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NuruColors.sailingBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white38,
            size: 20,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _editableTile(
    IconData icon,
    String label,
    String value,
    VoidCallback onEdit,
  ) {
    return GestureDetector(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NuruTheme.spacingL,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NuruColors.sailingBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: NuruColors.solidBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: NuruColors.nightTextMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: NuruColors.nightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: NuruColors.sailingBlue.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── Caregiver ─────────────────────────────────────────────

  Widget _buildCaregiverCard() {
    return Container(
      decoration: NuruTheme.darkCard(),
      child: _hasCaregiver
          ? Column(
              children: [
                _infoTile(
                  Icons.people_outline_rounded,
                  'Name',
                  _caregiverName!,
                ),
                if (_caregiverType != null) ...[
                  _cardDivider(),
                  _infoTile(Icons.badge_outlined, 'Role', _caregiverTypeLabel),
                ],
                if (_caregiverEmail != null && _caregiverEmail!.isNotEmpty) ...[
                  _cardDivider(),
                  _infoTile(Icons.email_outlined, 'Email', _caregiverEmail!),
                ],
                if (_caregiverPhone != null && _caregiverPhone!.isNotEmpty) ...[
                  _cardDivider(),
                  _infoTile(Icons.phone_outlined, 'Phone', _caregiverPhone!),
                ],
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(NuruTheme.spacingL),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: NuruColors.nightTextMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No caregiver added.',
                      style: TextStyle(
                        fontSize: 14,
                        color: NuruColors.nightTextSecondary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddCaregiverSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: NuruColors.sailingBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: NuruColors.sailingBlue.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Notifications ─────────────────────────────────────────

  Widget _buildNotificationsCard() {
    return Container(
      decoration: NuruTheme.darkCard(),
      child: Column(
        children: [
          // Master toggle
          _switchTile(
            Icons.notifications_outlined,
            'All Notifications',
            'Enable or disable all reminders',
            _notificationsOn,
            (v) async {
              setState(() => _notificationsOn = v);
              if (v) {
                await NuruNotificationService.instance
                    .scheduleDailyMoodReminder(
                      hour: _moodMorningTime.hour,
                      minute: _moodMorningTime.minute,
                    );
                await NuruNotificationService.instance
                    .scheduleEveningMoodReminder(
                      hour: _moodEveningTime.hour,
                      minute: _moodEveningTime.minute,
                    );
                await NuruNotificationService.instance.scheduleJournalReminder(
                  hour: _journalTime.hour,
                  minute: _journalTime.minute,
                );
                await NuruNotificationService.instance
                    .scheduleMorningStreakReminder(
                      hour: _streakMorningTime.hour,
                      minute: _streakMorningTime.minute,
                    );
                await NuruNotificationService.instance.scheduleStreakReminder(
                  hour: _streakEveningTime.hour,
                  minute: _streakEveningTime.minute,
                );
              } else {
                await NuruNotificationService.instance.cancelAll();
              }
            },
          ),
          _cardDivider(),
          // Mood
          _switchTile(
            Icons.mood_rounded,
            'Mood Check-in',
            '${_moodMorningTime.format(context)} · ${_moodEveningTime.format(context)}',
            _moodReminders && _notificationsOn,
            (v) async {
              setState(() => _moodReminders = v);
              if (v && _notificationsOn) {
                await NuruNotificationService.instance
                    .scheduleDailyMoodReminder(
                      hour: _moodMorningTime.hour,
                      minute: _moodMorningTime.minute,
                    );
                await NuruNotificationService.instance
                    .scheduleEveningMoodReminder(
                      hour: _moodEveningTime.hour,
                      minute: _moodEveningTime.minute,
                    );
              } else {
                await NuruNotificationService.instance.cancelAll();
              }
            },
          ),
          _cardDivider(),
          // Journal
          _switchTile(
            Icons.book_outlined,
            'Journal Reminder',
            'Daily at ${_journalTime.format(context)}',
            _journalReminder && _notificationsOn,
            (v) async {
              setState(() => _journalReminder = v);
              if (v && _notificationsOn) {
                await NuruNotificationService.instance.scheduleJournalReminder(
                  hour: _journalTime.hour,
                  minute: _journalTime.minute,
                );
              } else {
                await NuruNotificationService.instance.cancelAll();
              }
            },
          ),
          _cardDivider(),
          // Streak
          _switchTile(
            Icons.local_fire_department_rounded,
            'Streak Reminder',
            '${_streakMorningTime.format(context)} · ${_streakEveningTime.format(context)}',
            _streakReminder && _notificationsOn,
            (v) async {
              setState(() => _streakReminder = v);
              if (v && _notificationsOn) {
                await NuruNotificationService.instance
                    .scheduleMorningStreakReminder(
                      hour: _streakMorningTime.hour,
                      minute: _streakMorningTime.minute,
                    );
                await NuruNotificationService.instance.scheduleStreakReminder(
                  hour: _streakEveningTime.hour,
                  minute: _streakEveningTime.minute,
                );
              } else {
                await NuruNotificationService.instance.cancelAll();
              }
            },
          ),
          _cardDivider(),
          // Time settings
          _arrowTile(
            Icons.access_time_rounded,
            'Reminder Times',
            'Mood · Journal · Streak',
            () => _showReminderTimePicker(),
          ),
        ],
      ),
    );
  }

  // ── Appearance ────────────────────────────────────────────

  Widget _buildAppearanceCard() {
    final themeProvider = context.watch<NuruThemeProvider>();
    final textProvider = context.watch<TextSizeProvider>();
    return Container(
      decoration: NuruTheme.darkCard(),
      child: Column(
        children: [
          _arrowTile(
            Icons.palette_outlined,
            'Theme',
            themeProvider.activeTheme.fancyName,
            () => _showThemePicker(),
          ),
          _cardDivider(),
          _arrowTile(
            Icons.text_fields_rounded,
            'Text Size',
            textProvider.label,
            () => _showTextSizePicker(),
          ),
          _cardDivider(),
          _arrowTile(
            Icons.security_rounded,
            'Privacy & Security',
            'Manage your data',
            () => _showPrivacyAndSecurity(),
          ),
        ],
      ),
    );
  }

  // ── Support ───────────────────────────────────────────────

  Widget _buildSupportCard() {
    return Container(
      decoration: NuruTheme.darkCard(),
      child: Column(
        children: [
          _arrowTile(
            Icons.help_outline_rounded,
            'Help & Support',
            'FAQs, contact us',
            () => _showHelpAndSupport(),
          ),
          _cardDivider(),
          _arrowTile(
            Icons.info_outline_rounded,
            'About NuruAI',
            'Version 1.0.0',
            () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: NuruColors.nightCard,
          borderRadius: BorderRadius.circular(NuruTheme.radiusXL),
          border: Border.all(
            color: NuruColors.error.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: NuruColors.error, size: 22),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NuruColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM SHEETS
  // ══════════════════════════════════════════════════════════

  // ── Reminder time picker ──────────────────────────────────

  void _showReminderTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NuruColors.nightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reminder Times',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a time to change it',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _timeTile(ctx, '🌟 Mood — Morning', _moodMorningTime, (t) async {
                setState(() => _moodMorningTime = t);
                setSheet(() {});
                if (_moodReminders && _notificationsOn)
                  await NuruNotificationService.instance
                      .scheduleDailyMoodReminder(
                        hour: t.hour,
                        minute: t.minute,
                      );
              }),
              const SizedBox(height: 12),
              _timeTile(ctx, '🌙 Mood — Evening', _moodEveningTime, (t) async {
                setState(() => _moodEveningTime = t);
                setSheet(() {});
                if (_moodReminders && _notificationsOn)
                  await NuruNotificationService.instance
                      .scheduleEveningMoodReminder(
                        hour: t.hour,
                        minute: t.minute,
                      );
              }),
              const SizedBox(height: 12),
              _timeTile(ctx, '📓 Journal Reminder', _journalTime, (t) async {
                setState(() => _journalTime = t);
                setSheet(() {});
                if (_journalReminder && _notificationsOn)
                  await NuruNotificationService.instance
                      .scheduleJournalReminder(hour: t.hour, minute: t.minute);
              }),
              const SizedBox(height: 12),
              _timeTile(ctx, '🔥 Streak — Morning', _streakMorningTime, (
                t,
              ) async {
                setState(() => _streakMorningTime = t);
                setSheet(() {});
                if (_streakReminder && _notificationsOn)
                  await NuruNotificationService.instance
                      .scheduleMorningStreakReminder(
                        hour: t.hour,
                        minute: t.minute,
                      );
              }),
              const SizedBox(height: 12),
              _timeTile(ctx, '🔥 Streak — Evening', _streakEveningTime, (
                t,
              ) async {
                setState(() => _streakEveningTime = t);
                setSheet(() {});
                if (_streakReminder && _notificationsOn)
                  await NuruNotificationService.instance.scheduleStreakReminder(
                    hour: t.hour,
                    minute: t.minute,
                  );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeTile(
    BuildContext ctx,
    String label,
    TimeOfDay current,
    Function(TimeOfDay) onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: ctx,
          initialTime: current,
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4569AD),
                surface: Color(0xFF162036),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NuruColors.sailingBlue.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: NuruColors.sailingBlue.withOpacity(0.5),
                ),
              ),
              child: Text(
                current.format(ctx),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Theme picker ──────────────────────────────────────────

  void _showThemePicker() {
    final provider = context.read<NuruThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: NuruColors.nightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Choose Theme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: provider.themes.length,
                  itemBuilder: (_, i) {
                    final theme = provider.themes[i];
                    final isActive = provider.activeTheme.id == theme.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? NuruColors.sailingBlue.withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? NuruColors.sailingBlue
                              : Colors.white12,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: theme.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isActive ? Colors.white : Colors.white24,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                        ),
                        title: Text(
                          theme.fancyName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          theme.description,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        trailing: isActive
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: NuruColors.sailingBlue,
                              )
                            : null,
                        onTap: () {
                          provider.setTheme(theme.id);
                          setSheet(() {});
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text size picker ──────────────────────────────────────

  void _showTextSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NuruColors.nightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final provider = ctx.read<TextSizeProvider>();
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Text Size',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adjust how large text appears across the app',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),
                // Preview text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          fontSize: 16 * provider.scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap a mood to log how you're feeling right now.",
                        style: TextStyle(
                          fontSize: 13 * provider.scale,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Size label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'A',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      provider.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: NuruColors.sailingBlue,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: NuruColors.sailingBlue,
                    overlayColor: NuruColors.sailingBlue.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: provider.scale,
                    min: provider.min,
                    max: provider.max,
                    divisions: 11,
                    onChanged: (v) async {
                      await provider.setScale(v);
                      setSheet(() {});
                    },
                  ),
                ),
                // Size presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final entry in [
                      ('Small', 0.85),
                      ('Normal', 1.0),
                      ('Large', 1.2),
                      ('XL', 1.4),
                    ])
                      GestureDetector(
                        onTap: () async {
                          await provider.setScale(entry.$2);
                          setSheet(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (provider.scale - entry.$2).abs() < 0.05
                                ? NuruColors.sailingBlue.withOpacity(0.3)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (provider.scale - entry.$2).abs() < 0.05
                                  ? NuruColors.sailingBlue
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            entry.$1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight:
                                  (provider.scale - entry.$2).abs() < 0.05
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await provider.reset();
                      setSheet(() {});
                    },
                    child: const Text(
                      'Reset to Default',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Help & Support ────────────────────────────────────────

  void _showHelpAndSupport() {
    final faqs = [
      {
        'q': 'How does facial recognition work?',
        'a':
            'NuruAI uses your camera to verify your identity. Your face data is stored securely and never shared.',
      },
      {
        'q': 'Is my data private?',
        'a':
            'Yes. Your journal entries stay on your device. Only anonymised mood patterns are used to improve recommendations.',
      },
      {
        'q': 'How do I change my reminder times?',
        'a':
            'Go to Profile → Notifications → Reminder Times to set your preferred times.',
      },
      {
        'q': 'What does the Streak Reminder do?',
        'a':
            'It reminds you each evening if you haven\'t logged your mood that day, so you can keep your streak.',
      },
      {
        'q': 'Can a caregiver see my data?',
        'a':
            'Not unless you explicitly share it with them. Caregiver access is optional and controlled by you.',
      },
      {
        'q': 'How do I contact support?',
        'a': 'Email us at support@nuruai.app — we respond within 24 hours.',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: NuruColors.nightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NuruColors.sailingBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: NuruColors.sailingBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: [
                  // Contact card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          NuruColors.sailingBlue.withOpacity(0.25),
                          NuruColors.dive.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: NuruColors.sailingBlue.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Us',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: NuruColors.solidBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'support@nuruai.app',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: NuruColors.solidBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Response within 24 hours',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      color: NuruColors.nightTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...faqs.map((faq) => _faqTile(faq['q']!, faq['a']!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return Theme(
      data: ThemeData.dark(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: NuruColors.solidBlue,
          collapsedIconColor: Colors.white38,
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── About dialog ──────────────────────────────────────────

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NuruColors.nightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NuruTheme.radiusXL),
        ),
        title: const Text(
          'About NuruAI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: NuruColors.nightTextSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'AI-Powered Autism Care for ASD Level 1',
              style: TextStyle(color: NuruColors.nightTextSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'Built with care for autistic individuals aged 13–25.',
              style: TextStyle(
                color: NuruColors.nightTextSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '© 2025 NuruAI',
              style: TextStyle(color: NuruColors.nightTextMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: NuruColors.solidBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout dialog ─────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NuruColors.nightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NuruTheme.radiusXL),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will be taken back to the login screen.',
          style: TextStyle(color: NuruColors.nightTextSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: NuruColors.nightTextMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              NuruNotificationService.instance.cancelAll();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: const Text(
              'Log out',
              style: TextStyle(
                color: NuruColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SHARED TILE WIDGETS
  // ══════════════════════════════════════════════════════════

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NuruTheme.spacingL,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NuruColors.sailingBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: NuruColors.solidBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: NuruColors.nightTextMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NuruColors.nightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NuruTheme.spacingL,
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NuruColors.sailingBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: NuruColors.solidBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NuruColors.nightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NuruColors.nightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: NuruColors.sailingBlue,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _arrowTile(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NuruTheme.spacingL,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NuruColors.sailingBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: NuruColors.solidBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: NuruColors.nightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NuruColors.nightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: NuruColors.nightTextMuted,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardDivider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: NuruTheme.spacingL),
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.06),
          Colors.transparent,
        ],
      ),
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: NuruColors.nightTextMuted,
      letterSpacing: 0.8,
    ),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: NuruColors.nightElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Stars painter ─────────────────────────────────────────────

class _ProfileStarsPainter extends CustomPainter {
  final double t;
  const _ProfileStarsPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    const s = [
      [0.08, 0.05],
      [0.22, 0.12],
      [0.40, 0.08],
      [0.58, 0.15],
      [0.72, 0.06],
      [0.88, 0.11],
      [0.14, 0.30],
      [0.35, 0.38],
      [0.55, 0.28],
      [0.75, 0.35],
      [0.92, 0.28],
      [0.20, 0.55],
      [0.48, 0.60],
      [0.68, 0.52],
      [0.85, 0.62],
      [0.10, 0.75],
      [0.38, 0.80],
      [0.62, 0.72],
      [0.80, 0.82],
      [0.95, 0.70],
      [0.03, 0.18],
      [0.17, 0.42],
      [0.30, 0.65],
      [0.44, 0.22],
      [0.52, 0.78],
      [0.66, 0.44],
      [0.79, 0.58],
      [0.91, 0.38],
      [0.06, 0.88],
      [0.25, 0.92],
      [0.57, 0.95],
      [0.83, 0.90],
    ];
    for (final st in s) {
      final x = size.width * st[0];
      final y = size.height * st[1];
      final off = (st[0] + st[1]) % 1.0;
      final op = 0.45 + ((t + off) % 1.0) * 0.55;
      p.color = Colors.white.withOpacity(op * 0.15);
      canvas.drawCircle(Offset(x, y), 4.0, p);
      p.color = Colors.white.withOpacity(op * 0.30);
      canvas.drawCircle(Offset(x, y), 2.5, p);
      p.color = Colors.white.withOpacity(op * 0.75);
      canvas.drawCircle(Offset(x, y), 1.4, p);
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_ProfileStarsPainter o) => o.t != t;
}
