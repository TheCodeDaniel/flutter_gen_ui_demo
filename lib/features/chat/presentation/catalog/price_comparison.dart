import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/format_price.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/send_to_ai.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// 1. The schema: tells the AI what data a PriceComparison needs
final _priceComparisonSchema = S.object(
  description:
      'Compares prices of a few items across open markets, supermarkets and online stores. ONE card for all items.',
  properties: {
    'currencySymbol': S.string(description: 'Local currency symbol, e.g. "₦".'),
    'comparisons': S.list(
      items: S.object(
        properties: {
          'item': S.string(description: 'The item being compared, e.g. "Rice (5kg)".'),
          'trend': S.string(description: 'Short price trend, e.g. "Stable in open markets".'),
          'offers': S.list(
            items: S.object(
              properties: {
                'store': S.string(description: 'Store or market name.'),
                'storeType': S.string(enumValues: ['market', 'supermarket', 'online']),
                'price': S.number(description: 'Price in the local currency.'),
              },
              required: ['store', 'storeType', 'price'],
            ),
          ),
        },
        required: ['item', 'offers'],
      ),
    ),
  },
  required: ['currencySymbol', 'comparisons'],
);

// 2. The catalog item: connects the schema to a Flutter widget
final priceComparison = CatalogItem(
  name: 'PriceComparison',
  dataSchema: _priceComparisonSchema,
  widgetBuilder: (itemContext) {
    final data = PriceComparisonData.fromJson(itemContext.data as Map<String, Object?>);

    return PriceComparisonCard(
      data: data,
      // Tell the AI which store the user picked for each item
      onPricesChosen: (choices) => sendToAi(itemContext, 'pricesChosen', {'choices': choices}),
    );
  },
);

// 3. The data classes: read the AI's JSON
class PriceComparisonData {
  final String currencySymbol;
  final List<ItemComparison> comparisons;

  PriceComparisonData({required this.currencySymbol, required this.comparisons});

  factory PriceComparisonData.fromJson(Map<String, Object?> json) {
    return PriceComparisonData(
      currencySymbol: json['currencySymbol'] as String,
      comparisons: (json['comparisons'] as List)
          .map((comparison) => ItemComparison.fromJson(comparison as Map<String, Object?>))
          .toList(),
    );
  }
}

class ItemComparison {
  final String item;
  final String? trend;
  final List<StoreOffer> offers;

  ItemComparison({required this.item, this.trend, required this.offers});

  factory ItemComparison.fromJson(Map<String, Object?> json) {
    final offers = (json['offers'] as List).map((offer) => StoreOffer.fromJson(offer as Map<String, Object?>)).toList();

    // Cheapest first
    offers.sort((a, b) => a.price.compareTo(b.price));

    return ItemComparison(item: json['item'] as String, trend: json['trend'] as String?, offers: offers);
  }
}

class StoreOffer {
  final String store;
  final String storeType;
  final num price;

  StoreOffer({required this.store, required this.storeType, required this.price});

  factory StoreOffer.fromJson(Map<String, Object?> json) {
    return StoreOffer(
      store: json['store'] as String,
      storeType: json['storeType'] as String,
      price: json['price'] as num,
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
class PriceComparisonCard extends StatefulWidget {
  final PriceComparisonData data;
  final void Function(List<Map<String, Object?>> choices) onPricesChosen;

  const PriceComparisonCard({super.key, required this.data, required this.onPricesChosen});

  @override
  State<PriceComparisonCard> createState() => _PriceComparisonCardState();
}

class _PriceComparisonCardState extends State<PriceComparisonCard> {
  // Which store is picked for each item, by its position in the list.
  // 0 = the cheapest, because offers are sorted cheapest first.
  // (Positions, not objects: GenUI may rebuild the card with freshly parsed data.)
  late final List<int> chosenOfferIndexes = List.filled(widget.data.comparisons.length, 0);

  bool isSubmitted = false;

  void _submit() {
    setState(() => isSubmitted = true);
    widget.onPricesChosen([
      for (int i = 0; i < chosenOfferIndexes.length; i++)
        {
          'item': widget.data.comparisons[i].item,
          'store': widget.data.comparisons[i].offers[chosenOfferIndexes[i]].store,
          'price': widget.data.comparisons[i].offers[chosenOfferIndexes[i]].price,
        },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final comparisons = widget.data.comparisons;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(Iconsax.discount_shape, color: AppColors.jollof),
                Text("Pick where to buy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),

            // One section per item: tap a store to choose it
            for (int i = 0; i < comparisons.length; i++) ...[
              Text(comparisons[i].item, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              if (comparisons[i].trend != null)
                Text("📈 ${comparisons[i].trend}", style: TextStyle(fontSize: 12, color: AppColors.muted)),
              for (int o = 0; o < comparisons[i].offers.length; o++)
                _OfferTile(
                  offer: comparisons[i].offers[o],
                  currencySymbol: widget.data.currencySymbol,
                  isBestPrice: o == 0,
                  isChosen: o == chosenOfferIndexes[i],
                  onTap: isSubmitted ? null : () => setState(() => chosenOfferIndexes[i] = o),
                ),
            ],

            // Move on to the shopping plan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubmitted ? null : _submit,
                icon: Icon(isSubmitted ? Iconsax.tick_circle : Iconsax.receipt_item),
                label: Text(isSubmitted ? "Prices chosen" : "Use these prices"),
              ),
            ),
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
  final bool isChosen;
  final VoidCallback? onTap;

  const _OfferTile({
    required this.offer,
    required this.currencySymbol,
    required this.isBestPrice,
    required this.isChosen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // The chosen store is highlighted in green
      color: isChosen ? AppColors.leaf.withValues(alpha: 0.1) : AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isChosen ? AppColors.leaf : Colors.transparent),
      ),
      child: ListTile(
        onTap: onTap,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(formatPrice(currencySymbol, offer.price), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Icon(
              isChosen ? Iconsax.tick_circle5 : Iconsax.record,
              color: isChosen ? AppColors.leaf : AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
