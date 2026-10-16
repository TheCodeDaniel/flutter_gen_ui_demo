import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class EmptyChatView extends StatelessWidget {
  const EmptyChatView({super.key});

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
            child: Icon(Iconsax.message, size: 40, color: Colors.black),
          ),
          Text("Send. A. Message."),
        ],
      ),
    );
  }
}
