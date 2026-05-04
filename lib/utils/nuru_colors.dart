import 'package:flutter/material.dart';

class NuruColors {
  // PRIMARY COLOUR PALETTE
  static const Color lilacBlue = Color(0xFFB7C3E8); // Lightest
  static const Color solidBlue = Color(0xFF8EA2D7); // Secondary elements
  static const Color sailingBlue = Color(0xFF4569AD); // Main CTAs, buttons
  static const Color dive = Color(0xFF1F3F74); // Headers, bold text
  static const Color deepSea = Color(0xFF14366D); // Body text
  static const Color nightTime = Color(0xFF081F44); // Darkest emphasis

  // NEUTRAL COLORS
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F7FA);
  static const Color mediumGray = Color(0xFFE0E6ED);
  static const Color darkGray = Color(0xFF8B95A5);

  // SEMANTIC COLORS
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // DARK NIGHT THEME COLORS
  static const Color nightBackground = Color(0xFF0A1628);
  static const Color nightCard = Color(
    0xFF081F44,
  ); // lighter navy for glassmorphism cards
  static const Color nightElevated = Color(0xFF1F2D44);
  static const Color nightAccent = Color(0xFF060D16);

  static const Color nightTextPrimary = Color(0xFFFFFFFF);
  static const Color nightTextSecondary = Color(0xFFB4C5E0);
  static const Color nightTextMuted = Color(0xFF6E7D95);
  static const Color nightTextDisabled = Color(0xFF4A5566);

  // LIGHT MORNING THEME COLORS
  static const Color morningBackground = Color(0xFFF5F8FF);
  static const Color morningCard = Color(0xFFFFFFFF);
  static const Color morningElevated = Color(0xFFF0F4FF);
  static const Color morningAccent = Color(0xFFE8F0FF);

  static const Color morningTextPrimary = Color(0xFF1A2332);
  static const Color morningTextSecondary = Color(0xFF4A5A70);
  static const Color morningTextMuted = Color(0xFF7E8EA5);
  static const Color morningTextDisabled = Color(0xFFB4C5E0);

  // SOFT PASTELS
  static const Color softBlue = Color(0xFF5B9FFF);
  static const Color softCyan = Color(0xFF7EDCFF);
  static const Color softTeal = Color(0xFF82E0D4);
  static const Color softGreen = Color(0xFF82E0AA);
  static const Color softYellow = Color(0xFFFED98B);
  static const Color softOrange = Color(0xFFFFB380);
  static const Color softPink = Color(0xFFFFB3D9);
  static const Color softRed = Color(0xFFFF9999);
  static const Color softPurple = Color(0xFFA89FED);

  // MOOD COLORS
  static const Map<String, Color> moodColors = {
    'happy': softYellow,
    'sad': softCyan,
    'angry': softRed,
    'anxious': softOrange,
    'calm': softTeal,
    'tired': softPurple,
  };

  // GRADIENTS
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

  static const LinearGradient nightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [nightBackground, nightAccent],
  );

  static const LinearGradient morningBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [morningBackground, morningAccent],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softBlue, Color(0xFF4280E0)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softCyan, Color(0xFF5BC0E8)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softTeal, Color(0xFF5FC4B8)],
  );

  // HELPERS
  static Color withOpacity(Color color, double opacity) =>
      color.withOpacity(opacity);

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

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: sailingBlue.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: lilacBlue.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: sailingBlue.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Legacy
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1C2532);
  static const Color darkCard = Color(0xFF2D3748);
}
