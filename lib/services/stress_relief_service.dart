import 'dart:convert';
import 'package:http/http.dart' as http;

// STRESS RELIEF SERVICE
enum StressResourceType { book, research, guide, technique }

class StressItem {
  final String id;
  final String title;
  final String subtitle;
  final StressResourceType type;
  final String? author;
  final String? description;
  final String? url;
  final String? coverUrl;
  final String emoji;
  final String source;
  final String? subcategory;

  const StressItem({
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

class StressServiceException implements Exception {
  final String message;
  final int? statusCode;
  const StressServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'StressServiceException: $message';
}

class StressReliefService {
  StressReliefService._();
  static final StressReliefService instance = StressReliefService._();

  static const _openLibraryBase =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://openlibrary.org';
  static const _pubmedBase =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://eutils.ncbi.nlm.nih.gov/entrez/eutils';
  static const _timeout = Duration(seconds: 12);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  List<StressItem>? _cached;

  Future<List<StressItem>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final results = <StressItem>[];
    _injectGuides(results);

    await Future.wait([
      _fetchBooks('stress relief autism sensory overload', results, limit: 4),
      _fetchBooks(
        'burnout recovery self care neurodivergent',
        results,
        limit: 3,
      ),
      _fetchBooks('relaxation techniques stress management', results, limit: 3),
      _fetchPubMed(
        'stress reduction intervention autism spectrum disorder',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'sensory overload stress autistic adults adolescents',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'progressive relaxation cortisol stress ASD',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'autistic burnout stress recovery intervention',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'nature exposure stress reduction neurodevelopmental',
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

  void _injectGuides(List<StressItem> results) {
    for (final g in _understanding) {
      results.add(
        StressItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: StressResourceType.guide,
          description: g.body,
          emoji: g.emoji,
          source: 'NuruAI Guide',
          subcategory: 'understanding',
        ),
      );
    }
    for (final g in _communication) {
      results.add(
        StressItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: StressResourceType.guide,
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
      id: 'sr_what_is_stress',
      title: 'Stress and the Autistic Nervous System',
      subtitle: 'Why stress hits harder and lasts longer with ASD',
      emoji: '⚡',
      body:
          'Stress is a biological response to perceived threat. For autistic individuals, the threshold for that response is often lower — and the recovery time is longer.\n\n'
          'Why stress is amplified in ASD:\n'
          '• Sensory processing differences mean the nervous system is processing more input, more intensely\n'
          '• Unpredictability and change trigger threat responses more easily\n'
          '• Social demands require constant effort — "masking" is physiologically exhausting\n'
          '• Interoception differences make it harder to notice stress building until it is overwhelming\n'
          '• Executive function load depletes stress-buffering resources faster\n\n'
          'Autistic Burnout:\n'
          'When stress accumulates over months without adequate recovery, many autistic individuals experience burnout — a profound loss of skills, function, and energy. Prevention requires consistent, proactive stress relief, not just crisis management.\n\n'
          'Key insight: Stress relief for ASD is not a luxury. It is medical maintenance.',
    ),
    _G(
      id: 'sr_stress_signals',
      title: 'Reading Your Stress Signals',
      subtitle: 'Recognising stress in your body before it becomes crisis',
      emoji: '🔍',
      body:
          'Many autistic individuals notice stress very late — because interoception (the ability to read internal body states) is often reduced in ASD.\n\n'
          'Common stress signals to watch for:\n'
          '• Increased sensitivity to sounds, lights, or touch\n'
          '• Shutdown or withdrawal without knowing why\n'
          '• Stronger than usual stimming or repetitive behaviour\n'
          '• Difficulty with tasks that are usually manageable\n'
          '• Irritability, snapping at things that do not normally bother you\n'
          '• Fatigue that sleep does not fix\n'
          '• Feeling like your brain is "full"\n'
          '• Increased need for routine and sameness\n\n'
          'Exercise — Stress Body Map:\n'
          'Draw a body outline. Mark where you feel tension, heat, or discomfort when stressed. Revisit it weekly. Over time you will learn your personal early warning system.',
    ),
    _G(
      id: 'sr_sensory_stress',
      title: 'Sensory Overload and Stress',
      subtitle: 'When the environment itself is the stressor',
      emoji: '🌪️',
      body:
          'For many autistic individuals, stress is not primarily psychological — it is sensory. The environment itself is the source of stress, and standard "think positive" approaches will not fix a sensory overload.\n\n'
          'Common sensory stressors:\n'
          '• Fluorescent lighting (flicker, colour temperature)\n'
          '• Background noise and overlapping sounds\n'
          '• Crowded spaces and unpredictable movement\n'
          '• Uncomfortable clothing textures\n'
          '• Strong or unexpected smells\n'
          '• Temperature extremes\n\n'
          'Sensory stress relief strategies:\n'
          '• Identify your sensory stressors and reduce exposure where possible\n'
          '• Create low-stimulation spaces at home and work\n'
          '• Noise-cancelling headphones, sunglasses indoors, weighted items — these are legitimate tools\n'
          '• Build in "sensory recovery" time after demanding environments\n'
          '• Communicate sensory needs to people around you\n\n'
          'Tip: You do not need to justify sensory accommodations. Your nervous system is real.',
    ),
    _G(
      id: 'sr_burnout',
      title: 'Autistic Burnout',
      subtitle: 'What it is, what causes it, and how to recover',
      emoji: '🔋',
      body:
          'Autistic burnout is a state of physical and mental exhaustion caused by sustained, high-level demand that exceeds capacity. It is distinct from depression and from general burnout.\n\n'
          'Signs of autistic burnout:\n'
          '• Loss of previously held skills and abilities\n'
          '• Dramatic increase in autistic traits (stimming, need for sameness)\n'
          '• Complete withdrawal from social interaction\n'
          '• Cognitive fog — difficulty thinking, speaking, or processing\n'
          '• Deep fatigue that does not resolve with rest\n'
          '• Loss of ability to mask or adapt\n\n'
          'Causes:\n'
          '• Sustained masking over months or years\n'
          '• High social or sensory demands without recovery time\n'
          '• Major life transitions (school, work, relationships)\n'
          '• Lack of support and having to manage everything alone\n\n'
          'Recovery:\n'
          'Burnout recovery requires reducing demands, increasing rest, and allowing regression without shame. It is not laziness. It is healing.\n\n'
          'If you recognise burnout: speak to a professional, reduce obligations, and prioritise recovery. This is a medical need.',
    ),
  ];

  static const _communication = [
    _G(
      id: 'sr_asking_help',
      title: 'Asking for Help When Stressed',
      subtitle: 'Scripts for when you are overwhelmed and need support',
      emoji: '🙏',
      body:
          'When stress is high, finding words is harder. Having prepared scripts means you do not have to generate them under pressure.\n\n'
          'Short scripts to use:\n'
          '"I am overwhelmed right now. I need quiet time."\n'
          '"I am at my limit. Can we continue this later?"\n'
          '"I need to step away. I\'ll come back when I\'ve reset."\n'
          '"I\'m finding this environment very difficult. Can we move?"\n'
          '"I\'m struggling today. I might be slower or quieter than usual."\n\n'
          'With trusted people:\n'
          '"I think I\'m heading toward burnout. Can you help me reduce what\'s on my plate?"\n'
          '"I need you to not add anything new to my list this week."\n'
          '"I need low-demand time together — no conversation, just presence."\n\n'
          'Tip: Write these on your phone so you can show them instead of saying them.',
    ),
    _G(
      id: 'sr_setting_limits',
      title: 'Protecting Your Energy',
      subtitle: 'How to say no without guilt and reduce your stress load',
      emoji: '🛡️',
      body:
          'Every commitment you take on uses energy. Stress accumulates when your energy output consistently exceeds your input. Protecting your energy is not selfishness — it is maintenance.\n\n'
          'Saying no effectively:\n'
          '"I\'m not able to take that on right now." — No explanation needed.\n'
          '"I need to check my capacity before I commit." — Buys time.\n'
          '"I\'d like to help but I\'m at my limit." — Honest and direct.\n\n'
          'Reducing existing load:\n'
          '• Identify which commitments drain you most\n'
          '• Ask: which of these is truly non-negotiable?\n'
          '• Communicate reduced availability before you crash, not after\n\n'
          'For ASD:\n'
          'Autistic individuals often feel intense obligation to others. This can lead to consistent over-commitment and chronic stress. Your needs are as valid as theirs.',
    ),
  ];

  Future<void> _fetchBooks(
    String query,
    List<StressItem> out, {
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
          StressItem(
            id: 'book_${key.replaceAll('/', '_')}',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (year.isNotEmpty) year,
            ].join(' · '),
            type: StressResourceType.book,
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
    List<StressItem> out, {
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
          StressItem(
            id: 'pubmed_$pmid',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (date.isNotEmpty) date,
              journal,
            ].join(' · '),
            type: StressResourceType.research,
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
      throw StressServiceException(
        '$src returned ${r.statusCode}',
        statusCode: r.statusCode,
      );
    }
  }

  String _clean(String t) => t.endsWith('.') ? t.substring(0, t.length - 1) : t;
  void _log(String m) {
    assert(() {
      print('[StressReliefService] $m');
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
