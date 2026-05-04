import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../services/nuru_ai_service.dart';
import '../services/firebase_service.dart';
import '../providers/nuru_theme_extension.dart';

// ══════════════════════════════════════════════════════════════
// NURU AI CHAT SCREEN
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
  bool _loadingHistory = false;
  bool _showCrisisBanner = false;
  bool _showToolbar = false; // toggles the coping tools row

  final DateTime _sessionStart = DateTime.now();
  String? _sessionTopic;

  final _svc = NuruAIService.instance;
  final ScrollController _chipScrollCtrl = ScrollController();
  bool _chipScrolling = true;

  static const Color _aiColor = Color(0xFF6C5CE7);

  // All coping mechanism tools
  static const List<_CopingTool> _tools = [
    _CopingTool(
      label: 'Breathing',
      icon: Icons.air_rounded,
      route: '/breathing',
      color: Color(0xFF00B4D8),
      description: 'Calm your body',
    ),
    _CopingTool(
      label: 'Journal',
      icon: Icons.menu_book_rounded,
      route: '/journal',
      color: Color(0xFF4CAF50),
      description: 'Write it out',
    ),
    _CopingTool(
      label: 'Mindfulness',
      icon: Icons.self_improvement_rounded,
      route: '/mindfulness',
      color: Color(0xFFAB47BC),
      description: 'Stay present',
    ),
    _CopingTool(
      label: 'Music',
      icon: Icons.headphones_rounded,
      route: '/music',
      color: Color(0xFFFF7043),
      description: 'Soothe your mind',
    ),
    _CopingTool(
      label: 'Stress Relief',
      icon: Icons.spa_rounded,
      route: '/stress-relief',
      color: Color(0xFF26A69A),
      description: 'Release tension',
    ),
    _CopingTool(
      label: 'Anger Help',
      icon: Icons.local_fire_department_rounded,
      route: '/anger-management',
      color: Color(0xFFEF5350),
      description: 'Cool down',
    ),
    _CopingTool(
      label: 'Self Control',
      icon: Icons.psychology_rounded,
      route: '/self-control',
      color: Color(0xFF5C6BC0),
      description: 'Build focus',
    ),
    _CopingTool(
      label: 'Sensory',
      icon: Icons.hearing_rounded,
      route: '/sensory-toolkit',
      color: Color(0xFF8D6E63),
      description: 'Sensory toolkit',
    ),
    _CopingTool(
      label: 'Social Scripts',
      icon: Icons.chat_rounded,
      route: '/social-scripts',
      color: Color(0xFF29B6F6),
      description: 'What to say',
    ),
    _CopingTool(
      label: 'Calming Games',
      icon: Icons.games_rounded,
      route: '/calming-games',
      color: Color(0xFFFFCA28),
      description: 'Gentle distraction',
    ),
    _CopingTool(
      label: 'Poetry',
      icon: Icons.auto_stories_rounded,
      route: '/poetry-corner',
      color: Color(0xFFEC407A),
      description: 'Express yourself',
    ),
    _CopingTool(
      label: 'SOS',
      icon: Icons.emergency_rounded,
      route: '/sos',
      color: Color(0xFFFF6B6B),
      description: 'Immediate help',
    ),
  ];

  static const List<String> _suggestions = [
    'I feel overwhelmed',
    'I have a crush on someone',
    'I am anxious',
    'I had a hard day',
    'I feel lonely',
    'Someone is bothering me',
    'I need to calm down',
    'I feel misunderstood',
  ];

  static const Map<String, String> _topicLabels = {
    'overwhelm': 'Feeling overwhelmed',
    'anxiety': 'Anxiety & worry',
    'sadness': 'Sadness',
    'anger': 'Anger & frustration',
    'calming': 'Calming down',
    'connection': 'Loneliness',
    'sensory': 'Sensory challenges',
    'relationships': 'Relationships & crushes',
    'social': 'Social situations',
    'school': 'School & college',
    'family': 'Family',
    'general': 'General chat',
  };

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcome();
      _startChipTicker();
    });
  }

  @override
  void dispose() {
    final uid = widget.userData?['uid'] as String? ?? '';
    final userMsgs = _messages.where((m) => m.isUser).toList();
    if (uid.isNotEmpty && userMsgs.isNotEmpty) {
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
    _chipScrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Chip auto-scroll ticker

  Future<void> _startChipTicker() async {
    await Future.delayed(const Duration(milliseconds: 800));
    while (mounted && _chipScrolling) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) break;
      if (_chipScrollCtrl.hasClients) {
        final max = _chipScrollCtrl.position.maxScrollExtent;
        final cur = _chipScrollCtrl.offset;
        if (cur >= max) {
          // Jump back to start seamlessly (list is doubled for infinite feel)
          _chipScrollCtrl.jumpTo(0);
        } else {
          _chipScrollCtrl.jumpTo(cur + 1.2);
        }
      }
    }
  }

  // Welcome

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

  // Topic detection

  void _detectTopic(String msg) {
    if (_sessionTopic != null) return;
    final l = msg.toLowerCase();
    if (l.contains('overwhelm') || l.contains('meltdown')) {
      _sessionTopic = 'overwhelm';
    } else if (l.contains('anxi') ||
        l.contains('worry') ||
        l.contains('panic')) {
      _sessionTopic = 'anxiety';
    } else if (l.contains('sad') ||
        l.contains('cry') ||
        l.contains('depress')) {
      _sessionTopic = 'sadness';
    } else if (l.contains('ang') || l.contains('frust') || l.contains('rage')) {
      _sessionTopic = 'anger';
    } else if (l.contains('breath') ||
        l.contains('calm') ||
        l.contains('relax')) {
      _sessionTopic = 'calming';
    } else if (l.contains('lonely') ||
        l.contains('misunderstood') ||
        l.contains('alone')) {
      _sessionTopic = 'connection';
    } else if (l.contains('sensory') ||
        l.contains('loud') ||
        l.contains('light')) {
      _sessionTopic = 'sensory';
    } else if (l.contains('crush') ||
        l.contains('like someone') ||
        l.contains('in love') ||
        l.contains('relationship') ||
        l.contains('boyfriend') ||
        l.contains('girlfriend') ||
        l.contains('romantic')) {
      _sessionTopic = 'relationships';
    } else if (l.contains('friend') ||
        l.contains('bully') ||
        l.contains('left out') ||
        l.contains('social') ||
        l.contains('people')) {
      _sessionTopic = 'social';
    } else if (l.contains('school') ||
        l.contains('college') ||
        l.contains('class') ||
        l.contains('teacher') ||
        l.contains('exam') ||
        l.contains('study')) {
      _sessionTopic = 'school';
    } else if (l.contains('family') ||
        l.contains('parent') ||
        l.contains('mum') ||
        l.contains('dad') ||
        l.contains('sibling') ||
        l.contains('home')) {
      _sessionTopic = 'family';
    } else {
      _sessionTopic = 'general';
    }
  }

  // Send

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _inputCtrl.clear();
    _focusNode.unfocus();

    if (_svc.detectsCrisis(msg)) setState(() => _showCrisisBanner = true);
    _detectTopic(msg);

    setState(() {
      _messages.add(
        ChatMessage(text: msg, isUser: true, timestamp: DateTime.now()),
      );
      _loading = true;
      _showToolbar = false;
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

  //  History sheet

  Future<void> _showHistorySheet() async {
    final uid = widget.userData?['uid'] as String? ?? '';
    if (uid.isEmpty) return;

    setState(() => _loadingHistory = true);
    final sessions = await NuruFirebaseService.instance.getChatSessions(uid);
    if (!mounted) return;
    setState(() => _loadingHistory = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F42),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _aiColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: _aiColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Chat History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.clear();
                          _showCrisisBanner = false;
                          _sessionTopic = null;
                          _showToolbar = false;
                        });
                        _addWelcome();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _aiColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _aiColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: _aiColor, size: 16),
                            const SizedBox(width: 5),
                            const Text(
                              'New Chat',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _aiColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.08), height: 24),
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No previous chats yet.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start a conversation and it will appear here.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = sessions[i];
                          final topic = s['topic'] as String? ?? 'general';
                          final label = _topicLabels[topic] ?? 'Chat session';
                          final createdAt = s['createdAt'] as String?;
                          final msgCount = s['messageCount'] as int? ?? 0;
                          final msgs = s['messages'] as List? ?? [];

                          String preview = 'Tap to view this session';
                          for (final m in msgs) {
                            if (m['isUser'] == true) {
                              preview = m['text'] as String? ?? preview;
                              break;
                            }
                          }
                          if (preview.length > 60)
                            preview = '${preview.substring(0, 60)}...';

                          String dateStr = '';
                          if (createdAt != null) {
                            try {
                              final dt = DateTime.parse(createdAt).toLocal();
                              final diff = DateTime.now().difference(dt);
                              if (diff.inDays == 0)
                                dateStr = 'Today';
                              else if (diff.inDays == 1)
                                dateStr = 'Yesterday';
                              else if (diff.inDays < 7)
                                dateStr = '${diff.inDays} days ago';
                              else
                                dateStr = '${dt.day}/${dt.month}/${dt.year}';
                            } catch (_) {}
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              final loaded = <ChatMessage>[];
                              for (final m in msgs) {
                                loaded.add(
                                  ChatMessage(
                                    text: m['text'] as String? ?? '',
                                    isUser: m['isUser'] as bool? ?? false,
                                    timestamp:
                                        DateTime.tryParse(
                                          m['timestamp'] as String? ?? '',
                                        ) ??
                                        DateTime.now(),
                                  ),
                                );
                              }
                              setState(() {
                                _messages.clear();
                                _messages.addAll(loaded);
                                _sessionTopic = topic;
                                _showCrisisBanner = false;
                                _showToolbar = false;
                              });
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToBottom(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _aiColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _topicIcon(topic),
                                      color: _aiColor.withOpacity(0.8),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                label,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (dateStr.isNotEmpty)
                                              Text(
                                                dateStr,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white
                                                      .withOpacity(0.35),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          preview,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.white.withOpacity(
                                              0.45,
                                            ),
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$msgCount messages',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _aiColor.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _topicIcon(String topic) {
    switch (topic) {
      case 'relationships':
        return Icons.favorite_outline_rounded;
      case 'anxiety':
        return Icons.air_rounded;
      case 'sadness':
        return Icons.water_drop_outlined;
      case 'anger':
        return Icons.local_fire_department_outlined;
      case 'social':
        return Icons.people_outline_rounded;
      case 'school':
        return Icons.school_outlined;
      case 'family':
        return Icons.home_outlined;
      case 'sensory':
        return Icons.hearing_outlined;
      case 'calming':
        return Icons.self_improvement_outlined;
      case 'overwhelm':
        return Icons.waves_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF081F44),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.nuruTheme.backgroundStart,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.nuruTheme.gradientColors,
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
                  Expanded(child: _buildChatArea()),
                  // Coping tools toolbar — shown when grid button is tapped
                  if (_showToolbar) _buildCopingToolbar(),
                  _buildBottomSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App bar

  Widget _buildAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF081F44).withOpacity(0.82),
            border: Border(
              bottom: BorderSide(color: _aiColor.withOpacity(0.25), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar with animated glow ring
              AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) {
                  final glow = 0.35 + _starCtrl.value * 0.25;
                  return Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _aiColor.withOpacity(glow),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_aiColor, _aiColor.withOpacity(0.55)],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NuruAI',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _starCtrl,
                          builder: (_, __) => Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E676),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00E676,
                                  ).withOpacity(0.6 + _starCtrl.value * 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Here for you',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.55),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // History button
              GestureDetector(
                onTap: _loadingHistory ? null : _showHistorySheet,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: _loadingHistory
                          ? Padding(
                              padding: const EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            )
                          : Icon(
                              Icons.history_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
              // New chat button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _showCrisisBanner = false;
                    _sessionTopic = null;
                    _showToolbar = false;
                  });
                  _addWelcome();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _aiColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _aiColor.withOpacity(0.35)),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: _aiColor.withOpacity(0.9),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Crisis banner

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
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 18),
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

  // Coping tools toolbar

  Widget _buildCopingToolbar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F42).withOpacity(0.95),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
                bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _aiColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Access — Coping Tools',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showToolbar = false),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.35),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _tools.length,
                    itemBuilder: (_, i) {
                      final tool = _tools[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _showToolbar = false);
                          Navigator.pushNamed(
                            context,
                            tool.route,
                            arguments: widget.userData,
                          );
                        },
                        child: Container(
                          width: 72,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: tool.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: tool.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tool.color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  tool.icon,
                                  color: tool.color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tool.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Chat area

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
            color: Colors.white.withOpacity(0.04),
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

  // Bubbles

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final time =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20,
        left: isUser ? 52 : 0,
        right: isUser ? 0 : 52,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Nuru avatar
            AnimatedBuilder(
              animation: _starCtrl,
              builder: (_, __) => Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_aiColor, _aiColor.withOpacity(0.6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _aiColor.withOpacity(
                        0.35 + _starCtrl.value * 0.15,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isUser ? 22 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 22),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _aiColor.withOpacity(0.95),
                                  _aiColor.withOpacity(0.70),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.16),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: Radius.circular(isUser ? 22 : 5),
                          bottomRight: Radius.circular(isUser ? 5 : 22),
                        ),
                        border: Border.all(
                          color: isUser
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.14),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(isUser ? 0.97 : 0.92),
                          height: 1.6,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.28),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // Typing indicator

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_aiColor, _aiColor.withOpacity(0.6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _aiColor.withOpacity(0.35 + _starCtrl.value * 0.2),
                    blurRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(22),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.16),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(22),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: AnimatedBuilder(
                  animation: _starCtrl,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final v = ((_starCtrl.value + i * 0.33) % 1.0);
                      final sz = 6.0 + math.sin(v * math.pi) * 4;
                      final op = 0.35 + math.sin(v * math.pi) * 0.65;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: sz,
                        height: sz,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _aiColor.withOpacity(op.clamp(0.35, 1.0)),
                          boxShadow: [
                            BoxShadow(
                              color: _aiColor.withOpacity(op * 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Bottom section

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
              if (_messages.length <= 2) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    controller: _chipScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // Double the list for seamless looping
                    itemCount: _suggestions.length * 2,
                    itemBuilder: (_, i) {
                      final suggestion = _suggestions[i % _suggestions.length];
                      return GestureDetector(
                        onTap: () => _send(suggestion),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081F44).withOpacity(0.75),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _aiColor.withOpacity(0.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _aiColor.withOpacity(0.12),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Row(
                  children: [
                    // Grid / tools button
                    GestureDetector(
                      onTap: () => setState(() => _showToolbar = !_showToolbar),
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _showToolbar
                              ? _aiColor.withOpacity(0.2)
                              : context.nuruTheme.backgroundMid.withOpacity(
                                  0.6,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showToolbar
                                ? _aiColor.withOpacity(0.6)
                                : context.nuruTheme.accentColor.withOpacity(
                                    0.4,
                                  ),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          _showToolbar
                              ? Icons.grid_view_rounded
                              : Icons.grid_view_rounded,
                          color: _showToolbar
                              ? _aiColor
                              : Colors.white.withOpacity(0.55),
                          size: 20,
                        ),
                      ),
                    ),
                    // Text field
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
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
                                  color: Colors.white.withOpacity(0.38),
                                  fontSize: 14.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Send
                    GestureDetector(
                      onTap: () => _send(_inputCtrl.text),
                      child: AnimatedBuilder(
                        animation: _starCtrl,
                        builder: (_, __) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_aiColor, Color(0xFF9B59B6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _aiColor.withOpacity(
                                  0.45 + _starCtrl.value * 0.2,
                                ),
                                blurRadius: 16 + _starCtrl.value * 6,
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

// Coping tool model

class _CopingTool {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final String description;
  const _CopingTool({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
    required this.description,
  });
}

// Stars painter

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
