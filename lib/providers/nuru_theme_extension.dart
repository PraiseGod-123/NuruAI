import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

// NuruAI Theme Extension
extension NuruThemeContext on BuildContext {
  NuruAppTheme get nuruTheme => watch<NuruThemeProvider>().activeTheme;
  NuruAppTheme get nuruThemeRead => read<NuruThemeProvider>().activeTheme;
  bool get isDarkMode => watch<NuruThemeProvider>().isDark;
}

// NuruColors

class NuruDynamicColors {
  final NuruAppTheme _theme;
  final bool isDark;

  NuruDynamicColors(BuildContext context)
    : _theme = context.nuruTheme,
      isDark = context.isDarkMode;

  // Backgrounds
  Color get background => _theme.gradientColors.last;
  Color get backgroundTop => _theme.gradientColors.first;
  Color get backgroundMid => _theme.backgroundMid;
  Color get scaffold => _theme.gradientColors.last;

  // Cards & surfaces
  Color get cardBg => isDark
      ? _theme.accentColor.withOpacity(0.08)
      : _theme.accentColor.withOpacity(0.06);
  Color get cardBorder => _theme.accentColor.withOpacity(isDark ? 0.25 : 0.20);
  Color get cardSurface => isDark
      ? Colors.white.withOpacity(0.05)
      : _theme.accentColor.withOpacity(0.04);

  // Text
  Color get textPrimary => _theme.textColor;
  Color get textSecondary => _theme.textColor.withOpacity(0.65);
  Color get textMuted => _theme.textColor.withOpacity(0.40);
  Color get textHint => _theme.textColor.withOpacity(0.30);

  // Accent
  Color get accent => _theme.accentColor;
  Color get accentLight => _theme.accentColor.withOpacity(0.25);
  Color get accentBorder => _theme.accentColor.withOpacity(0.40);

  // Dividers & borders
  Color get divider => _theme.textColor.withOpacity(0.10);
  Color get border => _theme.textColor.withOpacity(0.12);

  // Input fields
  Color get inputBg => _theme.textColor.withOpacity(isDark ? 0.06 : 0.08);
  Color get inputBorder => _theme.accentColor.withOpacity(0.30);
  Color get inputText => _theme.textColor;

  // Gradient
  LinearGradient get bgGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _theme.gradientColors,
  );

  LinearGradient get bgGradientVertical => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _theme.gradientColors,
  );

  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      _theme.accentColor.withOpacity(isDark ? 0.18 : 0.12),
      _theme.accentColor.withOpacity(isDark ? 0.06 : 0.04),
    ],
  );
}
