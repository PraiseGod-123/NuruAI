import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// Theme Selection Screen
class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _starCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NuruThemeProvider>();
    final isDark = provider.isDark;
    final t = provider.activeTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: t.gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Stars background
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarFieldPainter(_starCtrl.value),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),

                          //Section: Brightness
                          _sectionLabel('Brightness'),
                          const SizedBox(height: 12),
                          _buildPreviewCards(isDark, provider),
                          const SizedBox(height: 12),
                          _buildToggle(context, isDark, t),

                          const SizedBox(height: 32),

                          //Section: Color Palette
                          _sectionLabel('Color Palette'),
                          const SizedBox(height: 4),
                          Text(
                            'Tap a palette to change the app\'s look',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPaletteGrid(context, provider),

                          const SizedBox(height: 32),

                          //Reset
                          _buildResetButton(context, provider),
                          const SizedBox(height: 16),
                          _buildDoneButton(context, t),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Section label

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.50),
        letterSpacing: 1.2,
      ),
    );
  }

  //Header

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Appearance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  //Side-by-side preview cards

  Widget _buildPreviewCards(bool isDark, NuruThemeProvider provider) {
    final palette = provider.selectedPalette;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        return Row(
          children: [
            Expanded(
              child: _buildCard(
                label: 'Light',
                subtitle: 'Original style',
                gradientColors: palette.lightGradient,
                accentColor: palette.accentColor,
                isSelected: !isDark,
                onTap: () =>
                    context.read<NuruThemeProvider>().setTheme('nuru_light'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCard(
                label: 'Dark',
                subtitle: 'Deeper tones',
                gradientColors: palette.darkGradient,
                accentColor: palette.accentColor,
                isSelected: isDark,
                onTap: () =>
                    context.read<NuruThemeProvider>().setTheme('nuru_dark'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final glow = _glowCtrl.value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? accentColor.withOpacity(0.5 + glow * 0.4)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3 + glow * 0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (isSelected)
              AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarFieldPainter(_starCtrl.value, density: 18),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 5,
                    width: 34,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Toggle switch

  Widget _buildToggle(BuildContext context, bool isDark, NuruAppTheme t) {
    return GestureDetector(
      onTap: () => context.read<NuruThemeProvider>().toggleDarkMode(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: t.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isDark
                        ? 'Tap to switch to light mode'
                        : 'Tap to switch to dark mode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: isDark ? t.accentColor : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark
                      ? t.accentColor.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      size: 12,
                      color: isDark
                          ? const Color(0xFF4569AD)
                          : const Color(0xFFFFCA28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Color Palette Grid

  Widget _buildPaletteGrid(BuildContext context, NuruThemeProvider provider) {
    final selectedId = provider.selectedPalette.id;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: allColorPalettes.length,
      itemBuilder: (_, i) {
        final palette = allColorPalettes[i];
        final isSelected = palette.id == selectedId;
        return _buildPaletteTile(
          context: context,
          palette: palette,
          isSelected: isSelected,
          onTap: () => provider.setColorPalette(palette.id),
        );
      },
    );
  }

  Widget _buildPaletteTile({
    required BuildContext context,
    required NuruColorPalette palette,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? palette.accentColor.withOpacity(0.7)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient swatch bar
            Container(
              height: 52,
              margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.lightGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(palette.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              palette.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white.withOpacity(isSelected ? 1.0 : 0.65),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  //Reset to default button

  Widget _buildResetButton(BuildContext context, NuruThemeProvider provider) {
    final isDefault =
        provider.selectedPalette.id == 'nuru_default' && !provider.isDark;
    if (isDefault) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => provider.resetToDefault(),
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Reset to Nuru Default',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Done button

  Widget _buildDoneButton(BuildContext context, NuruAppTheme t) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [t.accentColor, t.accentColor.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: t.accentColor.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Done',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

//Star field painter

class _StarFieldPainter extends CustomPainter {
  final double t;
  final int density;

  _StarFieldPainter(this.t, {this.density = 50});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < density; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * 2 * math.pi;
      final speed = rng.nextDouble() * 0.5 + 0.5;
      final sz = rng.nextDouble() * 1.8 + 0.4;
      final twinkle = (math.sin(t * 2 * math.pi * speed + phase) + 1) / 2;
      final opacity = 0.2 + twinkle * 0.5;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), sz, paint);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.t != t;
}
