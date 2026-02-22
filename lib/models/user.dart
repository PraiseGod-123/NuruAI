class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final String? diagnosis; // 'ASD', 'ADHD', 'Both', 'Prefer not to say'
  final Map<String, String>?
  microExpressionBaseline; // emotion -> video/image path
  final Caregiver? caregiver;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final UserPreferences? preferences;
  final int streakCount;
  final int totalPoints;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.diagnosis,
    this.microExpressionBaseline,
    this.caregiver,
    required this.createdAt,
    this.lastLogin,
    this.preferences,
    this.streakCount = 0,
    this.totalPoints = 0,
  });

  // Age-based access control
  bool get isMinor => age < 18;
  bool get needsCaregiverConsent => age < 16;
  bool get canUseSocialFeatures => age >= 16;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'diagnosis': diagnosis,
      'microExpressionBaseline': microExpressionBaseline,
      'caregiver': caregiver?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'preferences': preferences?.toMap(),
      'streakCount': streakCount,
      'totalPoints': totalPoints,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
      diagnosis: map['diagnosis'],
      microExpressionBaseline: map['microExpressionBaseline'] != null
          ? Map<String, String>.from(map['microExpressionBaseline'])
          : null,
      caregiver: map['caregiver'] != null
          ? Caregiver.fromMap(map['caregiver'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : null,
      preferences: map['preferences'] != null
          ? UserPreferences.fromMap(map['preferences'])
          : null,
      streakCount: map['streakCount'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? diagnosis,
    Map<String, String>? microExpressionBaseline,
    Caregiver? caregiver,
    DateTime? createdAt,
    DateTime? lastLogin,
    UserPreferences? preferences,
    int? streakCount,
    int? totalPoints,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      diagnosis: diagnosis ?? this.diagnosis,
      microExpressionBaseline:
          microExpressionBaseline ?? this.microExpressionBaseline,
      caregiver: caregiver ?? this.caregiver,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
      streakCount: streakCount ?? this.streakCount,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

class Caregiver {
  final String name;
  final String email;
  final String phone;
  final String relationship;
  final bool hasReadAccess;

  Caregiver({
    required this.name,
    required this.email,
    required this.phone,
    required this.relationship,
    this.hasReadAccess = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
      'hasReadAccess': hasReadAccess,
    };
  }

  factory Caregiver.fromMap(Map<String, dynamic> map) {
    return Caregiver(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
      hasReadAccess: map['hasReadAccess'] ?? false,
    );
  }
}

class UserPreferences {
  final bool darkMode;
  final bool hapticFeedback;
  final double textSize;
  final bool showStreaks;
  final bool showAchievements;
  final String theme; // 'default', 'ocean', 'sunset', etc.

  UserPreferences({
    this.darkMode = false,
    this.hapticFeedback = true,
    this.textSize = 1.0,
    this.showStreaks = true,
    this.showAchievements = true,
    this.theme = 'default',
  });

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'hapticFeedback': hapticFeedback,
      'textSize': textSize,
      'showStreaks': showStreaks,
      'showAchievements': showAchievements,
      'theme': theme,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      darkMode: map['darkMode'] ?? false,
      hapticFeedback: map['hapticFeedback'] ?? true,
      textSize: map['textSize'] ?? 1.0,
      showStreaks: map['showStreaks'] ?? true,
      showAchievements: map['showAchievements'] ?? true,
      theme: map['theme'] ?? 'default',
    );
  }
}
