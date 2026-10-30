import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/format_price.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/send_to_ai.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. The schema: tells the AI what data a ShoppingPlan needs
final _shoppingPlanSchema = S.object(
  description: 'The final shopping plan: every item grouped by the store to buy it from.',
  properties: {
    'dish': S.string(description: 'The dish, e.g. "Jollof rice".'),
    'emoji': S.string(description: 'One food emoji for the dish.'),
    'currencySymbol': S.string(description: 'Local currency symbol, e.g. "₦".'),
    'savings': S.number(description: 'How much the user saved by choosing cheaper stores (0 if none).'),
    'stops': S.list(
      description: 'One stop per store, in a sensible order to visit.',
      items: S.object(
        properties: {
          'store': S.string(description: 'Store or market name.'),
          'items': S.list(
            items: S.object(
              properties: {'name': S.string(), 'quantity': S.string(), 'price': S.number()},
              required: ['name', 'price'],
            ),
          ),
        },
        required: ['store', 'items'],
      ),
    ),
  },
  required: ['dish', 'currencySymbol', 'stops'],
);

// 2. The catalog item: connects the schema to a Flutter widget
final shoppingPlan = CatalogItem(
  name: 'ShoppingPlan',
  dataSchema: _shoppingPlanSchema,
  widgetBuilder: (itemContext) {
    final data = ShoppingPlanData.fromJson(itemContext.data as Map<String, Object?>);

    return ShoppingPlanCard(
      data: data,
      // The user wants to learn how to cook the dish
      onShowRecipe: () => sendToAi(itemContext, 'showRecipe', {'dish': data.dish}),
    );
  },
);

// 3. The data classes: read the AI's JSON
class ShoppingPlanData {
  final String dish;
  final String emoji;
  final String currencySymbol;
  final num savings;
  final List<ShoppingStop> stops;

  ShoppingPlanData({
    required this.dish,
    required this.emoji,
    required this.currencySymbol,
    required this.savings,
    required this.stops,
  });

  factory ShoppingPlanData.fromJson(Map<String, Object?> json) {
    return ShoppingPlanData(
      dish: json['dish'] as String,
      emoji: json['emoji'] as String? ?? "🛒",
      currencySymbol: json['currencySymbol'] as String,
      savings: json['savings'] as num? ?? 0,
      stops: (json['stops'] as List).map((stop) => ShoppingStop.fromJson(stop as Map<String, Object?>)).toList(),
    );
  }

  // Worked out on the phone, so the total always adds up
  num get total => stops.fold(0, (sum, stop) => sum + stop.total);
}

class ShoppingStop {
  final String store;
  final List<({String name, String? quantity, num price})> items;

  ShoppingStop({required this.store, required this.items});

  factory ShoppingStop.fromJson(Map<String, Object?> json) {
    return ShoppingStop(
      store: json['store'] as String,
      items: [
        for (final item in (json['items'] as List).cast<Map<String, Object?>>())
          (name: item['name'] as String, quantity: item['quantity'] as String?, price: item['price'] as num),
      ],
    );
  }

  num get total => items.fold(0, (sum, item) => sum + item.price);
}

// 4. The widget: what the user actually sees
class ShoppingPlanCard extends StatefulWidget {
  final ShoppingPlanData data;
  final VoidCallback onShowRecipe;

  const ShoppingPlanCard({super.key, required this.data, required this.onShowRecipe});

  @override
  State<ShoppingPlanCard> createState() => _ShoppingPlanCardState();
}

class _ShoppingPlanCardState extends State<ShoppingPlanCard> {
  bool hasAskedForRecipe = false;

  String price(num amount) => formatPrice(widget.data.currencySymbol, amount);

  // Opens WhatsApp with the whole plan ready to send
  void _shareOnWhatsApp() {
    final data = widget.data;
    final message = StringBuffer("${data.emoji} ${data.dish} shopping plan\n");
    for (final stop in data.stops) {
      message.writeln("\n📍 ${stop.store}");
      for (final item in stop.items) {
        message.writeln("• ${item.name} ${item.quantity ?? ''} — ${price(item.price)}");
      }
    }
    message.writeln("\nTotal: ${price(data.total)}");

    launchUrl(
      Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message.toString())}"),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green "ready" banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.leaf,
            child: Row(
              spacing: 12,
              children: [
                Text(data.emoji, style: TextStyle(fontSize: 40)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your shopping plan ✅", style: TextStyle(color: Colors.white70)),
                      Text(
                        data.dish,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // The route: one stop per store
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < data.stops.length; i++)
                  _StopTile(number: i + 1, stop: data.stops[i], price: price, isLast: i == data.stops.length - 1),
              ],
            ),
          ),

          // Total and savings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text("Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Spacer(),
                if (data.savings > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.pepper.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("You saved ${price(data.savings)} 🎉", style: TextStyle(fontSize: 12)),
                  ),
                Text(price(data.total), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // What next: share it, or learn to cook it
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 10,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasAskedForRecipe
                        ? null
                        : () {
                            setState(() => hasAskedForRecipe = true);
                            widget.onShowRecipe();
                          },
                    icon: Icon(Iconsax.book_1),
                    label: Text("How do I cook it?"),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _shareOnWhatsApp,
                    icon: Icon(Iconsax.send_2),
                    label: Text("Share on WhatsApp"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// One store on the route, with a numbered dot and a line to the next stop
class _StopTile extends StatelessWidget {
  final int number;
  final ShoppingStop stop;
  final String Function(num amount) price;
  final bool isLast;

  const _StopTile({required this.number, required this.stop, required this.price, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          // Route line
          Column(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.jollof,
                child: Text("$number", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              if (!isLast) Expanded(child: VerticalDivider(color: AppColors.outline, thickness: 2)),
            ],
          ),

          // Store and its items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(stop.store, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Text(price(stop.total), style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  for (final item in stop.items)
                    Text(
                      "${item.name}${item.quantity != null ? ' · ${item.quantity}' : ''}  ${price(item.price)}",
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
