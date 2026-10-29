import 'package:flutter/material.dart';

/// Fades and slides a widget up when it first appears,
/// so AI-generated UI "arrives" instead of popping in.
class AppearAnimation extends StatelessWidget {
  final Widget child;
  const AppearAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(offset: Offset(0, 24 * (1 - progress)), child: child),
      ),
    );
  }
}
