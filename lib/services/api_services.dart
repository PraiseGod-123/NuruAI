import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════════════════════
// NuruAI API Service
// ══════════════════════════════════════════════════════════════════════════════

class EmotionResult {
  final bool success;
  final String emotion;
  final double confidence;
  final Map<String, double> allEmotions;
  final String supportTool;
  final String supportMessage;
  final String? error;

  const EmotionResult({
    required this.success,
    required this.emotion,
    required this.confidence,
    required this.allEmotions,
    required this.supportTool,
    required this.supportMessage,
    this.error,
  });

  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    final support = json['support'] as Map<String, dynamic>? ?? {};
    final allEmotions = <String, double>{};
    final raw = json['all_emotions'] as Map<String, dynamic>? ?? {};
    raw.forEach((k, v) => allEmotions[k] = (v as num).toDouble());
    return EmotionResult(
      success: json['success'] as bool? ?? false,
      emotion: json['emotion'] as String? ?? 'neutral',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      allEmotions: allEmotions,
      supportTool: support['tool'] as String? ?? 'breathing',
      supportMessage: support['message'] as String? ?? '',
      error: json['message'] as String?,
    );
  }

  factory EmotionResult.error(String message) => EmotionResult(
    success: false,
    emotion: 'neutral',
    confidence: 0.0,
    allEmotions: {},
    supportTool: 'breathing',
    supportMessage: '',
    error: message,
  );
}

class LoginResult {
  final bool success;
  final bool authenticated;
  final double similarity;
  final EmotionResult? emotionResult;
  final String message;

  const LoginResult({
    required this.success,
    required this.authenticated,
    required this.similarity,
    this.emotionResult,
    required this.message,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    success: json['success'] as bool? ?? false,
    authenticated: json['authenticated'] as bool? ?? false,
    similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
    emotionResult: json['emotion'] != null
        ? EmotionResult.fromJson(json)
        : null,
    message: json['message'] as String? ?? '',
  );

  factory LoginResult.error(String message) => LoginResult(
    success: false,
    authenticated: false,
    similarity: 0.0,
    message: message,
  );
}

class BaselineResult {
  final bool success;
  final int numSamples;
  final String message;

  const BaselineResult({
    required this.success,
    required this.numSamples,
    required this.message,
  });

  factory BaselineResult.fromJson(Map<String, dynamic> json) => BaselineResult(
    success: json['success'] as bool? ?? false,
    numSamples: json['num_samples'] as int? ?? 0,
    message: json['message'] as String? ?? '',
  );

  factory BaselineResult.error(String message) =>
      BaselineResult(success: false, numSamples: 0, message: message);
}

// ── Service ───────────────────────────────────────────────────────────────────

class NuruApiService {
  NuruApiService._();
  static final NuruApiService instance = NuruApiService._();

  static const String baseUrl =
      'https://interlunar-unspinnable-carola.ngrok-free.dev';
  static const Duration _timeout = Duration(seconds: 30);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  // ── Health ────────────────────────────────────────────────────────────────

  Future<bool> isReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: _headers)
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Baseline ──────────────────────────────────────────────────────────────

  Future<BaselineResult> setupBaseline({
    required String userId,
    required List<String> images,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/setup_baseline'),
            headers: _headers,
            body: jsonEncode({'user_id': userId, 'images': images}),
          )
          .timeout(_timeout);
      return BaselineResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      return BaselineResult.error('Cannot reach the server.');
    } on TimeoutException {
      return BaselineResult.error('Request timed out.');
    } catch (e) {
      return BaselineResult.error('Something went wrong: $e');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<LoginResult> login({
    required String userId,
    required String imageBase64,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({'user_id': userId, 'image': imageBase64}),
          )
          .timeout(_timeout);
      return LoginResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      return LoginResult.error('Cannot reach the server.');
    } on TimeoutException {
      return LoginResult.error('Request timed out.');
    } catch (e) {
      return LoginResult.error('Something went wrong: $e');
    }
  }

  // ── Detect emotion ────────────────────────────────────────────────────────

  Future<EmotionResult> detectEmotion({
    required String userId,
    required String imageBase64,
    String trigger = 'manual',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/detect_emotion'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'image': imageBase64,
              'trigger': trigger,
            }),
          )
          .timeout(_timeout);
      return EmotionResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      return EmotionResult.error('Cannot reach the server.');
    } on TimeoutException {
      return EmotionResult.error('Request timed out.');
    } catch (e) {
      return EmotionResult.error('Something went wrong: $e');
    }
  }

  // ── Log mood ──────────────────────────────────────────────────────────────

  Future<bool> logMood({required String userId, required String mood}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/log_mood'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'mood': mood,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);
      return (jsonDecode(response.body) as Map<String, dynamic>)['success']
              as bool? ??
          false;
    } catch (e) {
      debugPrint('logMood error: $e');
      return false;
    }
  }

  // ── Log journal ───────────────────────────────────────────────────────────

  Future<bool> logJournal({
    required String userId,
    String? mood,
    String? title,
    int wordCount = 0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/log_journal'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'mood': mood,
              'title': title,
              'word_count': wordCount,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);
      return (jsonDecode(response.body) as Map<String, dynamic>)['success']
              as bool? ??
          false;
    } catch (e) {
      debugPrint('logJournal error: $e');
      return false;
    }
  }

  // ── Log chat ──────────────────────────────────────────────────────────────

  Future<bool> logChat({
    required String userId,
    int messageCount = 0,
    String? topic,
    int durationSecs = 0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/log_chat'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'message_count': messageCount,
              'topic': topic,
              'duration_secs': durationSecs,
            }),
          )
          .timeout(_timeout);
      return (jsonDecode(response.body) as Map<String, dynamic>)['success']
              as bool? ??
          false;
    } catch (e) {
      debugPrint('logChat error: $e');
      return false;
    }
  }

  // ── Emotion history ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEmotionHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/emotion_history').replace(
        queryParameters: {'user_id': userId, 'limit': limit.toString()},
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] != true) return [];
      return (json['history'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('getEmotionHistory error: $e');
      return [];
    }
  }

  // ── Register FCM token ────────────────────────────────────────────────────
  // Sends the device's FCM token to Flask so the backend can push notifications.
  // Call this after Firebase.initializeApp() and NuruNotificationService.init().

  Future<bool> registerFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register_fcm_token'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'fcm_token': fcmToken,
              'platform': Platform.isAndroid ? 'android' : 'ios',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('FCM token registered: ${json['success']}');
      return json['success'] as bool? ?? false;
    } catch (e) {
      debugPrint('registerFCMToken error: $e');
      return false;
    }
  }

  // ── Send notification via Flask ───────────────────────────────────────────
  // Triggers a push notification from the server to a specific user.
  // The Flask backend looks up the user's FCM token and sends via FCM.

  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/send_notification'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'body': body,
              'data': data,
            }),
          )
          .timeout(_timeout);
      return (jsonDecode(response.body) as Map<String, dynamic>)['success']
              as bool? ??
          false;
    } catch (e) {
      debugPrint('sendPushNotification error: $e');
      return false;
    }
  }
}
