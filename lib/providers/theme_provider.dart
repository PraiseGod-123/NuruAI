import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NuruAI Theme Provider
class NuruColorPalette {
  final String id;
  final String name;
  final String emoji;

  /// Background gradient for light mode
  final List<Color> lightGradient;

  /// Background gradient for dark mode
  final List<Color> darkGradient;

  /// 3 colours for floating background shape/orb painters
  final List<Color> shapeColors;

  /// Widget / button / card / border accent colour
  final Color accentColor;

  /// Primary text colour on light backgrounds
  final Color lightTextColor;

  /// Primary text colour on dark backgrounds
  final Color darkTextColor;

  /// Secondary/muted text colour (subtitles, hints)
  final Color secondaryTextColor;

  final bool hasStars;

  const NuruColorPalette({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lightGradient,
    required this.darkGradient,
    required this.shapeColors,
    required this.accentColor,
    this.lightTextColor = Colors.white,
    this.darkTextColor = Colors.white,
    this.secondaryTextColor = const Color(0x99FFFFFF),
    this.hasStars = true,
  });

  Color textColorFor(bool isDark) => isDark ? darkTextColor : lightTextColor;
}

// Nuru Default
const NuruColorPalette paletteNuruDefault = NuruColorPalette(
  id: 'nuru_default',
  name: 'Nuru Default',
  emoji: '🌊',
  lightGradient: [
    Color(0xFF4569AD), // sailing blue — top   (matches onboarding)
    Color(0xFF14366D), // deep sea     — bottom (matches onboarding)
  ],
  darkGradient: [Color(0xFF1A2D52), Color(0xFF0D1C36), Color(0xFF020C1E)],
  shapeColors: [Color(0xFF5B8DD9), Color(0xFF3A6BA8), Color(0xFF1F3F74)],
  accentColor: Color(0xFF4569AD),
  lightTextColor: Colors.white,
  darkTextColor: Colors.white,
  hasStars: true,
);

/// All palettes
const List<NuruColorPalette> allColorPalettes = [paletteNuruDefault];

class NuruAppTheme {
  final String id;
  final List<Color> gradientColors;
  final List<Color> shapeColors;
  final Color accentColor;
  final Color textColor;
  final Color secondaryTextColor;
  final bool hasStars;

  const NuruAppTheme({
    required this.id,
    required this.gradientColors,
    required this.shapeColors,
    required this.accentColor,
    required this.textColor,
    this.secondaryTextColor = const Color(0x99FFFFFF),
    this.hasStars = false,
  });

  Color get backgroundStart => gradientColors.first;
  Color get backgroundMid =>
      gradientColors.length >= 3 ? gradientColors[1] : gradientColors.last;
  Color get backgroundEnd => gradientColors.last;

  Color get cardColor =>
      const Color(0xFF081F44); // lighter navy — glassmorphism cards
  Color get borderColor => Colors.white.withOpacity(0.18);
  Color get mutedTextColor => textColor.withOpacity(0.55);
  Color get iconColor => accentColor;

  Color get shape1 => shapeColors.isNotEmpty ? shapeColors[0] : accentColor;
  Color get shape2 =>
      shapeColors.length > 1 ? shapeColors[1] : accentColor.withOpacity(0.6);
  Color get shape3 =>
      shapeColors.length > 2 ? shapeColors[2] : accentColor.withOpacity(0.3);
}

// Legacy named themes (backward compat)

const NuruAppTheme nuruLightTheme = NuruAppTheme(
  id: 'nuru_light',
  gradientColors: [Color(0xFF4569AD), Color(0xFF14366D)],
  shapeColors: [Color(0xFF5B8DD9), Color(0xFF3A6BA8), Color(0xFF1F3F74)],
  accentColor: Color(0xFF4569AD),
  textColor: Colors.white,
  hasStars: true,
);

const NuruAppTheme nuruDarkTheme = NuruAppTheme(
  id: 'nuru_dark',
  gradientColors: [Color(0xFF1A2D52), Color(0xFF0D1C36), Color(0xFF020C1E)],
  shapeColors: [Color(0xFF5B8DD9), Color(0xFF3A6BA8), Color(0xFF1F3F74)],
  accentColor: Color(0xFF4569AD),
  textColor: Colors.white,
  hasStars: true,
);

// Provider
class NuruThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  String _selectedPaletteId = 'nuru_default';

  bool get isDark => _isDark;
  bool get isLight => !_isDark;

  NuruColorPalette get selectedPalette => allColorPalettes.firstWhere(
    (p) => p.id == _selectedPaletteId,
    orElse: () => paletteNuruDefault,
  );

  NuruAppTheme get activeTheme {
    final p = selectedPalette;
    return NuruAppTheme(
      id: '${p.id}_${_isDark ? 'dark' : 'light'}',
      gradientColors: _isDark ? p.darkGradient : p.lightGradient,
      shapeColors: p.shapeColors,
      accentColor: p.accentColor,
      textColor: p.textColorFor(_isDark),
      secondaryTextColor: p.secondaryTextColor,
      hasStars: p.hasStars,
    );
  }

  List<NuruAppTheme> get themes => [nuruLightTheme, nuruDarkTheme];
  List<NuruAppTheme> get darkThemes => [nuruDarkTheme];
  List<NuruAppTheme> get lightThemes => [nuruLightTheme];

  NuruThemeProvider() {
    _loadFromPrefs();
  }

  void toggleDarkMode() {
    _isDark = !_isDark;
    notifyListeners();
    _saveToPrefs();
  }

  void toggleBrightness() => toggleDarkMode();

  void setColorPalette(String paletteId) {
    _selectedPaletteId = paletteId;
    notifyListeners();
    _saveToPrefs();
  }

  void resetToDefault() {
    _isDark = false;
    _selectedPaletteId = 'nuru_default';
    notifyListeners();
    _saveToPrefs();
  }

  void setTheme(String themeId) {
    if (themeId == 'nuru_dark') {
      _isDark = true;
    } else if (themeId == 'nuru_light') {
      _isDark = false;
    }
    notifyListeners();
    _saveToPrefs();
  }

  void setThemeByModel(NuruAppTheme theme) {
    _isDark = theme.id.contains('dark');
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool('nuru_is_dark') ?? false;
      _selectedPaletteId = prefs.getString('nuru_palette_id') ?? 'nuru_default';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nuru_is_dark', _isDark);
      await prefs.setString('nuru_palette_id', _selectedPaletteId);
    } catch (_) {}
  }
}

const List<NuruAppTheme> allNuruThemes = [nuruLightTheme, nuruDarkTheme];
const List<NuruAppTheme> darkNuruThemes = [nuruDarkTheme];
const List<NuruAppTheme> lightNuruThemes = [nuruLightTheme];
