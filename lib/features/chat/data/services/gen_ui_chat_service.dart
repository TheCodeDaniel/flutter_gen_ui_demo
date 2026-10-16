import 'package:firebase_ai/firebase_ai.dart' show ChatSession, Content, FirebaseAI, StartChatExtension;
import 'package:genui/genui.dart';

// Fast, free-tier friendly Gemini model served through Firebase AI Logic
const String _geminiModel = 'gemini-3.5-flash-lite';

/// Wires the GenUI pieces (catalog, surface controller, transport, conversation)
/// to Gemini via Firebase AI Logic.
class GenUiChatService {
  GenUiChatService() {
    catalog = BasicCatalogItems.asCatalog();
    controller = SurfaceController(catalogs: [catalog]);
    transport = A2uiTransportAdapter(onSend: _sendToGemini);
    conversation = Conversation(controller: controller, transport: transport);

    // The prompt builder teaches the model the A2UI protocol and our widget catalog
    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [
        'You are a friendly assistant in a GenUI demo app. '
            'Whenever it helps, answer with rich UI built from the widget catalog '
            '(cards, lists, rows, buttons, choice pickers, sliders, text fields...) '
            'instead of plain text. Keep any plain text short.',
        PromptFragments.acknowledgeUser(),
        PromptFragments.requireAtLeastOneSubmitElement(prefix: PromptBuilder.defaultImportancePrefix),
        PromptFragments.uiGenerationRestriction(prefix: PromptBuilder.defaultImportancePrefix),
        PromptFragments.currentDate(),
      ],
    );

    _chatSession = FirebaseAI.googleAI()
        .generativeModel(
          model: _geminiModel,
          systemInstruction: Content.system(promptBuilder.systemPromptJoined()),
        )
        .startChat();
  }

  late final Catalog catalog;
  late final SurfaceController controller;
  late final A2uiTransportAdapter transport;
  late final Conversation conversation;

  // The chat session keeps the history, the transport only hands us the newest message
  late final ChatSession _chatSession;

  /// Sends a user prompt to the model.
  Future<void> sendMessage(String text) => conversation.sendRequest(ChatMessage.user(text));

  // Called by the transport for user prompts and for interactions with generated UI
  Future<void> _sendToGemini(ChatMessage message) async {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is TextPart) {
        buffer.write(part.text);
      }
    }
    if (buffer.isEmpty) return;

    // Stream the response so text and UI show up as soon as they arrive
    final responses = _chatSession.sendMessageStream(Content.text(buffer.toString()));
    await for (final response in responses) {
      final chunk = response.text;
      if (chunk != null && chunk.isNotEmpty) transport.addChunk(chunk);
    }
  }

  void dispose() {
    conversation.dispose();
    transport.dispose();
    controller.dispose();
  }
}
