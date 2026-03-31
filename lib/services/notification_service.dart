import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ══════════════════════════════════════════════════════════════
// NURU NOTIFICATION SERVICE
//
// Handles both:
//   1. On-device scheduled notifications (flutter_local_notifications)
//   2. FCM push notifications from Flask backend
//
// Usage:
//   await NuruNotificationService.instance.init();
//   await NuruNotificationService.instance.scheduleDailyMoodReminder(hour: 9, minute: 0);
//   await NuruNotificationService.instance.scheduleJournalReminder(hour: 20, minute: 0);
//   await NuruNotificationService.instance.scheduleStreakReminder(hour: 21, minute: 0);
// ══════════════════════════════════════════════════════════════

// Background FCM handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NuruNotificationService.instance.showFCMNotification(message);
}

class NuruNotificationService {
  NuruNotificationService._();
  static final instance = NuruNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _fcm = FirebaseMessaging.instance;

  // Notification channel IDs
  static const _channelId = 'nuru_reminders';
  static const _channelName = 'NuruAI Reminders';
  static const _channelDesc = 'Daily mood, journal and streak reminders';
  static const _fcmChannelId = 'nuru_fcm';
  static const _fcmChannelName = 'NuruAI Updates';

  // Notification IDs
  static const int moodId = 1001;
  static const int moodEveningId = 1004;
  static const int journalId = 1002;
  static const int streakId = 1003;
  static const int streakMorningId = 1005;

  bool _initialised = false;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Initialise timezones
    tz.initializeTimeZones();

    // ── Local notifications setup ─────────────────────────────────────────────
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    await _createChannel(_channelId, _channelName, _channelDesc);
    await _createChannel(
      _fcmChannelId,
      _fcmChannelName,
      'Push updates from NuruAI',
    );

    // ── FCM setup ─────────────────────────────────────────────────────────────
    await _setupFCM();

    debugPrint('NuruNotificationService: initialised ✓');
  }

  // ── FCM ──────────────────────────────────────────────────────────────────────

  Future<void> _setupFCM() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('NuruNotifications: FCM permission denied');
      return;
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFCMNotification(message);
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationOpen(message.data);
    });

    // Get and store FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // TODO: send this token to your Flask backend so it can target this device
      // await ApiService.instance.registerFCMToken(token);
    }

    // Token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      // TODO: update token on Flask backend
    });
  }

  // Get FCM token (call after init — send to Flask backend)
  Future<String?> getFCMToken() => _fcm.getToken();

  // Show notification from FCM message
  Future<void> showFCMNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _fcmChannelId,
      _fcmChannelName,
      channelDescription: 'Push updates from NuruAI',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        summaryText: 'NuruAI',
      ),
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  // ── Scheduled local notifications ─────────────────────────────────────────

  /// Daily mood check-in — e.g. 9:00 AM
  Future<void> scheduleDailyMoodReminder({
    required int hour,
    required int minute,
  }) async {
    await _cancelIfExists(moodId);
    await _localNotifications.zonedSchedule(
      moodId,
      '🌟 How are you feeling today?',
      'Take a moment to check in with yourself. Your wellbeing matters.',
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            'Take a moment to check in with yourself. Your wellbeing matters.',
            summaryText: 'NuruAI Daily Check-in',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Daily mood check-in',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      payload: 'mood_checkin',
    );
    debugPrint(
      'Mood reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
    );
  }

  /// Evening mood check-in — e.g. 8:00 PM
  Future<void> scheduleEveningMoodReminder({
    required int hour,
    required int minute,
  }) async {
    await _cancelIfExists(moodEveningId);
    await _localNotifications.zonedSchedule(
      moodEveningId,
      '🌙 Evening check-in',
      'How did your day go? Take a moment to log your mood.',
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            'How did your day go? Take a moment to log your mood.',
            summaryText: 'NuruAI Evening Check-in',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Evening mood check-in',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'mood_checkin_evening',
    );
    debugPrint(
      'Evening mood reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
    );
  }

  /// Evening journal reminder — e.g. 8:00 PM
  Future<void> scheduleJournalReminder({
    required int hour,
    required int minute,
  }) async {
    await _cancelIfExists(journalId);
    await _localNotifications.zonedSchedule(
      journalId,
      '📓 Time to journal',
      'Writing about your day helps process emotions and build self-awareness.',
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Journal reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'journal_reminder',
    );
    debugPrint(
      'Journal reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
    );
  }

  /// Streak reminder — fires if user hasn't checked in by e.g. 9:00 PM
  Future<void> scheduleStreakReminder({
    required int hour,
    required int minute,
  }) async {
    await _cancelIfExists(streakId);
    await _localNotifications.zonedSchedule(
      streakId,
      '🔥 Don\'t break your streak!',
      'You\'re on a roll — take just 2 minutes to check in today.',
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            'You\'re on a roll — take just 2 minutes to check in today.',
            summaryText: 'NuruAI Streak',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Streak reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak_reminder',
    );
    debugPrint(
      'Streak reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
    );
  }

  /// Morning streak reminder — e.g. 8:00 AM
  Future<void> scheduleMorningStreakReminder({
    required int hour,
    required int minute,
  }) async {
    await _cancelIfExists(streakMorningId);
    await _localNotifications.zonedSchedule(
      streakMorningId,
      '🔥 Keep your streak going!',
      "Good morning! Don't forget to check in today and keep your streak alive.",
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            "Good morning! Don't forget to check in today and keep your streak alive.",
            summaryText: 'NuruAI Streak',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Morning streak reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak_reminder_morning',
    );
    debugPrint(
      'Morning streak reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
    );
  }

  /// Schedule all defaults at once (call after login)
  Future<void> scheduleAllDefaults() async {
    await scheduleDailyMoodReminder(hour: 9, minute: 0);
    await scheduleJournalReminder(hour: 20, minute: 0);
    await scheduleStreakReminder(hour: 21, minute: 0);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _createChannel(String id, String name, String desc) async {
    if (!Platform.isAndroid) return;
    final channel = AndroidNotificationChannel(
      id,
      name,
      description: desc,
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFF4569AD),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _cancelIfExists(int id) async {
    await _localNotifications.cancel(id);
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped: $payload');
    // Navigation is handled by the app's NavigatorKey
    // You can use a global navigatorKey to push routes here
  }

  void _handleNotificationOpen(Map<String, dynamic> data) {
    debugPrint('App opened from FCM notification: $data');
  }
}
