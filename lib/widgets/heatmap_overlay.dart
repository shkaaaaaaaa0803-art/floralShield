import 'package:flutter/material.dart';

/// Draws a Grad-CAM-style radial heat glow over the affected region
/// identified by the AI. This is a simplified visual approximation
/// (not a true pixel-level Grad-CAM from a trained model) but is based
/// on the AI's own estimate of where the disease is concentrated.
class HeatmapOverlay extends StatelessWidget {
  final double regionX; // 0.0-1.0
  final double regionY; // 0.0-1.0
  final double regionRadius; // 0.0-1.0

  const HeatmapOverlay({
    super.key,
    required this.regionX,
    required this.regionY,
    required this.regionRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _HeatmapPainter(
            regionX: regionX,
            regionY: regionY,
            regionRadius: regionRadius,
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final double regionX;
  final double regionY;
  final double regionRadius;

  _HeatmapPainter({
    required this.regionX,
    required this.regionY,
    required this.regionRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(regionX * size.width, regionY * size.height);
    final effectiveRadius = (regionRadius * size.shortestSide).clamp(20.0, size.shortestSide);

    // Multi-stop radial gradient: red-hot center fading through
    // orange/yellow to transparent, like a thermal camera view.
    final gradient = RadialGradient(
      colors: [
        Colors.red.withOpacity(0.75),
        Colors.deepOrange.withOpacity(0.55),
        Colors.orange.withOpacity(0.35),
        Colors.yellow.withOpacity(0.15),
        Colors.yellow.withOpacity(0.0),
      ],
      stops: const [0.0, 0.35, 0.6, 0.85, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: effectiveRadius);
    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawCircle(center, effectiveRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.regionX != regionX ||
        oldDelegate.regionY != regionY ||
        oldDelegate.regionRadius != regionRadius;
  }
}