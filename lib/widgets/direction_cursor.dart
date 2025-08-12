import 'package:flutter/material.dart';

class DirectionalCursor extends StatelessWidget {
  final double bearing;

  const DirectionalCursor({
    super.key,
    required this.bearing,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearing,
      child: CustomPaint(
        size: const Size(40, 40),
        painter: _CursorPainter(),
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.75)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
