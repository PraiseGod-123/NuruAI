import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// NURU AI SERVICE — Google Gemini 1.5 Flash
//
// Genuinely free — no card required.
// Free tier: 15 requests/min, 1M tokens/day
//
// Setup:
//   1. Go to: aistudio.google.com/app/apikey
//   2. Sign in with Google
//   3. Click "Create API Key"
//   4. Copy the key and set it in main.dart:
//      NuruAIService.instance.apiKey = 'YOUR_GEMINI_KEY';
// ══════════════════════════════════════════════════════════════

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

  // Set in main.dart — aistudio.google.com/app/apikey
  String apiKey = '';
  bool get _configured => apiKey.trim().isNotEmpty;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const _timeout = Duration(seconds: 20);

  static const String _systemPrompt =
      'You are NuruAI, a warm and calm AI companion inside the NuruAI app. '
      'NuruAI is designed specifically for autistic individuals aged 13 to 25 '
      'with ASD Level 1. '
      'Your role: Be a supportive non-judgmental presence. Help users understand '
      'and manage their emotions. Offer calm reassurance when they are overwhelmed. '
      'Gently suggest tools in the app when relevant. '
      'How you must communicate: Always use short clear sentences. '
      'Never write long paragraphs. Never use bullet points, numbered lists, or headers. '
      'Use warm simple language, never clinical or technical. '
      'Validate feelings before offering suggestions. '
      'Never tell the user how they should feel. '
      'Safety rules: If the user expresses crisis or mentions self-harm always say: '
      '"It sounds like you need some immediate support right now. Please tap the SOS '
      'button on the CalmMe screen - it will guide you through this calmly." '
      'Never give medical or clinical diagnoses. Never recommend medication. '
      'App features you know about: The CalmMe screen has breathing exercises, music, '
      'journaling, sensory toolkit, social scripts, calming games, meltdown prevention, '
      'and a special interest space. The SOS screen provides immediate calm. '
      'Keep all responses under 80 words unless the user asks for more detail.';

  // ══════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ══════════════════════════════════════════════════════════

  Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> history,
  ) async {
    if (!_configured) {
      return 'I am not ready yet. Please add a Gemini API key from '
          'aistudio.google.com/app/apikey';
    }

    try {
      final uri = Uri.parse('$_baseUrl?key=$apiKey');

      // Build conversation — Gemini uses alternating user/model roles
      final List<Map<String, dynamic>> contents = [];

      final recent = history.length > 20
          ? history.sublist(history.length - 20)
          : history;

      for (final msg in recent) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [
            {'text': msg.text},
          ],
        });
      }

      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });

      // Prepend system prompt to first user message for v1beta compatibility
      final List<Map<String, dynamic>> finalContents = [
        {
          'role': 'user',
          'parts': [
            {'text': _systemPrompt + '\n\nUser: ' + userMessage},
          ],
        },
        {
          'role': 'model',
          'parts': [
            {
              'text':
                  'Understood. I am NuruAI and I will follow these guidelines. How can I help you?',
            },
          ],
        },
        ...contents,
      ];

      final body = jsonEncode({
        'contents': finalContents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 300,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      });

      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_timeout);

      if (res.statusCode != 200) {
        try {
          final errData = jsonDecode(res.body) as Map<String, dynamic>;
          final errMsg = errData['error']?['message'] as String?;
          if (errMsg != null) return errMsg;
        } catch (_) {}
        return 'Error ' + res.statusCode.toString() + ': ' + res.body;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return "I'm having a little trouble right now. Please try again in a moment.";
      }

      final text = candidates[0]['content']?['parts']?[0]?['text'] as String?;
      return text?.trim() ?? "I'm here. Could you try saying that again?";
    } on Exception catch (e) {
      return 'Connection error. Please check your internet and try again.';
    }
  }

  // ══════════════════════════════════════════════════════════
  // CRISIS DETECTION
  // ══════════════════════════════════════════════════════════

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
  ];

  bool detectsCrisis(String message) {
    final lower = message.toLowerCase();
    return _crisisKeywords.any((kw) => lower.contains(kw));
  }
}
