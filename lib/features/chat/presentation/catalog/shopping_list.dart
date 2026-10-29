import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/format_price.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// 1. The schema: tells the AI what data a ShoppingList needs
final _shoppingListSchema = S.object(
  description: 'A shopping list for a dish or basket, with real current prices from web search.',
  properties: {
    'dish': S.string(description: 'What is being cooked or bought, e.g. "Jollof rice".'),
    'servings': S.integer(description: 'How many people it serves.'),
    'currencySymbol': S.string(description: 'Local currency symbol, e.g. "₦".'),
    'priceNote': S.string(description: 'Where and when the prices are from, e.g. "Lagos markets, Oct 2026".'),
    'items': S.list(
      items: S.object(
        properties: {
          'name': S.string(description: 'Ingredient name.'),
          'quantity': S.string(description: 'How much to buy, e.g. "5kg" or "1 paint bucket".'),
          'price': S.number(description: 'Current price in the local currency.'),
          'store': S.string(description: 'Where this price is from, e.g. "Mile 12 market" or "Jumia".'),
        },
        required: ['name', 'quantity', 'price'],
      ),
    ),
  },
  required: ['dish', 'currencySymbol', 'items'],
);

// 2. The catalog item: connects the schema to a Flutter widget
final shoppingList = CatalogItem(
  name: 'ShoppingList',
  dataSchema: _shoppingListSchema,
  widgetBuilder: (itemContext) {
    final data = ShoppingListData.fromJson(itemContext.data as Map<String, Object?>);

    return ShoppingListCard(
      data: data,
      // Tell the AI the user wants cheaper options for these items
      onFindCheaper: (itemNames) => itemContext.dispatchEvent(
        UserActionEvent(name: 'findCheaperOptions', sourceComponentId: itemContext.id, context: {'items': itemNames}),
      ),
    );
  },
);

// 3. The data class: reads the AI's JSON
class ShoppingListData {
  final String dish;
  final int? servings;
  final String currencySymbol;
  final String? priceNote;
  final List<ShoppingItem> items;

  ShoppingListData({
    required this.dish,
    this.servings,
    required this.currencySymbol,
    this.priceNote,
    required this.items,
  });

  factory ShoppingListData.fromJson(Map<String, Object?> json) {
    return ShoppingListData(
      dish: json['dish'] as String,
      servings: (json['servings'] as num?)?.toInt(),
      currencySymbol: json['currencySymbol'] as String,
      priceNote: json['priceNote'] as String?,
      items: (json['items'] as List).map((item) => ShoppingItem.fromJson(item as Map<String, Object?>)).toList(),
    );
  }
}

class ShoppingItem {
  final String name;
  final String quantity;
  final num price;
  final String? store;

  ShoppingItem({required this.name, required this.quantity, required this.price, this.store});

  factory ShoppingItem.fromJson(Map<String, Object?> json) {
    return ShoppingItem(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      price: json['price'] as num,
      store: json['store'] as String?,
    );
  }
}

// 4. The widget: what the user actually sees
class ShoppingListCard extends StatefulWidget {
  final ShoppingListData data;
  final void Function(List<String> itemNames) onFindCheaper;

  const ShoppingListCard({super.key, required this.data, required this.onFindCheaper});

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  // Items the user has already bought
  final Set<int> boughtItems = {};

  List<ShoppingItem> get items => widget.data.items;

  // Total of everything still left to buy
  num get remainingTotal {
    num total = 0;
    for (int i = 0; i < items.length; i++) {
      if (!boughtItems.contains(i)) total += items[i].price;
    }
    return total;
  }

  void _toggleBought(int index) {
    setState(() => boughtItems.contains(index) ? boughtItems.remove(index) : boughtItems.add(index));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Iconsax.shopping_cart),
                SizedBox(width: 8),
                Expanded(
                  child: Text(data.dish, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (data.servings != null) Text("Serves ${data.servings}"),
              ],
            ),
            if (data.priceNote != null)
              Text(data.priceNote!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Divider(height: 24),

            // One row per ingredient, tap to tick it off
            for (int i = 0; i < items.length; i++)
              CheckboxListTile(
                value: boughtItems.contains(i),
                onChanged: (_) => _toggleBought(i),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.black,
                title: Text(
                  "${items[i].name} · ${items[i].quantity}",
                  style: TextStyle(decoration: boughtItems.contains(i) ? TextDecoration.lineThrough : null),
                ),
                subtitle: items[i].store != null ? Text(items[i].store!) : null,
                secondary: Text(
                  formatPrice(data.currencySymbol, items[i].price),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Divider(height: 24),

            // Live total
            Row(
              children: [
                Text("Left to buy", style: TextStyle(fontSize: 16)),
                Spacer(),
                Text(
                  formatPrice(data.currencySymbol, remainingTotal),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Ask the AI for cheaper places to buy
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onFindCheaper(items.map((item) => item.name).toList()),
                icon: Icon(Iconsax.discount_shape),
                label: Text("Find cheaper options"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
