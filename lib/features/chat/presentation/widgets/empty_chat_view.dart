import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Tap one of these instead of typing on stage
const _starterPrompts = [
  "Jollof rice for 10 people",
  "Egusi soup for my family of 5",
  "A week of foodstuff for ₦50,000",
];

class EmptyChatView extends StatelessWidget {
  final void Function(String text) onPromptTap;
  const EmptyChatView({super.key, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        spacing: 10,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Iconsax.shopping_cart, size: 40, color: Colors.black),
          ),
          Text("What are we cooking?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          for (final prompt in _starterPrompts)
            ActionChip(
              label: Text(prompt),
              backgroundColor: Colors.grey.shade200,
              onPressed: () => onPromptTap(prompt),
            ),
        ],
      ),
    );
  }
}
