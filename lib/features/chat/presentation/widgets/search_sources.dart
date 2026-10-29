import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/data/models/web_sources.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows the web pages the AI searched, so anyone can check the prices.
class SearchSources extends StatelessWidget {
  final WebSources sources;
  const SearchSources({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text("Sources", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final link in sources.links)
              ActionChip(
                avatar: Icon(Iconsax.link, size: 16),
                label: Text(link.title, style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey.shade200,
                onPressed: () => launchUrl(Uri.parse(link.url)),
              ),
          ],
        ),
        if (sources.searchSuggestionsHtml != null) _GoogleSearchSuggestions(html: sources.searchSuggestionsHtml!),
      ],
    );
  }
}

// Google requires apps using Search grounding to show these suggestions as-is
class _GoogleSearchSuggestions extends StatefulWidget {
  final String html;
  const _GoogleSearchSuggestions({required this.html});

  @override
  State<_GoogleSearchSuggestions> createState() => _GoogleSearchSuggestionsState();
}

class _GoogleSearchSuggestionsState extends State<_GoogleSearchSuggestions> {
  late final WebViewController webViewController = WebViewController()
    ..setBackgroundColor(Colors.transparent)
    ..setNavigationDelegate(
      NavigationDelegate(
        // Open tapped suggestions in the browser, not inside the chat
        onNavigationRequest: (request) {
          if (request.url.startsWith('http')) {
            launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadHtmlString('<meta name="viewport" content="width=device-width, initial-scale=1">${widget.html}');

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 70, child: WebViewWidget(controller: webViewController));
  }
}
