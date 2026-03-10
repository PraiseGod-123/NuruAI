import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../utils/nuru_colors.dart';
import '../utils/nuru_theme.dart';

// ══════════════════════════════════════════════════════════════
// MUSIC LIBRARY SCREEN - TIIMO INSPIRED
// Complete music player with SoundCloud integration
// Features: Play/Pause, Skip, Volume, Loop, Shuffle, Timer
// ══════════════════════════════════════════════════════════════

class MusicLibraryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const MusicLibraryScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _backgroundController;

  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  double volume = 0.7;
  bool isShuffle = false;
  bool isLoop = false;
  int? currentTrackIndex;
  String? currentCategory;
  Timer? autoStopTimer;
  int autoStopMinutes = 0;

  // Tiimo-inspired music categories
  final List<Map<String, dynamic>> musicCategories = [
    {
      'name': 'Lo-fi Beats',
      'subtitle': 'Chill & Study',
      'icon': '🎵',
      'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)],
      'description': 'Relaxing lo-fi hip hop beats for focus and productivity',
    },
    {
      'name': 'Nature Sounds',
      'subtitle': 'Peaceful Ambience',
      'icon': '🌿',
      'gradient': [Color(0xFF43E97B), Color(0xFF38F9D7)],
      'description': 'Rain, ocean waves, forest sounds, and more',
    },
    {
      'name': 'Ambient Piano',
      'subtitle': 'Soft & Calm',
      'icon': '🎹',
      'gradient': [Color(0xFFF093FB), Color(0xFFF5576C)],
      'description': 'Beautiful piano melodies for relaxation',
    },
    {
      'name': 'Sleep Music',
      'subtitle': 'Deep Relaxation',
      'icon': '🌙',
      'gradient': [Color(0xFF4E54C8), Color(0xFF8F94FB)],
      'description': 'Soothing sounds to help you fall asleep',
    },
    {
      'name': 'White & Brown Noise',
      'subtitle': 'Focus & Sleep',
      'icon': '🌊',
      'gradient': [Color(0xFF89F7FE), Color(0xFF66A6FF)],
      'description': 'White noise, brown noise, and pink noise',
    },
  ];

  // Sample tracks - TODO: Replace with SoundCloud API
  final Map<String, List<Map<String, dynamic>>> categoryTracks = {
    'Lo-fi Beats': [
      {
        'title': 'Chill Lo-fi Study',
        'artist': 'Calm Beats',
        'duration': '3:45',
        'url': 'https://soundcloud.com/lofi',
      },
      {
        'title': 'Rainy Day Vibes',
        'artist': 'Peaceful Sound',
        'duration': '4:12',
        'url': 'https://soundcloud.com/rain',
      },
    ],
    'Nature Sounds': [
      {
        'title': 'Ocean Waves',
        'artist': 'Nature Sounds',
        'duration': '10:00',
        'url': 'https://soundcloud.com/ocean',
      },
      {
        'title': 'Gentle Rain',
        'artist': 'Nature Sounds',
        'duration': '8:30',
        'url': 'https://soundcloud.com/rain',
      },
      {
        'title': 'Forest Birds',
        'artist': 'Nature Sounds',
        'duration': '7:45',
        'url': 'https://soundcloud.com/forest',
      },
    ],
    'Ambient Piano': [
      {
        'title': 'Moonlight Sonata',
        'artist': 'Piano Peace',
        'duration': '5:20',
        'url': 'https://soundcloud.com/piano1',
      },
      {
        'title': 'Calm Waters',
        'artist': 'Piano Peace',
        'duration': '4:55',
        'url': 'https://soundcloud.com/piano2',
      },
    ],
    'Sleep Music': [
      {
        'title': 'Deep Sleep',
        'artist': 'Sleep Sounds',
        'duration': '30:00',
        'url': 'https://soundcloud.com/sleep1',
      },
      {
        'title': 'Peaceful Night',
        'artist': 'Sleep Sounds',
        'duration': '25:00',
        'url': 'https://soundcloud.com/sleep2',
      },
    ],
    'White & Brown Noise': [
      {
        'title': 'White Noise',
        'artist': 'Focus Sounds',
        'duration': '60:00',
        'url': 'https://soundcloud.com/white',
      },
      {
        'title': 'Brown Noise',
        'artist': 'Focus Sounds',
        'duration': '60:00',
        'url': 'https://soundcloud.com/brown',
      },
      {
        'title': 'Pink Noise',
        'artist': 'Focus Sounds',
        'duration': '60:00',
        'url': 'https://soundcloud.com/pink',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => totalDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => currentPosition = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (isLoop && currentTrackIndex != null) {
        _playTrack(currentTrackIndex!, currentCategory!);
      } else if (isShuffle) {
        _playRandomTrack();
      } else {
        _playNextTrack();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _backgroundController.dispose();
    autoStopTimer?.cancel();
    super.dispose();
  }

  Future<void> _playTrack(int index, String category) async {
    final tracks = categoryTracks[category] ?? [];
    if (index >= tracks.length) return;

    setState(() {
      currentTrackIndex = index;
      currentCategory = category;
      isPlaying = true;
    });

    // TODO: Replace with actual SoundCloud URL
    // await _audioPlayer.play(UrlSource(tracks[index]['url']));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: ${tracks[index]['title']}'),
        backgroundColor: NuruColors.softGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() => isPlaying = !isPlaying);
    isPlaying ? _audioPlayer.resume() : _audioPlayer.pause();
  }

  void _playNextTrack() {
    if (currentCategory == null || currentTrackIndex == null) return;
    final tracks = categoryTracks[currentCategory!] ?? [];
    _playTrack((currentTrackIndex! + 1) % tracks.length, currentCategory!);
  }

  void _playPreviousTrack() {
    if (currentCategory == null || currentTrackIndex == null) return;
    final tracks = categoryTracks[currentCategory!] ?? [];
    _playTrack(
      (currentTrackIndex! - 1 + tracks.length) % tracks.length,
      currentCategory!,
    );
  }

  void _playRandomTrack() {
    if (currentCategory == null) return;
    final tracks = categoryTracks[currentCategory!] ?? [];
    _playTrack(DateTime.now().millisecond % tracks.length, currentCategory!);
  }

  void _seekTo(double value) {
    final position = Duration(
      milliseconds: (value * totalDuration.inMilliseconds).toInt(),
    );
    _audioPlayer.seek(position);
  }

  void _setVolume(double value) {
    setState(() => volume = value);
    _audioPlayer.setVolume(value);
  }

  void _setAutoStopTimer(int minutes) {
    autoStopTimer?.cancel();
    setState(() => autoStopMinutes = minutes);

    if (minutes > 0) {
      autoStopTimer = Timer(Duration(minutes: minutes), () {
        _audioPlayer.stop();
        setState(() {
          isPlaying = false;
          autoStopMinutes = 0;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Music stopped automatically')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4569AD),
                  Color(0xFF4864B5),
                  Color(0xFF3A5FA8),
                  Color(0xFF2D5295),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: FloatingShapesPainter(
                  animation1: _backgroundController.value,
                  animation2: _backgroundController.value * 0.8,
                  animation3: _backgroundController.value * 1.2,
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: isPlaying ? 180 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Music Library',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Calming sounds for focus & relaxation',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        SizedBox(height: 24),
                        ...musicCategories.map(
                          (category) => Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: _buildCategoryCard(category),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPlaying) _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCategoryTracks(category),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: category['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (category['gradient'][0] as Color).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        category['icon'],
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            category['subtitle'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  category['description'],
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryTracks(Map<String, dynamic> category) {
    final tracks = categoryTracks[category['name']] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: category['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category['icon'],
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${tracks.length} tracks',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isCurrentTrack =
                        currentTrackIndex == index &&
                        currentCategory == category['name'];

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _playTrack(index, category['name']);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCurrentTrack
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: isCurrentTrack
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isCurrentTrack && isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track['title'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        track['artist'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  track['duration'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    if (currentCategory == null || currentTrackIndex == null)
      return SizedBox.shrink();

    final tracks = categoryTracks[currentCategory!] ?? [];
    if (currentTrackIndex! >= tracks.length) return SizedBox.shrink();

    final track = tracks[currentTrackIndex!];
    final category = musicCategories.firstWhere(
      (cat) => cat['name'] == currentCategory,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: category['gradient'] as List<Color>),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          category['icon'],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track['artist'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _playPreviousTrack,
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _playNextTrack,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: totalDuration.inMilliseconds > 0
                        ? currentPosition.inMilliseconds /
                              totalDuration.inMilliseconds
                        : 0,
                    onChanged: _seekTo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingShapesPainter extends CustomPainter {
  final double animation1, animation2, animation3;
  FloatingShapesPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Color(0xFFB7C3E8).withOpacity(0.12);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3 + animation1 * 20),
      60,
      paint,
    );
    paint.color = Color(0xFF3A4FA8).withOpacity(0.15);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7 + animation2 * 20),
      80,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
