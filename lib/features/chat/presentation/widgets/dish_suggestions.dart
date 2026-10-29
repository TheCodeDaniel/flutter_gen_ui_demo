import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';

/// A dish the user can tap instead of typing (handy on stage).
class _Dish {
  final String emoji;
  final String name;
  final String detail;
  final String prompt;
  final Color color;

  const _Dish({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.prompt,
    required this.color,
  });
}

const _dishes = [
  _Dish(
    emoji: "🍛",
    name: "Party Jollof",
    detail: "Serves 10",
    prompt: "Jollof rice for 10 people",
    color: Color(0xFFFFE3D6),
  ),
  _Dish(
    emoji: "🥣",
    name: "Egusi Soup",
    detail: "Family of 5",
    prompt: "Egusi soup for my family of 5",
    color: Color(0xFFE2F1E6),
  ),
  _Dish(
    emoji: "🧺",
    name: "Weekly Foodstuff",
    detail: "₦50,000 budget",
    prompt: "A week of foodstuff for ₦50,000",
    color: Color(0xFFFFF0CC),
  ),
  _Dish(
    emoji: "🍲",
    name: "Pepper Soup",
    detail: "Serves 4",
    prompt: "Goat meat pepper soup for 4 people",
    color: Color(0xFFFBE0E0),
  ),
];

/// The first screen: pick a dish and the AI builds your shopping list.
class DishSuggestions extends StatelessWidget {
  final void Function(String prompt) onDishTap;
  const DishSuggestions({super.key, required this.onDishTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Popular today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(
          "Tap a dish and I'll build your shopping list with today's market prices.",
          style: TextStyle(color: AppColors.muted),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [for (final dish in _dishes) _DishCard(dish: dish, onTap: () => onDishTap(dish.prompt))],
        ),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  final _Dish dish;
  final VoidCallback onTap;
  const _DishCard({required this.dish, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dish.color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dish.emoji, style: TextStyle(fontSize: 44)),
              Spacer(),
              Text(
                dish.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              Text(dish.detail, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
