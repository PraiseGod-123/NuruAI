import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../services/nuru_ai_service.dart';
import '../services/firebase_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/nuru_theme_extension.dart';

// ══════════════════════════════════════════════════════════════
// NURU AI CHAT SCREEN — Tiimo-inspired design
//
// Design language:
//   - Frosted glass chat area over the night blue background
//   - Large rounded pill bubbles — spacious and calm
//   - AI messages left, user messages right
//   - Generous spacing — nothing feels crowded
//   - Suggestion chips above input
//   - Minimal — no timestamps, no read receipts visible
// ══════════════════════════════════════════════════════════════

class NuruAIChatScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const NuruAIChatScreen({Key? key, this.userData}) : super(key: key);
  @override
  State<NuruAIChatScreen> createState() => _NuruAIChatScreenState();
}

class _NuruAIChatScreenState extends State<NuruAIChatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _showCrisisBanner = false;

  // Session tracking for Firestore persistence
  final DateTime _sessionStart = DateTime.now();
  String? _sessionTopic;

  final _svc = NuruAIService.instance;

  // Palette
  static const Color _aiColor = Color(0xFF6C5CE7);

  // User bubble — sailing blue
  // AI bubble — frosted white
  static const Color _aiBubble = Color(0xFFEDF1FB);

  static const List<String> _suggestions = [
    'I feel overwhelmed',
    'I need to calm down',
    'I am anxious',
    'I had a hard day',
    'Help me breathe',
    'I feel misunderstood',
  ];

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcome());
  }

  @override
  void dispose() {
    // Save chat session to Firestore when user leaves
    final uid = widget.userData?['uid'] as String? ?? '';
    final userMessages = _messages.where((m) => m.isUser).toList();
    if (uid.isNotEmpty && userMessages.isNotEmpty) {
      NuruFirebaseService.instance.saveChatSession(
        uid: uid,
        messages: _messages
            .map(
              (m) => {
                'text': m.text,
                'isUser': m.isUser,
                'timestamp': m.timestamp.toIso8601String(),
              },
            )
            .toList(),
        topic: _sessionTopic,
        durationSecs: DateTime.now().difference(_sessionStart).inSeconds,
      );
    }
    _starCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcome() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hi, I'm NuruAI. I'm here with you.\n\nHow are you feeling right now?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _inputCtrl.clear();
    _focusNode.unfocus();

    if (_svc.detectsCrisis(msg)) {
      setState(() => _showCrisisBanner = true);
    }

    // Detect topic from first user message
    if (_sessionTopic == null) {
      final lower = msg.toLowerCase();
      if (lower.contains('overwhelm') || lower.contains('meltdown')) {
        _sessionTopic = 'overwhelm';
      } else if (lower.contains('anxi') ||
          lower.contains('worry') ||
          lower.contains('panic')) {
        _sessionTopic = 'anxiety';
      } else if (lower.contains('sad') ||
          lower.contains('cry') ||
          lower.contains('depress')) {
        _sessionTopic = 'sadness';
      } else if (lower.contains('ang') ||
          lower.contains('frust') ||
          lower.contains('rage')) {
        _sessionTopic = 'anger';
      } else if (lower.contains('breath') ||
          lower.contains('calm') ||
          lower.contains('relax')) {
        _sessionTopic = 'calming';
      } else if (lower.contains('lonely') ||
          lower.contains('misunderstood') ||
          lower.contains('alone')) {
        _sessionTopic = 'connection';
      } else if (lower.contains('sensory') ||
          lower.contains('loud') ||
          lower.contains('light')) {
        _sessionTopic = 'sensory';
      } else {
        _sessionTopic = 'general';
      }
    }

    setState(() {
      _messages.add(
        ChatMessage(text: msg, isUser: true, timestamp: DateTime.now()),
      );
      _loading = true;
    });
    _scrollToBottom();

    final reply = await _svc.sendMessage(
      msg,
      List.from(_messages)..removeLast(),
    );

    setState(() {
      _messages.add(
        ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
      );
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.nuruTheme.backgroundStart,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.nuruTheme.accentColor,
                    context.nuruTheme.backgroundEnd,
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarsPainter(t: _starCtrl.value),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  if (_showCrisisBanner) _buildCrisisBanner(),
                  // Chat area — frosted glass
                  Expanded(child: _buildChatArea()),
                  // Input section
                  _buildBottomSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────

  Widget _buildAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.nuruTheme.backgroundMid.withOpacity(0.75),
                context.nuruTheme.backgroundStart.withOpacity(0.80),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: context.nuruTheme.accentColor.withOpacity(0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.nuruTheme.backgroundStart.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.nuruTheme.accentColor.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _aiColor.withOpacity(0.75),
                      _aiColor.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: _aiColor.withOpacity(0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: _aiColor.withOpacity(0.3), blurRadius: 12),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NuruAI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00B894),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Here for you',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Clear
              GestureDetector(
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _showCrisisBanner = false;
                  });
                  _addWelcome();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.nuruTheme.backgroundStart.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.nuruTheme.accentColor.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Crisis banner ─────────────────────────────────────────

  Widget _buildCrisisBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF6B6B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Need immediate support? The SOS screen can help.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/sos'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.5),
                ),
              ),
              child: const Text(
                'SOS',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _showCrisisBanner = false),
            child: Icon(
              Icons.close_rounded,
              size: 15,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat area ─────────────────────────────────────────────

  Widget _buildChatArea() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF).withOpacity(0.10),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
            ),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(overscroll: false),
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _buildTyping();
                return _buildBubble(_messages[i]);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Bubbles ───────────────────────────────────────────────

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _aiColor.withOpacity(0.7),
                    _aiColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: _aiColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser
                    ? context.nuruTheme.accentColor.withOpacity(0.85)
                    : Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 22),
                ),
                border: Border.all(
                  color: isUser
                      ? context.nuruTheme.accentColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.nuruTheme.backgroundStart.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(isUser ? 0.95 : 0.90),
                  height: 1.55,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _aiColor.withOpacity(0.7),
                  _aiColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
              border: Border.all(color: _aiColor.withOpacity(0.5), width: 1.5),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(22),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: AnimatedBuilder(
              animation: _starCtrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final v = ((_starCtrl.value + i * 0.33) % 1.0);
                  final opacity = 0.3 + math.sin(v * math.pi) * 0.7;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.nuruTheme.accentColor
                          .withOpacity(0.4)
                          .withOpacity(opacity.clamp(0.3, 1.0)),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom section — suggestions + input ─────────────────

  Widget _buildBottomSection() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.nuruTheme.backgroundStart.withOpacity(0.0),
                context.nuruTheme.backgroundStart.withOpacity(0.97),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Suggestion chips — only show at the start
              if (_messages.length <= 2) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _send(_suggestions[i]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.nuruTheme.backgroundMid.withOpacity(
                            0.6,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: context.nuruTheme.accentColor.withOpacity(
                              0.55,
                            ),
                          ),
                        ),
                        child: Text(
                          _suggestions[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Input row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Row(
                  children: [
                    // Text field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.nuruTheme.backgroundMid.withOpacity(
                            0.65,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: context.nuruTheme.accentColor.withOpacity(
                              0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: _send,
                                decoration: InputDecoration(
                                  hintText: 'Say something...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 14.5,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Send button
                    GestureDetector(
                      onTap: () => _send(_inputCtrl.text),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_aiColor, _aiColor.withOpacity(0.75)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _aiColor.withOpacity(0.4),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stars painter ─────────────────────────────────────────────

class _StarsPainter extends CustomPainter {
  final double t;
  const _StarsPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    const s = [
      [0.08, 0.05],
      [0.22, 0.12],
      [0.40, 0.08],
      [0.58, 0.15],
      [0.72, 0.06],
      [0.88, 0.11],
      [0.14, 0.30],
      [0.35, 0.38],
      [0.55, 0.28],
      [0.75, 0.35],
      [0.92, 0.28],
      [0.20, 0.55],
      [0.48, 0.60],
      [0.68, 0.52],
      [0.85, 0.62],
      [0.10, 0.75],
      [0.38, 0.80],
      [0.62, 0.72],
      [0.80, 0.82],
      [0.95, 0.70],
    ];
    for (final st in s) {
      final x = size.width * st[0];
      final y = size.height * st[1];
      final off = (st[0] + st[1]) % 1.0;
      final op = 0.2 + ((t + off) % 1.0) * 0.35;
      p.color = Colors.white.withOpacity(op * 0.3);
      canvas.drawCircle(Offset(x, y), 2.8, p);
      p.color = Colors.white.withOpacity(op * 0.6);
      canvas.drawCircle(Offset(x, y), 1.5, p);
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(x, y), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}
