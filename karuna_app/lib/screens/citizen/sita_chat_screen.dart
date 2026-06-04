import 'package:flutter/material.dart';
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

class _SitaChatScreenState extends State<SitaChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Greeting
    _messages.add(_Message(
      'नमस्ते! 🐾 I\'m Sita, your AI animal rescue guide.\n\n'
      'Tell me about the animal you found — what\'s happening, where, and any symptoms you can see. '
      'I\'ll give you step-by-step first aid guidance right away.',
      isUser: false,
    ));
    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      // Auto-send initial context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialContext!);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(text, isUser: true));
      _loading = true;
      _ctrl.clear();
    });
    _scrollToBottom();

    final reply = await AiService.chatWithSita(
      message: text,
      species: widget.species ?? 'animal',
    );

    setState(() {
      _loading = false;
      _messages.add(_Message(
        reply ?? 'Sorry, I couldn\'t get a response. Please try again or call your nearest animal rescue NGO.',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sita', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.teal)),
              Text('AI Animal Rescue Guide', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            ],
          ),
        ]),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  // Loading bubble
                  return _buildBubble(
                    _TypingIndicator(),
                    isUser: false,
                  );
                }
                final msg = _messages[i];
                return _buildBubble(
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: msg.isUser ? Colors.white : AppColors.dark,
                      height: 1.5,
                    ),
                  ),
                  isUser: msg.isUser,
                );
              },
            ),
          ),

          // Quick suggestion chips (shown only at start)
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  '🐕 Dog hit by car',
                  '🐈 Cat bleeding',
                  '🐄 Cow with wound',
                  '🦜 Injured bird',
                ].map((q) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.tealLight,
                    labelStyle: const TextStyle(color: AppColors.teal),
                    onPressed: () => _sendMessage(q),
                  ),
                )).toList(),
              ),
            ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Describe the animal\'s situation…',
                    hintStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _loading ? null : _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : () => _sendMessage(_ctrl.text),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _loading ? AppColors.gray : AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Widget child, {required bool isUser}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.tealLight, shape: BoxShape.circle),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => Container(
          width: 7, height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.3 + 0.7 * (i == (_anim.value * 3).floor() % 3 ? 1 : 0.3)),
            shape: BoxShape.circle,
          ),
        )),
      ),
    );
  }
}
