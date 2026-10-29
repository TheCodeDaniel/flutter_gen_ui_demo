import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/format_price.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. The schema: tells the AI what data a PriceComparison needs
final _priceComparisonSchema = S.object(
  description: 'Compares the current price of ONE item across open markets, supermarkets and online stores.',
  properties: {
    'item': S.string(description: 'The item being compared, e.g. "Rice (50kg bag)".'),
    'currencySymbol': S.string(description: 'Local currency symbol, e.g. "₦".'),
    'trend': S.string(description: 'Short price trend from the search, e.g. "Up 12% since September".'),
    'offers': S.list(
      items: S.object(
        properties: {
          'store': S.string(description: 'Store or market name.'),
          'storeType': S.string(enumValues: ['market', 'supermarket', 'online']),
          'price': S.number(description: 'Current price in the local currency.'),
          'url': S.string(description: 'Link to the product or source page, if available.'),
        },
        required: ['store', 'storeType', 'price'],
      ),
    ),
  },
  required: ['item', 'currencySymbol', 'offers'],
);

// 2. The catalog item: connects the schema to a Flutter widget
final priceComparison = CatalogItem(
  name: 'PriceComparison',
  dataSchema: _priceComparisonSchema,
  widgetBuilder: (itemContext) {
    final data = PriceComparisonData.fromJson(itemContext.data as Map<String, Object?>);
    return PriceComparisonCard(data: data);
  },
);

// 3. The data class: reads the AI's JSON
class PriceComparisonData {
  final String item;
  final String currencySymbol;
  final String? trend;
  final List<StoreOffer> offers;

  PriceComparisonData({required this.item, required this.currencySymbol, this.trend, required this.offers});

  factory PriceComparisonData.fromJson(Map<String, Object?> json) {
    final offers = (json['offers'] as List).map((offer) => StoreOffer.fromJson(offer as Map<String, Object?>)).toList();

    // Cheapest first
    offers.sort((a, b) => a.price.compareTo(b.price));

    return PriceComparisonData(
      item: json['item'] as String,
      currencySymbol: json['currencySymbol'] as String,
      trend: json['trend'] as String?,
      offers: offers,
    );
  }
}

class StoreOffer {
  final String store;
  final String storeType;
  final num price;
  final String? url;

  StoreOffer({required this.store, required this.storeType, required this.price, this.url});

  factory StoreOffer.fromJson(Map<String, Object?> json) {
    return StoreOffer(
      store: json['store'] as String,
      storeType: json['storeType'] as String,
      price: json['price'] as num,
      url: json['url'] as String?,
    );
  }

  IconData get icon => switch (storeType) {
    'market' => Iconsax.shop,
    'supermarket' => Iconsax.building,
    _ => Iconsax.global,
  };
}

// 4. The widget: what the user actually sees
class PriceComparisonCard extends StatelessWidget {
  final PriceComparisonData data;

  const PriceComparisonCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.item, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (data.trend != null)
              Text("📈 ${data.trend}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            SizedBox(height: 8),

            // Offers, cheapest first
            for (final offer in data.offers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(offer.icon),
                title: Text(offer.store),
                subtitle: offer == data.offers.first
                    ? Text(
                        "Best price",
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                      )
                    : Text(offer.storeType),
                trailing: Text(
                  formatPrice(data.currencySymbol, offer.price),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Online offers open the store page
                onTap: offer.url == null ? null : () => launchUrl(Uri.parse(offer.url!)),
              ),
          ],
        ),
      ),
    );
  }
}
