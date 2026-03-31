import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// ==============================================================================
// NuruScaffold
//
// A theme-aware scaffold wrapper used by every screen in NuruAI.
// It handles:
//   - Background gradient (from active theme)
//   - Star field animation (for themes with hasStars = true)
//   - Status bar colour (adapts to theme text colour)
//   - AnimatedContainer so theme transitions are smooth
//
// Usage — replaces Scaffold in every screen:
//
//   return NuruScaffold(
//     body: SafeArea(
//       child: Column(
//         children: [ ... your screen content ... ],
//       ),
//     ),
//   );
//
// Optional parameters:
//   bottomNavigationBar — pass your existing bottom nav widget
//   floatingActionButton — pass your FAB if needed
//   resizeToAvoidBottomInset — default true
// ==============================================================================

class NuruScaffold extends StatefulWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool showStars;

  const NuruScaffold({
    Key? key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.showStars = true,
  }) : super(key: key);

  @override
  State<NuruScaffold> createState() => _NuruScaffoldState();
}

class _NuruScaffoldState extends State<NuruScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuruTheme;

    // Status bar brightness adapts to the theme text colour
    final isDark = t.textColor == Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: t.backgroundStart,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        bottomNavigationBar: widget.bottomNavigationBar,
        floatingActionButton: widget.floatingActionButton,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Star field — only rendered for themes that have hasStars true,
              // or when showStars is explicitly true and the theme supports it
              if (widget.showStars)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _starController,
                    builder: (_, __) => CustomPaint(
                      size: Size.infinite,
                      painter: _NuruStarsPainter(
                        t: _starController.value,
                        accentColor: t.accentColor,
                        // More stars for dark themes, fewer for light ones
                        count: isDark ? 28 : 10,
                        opacity: isDark ? 0.5 : 0.15,
                      ),
                    ),
                  ),
                ),

              // Screen content
              widget.body,
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// NuruBottomNav
//
// Theme-aware bottom navigation bar used by home screens and calmme screen.
// Usage:
//
//   NuruBottomNav(
//     currentIndex: _currentNavIndex,
//     onTap: (index) { ... },
//     items: [
//       NuruNavItem(icon: Icons.home_rounded, label: 'Home'),
//       NuruNavItem(icon: Icons.spa_outlined,  label: 'CalmMe'),
//       NuruNavItem(icon: Icons.analytics_outlined, label: 'Analytics'),
//       NuruNavItem(icon: Icons.person_outline, label: 'Profile'),
//     ],
//   )
// ==============================================================================

class NuruNavItem {
  final IconData icon;
  final String label;
  const NuruNavItem({required this.icon, required this.label});
}

class NuruBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NuruNavItem> items;

  const NuruBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.nuruTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.backgroundMid, t.backgroundStart],
        ),
        border: Border(
          top: BorderSide(color: t.accentColor.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? t.accentColor.withOpacity(0.20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: t.accentColor.withOpacity(0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? t.textColor
                        : t.textColor.withOpacity(0.45),
                    size: 26,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? t.textColor
                          : t.textColor.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ==============================================================================
// NuruCard
//
// Theme-aware card used throughout the app.
// Replaces all the custom darkCard / glassCard containers in every screen.
//
// Usage:
//   NuruCard(
//     child: Column(children: [ ... ]),
//   )
//
//   NuruCard(
//     padding: EdgeInsets.all(20),
//     child: Text('Hello'),
//   )
// ==============================================================================

class NuruCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? overrideColor;

  const NuruCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.overrideColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.nuruTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: padding,
      decoration: BoxDecoration(
        color: overrideColor ?? t.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: t.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: t.backgroundStart.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==============================================================================
// NuruAccentButton
//
// Theme-aware primary action button.
//
// Usage:
//   NuruAccentButton(
//     label: 'Start Breathing',
//     icon: Icons.air_rounded,
//     onTap: () { ... },
//   )
// ==============================================================================

class NuruAccentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double? width;
  final double height;

  const NuruAccentButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
    this.height = 54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.nuruTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [t.accentColor, t.accentColor.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: t.accentColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.textColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// NuruAppBar
//
// Theme-aware app bar row used at the top of most screens.
//
// Usage:
//   NuruAppBar(
//     title: 'Breathing',
//     subtitle: 'Calm your mind',
//     onBack: () => Navigator.pop(context),
//   )
// ==============================================================================

class NuruAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const NuruAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.nuruTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.accentColor.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: t.textColor,
                  size: 18,
                ),
              ),
            ),
          if (onBack != null) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: t.textColor,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: t.mutedTextColor),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ==============================================================================
// Star field painter — used by NuruScaffold
// ==============================================================================

class _NuruStarsPainter extends CustomPainter {
  final double t;
  final Color accentColor;
  final int count;
  final double opacity;

  static final List<List<double>> _positions = List.generate(40, (i) {
    final rng = math.Random(i * 13 + 7);
    return [rng.nextDouble(), rng.nextDouble(), rng.nextDouble()];
  });

  const _NuruStarsPainter({
    required this.t,
    required this.accentColor,
    this.count = 28,
    this.opacity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stars = _positions.take(count);

    for (final s in stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final off = s[2];
      final op = opacity * (0.3 + ((t + off) % 1.0) * 0.7);

      paint.color = Colors.white.withOpacity(op * 0.3);
      canvas.drawCircle(Offset(x, y), 3.0, paint);
      paint.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 1.6, paint);
      paint.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(_NuruStarsPainter old) => old.t != t;
}
