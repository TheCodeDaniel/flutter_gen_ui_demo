import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';

/// Top of the screen: a friendly greeting and where the user is shopping.
class KitchenHeader extends StatelessWidget {
  final String? city;
  final bool isLocating;

  // Shown once a conversation has started, to plan another dish
  final VoidCallback? onNewDish;

  const KitchenHeader({super.key, this.city, required this.isLocating, this.onNewDish});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$_greeting 👋", style: TextStyle(color: AppColors.muted)),
                // Shrinks a little if needed, so it always fits on one line
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "What are we cooking?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 6,
            children: [
              _LocationPill(city: city, isLocating: isLocating),
              if (onNewDish != null)
                TextButton.icon(
                  onPressed: onNewDish,
                  icon: Icon(Iconsax.add_circle, size: 18),
                  label: Text("New dish"),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Shows the user's city, "Locating..." while we look, or "Any city" if we can't tell
class _LocationPill extends StatelessWidget {
  final String? city;
  final bool isLocating;
  const _LocationPill({this.city, required this.isLocating});

  @override
  Widget build(BuildContext context) {
    // "Ikeja, Lagos, Nigeria" -> "Ikeja"
    final String label = isLocating ? "Locating..." : city?.split(',').first ?? "Any city";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Iconsax.location5, size: 16, color: AppColors.jollof),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
