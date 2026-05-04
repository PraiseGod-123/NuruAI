import 'dart:convert';
import 'package:http/http.dart' as http;

//Models
enum ResourceType { book, poem, article, research, guide }

class ResourceItem {
  final String id;
  final String title;
  final String subtitle;
  final ResourceType type;
  final String? author;
  final String? description;
  final String? url;
  final String? coverUrl;
  final String emoji;
  final String source; // which API this came from
  final String?
  loveSubcategory; // 'love_languages' | 'understand_partner' | 'commitment' | null

  const ResourceItem({
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
    this.loveSubcategory,
  });
}

class ResourceServiceException implements Exception {
  final String message;
  final int? statusCode;
  const ResourceServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'ResourceServiceException: $message';
}

//Service

class ResourceService {
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  // Base URLs

  static const String _openLibraryBase = 'https://openlibrary.org';
  static const String _poetryDbBase = 'https://poetrydb.org';
  static const String _wikipediaBase = 'https://en.wikipedia.org/api/rest_v1';
  static const String _pubmedBase =
      'https://eutils.ncbi.nlm.nih.gov/entrez/eutils';

  //In-memory cache
  final Map<String, List<ResourceItem>> _cache = {};

  //Timeout

  static const Duration _timeout = Duration(seconds: 10);

  //Shared headers

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  // PUBLIC: fetch all resources for a category
  Future<List<ResourceItem>> fetchCategory(String categoryId) async {
    // Return cached result if available
    if (_cache.containsKey(categoryId)) {
      return _cache[categoryId]!;
    }

    final results = <ResourceItem>[];

    switch (categoryId) {
      case 'autism':
        await Future.wait([
          _fetchBooks('autism spectrum disorder', results, limit: 4),
          _fetchWikiSummary('Autism_spectrum_disorder', results),
          _fetchPubMedArticles('autism spectrum', results, limit: 3),
        ]);
        break;

      case 'adhd':
        await Future.wait([
          _fetchBooks(
            'ADHD attention deficit hyperactivity',
            results,
            limit: 4,
          ),
          _fetchWikiSummary(
            'Attention_deficit_hyperactivity_disorder',
            results,
          ),
          _fetchPubMedArticles(
            'attention deficit hyperactivity disorder',
            results,
            limit: 3,
          ),
        ]);
        break;

      case 'depression':
        await Future.wait([
          _fetchBooks('depression mental health recovery', results, limit: 4),
          _fetchWikiSummary('Major_depressive_disorder', results),
          _fetchPubMedArticles(
            'major depressive disorder treatment',
            results,
            limit: 3,
          ),
        ]);
        break;

      case 'love':
        await Future.wait([
          // Curated guides — always injected first (static, no API call needed)
          Future.sync(() => _injectLoveGuides(results)),

          // Books: love languages & relationships
          _fetchBooks('five love languages relationships', results, limit: 3),
          _fetchBooks(
            'understanding your partner communication',
            results,
            limit: 2,
          ),
          _fetchBooks('commitment long term relationships', results, limit: 2),
          _fetchBooks(
            'self love self worth emotional healing',
            results,
            limit: 2,
          ),

          // Wikipedia articles
          _fetchWikiSummary('Love_languages', results),
          _fetchWikiSummary('Interpersonal_relationship', results),
          _fetchWikiSummary('Intimate_relationship', results),
          _fetchWikiSummary('Self-love', results),

          // PubMed: relationship science
          _fetchPubMedArticles(
            'romantic relationship commitment satisfaction',
            results,
            limit: 2,
          ),
          _fetchPubMedArticles(
            'love languages attachment style couples',
            results,
            limit: 2,
          ),
        ]);
        break;

      case 'baking':
        await Future.wait([
          _fetchBooks('baking bread pastry cookbook', results, limit: 5),
          _fetchWikiSummary('Baking', results),
          _fetchWikiSummary('Bread', results),
        ]);
        break;

      case 'poems':
        await Future.wait([
          _fetchPoems('Emily Dickinson', results, limit: 2),
          _fetchPoems('Langston Hughes', results, limit: 2),
          _fetchPoems('Percy Bysshe Shelley', results, limit: 2),
          _fetchPoems('William Blake', results, limit: 1),
          _fetchBooks('poetry anthology modern collection', results, limit: 3),
        ]);
        break;
    }

    // Deduplicate by title
    final seen = <String>{};
    final deduped = results.where((r) {
      final key = r.title.toLowerCase();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    _cache[categoryId] = deduped;
    return deduped;
  }

  // Clear cache (e.g. on pull-to-refresh)

  void clearCache([String? categoryId]) {
    if (categoryId != null) {
      _cache.remove(categoryId);
    } else {
      _cache.clear();
    }
  }

  void _injectLoveGuides(List<ResourceItem> results) {
    // Love Languages
    final loveLanguages = [
      _LoveGuide(
        id: 'lg_words_affirmation',
        title: 'Words of Affirmation',
        subtitle: 'Expressing love through verbal encouragement',
        emoji: '💬',
        body:
            'If your love language is Words of Affirmation, you feel most loved when your partner uses words to build you up.\n\n'
            '• Say "I love you" and mean it — often\n'
            '• Offer genuine compliments unprompted\n'
            '• Leave a kind note or voice message\n'
            '• Acknowledge their efforts out loud\n'
            '• Avoid harsh criticism — words hurt deeply\n\n'
            'Tip: Ask your partner, "What is something I do or say that makes you feel appreciated?" Their answer tells you everything.',
      ),
      _LoveGuide(
        id: 'lg_quality_time',
        title: 'Quality Time',
        subtitle: 'Full, undivided attention as an act of love',
        emoji: '⏳',
        body:
            'Quality Time means giving your partner your complete, undivided presence — not just being in the same room.\n\n'
            '• Put your phone away during conversations\n'
            '• Plan activities you both enjoy\n'
            '• Make eye contact and actively listen\n'
            '• Create small rituals — morning coffee, evening walks\n'
            '• Being distracted or postponing time together can feel like rejection\n\n'
            'Tip: Ask "What is one thing we could do together this week that would make you feel close to me?"',
      ),
      _LoveGuide(
        id: 'lg_receiving_gifts',
        title: 'Receiving Gifts',
        subtitle: 'Thoughtful tokens as symbols of love',
        emoji: '🎁',
        body:
            'For someone whose love language is Receiving Gifts, it is not about the price — it is about the thought and effort behind the gesture.\n\n'
            '• Remember small things they mention wanting\n'
            '• Celebrate anniversaries and milestones\n'
            '• Surprise them with something meaningful, not expensive\n'
            '• Handmade gifts often mean more than bought ones\n'
            '• Forgetting important occasions can feel devastating\n\n'
            'Tip: Keep a private note of things they mention in passing — that list becomes your gift guide.',
      ),
      _LoveGuide(
        id: 'lg_acts_service',
        title: 'Acts of Service',
        subtitle: 'Doing things to ease their load',
        emoji: '🛠️',
        body:
            'Acts of Service means showing love by lightening your partner\'s burden — actions speak louder than words.\n\n'
            '• Cook a meal when they are tired\n'
            '• Handle a task they have been dreading\n'
            '• Follow through on promises reliably\n'
            '• Notice what needs doing without being asked\n'
            '• Laziness or broken promises feel like a lack of love\n\n'
            'Tip: Ask "Is there something stressing you this week that I could take off your plate?"',
      ),
      _LoveGuide(
        id: 'lg_physical_touch',
        title: 'Physical Touch',
        subtitle: 'Connection through safe, intentional touch',
        emoji: '🤝',
        body:
            'Physical Touch is not just about physical intimacy — it is about physical presence and safety.\n\n'
            '• Hold hands, hug hello and goodbye\n'
            '• A pat on the back or shoulder says "I\'m here"\n'
            '• Sit close when watching a film together\n'
            '• Physical neglect or coldness feels deeply hurtful\n'
            '• Always prioritise consent and comfort\n\n'
            'Tip: Ask "What kind of physical affection makes you feel most loved and safe?"',
      ),
    ];

    for (final guide in loveLanguages) {
      results.add(
        ResourceItem(
          id: guide.id,
          title: guide.title,
          subtitle: guide.subtitle,
          type: ResourceType.guide,
          description: guide.body,
          emoji: guide.emoji,
          source: 'NuruAI Guide',
          loveSubcategory: 'love_languages',
        ),
      );
    }

    //Understanding Your Partner
    final understandPartner = [
      _LoveGuide(
        id: 'up_attachment_styles',
        title: 'Attachment Styles',
        subtitle: 'Why you and your partner respond differently',
        emoji: '🔗',
        body:
            'Attachment theory explains how early experiences shape how we behave in relationships.\n\n'
            '🟢 Secure — comfortable with closeness and independence\n'
            '🟡 Anxious — craves closeness, fears abandonment\n'
            '🔵 Avoidant — values independence, uncomfortable with deep intimacy\n'
            '🔴 Disorganised — mix of anxious and avoidant\n\n'
            'Understanding your own style — and your partner\'s — removes blame and replaces it with empathy.\n\n'
            'Tip: Neither style is wrong. Ask yourself: "When I feel anxious in this relationship, what am I really afraid of?"',
      ),
      _LoveGuide(
        id: 'up_active_listening',
        title: 'Active Listening',
        subtitle: 'Truly hearing your partner — not just waiting to speak',
        emoji: '👂',
        body:
            'Most relationship conflicts come from feeling unheard, not from actual disagreements.\n\n'
            'How to listen actively:\n'
            '• Reflect back — "So what I\'m hearing is…"\n'
            '• Ask clarifying questions — "Can you tell me more?"\n'
            '• Validate before responding — "That makes sense that you\'d feel that way"\n'
            '• Resist the urge to fix immediately\n'
            '• Put your phone down and make eye contact\n\n'
            'Tip: After a difficult conversation, ask "Did you feel heard by me just now?" Their answer will surprise you.',
      ),
      _LoveGuide(
        id: 'up_conflict_styles',
        title: 'Understanding Conflict Styles',
        subtitle: 'Why you fight the way you fight',
        emoji: '⚡',
        body:
            'People have different default conflict styles — neither is right or wrong, but clashes cause pain.\n\n'
            '🗣️ Confronter — wants to resolve it now, directly\n'
            '🚪 Avoider — needs space first, returns when calm\n'
            '🎭 Deflector — uses humour or subject changes\n'
            '📋 Processor — needs time to organise thoughts before speaking\n\n'
            'The key is not to change your style, but to agree on a "fight contract" — rules both of you set when things are calm.\n\n'
            'Tip: Agree that either of you can call a 20-minute time-out during arguments, then always come back.',
      ),
      _LoveGuide(
        id: 'up_emotional_bids',
        title: 'Emotional Bids',
        subtitle: 'The small moments that build or break connection',
        emoji: '🃏',
        body:
            'Relationship researcher Dr John Gottman found that couples make hundreds of small "bids for connection" daily — and how partners respond determines relationship health.\n\n'
            'A bid is any small attempt to connect:\n'
            '"Look at this funny video…"\n'
            '"I had such a weird day…"\n'
            '"Do you want tea?"\n\n'
            'You can:\n'
            '✅ Turn towards — engage, respond\n'
            '❌ Turn away — ignore or dismiss\n'
            '⚠️ Turn against — respond negatively\n\n'
            'Tip: Notice how often you turn towards your partner\'s bids today. That number predicts more than any argument.',
      ),
    ];

    for (final guide in understandPartner) {
      results.add(
        ResourceItem(
          id: guide.id,
          title: guide.title,
          subtitle: guide.subtitle,
          type: ResourceType.guide,
          description: guide.body,
          emoji: guide.emoji,
          source: 'NuruAI Guide',
          loveSubcategory: 'understand_partner',
        ),
      );
    }

    //Commitment & Staying Together
    final commitment = [
      _LoveGuide(
        id: 'cm_building_trust',
        title: 'Building & Rebuilding Trust',
        subtitle: 'The foundation every relationship needs',
        emoji: '🏛️',
        body:
            'Trust is built in small moments, not grand gestures. It is the sum of consistent, reliable behaviour over time.\n\n'
            'How to build trust:\n'
            '• Do what you say you will do — every time\n'
            '• Be transparent about your feelings and decisions\n'
            '• Honour your partner\'s vulnerabilities — never use them against them\n'
            '• Repair quickly after ruptures — a sincere apology followed by changed behaviour\n\n'
            'If trust has been broken:\n'
            '• Acknowledge the hurt fully without minimising\n'
            '• Allow your partner time to process\n'
            '• Show consistency over weeks and months, not just days\n\n'
            'Tip: "I\'m sorry you feel that way" is not an apology. "I\'m sorry I did that, I understand why it hurt you" is.',
      ),
      _LoveGuide(
        id: 'cm_intentional_dating',
        title: 'Staying in Date Mode',
        subtitle: 'Keeping novelty alive in long-term relationships',
        emoji: '🌟',
        body:
            'The early rush of love is neurologically temporary — but deep, enduring love is a choice and a practice.\n\n'
            'Keep the relationship alive:\n'
            '• Schedule regular date nights — protect them like meetings\n'
            '• Try new activities together — novelty triggers the same dopamine as early romance\n'
            '• Ask new questions — "What is something you\'ve always wanted to try?" keeps you discovering each other\n'
            '• Express gratitude for ordinary things\n'
            '• Celebrate small wins together\n\n'
            'Tip: The "36 Questions That Lead to Love" (developed by psychologist Arthur Aron) are a science-backed way to rebuild intimacy. Look them up and try them.',
      ),
      _LoveGuide(
        id: 'cm_shared_goals',
        title: 'Building a Shared Future',
        subtitle: 'Aligning your dreams and values',
        emoji: '🗺️',
        body:
            'Couples who stay together long-term tend to have a shared vision — not identical lives, but compatible directions.\n\n'
            'Questions to explore together:\n'
            '• Where do we want to be in 5 years?\n'
            '• What values are non-negotiable for both of us?\n'
            '• How do we want to handle finances, family, and personal ambition?\n'
            '• What does a good life look like to each of us?\n\n'
            'These conversations feel vulnerable — that is exactly why they build closeness.\n\n'
            'Tip: Create a "relationship vision board" together — visual, fun, and it surfaces differences early before they become conflicts.',
      ),
      _LoveGuide(
        id: 'cm_repair_after_conflict',
        title: 'Repairing After a Fight',
        subtitle: 'Coming back together stronger',
        emoji: '🩹',
        body:
            'Every couple fights. What separates lasting couples is not how rarely they fight, but how well they repair afterwards.\n\n'
            'The repair process:\n'
            '1. Cool down first — at least 20 minutes for physiological calm\n'
            '2. Take responsibility for your part — even if only 10%\n'
            '3. Listen to understand, not to rebut\n'
            '4. Express what you needed that you didn\'t get\n'
            '5. Agree on one small change each of you will make\n'
            '6. Re-connect physically — a hug signals "we are safe"\n\n'
            'Tip: Gottman\'s research shows that a 5:1 ratio of positive to negative interactions predicts relationship health. Every repair adds to that ratio.',
      ),
      _LoveGuide(
        id: 'cm_self_love_first',
        title: 'Self-Love as the Foundation',
        subtitle: 'You cannot pour from an empty cup',
        emoji: '💎',
        body:
            'Healthy relationships start with a healthy relationship with yourself. This is not selfishness — it is the prerequisite for genuine love.\n\n'
            'Practising self-love:\n'
            '• Know your own needs and communicate them clearly\n'
            '• Maintain friendships and interests outside the relationship\n'
            '• Set boundaries — not walls, but healthy limits\n'
            '• Speak to yourself with the same kindness you offer your partner\n'
            '• Recognise when you need support and ask for it\n\n'
            'Tip: "I deserve love" is not arrogance. Write it down. Say it to yourself. Notice the resistance — that resistance is where the work is.',
      ),
    ];

    for (final guide in commitment) {
      results.add(
        ResourceItem(
          id: guide.id,
          title: guide.title,
          subtitle: guide.subtitle,
          type: ResourceType.guide,
          description: guide.body,
          emoji: guide.emoji,
          source: 'NuruAI Guide',
          loveSubcategory: 'commitment',
        ),
      );
    }
  }

  Future<void> _fetchBooks(
    String query,
    List<ResourceItem> results, {
    int limit = 4,
  }) async {
    try {
      final uri = Uri.parse('$_openLibraryBase/search.json').replace(
        queryParameters: {
          'q': query,
          'fields': 'key,title,author_name,first_publish_year,cover_i,subject',
          'limit': '$limit',
        },
      );

      final response = await http
          .get(uri, headers: _jsonHeaders)
          .timeout(_timeout);

      _checkStatus(response, 'Open Library');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = (data['docs'] as List?) ?? [];

      for (final doc in docs) {
        final title = (doc['title'] as String?) ?? 'Untitled';
        final authors = ((doc['author_name'] as List?) ?? [])
            .take(2)
            .map((a) => a.toString())
            .join(', ');
        final year = doc['first_publish_year']?.toString() ?? '';
        final coverId = doc['cover_i'];
        final key = doc['key'] as String? ?? '';

        results.add(
          ResourceItem(
            id: 'book_${key.replaceAll('/', '_')}',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (year.isNotEmpty) year,
            ].join(' · '),
            type: ResourceType.book,
            author: authors.isNotEmpty ? authors : null,
            description: null, // Open Library search doesn't return description
            url: key.isNotEmpty ? '$_openLibraryBase$key' : null,
            coverUrl: coverId != null
                ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
                : null,
            emoji: '📖',
            source: 'Open Library',
          ),
        );
      }
    } catch (e) {
      // Swallow individual source failures
      _log('Open Library error: $e');
    }
  }

  Future<void> _fetchPoems(
    String author,
    List<ResourceItem> results, {
    int limit = 2,
  }) async {
    try {
      final encodedAuthor = Uri.encodeComponent(author);
      final uri = Uri.parse(
        '$_poetryDbBase/author/$encodedAuthor/title,lines,linecount,author',
      );

      final response = await http
          .get(uri, headers: _jsonHeaders)
          .timeout(_timeout);

      _checkStatus(response, 'PoetryDB');

      final body = response.body.trim();
      if (!body.startsWith('[')) return; // API returns object on not-found

      final poems = jsonDecode(body) as List;
      if (poems.isEmpty) return;

      // Sort by line count ascending
      poems.sort((a, b) {
        final la = int.tryParse(a['linecount']?.toString() ?? '9999') ?? 9999;
        final lb = int.tryParse(b['linecount']?.toString() ?? '9999') ?? 9999;
        return la.compareTo(lb);
      });

      for (final poem in poems.take(limit)) {
        final title = (poem['title'] as String?) ?? 'Untitled';
        final poemAuthor = (poem['author'] as String?) ?? author;
        final lines = ((poem['lines'] as List?) ?? [])
            .map((l) => l.toString())
            .toList();

        // Full poem text for the detail sheet
        final fullText = lines.join('\n');
        // Preview: first 4 lines
        final preview =
            lines.take(4).join('\n') + (lines.length > 4 ? '\n…' : '');

        results.add(
          ResourceItem(
            id: 'poem_${author}_$title'.replaceAll(' ', '_').toLowerCase(),
            title: title,
            subtitle: 'by $poemAuthor',
            type: ResourceType.poem,
            author: poemAuthor,
            description: fullText,
            url: null,
            emoji: '🌸',
            source: 'PoetryDB',
          ),
        );
      }
    } catch (e) {
      _log('PoetryDB error: $e');
    }
  }

  Future<void> _fetchWikiSummary(
    String pageTitle,
    List<ResourceItem> results,
  ) async {
    try {
      final slug = Uri.encodeComponent(pageTitle);
      final uri = Uri.parse('$_wikipediaBase/page/summary/$slug');

      final response = await http
          .get(uri, headers: _jsonHeaders)
          .timeout(_timeout);

      _checkStatus(response, 'Wikipedia');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final title = (data['title'] as String?) ?? pageTitle;
      final extract = (data['extract'] as String?) ?? '';
      if (extract.isEmpty) return;

      final pageUrl =
          (data['content_urls'] as Map?)?['desktop']?['page'] as String?;
      final thumbnail = (data['thumbnail'] as Map?)?['source'] as String?;

      // Short subtitle — first sentence of extract
      final firstSentence = extract.contains('.')
          ? extract.substring(0, extract.indexOf('.') + 1)
          : extract.substring(0, extract.length.clamp(0, 120));

      results.add(
        ResourceItem(
          id: 'wiki_${pageTitle.replaceAll(' ', '_').toLowerCase()}',
          title: title,
          subtitle: firstSentence,
          type: ResourceType.article,
          description: extract,
          url: pageUrl,
          coverUrl: thumbnail,
          emoji: '📰',
          source: 'Wikipedia',
        ),
      );
    } catch (e) {
      _log('Wikipedia error: $e');
    }
  }

  Future<void> _fetchPubMedArticles(
    String query,
    List<ResourceItem> results, {
    int limit = 3,
  }) async {
    try {
      // Step 1 — search for PMIDs
      final searchUri = Uri.parse('$_pubmedBase/esearch.fcgi').replace(
        queryParameters: {
          'db': 'pubmed',
          'term': '$query[Title/Abstract]',
          'retmax': '$limit',
          'retmode': 'json',
          'sort': 'relevance',
          // Filter: last 5 years, English, free full text preferred
          'datetype': 'pdat',
          'reldate': '1825', // ~5 years in days
        },
      );

      final searchResponse = await http
          .get(searchUri, headers: _jsonHeaders)
          .timeout(_timeout);

      _checkStatus(searchResponse, 'PubMed search');

      final searchData =
          jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final idList =
          ((searchData['esearchresult']?['idlist']) as List?)
              ?.map((id) => id.toString())
              .toList() ??
          [];

      if (idList.isEmpty) return;

      // Step 2 — fetch summaries for those PMIDs
      final summaryUri = Uri.parse('$_pubmedBase/esummary.fcgi').replace(
        queryParameters: {
          'db': 'pubmed',
          'id': idList.join(','),
          'retmode': 'json',
        },
      );

      final summaryResponse = await http
          .get(summaryUri, headers: _jsonHeaders)
          .timeout(_timeout);

      _checkStatus(summaryResponse, 'PubMed summary');

      final summaryData =
          jsonDecode(summaryResponse.body) as Map<String, dynamic>;
      final summaries = (summaryData['result'] as Map<String, dynamic>?) ?? {};

      for (final pmid in idList) {
        final article = summaries[pmid] as Map<String, dynamic>?;
        if (article == null) continue;

        final title = (article['title'] as String?) ?? 'Untitled';
        final authorList = (article['authors'] as List?) ?? [];
        final authors = authorList
            .take(3)
            .map((a) => (a as Map)['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');
        final pubDate = (article['pubdate'] as String?) ?? '';
        final source = (article['source'] as String?) ?? 'PubMed';

        results.add(
          ResourceItem(
            id: 'pubmed_$pmid',
            title: _cleanTitle(title),
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (pubDate.isNotEmpty) pubDate,
              source,
            ].join(' · '),
            type: ResourceType.research,
            author: authors.isNotEmpty ? authors : null,
            description:
                'Published in $source. View on PubMed for abstract and full text.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/$pmid/',
            emoji: '🔬',
            source: 'PubMed',
          ),
        );
      }
    } catch (e) {
      _log('PubMed error: $e');
    }
  }

  // Helpers

  void _checkStatus(http.Response response, String source) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ResourceServiceException(
        '$source returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// PubMed titles often end with a period — strip it
  String _cleanTitle(String title) {
    return title.endsWith('.') ? title.substring(0, title.length - 1) : title;
  }

  void _log(String message) {
    // Replace with your logger in production
    assert(() {
      print('[ResourceService] $message');
      return true;
    }());
  }
}

// Private helper: love guide data container

class _LoveGuide {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String body;

  const _LoveGuide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.body,
  });
}
