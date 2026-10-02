import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/data/models/chat_model.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:iconsax/iconsax.dart';

class ChatHomeUi extends StatefulWidget {
  const ChatHomeUi({super.key});

  @override
  State<ChatHomeUi> createState() => _ChatHomeUiState();
}

class _ChatHomeUiState extends State<ChatHomeUi> {
  List<ChatModel> chatMessages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 16),
          child: Column(
            children: [
              if (chatMessages.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: .center,
                      spacing: 10,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(Iconsax.message, size: 40, color: Colors.black),
                        ),
                        Text("Write Something in the text field"),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (_, i) => SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final ChatModel message = chatMessages[index];
                      return ChatBubble(isUser: message.isUser, text: message.text);
                    },
                    itemCount: chatMessages.length,
                    shrinkWrap: true,
                  ),
                ),

              TextFormField(
                decoration: InputDecoration(
                  contentPadding: .symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: .circular(26), borderSide: .none),
                  hintText: "Say Hello...",
                  hintStyle: TextStyle(fontSize: 20, height: 0),
                  suffix: Icon(Iconsax.send_1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
