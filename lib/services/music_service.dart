import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String audioUrl;
  final int durationSecs;
  final String source; // 'jamendo' | 'itunes' | 'recording'

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.audioUrl,
    required this.durationSecs,
    required this.source,
  });

  String get durationLabel {
    if (durationSecs <= 0) return '--:--';
    final m = (durationSecs ~/ 60).toString().padLeft(2, '0');
    final s = (durationSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get isLocal => source == 'recording';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'albumArt': albumArt,
    'audioUrl': audioUrl,
    'durationSecs': durationSecs,
    'source': source,
  };

  factory MusicTrack.fromJson(Map<String, dynamic> j) => MusicTrack(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? 'Untitled',
    artist: j['artist'] as String? ?? 'Unknown',
    albumArt: j['albumArt'] as String? ?? '',
    audioUrl: j['audioUrl'] as String? ?? '',
    durationSecs: (j['durationSecs'] as num?)?.toInt() ?? 0,
    source: j['source'] as String? ?? 'itunes',
  );
}

class MusicMood {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final List<String> jamendoTags;
  final String iTunesQuery;
  const MusicMood({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.jamendoTags,
    required this.iTunesQuery,
  });
}

class RecordingMeta {
  final String id;
  final String label;
  final String path;
  final DateTime createdAt;
  final int durationSecs;

  const RecordingMeta({
    required this.id,
    required this.label,
    required this.path,
    required this.createdAt,
    required this.durationSecs,
  });

  MusicTrack toTrack() => MusicTrack(
    id: id,
    title: label,
    artist: 'My Recording',
    albumArt: '',
    audioUrl: path,
    durationSecs: durationSecs,
    source: 'recording',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'durationSecs': durationSecs,
  };

  factory RecordingMeta.fromJson(Map<String, dynamic> j) => RecordingMeta(
    id: j['id'] ?? '',
    label: j['label'] ?? 'Recording',
    path: j['path'] ?? '',
    durationSecs: j['durationSecs'] ?? 0,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  String jamendoClientId = '';
  bool get _hasJamendo => jamendoClientId.trim().isNotEmpty;

  static const _jamendoBase = 'https://api.jamendo.com/v3.0';
  static const _iTunesBase = 'https://itunes.apple.com';
  static const _timeout = Duration(seconds: 14);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0',
  };

  static const List<MusicMood> moods = [
    MusicMood(
      id: 'lofi',
      label: 'Lo-fi',
      emoji: '🎵',
      description: 'Chill beats for focus and study',
      jamendoTags: ['lofi', 'chillhop'],
      iTunesQuery: 'lofi chill hip hop beats',
    ),
    MusicMood(
      id: 'calming',
      label: 'Calming',
      emoji: '🌊',
      description: 'Ambient sounds to ease your mind',
      jamendoTags: ['ambient', 'chillout', 'relaxing'],
      iTunesQuery: 'ambient calming relaxing',
    ),
    MusicMood(
      id: 'sleep',
      label: 'Sleep',
      emoji: '🌙',
      description: 'Peaceful music to drift off to',
      jamendoTags: ['sleep', 'meditation'],
      iTunesQuery: 'sleep meditation peaceful music',
    ),
    MusicMood(
      id: 'piano',
      label: 'Piano',
      emoji: '🎹',
      description: 'Gentle piano for quiet moments',
      jamendoTags: ['piano', 'acoustic', 'classical'],
      iTunesQuery: 'calming piano solo acoustic',
    ),
    MusicMood(
      id: 'nature',
      label: 'Nature',
      emoji: '🌿',
      description: 'Acoustic folk and natural sounds',
      jamendoTags: ['nature', 'folk', 'acoustic'],
      iTunesQuery: 'nature acoustic folk peaceful',
    ),
    MusicMood(
      id: 'focus',
      label: 'Focus',
      emoji: '🧠',
      description: 'Instrumental music for deep work',
      jamendoTags: ['instrumental', 'downtempo'],
      iTunesQuery: 'instrumental focus concentration',
    ),
  ];

  final Map<String, List<MusicTrack>> _cache = {};

  Future<List<MusicTrack>> fetchMood(
    String moodId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(moodId)) return _cache[moodId]!;
    final mood = moods.firstWhere(
      (m) => m.id == moodId,
      orElse: () => moods.first,
    );
    List<MusicTrack> tracks = [];
    if (_hasJamendo) tracks = await _fetchJamendo(mood);
    if (tracks.isEmpty) tracks = await _fetchITunes(mood);
    _cache[moodId] = tracks;
    return tracks;
  }

  void clearCache([String? id]) {
    if (id != null)
      _cache.remove(id);
    else
      _cache.clear();
  }

  Future<List<MusicTrack>> _fetchJamendo(MusicMood mood) async {
    try {
      final uri = Uri.parse('$_jamendoBase/tracks').replace(
        queryParameters: {
          'client_id': jamendoClientId,
          'format': 'json',
          'tags': mood.jamendoTags.join('+'),
          'limit': '20',
          'imagesize': '300',
          'audioformat': 'mp31',
          'order': 'popularity_total',
        },
      );
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final results = (jsonDecode(res.body)['results'] as List?) ?? [];
      return results
          .map(
            (r) => MusicTrack(
              id: 'j_${r['id']}',
              title: (r['name'] as String?) ?? 'Untitled',
              artist: (r['artist_name'] as String?) ?? 'Unknown',
              albumArt: (r['image'] as String?) ?? '',
              audioUrl: (r['audio'] as String?) ?? '',
              durationSecs: int.tryParse(r['duration']?.toString() ?? '0') ?? 0,
              source: 'jamendo',
            ),
          )
          .where((t) => t.audioUrl.isNotEmpty)
          .toList();
    } catch (e) {
      _log('Jamendo: $e');
      return [];
    }
  }

  Future<List<MusicTrack>> _fetchITunes(MusicMood mood) async {
    try {
      final uri = Uri.parse('$_iTunesBase/search').replace(
        queryParameters: {
          'term': mood.iTunesQuery.replaceAll(' ', '+'),
          'media': 'music',
          'entity': 'song',
          'limit': '20',
          'country': 'US',
        },
      );
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final results = (jsonDecode(res.body)['results'] as List?) ?? [];
      return results
          .where(
            (r) =>
                r['previewUrl'] != null &&
                (r['previewUrl'] as String).isNotEmpty,
          )
          .map((r) {
            final art = ((r['artworkUrl100'] as String?) ?? '').replaceAll(
              '100x100bb',
              '300x300bb',
            );
            return MusicTrack(
              id: 'it_${r['trackId']}',
              title: (r['trackName'] as String?) ?? 'Untitled',
              artist: (r['artistName'] as String?) ?? 'Unknown',
              albumArt: art,
              audioUrl: r['previewUrl'] as String,
              durationSecs:
                  (int.tryParse(r['trackTimeMillis']?.toString() ?? '30000') ??
                      30000) ~/
                  1000,
              source: 'itunes',
            );
          })
          .toList();
    } catch (e) {
      _log('iTunes: $e');
      return [];
    }
  }

  // Recordings

  Future<Directory> get _recDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/nuru_recordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> newRecordingPath() async {
    final dir = await _recDir;
    return '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  Future<File> get _manifestFile async =>
      File('${(await _recDir).path}/manifest.json');

  Future<List<RecordingMeta>> loadRecordings() async {
    try {
      final f = await _manifestFile;
      if (!await f.exists()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return list
          .map((j) => RecordingMeta.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveManifest(List<RecordingMeta> list) async {
    final f = await _manifestFile;
    await f.writeAsString(jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  Future<void> saveRecording(RecordingMeta meta) async {
    final list = await loadRecordings()
      ..removeWhere((r) => r.id == meta.id);
    list.insert(0, meta);
    await _saveManifest(list);
  }

  Future<void> deleteRecording(String id) async {
    final list = await loadRecordings();
    final meta = list.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('not found'),
    );
    final f = File(meta.path);
    if (await f.exists()) await f.delete();
    list.removeWhere((r) => r.id == id);
    await _saveManifest(list);
  }

  Future<void> renameRecording(String id, String newLabel) async {
    final list = await loadRecordings();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    final o = list[idx];
    list[idx] = RecordingMeta(
      id: o.id,
      label: newLabel,
      path: o.path,
      createdAt: o.createdAt,
      durationSecs: o.durationSecs,
    );
    await _saveManifest(list);
  }

  void _log(String m) {
    assert(() {
      print('[MusicService] $m');
      return true;
    }());
  }

  //Favourites

  Future<File> get _favsFile async =>
      File('${(await _recDir).path}/favourites.json');

  Future<List<MusicTrack>> loadFavourites() async {
    try {
      final f = await _favsFile;
      if (!await f.exists()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return list
          .map((j) => MusicTrack.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavourites(List<MusicTrack> favs) async {
    try {
      final f = await _favsFile;
      await f.writeAsString(jsonEncode(favs.map((t) => t.toJson()).toList()));
    } catch (e) {
      _log('saveFavourites error: $e');
    }
  }
}
