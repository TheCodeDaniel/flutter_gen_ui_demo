import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return ChatMessageView(
      text: text,
      icon: isUser ? Iconsax.profile_circle : Iconsax.support,
      alignment: isUser ? .end : .start,
    );
  }
}
