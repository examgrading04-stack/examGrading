import 'package:flutter/material.dart';

class VectorLogo extends StatelessWidget {
  final double size;

  const VectorLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChecklistLogoPainter()),
    );
  }
}

class _ChecklistLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paintBlack = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()..style = PaintingStyle.fill;

    // 1. Draw Main Board (Rounded Rectangle)
    final RRect boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.75, h * 0.8),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(boardRect, paintFill..color = Colors.white);
    canvas.drawRRect(boardRect, paintBlack);

    // 2. Draw Blue Circles (Checkboxes)
    final paintBlue = Paint()
      ..color = const Color(0xFF00A3FF)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      double y = h * 0.2 + (i * h * 0.2);
      canvas.drawCircle(Offset(w * 0.2, y), w * 0.08, paintBlue);
      canvas.drawCircle(Offset(w * 0.2, y), w * 0.08, paintBlack);
    }

    // 3. Draw Text Lines
    for (int i = 0; i < 3; i++) {
      double y = h * 0.18 + (i * h * 0.2);
      // Line 1
      canvas.drawLine(
        Offset(w * 0.35, y),
        Offset(w * 0.55, y),
        paintBlack..strokeWidth = w * 0.03,
      );
      // Line 2 (indented)
      canvas.drawLine(
        Offset(w * 0.35, y + h * 0.06),
        Offset(w * 0.48, y + h * 0.06),
        paintBlack,
      );
    }

    // 4. Draw Pencil (Top Right)
    final pencilPath = Path();
    // Body
    pencilPath.moveTo(w * 0.55, h * 0.4);
    pencilPath.lineTo(w * 0.85, h * 0.1);
    pencilPath.lineTo(w * 0.95, h * 0.2);
    pencilPath.lineTo(w * 0.65, h * 0.5);
    pencilPath.close();
    canvas.drawPath(pencilPath, paintFill..color = const Color(0xFFFFD500));
    canvas.drawPath(pencilPath, paintBlack..strokeWidth = w * 0.03);

    // Tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.55, h * 0.4);
    tipPath.lineTo(w * 0.5, h * 0.5);
    tipPath.lineTo(w * 0.65, h * 0.5);
    tipPath.close();
    canvas.drawPath(tipPath, paintFill..color = const Color(0xFFFFE8A1));
    canvas.drawPath(tipPath, paintBlack);

    // Lead
    final leadPath = Path();
    leadPath.moveTo(w * 0.5, h * 0.5);
    leadPath.lineTo(w * 0.53, h * 0.53);
    leadPath.lineTo(w * 0.53, h * 0.47);
    leadPath.close();
    canvas.drawPath(leadPath, paintFill..color = Colors.black);

    // Eraser (Red)
    final eraserPath = Path();
    eraserPath.moveTo(w * 0.85, h * 0.1);
    eraserPath.lineTo(w * 0.9, h * 0.05);
    eraserPath.lineTo(w * 1.0, h * 0.15);
    eraserPath.lineTo(w * 0.95, h * 0.2);
    eraserPath.close();
    canvas.drawPath(eraserPath, paintFill..color = const Color(0xFFFF3B30));
    canvas.drawPath(eraserPath, paintBlack);

    // Metal part (Gray)
    final metalPath = Path();
    metalPath.moveTo(w * 0.8, h * 0.15);
    metalPath.lineTo(w * 0.85, h * 0.1);
    metalPath.lineTo(w * 0.95, h * 0.2);
    metalPath.lineTo(w * 0.9, h * 0.25);
    metalPath.close();
    canvas.drawPath(metalPath, paintFill..color = const Color(0xFF8E8E93));
    canvas.drawPath(metalPath, paintBlack);

    // 5. Draw Large Green Check Circle (Bottom Right)
    final paintGreen = Paint()
      ..color = const Color(0xFFA6CE00)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.25, paintGreen);
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.75),
      w * 0.25,
      paintBlack..strokeWidth = w * 0.04,
    );

    // Checkmark inside green circle
    final checkPath = Path();
    checkPath.moveTo(w * 0.65, h * 0.75);
    checkPath.lineTo(w * 0.72, h * 0.82);
    checkPath.lineTo(w * 0.85, h * 0.68);
    canvas.drawPath(checkPath, paintBlack..strokeWidth = w * 0.05);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
