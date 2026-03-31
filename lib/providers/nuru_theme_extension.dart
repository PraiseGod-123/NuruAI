import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

// ==============================================================================
// NuruAI Theme Extension
//
// Adds a .nuruTheme getter to BuildContext so any screen or widget
// can access the active theme colours with a single clean call.
//
// Usage in any screen's build() method:
//
//   final t = context.nuruTheme;
//
//   Container(
//     decoration: BoxDecoration(
//       gradient: LinearGradient(colors: t.gradientColors),
//     ),
//   )
//
// Replaces all the hardcoded static const colours in every screen:
//   static const Color _night   = Color(0xFF081F44);   <- DELETE
//   static const Color _dive    = Color(0xFF1F3F74);   <- DELETE
//   static const Color _sailing = Color(0xFF4569AD);   <- DELETE
//
// And replace usages with:
//   _night   -> t.backgroundStart
//   _dive    -> t.backgroundMid
//   _sailing -> t.accentColor
//   _deep    -> t.backgroundEnd
// ==============================================================================

extension NuruThemeContext on BuildContext {
  /// Returns the active NuruAppTheme.
  /// Listens for changes — widget rebuilds when theme changes.
  NuruAppTheme get nuruTheme => watch<NuruThemeProvider>().activeTheme;

  /// Returns the active NuruAppTheme without listening.
  /// Use this inside callbacks/logic where you don't need rebuilds.
  NuruAppTheme get nuruThemeRead => read<NuruThemeProvider>().activeTheme;
}
