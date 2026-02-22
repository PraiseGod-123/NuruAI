import 'package:flutter/material.dart';

class NuruColors {
  // Primary Color Palette
  static const Color sailingBlue = Color(0xFF4569AD); // Main CTAs, buttons
  static const Color solidBlue = Color(0xFF8EA2D7); // Secondary elements
  static const Color lilacBlue = Color(0xFFB7C3E8); // Backgrounds, cards
  static const Color dive = Color(0xFF1F3F74); // Headers, bold text
  static const Color deepSea = Color(0xFF14366D); // Body text
  static const Color nightTime = Color(0xFF081F44); // Dark text, emphasis

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F7FA);
  static const Color mediumGray = Color(0xFFE0E6ED);
  static const Color darkGray = Color(0xFF8B95A5);

  // Semantic Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sailingBlue, dive],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lilacBlue, white],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FBFF), white],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [sailingBlue, solidBlue],
  );

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1C2532);
  static const Color darkCard = Color(0xFF2D3748);

  // Opacity Helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Glassmorphism Helper
  static BoxDecoration glassCard({
    double blur = 10,
    double opacity = 0.3,
    Color? borderColor,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [white.withOpacity(opacity), white.withOpacity(opacity * 0.5)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? white.withOpacity(0.2),
        width: 1.5,
      ),
    );
  }

  // Shadow Helpers
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: sailingBlue.withOpacity(0.1),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: lilacBlue.withOpacity(0.3),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: sailingBlue.withOpacity(0.4),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}
