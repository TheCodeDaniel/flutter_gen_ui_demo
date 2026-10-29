import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart'
    show Candidate, ChatSession, Content, FirebaseAI, StartChatExtension, Tool;
import 'package:gen_ui_demo/features/chat/data/models/web_sources.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/market_catalog.dart';
import 'package:genui/genui.dart';

/// Everything GenUI needs, in six steps.
class GenUiChatService {
  // 1. The catalog: basic widgets + our ShoppingList and PriceComparison
  final Catalog catalog = marketCatalog;

  // 2. The controller: keeps track of every UI the AI generates
  late final SurfaceController controller = SurfaceController(catalogs: [catalog]);

  // 3. The transport: sends our messages out, turns the AI's replies into UI
  late final A2uiTransportAdapter transport = A2uiTransportAdapter(onSend: _sendToGemini);

  // 4. The conversation: ties the controller and transport together
  late final Conversation conversation = Conversation(controller: controller, transport: transport);

  // 5. Gemini, with Google Search so it can find REAL prices.
  //    It is created on the first message, so it already knows the user's location.
  late final ChatSession gemini = FirebaseAI.googleAI()
      .generativeModel(
        model: 'gemini-3.5-flash-lite',
        tools: [Tool.googleSearch()],
        systemInstruction: Content.system(_systemPrompt),
      )
      .startChat();

  // 6. Where the user is, e.g. "Ikeja, Lagos, Nigeria" (null if unknown)
  String? userLocation;

  // The web pages Gemini used for each reply
  final _sources = StreamController<WebSources>.broadcast();
  Stream<WebSources> get sources => _sources.stream;

  String get _systemPrompt => PromptBuilder.chat(
    catalog: catalog,
    systemPromptFragments: [
      '''
You are a friendly market shopping assistant for African shoppers.
The user tells you what they want to cook or buy, and you build them a shopping list.

PRICES:
- ALWAYS use Google Search to find CURRENT prices in the user's city before quoting any price.
- NEVER make up prices. If you can't find one, estimate it and say so in the priceNote.
- Compare open markets, supermarkets and online stores (for example Jumia, Chowdeck, Shoprite).
- Use the user's local currency, and mention price trends or inflation when the search shows them.

UI:
- For a recipe or basket, show a ShoppingList.
- When the user taps "Find cheaper options" (action "findCheaperOptions"), show a PriceComparison for the most expensive items.
- Keep plain text short and friendly.

LOCATION:
${userLocation != null ? 'The user is in $userLocation.' : 'The user\'s location is unknown. Before giving any prices, ask which city they are in using a ChoicePicker of major African cities (Lagos, Abuja, Port Harcourt, Ibadan, Kano, Accra, Nairobi), a TextField for other cities, and a submit Button.'}
''',
    ],
  ).systemPromptJoined();

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
