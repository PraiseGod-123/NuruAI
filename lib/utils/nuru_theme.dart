import 'package:flutter/material.dart';
import 'nuru_colors.dart';

class NuruTheme {
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // BORDER RADIUS
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;

  // CARD DECORATIONS
  static BoxDecoration darkCard({Color? backgroundColor, Gradient? gradient}) {
    return BoxDecoration(
      color: backgroundColor ?? NuruColors.nightCard,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radiusXL),
      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 40,
          offset: Offset(0, 20),
        ),
      ],
    );
  }

  //floating card for light theme
  static BoxDecoration lightCard({Color? backgroundColor, Gradient? gradient}) {
    return BoxDecoration(
      color: backgroundColor ?? NuruColors.morningCard,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radiusXL),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 30,
          offset: Offset(0, 15),
        ),
      ],
    );
  }

  //Glass morphism card for dark theme
  static BoxDecoration darkGlassCard({Color? tintColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (tintColor ?? Colors.white).withOpacity(0.12),
          (tintColor ?? Colors.white).withOpacity(0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(radiusXL),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // Glass morphism card for light theme
  static BoxDecoration lightGlassCard({Color? tintColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
      ),
      borderRadius: BorderRadius.circular(radiusXL),
      border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // BUTTON DECORATIONS
  static BoxDecoration button({
    Color? color,
    Gradient? gradient,
    bool isDark = true,
  }) {
    return BoxDecoration(
      color: color,
      gradient: gradient ?? NuruColors.blueGradient,
      borderRadius: BorderRadius.circular(radiusM),
      boxShadow: [
        BoxShadow(
          color: (color ?? NuruColors.softBlue).withOpacity(isDark ? 0.3 : 0.2),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // TEXT STYLES (DARK THEME)
  static const darkH1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: NuruColors.nightTextPrimary,
    height: 1.2,
  );

  static const darkH2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: NuruColors.nightTextPrimary,
    height: 1.3,
  );

  static const darkH3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: NuruColors.nightTextPrimary,
    height: 1.4,
  );

  static const darkBody1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: NuruColors.nightTextPrimary,
    height: 1.5,
  );

  static const darkBody2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: NuruColors.nightTextSecondary,
    height: 1.5,
  );

  static const darkCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: NuruColors.nightTextMuted,
    height: 1.4,
  );

  // TEXT STYLES (LIGHT THEME)
  static const lightH1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: NuruColors.morningTextPrimary,
    height: 1.2,
  );

  static const lightH2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: NuruColors.morningTextPrimary,
    height: 1.3,
  );

  static const lightH3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: NuruColors.morningTextPrimary,
    height: 1.4,
  );

  static const lightBody1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: NuruColors.morningTextPrimary,
    height: 1.5,
  );

  static const lightBody2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: NuruColors.morningTextSecondary,
    height: 1.5,
  );

  static const lightCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: NuruColors.morningTextMuted,
    height: 1.4,
  );

  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
