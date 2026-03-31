import 'package:flutter/material.dart';

// ==============================================================================
// NuruAI Theme Provider
//
// Central state for the selected app theme.
// Wrap the app with ChangeNotifierProvider<NuruThemeProvider> in main.dart.
//
//   final theme = context.watch<NuruThemeProvider>().activeTheme;
//   context.read<NuruThemeProvider>().setTheme('nuru_classic');
// ==============================================================================

class NuruAppTheme {
  final String id;
  final String fancyName;
  final String description;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color textColor;
  final bool hasStars;

  const NuruAppTheme({
    required this.id,
    required this.fancyName,
    required this.description,
    required this.gradientColors,
    required this.accentColor,
    required this.textColor,
    this.hasStars = false,
  });

  // gradientColors drives the BODY background (index 0 = top = lighter)
  // backgroundStart/Mid/End are the DARK widget fill colours (reverse order)
  // so screens that use backgroundMid/backgroundStart get the darkest values
  Color get backgroundStart => gradientColors.last; // darkest — widget fills
  Color get backgroundMid => gradientColors.length >= 3
      ? gradientColors[gradientColors.length - 2]
      : gradientColors.last; // second darkest — card tops
  Color get backgroundEnd => gradientColors.last; // darkest — gradient end

  Color get cardColor => accentColor.withOpacity(0.10);
  Color get borderColor => accentColor.withOpacity(0.20);
  Color get mutedTextColor => textColor.withOpacity(0.55);
  Color get iconColor => accentColor;
}

// ── All themes ─────────────────────────────────────────────────────────────────

const List<NuruAppTheme> allNuruThemes = [
  // ── 1. NuruAI Classic — the original app colours. Always first. ─────────────
  // gradientColors drives the BODY background (top → bottom)
  // backgroundMid + backgroundStart drive WIDGET fills (must be DARKER than body)
  // So gradientColors[0] must be LIGHTER than gradientColors[1]/[2]
  NuruAppTheme(
    id: 'nuru_classic',
    fancyName: 'NuruAI Classic',
    description: "The original Night Blue — NuruAI's home",
    gradientColors: [
      Color(0xFF4569AD), // sailing blue — onboarding bg top-left
      Color(0xFF1F3F74), // dive blue    — onboarding bg mid
      Color(
        0xFF020C1E,
      ), // near-black   — widget fills (must be very dark for opacity to work)
    ],
    accentColor: Color(0xFF4569AD), // sailing blue accent
    textColor: Colors.white,
    hasStars: true,
  ),

  // ── 2. Midnight Cosmos ───────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'midnight_cosmos',
    fancyName: 'Midnight Cosmos',
    description: 'A glittering night sky, deep and infinite',
    gradientColors: [Color(0xFF0D1117), Color(0xFF1B1040), Color(0xFF0A1628)],
    accentColor: Color(0xFF9D7FF4),
    textColor: Colors.white,
    hasStars: true,
  ),

  // ── 3. Astral Dusk ───────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'astral_dusk',
    fancyName: 'Astral Dusk',
    description: 'The hour when violet meets the horizon',
    gradientColors: [Color(0xFF1A0533), Color(0xFF3D1472), Color(0xFF7A35B8)],
    accentColor: Color(0xFFCF9FFF),
    textColor: Colors.white,
  ),

  // ── 4. Sage Canopy ───────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'sage_canopy',
    fancyName: 'Sage Canopy',
    description: 'Calm like light filtering through forest leaves',
    gradientColors: [Color(0xFF0A1F12), Color(0xFF164D2A), Color(0xFF237A44)],
    accentColor: Color(0xFF4EE688),
    textColor: Colors.white,
  ),

  // ── 5. Ocean Drift ───────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'ocean_drift',
    fancyName: 'Ocean Drift',
    description: 'Clear water, open skies, endless calm',
    gradientColors: [Color(0xFF021828), Color(0xFF063D5E), Color(0xFF0A7A9E)],
    accentColor: Color(0xFF22D4F5),
    textColor: Colors.white,
  ),

  // ── 6. Velvet Noir ───────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'velvet_noir',
    fancyName: 'Velvet Noir',
    description: 'Rich, deep, and unapologetically bold',
    gradientColors: [Color(0xFF12000A), Color(0xFF3A0022), Color(0xFF720042)],
    accentColor: Color(0xFFFF5C9E),
    textColor: Colors.white,
  ),

  // ── 7. Rose Ember ────────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'rose_ember',
    fancyName: 'Rose Ember',
    description: 'The warm glow of a rose catching last light',
    gradientColors: [Color(0xFF2A0614), Color(0xFF7A1535), Color(0xFFCC3366)],
    accentColor: Color(0xFFFF8CB4),
    textColor: Colors.white,
  ),

  // ── 8. Golden Horizon ────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'golden_horizon',
    fancyName: 'Golden Horizon',
    description: 'A clear day, sunshine, and open skies',
    gradientColors: [Color(0xFF12224A), Color(0xFF2855A0), Color(0xFFE8920A)],
    accentColor: Color(0xFFFFCA28),
    textColor: Colors.white,
  ),

  // ── 9. Blossom Mist ──────────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'blossom_mist',
    fancyName: 'Blossom Mist',
    description: 'Soft as the first petals of spring',
    gradientColors: [Color(0xFFFFE0F4), Color(0xFFFFB3E0), Color(0xFFFF80C8)],
    accentColor: Color(0xFFD63A8A),
    textColor: Color(0xFF3D0A28),
  ),

  // ── 10. Warm Parchment ───────────────────────────────────────────────────────
  NuruAppTheme(
    id: 'warm_parchment',
    fancyName: 'Warm Parchment',
    description: 'Timeless warmth, like worn paper and candlelight',
    gradientColors: [Color(0xFFF5ECD7), Color(0xFFEDD9B4), Color(0xFFE5C472)],
    accentColor: Color(0xFFBF8010),
    textColor: Color(0xFF3D2B0A),
  ),
];

// ── Provider ──────────────────────────────────────────────────────────────────

class NuruThemeProvider extends ChangeNotifier {
  // Default: NuruAI Classic
  NuruAppTheme _activeTheme = allNuruThemes.first;

  NuruAppTheme get activeTheme => _activeTheme;
  List<NuruAppTheme> get themes => allNuruThemes;

  void setTheme(String themeId) {
    final found = allNuruThemes.where((t) => t.id == themeId);
    if (found.isEmpty) return;
    _activeTheme = found.first;
    notifyListeners();
  }

  void setThemeByModel(NuruAppTheme theme) {
    _activeTheme = theme;
    notifyListeners();
  }

  void resetToDefault() {
    _activeTheme = allNuruThemes.first; // NuruAI Classic
    notifyListeners();
  }
}
