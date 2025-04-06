import 'package:flutter/material.dart';

class QuestionBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> questions;
  
  QuestionBoxPainter(this.questions);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    for (var question in questions) {
      final box = question['boundingBox'];
      final rect = Rect.fromLTWH(
        box['x'] * size.width,
        box['y'] * size.height,
        box['width'] * size.width,
        box['height'] * size.height,
      );
      
      // Draw rectangle around question
      canvas.drawRect(rect, paint);
      
      // Draw question number
      final textPainter = TextPainter(
        text: TextSpan(
          text: (questions.indexOf(question) + 1).toString(),
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}