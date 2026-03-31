import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';

// ==============================================================================
// Theme Selection Screen
//
// Opened from Profile > Appearance > Theme.
// Shows all 9 NuruAI themes as a preview card + grid of tiles.
// When the user taps Apply, it calls NuruThemeProvider.setThemeByModel()
// which triggers a rebuild on every screen listening to the provider.
// ==============================================================================

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen>
    with TickerProviderStateMixin {
  late String _selectedId;
  late AnimationController _starController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _selectedId = context.read<NuruThemeProvider>().activeTheme.id;

    _starController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _starController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  NuruAppTheme get _selectedTheme =>
      allNuruThemes.firstWhere((t) => t.id == _selectedId);

  void _selectTheme(NuruAppTheme theme) {
    setState(() => _selectedId = theme.id);
  }

  void _applyTheme() {
    context.read<NuruThemeProvider>().setThemeByModel(_selectedTheme);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedTheme.fancyName} applied',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _selectedTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPreview(),
            Expanded(child: _buildGrid()),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
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
            'Choose Your Theme',
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

  Widget _buildPreview() {
    final theme = _selectedTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.accentColor.withOpacity(
                  0.6 * _glowAnimation.value,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withOpacity(
                    0.3 * _glowAnimation.value,
                  ),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  if (theme.hasStars)
                    AnimatedBuilder(
                      animation: _starController,
                      builder: (_, __) => CustomPaint(
                        painter: _StarFieldPainter(_starController.value),
                        size: Size.infinite,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accentColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.accentColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'PREVIEW',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.accentColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          theme.fancyName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: theme.textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textColor.withOpacity(0.65),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Themes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: allNuruThemes.length,
              itemBuilder: (context, index) {
                final theme = allNuruThemes[index];
                final isSelected = theme.id == _selectedId;
                return _buildTile(theme, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(NuruAppTheme theme, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectTheme(theme),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.accentColor.withOpacity(0.9 * _glowAnimation.value)
                    : Colors.white.withOpacity(0.08),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.accentColor.withOpacity(
                          0.4 * _glowAnimation.value,
                        ),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                if (theme.hasStars && isSelected)
                  AnimatedBuilder(
                    animation: _starController,
                    builder: (_, __) => CustomPaint(
                      painter: _StarFieldPainter(
                        _starController.value,
                        density: 30,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      Text(
                        theme.fancyName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplyButton() {
    final theme = _selectedTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return GestureDetector(
            onTap: _applyTheme,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.accentColor,
                    theme.accentColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentColor.withOpacity(
                      0.4 * _glowAnimation.value,
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Apply ${theme.fancyName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Star field painter ────────────────────────────────────────

class _StarFieldPainter extends CustomPainter {
  final double animationValue;
  final int density;
  final List<_Star> _stars;

  _StarFieldPainter(this.animationValue, {this.density = 60})
    : _stars = _generateStars(density);

  static List<_Star> _generateStars(int count) {
    final rng = math.Random(42);
    return List.generate(
      count,
      (_) => _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 2.0 + 0.5,
        phase: rng.nextDouble() * 2 * math.pi,
        speed: rng.nextDouble() * 0.5 + 0.5,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle =
          (math.sin(animationValue * 2 * math.pi * star.speed + star.phase) +
              1) /
          2;
      final opacity = 0.3 + twinkle * 0.7;
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size * (0.7 + twinkle * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) =>
      old.animationValue != animationValue;
}

class _Star {
  final double x, y, size, phase, speed;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });
}
