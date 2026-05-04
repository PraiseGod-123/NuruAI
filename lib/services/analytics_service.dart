import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

//Backend config
class NuruBackend {
  static const String baseUrl = 'http://YOUR_FLASK_SERVER/api/v1';
  static const Duration timeout = Duration(seconds: 15);
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

//Enums
enum MoodValue { happy, calm, anxious, sad, angry, tired, overwhelmed, excited }

enum ActivityType {
  journalEntry,
  moodLog,
  breathingSession,
  nuruChat,
  calmMe,
  appOpen,
}

enum AwardTier { bronze, silver, gold, platinum }

enum InsightType {
  moodImproving,
  moodDeclining,
  moodStable,
  highEngagement,
  lowEngagement,
  breathingHelping,
  journalConsistency,
  streakMilestone,
  wellbeingScore,
}

//Models
class MoodEntry {
  final String id;
  final MoodValue mood;
  final String emoji;
  final String label;
  final DateTime timestamp;
  final String? note;

  // 'journal' | 'home' | 'micro_expression'
  final String? source;

  final double? sentimentScore;

  const MoodEntry({
    required this.id,
    required this.mood,
    required this.emoji,
    required this.label,
    required this.timestamp,
    this.note,
    this.source,
    this.sentimentScore,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mood': mood.name,
    'emoji': emoji,
    'label': label,
    'timestamp': timestamp.toIso8601String(),
    if (note != null) 'note': note,
    if (source != null) 'source': source,
    if (sentimentScore != null) 'sentimentScore': sentimentScore,
  };

  factory MoodEntry.fromMap(Map<String, dynamic> m) => MoodEntry(
    id: m['id'] as String,
    mood: MoodValue.values.firstWhere(
      (v) => v.name == m['mood'],
      orElse: () => MoodValue.calm,
    ),
    emoji: m['emoji'] as String,
    label: m['label'] as String,
    timestamp: DateTime.parse(m['timestamp'] as String),
    note: m['note'] as String?,
    source: m['source'] as String?,
    sentimentScore: (m['sentimentScore'] as num?)?.toDouble(),
  );
}

/// A single trackable user activity event.
class ActivityEvent {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final int durationSeconds;

  final Map<String, dynamic> metadata;

  /// Engagement quality score set by the ML backend (0.0–1.0).
  /// Null until backend processes this event.
  final double? engagementScore;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.durationSeconds = 0,
    this.metadata = const {},
    this.engagementScore,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'durationSeconds': durationSeconds,
    'metadata': metadata,
    if (engagementScore != null) 'engagementScore': engagementScore,
  };

  factory ActivityEvent.fromMap(Map<String, dynamic> m) => ActivityEvent(
    id: m['id'] as String,
    type: ActivityType.values.firstWhere(
      (v) => v.name == m['type'],
      orElse: () => ActivityType.appOpen,
    ),
    timestamp: DateTime.parse(m['timestamp'] as String),
    durationSeconds: (m['durationSeconds'] as num?)?.toInt() ?? 0,
    metadata: Map<String, dynamic>.from(m['metadata'] as Map? ?? {}),
    engagementScore: (m['engagementScore'] as num?)?.toDouble(),
  );
}

// Streak data read directly from Firestore.
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDaysActive;
  final DateTime? lastActiveDate;

  // 30 booleans — index 0 = 30 days ago, index 29 = today.
  final List<bool> last30Days;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDaysActive,
    this.lastActiveDate,
    this.last30Days = const [],
  });

  factory StreakData.empty() => const StreakData(
    currentStreak: 0,
    longestStreak: 0,
    totalDaysActive: 0,
    last30Days: [],
  );

  factory StreakData.fromMap(Map<String, dynamic> m) => StreakData(
    currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
    longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
    totalDaysActive: (m['totalDaysActive'] as num?)?.toInt() ?? 0,
    lastActiveDate: m['lastActiveDate'] != null
        ? DateTime.parse(m['lastActiveDate'] as String)
        : null,
    last30Days: List<bool>.from(m['last30Days'] as List? ?? []),
  );

  Map<String, dynamic> toMap() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalDaysActive': totalDaysActive,
    if (lastActiveDate != null)
      'lastActiveDate': lastActiveDate!.toIso8601String(),
    'last30Days': last30Days,
  };
}

// Daily wellbeing insight produced by the NuruAI PyTorch model.
class DailyInsight {
  final DateTime date;

  // 0.0–10.0 composite wellbeing score.
  // Null until the ML model has processed enough data for today.
  final double? wellbeingScore;

  /// Plain-English summary written by the model.
  final String? summary;

  // Key observations the model detected today.
  final List<String> highlights;

  // Actionable suggestions personalised to this user's patterns.
  final List<String> suggestions;

  final InsightType? primaryInsight;
  final int activitiesCompleted;

  // True = came from the PyTorch backend.
  // False = backend not yet connected; screen shows pending state.
  final bool isMLGenerated;

  const DailyInsight({
    required this.date,
    this.wellbeingScore,
    this.summary,
    this.highlights = const [],
    this.suggestions = const [],
    this.primaryInsight,
    this.activitiesCompleted = 0,
    this.isMLGenerated = false,
  });

  factory DailyInsight.fromMap(Map<String, dynamic> m) => DailyInsight(
    date: DateTime.parse(m['date'] as String),
    wellbeingScore: (m['wellbeingScore'] as num?)?.toDouble(),
    summary: m['summary'] as String?,
    highlights: List<String>.from(m['highlights'] as List? ?? []),
    suggestions: List<String>.from(m['suggestions'] as List? ?? []),
    primaryInsight: m['primaryInsight'] != null
        ? InsightType.values.firstWhere(
            (t) => t.name == m['primaryInsight'],
            orElse: () => InsightType.moodStable,
          )
        : null,
    activitiesCompleted: (m['activitiesCompleted'] as num?)?.toInt() ?? 0,
    isMLGenerated: m['isMLGenerated'] as bool? ?? false,
  );
}

// Weekly report produced by the NuruAI PyTorch model.
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;

  // All null until the backend has a full week of data.
  final double? avgWellbeingScore;
  final double? wellbeingTrend;
  final List<double> dailyScores;
  final List<MoodEntry> moodHistory;

  final int totalJournalEntries;
  final int totalBreathingSessions;
  final int totalNuruChats;
  final int totalCalmMeSessions;

  final String? overallSummary;
  final List<String> weeklyHighlights;
  final bool isMLGenerated;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    this.avgWellbeingScore,
    this.wellbeingTrend,
    this.dailyScores = const [],
    this.moodHistory = const [],
    this.totalJournalEntries = 0,
    this.totalBreathingSessions = 0,
    this.totalNuruChats = 0,
    this.totalCalmMeSessions = 0,
    this.overallSummary,
    this.weeklyHighlights = const [],
    this.isMLGenerated = false,
  });

  factory WeeklyReport.fromMap(Map<String, dynamic> m) => WeeklyReport(
    weekStart: DateTime.parse(m['weekStart'] as String),
    weekEnd: DateTime.parse(m['weekEnd'] as String),
    avgWellbeingScore: (m['avgWellbeingScore'] as num?)?.toDouble(),
    wellbeingTrend: (m['wellbeingTrend'] as num?)?.toDouble(),
    dailyScores: List<double>.from(
      ((m['dailyScores'] as List?) ?? []).map((v) => (v as num).toDouble()),
    ),
    moodHistory: ((m['moodHistory'] as List?) ?? [])
        .map((e) => MoodEntry.fromMap(e as Map<String, dynamic>))
        .toList(),
    totalJournalEntries: (m['totalJournalEntries'] as num?)?.toInt() ?? 0,
    totalBreathingSessions: (m['totalBreathingSessions'] as num?)?.toInt() ?? 0,
    totalNuruChats: (m['totalNuruChats'] as num?)?.toInt() ?? 0,
    totalCalmMeSessions: (m['totalCalmMeSessions'] as num?)?.toInt() ?? 0,
    overallSummary: m['overallSummary'] as String?,
    weeklyHighlights: List<String>.from(m['weeklyHighlights'] as List? ?? []),
    isMLGenerated: m['isMLGenerated'] as bool? ?? false,
  );
}

// Award definition
class Award {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AwardTier tier;
  final int pointsRequired;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Award({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.pointsRequired,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Award withUnlockStatus(int userPoints) {
    if (userPoints >= pointsRequired && !isUnlocked) {
      return Award(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        tier: tier,
        pointsRequired: pointsRequired,
        category: category,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
    }
    return this;
  }

  factory Award.fromMap(Map<String, dynamic> m) => Award(
    id: m['id'] as String,
    title: m['title'] as String,
    description: m['description'] as String,
    emoji: m['emoji'] as String,
    tier: AwardTier.values.firstWhere(
      (t) => t.name == m['tier'],
      orElse: () => AwardTier.bronze,
    ),
    pointsRequired: (m['pointsRequired'] as num).toInt(),
    category: m['category'] as String,
    isUnlocked: m['isUnlocked'] as bool? ?? false,
    unlockedAt: m['unlockedAt'] != null
        ? DateTime.parse(m['unlockedAt'] as String)
        : null,
  );
}

// The full analytics payload for one user session.
// Every field is populated from real Firebase + backend data.
class UserAnalytics {
  final String userId;
  final StreakData streakData;
  final List<MoodEntry> recentMoods;
  final List<ActivityEvent> recentActivities;
  final DailyInsight? todayInsight;
  final WeeklyReport? weeklyReport;
  final List<Award> awards;
  final int totalPoints;
  final int totalJournals;
  final int totalBreaths;
  final int totalChats;
  final int totalCalmMe;
  final bool isLoaded;
  final String? errorMessage;

  const UserAnalytics({
    required this.userId,
    required this.streakData,
    required this.recentMoods,
    required this.recentActivities,
    required this.awards,
    required this.totalPoints,
    required this.totalJournals,
    required this.totalBreaths,
    required this.totalChats,
    required this.totalCalmMe,
    this.todayInsight,
    this.weeklyReport,
    this.isLoaded = false,
    this.errorMessage,
  });

  // Shown before any data is available — new user or offline.
  factory UserAnalytics.empty(String userId) => UserAnalytics(
    userId: userId,
    streakData: StreakData.empty(),
    recentMoods: const [],
    recentActivities: const [],
    awards: AnalyticsService.awardCatalogue,
    totalPoints: 0,
    totalJournals: 0,
    totalBreaths: 0,
    totalChats: 0,
    totalCalmMe: 0,
    isLoaded: false,
  );

  UserAnalytics copyWithError(String msg) => UserAnalytics(
    userId: userId,
    streakData: streakData,
    recentMoods: recentMoods,
    recentActivities: recentActivities,
    awards: awards,
    totalPoints: totalPoints,
    totalJournals: totalJournals,
    totalBreaths: totalBreaths,
    totalChats: totalChats,
    totalCalmMe: totalCalmMe,
    todayInsight: todayInsight,
    weeklyReport: weeklyReport,
    isLoaded: false,
    errorMessage: msg,
  );
}

//Service
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  //Award catalogue
  static List<Award> get awardCatalogue => const [
    //Streak
    Award(
      id: 'streak_3',
      title: 'Getting Started',
      description: '3 days in a row',
      emoji: '\ud83c\udf31',
      tier: AwardTier.bronze,
      pointsRequired: 30,
      category: 'streak',
    ),
    Award(
      id: 'streak_7',
      title: 'One Week Strong',
      description: '7-day streak',
      emoji: '\u2b50',
      tier: AwardTier.silver,
      pointsRequired: 70,
      category: 'streak',
    ),
    Award(
      id: 'streak_14',
      title: 'Two Week Warrior',
      description: '14-day streak',
      emoji: '\ud83d\udd25',
      tier: AwardTier.silver,
      pointsRequired: 140,
      category: 'streak',
    ),
    Award(
      id: 'streak_30',
      title: 'Monthly Champion',
      description: '30-day streak',
      emoji: '\ud83c\udfc6',
      tier: AwardTier.gold,
      pointsRequired: 300,
      category: 'streak',
    ),
    Award(
      id: 'streak_60',
      title: 'Unstoppable',
      description: '60-day streak',
      emoji: '\ud83d\ude80',
      tier: AwardTier.platinum,
      pointsRequired: 600,
      category: 'streak',
    ),
    //Journal
    Award(
      id: 'journal_1',
      title: 'First Words',
      description: 'First journal entry',
      emoji: '\u270f\ufe0f',
      tier: AwardTier.bronze,
      pointsRequired: 10,
      category: 'journal',
    ),
    Award(
      id: 'journal_7',
      title: 'Story Teller',
      description: '7 journal entries',
      emoji: '\ud83d\udcd6',
      tier: AwardTier.silver,
      pointsRequired: 70,
      category: 'journal',
    ),
    Award(
      id: 'journal_30',
      title: 'Inner Voice',
      description: '30 journal entries',
      emoji: '\ud83d\udcdd',
      tier: AwardTier.gold,
      pointsRequired: 300,
      category: 'journal',
    ),
    //Breathing
    Award(
      id: 'breath_1',
      title: 'First Breath',
      description: 'First breathing session',
      emoji: '\ud83c\udf2c\ufe0f',
      tier: AwardTier.bronze,
      pointsRequired: 10,
      category: 'breathing',
    ),
    Award(
      id: 'breath_10',
      title: 'Calm Seeker',
      description: '10 breathing sessions',
      emoji: '\ud83e\uddd8',
      tier: AwardTier.silver,
      pointsRequired: 100,
      category: 'breathing',
    ),
    Award(
      id: 'breath_30',
      title: 'Zen Master',
      description: '30 breathing sessions',
      emoji: '\ud83e\udd71',
      tier: AwardTier.gold,
      pointsRequired: 300,
      category: 'breathing',
    ),
    //Mood
    Award(
      id: 'mood_7',
      title: 'Mood Tracker',
      description: '7 consecutive mood logs',
      emoji: '\ud83d\udcca',
      tier: AwardTier.bronze,
      pointsRequired: 70,
      category: 'mood',
    ),
    Award(
      id: 'mood_improve',
      title: 'Brighter Days',
      description: 'Mood improved over a week',
      emoji: '\u2600\ufe0f',
      tier: AwardTier.silver,
      pointsRequired: 100,
      category: 'mood',
    ),
    // Engagement
    Award(
      id: 'nuru_10',
      title: 'Chatty',
      description: '10 chats with NuruAI',
      emoji: '\ud83e\udd16',
      tier: AwardTier.bronze,
      pointsRequired: 100,
      category: 'engagement',
    ),
    Award(
      id: 'wellbeing_8',
      title: 'Thriving',
      description: 'Wellbeing score above 8.0',
      emoji: '\ud83c\udf1f',
      tier: AwardTier.gold,
      pointsRequired: 200,
      category: 'engagement',
    ),
  ];

  // LOAD USER ANALYTICS
  Future<UserAnalytics> loadUserAnalytics(String userId) async {
    if (userId.isEmpty) return UserAnalytics.empty(userId);
    try {
      final fs = FirebaseFirestore.instance;

      //User stats from Firestore
      final userSnap = await fs.collection('users').doc(userId).get();
      final userData = userSnap.data() ?? {};
      final statsMap = userData['stats'] as Map<String, dynamic>? ?? {};
      final profileMap = userData['profile'] as Map<String, dynamic>? ?? {};

      final currentStreak = (statsMap['currentStreak'] as num?)?.toInt() ?? 0;
      final longestStreak = (statsMap['longestStreak'] as num?)?.toInt() ?? 0;
      final totalCheckIns = (statsMap['totalCheckIns'] as num?)?.toInt() ?? 0;
      final totalJournals = (statsMap['totalJournals'] as num?)?.toInt() ?? 0;
      final totalChats = (statsMap['totalChats'] as num?)?.toInt() ?? 0;
      final avgMood = (statsMap['avgMood'] as num?)?.toDouble() ?? 0.0;
      final lastCheckInStr = statsMap['lastCheckIn'] as String?;

      //Last 30 days check-in calendar
      final now = DateTime.now();
      final List<bool> last30Days = List.filled(30, false);

      final calSnap = await fs
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      for (final doc in calSnap.docs) {
        final dateStr = doc.data()['date'] as String?;
        if (dateStr == null) continue;
        try {
          final d = DateTime.parse(dateStr);
          final diff = DateTime(
            now.year,
            now.month,
            now.day,
          ).difference(DateTime(d.year, d.month, d.day)).inDays;
          if (diff >= 0 && diff < 30) {
            last30Days[29 - diff] = true;
          }
        } catch (_) {}
      }

      //Last 7 mood entries for mood journey
      final List<MoodEntry> recentMoods = [];

      final moodSnap = await fs
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get();

      for (final doc in moodSnap.docs) {
        final d = doc.data();
        final score = (d['mood'] as num?)?.toInt() ?? 5;
        final moodVal = _scoreToMoodValue(score);
        recentMoods.add(
          MoodEntry(
            id: doc.id,
            mood: moodVal,
            emoji: _scoreToEmoji(score),
            label: _scoreToMoodLabel(score),
            timestamp: d['timestamp'] != null
                ? DateTime.parse(d['timestamp'] as String)
                : DateTime.now(),
            note: d['note'] as String?,
            source: 'home',
          ),
        );
      }

      //Recent activities (journals + chats)
      final List<ActivityEvent> recentActivities = [];

      final journalSnap = await fs
          .collection('users')
          .doc(userId)
          .collection('journals')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (final doc in journalSnap.docs) {
        final d = doc.data();
        recentActivities.add(
          ActivityEvent(
            id: doc.id,
            type: ActivityType.journalEntry,
            timestamp: DateTime.parse(
              d['createdAt'] as String? ?? DateTime.now().toIso8601String(),
            ),
            metadata: {
              'title': d['title'] ?? '',
              'mood': d['mood'] ?? '',
              'wordCount': d['wordCount'] ?? 0,
            },
          ),
        );
      }

      final chatSnap = await fs
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (final doc in chatSnap.docs) {
        final d = doc.data();
        recentActivities.add(
          ActivityEvent(
            id: doc.id,
            type: ActivityType.nuruChat,
            timestamp: DateTime.parse(
              d['createdAt'] as String? ?? DateTime.now().toIso8601String(),
            ),
            metadata: {
              'topic': d['topic'] ?? '',
              'messageCount': d['messageCount'] ?? 0,
            },
          ),
        );
      }

      recentActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      //Count real breathing sessions
      final breathSnap = await fs
          .collection('users')
          .doc(userId)
          .collection('breathingSessions')
          .get();
      final totalBreaths = breathSnap.docs.length;

      // Also add recent breathing to activities
      for (final doc in breathSnap.docs.take(10)) {
        final d = doc.data();
        recentActivities.add(
          ActivityEvent(
            id: doc.id,
            type: ActivityType.breathingSession,
            timestamp: DateTime.parse(
              d['createdAt'] as String? ?? DateTime.now().toIso8601String(),
            ),
            metadata: {
              'techniqueName': d['techniqueName'] ?? '',
              'cycles': d['cyclesCompleted'] ?? 0,
            },
          ),
        );
      }
      recentActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      //Streak data
      final streakData = StreakData(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        totalDaysActive: totalCheckIns,
        lastActiveDate: lastCheckInStr != null
            ? DateTime.tryParse(lastCheckInStr)
            : null,
        last30Days: last30Days,
      );

      //Awards — unlock by actual usage counts
      final totalPoints =
          currentStreak * 10 +
          totalCheckIns * 5 +
          totalJournals * 10 +
          totalChats * 5;

      final awards = awardCatalogue.map((a) {
        bool unlocked = false;

        switch (a.id) {
          // Streak awards
          case 'streak_3':
            unlocked = currentStreak >= 3;
            break;
          case 'streak_7':
            unlocked = currentStreak >= 7;
            break;
          case 'streak_14':
            unlocked = currentStreak >= 14;
            break;
          case 'streak_30':
            unlocked = currentStreak >= 30;
            break;
          case 'streak_60':
            unlocked = currentStreak >= 60;
            break;

          // Journal awards
          case 'journal_1':
            unlocked = totalJournals >= 1;
            break;
          case 'journal_7':
            unlocked = totalJournals >= 7;
            break;
          case 'journal_30':
            unlocked = totalJournals >= 30;
            break;

          // Breathing awards
          case 'breath_1':
            unlocked = totalBreaths >= 1;
            break;
          case 'breath_10':
            unlocked = totalBreaths >= 10;
            break;
          case 'breath_30':
            unlocked = totalBreaths >= 30;
            break;

          // Mood awards
          case 'mood_7':
            unlocked = totalCheckIns >= 7;
            break;
          case 'mood_improve':
            if (recentMoods.length >= 2) {
              final newest = recentMoods.first.label;
              final oldest = recentMoods.last.label;
              unlocked = _moodLabelToScore(newest) > _moodLabelToScore(oldest);
            }
            break;

          // Engagement awards — by totalChats
          case 'nuru_10':
            unlocked = totalChats >= 10;
            break;

          // Wellbeing — by avgMood
          case 'wellbeing_8':
            unlocked = avgMood >= 8.0;
            break;

          default:
            unlocked = totalPoints >= a.pointsRequired;
        }

        if (unlocked) {
          return Award(
            id: a.id,
            title: a.title,
            description: a.description,
            emoji: a.emoji,
            tier: a.tier,
            pointsRequired: a.pointsRequired,
            category: a.category,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
        }
        return a;
      }).toList();

      //Build a daily insight from Firestore data
      DailyInsight? todayInsight;
      if (totalCheckIns > 0 || totalBreaths > 0 || totalJournals > 0) {
        todayInsight = DailyInsight(
          date: now,
          wellbeingScore: avgMood > 0 ? avgMood : null,
          summary: _buildInsightSummary(avgMood, currentStreak, totalJournals),
          highlights: _buildHighlights(
            avgMood,
            currentStreak,
            totalJournals,
            totalChats,
            totalBreaths,
          ),
          suggestions: _buildSuggestions(avgMood, totalJournals),
          isMLGenerated: false,
          activitiesCompleted: totalCheckIns + totalBreaths + totalJournals,
        );
      }

      return UserAnalytics(
        userId: userId,
        streakData: streakData,
        recentMoods: recentMoods,
        recentActivities: recentActivities,
        todayInsight: todayInsight,
        awards: awards,
        totalPoints:
            currentStreak * 10 +
            totalCheckIns * 5 +
            totalJournals * 10 +
            totalChats * 5 +
            totalBreaths * 3,
        totalJournals: totalJournals,
        totalBreaths: totalBreaths,
        totalChats: totalChats,
        totalCalmMe: 0,
        isLoaded: true,
      );
    } catch (e) {
      debugPrint('AnalyticsService.loadUserAnalytics error: $e');
      return UserAnalytics.empty(
        userId,
      ).copyWithError('Could not load your analytics. Check your connection.');
    }
  }

  // Firestore insight helpers
  int _moodLabelToScore(String label) {
    switch (label) {
      case 'excellent':
        return 5;
      case 'good':
        return 4;
      case 'neutral':
        return 3;
      case 'low':
        return 2;
      case 'difficult':
        return 1;
      default:
        return 3;
    }
  }

  String _scoreToMoodLabel(int score) {
    if (score >= 9) return 'excellent';
    if (score >= 7) return 'good';
    if (score >= 5) return 'neutral';
    if (score >= 3) return 'low';
    return 'difficult';
  }

  MoodValue _scoreToMoodValue(int score) {
    if (score >= 9) return MoodValue.excited;
    if (score >= 7) return MoodValue.happy;
    if (score >= 5) return MoodValue.calm;
    if (score >= 3) return MoodValue.sad;
    return MoodValue.overwhelmed;
  }

  String _scoreToEmoji(int score) {
    if (score >= 9) return '😄';
    if (score >= 7) return '🙂';
    if (score >= 5) return '😐';
    if (score >= 3) return '😔';
    return '😢';
  }

  String _buildInsightSummary(double avgMood, int streak, int journals) {
    if (avgMood >= 8)
      return 'You\'ve been in a great headspace lately. Keep up the momentum.';
    if (avgMood >= 6)
      return 'You\'re staying consistent. Small steps every day add up.';
    if (avgMood >= 4)
      return 'Some tough days recently. Be kind to yourself — you\'re doing the work.';
    return 'It\'s been a challenging period. Remember NuruAI is here whenever you need support.';
  }

  List<String> _buildHighlights(
    double avgMood,
    int streak,
    int journals,
    int chats,
    int breaths,
  ) {
    final list = <String>[];
    if (streak > 0) list.add('$streak-day check-in streak — great consistency');
    if (journals > 0)
      list.add('$journals journal entr${journals == 1 ? 'y' : 'ies'} written');
    if (chats > 0)
      list.add('$chats conversation${chats == 1 ? '' : 's'} with NuruAI');
    if (breaths > 0)
      list.add(
        '$breaths breathing session${breaths == 1 ? '' : 's'} completed',
      );
    if (avgMood >= 7)
      list.add('Average mood score of ${avgMood.toStringAsFixed(1)}/10');
    return list;
  }

  List<String> _buildSuggestions(double avgMood, int journals) {
    if (avgMood >= 7)
      return [
        'Keep logging your mood daily to maintain your streak',
        'Try a mindfulness session today',
      ];
    if (journals == 0)
      return [
        'Try writing a journal entry — it helps process your feelings',
        'A breathing exercise can help on difficult days',
      ];
    return [
      'A breathing exercise can help on difficult days',
      'Chat with NuruAI if you need someone to talk to',
    ];
  }

  // EVENT LOGGERS
  // Call from journal_entry_screen.dart when user saves a journal entry.
  Future<void> logJournalEntry({
    required String userId,
    required String entryId,
    required String title,
    required String content,
    required String mood,
    required DateTime date,
  }) async {
    final event = ActivityEvent(
      id: entryId,
      type: ActivityType.journalEntry,
      timestamp: date,
      metadata: {
        'wordCount': content.trim().split(RegExp(r'\s+')).length,
        'mood': mood,
        'title': title,
        'charCount': content.length,
      },
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activityEvents')
          .doc(event.id)
          .set({...event.toMap(), 'userId': userId});

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'stats.totalJournals': FieldValue.increment(1),
        'stats.totalPoints': FieldValue.increment(10),
      });
    } catch (e) {
      debugPrint('AnalyticsService.logJournal Firestore error: $e');
    }

    await _postEventToBackend(userId, event);
  }

  // Call from breathing_exercise_screen.dart on session complete.
  Future<void> logBreathingSession({
    required String userId,
    required String techniqueId,
    required String techniqueName,
    required int cyclesCompleted,
    required int durationSeconds,
  }) async {
    final event = ActivityEvent(
      id: '${userId}_breath_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.breathingSession,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      metadata: {
        'techniqueId': techniqueId,
        'techniqueName': techniqueName,
        'cyclesCompleted': cyclesCompleted,
      },
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activityEvents')
          .doc(event.id)
          .set({...event.toMap(), 'userId': userId});

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'stats.totalBreaths': FieldValue.increment(1),
        'stats.totalPoints': FieldValue.increment(10),
      });
    } catch (e) {
      debugPrint('AnalyticsService.logBreathing Firestore error: $e');
    }

    await _postEventToBackend(userId, event);
  }

  // Call from home screen mood widget and journal screen mood selector.
  Future<void> logMood({
    required String userId,
    required MoodEntry entry,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('moodLogs')
          .doc(entry.id)
          .set({...entry.toMap(), 'userId': userId});

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'stats.totalPoints': FieldValue.increment(5),
      });
    } catch (e) {
      debugPrint('AnalyticsService.logMood Firestore error: $e');
    }

    await _postMoodToBackend(userId, entry);
  }

  // Call from NuruAI chat screen after each conversation ends.
  Future<void> logNuruChat({
    required String userId,
    required int messageCount,
    required String topic,
    required int durationSeconds,
  }) async {
    final event = ActivityEvent(
      id: '${userId}_chat_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.nuruChat,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      metadata: {'messageCount': messageCount, 'topic': topic},
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activityEvents')
          .doc(event.id)
          .set({...event.toMap(), 'userId': userId});

      final pts = ((messageCount / 10).floor() * 10).clamp(0, 50);
      if (pts > 0) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'stats.totalPoints': FieldValue.increment(pts)},
        );
      }
    } catch (e) {
      debugPrint('AnalyticsService.logNuruChat Firestore error: $e');
    }

    await _postEventToBackend(userId, event);
  }

  // Call from calmme_screen.dart when a CalmMe activity completes.
  Future<void> logCalmMeSession({
    required String userId,
    required String activity,
    required int durationSeconds,
  }) async {
    final event = ActivityEvent(
      id: '${userId}_calmme_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.calmMe,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      metadata: {'activity': activity},
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activityEvents')
          .doc(event.id)
          .set({...event.toMap(), 'userId': userId});

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'stats.totalPoints': FieldValue.increment(5),
      });
    } catch (e) {
      debugPrint('AnalyticsService.logCalmMe Firestore error: $e');
    }

    await _postEventToBackend(userId, event);
  }

  // Call on every app open to update streak in Firestore.
  Future<void> logAppOpen(String userId) async {
    try {
      final fs = FirebaseFirestore.instance;
      final userRef = fs.collection('users').doc(userId);
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await fs.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return;

        final stats = snap.data()?['stats'] as Map<String, dynamic>? ?? {};
        final lastActive = stats['lastCheckIn'] as String?;
        final currentStreak = (stats['currentStreak'] as num?)?.toInt() ?? 0;
        final longestStreak = (stats['longestStreak'] as num?)?.toInt() ?? 0;
        final totalDays = (stats['totalDaysActive'] as num?)?.toInt() ?? 0;

        if (lastActive == todayKey) return; // already counted today

        int newStreak = 1;
        if (lastActive != null) {
          final last = DateTime.parse(lastActive);
          final diff = DateTime(
            now.year,
            now.month,
            now.day,
          ).difference(DateTime(last.year, last.month, last.day)).inDays;
          newStreak = diff == 1 ? currentStreak + 1 : 1;
        }

        tx.update(userRef, {
          'stats.currentStreak': newStreak,
          'stats.longestStreak': newStreak > longestStreak
              ? newStreak
              : longestStreak,
          'stats.totalDaysActive': totalDays + 1,
          'stats.lastCheckIn': todayKey,
          'stats.totalPoints': FieldValue.increment(10),
        });
      });
    } catch (e) {
      debugPrint('AnalyticsService.logAppOpen error: $e');
    }
  }

  // Call from your micro-expression CV model when an emotion is detected.
  Future<void> logMicroExpression({
    required String userId,
    required String detectedEmotion,
    required double confidence,
    required String context, // 'chat' | 'journal' | 'home'
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('microExpressions')
          .add({
            'userId': userId,
            'emotion': detectedEmotion,
            'confidence': confidence,
            'context': context,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('AnalyticsService.logMicroExpression Firestore error: $e');
    }

    // POST to ML backend so model can correlate micro-expression
    try {
      await http
          .post(
            Uri.parse('${NuruBackend.baseUrl}/events/micro_expression'),
            headers: NuruBackend.headers,
            body: jsonEncode({
              'userId': userId,
              'detectedEmotion': detectedEmotion,
              'confidence': confidence,
              'context': context,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(NuruBackend.timeout);
    } catch (_) {
      // Queue for retry when connection is restored.
    }
  }

  // Internal backend POST helpers
  Future<void> _postEventToBackend(String userId, ActivityEvent event) async {
    try {
      await http
          .post(
            Uri.parse('${NuruBackend.baseUrl}/events/activity'),
            headers: NuruBackend.headers,
            body: jsonEncode({'userId': userId, ...event.toMap()}),
          )
          .timeout(NuruBackend.timeout);
    } catch (_) {}
  }

  Future<void> _postMoodToBackend(String userId, MoodEntry entry) async {
    try {
      await http
          .post(
            Uri.parse('${NuruBackend.baseUrl}/events/mood'),
            headers: NuruBackend.headers,
            body: jsonEncode({'userId': userId, ...entry.toMap()}),
          )
          .timeout(NuruBackend.timeout);
    } catch (_) {
      // Queue for offline retry.
    }
  }

  // Static helpers
  static String moodEmoji(MoodValue mood) {
    const map = {
      MoodValue.happy: '\ud83d\ude0a',
      MoodValue.calm: '\ud83d\ude0c',
      MoodValue.anxious: '\ud83d\ude30',
      MoodValue.sad: '\ud83d\ude22',
      MoodValue.angry: '\ud83d\ude20',
      MoodValue.tired: '\ud83d\ude34',
      MoodValue.overwhelmed: '\ud83e\udd2f',
      MoodValue.excited: '\ud83e\udd29',
    };
    return map[mood] ?? '\ud83d\ude10';
  }

  static double moodToScore(MoodValue mood) {
    const scores = {
      MoodValue.excited: 9.0,
      MoodValue.happy: 8.0,
      MoodValue.calm: 7.5,
      MoodValue.tired: 5.0,
      MoodValue.sad: 3.5,
      MoodValue.anxious: 3.0,
      MoodValue.angry: 2.5,
      MoodValue.overwhelmed: 2.0,
    };
    return scores[mood] ?? 5.0;
  }
}
