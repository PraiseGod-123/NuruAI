import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// ANGER MANAGEMENT SERVICE  v3
//
// DATA STRUCTURE:
//   Three distinct content types, each with its own source:
//
//   1. COPING TECHNIQUES  (subcategory = 'coping')
//      Source: Open Library — books on evidence-based techniques
//              PubMed — clinical studies on ASD anger interventions
//      These are real, usable, step-by-step techniques drawn from
//      clinical literature. No Wikipedia article summaries.
//      Each technique card includes:
//        • What it is (title + subtitle)
//        • How to do it right now (steps)
//        • Why it works (mechanism)
//        • Time to effect (actionLabel)
//
//   2. UNDERSTANDING ANGER (subcategory = 'understanding')
//      Source: NuruAI curated guides
//
//   3. COMMUNICATION       (subcategory = 'communication')
//      Source: NuruAI curated guides
//
// APIs used:
//   Open Library  — openlibrary.org/search.json
//   PubMed        — eutils.ncbi.nlm.nih.gov/entrez/eutils
// ══════════════════════════════════════════════════════════════

enum AngerResourceType { book, research, guide, technique }

class AngerResourceItem {
  final String id;
  final String title;
  final String subtitle;
  final AngerResourceType type;
  final String? author;
  final String? description; // full step-by-step content for techniques
  final String? url;
  final String? coverUrl;
  final String emoji;
  final String source;
  final String? subcategory; // 'coping' | 'understanding' | 'communication'
  final String? actionLabel; // e.g. "Works in 30 seconds"
  final String? mechanism; // why it works (science note)

  const AngerResourceItem({
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
    this.actionLabel,
    this.mechanism,
  });
}

class AngerServiceException implements Exception {
  final String message;
  final int? statusCode;
  const AngerServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'AngerServiceException: $message';
}

// ─────────────────────────────────────────────────────────────

class AngerManagementService {
  AngerManagementService._();
  static final AngerManagementService instance = AngerManagementService._();

  static const _openLibraryBase = 'https://openlibrary.org';
  static const _pubmedBase = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils';
  static const _timeout = Duration(seconds: 12);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NuruAI/1.0 (contact@nuruai.app)',
  };

  List<AngerResourceItem>? _cached;

  // ══════════════════════════════════════════════════════════
  // PUBLIC
  // ══════════════════════════════════════════════════════════

  Future<List<AngerResourceItem>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final results = <AngerResourceItem>[];

    // 1. NuruAI offline guides (understanding + communication)
    _injectGuides(results);

    // 2. Coping techniques — structured local data (clinically sourced)
    _injectCopingTechniques(results);

    // 3. Network: books + clinical research to supplement coping tab
    await Future.wait([
      _fetchBooks(
        'anger management autism spectrum coping strategies',
        results,
        limit: 4,
      ),
      _fetchBooks(
        'emotion regulation self help autistic adolescent',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'anger coping intervention autism spectrum disorder',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'emotion dysregulation de-escalation ASD adolescent',
        results,
        limit: 3,
      ),
      _fetchPubMed(
        'diaphragmatic breathing anger anxiety autism',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'progressive muscle relaxation autism emotional regulation',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'sensory based intervention anger ASD immediate',
        results,
        limit: 2,
      ),
      _fetchPubMed(
        'mindfulness anger regulation neurodevelopmental disorder',
        results,
        limit: 2,
      ),
    ]);

    // Deduplicate by title
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

  // ══════════════════════════════════════════════════════════
  // COPING TECHNIQUES
  //
  // 14 real, clinically-evidenced techniques.
  // Each one is drawn from:
  //   • CBT / DBT therapy manuals
  //   • Occupational therapy for ASD
  //   • Polyvagal theory (Stephen Porges)
  //   • Applied Behaviour Analysis (ABA)
  //   • Acceptance & Commitment Therapy (ACT)
  //   • Clinical neuroscience (Huberman, van der Kolk)
  //
  // Every technique has:
  //   - Exact steps to use RIGHT NOW
  //   - The physiological mechanism (why it works)
  //   - Time-to-effect label
  //   - ASD-specific adaptations where relevant
  // ══════════════════════════════════════════════════════════

  void _injectCopingTechniques(List<AngerResourceItem> results) {
    for (final t in _techniques) {
      results.add(t);
    }
  }

  static final List<AngerResourceItem> _techniques = [
    // ── 1. Physiological Sigh ─────────────────────────────
    AngerResourceItem(
      id: 'ct_physiological_sigh',
      title: 'Physiological Sigh',
      subtitle: 'Double inhale + long exhale — fastest nervous system reset',
      type: AngerResourceType.technique,
      emoji: '🌬️',
      source: 'Clinical Neuroscience',
      subcategory: 'coping',
      actionLabel: 'Works in 30 seconds',
      mechanism:
          'Activates parasympathetic nervous system via extended exhale. Researched by Dr Mark Krasnow & Dr Andrew Huberman, Stanford University.',
      description:
          'WHAT IT IS\n'
          'The single fastest way to lower physiological arousal — reduces heart rate measurably in under 30 seconds. Used in clinical settings for acute emotional dysregulation.\n\n'
          'DO THIS NOW\n'
          '1. Inhale fully through your nose (fill your lungs)\n'
          '2. Without exhaling — take one short extra sniff through your nose\n'
          '3. Exhale slowly and completely through your mouth (as long as possible)\n'
          '4. Repeat 2–3 times\n\n'
          'WHY IT WORKS\n'
          'The double inhale re-inflates collapsed alveoli in the lungs. The long exhale slows the heart directly — the exhale phase of breathing is controlled by the parasympathetic nervous system. Longer exhale = more calm, faster.\n\n'
          'FOR ASD\n'
          'No eye contact needed. Can be done silently. Works even mid-meltdown. Teach it when calm so the body remembers it under stress.\n\n'
          'WHEN TO USE IT\n'
          'The moment you notice your jaw tightening, fists clenching, or heart rate rising — before you\'ve lost control.',
    ),

    // ── 2. Box Breathing (4-4-4-4) ───────────────────────
    AngerResourceItem(
      id: 'ct_box_breathing',
      title: 'Box Breathing',
      subtitle: '4-4-4-4 breath pattern used by Navy SEALs and therapists',
      type: AngerResourceType.technique,
      emoji: '📦',
      source: 'CBT / Clinical Practice',
      subcategory: 'coping',
      actionLabel: 'Works in 90 seconds',
      mechanism:
          'Regulates CO₂ levels and activates the vagus nerve. Standard protocol in CBT for acute anxiety and anger.',
      description:
          'WHAT IT IS\n'
          'A controlled breathing pattern used by Navy SEALs, surgeons, and clinical therapists for acute stress. Clinically validated for anxiety and anger regulation.\n\n'
          'DO THIS NOW\n'
          '1. Breathe IN for 4 counts\n'
          '2. HOLD for 4 counts\n'
          '3. Breathe OUT for 4 counts\n'
          '4. HOLD for 4 counts\n'
          '5. Repeat for at least 4 full cycles (90 seconds)\n\n'
          'WHY IT WORKS\n'
          'The equal-ratio breathing balances CO₂ levels and prevents hyperventilation. The holds engage the vagus nerve — your body\'s main calming pathway. Consistent rhythm overrides the brain\'s threat response.\n\n'
          'FOR ASD\n'
          'You can trace a square with your finger on your leg or the wall — up one side for inhale, across for hold, down for exhale, across for hold. The visual-physical anchor makes it easier to stay regulated.\n\n'
          'WHEN TO USE IT\n'
          'When you are at Level 2–3 and need to stop escalation. Also useful before entering a stressful situation.',
    ),

    // ── 3. Progressive Muscle Relaxation ─────────────────
    AngerResourceItem(
      id: 'ct_pmr',
      title: 'Progressive Muscle Relaxation',
      subtitle:
          'Tense and release each muscle group to discharge anger physically',
      type: AngerResourceType.technique,
      emoji: '💪',
      source: 'Edmund Jacobson, 1929 — Standard CBT Protocol',
      subcategory: 'coping',
      actionLabel: 'Works in 3 minutes',
      mechanism:
          'Anger creates physical tension. PMR forces the body to release it systematically, signalling safety to the brain. Reduces cortisol and activates the parasympathetic response.',
      description:
          'WHAT IT IS\n'
          'Developed by physician Edmund Jacobson in 1929. Now a standard CBT and OT tool for anger, anxiety, and ASD emotional dysregulation. Works by physically discharging the tension that anger creates in the body.\n\n'
          'DO THIS NOW\n'
          '1. Sit or lie down in a comfortable position\n'
          '2. Start with your hands — squeeze your fists as tight as you can for 5 seconds\n'
          '3. Release completely — feel the difference\n'
          '4. Move up: arms, shoulders (raise to ears, hold, drop)\n'
          '5. Face: scrunch everything tight, then release\n'
          '6. Stomach: pull in tight, hold, release\n'
          '7. Legs: push heels into the floor, hold, release\n'
          '8. Breathe slowly throughout\n\n'
          'WHY IT WORKS\n'
          'Anger floods muscles with tension ready for fighting. PMR gives that tension a physical outlet, then deliberately releases it. The contrast between tension and release signals the nervous system to switch to rest mode.\n\n'
          'FOR ASD\n'
          'The strong physical sensation is often easier to focus on than abstract breathing instructions. Many autistic individuals find the pressure and release satisfying and grounding.\n\n'
          'WHEN TO USE IT\n'
          'When you are too agitated to just "breathe" — when your body needs a physical outlet.',
    ),

    // ── 4. Cold Water Face Immersion (Dive Reflex) ───────
    AngerResourceItem(
      id: 'ct_dive_reflex',
      title: 'Cold Water Face Immersion',
      subtitle: 'Triggers the mammalian dive reflex — forces the heart to slow',
      type: AngerResourceType.technique,
      emoji: '🧊',
      source: 'DBT (Marsha Linehan) — TIPP Skills',
      subcategory: 'coping',
      actionLabel: 'Works in 30 seconds',
      mechanism:
          'Activates the mammalian dive reflex via trigeminal nerve stimulation, directly reducing heart rate by 10–25%. A core DBT skill (Temperature).',
      description:
          'WHAT IT IS\n'
          'A core Dialectical Behaviour Therapy (DBT) skill developed by Dr Marsha Linehan. Part of the TIPP protocol (Temperature, Intense exercise, Paced breathing, Paired relaxation). One of the fastest physiological interventions known.\n\n'
          'DO THIS NOW\n'
          'Option A (strongest): Fill a bowl or sink with cold water. Hold your breath. Dip your face in for 30 seconds.\n'
          'Option B: Splash cold water on your face and wrists repeatedly\n'
          'Option C: Hold an ice pack or bag of frozen peas to your face\n'
          'Option D: Drink a glass of very cold water quickly\n\n'
          'WHY IT WORKS\n'
          'Cold water on the face triggers the mammalian dive reflex — a hardwired biological response that immediately slows the heart rate. This directly counters the high-arousal state of anger. It bypasses thoughts completely — you do not need to "think calm," the body forces it.\n\n'
          'FOR ASD\n'
          'Many autistic individuals are sensitive to temperature. If cold is distressing, use cool (not freezing) water. Even cool water on wrists and the back of the neck is effective. This technique requires no communication — ideal during a meltdown.\n\n'
          'WHEN TO USE IT\n'
          'Level 3–5. When you are already very angry and need to physically force your body down.',
    ),

    // ── 5. Intense Physical Exercise (Discharge) ─────────
    AngerResourceItem(
      id: 'ct_intense_exercise',
      title: 'Intense Physical Discharge',
      subtitle: 'Use your body to burn off the adrenaline anger produces',
      type: AngerResourceType.technique,
      emoji: '🏃',
      source: 'DBT TIPP Skills / Exercise Science',
      subcategory: 'coping',
      actionLabel: 'Works in 5 minutes',
      mechanism:
          'Anger produces adrenaline and cortisol. Intense exercise metabolises these chemicals physically, restoring hormonal baseline. Also releases endorphins.',
      description:
          'WHAT IT IS\n'
          'Another core DBT TIPP skill (Intense exercise). Anger is a biological preparation for physical action. When that action doesn\'t happen, the chemical load remains in your body. Exercise is the physiologically correct response to that chemical state.\n\n'
          'DO THIS NOW\n'
          'Choose ONE for 5 minutes:\n'
          '• Sprint as fast as you can (outside or on the spot)\n'
          '• Do jumping jacks until you are out of breath\n'
          '• Do press-ups or squats as fast as you can\n'
          '• Jump on a trampoline (if available)\n'
          '• Punch a pillow or mattress (not a person or wall)\n'
          '• Dance intensely to loud music\n'
          '• Climb stairs repeatedly\n\n'
          'WHY IT WORKS\n'
          'Adrenaline and cortisol are designed to fuel physical action. Exercise metabolises them directly. After 5 minutes of intense movement, your hormonal baseline drops measurably. Endorphins released during exercise also create a natural calm state.\n\n'
          'FOR ASD\n'
          'Jumping is a common and effective stim that doubles as anger discharge. Trampolines are used in OT for exactly this reason. Heavy work activities (push-ups, carrying heavy objects) also provide proprioceptive input that regulates the nervous system.\n\n'
          'WHEN TO USE IT\n'
          'When you feel the physical urge to do something — to hit, throw, or run. Channel that urge here.',
    ),

    // ── 6. 5-4-3-2-1 Sensory Grounding ──────────────────
    AngerResourceItem(
      id: 'ct_54321_grounding',
      title: '5-4-3-2-1 Sensory Grounding',
      subtitle:
          'Forces your brain out of the anger loop and back into the present',
      type: AngerResourceType.technique,
      emoji: '🌱',
      source: 'CBT / Trauma Therapy',
      subcategory: 'coping',
      actionLabel: 'Works in 2 minutes',
      mechanism:
          'Redirects prefrontal cortex attention to present sensory data, interrupting the amygdala\'s threat loop. Used in PTSD and trauma treatment.',
      description:
          'WHAT IT IS\n'
          'A grounding technique from CBT and trauma therapy. Anger keeps the brain locked in a threat loop. This technique forcibly redirects your brain\'s attention to real-time sensory input, breaking the loop.\n\n'
          'DO THIS NOW\n'
          'Name these out loud or in your head:\n'
          '5 things you can SEE right now\n'
          '4 things you can physically TOUCH (actually touch them)\n'
          '3 things you can HEAR right now\n'
          '2 things you can SMELL (or remember smelling)\n'
          '1 thing you can TASTE\n\n'
          'Go slowly. Do not rush. The slower you go, the more effective.\n\n'
          'WHY IT WORKS\n'
          'The prefrontal cortex (rational thinking) and amygdala (threat/anger) compete for brain resources. By engaging the PFC with specific sensory tasks, you reduce amygdala activity. Saying things out loud activates language processing, which anger suppresses.\n\n'
          'FOR ASD\n'
          'Sensory awareness is often heightened in ASD — this technique plays to that strength. The structured numbered format is predictable and clear. It is also silent-capable: do it in your head if speaking feels hard.\n\n'
          'WHEN TO USE IT\n'
          'Level 2–3. Especially useful during sensory overload when you need to find your footing.',
    ),

    // ── 7. Cold Shower / Water Exposure ──────────────────
    AngerResourceItem(
      id: 'ct_cold_shower',
      title: 'Cold Shower Exposure',
      subtitle: 'Brief cold water on the body resets the entire nervous system',
      type: AngerResourceType.technique,
      emoji: '🚿',
      source: 'Polyvagal Theory / Clinical Neuroscience',
      subcategory: 'coping',
      actionLabel: 'Works in 2 minutes',
      mechanism:
          'Cold water activates the vagus nerve and triggers a catecholamine release that paradoxically calms the anger response after the initial shock passes.',
      description:
          'WHAT IT IS\n'
          'Used in clinical programmes for emotional dysregulation. Brief cold water exposure resets the autonomic nervous system through vagal nerve stimulation. More powerful than face immersion when the body is highly activated.\n\n'
          'DO THIS NOW\n'
          '1. Go to the shower\n'
          '2. Turn the water to cool or cold (not dangerously cold — uncomfortably cool is enough)\n'
          '3. Step in and let it hit your neck, back, and chest\n'
          '4. Stay for 60–90 seconds\n'
          '5. Focus on your breathing while under the water\n'
          '6. Step out slowly\n\n'
          'WHY IT WORKS\n'
          'Cold water triggers a sharp sympathetic nervous system response, followed by a strong parasympathetic rebound — the body overcorrects toward calm. Noradrenaline (norepinephrine) is released, which increases focus and reduces emotional flooding. After the initial 20 seconds, most people report a clear-headed calm.\n\n'
          'FOR ASD\n'
          'If cold is sensory-distressing, use lukewarm water and focus on the pressure of the water rather than the temperature. The ritual of getting to the shower also provides a safe exit from the triggering situation.\n\n'
          'WHEN TO USE IT\n'
          'When you are at Level 3–4 and have access to a shower. Also useful as a daily morning reset to lower your baseline reactivity.',
    ),

    // ── 8. Weighted Blanket / Deep Pressure ──────────────
    AngerResourceItem(
      id: 'ct_deep_pressure',
      title: 'Deep Pressure Stimulation',
      subtitle: 'Firm pressure on the body calms the nervous system rapidly',
      type: AngerResourceType.technique,
      emoji: '🫂',
      source: 'Occupational Therapy for ASD — Jean Ayres, Sensory Integration',
      subcategory: 'coping',
      actionLabel: 'Works in 3 minutes',
      mechanism:
          'Activates the parasympathetic nervous system via mechanoreceptors in the skin. Reduces cortisol and increases serotonin. Core OT strategy for ASD sensory regulation.',
      description:
          'WHAT IT IS\n'
          'Developed through Sensory Integration Therapy by OT pioneer Jean Ayres. Deep pressure stimulation (DPS) is one of the most well-researched non-pharmacological calming interventions for ASD. It works by activating specific sensory receptors that signal safety to the brain.\n\n'
          'DO THIS NOW\n'
          'Options (choose what is available):\n'
          '• Wrap yourself tightly in a heavy blanket\n'
          '• Use a weighted blanket (5–15% of body weight is the clinical recommendation)\n'
          '• Put on tight-fitting clothing or compression garment\n'
          '• Cross your arms and squeeze yourself firmly\n'
          '• Lie face-down with a heavy pillow on your back\n'
          '• Ask someone you trust for a firm, sustained hug (10+ seconds)\n'
          '• Use a body pillow and squeeze it from both sides\n\n'
          'WHY IT WORKS\n'
          'Firm pressure on the body activates mechanoreceptors (Meissner\'s and Pacinian corpuscles) that send direct signals to the parasympathetic nervous system. Cortisol drops. Serotonin and oxytocin increase. This is why animals and humans instinctively curl up when distressed.\n\n'
          'FOR ASD\n'
          'This technique was specifically developed for autistic sensory regulation. It does not require language, eye contact, or cognitive effort. It works at Level 4–5 when thinking is impossible. Many autistic individuals already use pressure instinctively.\n\n'
          'WHEN TO USE IT\n'
          'During or approaching a meltdown. Also as a daily sensory diet tool to prevent escalation.',
    ),

    // ── 9. Tapping (EFT) ─────────────────────────────────
    AngerResourceItem(
      id: 'ct_eft_tapping',
      title: 'EFT Tapping',
      subtitle: 'Tap acupressure points while naming the emotion — 2 minutes',
      type: AngerResourceType.technique,
      emoji: '✋',
      source: 'Emotional Freedom Techniques (EFT) — Feinstein, Craig',
      subcategory: 'coping',
      actionLabel: 'Works in 2 minutes',
      mechanism:
          'Tapping on meridian endpoints sends calming signals to the amygdala, reducing the stress response. Backed by over 100 clinical studies including randomised controlled trials.',
      description:
          'WHAT IT IS\n'
          'EFT (Emotional Freedom Techniques) was developed by Gary Craig and has been validated in over 100 clinical trials including RCTs. It is used in veteran PTSD treatment, anxiety clinics, and increasingly in ASD emotional regulation programmes. It combines cognitive exposure (naming the emotion) with somatic stimulation (tapping on acupressure points).\n\n'
          'DO THIS NOW — Basic Protocol\n'
          '1. Rate your anger 0–10 right now\n'
          '2. Tap the KARATE CHOP point (fleshy side of your hand) and say:\n'
          '   "Even though I feel this anger, I accept myself"\n'
          '   Repeat 3 times\n'
          '3. Now tap each point 5–7 times while saying "this anger":\n'
          '   • Top of head\n'
          '   • Eyebrow (inner edge)\n'
          '   • Side of eye\n'
          '   • Under eye (on cheekbone)\n'
          '   • Under nose\n'
          '   • Chin crease\n'
          '   • Collarbone (just below and inward)\n'
          '   • Under arm (bra strap line)\n'
          '4. Take a deep breath\n'
          '5. Rate your anger again — it typically drops 2–4 points\n\n'
          'WHY IT WORKS\n'
          'Research shows tapping on these points sends calming electrical signals to the amygdala, reducing cortisol. The verbal naming activates the prefrontal cortex simultaneously, creating a dual-processing effect that de-conditions the emotional response.\n\n'
          'FOR ASD\n'
          'The structured, repetitive physical action is predictable and patterned — well-suited to ASD. The self-touch is controlled and comfortable. It can be done silently and in public without anyone noticing.',
    ),

    // ── 10. STOP Skill (DBT) ─────────────────────────────
    AngerResourceItem(
      id: 'ct_stop_skill',
      title: 'The STOP Skill',
      subtitle: 'DBT\'s 4-step emergency brake for emotional explosions',
      type: AngerResourceType.technique,
      emoji: '🛑',
      source: 'Dialectical Behaviour Therapy (DBT) — Marsha Linehan',
      subcategory: 'coping',
      actionLabel: 'Works immediately',
      mechanism:
          'A structured behavioural interrupt that creates a pause between stimulus and response. Prevents automatic reactive behaviour by inserting conscious steps.',
      description:
          'WHAT IT IS\n'
          'A core skill from Dialectical Behaviour Therapy (DBT), developed by Dr Marsha Linehan at the University of Washington. DBT is one of the most clinically validated therapies for emotional dysregulation. The STOP skill is the emergency brake.\n\n'
          'DO THIS NOW\n'
          'S — STOP\n'
          '   Freeze. Do not move. Do not speak. Do not act. Just stop.\n\n'
          'T — TAKE A STEP BACK\n'
          '   Physically step back if you can. Take a breath. Create distance.\n'
          '   You are not leaving — you are pausing.\n\n'
          'O — OBSERVE\n'
          '   Notice what is happening. What did you just feel?\n'
          '   What is the situation? What does your body feel like right now?\n'
          '   Do not judge. Just observe.\n\n'
          'P — PROCEED MINDFULLY\n'
          '   Ask: "What is the most effective thing I can do right now?"\n'
          '   Not the most satisfying. Not the most fair. The most effective.\n'
          '   Then do that.\n\n'
          'WHY IT WORKS\n'
          'The gap between a trigger and your response is where your power lives. The STOP skill creates that gap when the brain is trying to skip it entirely. Observation activates the prefrontal cortex, which anger suppresses.\n\n'
          'FOR ASD\n'
          'The acronym provides a clear, memorisable structure. Practise saying "STOP" quietly to yourself as a cue. The predictable steps reduce cognitive load in a moment of high arousal.',
    ),

    // ── 11. Vagus Nerve Humming ───────────────────────────
    AngerResourceItem(
      id: 'ct_humming',
      title: 'Vagal Humming',
      subtitle: 'Hum or sing to directly activate the vagus nerve',
      type: AngerResourceType.technique,
      emoji: '🎵',
      source: 'Polyvagal Theory — Dr Stephen Porges',
      subcategory: 'coping',
      actionLabel: 'Works in 60 seconds',
      mechanism:
          'The vagus nerve runs through the larynx. Humming, chanting, or singing creates vibration that directly stimulates the vagus nerve, activating the parasympathetic nervous system.',
      description:
          'WHAT IT IS\n'
          'Based on Polyvagal Theory developed by neuroscientist Dr Stephen Porges. The vagus nerve — your main parasympathetic nerve — runs through the larynx (voice box). Any vibration in the throat directly stimulates it. Used in somatic therapy, trauma treatment, and OT for ASD.\n\n'
          'DO THIS NOW\n'
          'Option A — Simple hum:\n'
          '1. Close your lips\n'
          '2. Take a full breath\n'
          '3. Hum on your exhale for as long as you can\n'
          '4. Feel the vibration in your throat and chest\n'
          '5. Repeat 5–10 times\n\n'
          'Option B — Extended hum:\n'
          'Hum a low, steady note. Place your hand on your chest and feel the vibration.\n\n'
          'Option C — Sing or chant:\n'
          'Any singing activates the same mechanism. Put on a favourite song and sing along — even quietly.\n\n'
          'WHY IT WORKS\n'
          'The vagus nerve innervates the vocal cords. Vibration in the throat sends direct parasympathetic signals to the heart, lungs, and gut, reducing the physiological markers of anger within 60–90 seconds.\n\n'
          'FOR ASD\n'
          'Many autistic individuals already hum as a stim — this is intuitively self-regulating. If you stim by humming, you are already doing this. You can also hum a favourite song or theme song — the familiar melody adds additional emotional regulation through the limbic system.',
    ),

    // ── 12. Proprioceptive Heavy Work ────────────────────
    AngerResourceItem(
      id: 'ct_heavy_work',
      title: 'Proprioceptive Heavy Work',
      subtitle:
          'Push, pull, carry — heavy physical work grounds the nervous system',
      type: AngerResourceType.technique,
      emoji: '🏋️',
      source: 'Occupational Therapy — Sensory Processing & ASD',
      subcategory: 'coping',
      actionLabel: 'Works in 3 minutes',
      mechanism:
          'Heavy resistance input to joints and muscles activates proprioceptors, which send organising signals to the nervous system. Clinically used in ASD sensory diets to regulate emotional state.',
      description:
          'WHAT IT IS\n'
          'A core Occupational Therapy strategy used in ASD sensory diets. Proprioception — your sense of your body\'s position and effort — has a uniquely calming effect on the nervous system. Heavy work activates it powerfully.\n\n'
          'DO THIS NOW\n'
          'Choose any of these:\n'
          '• Push against a wall with full strength for 30 seconds (don\'t move — just push)\n'
          '• Do 10–20 slow press-ups (feel the weight and resistance)\n'
          '• Carry something heavy (bag of shopping, a box) around the room\n'
          '• Lift weights slowly if available\n'
          '• Do slow, heavy squats\n'
          '• Pull a heavy piece of furniture (carefully)\n'
          '• Crawl on hands and knees (this provides joint compression throughout)\n'
          '• Chew something tough — gum, a carrot, a bread crust\n\n'
          'WHY IT WORKS\n'
          'Heavy work activates mechanoreceptors in joints and muscles (Golgi tendon organs and muscle spindles). These send signals to the reticular formation in the brainstem, which has a direct organising and calming effect on arousal levels. This is why OTs prescribe physical work in sensory diets.\n\n'
          'FOR ASD\n'
          'This technique was developed for autistic individuals specifically. Many autistic people instinctively seek heavy input when dysregulated — rocking, pressing on things, wearing heavy clothing. This technique consciously channels that same instinct.\n\n'
          'WHEN TO USE IT\n'
          'When you feel agitated, restless, or on the edge. Also as a daily morning and evening regulating activity.',
    ),

    // ── 13. TIPP Temperature Skill (DBT) ─────────────────
    AngerResourceItem(
      id: 'ct_tipp',
      title: 'TIPP — Temperature Skill',
      subtitle: 'Change your body temperature to change your emotional state',
      type: AngerResourceType.technique,
      emoji: '🌡️',
      source: 'DBT Crisis Survival Skills — Marsha Linehan',
      subcategory: 'coping',
      actionLabel: 'Works in 60 seconds',
      mechanism:
          'Temperature change directly alters physiological arousal by activating or suppressing the autonomic nervous system. Cold = parasympathetic activation. Heat = muscular relaxation.',
      description:
          'WHAT IT IS\n'
          'The T in DBT\'s TIPP skills (Temperature, Intense exercise, Paced breathing, Paired relaxation). TIPP skills are specifically designed for emotional crisis moments — when standard coping is not enough.\n\n'
          'DO THIS NOW\n'
          'FOR INTENSE ANGER (cool it down):\n'
          '• Splash cold water on your face, wrists, and back of neck\n'
          '• Hold a cold can or ice pack to your face\n'
          '• Step outside if it is cooler than where you are\n'
          '• Drink cold water slowly\n\n'
          'FOR ANXIETY-DRIVEN ANGER (warm it up):\n'
          '• Wrap hands around a warm mug\n'
          '• Take a warm shower or bath\n'
          '• Use a heat pack on your neck or chest\n\n'
          'WHY IT WORKS\n'
          'Body temperature is directly linked to autonomic nervous system state. Cold on the face activates the dive reflex and parasympathetic nervous system. Warmth relaxes muscles and reduces the physiological preparation for fight-or-flight.\n\n'
          'FOR ASD\n'
          'Temperature change is a concrete, sensory-focused intervention that does not require abstract thinking. Many autistic individuals are already sensitive to temperature — this technique uses that sensitivity as a tool.\n\n'
          'WHEN TO USE IT\n'
          'Level 3–5 situations. Any time thinking your way calm is not working.',
    ),

    // ── 14. Safe Space Exit (Sensory Retreat) ────────────
    AngerResourceItem(
      id: 'ct_sensory_retreat',
      title: 'Planned Sensory Retreat',
      subtitle:
          'A designated safe space that you leave to before losing control',
      type: AngerResourceType.technique,
      emoji: '🚪',
      source: 'ABA + Occupational Therapy for ASD',
      subcategory: 'coping',
      actionLabel: 'Works in 5 minutes',
      mechanism:
          'Removing sensory and social triggers stops the escalation cycle. A familiar, low-stimulation environment allows the nervous system to return to baseline without competing demands.',
      description:
          'WHAT IT IS\n'
          'Used in both Applied Behaviour Analysis (ABA) and Occupational Therapy for ASD. A sensory retreat is a pre-planned, low-stimulation space that you use proactively — before losing control — as a regulatory tool.\n\n'
          'THIS REQUIRES PREPARATION (do this now, not during a crisis)\n'
          'Choose your retreat space:\n'
          '• A quiet bedroom or corner\n'
          '• A wardrobe or small enclosed space (many autistic individuals prefer enclosed spaces)\n'
          '• A place with dim lighting and low noise\n'
          '• Somewhere familiar and predictable\n\n'
          'Equip it with regulatory items:\n'
          '• Weighted blanket or heavy throw\n'
          '• Noise-cancelling headphones\n'
          '• Sensory toys, fidgets, or stim items\n'
          '• A favourite smell (candle, essential oil)\n'
          '• A favourite object\n\n'
          'Agree a signal with people around you:\n'
          'Choose a word or gesture that means "I am going to my space. I will come back in [X] minutes." Practise it when calm.\n\n'
          'DURING A CRISIS\n'
          'Go to your space before you reach Level 4. Stay until you feel Level 2 or below. Do not re-enter the situation until you are regulated.\n\n'
          'WHY IT WORKS\n'
          'Sensory and social inputs drive escalation. Removing them stops the escalation cycle. A familiar environment sends safety signals to the nervous system. The planned nature means others understand and do not escalate further.\n\n'
          'FOR ASD\n'
          'This technique was designed for autistic individuals. The structure, predictability, and sensory control are all specifically ASD-adapted. It is used in schools, workplaces, and homes.',
    ),
  ]; // end _techniques

  // ══════════════════════════════════════════════════════════
  // NURURAI GUIDES — understanding + communication only
  // ══════════════════════════════════════════════════════════

  void _injectGuides(List<AngerResourceItem> results) {
    for (final g in _understanding) {
      results.add(
        AngerResourceItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: AngerResourceType.guide,
          description: g.body,
          emoji: g.emoji,
          source: 'NuruAI Guide',
          subcategory: 'understanding',
        ),
      );
    }
    for (final g in _communication) {
      results.add(
        AngerResourceItem(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          type: AngerResourceType.guide,
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
      id: 'ua_what_is_anger',
      title: 'What Is Anger?',
      subtitle: 'Understanding the emotion before managing it',
      emoji: '🔥',
      body:
          'Anger is a completely normal, healthy human emotion. It is your brain\'s alarm system telling you something feels unfair, threatening, or out of your control.\n\n'
          'What happens in your body:\n'
          '• Heart rate and blood pressure rise\n'
          '• Muscles tense — jaw, shoulders, fists\n'
          '• Adrenaline floods your system\n'
          '• Rational thinking temporarily shuts down\n\n'
          'For people with ASD or ADHD, this response arrives faster, feels more intense, and is harder to come down from. This is neurology, not a character flaw.\n\n'
          'Key insight: Anger is not the problem. How you express it — and how quickly you return to calm — is what matters.',
    ),
    _G(
      id: 'ua_triggers',
      title: 'Knowing Your Triggers',
      subtitle: 'What sets off your anger — and why',
      emoji: '⚡',
      body:
          'A trigger is any situation, person, sound, or feeling that activates your anger response. Once you know yours, you have power over them.\n\n'
          'Common triggers for ASD and ADHD:\n'
          '• Unexpected changes to routines or plans\n'
          '• Sensory overload — loud noise, crowds, bright lights\n'
          '• Feeling misunderstood or unheard\n'
          '• Injustice — things that are unfair or break rules\n'
          '• Frustration when a task is not going as expected\n'
          '• Feeling rushed, overwhelmed, or interrupted\n\n'
          'Exercise — Anger Log:\n'
          'For one week, write down every time you feel angry:\n'
          '1. What happened just before?\n'
          '2. Where were you? Who was there?\n'
          '3. How did your body feel?\n\n'
          'Patterns will emerge. Those patterns are your triggers.',
    ),
    _G(
      id: 'ua_spectrum',
      title: 'The Anger Spectrum',
      subtitle: 'From irritation to rage — reading your own levels',
      emoji: '📊',
      body:
          '😤 Level 1 — Irritated: Slightly annoyed, can still function\n'
          '😠 Level 2 — Frustrated: Hard to focus, starting to snap\n'
          '😡 Level 3 — Angry: Heart racing, voice raised, less rational\n'
          '🤬 Level 4 — Furious: Overwhelming, hard to think clearly\n'
          '💥 Level 5 — Explosive: Full loss of control\n\n'
          'The goal is to catch yourself at Level 1–2 and use tools before reaching 4–5.\n\n'
          'Right now, assign a number to how you feel. Just naming the level reduces its intensity.',
    ),
    _G(
      id: 'ua_asd',
      title: 'Anger and Neurodivergence',
      subtitle: 'Why anger feels different with ASD and ADHD',
      emoji: '🧠',
      body:
          'If you have ASD or ADHD, anger can feel more intense, arrive faster, and be harder to de-escalate. Research backs this up.\n\n'
          '• Interoception differences — harder to notice early body signals\n'
          '• Executive function gaps — harder to pause before reacting\n'
          '• Emotional dysregulation — the brain\'s braking system is less efficient\n'
          '• Rejection Sensitive Dysphoria (ADHD) — perceived rejection triggers intense pain\n'
          '• Higher baseline sensory load — the nervous system is already carrying more\n\n'
          'Standard advice like "just count to ten" is often not enough. You need strategies built for how your brain actually works.',
    ),
  ];

  static const _communication = [
    _G(
      id: 'cc_i_statements',
      title: 'I-Statements',
      subtitle: 'Express anger without triggering defensiveness',
      emoji: '💬',
      body:
          'The formula: "I feel [emotion] when [situation] because [impact]."\n\n'
          '❌ "You always ignore what I say."\n'
          '✅ "I feel dismissed when I share something and the conversation moves on."\n\n'
          '❌ "You made me angry."\n'
          '✅ "I felt angry when the plan changed without telling me, because I had prepared for something specific."\n\n'
          'I-statements communicate emotion without blame. Practise writing them after an argument before trying them live.',
    ),
    _G(
      id: 'cc_repair',
      title: 'Repairing After Anger',
      subtitle: 'What to do after you have lost your temper',
      emoji: '🩹',
      body:
          '1. Wait until genuinely calm — not just quiet\n'
          '2. Take responsibility: "I raised my voice. I said something hurtful."\n'
          '3. Acknowledge the impact: "I understand that felt frightening."\n'
          '4. Share what you were actually feeling: "I was overwhelmed, not just angry."\n'
          '5. Ask what would help them\n\n'
          '"I\'m sorry you felt that way" is not an apology.\n\n'
          'A genuine repair builds more trust than if the incident had never happened.',
    ),
    _G(
      id: 'cc_asking_space',
      title: 'Asking for Space Clearly',
      subtitle: 'How to pause a conversation without abandoning it',
      emoji: '⏸️',
      body:
          'The script:\n'
          '"I am starting to feel overwhelmed. I need [time] to calm down. This matters to me and I will come back at [specific time]."\n\n'
          'Example: "I need 30 minutes. I\'ll come back at 7pm."\n\n'
          'You must come back when you said you would.\n\n'
          'This keeps you from exploding and keeps the relationship from breaking.',
    ),
    _G(
      id: 'cc_limits',
      title: 'Setting Limits Under Anger',
      subtitle: 'Boundaries that protect without escalating',
      emoji: '🛑',
      body:
          'Effective limits state what YOU will do — not what the other person must stop.\n\n'
          '❌ "Stop doing that or I\'m leaving"\n'
          '✅ "I need this conversation to pause. I will come back to it."\n'
          '✅ "When the volume rises, I can\'t process what you\'re saying. Can we lower the temperature?"\n\n'
          'You control your behaviour. Not theirs.',
    ),
  ];

  // ══════════════════════════════════════════════════════════
  // OPEN LIBRARY
  // ══════════════════════════════════════════════════════════

  Future<void> _fetchBooks(
    String query,
    List<AngerResourceItem> out, {
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
          AngerResourceItem(
            id: 'book_${key.replaceAll('/', '_')}',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (year.isNotEmpty) year,
            ].join(' · '),
            type: AngerResourceType.book,
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

  // ══════════════════════════════════════════════════════════
  // PUBMED
  // ══════════════════════════════════════════════════════════

  Future<void> _fetchPubMed(
    String query,
    List<AngerResourceItem> out, {
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
      final summaries =
          (jsonDecode(summRes.body)['result'] as Map<String, dynamic>?) ?? {};

      for (final pmid in ids) {
        final a = summaries[pmid] as Map<String, dynamic>?;
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
          AngerResourceItem(
            id: 'pubmed_$pmid',
            title: title,
            subtitle: [
              if (authors.isNotEmpty) authors,
              if (date.isNotEmpty) date,
              journal,
            ].join(' · '),
            type: AngerResourceType.research,
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
      throw AngerServiceException(
        '$src returned ${r.statusCode}',
        statusCode: r.statusCode,
      );
    }
  }

  String _clean(String t) => t.endsWith('.') ? t.substring(0, t.length - 1) : t;
  void _log(String m) {
    assert(() {
      print('[AngerManagementService] $m');
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
