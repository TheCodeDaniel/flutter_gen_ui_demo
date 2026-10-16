import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/data/models/chat_model.dart';
import 'package:gen_ui_demo/features/chat/data/services/gen_ui_chat_service.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:genui/genui.dart';
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

  final GenUiChatService chatService = GenUiChatService();
  late final StreamSubscription<ConversationEvent> _eventsSubscription;

  // True when the next text chunk from the AI should start a new bubble
  bool _startNewAiBubble = true;

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

    _eventsSubscription = chatService.conversation.events.listen(_onConversationEvent);
  }

  @override
  void dispose() {
    _eventsSubscription.cancel();
    chatService.dispose();
    userMessageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  List<ChatModel> chatMessages = [];

  void _onConversationEvent(ConversationEvent event) {
    switch (event) {
      case ConversationWaiting():
        _startNewAiBubble = true;
      case ConversationContentReceived(:final text):
        _onTextReceived(text);
      case ConversationSurfaceAdded(:final surfaceId):
        setState(() => chatMessages.add(ChatModel(isUser: false, surfaceId: surfaceId)));
        _startNewAiBubble = true;
        _scrollToBottom();
      case ConversationSurfaceRemoved(:final surfaceId):
        setState(() => chatMessages.removeWhere((message) => message.surfaceId == surfaceId));
      case ConversationError(:final error):
        debugPrint("GenUI conversation error: $error");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong, please try again.")));
      case ConversationComponentsUpdated():
        break;
    }
  }

  // Text arrives in streamed chunks, so merge them into the current AI bubble
  void _onTextReceived(String text) {
    final ChatModel? last = chatMessages.isEmpty ? null : chatMessages.last;
    final bool canAppend = !_startNewAiBubble && last != null && !last.isUser && !last.isSurface;

    if (canAppend) {
      setState(() => chatMessages.last = ChatModel(isUser: false, text: last.text + text));
    } else {
      if (text.trim().isEmpty) return;
      setState(() => chatMessages.add(ChatModel(isUser: false, text: text.trimLeft())));
      _startNewAiBubble = false;
    }
    _scrollToBottom();
  }

  void _sendMessage() {
    final String text = userMessageController.text.trim();
    if (text.isEmpty) return;

    setState(() => chatMessages.add(ChatModel(isUser: true, text: text)));
    userMessageController.clear();
    _scrollToBottom();

    chatService.sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
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
                      if (message.isSurface) {
                        return Surface(surfaceContext: chatService.controller.contextFor(message.surfaceId!));
                      }
                      return ChatBubble(isUser: message.isUser, text: message.text);
                    },
                    itemCount: chatMessages.length,
                    shrinkWrap: true,
                  ),
                ),

              // Shows while the AI is working on a response
              ValueListenableBuilder<ConversationState>(
                valueListenable: chatService.conversation.state,
                builder: (_, state, _) => state.isWaiting
                    ? Padding(
                        padding: const .symmetric(vertical: 8),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: Colors.black,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      )
                    : SizedBox(height: 18),
              ),

              TextFormField(
                controller: userMessageController,
                onFieldSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
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
