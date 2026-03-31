import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════
// NURU FIREBASE SERVICE
//
// Handles all Firebase Auth + Firestore operations:
//   - Sign up / Login / Logout
//   - Email verification
//   - User profile storage
//   - Streak tracking
//   - Check-in logging
//   - Live stats streaming
// ══════════════════════════════════════════════════════════════

class NuruFirebaseService {
  NuruFirebaseService._();
  static final instance = NuruFirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ── Current user ─────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ── Auth state stream ─────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ══════════════════════════════════════════════════════════════
  // EMULATOR BYPASS
  // Call once from main.dart after Firebase.initializeApp()
  // Disables reCAPTCHA on Android emulators (CONFIGURATION_NOT_FOUND fix)
  // Remove the call in main.dart before releasing to production
  // ══════════════════════════════════════════════════════════════

  static Future<void> useEmulatorIfDebug() async {
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
        debugPrint(
          'NuruFirebase: reCAPTCHA disabled for debug/emulator testing',
        );
      } catch (e) {
        debugPrint(
          'NuruFirebase: Could not disable reCAPTCHA: ' + e.toString(),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SIGN UP
  // ══════════════════════════════════════════════════════════════

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String diagnosis,
    String? caregiverName,
    String? caregiverType,
    String? caregiverEmail,
    String? caregiverPhone,
  }) async {
    // Step 1: Create Firebase Auth account
    // createUserWithEmailAndPassword throws a PigeonUserDetails internal cast
    // error on some firebase_auth versions. The account IS created — we detect
    // this by checking _auth.currentUser immediately after.
    String? uid;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = credential.user?.uid;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'NuruFirebase signUp FirebaseAuthException: ' +
            e.code +
            ' — ' +
            (e.message ?? ''),
      );
      return AuthResult.failure(_authErrorMessage(e.code));
    } catch (e) {
      // Check if it's the PigeonUserDetails crash — account was still created
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        uid = _auth.currentUser?.uid;
        debugPrint(
          'NuruFirebase: PigeonUserDetails on signup — recovering, uid=$uid',
        );
      }
      if (uid == null) {
        debugPrint('NuruFirebase signUp unknown error: $e');
        return AuthResult.failure('Something went wrong. Please try again.');
      }
    }

    if (uid == null)
      return AuthResult.failure('Account creation failed. Please try again.');

    final now = DateTime.now();

    // Step 2: Write Firestore profile immediately — before any other calls
    try {
      await _db.collection('users').doc(uid).set({
        'profile': {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'age': age,
          'diagnosis': diagnosis,
          'createdAt': now.toIso8601String(),
          'uid': uid,
          if (caregiverName != null && caregiverName.isNotEmpty)
            'caregiverName': caregiverName,
          if (caregiverType != null && caregiverType.isNotEmpty)
            'caregiverType': caregiverType,
          if (caregiverEmail != null && caregiverEmail.isNotEmpty)
            'caregiverEmail': caregiverEmail,
          if (caregiverPhone != null && caregiverPhone.isNotEmpty)
            'caregiverPhone': caregiverPhone,
        },
        'stats': {
          'currentStreak': 0,
          'longestStreak': 0,
          'totalCheckIns': 0,
          'totalMoodLogs': 0,
          'avgMood': 0.0,
          'lastCheckIn': null,
          'unreadNotifications': 0,
        },
      });
      debugPrint('NuruFirebase: Firestore profile written for $uid');
    } catch (e) {
      debugPrint('NuruFirebase: Firestore write error: $e');
      // Non-fatal — account exists, profile can be written later
    }

    // Step 3: Update display name (non-fatal if it throws)
    try {
      await _auth.currentUser?.updateDisplayName(name.trim());
    } catch (e) {
      debugPrint('NuruFirebase: updateDisplayName warning (non-fatal): $e');
    }

    // Step 4: Send email verification (non-fatal if it throws)
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('NuruFirebase: sendEmailVerification warning (non-fatal): $e');
    }

    debugPrint('NuruFirebase: User created — $uid');
    return AuthResult.success(uid: uid, user: _auth.currentUser!);
  }

  // ══════════════════════════════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════════════════════════════

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Load user profile from Firestore
      final userData = await getUserData(uid);

      debugPrint('NuruFirebase: User logged in — $uid');
      return AuthResult.success(
        uid: uid,
        user: credential.user!,
        userData: userData,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'NuruFirebase login FirebaseAuthException: ' +
            e.code +
            ' — ' +
            (e.message ?? 'no message'),
      );
      return AuthResult.failure(_authErrorMessage(e.code));
    } catch (e, stack) {
      debugPrint('NuruFirebase login error: ' + e.toString());
      debugPrint('Stack: $stack');

      // PigeonUserDetails is an internal firebase_auth plugin cast error.
      // The login itself succeeded — recover by reading the current user.
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        final user = _auth.currentUser;
        if (user != null) {
          debugPrint(
            'NuruFirebase: Recovering from PigeonUserDetails error — login succeeded',
          );
          final userData = await getUserData(user.uid);
          return AuthResult.success(
            uid: user.uid,
            user: user,
            userData: userData,
          );
        }
      }

      return AuthResult.failure(e.toString());
    }
  }

  // ══════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════

  Future<void> logout() async {
    await _auth.signOut();
    debugPrint('NuruFirebase: User logged out');
  }

  // ══════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ══════════════════════════════════════════════════════════════

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(uid: '');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_authErrorMessage(e.code));
    }
  }

  // ══════════════════════════════════════════════════════════════
  // RESEND EMAIL VERIFICATION
  // ══════════════════════════════════════════════════════════════

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ══════════════════════════════════════════════════════════════
  // USER DATA
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      return {...profile, ...stats, 'uid': uid};
    } catch (e) {
      debugPrint('NuruFirebase: getUserData error — $e');
      return null;
    }
  }

  // Live stream of user stats (for home screen real-time updates)
  Stream<Map<String, dynamic>> streamUserStats(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data()!;
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      final stats = data['stats'] as Map<String, dynamic>? ?? {};
      return {...profile, ...stats, 'uid': uid};
    });
  }

  // ══════════════════════════════════════════════════════════════
  // CHECK-IN + STREAK
  // ══════════════════════════════════════════════════════════════

  Future<void> logCheckIn({
    required String uid,
    required int moodScore,
    String? note,
  }) async {
    try {
      final now = DateTime.now();
      final dateKey = _dateKey(now);

      final userRef = _db.collection('users').doc(uid);
      final checkRef = userRef.collection('checkIns').doc(dateKey);

      final existing = await checkRef.get();
      if (existing.exists) {
        await checkRef.update({
          'mood': moodScore,
          'note': note ?? '',
          'updatedAt': now.toIso8601String(),
        });
        return;
      }

      await checkRef.set({
        'mood': moodScore,
        'note': note ?? '',
        'date': dateKey,
        'timestamp': now.toIso8601String(),
      });

      await _db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final stats =
            (userSnap.data()?['stats'] as Map<String, dynamic>?) ?? {};

        final lastCheckIn = stats['lastCheckIn'] as String?;
        final currentStreak = (stats['currentStreak'] as num?)?.toInt() ?? 0;
        final longestStreak = (stats['longestStreak'] as num?)?.toInt() ?? 0;
        final totalCheckIns = (stats['totalCheckIns'] as num?)?.toInt() ?? 0;
        final totalMoodLogs = (stats['totalMoodLogs'] as num?)?.toInt() ?? 0;
        final currentAvg = (stats['avgMood'] as num?)?.toDouble() ?? 0.0;

        int newStreak = 1;
        if (lastCheckIn != null) {
          final last = DateTime.parse(lastCheckIn);
          final diff = DateTime(
            now.year,
            now.month,
            now.day,
          ).difference(DateTime(last.year, last.month, last.day)).inDays;
          if (diff == 1) {
            newStreak = currentStreak + 1;
          } else if (diff == 0) {
            newStreak = currentStreak;
          } else {
            newStreak = 1;
          }
        }

        final newTotal = totalMoodLogs + 1;
        final newAvg = ((currentAvg * totalMoodLogs) + moodScore) / newTotal;

        tx.update(userRef, {
          'stats.currentStreak': newStreak,
          'stats.longestStreak': newStreak > longestStreak
              ? newStreak
              : longestStreak,
          'stats.totalCheckIns': totalCheckIns + 1,
          'stats.totalMoodLogs': newTotal,
          'stats.avgMood': double.parse(newAvg.toStringAsFixed(1)),
          'stats.lastCheckIn': dateKey,
        });
      });

      debugPrint('NuruFirebase: Check-in logged for $uid on $dateKey');
    } catch (e) {
      debugPrint('NuruFirebase: logCheckIn error — $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATIONS COUNT
  // ══════════════════════════════════════════════════════════════

  Future<void> incrementUnreadNotifications(String uid) async {
    await _db.collection('users').doc(uid).update({
      'stats.unreadNotifications': FieldValue.increment(1),
    });
  }

  Future<void> clearUnreadNotifications(String uid) async {
    await _db.collection('users').doc(uid).update({
      'stats.unreadNotifications': 0,
    });
  }

  // ══════════════════════════════════════════════════════════════
  // CHAT SESSIONS
  // ══════════════════════════════════════════════════════════════

  /// Save a NuruAI chat session to Firestore when it ends.
  Future<void> saveChatSession({
    required String uid,
    required List<Map<String, dynamic>> messages,
    required String? topic,
    required int durationSecs,
  }) async {
    if (messages.isEmpty) return;
    try {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('chatSessions')
          .doc();

      await ref.set({
        'id': ref.id,
        'uid': uid,
        'messages': messages,
        'topic': topic ?? 'general',
        'messageCount': messages.length,
        'durationSecs': durationSecs,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _db.collection('users').doc(uid).update({
        'stats.totalChats': FieldValue.increment(1),
      });

      debugPrint('NuruFirebase: Chat session saved — ${ref.id}');
    } catch (e) {
      debugPrint('NuruFirebase: saveChatSession error — $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE USER PROFILE
  // ══════════════════════════════════════════════════════════════

  /// Update specific fields in the user's Firestore profile.
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final profileFields = <String, dynamic>{};
      fields.forEach((key, value) {
        profileFields['profile.$key'] = value;
      });
      await _db.collection('users').doc(uid).update(profileFields);
      debugPrint('NuruFirebase: Profile updated — $uid');
    } catch (e) {
      debugPrint('NuruFirebase: updateUserProfile error — $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // JOURNALS
  // ══════════════════════════════════════════════════════════════

  /// Save a journal entry to Firestore.
  /// Returns the generated document ID.
  Future<String?> saveJournal({
    required String uid,
    required String title,
    required String content,
    required String mood,
    required DateTime date,
  }) async {
    try {
      final now = DateTime.now();
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(); // auto-generated ID

      await ref.set({
        'id': ref.id,
        'uid': uid,
        'title': title,
        'content': content,
        'mood': mood,
        'date': _dateKey(date),
        'createdAt': now.toIso8601String(),
        'wordCount': content.trim().split(RegExp(r'\s+')).length,
      });

      // Increment total journals counter
      await _db.collection('users').doc(uid).update({
        'stats.totalJournals': FieldValue.increment(1),
      });

      debugPrint('NuruFirebase: Journal saved — ${ref.id}');
      return ref.id;
    } catch (e) {
      debugPrint('NuruFirebase: saveJournal error — $e');
      return null;
    }
  }

  /// Stream all journal entries for a user, newest first.
  Stream<List<Map<String, dynamic>>> streamJournals(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('journals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Permanently delete a journal entry.
  Future<void> deleteJournal({
    required String uid,
    required String entryId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(entryId)
          .delete();

      // Decrement counter
      await _db.collection('users').doc(uid).update({
        'stats.totalJournals': FieldValue.increment(-1),
      });

      debugPrint('NuruFirebase: Journal deleted — $entryId');
    } catch (e) {
      debugPrint('NuruFirebase: deleteJournal error — $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// ── Result model ──────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? error;
  final String? uid;
  final User? user;
  final Map<String, dynamic>? userData;

  const AuthResult._({
    required this.success,
    this.error,
    this.uid,
    this.user,
    this.userData,
  });

  factory AuthResult.success({
    required String uid,
    User? user,
    Map<String, dynamic>? userData,
  }) => AuthResult._(success: true, uid: uid, user: user, userData: userData);

  factory AuthResult.failure(String error) =>
      AuthResult._(success: false, error: error);
}
