import 'package:gen_ui_demo/features/chat/data/models/web_sources.dart';

/// One item in the chat: a user message, an AI message, an AI-generated UI,
/// or the web sources the AI used.
class ChatModel {
  String? id;
  final bool isUser;
  final String text;
  final String? surfaceId;
  final WebSources? sources;

  ChatModel({this.id, required this.isUser, this.text = "", this.surfaceId, this.sources});

  ChatModel.user(String text) : this(isUser: true, text: text);

  ChatModel.ai(String text) : this(isUser: false, text: text);

  ChatModel.surface(String surfaceId) : this(isUser: false, surfaceId: surfaceId);

  ChatModel.sources(WebSources sources) : this(isUser: false, sources: sources);

  bool get isSurface => surfaceId != null;

  bool get isSources => sources != null;

  bool get isAiText => !isUser && !isSurface && !isSources;
}
