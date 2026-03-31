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

        return MaterialApp(
          title: 'NuruAI',
          debugShowCheckedModeBanner: false,

          // Apply user's text scale factor across the whole app
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textProvider.scale)),
              child: child!,
            );
          },

          theme: ThemeData(
            primaryColor: t.accentColor,
            scaffoldBackgroundColor: t.backgroundStart,

            colorScheme: ColorScheme.dark(
              primary: t.accentColor,
              secondary: t.accentColor.withOpacity(0.7),
              surface: t.backgroundMid,
              background: t.backgroundStart,
              error: NuruColors.error,
              onPrimary: t.textColor,
              onSecondary: t.textColor,
              onSurface: t.textColor,
              onBackground: t.textColor,
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
