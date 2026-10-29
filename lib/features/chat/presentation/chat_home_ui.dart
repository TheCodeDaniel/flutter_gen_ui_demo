import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/data/models/chat_model.dart';
import 'package:gen_ui_demo/features/chat/data/services/gen_ui_chat_service.dart';
import 'package:gen_ui_demo/features/chat/data/services/location_service.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/empty_chat_view.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/search_sources.dart';
import 'package:genui/genui.dart';

class ChatHomeUi extends StatefulWidget {
  const ChatHomeUi({super.key});

  @override
  State<ChatHomeUi> createState() => _ChatHomeUiState();
}

class _ChatHomeUiState extends State<ChatHomeUi> {
  final GenUiChatService chatService = GenUiChatService();
  final scrollController = ScrollController();

  List<ChatModel> chatMessages = [];
  String? userCity;

  @override
  void initState() {
    super.initState();
    // Listen to everything the AI sends back
    chatService.conversation.events.listen(_onConversationEvent);

    // Show the web pages the AI used for its prices
    chatService.sources.listen((sources) => _addToChat(ChatModel.sources(sources)));

    // Find the user's city, so prices match where they live
    LocationService.getUserCity().then((city) {
      if (!mounted) return;
      chatService.userLocation = city;
      setState(() => userCity = city);
    });
  }

  @override
  void dispose() {
    chatService.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    _addToChat(ChatModel.user(text));
    chatService.sendMessage(text);
  }

  void _onConversationEvent(ConversationEvent event) {
    switch (event) {
      // The AI wrote some text
      case ConversationContentReceived():
        _onAiText(event.text);

      // The AI built a new piece of UI
      case ConversationSurfaceAdded():
        _addToChat(ChatModel.surface(event.surfaceId));

      // Something went wrong
      case ConversationError():
        debugPrint("GenUI error: ${event.error}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong, please try again.")));

      default:
        break;
    }
  }

  // Text streams in small chunks, so keep adding to the AI's latest bubble
  void _onAiText(String text) {
    if (chatMessages.isNotEmpty && chatMessages.last.isAiText) {
      setState(() => chatMessages.last = ChatModel.ai(chatMessages.last.text + text));
    } else if (text.trim().isNotEmpty) {
      _addToChat(ChatModel.ai(text.trimLeft()));
    }
  }

  void _addToChat(ChatModel message) {
    setState(() => chatMessages.add(message));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text("Market Shopper"),
            if (userCity != null) Text("📍 $userCity", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: chatMessages.isEmpty
                    ? EmptyChatView(onPromptTap: _sendMessage)
                    : ListView.separated(
                        physics: BouncingScrollPhysics(),
                        controller: scrollController,
                        separatorBuilder: (_, i) => SizedBox(height: 10),
                        itemCount: chatMessages.length,
                        itemBuilder: (_, index) => _buildChatItem(chatMessages[index]),
                      ),
              ),
              _buildLoadingIndicator(),
              ChatInputField(onSend: _sendMessage),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatModel message) {
    // AI-generated UI is rendered by GenUI's Surface widget
    if (message.isSurface) {
      return Surface(surfaceContext: chatService.controller.contextFor(message.surfaceId!));
    }
    if (message.isSources) {
      return SearchSources(sources: message.sources!);
    }
    return ChatBubble(isUser: message.isUser, text: message.text);
  }

  // A thin progress bar while the AI is thinking
  Widget _buildLoadingIndicator() {
    return ValueListenableBuilder(
      valueListenable: chatService.conversation.state,
      builder: (_, state, _) {
        if (!state.isWaiting) return SizedBox(height: 18);
        return Padding(
          padding: const .symmetric(vertical: 8),
          child: LinearProgressIndicator(minHeight: 2, color: Colors.black, backgroundColor: Colors.grey.shade200),
        );
      },
    );
  }
}
