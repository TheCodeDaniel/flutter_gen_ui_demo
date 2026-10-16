import 'package:firebase_ai/firebase_ai.dart' show ChatSession, Content, FirebaseAI, StartChatExtension;
import 'package:genui/genui.dart';

/// Everything GenUI needs, in five steps.
class GenUiChatService {
  // 1. The catalog: the widgets the AI is allowed to build with
  final Catalog catalog = BasicCatalogItems.asCatalog();

  // 2. The controller: keeps track of every UI the AI generates
  late final SurfaceController controller = SurfaceController(catalogs: [catalog]);

  // 3. The transport: sends our messages out, turns the AI's replies into UI
  late final A2uiTransportAdapter transport = A2uiTransportAdapter(onSend: _sendToGemini);

  // 4. The conversation: ties the controller and transport together
  late final Conversation conversation = Conversation(controller: controller, transport: transport);

  // 5. Gemini, taught how to "speak GenUI" through the system prompt
  late final ChatSession gemini = FirebaseAI.googleAI()
      .generativeModel(model: 'gemini-3.5-flash-lite', systemInstruction: Content.system(_systemPrompt))
      .startChat();

  // The prompt builder explains our catalog and the GenUI protocol to the AI
  String get _systemPrompt => PromptBuilder.chat(
    catalog: catalog,
    systemPromptFragments: [
      'You are a friendly assistant. '
          'Answer with rich UI from the widget catalog whenever it helps. '
          'Keep plain text short.',
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

    // Stream the reply, so text and UI appear while Gemini is still writing
    await for (final reply in gemini.sendMessageStream(Content.text(userInput))) {
      transport.addChunk(reply.text ?? '');
    }
  }

  void dispose() {
    conversation.dispose();
    transport.dispose();
    controller.dispose();
  }
}
