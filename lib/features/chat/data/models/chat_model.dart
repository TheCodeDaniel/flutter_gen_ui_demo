class ChatModel {
  String? id;
  final bool isUser;
  final String text;

  // Set when this item is a generated UI surface instead of a text message
  final String? surfaceId;

  ChatModel({this.id, required this.isUser, this.text = "", this.surfaceId});

  bool get isSurface => surfaceId != null;
}
