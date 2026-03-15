import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../services/music_service.dart';
import 'package:audioplayers/audioplayers.dart';

// ══════════════════════════════════════════════════════════════
// MUSIC LIBRARY SCREEN
//
// Tabs:
//   DISCOVER     — Jamendo (full CC tracks) or iTunes (30s previews)
//                  Six moods. Tap any track → full-screen player.
//   MY RECORDINGS — Record with flutter_sound. Name, rename, delete.
//                  Record voices of loved ones or soothing sounds.
//   FAVOURITES   — Heart any track to save here.
//
// pubspec.yaml:
//   audioplayers: ^5.2.1
//   flutter_sound: ^9.2.13
//   path_provider: ^2.1.2
//   http: ^1.2.0
// ══════════════════════════════════════════════════════════════

class MusicLibraryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const MusicLibraryScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────
  late AnimationController _starCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _visCtrl;

  // ── Audio player ─────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  MusicTrack? _current;
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  double _vol = 0.8;
  bool _shuffle = false;
  bool _loop = false;
  List<MusicTrack> _queue = [];
  bool _expanded = false;

  // ── Recorder (flutter_sound) ─────────────────────────────
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recOpen = false;
  bool _recording = false;
  int _recSecs = 0;
  Timer? _recTimer;
  List<RecordingMeta> _recordings = [];

  // ── UI state ─────────────────────────────────────────────
  int _tab = 0; // 0=Discover 1=Recordings 2=Favourites
  String _moodId = 'lofi';
  bool _loading = false;
  String? _err;
  List<MusicTrack> _tracks = [];
  List<MusicTrack> _favs = [];

  final _svc = MusicService.instance;

  // ── Palette ───────────────────────────────────────────────
  static const Color _night = Color(0xFF081F44);
  static const Color _dive = Color(0xFF1F3F74);
  static const Color _sailing = Color(0xFF4569AD);
  static const Color _deep = Color(0xFF14366D);
  static const Color _lilac = Color(0xFFB7C3E8);

  static const Map<String, Color> _moodColors = {
    'lofi': Color(0xFF6C5CE7),
    'calming': Color(0xFF0984E3),
    'sleep': Color(0xFF4E54C8),
    'piano': Color(0xFFE84393),
    'nature': Color(0xFF00B894),
    'focus': Color(0xFF43C6AC),
  };

  Color get _moodColor => _moodColors[_moodId] ?? _sailing;
  Color _trackColor(MusicTrack t) =>
      t.source == 'recording' ? const Color(0xFFFF6B9D) : _moodColor;

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _visCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _player.setVolume(_vol);
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _dur = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = (s.name == 'playing'));
    });
    _player.onPlayerComplete.listen((_) => _onComplete());

    _initRecorder();
    _loadRecordings();
    _fetch('lofi');
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    _player.dispose();
    if (_recOpen) _recorder.closeRecorder();
    _starCtrl.dispose();
    _orbCtrl.dispose();
    _visCtrl.dispose();
    super.dispose();
  }

  // ── Recorder init ─────────────────────────────────────────

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      if (mounted) setState(() => _recOpen = true);
    } catch (e) {
      debugPrint('[Music] Recorder init error: $e');
    }
  }

  Future<void> _loadRecordings() async {
    final r = await _svc.loadRecordings();
    if (mounted) setState(() => _recordings = r);
  }

  // ══════════════════════════════════════════════════════════
  // PLAYBACK
  // ══════════════════════════════════════════════════════════

  Future<void> _play(MusicTrack track, {List<MusicTrack>? queue}) async {
    setState(() {
      _current = track;
      _pos = Duration.zero;
      _dur = Duration.zero;
      if (queue != null) _queue = queue;
    });
    await _player.stop();
    if (track.isLocal) {
      await _player.play(DeviceFileSource(track.audioUrl));
    } else {
      await _player.play(UrlSource(track.audioUrl));
    }
    setState(() => _expanded = true);
  }

  void _togglePP() {
    if (_playing)
      _player.pause();
    else if (_current != null)
      _player.resume();
  }

  void _seek(double v) {
    if (_dur.inMilliseconds > 0) {
      _player.seek(Duration(milliseconds: (v * _dur.inMilliseconds).toInt()));
    }
  }

  void _setVol(double v) {
    setState(() => _vol = v);
    _player.setVolume(v);
  }

  void _next() {
    if (_queue.isEmpty || _current == null) return;
    if (_shuffle) {
      _play(_queue[math.Random().nextInt(_queue.length)]);
      return;
    }
    final i = _queue.indexWhere((t) => t.id == _current!.id);
    _play(_queue[(i + 1) % _queue.length]);
  }

  void _prev() {
    if (_queue.isEmpty || _current == null) return;
    final i = _queue.indexWhere((t) => t.id == _current!.id);
    _play(_queue[(i - 1 + _queue.length) % _queue.length]);
  }

  void _onComplete() {
    if (_loop && _current != null) {
      _play(_current!);
      return;
    }
    _next();
  }

  void _toggleFav(MusicTrack t) {
    setState(() {
      if (_favs.any((x) => x.id == t.id))
        _favs.removeWhere((x) => x.id == t.id);
      else
        _favs.insert(0, t);
    });
  }

  bool _isFav(MusicTrack t) => _favs.any((x) => x.id == t.id);

  double get _seekVal => _dur.inMilliseconds == 0
      ? 0
      : (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0);

  String _fmtD(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  String _fmtS(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';

  // ══════════════════════════════════════════════════════════
  // TRACK FETCHING
  // ══════════════════════════════════════════════════════════

  Future<void> _fetch(String id, {bool force = false}) async {
    setState(() {
      _moodId = id;
      _loading = true;
      _err = null;
      _tracks = [];
    });
    try {
      final t = await _svc.fetchMood(id, forceRefresh: force);
      if (mounted)
        setState(() {
          _tracks = t;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _err = 'Could not load tracks. Check your connection.';
          _loading = false;
        });
    }
  }

  // ══════════════════════════════════════════════════════════
  // RECORDING
  // ══════════════════════════════════════════════════════════

  Future<void> _startRecording() async {
    if (!_recOpen) {
      _showSnack('Microphone not available. Check permissions.');
      return;
    }
    final path = await _svc.newRecordingPath();
    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
    setState(() {
      _recording = true;
      _recSecs = 0;
    });
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recSecs++);
    });
  }

  Future<void> _stopRecording() async {
    _recTimer?.cancel();
    final path = await _recorder.stopRecorder();
    setState(() => _recording = false);
    if (path != null) _promptName(path, _recSecs);
  }

  void _promptName(String path, int secs) {
    final ctrl = TextEditingController(
      text: 'Recording ${_recordings.length + 1}',
    );
    showDialog(
      context: context,
      builder: (_) => _dialog(
        title: 'Name this recording',
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec("e.g. Mum's voice, Rain outside..."),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final label = ctrl.text.trim().isEmpty
                  ? 'Recording'
                  : ctrl.text.trim();
              final meta = RecordingMeta(
                id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                label: label,
                path: path,
                createdAt: DateTime.now(),
                durationSecs: secs,
              );
              await _svc.saveRecording(meta);
              await _loadRecordings();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(color: _lilac, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecOptions(RecordingMeta meta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_dive.withOpacity(0.97), _night.withOpacity(0.99)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: _sailing.withOpacity(0.4))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  meta.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _sheetBtn(Icons.edit_outlined, 'Rename', Colors.white, () {
                  Navigator.pop(context);
                  _showRename(meta);
                }),
                const SizedBox(height: 10),
                _sheetBtn(
                  Icons.delete_outline_rounded,
                  'Delete',
                  const Color(0xFFFF6B6B),
                  () {
                    Navigator.pop(context);
                    _confirmDelete(meta);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRename(RecordingMeta meta) {
    final ctrl = TextEditingController(text: meta.label);
    showDialog(
      context: context,
      builder: (_) => _dialog(
        title: 'Rename',
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec(''),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) await _svc.renameRecording(meta.id, t);
              await _loadRecordings();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(color: _lilac, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(RecordingMeta meta) {
    showDialog(
      context: context,
      builder: (_) => _dialog(
        title: 'Delete recording?',
        content: Text(
          '"${meta.label}" will be permanently deleted.',
          style: TextStyle(color: Colors.white.withOpacity(0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _svc.deleteRecording(meta.id);
              await _loadRecordings();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  AlertDialog _dialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) => AlertDialog(
    backgroundColor: _dive,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
    content: content,
    actions: actions,
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _sailing.withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _lilac),
    ),
    filled: true,
    fillColor: _night.withOpacity(0.4),
  );

  Widget _sheetBtn(IconData icon, String label, Color c, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: c.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.withOpacity(0.8), size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: c.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _dive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1F3F74),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_sailing, _deep],
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarsPainter(t: _starCtrl.value),
                ),
              ),
            ),

            if (_expanded && _current != null)
              _buildFullPlayer()
            else
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildTabBar(),
                    Expanded(child: _buildBody()),
                    if (_current != null) _buildMiniPlayer(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────

  Widget _buildAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_dive.withOpacity(0.75), _night.withOpacity(0.80)],
            ),
            border: Border(
              bottom: BorderSide(color: _sailing.withOpacity(0.4)),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _night.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _sailing.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Music',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Discover · Record · Favourites',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (_recording)
                AnimatedBuilder(
                  animation: _visCtrl,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFF6B6B,
                      ).withOpacity(0.15 + _visCtrl.value * 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fmtS(_recSecs),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────

  Widget _buildTabBar() {
    const tabs = [
      ('Discover', Icons.explore_outlined),
      ('My Recordings', Icons.mic_outlined),
      ('Favourites', Icons.favorite_outline_rounded),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: i < 2
                    ? const EdgeInsets.only(right: 8)
                    : EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sel
                        ? [_sailing.withOpacity(0.45), _night.withOpacity(0.75)]
                        : [_dive.withOpacity(0.4), _night.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel
                        ? _sailing.withOpacity(0.7)
                        : _sailing.withOpacity(0.2),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].$2,
                      size: 18,
                      color: sel
                          ? Colors.white
                          : Colors.white.withOpacity(0.45),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i].$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        return _buildDiscover();
      case 1:
        return _buildRecordingsTab();
      case 2:
        return _buildFavourites();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════
  // DISCOVER TAB
  // ══════════════════════════════════════════════════════════

  Widget _buildDiscover() => Column(
    children: [
      _buildMoodChips(),
      Expanded(
        child: _loading
            ? _loadingState()
            : _err != null
            ? _errorState()
            : _tracks.isEmpty
            ? _emptyState()
            : _buildTrackList(),
      ),
    ],
  );

  Widget _buildMoodChips() {
    return SizedBox(
      height: 54,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: MusicService.moods.length,
          itemBuilder: (_, i) {
            final m = MusicService.moods[i];
            final sel = m.id == _moodId;
            final c = _moodColors[m.id] ?? _sailing;
            return GestureDetector(
              onTap: () => _fetch(m.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10, top: 7, bottom: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sel
                        ? [c.withOpacity(0.45), _night.withOpacity(0.75)]
                        : [_dive.withOpacity(0.6), _night.withOpacity(0.75)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? c.withOpacity(0.7) : _sailing.withOpacity(0.3),
                    width: sel ? 1.5 : 1,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: c.withOpacity(0.22), blurRadius: 10)]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 7),
                    Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrackList() {
    final isItunes = _tracks.isNotEmpty && _tracks.first.source == 'itunes';
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 8, 20, _current != null ? 100 : 30),
        itemCount: _tracks.length + 1,
        itemBuilder: (_, i) => i == 0
            ? _sourceBadge(isItunes)
            : _trackCard(_tracks[i - 1], _tracks),
      ),
    );
  }

  Widget _sourceBadge(bool isItunes) {
    if (!isItunes)
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _moodColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _moodColor.withOpacity(0.4)),
              ),
              child: Text(
                'Full tracks · CC Music',
                style: TextStyle(
                  fontSize: 10,
                  color: _moodColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'via Jamendo',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              '30-second previews',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'via iTunes · Add Jamendo client_id for full tracks',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.3),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackCard(MusicTrack t, List<MusicTrack> queue) {
    final isCur = _current?.id == t.id;
    final c = _moodColor;
    return GestureDetector(
      onTap: () => _play(t, queue: queue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCur
                    ? [c.withOpacity(0.25), _night.withOpacity(0.88)]
                    : [_dive.withOpacity(0.55), _night.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCur ? c.withOpacity(0.6) : _sailing.withOpacity(0.28),
                width: isCur ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: t.albumArt.isNotEmpty
                      ? Image.network(
                          t.albumArt,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _artFallback(c),
                        )
                      : _artFallback(c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCur
                              ? Colors.white
                              : Colors.white.withOpacity(0.88),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.artist,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isCur
                              ? c.withOpacity(0.85)
                              : Colors.white.withOpacity(0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isCur && _playing) ...[
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _visCtrl,
                    builder: (_, __) => _MiniVis(color: c, v: _visCtrl.value),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  t.durationLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleFav(t),
                  child: Icon(
                    _isFav(t)
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    size: 20,
                    color: _isFav(t)
                        ? const Color(0xFFFF6B9D)
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _artFallback(Color c) {
    final emoji = MusicService.moods
        .firstWhere(
          (m) => m.id == _moodId,
          orElse: () => MusicService.moods.first,
        )
        .emoji;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: RadialGradient(
          colors: [c.withOpacity(0.5), c.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
    );
  }

  // ══════════════════════════════════════════════════════════
  // RECORDINGS TAB
  // ══════════════════════════════════════════════════════════

  Widget _buildRecordingsTab() => Column(
    children: [
      _buildRecordHeader(),
      Expanded(
        child: _recordings.isEmpty ? _recordingsEmpty() : _recordingsList(),
      ),
    ],
  );

  Widget _buildRecordHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _recording
              ? [
                  const Color(0xFFFF6B6B).withOpacity(0.2),
                  _night.withOpacity(0.85),
                ]
              : [_dive.withOpacity(0.65), _night.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _recording
              ? const Color(0xFFFF6B6B).withOpacity(0.5)
              : _sailing.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Description
          Row(
            children: [
              const Text('🎙️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voice & Sound Recorder',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _recording
                          ? 'Recording in progress...'
                          : 'Record voices you love or sounds that soothe you',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Record / Stop button
          GestureDetector(
            onTap: _recording ? _stopRecording : _startRecording,
            child: AnimatedBuilder(
              animation: _visCtrl,
              builder: (_, __) => Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _recording
                        ? [
                            const Color(0xFFFF6B6B).withOpacity(0.4),
                            _night.withOpacity(0.7),
                          ]
                        : [_sailing.withOpacity(0.35), _night.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _recording
                        ? const Color(
                            0xFFFF6B6B,
                          ).withOpacity(0.6 + _visCtrl.value * 0.4)
                        : _sailing.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _recording
                          ? Icons.stop_rounded
                          : Icons.fiber_manual_record_rounded,
                      color: _recording
                          ? const Color(0xFFFF6B6B)
                          : Colors.white,
                      size: _recording ? 26 : 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _recording
                          ? 'Stop   ${_fmtS(_recSecs)}'
                          : 'Start Recording',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _recording
                            ? const Color(0xFFFF6B6B)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Waveform while recording
          if (_recording) ...[
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _visCtrl,
              builder: (_, __) => _RecWave(v: _visCtrl.value),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Tip: Record a loved one saying something kind, or a sound from a place that feels safe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordingsEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎙️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        const Text(
          'No recordings yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Press Start Recording above\nto capture voices or sounds that soothe you',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.45),
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _recordingsList() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 4, 20, _current != null ? 100 : 24),
        itemCount: _recordings.length,
        itemBuilder: (_, i) {
          final meta = _recordings[i];
          final t = meta.toTrack();
          final isCur = _current?.id == t.id;
          return GestureDetector(
            onTap: () =>
                _play(t, queue: _recordings.map((r) => r.toTrack()).toList()),
            onLongPress: () => _showRecOptions(meta),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCur
                          ? [
                              const Color(0xFFFF6B9D).withOpacity(0.2),
                              _night.withOpacity(0.88),
                            ]
                          : [_dive.withOpacity(0.55), _night.withOpacity(0.85)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCur
                          ? const Color(0xFFFF6B9D).withOpacity(0.5)
                          : _sailing.withOpacity(0.28),
                      width: isCur ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(
                                0xFFFF6B9D,
                              ).withOpacity(isCur ? 0.6 : 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isCur && _playing ? '▶️' : '🎙️',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_fmtDate(meta.createdAt)} · ${_fmtS(meta.durationSecs)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCur && _playing) ...[
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _visCtrl,
                          builder: (_, __) => _MiniVis(
                            color: const Color(0xFFFF6B9D),
                            v: _visCtrl.value,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showRecOptions(meta),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white.withOpacity(0.5),
                            size: 18,
                          ),
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
    );
  }

  String _fmtDate(DateTime d) {
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day)
      return 'Today';
    if (d.year == n.year && d.month == n.month && d.day == n.day - 1)
      return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  // ══════════════════════════════════════════════════════════
  // FAVOURITES TAB
  // ══════════════════════════════════════════════════════════

  Widget _buildFavourites() {
    if (_favs.isEmpty)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💛', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            const Text(
              'No favourites yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap ♡ on any track in Discover to save it here',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ],
        ),
      );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 14, 20, _current != null ? 100 : 30),
        itemCount: _favs.length,
        itemBuilder: (_, i) => _trackCard(_favs[i], _favs),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MINI PLAYER
  // ══════════════════════════════════════════════════════════

  Widget _buildMiniPlayer() {
    final c = _trackColor(_current!);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(_dive, c, 0.18)!.withOpacity(0.97),
                _night.withOpacity(0.99),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: c.withOpacity(0.4), width: 1.2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      activeTrackColor: c,
                      inactiveTrackColor: Colors.white.withOpacity(0.12),
                      thumbColor: Colors.white,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(value: _seekVal, onChanged: _seek),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = true),
                    child: Row(
                      children: [
                        // Art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _current!.albumArt.isNotEmpty
                              ? Image.network(
                                  _current!.albumArt,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _miniArt(c),
                                )
                              : _miniArt(c),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _current!.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _current!.artist,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _ctrlBtn(Icons.skip_previous_rounded, _prev, 36),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _togglePP,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.28),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ctrlBtn(Icons.skip_next_rounded, _next, 36),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniArt(Color c) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: RadialGradient(
        colors: [c.withOpacity(0.6), c.withOpacity(0.15), Colors.transparent],
      ),
    ),
    child: Center(
      child: Text(
        _current!.isLocal ? '🎙️' : '🎵',
        style: const TextStyle(fontSize: 20),
      ),
    ),
  );

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, double sz) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: sz * 0.55,
          ),
        ),
      );

  // ══════════════════════════════════════════════════════════
  // FULL SCREEN PLAYER
  // ══════════════════════════════════════════════════════════

  Widget _buildFullPlayer() {
    final c = _trackColor(_current!);
    final t = _current!;
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _expanded = false),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _night.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.withOpacity(0.4), width: 1.2),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  t.isLocal ? 'My Recording' : 'Now Playing',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleFav(t),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isFav(t)
                          ? const Color(0xFFFF6B9D).withOpacity(0.2)
                          : _night.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isFav(t)
                            ? const Color(0xFFFF6B9D).withOpacity(0.6)
                            : _sailing.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      _isFav(t)
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color: _isFav(t)
                          ? const Color(0xFFFF6B9D)
                          : Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Album art orb
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_orbCtrl, _visCtrl]),
                builder: (_, __) {
                  final pulse = _playing ? 0.88 + _orbCtrl.value * 0.10 : 0.82;
                  final glow = _playing ? 0.28 + _orbCtrl.value * 0.20 : 0.12;
                  return Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(glow),
                            blurRadius: 80,
                            spreadRadius: 12,
                          ),
                          BoxShadow(
                            color: c.withOpacity(glow * 0.5),
                            blurRadius: 120,
                            spreadRadius: 24,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: t.albumArt.isNotEmpty
                            ? Image.network(
                                t.albumArt,
                                width: 240,
                                height: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _bigArtFallback(c, t),
                              )
                            : _bigArtFallback(c, t),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Track info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Text(
                  t.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.artist,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.withOpacity(0.85),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (t.source == 'itunes') ...[
                  const SizedBox(height: 4),
                  Text(
                    '30-second preview',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Seek bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    activeTrackColor: c,
                    inactiveTrackColor: Colors.white.withOpacity(0.12),
                    thumbColor: Colors.white,
                    overlayColor: c.withOpacity(0.15),
                  ),
                  child: Slider(value: _seekVal, onChanged: _seek),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmtD(_pos),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        _fmtD(_dur),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Transport
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _toggleBtn(
                  Icons.shuffle_rounded,
                  _shuffle,
                  () => setState(() => _shuffle = !_shuffle),
                  c,
                ),
                _ctrlBtn(Icons.skip_previous_rounded, _prev, 52),
                GestureDetector(
                  onTap: _togglePP,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [c, c.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                _ctrlBtn(Icons.skip_next_rounded, _next, 52),
                _toggleBtn(
                  Icons.repeat_rounded,
                  _loop,
                  () => setState(() => _loop = !_loop),
                  c,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Volume
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Icon(
                  Icons.volume_down_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 18,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      activeTrackColor: Colors.white.withOpacity(0.6),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: Colors.white,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(value: _vol, onChanged: _setVol),
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _bigArtFallback(Color c, MusicTrack t) => Container(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        colors: [c.withOpacity(0.7), c.withOpacity(0.2), _night],
      ),
    ),
    child: Center(
      child: Text(
        t.isLocal
            ? '🎙️'
            : MusicService.moods
                  .firstWhere(
                    (m) => m.id == _moodId,
                    orElse: () => MusicService.moods.first,
                  )
                  .emoji,
        style: const TextStyle(fontSize: 72),
      ),
    ),
  );

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap, Color c) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? c.withOpacity(0.2) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? c.withOpacity(0.5)
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Icon(
            icon,
            color: active ? c : Colors.white.withOpacity(0.45),
            size: 20,
          ),
        ),
      );

  // ── Common states ─────────────────────────────────────────

  Widget _loadingState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(color: _moodColor, strokeWidth: 2.5),
        ),
        const SizedBox(height: 14),
        Text(
          'Finding music…',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎵', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text(
            _err!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _fetch(_moodId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _sailing.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sailing.withOpacity(0.55)),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Text(
      'No tracks found.',
      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
    ),
  );
}

// ── Visualiser widgets ────────────────────────────────────────

class _MiniVis extends StatelessWidget {
  final Color color;
  final double v;
  const _MiniVis({required this.color, required this.v});
  @override
  Widget build(BuildContext context) {
    const h = [0.5, 1.0, 0.7];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final t = (v + i * 0.22) % 1.0;
        final ht = 4 + (h[i] * 10 * math.sin(t * math.pi)).abs();
        return Container(
          width: 3,
          height: ht,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _RecWave extends StatelessWidget {
  final double v;
  const _RecWave({required this.v});
  @override
  Widget build(BuildContext context) {
    const bars = [
      0.3,
      0.6,
      0.9,
      0.5,
      1.0,
      0.4,
      0.7,
      0.8,
      0.3,
      0.6,
      1.0,
      0.5,
      0.8,
      0.4,
      0.7,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(bars.length, (i) {
        final t = (v + i * 0.08) % 1.0;
        final ht = 6 + (bars[i] * 22 * math.sin(t * math.pi)).abs();
        return Container(
          width: 4,
          height: ht,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.6 + bars[i] * 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Stars painter ─────────────────────────────────────────────

class _StarsPainter extends CustomPainter {
  final double t;
  const _StarsPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    const s = [
      [0.08, 0.05],
      [0.22, 0.12],
      [0.40, 0.08],
      [0.58, 0.15],
      [0.72, 0.06],
      [0.88, 0.11],
      [0.14, 0.30],
      [0.35, 0.38],
      [0.55, 0.28],
      [0.75, 0.35],
      [0.92, 0.28],
      [0.20, 0.55],
      [0.48, 0.60],
      [0.68, 0.52],
      [0.85, 0.62],
      [0.10, 0.75],
      [0.38, 0.80],
      [0.62, 0.72],
      [0.80, 0.82],
      [0.95, 0.70],
    ];
    for (final st in s) {
      final x = size.width * st[0];
      final y = size.height * st[1];
      final off = (st[0] + st[1]) % 1.0;
      final op = 0.2 + ((t + off) % 1.0) * 0.35;
      p.color = Colors.white.withOpacity(op * 0.3);
      canvas.drawCircle(Offset(x, y), 2.8, p);
      p.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 1.5, p);
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}
