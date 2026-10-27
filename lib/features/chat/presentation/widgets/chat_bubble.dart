import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: isUser ? .end : .start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16)),
              ),
            ),
            Text(isUser ? "You" : "Support"),
          ],
        ),
      ),
    );
  }
}
