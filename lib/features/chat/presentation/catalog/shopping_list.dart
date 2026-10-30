import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/format_price.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/send_to_ai.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// 1. The schema: tells the AI what data a ShoppingList needs
final _shoppingListSchema = S.object(
  description: 'A shopping list for a dish or basket, with real current prices from web search.',
  properties: {
    'dish': S.string(description: 'What is being cooked or bought, e.g. "Jollof rice".'),
    'emoji': S.string(description: 'One food emoji for the dish, e.g. "🍛".'),
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
      // The user wants to compare stores for these items
      onFindCheaper: (items) => sendToAi(itemContext, 'findCheaperOptions', {'items': items}),
      // The user is happy with the list and wants a shopping plan
      onPlanShopping: (items) => sendToAi(itemContext, 'planShopping', {'items': items}),
    );
  },
);

// 3. The data class: reads the AI's JSON
class ShoppingListData {
  final String dish;
  final String emoji;
  final int? servings;
  final String currencySymbol;
  final String? priceNote;
  final List<ShoppingItem> items;

  ShoppingListData({
    required this.dish,
    this.emoji = "🛒",
    this.servings,
    required this.currencySymbol,
    this.priceNote,
    required this.items,
  });

  factory ShoppingListData.fromJson(Map<String, Object?> json) {
    return ShoppingListData(
      dish: json['dish'] as String,
      emoji: json['emoji'] as String? ?? "🛒",
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
  final void Function(List<Map<String, Object?>> items) onFindCheaper;
  final void Function(List<Map<String, Object?>> items) onPlanShopping;

  const ShoppingListCard({super.key, required this.data, required this.onFindCheaper, required this.onPlanShopping});

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  // Items the user has already bought
  final Set<int> boughtItems = {};

  // Buttons switch off once the user has picked what to do next
  bool hasChosenNextStep = false;

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), for (int i = 0; i < items.length; i++) _buildItemRow(i), _buildFooter()],
      ),
    );
  }

  // Coloured banner with the dish, servings and where the prices are from
  Widget _buildHeader() {
    final data = widget.data;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.jollof, AppColors.pepper])),
      child: Row(
        spacing: 12,
        children: [
          Text(data.emoji, style: TextStyle(fontSize: 40)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.dish,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (data.servings != null)
                  Text("Serves ${data.servings} · ${items.length} items", style: TextStyle(color: Colors.white)),
                if (data.priceNote != null)
                  Text(data.priceNote!, style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // One ingredient, tap to tick it off while shopping
  Widget _buildItemRow(int index) {
    final item = items[index];
    final bool isBought = boughtItems.contains(index);

    return CheckboxListTile(
      value: isBought,
      onChanged: (_) => _toggleBought(index),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.leaf,
      title: Text(
        item.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: isBought ? TextDecoration.lineThrough : null,
          color: isBought ? AppColors.muted : AppColors.ink,
        ),
      ),
      subtitle: Text([item.quantity, ?item.store].join(" · "), style: TextStyle(fontSize: 12, color: AppColors.muted)),
      secondary: Text(
        formatPrice(widget.data.currencySymbol, item.price),
        style: TextStyle(fontWeight: FontWeight.bold, color: isBought ? AppColors.muted : AppColors.ink),
      ),
    );
  }

  // Live total + ask the AI for cheaper places to buy
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  "Left to buy",
                  style: TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text(
                  formatPrice(widget.data.currencySymbol, remainingTotal),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.leaf),
                ),
              ],
            ),
          ),

          // What next: compare stores, or go straight to the shopping plan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasChosenNextStep ? null : () => _nextStep(widget.onPlanShopping),
              icon: Icon(Iconsax.routing),
              label: Text("Plan my shopping"),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasChosenNextStep ? null : () => _nextStep(widget.onFindCheaper),
              icon: Icon(Iconsax.discount_shape),
              label: Text("Find cheaper options"),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep(void Function(List<Map<String, Object?>> items) action) {
    setState(() => hasChosenNextStep = true);
    action([
      for (final item in items)
        {'name': item.name, 'quantity': item.quantity, 'price': item.price, 'store': item.store},
    ]);
  }
}
