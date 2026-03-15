import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// MINDFULNESS SERVICE
//
// Mindfulness for ASD is adapted from standard MBSR/MBCT:
//   • Shorter sessions — attention span differences
//   • Sensory-focused anchors (touch, sound, body) over breath
//   • Concrete and structured — not abstract "clear your mind"
//   • Movement-based options — sitting still is not required
//   • Visual and tactile anchors alongside verbal instruction
//
// Real APIs (free, no key):
//   Open Library — books on mindfulness, MBSR, ASD meditation
//   PubMed       — clinical research on mindfulness and ASD
//
// NuruAI Curated Guides (offline):
//   subcategory = 'understanding'  — what mindfulness is, ASD context
//   subcategory = 'communication'  — mindful communication
// ══════════════════════════════════════════════════════════════

enum MindfulnessResourceType { book, research, guide, technique }

class MindfulnessItem {
  final String id;
  final String title;
  final String subtitle;
  final MindfulnessResourceType type;
  final String? author;
  final String? description;
  final String? url;
  final String? coverUrl;
  final String emoji;
  final String source;
  final String? subcategory;

  const MindfulnessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.author,
    this.description,
    this.url,
    this.coverUrl,
    required this.emoji,
    required this.source,
    this.subcategory,
  });
}

class MindfulnessServiceException implements Exception {
  final String message;
  final int? statusCode;
  const MindfulnessServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'MindfulnessServiceException: $message';
}

class MindfulnessService {
  MindfulnessService._();
  static final MindfulnessService instance = MindfulnessService._();

  static const _openLibraryBase = 'https://openlibrary.org';
  static const _pubmedBase = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils';
  static const _timeout = Duration(seconds: 12);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  List<MindfulnessItem>? _cached;

  Future<List<MindfulnessItem>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final results = <MindfulnessItem>[];
    _injectGuides(results);

    await Future.wait([
      _fetchBooks('mindfulness meditation autism spectrum', results, limit: 4),
      _fetchBooks('mindfulness based stress reduction MBSR', results, limit: 3),
      _fetchBooks(
        'present moment awareness acceptance therapy ACT',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'mindfulness intervention autism spectrum disorder',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'mindfulness based cognitive therapy anxiety autism adolescent',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'mindfulness attention regulation neurodevelopmental disorder',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'body scan mindfulness emotion regulation ASD',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'mindful movement yoga autism sensory regulation',
        results,
        limit: 2,
      ),
    ]);

    final seen = <String>{};
    final deduped = results.where((r) {
      final k = r.title.toLowerCase();
      if (seen.contains(k)) return false;
      seen.add(k);
      return true;
    }).toList();

    _cached = deduped;
    return deduped;
  }

  void clearCache() => _cached = null;

  void _injectGuides(List<MindfulnessItem> results) {
    for (final g in _understanding) {
      results.add(
        MindfulnessItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: MindfulnessResourceType.guide,
          description: g.body,
          emoji: g.emoji,
          source: 'NuruAI Guide',
          subcategory: 'understanding',
        ),
      );
    }
    for (final g in _communication) {
      results.add(
        MindfulnessItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: MindfulnessResourceType.guide,
          description: g.body,
          emoji: g.emoji,
          source: 'NuruAI Guide',
          subcategory: 'communication',
        ),
      );
    }
  }

  static const _understanding = [
    _G(
      id: 'mf_what_is',
      title: 'What Is Mindfulness?',
      subtitle: 'Presence without judgement — adapted for ASD',
      emoji: '🧘',
      body:
          'Mindfulness is the practice of paying attention to the present moment — what is happening right now — without judging it as good or bad.\n\n'
          'It does not mean:\n'
          '• Clearing your mind (impossible and unnecessary)\n'
          '• Sitting still in silence for hours\n'
          '• Feeling calm all the time\n'
          '• Being spiritual or religious\n\n'
          'It does mean:\n'
          '• Noticing what you are experiencing right now\n'
          '• Returning your attention when it wanders (it will always wander — that is normal)\n'
          '• Observing thoughts and feelings without being controlled by them\n\n'
          'For ASD:\n'
          'Standard mindfulness instructions ("focus on your breath") can be difficult if breath-awareness is uncomfortable or if sitting still creates sensory distress. Adapted mindfulness uses objects, sounds, textures, and movement as anchors instead.\n\n'
          'Research: Over 30 studies show mindfulness reduces anxiety, stress, and emotional dysregulation in autistic individuals.',
    ),
    _G(
      id: 'mf_asd_adapted',
      title: 'Mindfulness Adapted for ASD',
      subtitle: 'Why standard mindfulness often needs adjusting',
      emoji: '🧩',
      body:
          'Standard mindfulness programmes (MBSR, MBCT) were developed primarily for neurotypical adults. They often assume:\n'
          '• Comfortable breath awareness\n'
          '• Tolerance for extended stillness\n'
          '• Ability to follow abstract verbal instructions\n'
          '• Comfort with eye closure\n\n'
          'Adaptations that work better for ASD:\n\n'
          'Anchor alternatives:\n'
          '• Texture of an object instead of breath\n'
          '• Sound instead of internal sensation\n'
          '• Slow walking instead of sitting\n'
          '• Holding a weighted or textured item\n\n'
          'Session modifications:\n'
          '• Shorter sessions (2–5 minutes) practiced more frequently\n'
          '• Eyes open or soft gaze rather than closed\n'
          '• Concrete, specific instructions rather than open metaphors\n'
          '• Predictable structure — same sequence every time\n\n'
          'Tip: A special interest can be a mindfulness anchor. If you love trains, mindfully watching a train video for 3 minutes is valid meditation.',
    ),
    _G(
      id: 'mf_benefits',
      title: 'What Mindfulness Does to Your Brain',
      subtitle: 'The science behind why it works',
      emoji: '🔬',
      body:
          'Mindfulness practice produces measurable changes in brain structure and function — including in autistic individuals.\n\n'
          'Documented effects:\n'
          '• Reduces activity in the amygdala (threat and stress centre)\n'
          '• Strengthens prefrontal cortex — improving emotional regulation\n'
          '• Increases grey matter in the insula — improving interoception\n'
          '• Reduces default mode network activity — reducing rumination\n'
          '• Lowers cortisol (stress hormone) levels over 8 weeks\n\n'
          'For ASD specifically (research findings):\n'
          '• Reduces anxiety and emotional reactivity\n'
          '• Improves social communication awareness\n'
          '• Reduces repetitive negative thinking\n'
          '• Improves sleep quality\n'
          '• Reduces sensory sensitivity over time\n\n'
          'How long does it take?\n'
          'Studies show measurable changes after 8 weeks of daily practice, even at 10 minutes per day. The sessions in this app start at 2–5 minutes.',
    ),
  ];

  static const _communication = [
    _G(
      id: 'mf_comm_listening',
      title: 'Mindful Listening',
      subtitle: 'Being fully present with another person',
      emoji: '👂',
      body:
          'Mindful listening is the practice of giving your complete attention to another person — without planning your reply, judging what they say, or waiting for them to finish.\n\n'
          'How to practice:\n'
          '• Put down or away everything in your hands\n'
          '• Turn your body toward the person\n'
          '• Let your eyes land comfortably (direct contact, their forehead, nearby object — whatever feels natural)\n'
          '• Notice when your mind goes to your own response — gently return to their words\n'
          '• Before you speak, take one breath\n\n'
          'For ASD:\n'
          'Direct eye contact is not required for mindful listening. You can demonstrate presence through stillness, nodding, and brief verbal acknowledgments ("yes," "I see").\n\n'
          'Why it matters: Most people feel whether they are truly being heard. Mindful listening changes the quality of every relationship.',
    ),
    _G(
      id: 'mf_comm_pause',
      title: 'The Mindful Pause in Conversation',
      subtitle: 'Respond instead of react — the one-breath rule',
      emoji: '⏸️',
      body:
          'The mindful pause is the simplest conversational tool: before you speak, take one breath.\n\n'
          'What happens in that breath:\n'
          '• Your brain shifts from reactive mode to responsive mode\n'
          '• You have a fraction of a second to choose your words\n'
          '• Your tone becomes calmer — the breath changes your voice\n\n'
          'Practice levels:\n'
          'Level 1: Pause before every reply in a low-stakes conversation\n'
          'Level 2: Pause before replying to anything that makes you feel reactive\n'
          'Level 3: Pause before sending any message or email\n\n'
          'For ASD:\n'
          'Autistic individuals often process information more deeply before speaking — this is a strength. The mindful pause honours this processing time rather than treating it as a delay.',
    ),
  ];

  Future<void> _fetchBooks(
    String query,
    List<MindfulnessItem> out, {
    int limit = 4,
  }) async {
    try {
      final uri = Uri.parse('$_openLibraryBase/search.json').replace(
        queryParameters: {
          'q': query,
          'fields': 'key,title,author_name,first_publish_year,cover_i',
          'limit': '$limit',
        },
      );
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      _check(res, 'Open Library');
      final docs = ((jsonDecode(res.body) as Map)['docs'] as List?) ?? [];
      for (final d in docs) {
        final key = (d['key'] as String?) ?? '';
        final title = (d['title'] as String?) ?? 'Untitled';
        final authors = ((d['author_name'] as List?) ?? [])
            .take(2)
            .map((a) => '$a')
            .join(', ');
        final year = d['first_publish_year']?.toString() ?? '';
        final cover = d['cover_i'];
        out.add(
          MindfulnessItem(
            id: 'book_${key.replaceAll('/', '_')}',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (year.isNotEmpty) year,
            ].join(' · '),
            type: MindfulnessResourceType.book,
            author: authors.isNotEmpty ? authors : null,
            url: key.isNotEmpty ? '$_openLibraryBase$key' : null,
            coverUrl: cover != null
                ? 'https://covers.openlibrary.org/b/id/$cover-M.jpg'
                : null,
            emoji: '📖',
            source: 'Open Library',
          ),
        );
      }
    } catch (e) {
      _log('OpenLibrary: $e');
    }
  }

  Future<void> _fetchPubMed(
    String query,
    List<MindfulnessItem> out, {
    int limit = 3,
  }) async {
    try {
      final searchUri = Uri.parse('$_pubmedBase/esearch.fcgi').replace(
        queryParameters: {
          'db': 'pubmed',
          'term': '$query[Title/Abstract]',
          'retmax': '$limit',
          'retmode': 'json',
          'sort': 'relevance',
          'datetype': 'pdat',
          'reldate': '2555',
        },
      );
      final searchRes = await http
          .get(searchUri, headers: _headers)
          .timeout(_timeout);
      _check(searchRes, 'PubMed esearch');
      final ids =
          ((jsonDecode(searchRes.body)['esearchresult']?['idlist']) as List?)
              ?.map((e) => '$e')
              .toList() ??
          [];
      if (ids.isEmpty) return;

      final summUri = Uri.parse('$_pubmedBase/esummary.fcgi').replace(
        queryParameters: {
          'db': 'pubmed',
          'id': ids.join(','),
          'retmode': 'json',
        },
      );
      final summRes = await http
          .get(summUri, headers: _headers)
          .timeout(_timeout);
      _check(summRes, 'PubMed esummary');
      final sums =
          (jsonDecode(summRes.body)['result'] as Map<String, dynamic>?) ?? {};

      for (final pmid in ids) {
        final a = sums[pmid] as Map<String, dynamic>?;
        if (a == null) continue;
        final title = _clean((a['title'] as String?) ?? 'Untitled');
        final authors = ((a['authors'] as List?) ?? [])
            .take(3)
            .map((x) => (x as Map)['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');
        final date = (a['pubdate'] as String?) ?? '';
        final journal = (a['source'] as String?) ?? 'PubMed';
        out.add(
          MindfulnessItem(
            id: 'pubmed_$pmid',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (date.isNotEmpty) date,
              journal,
            ].join(' · '),
            type: MindfulnessResourceType.research,
            author: authors.isNotEmpty ? authors : null,
            description:
                'Published in $journal. View on PubMed for abstract and full text.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/$pmid/',
            emoji: '🔬',
            source: 'PubMed',
          ),
        );
      }
    } catch (e) {
      _log('PubMed: $e');
    }
  }

  void _check(http.Response r, String src) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw MindfulnessServiceException(
        '$src returned ${r.statusCode}',
        statusCode: r.statusCode,
      );
    }
  }

  String _clean(String t) => t.endsWith('.') ? t.substring(0, t.length - 1) : t;
  void _log(String m) {
    assert(() {
      print('[MindfulnessService] $m');
      return true;
    }());
  }
}

class _G {
  final String id, title, subtitle, emoji, body;
  const _G({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.body,
  });
}
