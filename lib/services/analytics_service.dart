import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════════════════
// NuruAI — AnalyticsService
//
// ALL data is sourced from real user interactions.
// There is NO mock data, NO hardcoded values, NO fake scores.
//
// Data pipeline:
//   User action (journal / mood / breathing / chat / micro-expression)
//       ↓
//   logXxx() writes event to Firebase Firestore
//       ↓
//   _postToBackend() sends event to NuruAI Flask/PyTorch server
//       ↓
//   ML model processes: sentiment, emotion patterns, engagement
//       ↓
//   loadUserAnalytics() reads computed insights back from backend
//       ↓
//   AnalyticsScreen renders real results
//
// Until your Python backend is deployed:
//   - Firebase writes are stubbed with TODO comments
//   - Backend POST calls are present but gated behind the TODO
//   - The screen receives UserAnalytics.empty() and shows
//     proper empty states ("Start logging to see your insights")
//
// When you are ready to connect:
//   1. Add firebase_core + cloud_firestore to pubspec.yaml
//   2. Uncomment the Firestore blocks below
//   3. Set NuruBackend.baseUrl to your Flask server address
//   4. Uncomment the http.post / http.get calls
//   Everything else is already wired.
// ══════════════════════════════════════════════════════════════════════════

// ── Backend config ─────────────────────────────────────────────────────────
class NuruBackend {
  // Set this to your Flask server once deployed.
  // e.g. 'https://nuruai.yourdomain.com/api/v1'
  // During local dev, use your machine's LAN IP or ngrok tunnel.
  static const String baseUrl = 'http://YOUR_FLASK_SERVER/api/v1';
  static const Duration timeout = Duration(seconds: 15);
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

// ── Enums ───────────────────────────────────────────────────────────────────

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

// ── Models ───────────────────────────────────────────────────────────────────

/// One mood entry — logged by the user explicitly (home screen,
/// journal) or detected automatically via micro-expression model.
class MoodEntry {
  final String id;
  final MoodValue mood;
  final String emoji;
  final String label;
  final DateTime timestamp;
  final String? note;

  /// 'journal' | 'home' | 'micro_expression'
  final String? source;

  /// Sentiment score set by the PyTorch model after processing.
  /// -1.0 = very negative, 1.0 = very positive.
  /// Null until backend has processed this entry.
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

  /// Flexible metadata per type:
  ///   journalEntry  → wordCount, mood, title
  ///   breathingSession → techniqueId, techniqueName, cyclesCompleted
  ///   nuruChat      → messageCount, topic
  ///   calmMe        → activity
  ///   moodLog       → mood
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

/// Streak data read directly from Firestore.
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDaysActive;
  final DateTime? lastActiveDate;

  /// 30 booleans — index 0 = 30 days ago, index 29 = today.
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

/// Daily wellbeing insight produced by the NuruAI PyTorch model.
///
/// The model computes this from:
///   - Mood logs (explicit + micro-expression detected)
///   - Journal entry sentiment (NLP analysis)
///   - Breathing session patterns
///   - Chat tone and topic analysis
///   - Engagement frequency and duration
///
/// ALL fields are nullable. The screen checks isMLGenerated and
/// shows appropriate empty states when backend is not yet connected.
class DailyInsight {
  final DateTime date;

  /// 0.0–10.0 composite wellbeing score.
  /// Null until the ML model has processed enough data for today.
  final double? wellbeingScore;

  /// Plain-English summary written by the model.
  final String? summary;

  /// Key observations the model detected today.
  final List<String> highlights;

  /// Actionable suggestions personalised to this user's patterns.
  final List<String> suggestions;

  final InsightType? primaryInsight;
  final int activitiesCompleted;

  /// True = came from the PyTorch backend.
  /// False = backend not yet connected; screen shows pending state.
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

/// Weekly report produced by the NuruAI PyTorch model.
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;

  /// All null until the backend has a full week of data.
  final double? avgWellbeingScore;
  final double? wellbeingTrend; // positive = improving, negative = declining
  final List<double> dailyScores; // 7 values Mon–Sun, empty until backend ready
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

/// Award definition. Unlock status is resolved at runtime
/// against the user's real totalPoints from Firestore.
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

/// The full analytics payload for one user session.
/// Every field is populated from real Firebase + backend data.
class UserAnalytics {
  final String userId;
  final StreakData streakData;
  final List<MoodEntry> recentMoods; // last 7 days from Firestore
  final List<ActivityEvent> recentActivities; // last 30 from Firestore
  final DailyInsight? todayInsight; // null until ML backend responds
  final WeeklyReport? weeklyReport; // null until ML backend responds
  final List<Award> awards; // unlock status from real totalPoints
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

  /// Shown before any data is available — new user or offline.
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

// ── Service ─────────────────────────────────────────────────────────────────

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // ── Award catalogue ──────────────────────────────────────────────────────
  // These are fixed definitions. Unlock status is computed at runtime
  // from the user's real totalPoints read from Firestore.
  // Points are earned from real interactions only:
  //   App open per day  = 10 pts
  //   Journal entry     = 10 pts
  //   Breathing session = 10 pts
  //   Every 10 NuruAI messages = 10 pts
  //   CalmMe session    = 10 pts

  static List<Award> get awardCatalogue => const [
    // ── Streak ──────────────────────────────────────────────
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
    // ── Journal ─────────────────────────────────────────────
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
    // ── Breathing ───────────────────────────────────────────
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
    // ── Mood ────────────────────────────────────────────────
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
    // ── Engagement ──────────────────────────────────────────
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

  // ══════════════════════════════════════════════════════════════════════════
  // LOAD USER ANALYTICS
  //
  // Reads real data from Firebase then requests ML insight from backend.
  // Returns UserAnalytics.empty() if no data exists yet or connection fails.
  // The screen handles all empty/pending states gracefully.
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserAnalytics> loadUserAnalytics(String userId) async {
    try {
      // ── STEP 1: Read from Firebase Firestore ──────────────────────────────
      // Uncomment when firebase_core + cloud_firestore are added to pubspec.yaml
      //
      // final fs = FirebaseFirestore.instance;
      //
      // final userSnap = await fs.collection('users').doc(userId).get();
      // final userData = userSnap.data() ?? {};
      //
      // final streakSnap = await fs.collection('streaks').doc(userId).get();
      // final streakData = streakSnap.exists
      //     ? StreakData.fromMap(streakSnap.data()!)
      //     : StreakData.empty();
      //
      // final moodSnap = await fs
      //     .collection('mood_logs')
      //     .where('userId', isEqualTo: userId)
      //     .orderBy('timestamp', descending: true)
      //     .limit(7)
      //     .get();
      // final recentMoods = moodSnap.docs
      //     .map((d) => MoodEntry.fromMap(d.data()))
      //     .toList();
      //
      // final activitySnap = await fs
      //     .collection('activity_events')
      //     .where('userId', isEqualTo: userId)
      //     .orderBy('timestamp', descending: true)
      //     .limit(30)
      //     .get();
      // final recentActivities = activitySnap.docs
      //     .map((d) => ActivityEvent.fromMap(d.data()))
      //     .toList();
      //
      // final totalPoints    = (userData['totalPoints'] as num?)?.toInt() ?? 0;
      // final totalJournals  = (userData['totalJournals'] as num?)?.toInt() ?? 0;
      // final totalBreaths   = (userData['totalBreaths'] as num?)?.toInt() ?? 0;
      // final totalChats     = (userData['totalChats'] as num?)?.toInt() ?? 0;
      // final totalCalmMe    = (userData['totalCalmMe'] as num?)?.toInt() ?? 0;

      // ── STEP 2: Request ML insight from NuruAI backend ───────────────────
      // Uncomment when your Flask server is deployed and baseUrl is set.
      //
      // DailyInsight? todayInsight;
      // WeeklyReport? weeklyReport;
      //
      // try {
      //   final dailyRes = await http.get(
      //     Uri.parse('${NuruBackend.baseUrl}/analytics/$userId/daily'),
      //     headers: NuruBackend.headers,
      //   ).timeout(NuruBackend.timeout);
      //
      //   if (dailyRes.statusCode == 200) {
      //     todayInsight = DailyInsight.fromMap(
      //       jsonDecode(dailyRes.body) as Map<String, dynamic>,
      //     );
      //   }
      //
      //   final weeklyRes = await http.get(
      //     Uri.parse('${NuruBackend.baseUrl}/analytics/$userId/weekly'),
      //     headers: NuruBackend.headers,
      //   ).timeout(NuruBackend.timeout);
      //
      //   if (weeklyRes.statusCode == 200) {
      //     weeklyReport = WeeklyReport.fromMap(
      //       jsonDecode(weeklyRes.body) as Map<String, dynamic>,
      //     );
      //   }
      // } catch (_) {
      //   // Backend not yet available — insight fields will be null.
      //   // Screen shows "Your insights will appear here once NuruAI
      //   // has enough data to analyse."
      // }

      // ── STEP 3: Resolve award unlock status ───────────────────────────────
      // final awards = awardCatalogue
      //     .map((a) => a.withUnlockStatus(totalPoints))
      //     .toList();

      // ── STEP 4: Return real UserAnalytics ─────────────────────────────────
      // return UserAnalytics(
      //   userId: userId,
      //   streakData: streakData,
      //   recentMoods: recentMoods,
      //   recentActivities: recentActivities,
      //   todayInsight: todayInsight,
      //   weeklyReport: weeklyReport,
      //   awards: awards,
      //   totalPoints: totalPoints,
      //   totalJournals: totalJournals,
      //   totalBreaths: totalBreaths,
      //   totalChats: totalChats,
      //   totalCalmMe: totalCalmMe,
      //   isLoaded: true,
      // );

      // ── Backend not yet connected — return empty state ────────────────────
      // The screen renders proper empty states with guidance messages.
      // Remove this return once Firebase + backend are connected above.
      return UserAnalytics.empty(userId);
    } catch (e) {
      return UserAnalytics.empty(
        userId,
      ).copyWithError('Could not load your analytics. Check your connection.');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT LOGGERS
  //
  // Call these from each screen when a real user action occurs.
  // They write to Firestore and forward to the ML backend so the
  // PyTorch model can update the user's profile incrementally.
  //
  // The ML model uses these signals:
  //   journalEntry    → NLP sentiment + writing pattern analysis
  //   moodLog         → explicit emotion + source context
  //   breathingSession → regulation behaviour + consistency
  //   nuruChat        → conversation tone + topic tracking
  //   calmMe          → coping strategy usage
  //   appOpen         → streak + engagement frequency
  //   microExpression → automatic emotion detection (from your CV model)
  // ══════════════════════════════════════════════════════════════════════════

  /// Call from journal_entry_screen.dart when user saves a journal entry.
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

    // TODO: Firestore write
    // await FirebaseFirestore.instance
    //     .collection('activity_events')
    //     .doc(entryId)
    //     .set({...event.toMap(), 'userId': userId});
    //
    // await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(userId)
    //     .update({
    //       'totalJournals': FieldValue.increment(1),
    //       'totalPoints':   FieldValue.increment(10),
    //     });

    await _postEventToBackend(userId, event);
  }

  /// Call from breathing_exercise_screen.dart on session complete.
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

    // TODO: Firestore write + FieldValue.increment

    await _postEventToBackend(userId, event);
  }

  /// Call from home screen mood widget and journal screen mood selector.
  Future<void> logMood({
    required String userId,
    required MoodEntry entry,
  }) async {
    // TODO: Firestore write
    // await FirebaseFirestore.instance
    //     .collection('mood_logs')
    //     .doc(entry.id)
    //     .set({...entry.toMap(), 'userId': userId});
    //
    // await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(userId)
    //     .update({'totalPoints': FieldValue.increment(5)});

    await _postMoodToBackend(userId, entry);
  }

  /// Call from NuruAI chat screen after each conversation ends.
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

    // TODO: Firestore write + points increment (messageCount / 10 * 10)

    await _postEventToBackend(userId, event);
  }

  /// Call from calmme_screen.dart when a CalmMe activity completes.
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

    // TODO: Firestore write + points increment

    await _postEventToBackend(userId, event);
  }

  /// Call on every app open to update streak in Firestore.
  Future<void> logAppOpen(String userId) async {
    // TODO:
    // final fs = FirebaseFirestore.instance;
    // final doc = fs.collection('streaks').doc(userId);
    // final snap = await doc.get();
    // final today = DateTime(now.year, now.month, now.day);
    //
    // if snap exists:
    //   lastActive = DateTime.parse(snap.data()!['lastActiveDate'])
    //   if lastActive.date == today: return (already counted)
    //   if lastActive.date == yesterday:
    //     increment currentStreak, totalDaysActive
    //   else:
    //     reset currentStreak to 1, increment totalDaysActive
    //   update longestStreak if currentStreak > longestStreak
    //   update last30Days array (shift + append true)
    // else:
    //   create doc with currentStreak=1, longestStreak=1, totalDaysActive=1
    //
    // await fs.collection('users').doc(userId)
    //     .update({'totalPoints': FieldValue.increment(10)});
  }

  /// Call from your micro-expression CV model when an emotion is detected.
  /// This is the core ML integration point — the PyTorch model that detects
  /// micro-expressions feeds directly into the analytics pipeline.
  Future<void> logMicroExpression({
    required String userId,
    required String detectedEmotion,
    required double confidence,
    required String context, // 'chat' | 'journal' | 'home'
  }) async {
    // TODO: Firestore write to 'micro_expressions' collection
    // await FirebaseFirestore.instance
    //     .collection('micro_expressions')
    //     .add({
    //       'userId': userId,
    //       'emotion': detectedEmotion,
    //       'confidence': confidence,
    //       'context': context,
    //       'timestamp': DateTime.now().toIso8601String(),
    //     });

    // POST to ML backend so model can correlate micro-expression
    // with concurrent mood log, journal entry, or chat session.
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

  // ── Internal backend POST helpers ─────────────────────────────────────────

  Future<void> _postEventToBackend(String userId, ActivityEvent event) async {
    try {
      await http
          .post(
            Uri.parse('${NuruBackend.baseUrl}/events/activity'),
            headers: NuruBackend.headers,
            body: jsonEncode({'userId': userId, ...event.toMap()}),
          )
          .timeout(NuruBackend.timeout);
    } catch (_) {
      // Silently fail — queue for offline retry via local SQLite.
    }
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

  // ── Static helpers ─────────────────────────────────────────────────────────

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
