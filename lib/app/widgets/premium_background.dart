import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({
    required this.child,
    this.overlayOpacity = 0.7,
    super.key,
  });

  final Widget child;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF0A0E16), Color(0xFF191422)],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: _GlowOrb(
            size: 220,
            color: const Color(0xFFE55B79).withValues(alpha: 0.2),
          ),
        ),
        Positioned(
          left: -70,
          bottom: -60,
          child: _GlowOrb(
            size: 260,
            color: const Color(0xFF5A7DFF).withValues(alpha: 0.16),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: overlayOpacity * 0.22)),
        child,
      ],
    );
  }
}

class PremiumGlassCard extends StatelessWidget {
  const PremiumGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 18,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x2AFFFFFF),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: 110, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}
