import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return ChatMessageView(text: text, icon: isUser ? Icons.person : Icons.person_2, alignment: isUser ? .end : .start);
  }
}
