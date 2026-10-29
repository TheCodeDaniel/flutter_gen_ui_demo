/// The web pages Gemini searched to answer, so users can check the prices.
class WebSources {
  final List<WebLink> links;

  // Google Search suggestions (HTML) that Google asks us to display
  final String? searchSuggestionsHtml;

  WebSources({required this.links, this.searchSuggestionsHtml});
}

class WebLink {
  final String title;
  final String url;

  WebLink({required this.title, required this.url});
}
