import 'package:flutter/material.dart';

/// Utility class for common app animations
class AppAnimations {
  // Standard durations
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);

  // Standard curves
  static const Curve standard = Curves.easeInOut;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve bouncy = Curves.easeOutBack;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = smooth,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in animation
  static Widget slideIn({
    required Widget child,
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
    Duration duration = medium,
    Curve curve = smooth,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation
  static Widget scaleIn({
    required Widget child,
    double begin = 0.9,
    double end = 1.0,
    Duration duration = medium,
    Curve curve = smooth,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Page route transition
  static PageRouteBuilder<T> fadeRoute<T>({
    required Widget page,
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Slide route transition
  static PageRouteBuilder<T> slideRoute<T>({
    required Widget page,
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: smooth,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }
}

