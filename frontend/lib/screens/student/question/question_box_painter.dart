import 'package:flutter/material.dart';

class QuestionBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> questions;
  final Size imageSize;
  final Function(Map<String, dynamic>)? onQuestionTap;

  QuestionBoxPainter({
    required this.questions,
    required this.imageSize,
    this.onQuestionTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          offset: const Offset(1.0, 1.0),
          blurRadius: 3.0,
          color: Colors.black.withOpacity(0.7),
        ),
      ],
    );

    for (var question in questions) {
      if (question['boundingBox'] != null) {
        final box = question['boundingBox'];
        
        // Get the actual coordinates
        double x = box['x'];
        double y = box['y'];
        double width = box['width'];
        double height = box['height'];

        final rect = Rect.fromLTWH(x, y, width, height);
        
        // Draw the semi-transparent fill
        canvas.drawRect(rect, boxPaint);
        
        // Draw the border
        canvas.drawRect(rect, borderPaint);

        // Draw the question number with background
        final questionNumber = '${questions.indexOf(question) + 1}';
        final textSpan = TextSpan(
          text: questionNumber,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Draw number background
        final numberBackgroundPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(x + 15, y + 15),
          15,
          numberBackgroundPaint,
        );

        // Position the number in the circle
        textPainter.paint(
          canvas,
          Offset(
            x + 15 - textPainter.width / 2,
            y + 15 - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(QuestionBoxPainter oldDelegate) {
    return questions != oldDelegate.questions;
  }

  // Helper method to check if a point is inside a rectangle
  bool isPointInRect(Offset point, Rect rect) {
    return point.dx >= rect.left && 
           point.dx <= rect.right && 
           point.dy >= rect.top && 
           point.dy <= rect.bottom;
  }

  // Add this method
  bool hitTest(Offset position) {
    for (var question in questions) {
      if (question['boundingBox'] != null) {
        final box = question['boundingBox'];
        final rect = Rect.fromLTWH(
          box['x'],
          box['y'],
          box['width'],
          box['height'],
        );

        if (isPointInRect(position, rect)) {
          onQuestionTap?.call(question);
          return true;
        }
      }
    }
    return false;
  }
}

// Add this class to handle tap detection
class QuestionBoxPainterGestureDetector extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Size imageSize;
  final Function(Map<String, dynamic>) onQuestionTap;
  final Widget child;

  const QuestionBoxPainterGestureDetector({
    Key? key,
    required this.questions,
    required this.imageSize,
    required this.onQuestionTap,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        final painter = QuestionBoxPainter(
          questions: questions,
          imageSize: imageSize,
          onQuestionTap: onQuestionTap,
        );
        painter.hitTest(details.localPosition);
      },
      child: child,
    );
  }
} 