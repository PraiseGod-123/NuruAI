import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/age_verification_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/micro_expression_setup_screen.dart';
import 'screens/facial_recognition_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/home_screen_young.dart';
import 'screens/home_screen_teen.dart';
import 'screens/home_screen_young_adult.dart';
import 'screens/calmme_screen.dart';
import 'screens/journal_list_screen.dart';
import 'screens/breathing_exercise_screen.dart';
import 'screens/music_library_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/anger_management_screen.dart';
import 'screens/self_control_screen.dart';
import 'screens/stress_relief_screen.dart';
import 'screens/mindfulness_screen.dart';
import 'screens/poetry_corner_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/nuru_ai_screen.dart';
import 'screens/sensory_toolkit_screen.dart';
import 'screens/social_scripts_screen.dart';
import 'screens/special_interest_screen.dart';

class AppRoutes {
  // Route name constants
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String ageVerification = '/age-verification';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String facialRecognitionSetup = '/facial-recognition-setup';
  static const String microExpressionSetup = '/micro-expression-setup';
  static const String home = '/home';
  static const String calmme = '/calmme';
  static const String journal = '/journal';
  static const String breathing = '/breathing';
  static const String music = '/music';
  static const String profile = '/profile';
  static const String resources = '/resources';
  static const String analytics = '/analytics';
  static const String angerManagement = '/anger-management';
  static const String selfControl = '/self-control';
  static const String stressRelief = '/stress-relief';
  static const String mindfulness = '/mindfulness';
  static const String poetryCorner = '/poetry-corner';
  static const String nuruAI = '/nuru-ai';
  static const String sos = '/sos';
  static const String sensoryToolkit = '/sensory-toolkit';
  static const String socialScripts = '/social-scripts';
  static const String specialInterest = '/special-interest';

  // Static route map (used by MaterialApp.routes)
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(),
      onboarding: (context) => OnboardingScreen(),
      ageVerification: (context) => AgeVerificationScreen(),
      signup: (context) => SignupScreen(),
      login: (context) => LoginScreen(),
      facialRecognitionSetup: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return FacialRecognitionSetupScreen(userData: args);
      },
      microExpressionSetup: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MicroExpressionSetupScreen(userData: args);
      },
      home: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return HomeScreen(userData: args);
      },
      calmme: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CalmMeScreen(userData: args);
      },
      journal: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return JournalListScreen(userData: args);
      },
      breathing: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return BreathingExerciseScreen(userData: args);
      },
      music: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MusicLibraryScreen(userData: args);
      },
      profile: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ProfileScreen(userData: args);
      },
      resources: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ResourcesScreen(userData: args);
      },
      angerManagement: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return AngerManagementScreen(userData: args);
      },
      selfControl: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return SelfControlScreen(userData: args);
      },
      stressRelief: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return StressReliefScreen(userData: args);
      },
      mindfulness: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MindfulnessScreen(userData: args);
      },
      poetryCorner: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return PoetryCornerScreen(userData: args);
      },
      analytics: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return AnalyticsScreen(userData: args);
      },
    };
  }

  // ── onGenerateRoute (used by MaterialApp.onGenerateRoute) ──
  // MaterialPageRoute causes during transitions.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _darkFade((_) => SplashScreen(), settings);

      case onboarding:
        return _darkFade((_) => OnboardingScreen(), settings);

      case ageVerification:
        return _darkFade((_) => AgeVerificationScreen(), settings);

      case signup:
        return _darkFade((_) => SignupScreen(), settings);

      case login:
        return _darkFade((_) => LoginScreen(), settings);

      case facialRecognitionSetup:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => FacialRecognitionSetupScreen(userData: args),
            settings,
          );
        }

      case microExpressionSetup:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => MicroExpressionSetupScreen(userData: args),
            settings,
          );
        }

      case home:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => HomeScreen(userData: args), settings);
        }

      case calmme:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => CalmMeScreen(userData: args), settings);
        }

      case journal:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => JournalListScreen(userData: args), settings);
        }

      case breathing:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => BreathingExerciseScreen(userData: args),
            settings,
          );
        }

      case music:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => MusicLibraryScreen(userData: args), settings);
        }

      case profile:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => ProfileScreen(userData: args), settings);
        }

      case resources:
        return _darkFade((_) => ResourcesScreen(), settings);

      case angerManagement:
        return _darkFade((_) => const AngerManagementScreen(), settings);

      case selfControl:
        return _darkFade((_) => const SelfControlScreen(), settings);

      case stressRelief:
        return _darkFade((_) => const StressReliefScreen(), settings);

      case mindfulness:
        return _darkFade((_) => const MindfulnessScreen(), settings);

      case nuruAI:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => NuruAIChatScreen(userData: args), settings);
        }

      case sos:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => SOSScreen(userData: args), settings);
        }

      case sensoryToolkit:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => SensoryToolkitScreen(userData: args),
            settings,
          );
        }

      case socialScripts:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => SocialScriptsScreen(userData: args),
            settings,
          );
        }

      case specialInterest:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => SpecialInterestScreen(userData: args),
            settings,
          );
        }

      case poetryCorner:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => PoetryCornerScreen(userData: args), settings);
        }

      case resources:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => ResourcesScreen(userData: args), settings);
        }

      case angerManagement:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade(
            (_) => AngerManagementScreen(userData: args),
            settings,
          );
        }

      case selfControl:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => SelfControlScreen(userData: args), settings);
        }

      case stressRelief:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => StressReliefScreen(userData: args), settings);
        }

      case mindfulness:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => MindfulnessScreen(userData: args), settings);
        }

      case analytics:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return _darkFade((_) => AnalyticsScreen(userData: args), settings);
        }

      default:
        return _darkFade(
          (_) => Scaffold(
            backgroundColor: const Color(0xFF081F44),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Route ${settings.name} not found',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder<T> _darkFade<T>(
    WidgetBuilder builder,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: false,
      barrierColor: const Color(0xFF081F44),
      pageBuilder:
          (
            BuildContext ctx,
            Animation<double> anim,
            Animation<double> secondAnim,
          ) {
            return builder(ctx);
          },
      transitionsBuilder:
          (
            BuildContext ctx,
            Animation<double> anim,
            Animation<double> secondAnim,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            );
          },
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
    );
  }
}
