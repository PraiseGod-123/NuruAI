import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/music_service.dart';
import 'services/nuru_ai_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'providers/theme_provider.dart';
import 'providers/text_size_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF081F44),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF081F44),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Disable reCAPTCHA ONLY in debug mode on emulators.
  // This is automatically skipped in release builds.
  if (kDebugMode) {
    await NuruFirebaseService.useEmulatorIfDebug();
  }

  // Notifications — must come after Firebase.initializeApp()
  try {
    await NuruNotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }

  // Schedule default reminders — wrapped in try-catch so a
  // permissions error never crashes the app on first launch
  try {
    await NuruNotificationService.instance.scheduleAllDefaults();
  } catch (e) {
    debugPrint('Notification scheduling skipped: $e');
  }

  // Services
  // Jamendo: get a free client ID at https://developer.jamendo.com
  // Leave empty to fall back to iTunes previews (no key needed)
  MusicService.instance.jamendoClientId = const String.fromEnvironment(
    'JAMENDO_CLIENT_ID',
    defaultValue: '',
  );

  // Groq API key
  const groqKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  NuruAIService.instance.apiKey = const String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NuruThemeProvider()),
        ChangeNotifierProvider(create: (_) => TextSizeProvider()),
      ],
      child: const NuruAIApp(),
    ),
  );
}
