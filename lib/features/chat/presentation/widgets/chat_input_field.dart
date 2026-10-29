import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';

/// Where the user types what they want to cook.
class ChatInputField extends StatefulWidget {
  final void Function(String text) onSend;
  const ChatInputField({super.key, required this.onSend});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  TextEditingController userMessageController = TextEditingController();
  bool hasMessage = false;

  @override
  void initState() {
    super.initState();
    userMessageController.addListener(() {
      setState(() => hasMessage = userMessageController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    userMessageController.dispose();
    super.dispose();
  }

  void _send() {
    if (!hasMessage) return;
    widget.onSend(userMessageController.text.trim());
    userMessageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: userMessageController,
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: "Tell me what you want to cook...",
                prefixIcon: Icon(Iconsax.reserve, color: AppColors.muted),
              ),
            ),
          ),
          // Send button lights up once there's something to send
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(color: hasMessage ? AppColors.jollof : AppColors.outline, shape: BoxShape.circle),
            child: IconButton(
              onPressed: hasMessage ? _send : null,
              icon: Icon(Iconsax.send_1, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
