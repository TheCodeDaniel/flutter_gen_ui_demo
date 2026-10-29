import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
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

  // Each kind of store gets its own colour
  Color get color => switch (storeType) {
    'market' => AppColors.jollof,
    'supermarket' => AppColors.leaf,
    _ => Colors.blue.shade700,
  };
}

// 4. The widget: what the user actually sees
class PriceComparisonCard extends StatelessWidget {
  final PriceComparisonData data;

  const PriceComparisonCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            // Header: the item and how its price is moving
            Row(
              spacing: 8,
              children: [
                Icon(Iconsax.discount_shape, color: AppColors.jollof),
                Expanded(
                  child: Text(data.item, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (data.trend != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pepper.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("📈 ${data.trend}", style: TextStyle(fontSize: 12, color: AppColors.ink)),
              ),

            // Offers, cheapest first
            for (final offer in data.offers)
              _OfferTile(offer: offer, currencySymbol: data.currencySymbol, isBestPrice: offer == data.offers.first),
          ],
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final StoreOffer offer;
  final String currencySymbol;
  final bool isBestPrice;

  const _OfferTile({required this.offer, required this.currencySymbol, required this.isBestPrice});

  @override
  Widget build(BuildContext context) {
    return Material(
      // The best price stands out in green
      color: isBestPrice ? AppColors.leaf.withValues(alpha: 0.1) : AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isBestPrice ? AppColors.leaf : Colors.transparent),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: offer.color.withValues(alpha: 0.15),
          child: Icon(offer.icon, color: offer.color, size: 20),
        ),
        title: Text(offer.store, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isBestPrice ? "Best price · ${offer.storeType}" : offer.storeType,
          style: TextStyle(
            fontSize: 12,
            color: isBestPrice ? AppColors.leaf : AppColors.muted,
            fontWeight: isBestPrice ? FontWeight.bold : null,
          ),
        ),
        trailing: Text(
          formatPrice(currencySymbol, offer.price),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // Online offers open the store page
        onTap: offer.url == null ? null : () => launchUrl(Uri.parse(offer.url!)),
      ),
    );
  }
}
