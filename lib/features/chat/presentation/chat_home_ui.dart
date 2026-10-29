import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/data/models/chat_model.dart';
import 'package:gen_ui_demo/features/chat/data/services/gen_ui_chat_service.dart';
import 'package:gen_ui_demo/features/chat/data/services/location_service.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/appear_animation.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/cooking_indicator.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/dish_suggestions.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/kitchen_header.dart';
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
  bool isLocating = true;

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
      setState(() {
        userCity = city;
        isLocating = false;
      });
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
      body: SafeArea(
        child: Column(
          children: [
            KitchenHeader(city: userCity, isLocating: isLocating),

            // Dish suggestions first, then the conversation with the chef
            Expanded(
              child: chatMessages.isEmpty
                  ? DishSuggestions(onDishTap: _sendMessage)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: BouncingScrollPhysics(),
                      controller: scrollController,
                      separatorBuilder: (_, i) => SizedBox(height: 14),
                      itemCount: chatMessages.length,
                      itemBuilder: (_, index) => AppearAnimation(child: _buildChatItem(chatMessages[index])),
                    ),
            ),

            _buildCookingIndicator(),
            ChatInputField(onSend: _sendMessage),
          ],
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

  // The chef shows what she's doing while the AI is working
  Widget _buildCookingIndicator() {
    return ValueListenableBuilder(
      valueListenable: chatService.conversation.state,
      builder: (_, state, _) => state.isWaiting ? CookingIndicator() : SizedBox.shrink(),
    );
  }
}
