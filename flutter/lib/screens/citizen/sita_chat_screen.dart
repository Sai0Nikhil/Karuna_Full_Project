import 'package:flutter/material.dart';
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
  bool _isActive = false;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAnimation();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
          // Auto-send if we have words
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

  Future<void> _updateTtsLanguage(String lang) async {
    String ttsLang = 'en-IN';
    if (lang == 'Hindi') ttsLang = 'hi-IN';
    else if (lang == 'Telugu') ttsLang = 'te-IN';
    else if (lang == 'Tamil') ttsLang = 'ta-IN';
    else if (lang == 'Kannada') ttsLang = 'kn-IN';
    else if (lang == 'Bengali') ttsLang = 'bn-IN';
    try {
      await _tts.setLanguage(ttsLang);
    } catch (_) {}
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

  // ─── Start Chat ─────────────────────────────────────────────────
  void _startChat() {
    setState(() {
      _isActive = true;
      _messages.clear();
    });

    final greeting = 'Namaste! 🙏 I\'m Sita, your AI animal rescue guide. '
        'Tell me about the animal you found — I\'ll guide you step by step. '
        'Tap the microphone and speak, or type below.';

    _messages.add(_Message(greeting, isUser: false));
    _speak(greeting);
  }

  // ─── End Chat ───────────────────────────────────────────────────
  void _endChat() {
    _tts.stop();
    _speech.stop();
    setState(() {
      _isActive = false;
      _isListening = false;
      _isSpeaking = false;
    });
    _pulseController.stop();
  }

  // ─── Listen (Speech-to-Text) ────────────────────────────────────
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
      // Stop TTS if speaking
      if (_isSpeaking) {
        await _tts.stop();
      }

      setState(() {
        _isListening = true;
        _currentWords = '';
      });
      _pulseController.repeat(reverse: true);

      String locale = 'en_IN';
      if (_language == 'Hindi') locale = 'hi_IN';
      else if (_language == 'Telugu') locale = 'te_IN';
      else if (_language == 'Tamil') locale = 'ta_IN';
      else if (_language == 'Kannada') locale = 'kn_IN';
      else if (_language == 'Bengali') locale = 'bn_IN';

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentWords = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: locale,
      );
    }
  }

  // ─── Speak (Text-to-Speech) ─────────────────────────────────────
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    // Clean text for TTS
    final cleanText = text
        .replaceAll(RegExp(r'[🐾🙏⚠️📞🕐🤖]'), '')
        .replaceAll(RegExp(r'\n+'), '. ');
    await _tts.speak(cleanText);
  }

  // ─── Send Message ───────────────────────────────────────────────
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
          'I\'m having trouble connecting. Please check your internet and try again, or call your nearest animal rescue NGO.';
      _messages.add(_Message(response, isUser: false));
    });
    _scrollToBottom();

    // Auto-speak the response
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

  // ─── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF115E59)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isActive ? _buildChatArea() : _buildWelcome(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.greenAccent : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSpeaking ? 'Speaking...' : (_isListening ? 'Listening...' : 'AI Voice Assistant'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Language selector dropdown
          Theme(
            data: Theme.of(context).copyWith(canvasColor: AppColors.teal),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                icon: const Icon(Icons.translate, color: Colors.white, size: 20),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                onChanged: (lang) {
                  if (lang != null) {
                    setState(() {
                      _language = lang;
                    });
                    _updateTtsLanguage(lang);
                  }
                },
                items: [
                  ['English', 'EN'],
                  ['Hindi', 'HI'],
                  ['Telugu', 'TE'],
                  ['Tamil', 'TA'],
                  ['Kannada', 'KN'],
                  ['Bengali', 'BN'],
                ].map((l) => DropdownMenuItem<String>(
                  value: l[0],
                  child: Text(l[1]),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          if (_isActive)
            GestureDetector(
              onTap: _endChat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'End',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text('🗣️', style: TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Talk to Sita',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your AI-powered voice assistant for animal rescue guidance. '
            'Sita can help you with first aid steps, what to do next, and finding nearby help.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          // Start button
          GestureDetector(
            onTap: _startChat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_rounded, color: AppColors.teal, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Start Conversation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Features
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _featureChip('🎤 Voice Input'),
              const SizedBox(width: 12),
              _featureChip('🔊 Voice Output'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        // Messages
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[i]);
                },
              ),
            ),
          ),
        ),

        // Live transcription
        if (_isListening && _currentWords.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentWords,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

        // Input area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? AppColors.teal : Colors.white,
                  height: 1.4,
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
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 150)),
      builder: (_, value, __) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4 + (0.6 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main mic button
          GestureDetector(
            onTap: _loading ? null : _toggleListening,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red[400] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isListening 
                              ? Colors.red.withOpacity(0.4) 
                              : Colors.black.withOpacity(0.2),
                          blurRadius: _isListening ? 25 : 15,
                          spreadRadius: _isListening ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 32,
                      color: _isListening ? Colors.white : AppColors.teal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? 'Tap to stop' : 'Tap to speak',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          // Text input fallback
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Or type here...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _loading ? null : _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : () => _sendMessage(_textCtrl.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_loading ? 0.3 : 1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _loading ? Colors.white54 : AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
