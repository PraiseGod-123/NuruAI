import 'dart:convert';
import 'package:http/http.dart' as http;

// SELF CONTROL SERVICE
enum SelfControlResourceType { book, research, guide, technique }

class SelfControlItem {
  final String id;
  final String title;
  final String subtitle;
  final SelfControlResourceType type;
  final String? author;
  final String? description;
  final String? url;
  final String? coverUrl;
  final String emoji;
  final String source;
  final String? subcategory;

  const SelfControlItem({
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

class SelfControlServiceException implements Exception {
  final String message;
  final int? statusCode;
  const SelfControlServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'SelfControlServiceException: $message';
}

class SelfControlService {
  SelfControlService._();
  static final SelfControlService instance = SelfControlService._();

  static const _openLibraryBase =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://openlibrary.org';
  static const _pubmedBase =
      'https://nuruai-api-production.up.railway.app/proxy?url=https://eutils.ncbi.nlm.nih.gov/entrez/eutils';
  static const _timeout = Duration(seconds: 12);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  List<SelfControlItem>? _cached;

  // PUBLIC
  Future<List<SelfControlItem>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final results = <SelfControlItem>[];

    // Offline guides first
    _injectGuides(results);

    // Network in parallel
    await Future.wait([
      _fetchBooks('self control impulse regulation autism', results, limit: 4),
      _fetchBooks('delayed gratification self discipline', results, limit: 3),
      _fetchBooks(
        'cognitive behavioral therapy self regulation',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'self-regulation impulse control autism spectrum disorder',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'inhibitory control executive function ASD adolescent',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'urge surfing impulse control behavioral intervention',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'delayed gratification self control intervention neurodevelopmental',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'mindfulness self regulation autism impulsivity',
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

  // NURURAI GUIDES
  void _injectGuides(List<SelfControlItem> results) {
    for (final g in _understanding) {
      results.add(
        SelfControlItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: SelfControlResourceType.guide,
          description: g.body,
          emoji: g.emoji,
          source: 'NuruAI Guide',
          subcategory: 'understanding',
        ),
      );
    }
    for (final g in _communication) {
      results.add(
        SelfControlItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: SelfControlResourceType.guide,
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
      id: 'sc_what_is',
      title: 'What Is Self Control?',
      subtitle: 'The brain science of pausing before you act',
      emoji: '🧠',
      body:
          'Self control is the ability to pause between a trigger and your response — to choose your behaviour rather than be driven by it.\n\n'
          'It is not willpower. It is a skill based in the prefrontal cortex (PFC) — the part of the brain responsible for planning, consequences, and impulse inhibition.\n\n'
          'For ASD and ADHD:\n'
          '• The PFC develops more slowly — impulse control catches up later than in neurotypical peers\n'
          '• Emotional intensity amplifies impulses — the urge feels more urgent than it is\n'
          '• Executive function differences mean the "pause" between stimulus and response is shorter\n'
          '• Sensory overload depletes the self-control resource — when overwhelmed, impulse control drops\n\n'
          'Key insight: Self control is not about being a "good person." It is a trainable neurological skill. Every time you pause and choose, you strengthen the circuit.',
    ),
    _G(
      id: 'sc_impulse_cycle',
      title: 'The Impulse Cycle',
      subtitle:
          'Trigger → urge → action → consequence — and how to interrupt it',
      emoji: '🔄',
      body:
          'Understanding the impulse cycle is the first step to interrupting it.\n\n'
          '1. TRIGGER — something happens (a frustration, a desire, a feeling)\n'
          '2. URGE — an automatic pull to do or say something\n'
          '3. ACTION — you act on the urge\n'
          '4. CONSEQUENCE — the result (often regret, conflict, or harm)\n\n'
          'The intervention point is between Step 2 and Step 3.\n\n'
          'That gap is tiny — sometimes under a second. But it exists. And it can be widened.\n\n'
          'For ASD:\n'
          'The gap between urge and action is often shorter than in neurotypical individuals. The techniques in this section are specifically designed to widen it — using the body, not just the mind.\n\n'
          'Exercise: This week, notice when you feel an urge. Do not judge it. Just notice: "There is an urge right now." That awareness alone begins to widen the gap.',
    ),
    _G(
      id: 'sc_asd_context',
      title: 'Self Control and ASD',
      subtitle: 'Why impulse regulation is harder — and how to work with it',
      emoji: '🧩',
      body:
          'Impulsivity in ASD is not a character flaw. It is the result of real neurological differences in how the brain processes signals, manages sensory input, and inhibits automatic responses.\n\n'
          'Research shows:\n'
          '• Autistic individuals show reduced activity in the anterior cingulate cortex — the brain region that detects conflict between impulse and goal\n'
          '• Sensory processing differences mean the nervous system is often already at capacity, leaving fewer resources for inhibitory control\n'
          '• Emotional responses in ASD are often more intense — which makes urges feel more urgent\n'
          '• Many autistic individuals have co-occurring ADHD, which adds impulsivity as a core feature\n\n'
          'What works for ASD:\n'
          '• Physical techniques (body-based) work better than pure cognitive ones\n'
          '• External structure and cues help (visual timers, rules, routines)\n'
          '• Environment modification is often more effective than willpower\n'
          '• Predictable systems replace the need for impulse control entirely\n\n'
          'Tip: Do not fight your nervous system. Design around it.',
    ),
    _G(
      id: 'sc_delayed_gratification',
      title: 'Delayed Gratification',
      subtitle: 'Tolerating the wait — why it matters and how to build it',
      emoji: '⏳',
      body:
          'Delayed gratification is the ability to resist an immediate reward in order to receive a larger or more appropriate reward later.\n\n'
          'The famous "marshmallow test" (Walter Mischel, Stanford) showed that children who could wait longer had better life outcomes — but later research showed this is about environment and security, not fixed personality.\n\n'
          'Delayed gratification can be trained:\n\n'
          '• Make the wait visible — use a physical timer so "the wait" has a concrete end\n'
          '• Shrink the wait — "I will wait 2 minutes" is more achievable than "I will wait"\n'
          '• Distract during the wait — an activity makes time feel shorter\n'
          '• Reward the waiting — acknowledge yourself for every successful pause\n'
          '• Understand the why — knowing why you are waiting makes it easier to tolerate\n\n'
          'For ASD:\n'
          'Abstract waiting is very hard. Concrete, visible waiting (timer countdown, visual chart) is significantly easier. Use tools, not willpower.',
    ),
  ];

  static const _communication = [
    _G(
      id: 'sc_comm_expressing_limits',
      title: 'Expressing Your Limits',
      subtitle: 'Telling people what you need before you lose control',
      emoji: '🗣️',
      body:
          'One of the most powerful self-control strategies is communicating your state to others before it escalates.\n\n'
          '"I am starting to feel overwhelmed. I need a few minutes."\n'
          '"I am finding this conversation really hard right now."\n'
          '"I need to stop and reset before we continue."\n\n'
          'This does three things:\n'
          '• It signals to others that you need space — reducing escalating pressure\n'
          '• It activates your verbal/language brain — which competes with the impulse\n'
          '• It gives you permission to exit before losing control\n\n'
          'Practise these scripts when calm so they come automatically under stress.',
    ),
    _G(
      id: 'sc_comm_accountability',
      title: 'Using an Accountability Partner',
      subtitle: 'A trusted person who helps you stay on track',
      emoji: '🤝',
      body:
          'Self control is significantly easier with external support. An accountability partner is someone who:\n\n'
          '• Knows your specific impulse challenges\n'
          '• Has an agreed signal or word they can use when they notice you escalating\n'
          '• Does not shame or lecture — just gently names what they see\n'
          '• Celebrates your successes with you\n\n'
          'How to set it up:\n'
          '1. Choose someone you trust completely\n'
          '2. Tell them specifically what you struggle with\n'
          '3. Agree on a signal (a word, a look, a tap on the shoulder)\n'
          '4. Agree that when they use it, you will pause — not defend\n'
          '5. Review weekly: what worked, what was hard\n\n'
          'This is not weakness. Every high-performer uses accountability structures.',
    ),
    _G(
      id: 'sc_comm_repair',
      title: 'After You Lose Control',
      subtitle: 'What to do when your impulse caused harm',
      emoji: '🩹',
      body:
          'Acting on impulse and causing harm — to yourself, a relationship, or a situation — is not the end. What you do next matters more than the moment itself.\n\n'
          'The repair steps:\n'
          '1. Wait until you are calm — you cannot repair from a dysregulated state\n'
          '2. Acknowledge what happened without minimising: "I said something hurtful. I acted before thinking."\n'
          '3. Take responsibility without over-explaining: "I am sorry. That was not okay."\n'
          '4. Ask what would help repair the situation\n'
          '5. Reflect privately: what was the trigger? what will you do differently?\n\n'
          'Avoid:\n'
          '• "But I was upset because…" — this shifts focus to your feelings before acknowledging theirs\n'
          '• Over-apologising — say it clearly once, then show it through behaviour\n'
          '• Punishing yourself — the goal is learning, not suffering',
    ),
  ];

  // OPEN LIBRARY
  Future<void> _fetchBooks(
    String query,
    List<SelfControlItem> out, {
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
          SelfControlItem(
            id: 'book_${key.replaceAll('/', '_')}',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (year.isNotEmpty) year,
            ].join(' · '),
            type: SelfControlResourceType.book,
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

  // PUBMED
  Future<void> _fetchPubMed(
    String query,
    List<SelfControlItem> out, {
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
          SelfControlItem(
            id: 'pubmed_$pmid',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (date.isNotEmpty) date,
              journal,
            ].join(' · '),
            type: SelfControlResourceType.research,
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
      throw SelfControlServiceException(
        '$src returned ${r.statusCode}',
        statusCode: r.statusCode,
      );
    }
  }

  String _clean(String t) => t.endsWith('.') ? t.substring(0, t.length - 1) : t;
  void _log(String m) {
    assert(() {
      print('[SelfControlService] $m');
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
