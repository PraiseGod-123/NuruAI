import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'utils/nuru_colors.dart';
import 'providers/theme_provider.dart';
import 'providers/text_size_provider.dart';

class NuruAIApp extends StatelessWidget {
  const NuruAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<NuruThemeProvider, TextSizeProvider>(
      builder: (context, themeProvider, textProvider, _) {
        final t = themeProvider.activeTheme;
        final isDark = themeProvider.isDark;
        final brightness = isDark ? Brightness.dark : Brightness.light;

        return MaterialApp(
          title: 'NuruAI',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textProvider.scale)),
              child: child!,
            );
          },

          theme: ThemeData(
            brightness: brightness,
            primaryColor: t.accentColor,
            scaffoldBackgroundColor: t.backgroundStart,

            colorScheme: ColorScheme(
              brightness: brightness,
              primary: t.accentColor,
              onPrimary: Colors.white,
              secondary: t.accentColor.withOpacity(0.7),
              onSecondary: Colors.white,
              surface: t.backgroundMid,
              onSurface: t.textColor,
              background: t.backgroundStart,
              onBackground: t.textColor,
              error: NuruColors.error,
              onError: Colors.white,
            ),

            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: t.accentColor),
              titleTextStyle: TextStyle(
                color: t.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: t.accentColor,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith(
                (s) => s.contains(MaterialState.selected)
                    ? Colors.white
                    : Colors.white38,
              ),
              trackColor: MaterialStateProperty.resolveWith(
                (s) => s.contains(MaterialState.selected)
                    ? t.accentColor
                    : Colors.white12,
              ),
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: t.accentColor.withOpacity(0.4),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: t.accentColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: NuruColors.error, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: NuruColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(color: t.textColor.withOpacity(0.4)),
              labelStyle: TextStyle(color: t.textColor.withOpacity(0.7)),
            ),

            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: t.backgroundMid,
            ),

            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: t.backgroundStart,
              selectedItemColor: t.accentColor,
              unselectedItemColor: t.textColor.withOpacity(0.4),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
            ),

            dialogTheme: DialogThemeData(
              backgroundColor: t.backgroundMid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titleTextStyle: TextStyle(
                color: t.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: TextStyle(
                color: t.textColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),

            textTheme: TextTheme(
              bodyLarge: TextStyle(color: t.textColor),
              bodyMedium: TextStyle(color: t.textColor),
              bodySmall: TextStyle(color: t.textColor.withOpacity(0.7)),
              titleLarge: TextStyle(
                color: t.textColor,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: t.textColor,
                fontWeight: FontWeight.w600,
              ),
              titleSmall: TextStyle(color: t.textColor.withOpacity(0.8)),
              labelLarge: TextStyle(color: t.textColor),
              labelMedium: TextStyle(color: t.textColor.withOpacity(0.8)),
              labelSmall: TextStyle(color: t.textColor.withOpacity(0.6)),
            ),

            snackBarTheme: SnackBarThemeData(
              backgroundColor: t.backgroundMid,
              contentTextStyle: TextStyle(color: t.textColor),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: t.accentColor,
            ),

            dividerTheme: DividerThemeData(
              color: t.accentColor.withOpacity(0.2),
              thickness: 1,
            ),

            fontFamily: 'Roboto',
          ),

          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
