import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/ai_service.dart';
import '../../utils/app_colors.dart';

class _Message {
  final String text;
  final bool isUser;
  _Message(this.text, {required this.isUser});
}

class SitaChatScreen extends StatefulWidget {
  final String? species;
  final String? initialContext;

  const SitaChatScreen({super.key, this.species, this.initialContext});

  @override
  State<SitaChatScreen> createState() => _SitaChatScreenState();
}

class _SitaChatScreenState extends State<SitaChatScreen> with TickerProviderStateMixin {
  // Voice
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechAvailable = false;
  String _currentWords = '';
  String _language = 'English';

  // Chat
  final List<_Message> _messages = [];
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _quickReplies = [
    'REPORT INJURY',
    'STRAY PUPPIES',
    'BIRD RESCUE'
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAnimation();
    _startChat();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          _pulseController.stop();
          if (_currentWords.isNotEmpty) {
            _sendMessage(_currentWords);
            _currentWords = '';
          }
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        _pulseController.stop();
      },
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startChat() {
    _messages.clear();
    final greeting = 'Namaste! 🙏 I\'m Sita, your AI animal rescue guide. '
        'Tell me about the animal you found.';
    setState(() {
      _messages.add(_Message(greeting, isUser: false));
    });
    _speak(greeting);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showSnack('Speech recognition not available on this device');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
    } else {
      if (_isSpeaking) {
        await _tts.stop();
      }
      setState(() {
        _isListening = true;
        _currentWords = '';
      });
      _pulseController.repeat(reverse: true);

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentWords = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
      );
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    final cleanText = text
        .replaceAll(RegExp(r'[🐾🙏⚠️📞🕐🤖]'), '')
        .replaceAll(RegExp(r'\n+'), '. ');
    await _tts.speak(cleanText);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add(_Message(text.trim(), isUser: true));
      _loading = true;
      _textCtrl.clear();
    });
    _scrollToBottom();

    final reply = await AiService.chatWithSita(
      message: text,
      species: widget.species ?? 'animal',
      context: widget.initialContext ?? '',
      language: _language,
    );

    setState(() {
      _loading = false;
      final response = reply ?? 
          'I\'m having trouble connecting. Please check your internet and try again.';
      _messages.add(_Message(response, isUser: false));
    });
    _scrollToBottom();

    if (reply != null) {
      _speak(reply);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D9488), Color(0xFF115E59)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    // Chat message view
                    Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: _messages.length + (_loading ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _messages.length) {
                                return _buildTypingIndicator();
                              }
                              return _buildMessageBubble(_messages[i]);
                            },
                          ),
                        ),
                        const SizedBox(height: 120), // spacer for mic/input
                      ],
                    ),

                    // Centered Listening overlay when active
                    if (_isListening)
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFF115E59).withOpacity(0.9),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPulsingMic(),
                              const SizedBox(height: 24),
                              Text(
                                'Listening...',
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSoundwave(),
                              if (_currentWords.isNotEmpty) ...[
                                const SizedBox(height: 28),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    '"$_currentWords"',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // Bottom action controllers
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildControlsSection(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          // Glowing Sita avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Center(
              child: Text('🐾', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sita',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'AI Rescue Guide',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // ACTIVE badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: isUser ? const Color(0xFF115E59) : Colors.white,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (idx) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 300 + (idx * 150)),
                  builder: (_, val, __) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(val),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingMic() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Center(
            child: Container(
              width: 100 * _pulseAnimation.value,
              height: 100 * _pulseAnimation.value,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.mic, size: 40, color: Color(0xFF115E59)),
                  onPressed: _toggleListening,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoundwave() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (idx) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 8, end: 28),
          duration: Duration(milliseconds: 250 + (idx * 80)),
          builder: (_, val, __) {
            return Container(
              width: 3.5,
              height: _isListening ? val : 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF115E59).withOpacity(0.0),
            const Color(0xFF115E59).withOpacity(0.95),
            const Color(0xFF115E59),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text Input bar with mic icon inside left, send icon right
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic, color: AppColors.teal),
                  onPressed: _toggleListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: GoogleFonts.inter(color: AppColors.dark, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(color: AppColors.gray, fontSize: 15),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      fillColor: Colors.transparent,
                      filled: false,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                GestureDetector(
                  onTap: () => _sendMessage(_textCtrl.text),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick reply chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _quickReplies.map((text) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(text),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    labelStyle: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    onPressed: () => _sendMessage(text),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
