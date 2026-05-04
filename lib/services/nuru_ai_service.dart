import 'dart:convert';
import 'package:http/http.dart' as http;

// NURU AI SERVICE — Groq API
//
// Model: llama-3.3-70b-versatile (fast, free tier available)
// Docs:  https://console.groq.com/docs/openai

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class NuruAIService {
  NuruAIService._();
  static final NuruAIService instance = NuruAIService._();

  String apiKey = '';
  bool get _configured => apiKey.trim().isNotEmpty;

  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';
  static const _timeout = Duration(seconds: 30);

  static const String _systemPrompt =
      'You are NuruAI, a warm, caring and knowledgeable AI companion inside the NuruAI app. '
      'NuruAI is designed for autistic individuals aged 13 to 25 with ASD Level 1. '
      'You are like a trusted, understanding older friend — not a therapist, not a robot. '
      'You help users with a wide range of everyday topics including: '
      'emotions and how to manage them, relationships and friendships, crushes and romantic feelings, '
      'social situations that feel confusing or overwhelming, school or college stress, '
      'family conflicts, loneliness, self-confidence, identity, '
      'sensory challenges, meltdowns and shutdowns, anxiety and worry, '
      'communication difficulties, making and keeping friends, '
      'understanding other people\'s behaviour and intentions, '
      'coping with change or unexpected events, and daily life challenges. '
      'When a user is struggling, always offer practical coping mechanisms suited to their situation. '
      'Examples include: breathing exercises, grounding techniques (5-4-3-2-1 senses), '
      'journaling prompts, taking a sensory break, movement or physical activity, '
      'listening to calming music, using a comfort object, stepping away from a situation temporarily, '
      'writing down thoughts, talking to someone they trust, or acknowledging their feelings out loud. '
      'Always explain the coping mechanism briefly and warmly — never make it feel like a chore. '
      'When users talk about crushes, relationships, or romantic feelings — engage warmly and helpfully. '
      'Help them understand their own feelings, think through situations, and navigate social interactions. '
      'Give practical, age-appropriate advice about communicating feelings, reading social cues, '
      'understanding boundaries, and handling rejection or uncertainty with self-respect. '
      'Do not shut down these conversations — they are a normal and important part of growing up. '
      'How you must communicate: '
      'Always use short clear sentences. Never write long paragraphs. '
      'Never use bullet points, numbered lists, or headers. '
      'Use warm, simple language — never clinical or technical. '
      'Validate feelings before offering suggestions. '
      'Never tell the user how they should feel. '
      'Ask gentle follow-up questions to understand their situation better before giving advice. '
      'Be direct and practical — autistic users often appreciate clear, honest responses '
      'rather than vague or overly cautious ones. '
      'Keep responses under 100 words unless the user asks for more detail or the topic genuinely needs it. '
      'Some things are beyond what you can help with. Tell the user to speak to their doctor, '
      'caregiver, guardian, or a trusted adult when: '
      'they describe physical health symptoms or pain, '
      'they need a formal diagnosis or assessment, '
      'they are dealing with abuse, neglect, or unsafe situations at home or school, '
      'they need medication advice or changes, '
      'they are experiencing something that has been going on for a long time and is not getting better, '
      'or their situation clearly requires professional intervention. '
      'When redirecting, always say something warm like: '
      'This sounds like something important that deserves proper support. '
      'I would really encourage you to talk to your doctor, caregiver, or a trusted adult about this. '
      'If the user mentions self-harm, wanting to die, or being in immediate danger, say: '
      'I am really glad you told me. Please tap the SOS button on the CalmMe screen right now. '
      'Never give medical diagnoses. Never recommend specific medication. '
      'App tools you can suggest when relevant: '
      'CalmMe screen has breathing exercises, music library, journaling, sensory toolkit, '
      'social scripts, calming games, anger management, mindfulness, stress relief, and self-control tools. '
      'The SOS screen gives immediate calm support. '
      'The Journal is great for processing feelings. '
      'The Analytics screen tracks mood patterns over time.';

  Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> history,
  ) async {
    if (!_configured) {
      return 'NuruAI is not set up yet. Please contact support.';
    }

    try {
      final List<Map<String, dynamic>> messages = [
        {'role': 'system', 'content': _systemPrompt},
      ];

      final recent = history.length > 20
          ? history.sublist(history.length - 20)
          : history;

      for (final msg in recent) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      messages.add({'role': 'user', 'content': userMessage});

      final res = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': 400,
              'temperature': 0.75,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        try {
          final err = jsonDecode(res.body) as Map<String, dynamic>;
          final msg = err['error']?['message'] as String?;
          if (msg != null) return msg;
        } catch (_) {}
        return 'Something went wrong. Please try again.';
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return "I'm having a little trouble right now. Please try again in a moment.";
      }

      final text = choices[0]['message']?['content'] as String?;
      return text?.trim() ??
          "I'm here with you. Could you try saying that again?";
    } catch (e) {
      return 'Connection error. Please check your internet and try again.';
    }
  }

  static const List<String> _crisisKeywords = [
    'hurt myself',
    'want to die',
    'kill myself',
    'self harm',
    'self-harm',
    'cut myself',
    'suicidal',
    'no reason to live',
    "can't go on",
    'cant go on',
    'give up on life',
    'end it all',
    'end my life',
    'not worth living',
    'rather be dead',
  ];

  bool detectsCrisis(String message) {
    final lower = message.toLowerCase();
    return _crisisKeywords.any((kw) => lower.contains(kw));
  }
}
