import 'dart:convert';

import 'package:genui/genui.dart';

/// Builds the instructions Gemini gets before every conversation.
///
/// It has two parts:
///   1. Our own instructions (who the AI is, how to price, which widgets to use)
///   2. GenUI's part, made by [PromptBuilder]: the widget catalog and the
///      JSON format the AI must use to build UI
String buildSystemPrompt({required Catalog catalog, required bool useLiveSearch, String? userLocation}) {
  final String ourInstructions =
      '''
You are a friendly market shopping assistant for African shoppers.
The user tells you what they want to cook or buy, and you build them a shopping list.

PRICES:
${useLiveSearch ? _livePriceRules : _estimatedPriceRules}
- Compare open markets, supermarkets and online stores (for example Jumia, Chowdeck, Shoprite).
- Use the user's local currency.

UI:
- For a recipe or basket, show a ShoppingList with a fitting food emoji.
- When the user taps "Find cheaper options" (action "findCheaperOptions"), show a PriceComparison for the most expensive items.
- Keep plain text short and friendly, like a Nigerian aunty who loves to cook.
- The ShoppingList already has a "Find cheaper options" button, so don't add extra buttons next to it.
- TextField values must be data bindings like {"path": "/city"}, never plain text like "/city".
- Give every input its own data path (e.g. the ChoicePicker "/pickedCity", the TextField "/typedCity").

LOCATION:
${userLocation != null ? 'The user is in $userLocation.' : _askForCity}
''';

  final Iterable<String> sections = PromptBuilder.chat(
    catalog: catalog,
    systemPromptFragments: [ourInstructions],
  ).systemPrompt();

  // GenUI pretty-prints its JSON schemas. Squashing them onto one line
  // removes thousands of spaces and newlines from every request.
  return sections.map(_compactJsonSection).join('\n\n');
}

const _livePriceRules = '''
- ALWAYS use Google Search to find CURRENT prices in the user's city before quoting any price.
- NEVER make up prices. If you can't find one, estimate it and say so in the priceNote.
- Mention price trends or inflation when the search shows them.''';

const _estimatedPriceRules = '''
- You can't search the web, so give your best realistic estimate of current prices in the user's city.
- ALWAYS start the priceNote with "Estimated prices", e.g. "Estimated prices · Lagos markets".''';

const _askForCity =
    "The user's location is unknown. Before giving any prices, ask which city they are in using "
    'a ChoicePicker of major African cities (Lagos, Abuja, Port Harcourt, Ibadan, Kano, Accra, Nairobi), '
    'a TextField for other cities, and a submit Button. '
    'The Button action MUST send the answers back in its context, exactly like this: '
    '{"event": {"name": "citySelected", "context": {"pickedCity": {"path": "/pickedCity"}, "typedCity": {"path": "/typedCity"}}}}';

// Sections look like "-----NAME_START-----\n{ ...json... }\n-----NAME_END-----"
final _jsonSection = RegExp(r'^(-----\w+_START-----)\n([\s\S]*)\n(-----\w+_END-----)$');

String _compactJsonSection(String section) {
  final match = _jsonSection.firstMatch(section);
  if (match == null) return section;

  try {
    final String compactJson = jsonEncode(jsonDecode(match[2]!));
    return '${match[1]}\n$compactJson\n${match[3]}';
  } on FormatException {
    return section; // Not JSON (plain text section), keep it as it is
  }
}
