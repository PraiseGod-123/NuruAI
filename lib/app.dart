import 'package:flutter/material.dart';
import 'routes.dart';
import 'utils/nuru_colors.dart';

class NuruAIApp extends StatelessWidget {
  const NuruAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NuruAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Primary Colors
        primaryColor: NuruColors.sailingBlue,
        scaffoldBackgroundColor: NuruColors.white,

        // Color Scheme
        colorScheme: ColorScheme.light(
          primary: NuruColors.sailingBlue,
          secondary: NuruColors.solidBlue,
          surface: NuruColors.white,
          background: NuruColors.white,
          error: NuruColors.error,
          onPrimary: NuruColors.white,
          onSecondary: NuruColors.white,
          onSurface: NuruColors.dive,
          onBackground: NuruColors.dive,
          onError: NuruColors.white,
        ),

        // App Bar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: NuruColors.sailingBlue),
          titleTextStyle: TextStyle(
            color: NuruColors.dive,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Text Theme
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: NuruColors.dive,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: NuruColors.dive,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: NuruColors.dive,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: NuruColors.dive,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: NuruColors.dive,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: NuruColors.deepSea),
          bodyMedium: TextStyle(fontSize: 14, color: NuruColors.deepSea),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: NuruColors.sailingBlue,
            foregroundColor: NuruColors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: NuruColors.sailingBlue,
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: NuruColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: NuruColors.lilacBlue, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: NuruColors.sailingBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: NuruColors.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: NuruColors.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: NuruColors.white,
        ),

        // Divider Theme
        dividerTheme: DividerThemeData(
          color: NuruColors.lilacBlue,
          thickness: 1.5,
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: NuruColors.white,
          selectedItemColor: NuruColors.sailingBlue,
          unselectedItemColor: NuruColors.darkGray,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),

        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // Progress Indicator Theme
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: NuruColors.sailingBlue,
        ),

        // Font Family
        fontFamily: 'Roboto',
      ),

      // Routes
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
