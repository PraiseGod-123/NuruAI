import 'dart:convert';
import 'package:http/http.dart' as http;

// Enums
enum BreathingCategory { regulation, anxiety, focus, sleep, grounding }

// Models
class BreathingResearch {
  final String title;
  final String authors;
  final String journal;
  final String pubDate;
  final String pmid;
  final String url;

  const BreathingResearch({
    required this.title,
    required this.authors,
    required this.journal,
    required this.pubDate,
    required this.pmid,
    required this.url,
  });
}

class BreathingTechnique {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String autismNote;
  final String emoji;
  final List<int> pattern;
  final int cycles;
  final String difficulty;
  final BreathingCategory category;
  final List<String> benefits;
  final String source;
  final String wikiSlug;
  final String pubmedQuery;

  // Enriched at runtime by the service
  String? wikiSummary;
  List<BreathingResearch> research;

  BreathingTechnique({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.autismNote,
    required this.emoji,
    required this.pattern,
    required this.cycles,
    required this.difficulty,
    required this.category,
    required this.benefits,
    required this.source,
    required this.wikiSlug,
    required this.pubmedQuery,
    this.wikiSummary,
    this.research = const [],
  });
}

// Service
class BreathingService {
  BreathingService._();
  static final BreathingService instance = BreathingService._();

  static const String _pubmedBase =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://eutils.ncbi.nlm.nih.gov/entrez/eutils';
  static const String _wikipediaBase =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://en.wikipedia.org/api/rest_v1';
  static const Duration _timeout = Duration(seconds: 10);
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  // Cache: technique id -> enriched technique
  final Map<String, BreathingTechnique> _cache = {};

  // Curated techniques
  static List<BreathingTechnique> get techniques => [
    //Box Breathing
    BreathingTechnique(
      id: 'box',
      name: 'Box Breathing',
      subtitle: 'Equal sides - Predictable rhythm',
      description:
          'Four equal counts: inhale, hold, exhale, hold. The symmetry '
          'and predictability make this ideal for autism: there are no '
          'surprises, and the visual "box" shape gives a concrete anchor.',
      autismNote:
          'The equal, repeating pattern removes uncertainty. Many autistic '
          'individuals find the rhythmic predictability regulating -- it '
          'mirrors the comfort of routine and sameness. Used by occupational '
          'therapists in sensory regulation programmes.',
      emoji: '\u2b1b',
      pattern: [4, 4, 4, 4],
      cycles: 5,
      difficulty: 'Beginner',
      category: BreathingCategory.regulation,
      benefits: [
        'Reduces cortisol and stress hormones',
        'Activates the parasympathetic nervous system',
        'Predictable -- safe during sensory overload',
        'Improves heart rate variability (HRV)',
        'Clinically used in PTSD and anxiety treatment',
      ],
      source: 'US Navy SEAL training; validated in clinical anxiety research',
      wikiSlug: 'Box_breathing',
      pubmedQuery: 'box breathing anxiety stress autonomic nervous system',
    ),

    // 4-7-8 Breathing
    BreathingTechnique(
      id: '478',
      name: '4-7-8 Breathing',
      subtitle: 'Dr Weil\'s calm-down technique',
      description:
          'Inhale for 4, hold for 7, exhale slowly for 8. The extended '
          'exhale activates the vagus nerve -- the body\'s natural '
          'off-switch for the stress response.',
      autismNote:
          'Research shows autistic individuals often have dysregulated '
          'autonomic nervous systems. The long exhale directly stimulates '
          'vagal tone, helping shift the nervous system from fight-or-flight '
          'to rest-and-digest -- particularly useful after sensory overload '
          'or emotional dysregulation episodes.',
      emoji: '\ud83c\udf0a',
      pattern: [4, 7, 8, 0],
      cycles: 4,
      difficulty: 'Intermediate',
      category: BreathingCategory.anxiety,
      benefits: [
        'Directly stimulates the vagus nerve',
        'Reduces acute anxiety within 60 seconds',
        'Slows heart rate measurably',
        'Helps with sleep onset',
        'Counters hyperventilation from anxiety',
      ],
      source: 'Dr Andrew Weil, Harvard Medical School; pranayama tradition',
      wikiSlug: 'Pranayama',
      pubmedQuery: '4-7-8 breathing vagus nerve anxiety parasympathetic',
    ),

    // Diaphragmatic / Belly Breathing
    BreathingTechnique(
      id: 'diaphragmatic',
      name: 'Belly Breathing',
      subtitle: 'Diaphragmatic - Deep and slow',
      description:
          'Slow, deep breaths that fully engage the diaphragm. You breathe '
          'into the belly, not the chest. This is the most fundamental '
          'relaxation breath and the basis for most other techniques.',
      autismNote:
          'Autistic children and adults frequently breathe shallowly during '
          'stress, which amplifies anxiety. Studies confirm diaphragmatic '
          'breathing reduces physiological stress markers in young people '
          'aged 6-18. It is taught in most ASD occupational therapy programmes '
          'as a foundation skill.',
      emoji: '\ud83e\udef1',
      pattern: [4, 2, 6, 0],
      cycles: 6,
      difficulty: 'Beginner',
      category: BreathingCategory.regulation,
      benefits: [
        'Lowers heart rate and blood pressure',
        'Reduces muscle tension throughout the body',
        'Increases oxygen delivery to the brain',
        'Reduces cortisol in children and adolescents',
        'No equipment needed -- works anywhere',
      ],
      source:
          'American Lung Association; validated in paediatric stress research',
      wikiSlug: 'Diaphragmatic_breathing',
      pubmedQuery:
          'diaphragmatic breathing children adolescents anxiety stress reduction',
    ),

    //Resonant / Coherent Breathing
    BreathingTechnique(
      id: 'resonant',
      name: 'Resonant Breathing',
      subtitle: '5 breaths per minute - Heart coherence',
      description:
          'Breathe at exactly 5 breaths per minute: 5 seconds in, '
          '5 seconds out. This synchronises heart rhythm and breathing '
          'rhythm. HeartMath Institute research shows this maximises '
          'heart rate variability.',
      autismNote:
          'Low HRV is consistently found in autism research, indicating '
          'a dysregulated autonomic nervous system. Resonant breathing '
          'directly addresses this -- it has been studied specifically in '
          'autistic populations and shown to improve emotional regulation '
          'and reduce anxiety over 4-8 weeks of practice.',
      emoji: '\ud83d\udc99',
      pattern: [5, 0, 5, 0],
      cycles: 6,
      difficulty: 'Intermediate',
      category: BreathingCategory.focus,
      benefits: [
        'Maximises heart rate variability (HRV)',
        'Balances sympathetic/parasympathetic tone',
        'Studied specifically in autistic populations',
        'Reduces chronic stress over weeks of practice',
        'Improves cognitive performance and focus',
      ],
      source:
          'HeartMath Institute; Lehrer and Gevirtz (2014) Frontiers in Psychology',
      wikiSlug: 'Heart_rate_variability',
      pubmedQuery:
          'resonant coherent breathing heart rate variability autism anxiety',
    ),

    //Extended Exhale
    BreathingTechnique(
      id: 'extended_exhale',
      name: 'Extended Exhale',
      subtitle: 'Longer out-breath - Quick calm',
      description:
          'Any breathing where the exhale is longer than the inhale '
          'activates the parasympathetic system. This 4-count in, '
          '6-count out pattern is the simplest way to engage your '
          'body\'s natural calm response.',
      autismNote:
          'This is ideal for early signs of meltdown or sensory overload '
          'because it works quickly and the ratio is easy to remember. '
          'Cognitive Behavioural Therapy for autism recommends extended '
          'exhale breathing as a first-line self-regulation tool before '
          'escalation occurs.',
      emoji: '\ud83c\udf2c\ufe0f',
      pattern: [4, 0, 6, 0],
      cycles: 8,
      difficulty: 'Beginner',
      category: BreathingCategory.grounding,
      benefits: [
        'Fast-acting -- works in under 2 minutes',
        'Directly activates the parasympathetic system',
        'Recommended in CBT for autism programmes',
        'Easy ratio to remember under stress',
        'Reduces physiological arousal quickly',
      ],
      source: 'Mindfulness-Based Cognitive Therapy; CBT for autism protocols',
      wikiSlug: 'Relaxation_technique',
      pubmedQuery:
          'extended exhale breathing parasympathetic activation anxiety',
    ),

    //Grounding Breath
    BreathingTechnique(
      id: 'grounding',
      name: 'Grounding Breath',
      subtitle: 'Sensory overload first-response',
      description:
          'A gentle, even-paced breath designed as an immediate response '
          'to sensory overload. The short pause between inhale and exhale '
          'gives the nervous system just enough space to reset.',
      autismNote:
          'Developed for use in sensory integration therapy, this technique '
          'is intentionally simple: 4 counts in, 2-count pause, 4 counts '
          'out. The brevity means it can be initiated even when cognitive '
          'load is high during sensory overload. It is taught in many '
          'autism sensory support programmes as the first breath tool.',
      emoji: '\ud83c\udf31',
      pattern: [4, 2, 4, 0],
      cycles: 8,
      difficulty: 'Beginner',
      category: BreathingCategory.grounding,
      benefits: [
        'Designed for sensory overload situations',
        'Minimal cognitive load -- easy under stress',
        'Gentle enough for children and teens',
        'Works as a meltdown prevention tool',
        'Builds self-regulation habit over time',
      ],
      source: 'Sensory Integration Therapy; occupational therapy for ASD',
      wikiSlug: 'Sensory_processing_disorder',
      pubmedQuery: 'breathing grounding sensory overload autism regulation',
    ),

    //Sleep Breath
    BreathingTechnique(
      id: 'sleep',
      name: 'Sleep Breath',
      subtitle: 'Wind-down - Before bedtime',
      description:
          'A slow, progressive breath specifically designed for sleep '
          'onset. The long hold and very extended exhale mimic the '
          'natural slowing of breath that occurs as the body falls asleep.',
      autismNote:
          'Sleep difficulties affect 40-80% of autistic individuals. '
          'This breath specifically targets the insomnia cycle: it slows '
          'racing thoughts through rhythmic focus, reduces physiological '
          'arousal, and trains the body to associate this pattern with '
          'sleep -- a form of bedtime routine that benefits from the '
          'autistic preference for predictable ritual.',
      emoji: '\ud83c\udf19',
      pattern: [4, 7, 8, 0],
      cycles: 6,
      difficulty: 'Beginner',
      category: BreathingCategory.sleep,
      benefits: [
        'Reduces sleep onset time',
        'Addresses autistic sleep difficulties (40-80% prevalence)',
        'Slows racing thoughts through rhythmic focus',
        'Creates a calming bedtime ritual',
        'Lowers heart rate for sleep state',
      ],
      source: 'Sleep Foundation; autism sleep research (Malow et al., 2012)',
      wikiSlug: 'Sleep_hygiene',
      pubmedQuery: 'breathing sleep autism insomnia relaxation',
    ),
  ];

  // PUBLIC: Enrich a technique with live research from APIs.
  Future<BreathingTechnique> enrichTechnique(
    BreathingTechnique technique,
  ) async {
    if (_cache.containsKey(technique.id)) {
      return _cache[technique.id]!;
    }

    // Fetch Wikipedia + PubMed in parallel
    await Future.wait([
      _fetchWikiSummary(technique),
      _fetchPubMedResearch(technique),
    ]);

    _cache[technique.id] = technique;
    return technique;
  }

  void clearCache() => _cache.clear();

  // Wikipedia
  Future<void> _fetchWikiSummary(BreathingTechnique technique) async {
    try {
      final slug = Uri.encodeComponent(technique.wikiSlug);
      final uri = Uri.parse('$_wikipediaBase/page/summary/$slug');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final extract = data['extract'] as String? ?? '';
      if (extract.isEmpty) return;

      // First 3 sentences as background snippet
      final sentences = extract.split('. ');
      technique.wikiSummary = sentences.take(3).join('. ').trimRight();
      if (!technique.wikiSummary!.endsWith('.')) {
        technique.wikiSummary = '${technique.wikiSummary}.';
      }
    } catch (_) {
      //Silently swallow
    }
  }

  //PubMed
  Future<void> _fetchPubMedResearch(BreathingTechnique technique) async {
    try {
      //search for article IDs
      final searchUri = Uri.parse('$_pubmedBase/esearch.fcgi').replace(
        queryParameters: {
          'db': 'pubmed',
          'term': '${technique.pubmedQuery}[Title/Abstract]',
          'retmax': '3',
          'retmode': 'json',
          'sort': 'relevance',
          'datetype': 'pdat',
          'reldate': '2555', // ~7 years
        },
      );

      final searchRes = await http
          .get(searchUri, headers: _headers)
          .timeout(_timeout);
      if (searchRes.statusCode < 200 || searchRes.statusCode >= 300) return;

      final searchData = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final idList =
          ((searchData['esearchresult']?['idlist']) as List?)
              ?.map((id) => id.toString())
              .toList() ??
          [];
      if (idList.isEmpty) return;

      //fetch article summaries
      final summaryUri = Uri.parse('$_pubmedBase/esummary.fcgi').replace(
        queryParameters: {
          'db': 'pubmed',
          'id': idList.join(','),
          'retmode': 'json',
        },
      );

      final summaryRes = await http
          .get(summaryUri, headers: _headers)
          .timeout(_timeout);
      if (summaryRes.statusCode < 200 || summaryRes.statusCode >= 300) return;

      final summaryData = jsonDecode(summaryRes.body) as Map<String, dynamic>;
      final results = (summaryData['result'] as Map<String, dynamic>?) ?? {};

      final research = <BreathingResearch>[];
      for (final pmid in idList) {
        final article = results[pmid] as Map<String, dynamic>?;
        if (article == null) continue;

        final title = _clean(article['title'] as String? ?? '');
        if (title.isEmpty) continue;

        final authors = ((article['authors'] as List?) ?? [])
            .take(3)
            .map((a) => (a as Map)['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');

        research.add(
          BreathingResearch(
            title: title,
            authors: authors,
            journal: article['source'] as String? ?? '',
            pubDate: article['pubdate'] as String? ?? '',
            pmid: pmid,
            url: 'https://pubmed.ncbi.nlm.nih.gov/$pmid/',
          ),
        );
      }

      technique.research = research;
    } catch (_) {
      // Silently swallow
    }
  }

  String _clean(String s) => s.endsWith('.') ? s.substring(0, s.length - 1) : s;
}
