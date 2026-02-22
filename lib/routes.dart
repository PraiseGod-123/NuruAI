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
import 'screens/calmme.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String ageVerification = '/age-verification';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String facialRecognitionSetup = '/facial-recognition-setup';
  static const String microExpressionSetup = '/micro-expression-setup';
  static const String home = '/home';
  static const String calmme = '/calmme';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(),
      onboarding: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return OnboardingScreen();
      },
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
      calmme: (context) => CalmMeScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => OnboardingScreen(),
          settings: settings,
        );
      case ageVerification:
        return MaterialPageRoute(
          builder: (_) => AgeVerificationScreen(),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => SignupScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(),
          settings: settings,
        );
      case facialRecognitionSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FacialRecognitionSetupScreen(userData: args),
          settings: settings,
        );
      case microExpressionSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MicroExpressionSetupScreen(userData: args),
          settings: settings,
        );
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(userData: args),
          settings: settings,
        );
      case calmme:
        return MaterialPageRoute(
          builder: (_) => CalmMeScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Route ${settings.name} not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
