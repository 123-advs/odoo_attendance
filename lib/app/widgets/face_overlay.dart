import 'package:flutter/material.dart';

/// Semi-transparent dark mask with an oval cutout in the middle and
/// 4 corner brackets around the cutout. Used as a viewfinder for face
/// capture screens.
class FaceOverlay extends StatelessWidget {
  const FaceOverlay({
    super.key,
    this.borderColor = Colors.white,
    this.dimColor = const Color(0x99000000),
  });

  final Color borderColor;
  final Color dimColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FaceOverlayPainter(
        borderColor: borderColor,
        dimColor: dimColor,
      ),
      size: Size.infinite,
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  _FaceOverlayPainter({required this.borderColor, required this.dimColor});

  final Color borderColor;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.7;
    final ovalHeight = ovalWidth * 1.3;
    final center = Offset(size.width / 2, size.height * 0.42);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Dim background with oval cutout.
    final mask = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addOval(ovalRect);
    final combined = Path.combine(PathOperation.difference, mask, hole);
    canvas.drawPath(combined, Paint()..color = dimColor);

    // Oval ring.
    canvas.drawOval(
      ovalRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = borderColor.withValues(alpha: 0.85),
    );

    // 4 corner brackets around the oval bounding box.
    final bracketLen = ovalWidth * 0.12;
    final bracketPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset h, Offset v) {
      canvas.drawLine(start, start + h, bracketPaint);
      canvas.drawLine(start, start + v, bracketPaint);
    }

    corner(ovalRect.topLeft, Offset(bracketLen, 0), Offset(0, bracketLen));
    corner(ovalRect.topRight, Offset(-bracketLen, 0), Offset(0, bracketLen));
    corner(ovalRect.bottomLeft, Offset(bracketLen, 0), Offset(0, -bracketLen));
    corner(
      ovalRect.bottomRight,
      Offset(-bracketLen, 0),
      Offset(0, -bracketLen),
    );
  }

  @override
  bool shouldRepaint(covariant _FaceOverlayPainter old) =>
      old.borderColor != borderColor || old.dimColor != dimColor;
}
