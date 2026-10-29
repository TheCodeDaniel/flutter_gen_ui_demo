import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';

/// A text message: the user's request on the right, the chef's reply on the left.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return isUser ? _UserBubble(text: text) : _ChefBubble(text: text);
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.jollof,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }
}

class _ChefBubble extends StatelessWidget {
  final String text;
  const _ChefBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        ChefAvatar(),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Text(text.trim(), style: TextStyle(color: AppColors.ink, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

/// The AI's face in the app.
class ChefAvatar extends StatelessWidget {
  const ChefAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.pepper.withValues(alpha: 0.3),
      child: Text("👩🏾‍🍳", style: TextStyle(fontSize: 20)),
    );
  }
}
