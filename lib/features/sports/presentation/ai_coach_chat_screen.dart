import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/models/sports_models.dart'; // حاوی ChatMessage, TextMessage, ActionableSuggestionMessage

class AiCoachChatScreen extends StatefulWidget {
  const AiCoachChatScreen({super.key});

  @override
  State<AiCoachChatScreen> createState() => _AiCoachChatScreenState();
}

class _AiCoachChatScreenState extends State<AiCoachChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [
    TextMessage(content: 'سلام! من مربی هوشمند ریتمو هستم. چطور می‌تونم بهت کمک کنم؟', fromUser: false),
    TextMessage(content: 'مثلاً می‌تونی بپرسی: "امروز خیلی خسته‌ام، برنامه‌م رو سبک‌تر کن" یا "تمرین سینه دیروز خیلی راحت بود".', fromUser: false),
  ];

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    RitmoHaptics.tap();
    setState(() {
      _messages.add(TextMessage(content: text, fromUser: true));
      _textController.clear();
    });
    
    _scrollToBottom();

    // Mock AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add(TextMessage(content: 'دارم بررسی می‌کنم...', fromUser: false));
      });
      _scrollToBottom();

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _messages.removeLast(); // حذف پیام "دارم بررسی میکنم"
          
          if (text.contains('سخت') || text.contains('خسته')) {
            _messages.add(TextMessage(content: 'به نظر میاد خسته‌ای. پیشنهاد می‌کنم یکم حجم تمرینات رو کم کنیم.', fromUser: false));
            _messages.add(ActionableSuggestionMessage(
              title: 'کاهش حجم تمرین',
              description: 'حذف یک ست از تمام حرکات سنگین امروز.',
              actionLabel: 'اعمال تغییرات',
            ));
          } else {
            _messages.add(TextMessage(content: 'متوجهم. فعلاً به همین روند ادامه بده، اگر تغییری نیاز بود بهت میگم.', fromUser: false));
          }
        });
        RitmoHaptics.success();
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A110E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.right_chevron, color: Colors.white),
          onPressed: () { RitmoHaptics.tap(); Navigator.pop(context); },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('مربی هوشمند',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16,
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg is TextMessage) {
                    return _buildTextMessage(msg);
                  } else if (msg is ActionableSuggestionMessage) {
                    return _buildActionableMessage(msg);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(TextMessage msg) {
    return Align(
      alignment: msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.fromUser ? const Color(0xff00F5A0).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.fromUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: msg.fromUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
          border: msg.fromUser ? Border.all(color: const Color(0xff00F5A0).withValues(alpha: 0.3)) : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: msg.fromUser ? Colors.white : Colors.white70,
            fontSize: 14,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }

  Widget _buildActionableMessage(ActionableSuggestionMessage msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xff3B82F6).withValues(alpha: 0.1), Colors.transparent],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(0)),
          border: Border.all(color: const Color(0xff3B82F6).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xff60A5FA), size: 18),
                const SizedBox(width: 8),
                Text('پیشنهاد هوشمند', style: TextStyle(fontSize: 12, color: const Color(0xff60A5FA).withValues(alpha: 0.8), fontFamily: 'Vazirmatn')),
              ],
            ),
            const SizedBox(height: 8),
            Text(msg.title, style: const TextStyle(fontSize: 15, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(msg.description, style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: RitmoHaptics.success,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(msg.actionLabel, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xff0A110E),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'پیام خود را بنویسید...',
                  hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Vazirmatn'),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff00F5A0),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
