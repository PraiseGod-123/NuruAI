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
// PROFILE SCREEN
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

    _registerFCMToken();

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

  // Header

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

  //  Avatar

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

  // Personal info

  Widget _buildPersonalInfoCard() {
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

  // Caregiver

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

  //  Notifications

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
                if (_moodReminders)
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
          // Mood
          _switchTile(
            Icons.mood_outlined,
            'Mood Reminders',
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

  //  Appearance

  Widget _buildAppearanceCard() {
    final themeProvider = context.watch<NuruThemeProvider>();
    final textProvider = context.watch<TextSizeProvider>();
    return Container(
      decoration: NuruTheme.darkCard(),
      child: Column(
        children: [
          // Dark / Light mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeProvider.activeTheme.accentColor.withOpacity(
                      0.15,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: themeProvider.activeTheme.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Display Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        themeProvider.isDark ? 'Dark mode' : 'Light mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    themeProvider.toggleBrightness();
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 28,
                    decoration: BoxDecoration(
                      color: themeProvider.isDark
                          ? Colors.white.withOpacity(0.15)
                          : themeProvider.activeTheme.accentColor.withOpacity(
                              0.8,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: themeProvider.isDark ? 2 : 26,
                          top: 2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                themeProvider.isDark
                                    ? Icons.nightlight_round
                                    : Icons.wb_sunny_rounded,
                                size: 14,
                                color: themeProvider.isDark
                                    ? const Color(0xFF1A2D5A)
                                    : const Color(0xFFE87040),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _cardDivider(),
          _arrowTile(
            Icons.palette_outlined,
            'Theme',
            themeProvider.selectedPalette.name,
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

  // Support

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

  // Logout

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

  // Reminder time picker

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
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeTile(
    BuildContext ctx,
    String label,
    TimeOfDay time,
    Future<void> Function(TimeOfDay) onPick,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: ctx,
          initialTime: time,
          builder: (c, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: NuruColors.sailingBlue,
                surface: Color(0xFF1F3F74),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) await onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              time.format(ctx),
              style: const TextStyle(
                fontSize: 14,
                color: NuruColors.sailingBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Theme picker (UPDATED — full color palette grid) ──────

  void _showThemePicker() {
    final provider = context.read<NuruThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: NuruColors.nightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _ThemePickerSheet(onDone: () => setState(() {})),
      ),
    );
  }

  // Text size picker

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
                  'Adjust the text size across the app',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final entry in [
                      ('Small', 0.85),
                      ('Default', 1.0),
                      ('Large', 1.15),
                      ('XL', 1.3),
                    ])
                      GestureDetector(
                        onTap: () {
                          provider.setScale(entry.$2);
                          setSheet(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: (provider.scale - entry.$2).abs() < 0.05
                                ? NuruColors.sailingBlue.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
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

  // Edit profile sheet

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _name);
    final ageCtrl = TextEditingController(text: _age.toString());

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
              const SizedBox(height: 20),
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

  //  Add / edit caregiver sheet

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
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF1F3F74),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type (Parent, Doctor…)',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
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
                    ),
                    items: types
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.toLowerCase(),
                            child: Text(t),
                          ),
                        )
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
                  const SizedBox(height: 20),
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

  // Privacy & Security

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
            child: SingleChildScrollView(
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
                  Text(
                    'Change your password below',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _passwordField(
                    'Current Password',
                    currentCtrl,
                    obscureCurrent,
                    () => setSheetState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    'New Password',
                    newCtrl,
                    obscureNew,
                    () => setSheetState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    'Confirm New Password',
                    confirmCtrl,
                    obscureConfirm,
                    () => setSheetState(() => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 20),
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
                              _showSnack('Passwords do not match');
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
                              final cred = EmailAuthProvider.credential(
                                email: _email,
                                password: currentCtrl.text,
                              );
                              await user?.reauthenticateWithCredential(cred);
                              await user?.updatePassword(newCtrl.text);
                              if (mounted) Navigator.pop(context);
                              _showSnack('Password updated');
                            } catch (e) {
                              _showSnack('Error: ${e.toString()}');
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
      ),
    );
  }

  // Help & Support

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
        initialChildSize: 0.65,
        maxChildSize: 0.92,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Help & Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final faq in faqs) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq['q']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            faq['a']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // About dialog

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
              style: TextStyle(color: NuruColors.sailingBlue, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              'NuruAI is a mental wellness companion designed for people with autism and ADHD. We help you track your mood, journal your thoughts, and access calming tools — all in one place.',
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

  //  Logout dialog

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
          style: TextStyle(color: Colors.white.withOpacity(0.65)),
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
              Navigator.pop(context);
              await NuruFirebaseService.instance.logout();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            child: Text(
              'Log Out',
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

  // Edit name dialog

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
                await NuruFirebaseService.instance.currentUser
                    ?.updateDisplayName(newName);
              }
              _showSnack('Name updated');
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TILE HELPERS
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

  Widget _switchTile(
    IconData icon,
    String title,
    String sub,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
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
            activeColor: NuruColors.sailingBlue,
            activeTrackColor: NuruColors.sailingBlue.withOpacity(0.3),
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

  // Sheet helpers

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

// ══════════════════════════════════════════════════════════════
// THEME PICKER SHEET — full palette grid + brightness toggle
// ══════════════════════════════════════════════════════════════

class _ThemePickerSheet extends StatelessWidget {
  final VoidCallback onDone;
  const _ThemePickerSheet({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NuruThemeProvider>();
    final selectedId = provider.selectedPalette.id;
    final isDark = provider.isDark;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          // Handle
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
          // Title
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pick a colour palette, then choose light or dark',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                // Brightness row
                _sheetSectionLabel('BRIGHTNESS'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BrightnessTile(
                        label: 'Light',
                        subtitle: 'Original style',
                        icon: Icons.wb_sunny_rounded,
                        isSelected: !isDark,
                        accentColor: provider.activeTheme.accentColor,
                        gradientColors: provider.selectedPalette.lightGradient,
                        onTap: () => provider.setTheme('nuru_light'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BrightnessTile(
                        label: 'Dark',
                        subtitle: 'Deeper tones',
                        icon: Icons.nightlight_round,
                        isSelected: isDark,
                        accentColor: provider.activeTheme.accentColor,
                        gradientColors: provider.selectedPalette.darkGradient,
                        onTap: () => provider.setTheme('nuru_dark'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Palette grid
                _sheetSectionLabel('COLOR PALETTE'),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: allColorPalettes.length,
                  itemBuilder: (_, i) {
                    final palette = allColorPalettes[i];
                    final isSelected = palette.id == selectedId;
                    return GestureDetector(
                      onTap: () => provider.setColorPalette(palette.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            isSelected ? 0.10 : 0.04,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? palette.accentColor.withOpacity(0.75)
                                : Colors.white.withOpacity(0.08),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: palette.accentColor.withOpacity(
                                      0.28,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 48,
                              margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: palette.lightGradient,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              palette.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                palette.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Colors.white.withOpacity(
                                    isSelected ? 1.0 : 0.6,
                                  ),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Reset button
                if (selectedId != 'nuru_default' || isDark) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => provider.resetToDefault(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reset to Nuru Default',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Done button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onDone();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          provider.activeTheme.accentColor,
                          provider.activeTheme.accentColor.withOpacity(0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: provider.activeTheme.accentColor.withOpacity(
                            0.30,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.45),
        letterSpacing: 1.1,
      ),
    ),
  );
}

// Brightness tile

class _BrightnessTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _BrightnessTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor.withOpacity(0.7)
                : Colors.white.withOpacity(0.10),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stars painter

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
