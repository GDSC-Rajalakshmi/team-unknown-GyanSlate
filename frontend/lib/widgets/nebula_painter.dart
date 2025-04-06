import 'package:flutter/material.dart';
import 'dart:math';

class NebulaPainter extends CustomPainter {
  final double animation;

  NebulaPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42); // Fixed seed for consistent pattern
    
    // Draw nebula clouds
    for (int i = 0; i < 5; i++) {
      final xCenter = size.width * (0.2 + random.nextDouble() * 0.6);
      final yCenter = size.height * (0.2 + random.nextDouble() * 0.6);
      final radius = size.width * (0.2 + random.nextDouble() * 0.3);
      
      // Create a radial gradient for each nebula cloud
      final colors = [
        HSLColor.fromAHSL(
          0.2 + random.nextDouble() * 0.1,
          (220 + random.nextDouble() * 60 + animation * 30) % 360,
          0.7 + random.nextDouble() * 0.3,
          0.5 + random.nextDouble() * 0.3,
        ).toColor(),
        Colors.transparent,
      ];
      
      paint.shader = RadialGradient(
        colors: colors,
        stops: [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(xCenter, yCenter), radius: radius),
      );
      
      // Draw the nebula cloud
      canvas.drawCircle(Offset(xCenter, yCenter), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 