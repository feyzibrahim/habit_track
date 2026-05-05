import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:ezecute/core/api/api_service.dart';

enum MessageSender { ai, user }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final String? time;

  const ChatMessage({required this.text, required this.sender, this.time});
}

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      sender: MessageSender.ai,
      text:
          'Hello! I am your Mission Coach. How can I help you with your goals today?',
    ),
  ];
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(sender: MessageSender.user, text: text, time: 'Now'),
      );
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      // In a real scenario, this might call a different chat endpoint
      // but for now we'll keep the terminology clean
      await ApiService.getGoals(); // Placeholder or actual chat logic

      setState(() {
        _messages.add(
          const ChatMessage(
            sender: MessageSender.ai,
            text:
                "I'm here to help you navigate your mission. Feel free to ask about your tasks or milestones!",
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            sender: MessageSender.ai,
            text: 'Sorry, I encountered an error: $e',
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      appBar: AppBar(title: const Text('AI Coach'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _MessageBubble(msg: msg);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            _ChatInputBar(controller: _inputController, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAi = msg.sender == MessageSender.ai;
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAi
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: isAi
              ? Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                )
              : null,
        ),
        child: Text(
          msg.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isAi ? theme.colorScheme.onSurface : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LucideIcons.send,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
