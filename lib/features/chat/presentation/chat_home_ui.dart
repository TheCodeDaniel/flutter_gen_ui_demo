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
  TextEditingController userMessageController = TextEditingController();
  bool hasMessage = false;

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    userMessageController.addListener(() {
      if (userMessageController.text.isNotEmpty) {
        setState(() => hasMessage = true);
      } else {
        setState(() => hasMessage = false);
      }
    });
  }

  List<ChatModel> chatMessages = [];

  void _sendMessage() {
    setState(() {});
    chatMessages.add(ChatModel(isUser: true, text: userMessageController.text));
    userMessageController.clear();
    if (chatMessages.length > 2) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, centerTitle: true, title: Text("GenUi Example")),
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
                        Text("Send. A. Message."),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    physics: BouncingScrollPhysics(),
                    controller: scrollController,
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
                controller: userMessageController,
                decoration: InputDecoration(
                  contentPadding: .symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: .circular(26), borderSide: .none),
                  hintText: "Say Hello...",
                  hintStyle: TextStyle(fontSize: 20, height: 0),
                  suffix: GestureDetector(
                    onTap: _sendMessage,
                    child: hasMessage ? Icon(Iconsax.send_1) : SizedBox.shrink(),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
