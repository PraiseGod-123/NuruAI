import 'dart:convert';
import 'package:http/http.dart' as http;

// POETRY CORNER SERVICE
class Poem {
  final String id;
  final String title;
  final String author;
  final List<String> lines;
  final String mood;
  final String moodEmoji;

  const Poem({
    required this.id,
    required this.title,
    required this.author,
    required this.lines,
    required this.mood,
    required this.moodEmoji,
  });

  String get fullText => lines.join('\n');
  String get preview {
    final take = lines.take(4).join('\n');
    return lines.length > 4 ? '$take\n…' : take;
  }

  int get lineCount => lines.length;
}

class PoemMood {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final int colorValue;

  const PoemMood({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.colorValue,
  });
}

class PoetryServiceException implements Exception {
  final String message;
  const PoetryServiceException(this.message);
  @override
  String toString() => 'PoetryServiceException: $message';
}

class PoetryService {
  PoetryService._();
  static final PoetryService instance = PoetryService._();

  static const _base =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://poetrydb.org';
  static const _timeout = Duration(seconds: 12);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  // Per-mood cache
  final Map<String, List<Poem>> _cache = {};

  // Mood definitions

  static const List<PoemMood> moods = [
    PoemMood(
      id: 'all',
      label: 'All Poems',
      emoji: '📚',
      description: 'Everything',
      colorValue: 0xFF8EA2D7,
    ),
    PoemMood(
      id: 'calm',
      label: 'Calm',
      emoji: '🌙',
      description: 'Quiet and still',
      colorValue: 0xFF6C5CE7,
    ),
    PoemMood(
      id: 'hopeful',
      label: 'Hopeful',
      emoji: '🌅',
      description: 'Light ahead',
      colorValue: 0xFFFDCB6E,
    ),
    PoemMood(
      id: 'nature',
      label: 'Nature',
      emoji: '🌿',
      description: 'Earth and sky',
      colorValue: 0xFF00B894,
    ),
    PoemMood(
      id: 'selfworth',
      label: 'Self-Worth',
      emoji: '💙',
      description: 'You belong here',
      colorValue: 0xFFE84393,
    ),
    PoemMood(
      id: 'short',
      label: 'Quick Read',
      emoji: '✨',
      description: 'Under 12 lines',
      colorValue: 0xFF55EFC4,
    ),
  ];

  // Authors per mood
  static const Map<String, List<_AuthorSpec>> _moodAuthors = {
    'calm': [
      _AuthorSpec('Emily Dickinson', limit: 3),
      _AuthorSpec('Walt Whitman', limit: 2),
      _AuthorSpec('William Blake', limit: 2),
      _AuthorSpec('John Keats', limit: 2),
      _AuthorSpec('Percy Bysshe Shelley', limit: 2),
    ],
    'hopeful': [
      _AuthorSpec('Emily Dickinson', limit: 2),
      _AuthorSpec('Walt Whitman', limit: 3),
      _AuthorSpec('Langston Hughes', limit: 3),
      _AuthorSpec('Christina Rossetti', limit: 2),
      _AuthorSpec('Alfred Lord Tennyson', limit: 2),
    ],
    'nature': [
      _AuthorSpec('William Wordsworth', limit: 3),
      _AuthorSpec('John Keats', limit: 2),
      _AuthorSpec('Walt Whitman', limit: 2),
      _AuthorSpec('Percy Bysshe Shelley', limit: 2),
      _AuthorSpec('Robert Frost', limit: 2),
    ],
    'selfworth': [
      _AuthorSpec('Langston Hughes', limit: 3),
      _AuthorSpec('Emily Dickinson', limit: 2),
      _AuthorSpec('Walt Whitman', limit: 2),
      _AuthorSpec('Christina Rossetti', limit: 2),
      _AuthorSpec('Maya Angelou', limit: 2),
    ],
  };

  // PUBLIC
  Future<List<Poem>> fetchMood(
    String moodId, {
    bool forceRefresh = false,
  }) async {
    if (moodId == 'all') return fetchAll(forceRefresh: forceRefresh);
    if (moodId == 'short') return fetchShort(forceRefresh: forceRefresh);
    if (!forceRefresh && _cache.containsKey(moodId)) return _cache[moodId]!;
    final specs = _moodAuthors[moodId] ?? [];
    final results = <Poem>[];
    await Future.wait(
      specs.map(
        (spec) =>
            _fetchByAuthor(spec.author, moodId, results, limit: spec.limit),
      ),
    );
    _dedup(results);
    // If API failed, use fallback
    if (results.isEmpty) results.addAll(_fallbackPoems(moodId));
    _cache[moodId] = results;
    return results;
  }

  static List<Poem> _fallbackPoems(String mood) {
    final emoji = moods
        .firstWhere((m) => m.id == mood, orElse: () => moods[0])
        .emoji;
    return [
      Poem(
        id: 'f1',
        title: 'Hope is the Thing with Feathers',
        author: 'Emily Dickinson',
        lines: [
          'Hope is the thing with feathers',
          'That perches in the soul,',
          'And sings the tune without the words,',
          'And never stops at all,',
          'And sweetest in the gale is heard;',
          'And sore must be the storm',
          'That could abash the little bird',
          'That kept so many warm.',
        ],
        mood: mood,
        moodEmoji: emoji,
      ),
      Poem(
        id: 'f2',
        title: 'Dreams',
        author: 'Langston Hughes',
        lines: [
          'Hold fast to dreams',
          'For if dreams die',
          'Life is a broken-winged bird',
          'That cannot fly.',
          'Hold fast to dreams',
          'For when dreams go',
          'Life is a barren field',
          'Frozen with snow.',
        ],
        mood: mood,
        moodEmoji: emoji,
      ),
      Poem(
        id: 'f3',
        title: 'The Road Not Taken',
        author: 'Robert Frost',
        lines: [
          'Two roads diverged in a yellow wood,',
          'And sorry I could not travel both',
          'And be one traveler, long I stood',
          'And looked down one as far as I could',
          'To where it bent in the undergrowth.',
        ],
        mood: mood,
        moodEmoji: emoji,
      ),
      Poem(
        id: 'f4',
        title: 'Still I Rise',
        author: 'Maya Angelou',
        lines: [
          'You may write me down in history',
          'With your bitter, twisted lies,',
          'You may trod me in the very dirt',
          'But still, like dust, I\'ll rise.',
        ],
        mood: mood,
        moodEmoji: emoji,
      ),
      Poem(
        id: 'f5',
        title: 'I Wandered Lonely as a Cloud',
        author: 'William Wordsworth',
        lines: [
          'I wandered lonely as a cloud',
          'That floats on high o\'er vales and hills,',
          'When all at once I saw a crowd,',
          'A host, of golden daffodils;',
          'Beside the lake, beneath the trees,',
          'Fluttering and dancing in the breeze.',
        ],
        mood: mood,
        moodEmoji: emoji,
      ),
    ];
  }

  Future<List<Poem>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey('all')) return _cache['all']!;

    final results = <Poem>[];
    await Future.wait([
      _fetchByAuthor('Emily Dickinson', 'calm', results, limit: 3),
      _fetchByAuthor('Langston Hughes', 'hopeful', results, limit: 3),
      _fetchByAuthor('Walt Whitman', 'nature', results, limit: 2),
      _fetchByAuthor('William Wordsworth', 'nature', results, limit: 2),
      _fetchByAuthor('Christina Rossetti', 'hopeful', results, limit: 2),
      _fetchByAuthor('William Blake', 'calm', results, limit: 2),
      _fetchByAuthor('John Keats', 'nature', results, limit: 2),
      _fetchByAuthor('Percy Bysshe Shelley', 'calm', results, limit: 2),
      _fetchByAuthor('Robert Frost', 'nature', results, limit: 2),
    ]);

    _dedup(results);
    _cache['all'] = results;
    return results;
  }

  Future<List<Poem>> fetchShort({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey('short')) return _cache['short']!;

    // Fetch all, filter to ≤12 lines
    final all = await fetchAll(forceRefresh: forceRefresh);
    final short = all
        .where((p) => p.lineCount <= 12 && p.lineCount > 2)
        .toList();
    _cache['short'] = short;
    return short;
  }

  void clearCache([String? moodId]) {
    if (moodId != null) {
      _cache.remove(moodId);
    } else {
      _cache.clear();
    }
  }

  // POETRYDB FETCH

  Future<void> _fetchByAuthor(
    String author,
    String mood,
    List<Poem> out, {
    int limit = 3,
  }) async {
    try {
      final encoded = Uri.encodeComponent(author);
      final uri = Uri.parse(
        '$_base/author/$encoded/title,lines,linecount,author',
      );
      final res = await http.get(uri, headers: _headers).timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) return;

      final body = res.body.trim();
      if (!body.startsWith('[')) return;

      final raw = jsonDecode(body) as List;
      if (raw.isEmpty) return;

      // Filter out very short (likely incomplete) and very long (overwhelming)
      final filtered = raw.where((p) {
        final lc = int.tryParse(p['linecount']?.toString() ?? '0') ?? 0;
        return lc >= 4 && lc <= 40;
      }).toList();

      // Sort shortest first
      filtered.sort((a, b) {
        final la = int.tryParse(a['linecount']?.toString() ?? '999') ?? 999;
        final lb = int.tryParse(b['linecount']?.toString() ?? '999') ?? 999;
        return la.compareTo(lb);
      });

      final moodDef = moods.firstWhere(
        (m) => m.id == mood,
        orElse: () => moods[0],
      );

      for (final p in filtered.take(limit)) {
        final title = (p['title'] as String?) ?? 'Untitled';
        final pAuthor = (p['author'] as String?) ?? author;
        final lines = ((p['lines'] as List?) ?? [])
            .map((l) => l.toString())
            .toList();

        out.add(
          Poem(
            id: '${author}_$title'.replaceAll(' ', '_').toLowerCase(),
            title: title,
            author: pAuthor,
            lines: lines,
            mood: mood,
            moodEmoji: moodDef.emoji,
          ),
        );
      }
    } catch (e) {
      // Swallow — other authors still load
      assert(() {
        print('[PoetryService] $author: $e');
        return true;
      }());
    }
  }

  void _dedup(List<Poem> list) {
    final seen = <String>{};
    list.retainWhere((p) {
      final key = p.title.toLowerCase();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    });
  }
}

class _AuthorSpec {
  final String author;
  final int limit;
  const _AuthorSpec(this.author, {required this.limit});
}
