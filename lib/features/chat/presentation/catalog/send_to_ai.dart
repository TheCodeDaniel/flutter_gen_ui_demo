import 'package:genui/genui.dart';

/// Tells the AI the user did something in one of our cards,
/// e.g. sendToAi(itemContext, 'findCheaperOptions', {'items': [...]}).
///
/// GenUI turns this into a message for Gemini, which replies with the next UI.
void sendToAi(CatalogItemContext itemContext, String action, [Map<String, Object?> details = const {}]) {
  itemContext.dispatchEvent(UserActionEvent(name: action, sourceComponentId: itemContext.id, context: details));
}
