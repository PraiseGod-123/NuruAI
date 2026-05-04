import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// CALMING GAMES SCREEN
class CalmingGamesScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const CalmingGamesScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<CalmingGamesScreen> createState() => _CalmingGamesScreenState();
}

class _CalmingGamesScreenState extends State<CalmingGamesScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;

  static const List<_GameInfo> _games = [
    _GameInfo(
      id: 'piano',
      title: 'Piano Tiles',
      description:
          'Tap the dark tiles as they fall. Miss one and the music stops.',
      emoji: '🎹',
      color: Color(0xFF6C5CE7),
    ),
    _GameInfo(
      id: 'memory',
      title: 'Memory Match',
      description:
          'Flip cards to find matching emoji pairs. Train your memory gently.',
      emoji: '🃏',
      color: Color(0xFF00B894),
    ),
    _GameInfo(
      id: 'words',
      title: 'Word Calm',
      description:
          'Find hidden calming words in the letter grid. Peaceful and satisfying.',
      emoji: '📝',
      color: Color(0xFF0984E3),
    ),
    _GameInfo(
      id: 'dots',
      title: 'Dot Connect',
      description: 'Connect matching coloured dots without crossing the lines.',
      emoji: '🔴',
      color: Color(0xFFE17055),
    ),
    _GameInfo(
      id: 'bubbles',
      title: 'Bubble Pop',
      description:
          'Tap the bubbles before they float away. Calming and satisfying.',
      emoji: '🫧',
      color: Color(0xFF74B9FF),
    ),
    _GameInfo(
      id: 'orb',
      title: 'Breathing Orb',
      description:
          'Hold to expand, release to breathe out. Follow the orb\'s rhythm.',
      emoji: '🔮',
      color: Color(0xFFA29BFE),
    ),
    _GameInfo(
      id: 'sequence',
      title: 'Colour Flow',
      description: 'Watch the colours light up, then repeat the pattern.',
      emoji: '🌈',
      color: Color(0xFF55EFC4),
    ),
    _GameInfo(
      id: 'doodle',
      title: 'Zen Doodle',
      description: 'Draw freely — watch your lines glow and shimmer.',
      emoji: '✨',
      color: Color(0xFFFDCB6E),
    ),
    _GameInfo(
      id: 'stars',
      title: 'Star Catch',
      description: 'Gently tap the falling stars before they disappear.',
      emoji: '⭐',
      color: Color(0xFFFF7675),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _openGame(_GameInfo game) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0xFF081F44),
        pageBuilder: (_, __, ___) =>
            _GamePage(game: game, userData: widget.userData),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.nuruTheme.backgroundStart,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF0D1B3E),
                        const Color(0xFF1A1060),
                        _bgCtrl.value,
                      )!,
                      Color.lerp(
                        context.nuruTheme.backgroundStart,
                        const Color(0xFF0D3060),
                        _bgCtrl.value,
                      )!,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calming Games',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Fun, gentle games to help you relax',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(overscroll: false),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: _games.length,
                        itemBuilder: (_, i) => _buildGameCard(_games[i]),
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

  Widget _buildGameCard(_GameInfo game) {
    return GestureDetector(
      onTap: () => _openGame(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              game.color.withOpacity(0.18),
              game.color.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: game.color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: game.color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(game.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: game.color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameInfo {
  final String id, title, description, emoji;
  final Color color;
  const _GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });
}

//Game Page Router

class _GamePage extends StatelessWidget {
  final _GameInfo game;
  final Map<String, dynamic>? userData;
  const _GamePage({required this.game, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.nuruTheme.backgroundStart,
      body: Stack(
        children: [
          _buildGame(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    switch (game.id) {
      case 'piano':
        return const _PianoTilesGame();
      case 'memory':
        return const _MemoryMatchGame();
      case 'words':
        return const _WordCalmGame();
      case 'dots':
        return const _DotConnectGame();
      case 'bubbles':
        return const _BubblePopGame();
      case 'orb':
        return const _BreathingOrbGame();
      case 'sequence':
        return const _ColourSequenceGame();
      case 'doodle':
        return const _ZenDoodleGame();
      case 'stars':
        return const _StarCatchGame();
      default:
        return const _BubblePopGame();
    }
  }
}

// GAME 1: PIANO TILES
class _Tile {
  int col;
  double y;
  bool tapped;
  double opacity;
  _Tile({
    required this.col,
    required this.y,
    this.tapped = false,
    this.opacity = 1.0,
  });
}

class _PianoTilesGame extends StatefulWidget {
  const _PianoTilesGame();
  @override
  State<_PianoTilesGame> createState() => _PianoTilesGameState();
}

class _PianoTilesGameState extends State<_PianoTilesGame>
    with TickerProviderStateMixin {
  final List<_Tile> _tiles = [];
  final math.Random _rng = math.Random();
  late AnimationController _tickCtrl;
  int _score = 0;
  int _lives = 3;
  double _speed = 3.0;
  bool _gameOver = false;
  bool _initialized = false;
  Timer? _spawnTimer;
  int _lastCol = -1;

  @override
  void initState() {
    super.initState();
    _tickCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 16),
          )
          ..addListener(_tick)
          ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _spawnTile();
      _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        if (!_gameOver) _spawnTile();
      });
    }
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _spawnTile() {
    if (!mounted) return;
    int col;
    do {
      col = _rng.nextInt(4);
    } while (col == _lastCol);
    _lastCol = col;
    setState(() => _tiles.add(_Tile(col: col, y: -120.0)));
  }

  void _tick() {
    if (!mounted || _gameOver) return;
    final sz = MediaQuery.of(context).size;
    final tileH = sz.height * 0.18;
    setState(() {
      for (final t in _tiles) {
        if (!t.tapped) t.y += _speed;
        if (t.tapped) t.opacity -= 0.08;
      }
      // Check missed tiles
      for (final t in _tiles) {
        if (!t.tapped && t.y > sz.height) {
          t.tapped = true;
          _lives--;
          HapticFeedback.heavyImpact();
          if (_lives <= 0) _gameOver = true;
        }
      }
      _tiles.removeWhere((t) => t.tapped && t.opacity <= 0);
      // Increase speed
      _speed = 3.0 + (_score / 10).clamp(0, 5);
    });
  }

  void _tapTile(_Tile tile) {
    if (tile.tapped || _gameOver) return;
    HapticFeedback.lightImpact();
    setState(() {
      tile.tapped = true;
      _score++;
    });
  }

  void _restart() {
    setState(() {
      _tiles.clear();
      _score = 0;
      _lives = 3;
      _speed = 3.0;
      _gameOver = false;
      _lastCol = -1;
    });
    _spawnTile();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final tileW = sz.width / 4;
    final tileH = sz.height * 0.18;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.nuruTheme.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Column dividers
          ...List.generate(
            3,
            (i) => Positioned(
              left: tileW * (i + 1),
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white.withOpacity(0.08)),
            ),
          ),

          // Tiles
          ..._tiles.map(
            (t) => Positioned(
              left: tileW * t.col + 2,
              top: t.y,
              width: tileW - 4,
              height: tileH,
              child: GestureDetector(
                onTap: () => _tapTile(t),
                child: Opacity(
                  opacity: t.opacity.clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: t.tapped
                          ? const Color(0xFF6C5CE7)
                          : const Color(0xFF2D1B69),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.5),
                      ),
                      boxShadow: t.tapped
                          ? [
                              const BoxShadow(
                                color: Color(0xFF6C5CE7),
                                blurRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Score / lives
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < _lives
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: const Color(0xFFFF7675),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Game over overlay
          if (_gameOver)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Game Over',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Score: $_score',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: _restart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Play Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// GAME 2: MEMORY MATCH
class _MemoryMatchGame extends StatefulWidget {
  const _MemoryMatchGame();
  @override
  State<_MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<_MemoryMatchGame>
    with TickerProviderStateMixin {
  static const List<String> _emojis = [
    '🌸',
    '🦋',
    '🌙',
    '⭐',
    '🌈',
    '🍀',
    '🐬',
    '🌺',
  ];
  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  List<int> _selected = [];
  bool _checking = false;
  int _moves = 0;
  int _matches = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final pairs = [..._emojis, ..._emojis]..shuffle();
    setState(() {
      _cards = pairs;
      _flipped = List.filled(16, false);
      _matched = List.filled(16, false);
      _selected = [];
      _moves = 0;
      _matches = 0;
      _won = false;
      _checking = false;
    });
  }

  void _onTap(int idx) {
    if (_checking || _flipped[idx] || _matched[idx]) return;
    HapticFeedback.selectionClick();
    setState(() {
      _flipped[idx] = true;
      _selected.add(idx);
    });
    if (_selected.length == 2) {
      _moves++;
      _checking = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          if (_cards[_selected[0]] == _cards[_selected[1]]) {
            _matched[_selected[0]] = true;
            _matched[_selected[1]] = true;
            _matches++;
            HapticFeedback.lightImpact();
            if (_matches == 8) _won = true;
          } else {
            _flipped[_selected[0]] = false;
            _flipped[_selected[1]] = false;
          }
          _selected.clear();
          _checking = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.nuruTheme.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Text(
              'Memory Match',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Moves: $_moves',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'Pairs: $_matches/8',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 16,
                  itemBuilder: (_, i) {
                    final isFlipped = _flipped[i] || _matched[i];
                    return GestureDetector(
                      onTap: () => _onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: _matched[i]
                              ? const Color(0xFF00B894).withOpacity(0.3)
                              : isFlipped
                              ? const Color(0xFF2D3561)
                              : const Color(0xFF1A2550),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _matched[i]
                                ? const Color(0xFF00B894)
                                : Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: _matched[i]
                              ? [
                                  const BoxShadow(
                                    color: Color(0xFF00B894),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            isFlipped ? _cards[i] : '?',
                            style: TextStyle(
                              fontSize: isFlipped ? 26 : 18,
                              color: Colors.white.withOpacity(
                                isFlipped ? 1 : 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_won) ...[
              const SizedBox(height: 16),
              const Text(
                '🎉 You won!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _initGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// GAME 3: WORD CALM — drag to select words in the grid
class _WordCalmGame extends StatefulWidget {
  const _WordCalmGame();
  @override
  State<_WordCalmGame> createState() => _WordCalmGameState();
}

class _WordCalmGameState extends State<_WordCalmGame> {
  static const int _gridSize = 7;
  static const List<String> _words = [
    'CALM',
    'PEACE',
    'LOVE',
    'REST',
    'JOY',
    'SAFE',
    'HOPE',
  ];

  late List<List<String>> _grid;
  late List<List<bool>> _highlighted;
  final Map<String, List<List<int>>> _wordPositions = {};
  final Set<String> _foundWords = {};
  // Drag selection
  int? _startRow, _startCol, _endRow, _endCol;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _buildGrid();
  }

  void _buildGrid() {
    _grid = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => ''),
    );
    _highlighted = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => false),
    );
    _wordPositions.clear();
    _foundWords.clear();
    _won = false;
    _startRow = _startCol = _endRow = _endCol = null;

    // Fixed placements for reliability
    final placements = [
      ['CALM', 0, 0, 0, 1], // row 0, col 0, right
      ['PEACE', 1, 0, 0, 1], // row 1, col 0, right
      ['LOVE', 2, 0, 0, 1], // row 2, col 0, right
      ['REST', 3, 0, 0, 1], // row 3, col 0, right
      ['JOY', 4, 0, 0, 1], // row 4, col 0, right
      ['SAFE', 5, 0, 0, 1], // row 5, col 0, right
      ['HOPE', 6, 0, 0, 1], // row 6, col 0, right
    ];

    for (final p in placements) {
      final word = p[0] as String;
      final row = p[1] as int;
      final col = p[2] as int;
      final dr = p[3] as int;
      final dc = p[4] as int;
      final positions = <List<int>>[];
      for (int i = 0; i < word.length; i++) {
        final r = row + dr * i;
        final c = col + dc * i;
        _grid[r][c] = word[i];
        positions.add([r, c]);
      }
      _wordPositions[word] = positions;
    }

    // Fill empty with random letters
    final rng = math.Random(99);
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_grid[r][c] == '')
          _grid[r][c] = letters[rng.nextInt(letters.length)];
      }
    }
  }

  // Convert local position to grid cell
  List<int>? _posToCell(
    Offset local,
    double cellSize,
    double padH,
    double padV,
  ) {
    final c = ((local.dx - padH) / cellSize).floor();
    final r = ((local.dy - padV) / cellSize).floor();
    if (r < 0 || r >= _gridSize || c < 0 || c >= _gridSize) return null;
    return [r, c];
  }

  // Get all cells between start and end in a straight line
  List<List<int>> _getCells(int r1, int c1, int r2, int c2) {
    final cells = <List<int>>[];
    final dr = (r2 - r1 == 0) ? 0 : (r2 - r1) ~/ (r2 - r1).abs();
    final dc = (c2 - c1 == 0) ? 0 : (c2 - c1) ~/ (c2 - c1).abs();
    // Only allow straight lines (horizontal, vertical, diagonal)
    final rowDiff = (r2 - r1).abs();
    final colDiff = (c2 - c1).abs();
    if (rowDiff != 0 && colDiff != 0 && rowDiff != colDiff) {
      cells.add([r1, c1]);
      return cells;
    }
    int r = r1, c = c1;
    while (true) {
      cells.add([r, c]);
      if (r == r2 && c == c2) break;
      r += dr;
      c += dc;
    }
    return cells;
  }

  void _onPanEnd(double cellSize, double padH, double padV) {
    if (_startRow == null || _endRow == null) {
      setState(() {
        _startRow = _startCol = _endRow = _endCol = null;
      });
      return;
    }
    final cells = _getCells(_startRow!, _startCol!, _endRow!, _endCol!);
    final selected = cells.map((p) => _grid[p[0]][p[1]]).join();
    final reversed = selected.split('').reversed.join();

    for (final word in _words) {
      if (_foundWords.contains(word)) continue;
      if (selected == word || reversed == word) {
        // Verify positions match
        final positions = _wordPositions[word]!;
        bool match = false;
        if (cells.length == positions.length) {
          // forward
          bool fwd = true;
          for (int i = 0; i < cells.length; i++) {
            if (cells[i][0] != positions[i][0] ||
                cells[i][1] != positions[i][1]) {
              fwd = false;
              break;
            }
          }
          // backward
          bool bwd = true;
          for (int i = 0; i < cells.length; i++) {
            final j = cells.length - 1 - i;
            if (cells[i][0] != positions[j][0] ||
                cells[i][1] != positions[j][1]) {
              bwd = false;
              break;
            }
          }
          match = fwd || bwd;
        }
        if (match) {
          setState(() {
            _foundWords.add(word);
            for (final p in positions) _highlighted[p[0]][p[1]] = true;
            if (_foundWords.length == _words.length) _won = true;
          });
          HapticFeedback.lightImpact();
          break;
        }
      }
    }
    setState(() {
      _startRow = _startCol = _endRow = _endCol = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    const padH = 16.0;
    const padV = 220.0;
    final cellSize = (sz.width - padH * 2) / _gridSize;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.nuruTheme.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 56),
            const Text(
              'Word Calm',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Drag to find the hidden words',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),

            // Word list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _words
                    .map(
                      (w) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _foundWords.contains(w)
                              ? const Color(0xFF0984E3).withOpacity(0.4)
                              : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _foundWords.contains(w)
                                ? const Color(0xFF0984E3)
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: 13,
                            color: _foundWords.contains(w)
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                            decoration: _foundWords.contains(w)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: padH),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final cs = constraints.maxWidth / _gridSize;
                    return GestureDetector(
                      onPanStart: (d) {
                        final cell = _posToCell(d.localPosition, cs, 0, 0);
                        if (cell != null)
                          setState(() {
                            _startRow = cell[0];
                            _startCol = cell[1];
                            _endRow = cell[0];
                            _endCol = cell[1];
                          });
                      },
                      onPanUpdate: (d) {
                        final cell = _posToCell(d.localPosition, cs, 0, 0);
                        if (cell != null)
                          setState(() {
                            _endRow = cell[0];
                            _endCol = cell[1];
                          });
                      },
                      onPanEnd: (_) => _onPanEnd(cs, 0, 0),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (_, i) {
                          final r = i ~/ _gridSize, c = i % _gridSize;
                          final isHighlighted = _highlighted[r][c];

                          // Check if in current drag selection
                          bool inDrag = false;
                          if (_startRow != null && _endRow != null) {
                            final dragCells = _getCells(
                              _startRow!,
                              _startCol!,
                              _endRow!,
                              _endCol!,
                            );
                            inDrag = dragCells.any(
                              (p) => p[0] == r && p[1] == c,
                            );
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? const Color(0xFF0984E3).withOpacity(0.5)
                                  : inDrag
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isHighlighted
                                    ? const Color(0xFF0984E3).withOpacity(0.7)
                                    : inDrag
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.08),
                                width: inDrag ? 1.5 : 1,
                              ),
                              boxShadow: isHighlighted
                                  ? [
                                      const BoxShadow(
                                        color: Color(0xFF0984E3),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _grid[r][c],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isHighlighted
                                      ? Colors.white
                                      : inDrag
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.65),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Win / progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: _won
                  ? Column(
                      children: [
                        const Text(
                          '🎉 All words found!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _buildGrid()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0984E3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Play Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${_foundWords.length}/${_words.length} words found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// GAME 4: DOT CONNECT
class _DotConnectGame extends StatefulWidget {
  const _DotConnectGame();
  @override
  State<_DotConnectGame> createState() => _DotConnectGameState();
}

class _DotConnectGameState extends State<_DotConnectGame> {
  static const int _gridSize = 5;
  static const List<Color> _dotColors = [
    Color(0xFFFF7675),
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
    Color(0xFFFDCB6E),
    Color(0xFFE17EFF),
  ];

  // Puzzle: list of dot pairs [row1,col1, row2,col2, colorIndex]
  static const List<List<int>> _puzzle = [
    [0, 0, 4, 4, 0], // red
    [0, 4, 4, 0, 1], // blue
    [0, 2, 2, 4, 2], // green
    [2, 0, 2, 4, 3], // yellow
    [1, 1, 3, 3, 4], // purple
  ];

  final Map<int, List<Offset>> _paths = {};
  int? _drawing; // color index being drawn
  List<Offset> _currentPath = [];
  bool _won = false;

  bool _isDot(
    double dx,
    double dy,
    double cellSize,
    double offsetX,
    double offsetY,
  ) {
    for (final p in _puzzle) {
      final r1 = p[0], c1 = p[1], r2 = p[2], c2 = p[3];
      final x1 = offsetX + c1 * cellSize + cellSize / 2;
      final y1 = offsetY + r1 * cellSize + cellSize / 2;
      final x2 = offsetX + c2 * cellSize + cellSize / 2;
      final y2 = offsetY + r2 * cellSize + cellSize / 2;
      if ((dx - x1).abs() < 20 && (dy - y1).abs() < 20) return true;
      if ((dx - x2).abs() < 20 && (dy - y2).abs() < 20) return true;
    }
    return false;
  }

  int? _colorAtDot(
    double dx,
    double dy,
    double cellSize,
    double offX,
    double offY,
  ) {
    for (final p in _puzzle) {
      final r1 = p[0], c1 = p[1], r2 = p[2], c2 = p[3], ci = p[4];
      final x1 = offX + c1 * cellSize + cellSize / 2;
      final y1 = offY + r1 * cellSize + cellSize / 2;
      final x2 = offX + c2 * cellSize + cellSize / 2;
      final y2 = offY + r2 * cellSize + cellSize / 2;
      if ((dx - x1).abs() < 22 && (dy - y1).abs() < 22) return ci;
      if ((dx - x2).abs() < 22 && (dy - y2).abs() < 22) return ci;
    }
    return null;
  }

  void _checkWin() {
    if (_paths.length == _puzzle.length) {
      setState(() => _won = true);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final gridW = sz.width - 40;
    final cellSize = gridW / _gridSize;
    final offX = 20.0;
    final offY = sz.height * 0.25;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.nuruTheme.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'Dot Connect',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect matching dots',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Game area
          GestureDetector(
            onPanStart: (d) {
              final ci = _colorAtDot(
                d.localPosition.dx,
                d.localPosition.dy,
                cellSize,
                offX,
                offY,
              );
              if (ci != null) {
                setState(() {
                  _drawing = ci;
                  _currentPath = [d.localPosition];
                  _paths.remove(ci);
                });
              }
            },
            onPanUpdate: (d) {
              if (_drawing != null) {
                setState(() => _currentPath.add(d.localPosition));
              }
            },
            onPanEnd: (_) {
              if (_drawing != null && _currentPath.isNotEmpty) {
                final last = _currentPath.last;
                final ci = _colorAtDot(last.dx, last.dy, cellSize, offX, offY);
                if (ci == _drawing) {
                  setState(() => _paths[_drawing!] = List.from(_currentPath));
                  _checkWin();
                }
                setState(() {
                  _drawing = null;
                  _currentPath = [];
                });
              }
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _DotConnectPainter(
                puzzle: _puzzle,
                colors: _dotColors,
                cellSize: cellSize,
                offX: offX,
                offY: offY,
                paths: _paths,
                currentPath: _currentPath,
                drawingColor: _drawing != null ? _dotColors[_drawing!] : null,
              ),
            ),
          ),

          // Reset button
          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => setState(() {
                _paths.clear();
                _drawing = null;
                _currentPath = [];
                _won = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // Win overlay
          if (_won)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉 Solved!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() {
                        _paths.clear();
                        _won = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE17055),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Play Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DotConnectPainter extends CustomPainter {
  final List<List<int>> puzzle;
  final List<Color> colors;
  final double cellSize, offX, offY;
  final Map<int, List<Offset>> paths;
  final List<Offset> currentPath;
  final Color? drawingColor;

  _DotConnectPainter({
    required this.puzzle,
    required this.colors,
    required this.cellSize,
    required this.offX,
    required this.offY,
    required this.paths,
    required this.currentPath,
    this.drawingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke;
    for (int r = 0; r <= 5; r++) {
      canvas.drawLine(
        Offset(offX, offY + r * cellSize),
        Offset(offX + 5 * cellSize, offY + r * cellSize),
        gridPaint,
      );
    }
    for (int c = 0; c <= 5; c++) {
      canvas.drawLine(
        Offset(offX + c * cellSize, offY),
        Offset(offX + c * cellSize, offY + 5 * cellSize),
        gridPaint,
      );
    }

    // Draw completed paths
    for (final entry in paths.entries) {
      final color = colors[entry.key];
      final paint = Paint()
        ..color = color.withOpacity(0.7)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (entry.value.length < 2) continue;
      final path = Path()..moveTo(entry.value[0].dx, entry.value[0].dy);
      for (int i = 1; i < entry.value.length; i++)
        path.lineTo(entry.value[i].dx, entry.value[i].dy);
      canvas.drawPath(path, paint);
    }

    // Draw current path
    if (currentPath.length >= 2 && drawingColor != null) {
      final paint = Paint()
        ..color = drawingColor!.withOpacity(0.8)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(currentPath[0].dx, currentPath[0].dy);
      for (int i = 1; i < currentPath.length; i++)
        path.lineTo(currentPath[i].dx, currentPath[i].dy);
      canvas.drawPath(path, paint);
    }

    // Draw dots
    for (final p in puzzle) {
      final color = colors[p[4]];
      final x1 = offX + p[1] * cellSize + cellSize / 2;
      final y1 = offY + p[0] * cellSize + cellSize / 2;
      final x2 = offX + p[3] * cellSize + cellSize / 2;
      final y2 = offY + p[2] * cellSize + cellSize / 2;

      for (final pt in [Offset(x1, y1), Offset(x2, y2)]) {
        canvas.drawCircle(
          pt,
          16,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pt,
          16,
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          pt,
          8,
          Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DotConnectPainter old) => true;
}

// GAME 5: BUBBLE POP
class _Bubble {
  double x, y, size, speed, opacity;
  Color color;
  bool popped;
  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    this.popped = false,
    this.opacity = 1.0,
  });
}

class _BubblePopGame extends StatefulWidget {
  const _BubblePopGame();
  @override
  State<_BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<_BubblePopGame>
    with TickerProviderStateMixin {
  final List<_Bubble> _bubbles = [];
  final math.Random _rng = math.Random();
  late AnimationController _tickCtrl;
  int _score = 0;
  Timer? _spawnTimer;
  bool _initialized = false;

  static const List<Color> _colors = [
    Color(0xFF74B9FF),
    Color(0xFFA29BFE),
    Color(0xFF55EFC4),
    Color(0xFFFDCB6E),
    Color(0xFFFF7675),
    Color(0xFFE17EFF),
  ];

  @override
  void initState() {
    super.initState();
    _tickCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 16),
          )
          ..addListener(_tick)
          ..repeat();
    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _spawnBubble(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      for (int i = 0; i < 4; i++) _spawnBubble();
    }
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _spawnBubble() {
    if (!mounted) return;
    final sz = MediaQuery.of(context).size;
    setState(
      () => _bubbles.add(
        _Bubble(
          x: _rng.nextDouble() * (sz.width - 80) + 40,
          y: sz.height + 40,
          size: 32 + _rng.nextDouble() * 38,
          speed: 0.8 + _rng.nextDouble() * 1.2,
          color: _colors[_rng.nextInt(_colors.length)],
        ),
      ),
    );
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final b in _bubbles) {
        if (!b.popped) b.y -= b.speed;
        if (b.popped) b.opacity -= 0.05;
      }
      _bubbles.removeWhere((b) => b.y < -80 || (b.popped && b.opacity <= 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: context.nuruTheme.gradientColors,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'bubbles popped',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ..._bubbles.map(
          (b) => Positioned(
            left: b.x - b.size / 2,
            top: b.y - b.size / 2,
            child: GestureDetector(
              onTap: () {
                if (!b.popped) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    b.popped = true;
                    _score++;
                  });
                }
              },
              child: Opacity(
                opacity: b.opacity.clamp(0.0, 1.0),
                child: AnimatedScale(
                  scale: b.popped ? 1.4 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: b.size,
                    height: b.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: b.color.withOpacity(0.2),
                      border: Border.all(
                        color: b.color.withOpacity(0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: b.color.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: b.size * 0.2,
                        height: b.size * 0.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// GAME 6: BREATHING ORB
class _BreathingOrbGame extends StatefulWidget {
  const _BreathingOrbGame();
  @override
  State<_BreathingOrbGame> createState() => _BreathingOrbGameState();
}

class _BreathingOrbGameState extends State<_BreathingOrbGame>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  bool _pressing = false;
  String _phase = 'Tap and hold to breathe in';
  int _cycles = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.nuruTheme.gradientColors,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Text(
            _phase,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$_cycles cycles completed',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 60),
          AnimatedBuilder(
            animation: Listenable.merge([_pulseCtrl, _glowCtrl]),
            builder: (_, __) {
              final scale = 0.6 + _pulseCtrl.value * 0.5;
              final glow = 0.5 + _glowCtrl.value * 0.5;
              final orbSz = sz.width * 0.55 * scale;
              return GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _pressing = true;
                    _phase = 'Breathe in slowly...';
                  });
                  _pulseCtrl.forward();
                },
                onTapUp: (_) {
                  setState(() {
                    _pressing = false;
                    _phase = 'Breathe out slowly...';
                  });
                  _pulseCtrl.reverse().then((_) {
                    if (mounted)
                      setState(() {
                        _phase = 'Tap and hold to breathe in';
                        _cycles++;
                      });
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _pressing = false;
                  });
                  _pulseCtrl.reverse().then((_) {
                    if (mounted)
                      setState(() {
                        _phase = 'Tap and hold to breathe in';
                        _cycles++;
                      });
                  });
                },
                child: Container(
                  width: orbSz,
                  height: orbSz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA29BFE).withOpacity(0.9),
                        const Color(0xFF6C5CE7).withOpacity(0.6),
                        const Color(0xFF4834D4).withOpacity(0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA29BFE).withOpacity(0.4 * glow),
                        blurRadius: 60 * glow,
                        spreadRadius: 20 * glow,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _pressing
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: orbSz * 0.25,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// GAME 7: COLOUR SEQUENCE
class _ColourSequenceGame extends StatefulWidget {
  const _ColourSequenceGame();
  @override
  State<_ColourSequenceGame> createState() => _ColourSequenceGameState();
}

class _ColourSequenceGameState extends State<_ColourSequenceGame>
    with TickerProviderStateMixin {
  final math.Random _rng = math.Random();
  final List<int> _sequence = [];
  final List<int> _userInput = [];
  int _activeIdx = -1;
  bool _canInput = false;
  int _level = 1;
  String _status = 'Watch the pattern';
  bool _failed = false;

  static const List<Color> _colors = [
    Color(0xFFFF7675),
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
    Color(0xFFFDCB6E),
  ];
  static const List<String> _labels = ['Red', 'Blue', 'Green', 'Yellow'];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), _startRound);
  }

  void _startRound() {
    _sequence.add(_rng.nextInt(4));
    _userInput.clear();
    setState(() {
      _canInput = false;
      _status = 'Watch the pattern';
      _failed = false;
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _activeIdx = _sequence[i]);
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _activeIdx = -1);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    setState(() {
      _canInput = true;
      _status = 'Your turn! Repeat the pattern';
    });
  }

  void _onTap(int idx) {
    if (!_canInput || _failed) return;
    HapticFeedback.lightImpact();
    setState(() => _activeIdx = idx);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _activeIdx = -1);
    });
    _userInput.add(idx);
    final pos = _userInput.length - 1;
    if (_userInput[pos] != _sequence[pos]) {
      HapticFeedback.heavyImpact();
      setState(() {
        _failed = true;
        _canInput = false;
        _status = 'Not quite! Starting over...';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _sequence.clear();
          _level = 1;
          _startRound();
        }
      });
      return;
    }
    if (_userInput.length == _sequence.length) {
      setState(() {
        _canInput = false;
        _level++;
        _status = '✓ Perfect! Level $_level';
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startRound();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.nuruTheme.gradientColors,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Text(
            'Level $_level',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(4, (i) {
                final active = _activeIdx == i;
                return GestureDetector(
                  onTap: () => _onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: active ? _colors[i] : _colors[i].withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _colors[i].withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _colors[i].withOpacity(0.6),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _canInput ? 'Tap the colours in order' : '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}

// GAME 8: ZEN DOODLE
class _DoodleLine {
  final List<Offset> points;
  final Color color;
  _DoodleLine({required this.points, required this.color});
}

class _ZenDoodleGame extends StatefulWidget {
  const _ZenDoodleGame();
  @override
  State<_ZenDoodleGame> createState() => _ZenDoodleGameState();
}

class _ZenDoodleGameState extends State<_ZenDoodleGame>
    with TickerProviderStateMixin {
  final List<_DoodleLine> _lines = [];
  _DoodleLine? _current;
  late AnimationController _glowCtrl;
  int _colorIdx = 0;

  static const List<Color> _palette = [
    Color(0xFF74B9FF),
    Color(0xFFA29BFE),
    Color(0xFF55EFC4),
    Color(0xFFFDCB6E),
    Color(0xFFFF7675),
    Color(0xFFE17EFF),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050D1F),
      child: Stack(
        children: [
          GestureDetector(
            onPanStart: (d) => setState(
              () => _current = _DoodleLine(
                points: [d.localPosition],
                color: _palette[_colorIdx],
              ),
            ),
            onPanUpdate: (d) {
              if (_current != null)
                setState(() => _current!.points.add(d.localPosition));
            },
            onPanEnd: (_) {
              if (_current != null)
                setState(() {
                  _lines.add(_current!);
                  _current = null;
                  _colorIdx = (_colorIdx + 1) % _palette.length;
                });
            },
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: _DoodlePainter(
                  lines: _lines,
                  current: _current,
                  glow: 0.5 + _glowCtrl.value * 0.5,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56),
                const Text(
                  'Zen Doodle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Draw freely — watch it glow',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            right: 24,
            child: GestureDetector(
              onTap: () => setState(() {
                _lines.clear();
                _current = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _palette[_colorIdx],
                boxShadow: [
                  BoxShadow(
                    color: _palette[_colorIdx].withOpacity(0.6),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<_DoodleLine> lines;
  final _DoodleLine? current;
  final double glow;
  _DoodlePainter({required this.lines, this.current, required this.glow});
  @override
  void paint(Canvas canvas, Size size) {
    for (final line in [...lines, if (current != null) current!]) {
      if (line.points.length < 2) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * glow);
      final path = Path()..moveTo(line.points[0].dx, line.points[0].dy);
      for (int i = 1; i < line.points.length; i++)
        path.lineTo(line.points[i].dx, line.points[i].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => true;
}

// GAME 9: STAR CATCH
class _StarItem {
  double x, y, size, speed, opacity;
  Color color;
  bool caught;
  _StarItem({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    this.caught = false,
    this.opacity = 1.0,
  });
}

class _StarCatchGame extends StatefulWidget {
  const _StarCatchGame();
  @override
  State<_StarCatchGame> createState() => _StarCatchGameState();
}

class _StarCatchGameState extends State<_StarCatchGame>
    with TickerProviderStateMixin {
  final List<_StarItem> _stars = [];
  final math.Random _rng = math.Random();
  late AnimationController _tickCtrl;
  int _score = 0, _missed = 0;
  Timer? _spawnTimer;
  bool _initialized = false;

  static const List<Color> _starColors = [
    Color(0xFFFDCB6E),
    Color(0xFFFFFFFF),
    Color(0xFFA29BFE),
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
  ];

  @override
  void initState() {
    super.initState();
    _tickCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 16),
          )
          ..addListener(_tick)
          ..repeat();
    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => _spawnStar(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      for (int i = 0; i < 3; i++) _spawnStar();
    }
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _spawnStar() {
    if (!mounted) return;
    final sz = MediaQuery.of(context).size;
    setState(
      () => _stars.add(
        _StarItem(
          x: _rng.nextDouble() * (sz.width - 60) + 30,
          y: -30,
          size: 20 + _rng.nextDouble() * 24,
          speed: 1.0 + _rng.nextDouble() * 1.5,
          color: _starColors[_rng.nextInt(_starColors.length)],
        ),
      ),
    );
  }

  void _tick() {
    if (!mounted) return;
    final sz = MediaQuery.of(context).size;
    setState(() {
      for (final s in _stars) {
        if (!s.caught) s.y += s.speed;
        if (s.caught) s.opacity -= 0.06;
        if (s.y > sz.height + 30 && !s.caught) {
          s.caught = true;
          _missed++;
        }
      }
      _stars.removeWhere((s) => s.caught && s.opacity <= 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: context.nuruTheme.gradientColors,
            ),
          ),
        ),
        ..._stars.map(
          (s) => Positioned(
            left: s.x - s.size,
            top: s.y - s.size,
            child: GestureDetector(
              onTap: () {
                if (!s.caught) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    s.caught = true;
                    _score++;
                  });
                }
              },
              child: Opacity(
                opacity: s.opacity.clamp(0.0, 1.0),
                child: AnimatedScale(
                  scale: s.caught ? 1.5 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: SizedBox(
                    width: s.size * 2,
                    height: s.size * 2,
                    child: Center(
                      child: Text(
                        '⭐',
                        style: TextStyle(
                          fontSize: s.size,
                          shadows: [
                            Shadow(
                              color: s.color.withOpacity(0.8),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'stars caught',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_missed missed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
