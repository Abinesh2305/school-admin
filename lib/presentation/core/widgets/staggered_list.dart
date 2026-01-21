import 'package:flutter/material.dart';

/// Helper for creating staggered list item animations
class StaggeredListBuilder {
  /// Build a list with staggered fade-in animations
  static Widget build<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    int? itemCount,
  }) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      physics: physics,
      itemCount: itemCount ?? items.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// Animated list item wrapper
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 0),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}




