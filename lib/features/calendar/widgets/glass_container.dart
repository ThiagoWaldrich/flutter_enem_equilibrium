import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color color;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(12.0),
    this.borderRadius = 20.0,
    this.blur = 6.0,
    this.opacity = 0.03,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.7,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}