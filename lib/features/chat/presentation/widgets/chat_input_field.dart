import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
    return TextFormField(
      controller: userMessageController,
      onFieldSubmitted: (_) => _send(),
      textInputAction: TextInputAction.send,
      decoration: InputDecoration(
        contentPadding: .symmetric(horizontal: 16),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: .circular(26), borderSide: .none),
        hintText: "Say Hello...",
        hintStyle: TextStyle(fontSize: 20, height: 0),
        suffix: GestureDetector(onTap: _send, child: hasMessage ? Icon(Iconsax.send_1) : SizedBox.shrink()),
      ),
    );
  }
}
