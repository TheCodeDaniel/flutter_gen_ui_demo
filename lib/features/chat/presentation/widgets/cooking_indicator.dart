import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:gen_ui_demo/features/chat/presentation/widgets/chat_bubble.dart';

/// Shown while the AI works: the chef "talks" through what she's doing.
class CookingIndicator extends StatefulWidget {
  const CookingIndicator({super.key});

  @override
  State<CookingIndicator> createState() => _CookingIndicatorState();
}

class _CookingIndicatorState extends State<CookingIndicator> {
  static const _steps = [
    "Checking today's market prices...",
    "Comparing stores near you...",
    "Writing your shopping list...",
  ];

  int stepIndex = 0;
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    // Move to the next step every few seconds
    timer = Timer.periodic(Duration(seconds: 3), (_) {
      setState(() => stepIndex = (stepIndex + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        spacing: 10,
        children: [
          ChefAvatar(),
          SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          Expanded(
            child: AnimatedSwitcher(
              // Old text fades out fully before the new one fades in
              duration: Duration(milliseconds: 400),
              switchInCurve: Interval(0.5, 1),
              switchOutCurve: Interval(0.5, 1),
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
              child: Text(
                _steps[stepIndex],
                key: ValueKey(stepIndex),
                style: TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
