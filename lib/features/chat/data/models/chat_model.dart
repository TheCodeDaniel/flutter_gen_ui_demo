/// One item in the chat: a user message, an AI message, or an AI-generated UI.
class ChatModel {
  String? id;
  final bool isUser;
  final String text;
  final String? surfaceId;

  ChatModel({this.id, required this.isUser, this.text = "", this.surfaceId});

  ChatModel.user(String text) : this(isUser: true, text: text);

  ChatModel.ai(String text) : this(isUser: false, text: text);

  ChatModel.surface(String surfaceId) : this(isUser: false, surfaceId: surfaceId);

  bool get isSurface => surfaceId != null;

  bool get isAiText => !isUser && !isSurface;
}
