import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart'
    show
        Candidate,
        ChatSession,
        Content,
        FirebaseAI,
        GenerationConfig,
        StartChatExtension,
        ThinkingConfig,
        ThinkingLevel,
        Tool;
import 'package:gen_ui_demo/features/chat/data/models/web_sources.dart';
import 'package:gen_ui_demo/features/chat/data/services/system_prompt.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/market_catalog.dart';
import 'package:genui/genui.dart';

// Live Google Search needs billing on the Firebase project.
// Off = free tier, and the AI labels its prices as estimates.
const bool useLiveSearch = false;

/// Everything GenUI needs, in six steps.
class GenUiChatService {
  // 1. The catalog: basic widgets + our own cards (shopping list, prices, plan, recipe)
  final Catalog catalog = marketCatalog;

  // 2. The controller: keeps track of every UI the AI generates
  late final SurfaceController controller = SurfaceController(catalogs: [catalog]);

  // 3. The transport: sends our messages out, turns the AI's replies into UI
  late final A2uiTransportAdapter transport = A2uiTransportAdapter(onSend: _sendToGemini);

  // 4. The conversation: ties the controller and transport together
  late final Conversation conversation = Conversation(controller: controller, transport: transport);

  // 5. Gemini: the lightest free model, with Google Search when it's switched on.
  //    It is created on the first message, so it already knows the user's location.
  late ChatSession gemini = _startGemini();

  ChatSession _startGemini() => FirebaseAI.googleAI()
      .generativeModel(
        model: 'gemini-3.1-flash-lite',
        tools: [if (useLiveSearch) Tool.googleSearch()],
        // Minimal "thinking": faster replies and fewer tokens used
        generationConfig: GenerationConfig(thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.minimal)),
        systemInstruction: Content.system(
          buildSystemPrompt(catalog: catalog, useLiveSearch: useLiveSearch, userLocation: userLocation),
        ),
      )
      .startChat();

  // 6. Where the user is, e.g. "Ikeja, Lagos, Nigeria" (null if unknown)
  String? userLocation;

  // The web pages Gemini used for each reply
  final _sources = StreamController<WebSources>.broadcast();
  Stream<WebSources> get sources => _sources.stream;

  /// Forgets the conversation so the user can plan a new dish.
  void startNewDish() {
    gemini = _startGemini();
  }

  /// Sends what the user typed.
  Future<void> sendMessage(String text) {
    return conversation.sendRequest(ChatMessage.user(text));
  }

  // Called for typed messages AND for taps on AI-generated buttons
  Future<void> _sendToGemini(ChatMessage message) async {
    // Either text the user typed, or a description of what they tapped
    final String userInput = message.text.isNotEmpty
        ? message.text
        : message.parts.uiInteractionParts.first.interaction;

    WebSources? webSources;

    // Stream the reply, so text and UI appear while Gemini is still writing
    await for (final reply in gemini.sendMessageStream(Content.text(userInput))) {
      transport.addChunk(reply.text ?? '');
      webSources = _readWebSources(reply.candidates.firstOrNull) ?? webSources;
    }

    // Show the user where the prices came from
    if (webSources != null) _sources.add(webSources);
  }

  // Pulls the searched web pages out of Gemini's grounding data
  WebSources? _readWebSources(Candidate? candidate) {
    final grounding = candidate?.groundingMetadata;
    if (grounding == null || grounding.groundingChunks.isEmpty) return null;

    return WebSources(
      links: [
        for (final chunk in grounding.groundingChunks)
          if (chunk.web?.uri != null) WebLink(title: chunk.web!.title ?? chunk.web!.uri!, url: chunk.web!.uri!),
      ],
      searchSuggestionsHtml: grounding.searchEntryPoint?.renderedContent,
    );
  }

  void dispose() {
    _sources.close();
    conversation.dispose();
    transport.dispose();
    controller.dispose();
  }
}
