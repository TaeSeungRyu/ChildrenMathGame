import 'package:flutter/material.dart';

import '../data/models/coop_message.dart';

/// Renders coach pen strokes over the shared problem area. Stroke points are
/// normalized (0..1), so the same strokes map proportionally onto the parent's
/// draw board and the child's overlay regardless of each screen's size.
class StrokePainter extends CustomPainter {
  StrokePainter({required this.strokes, this.live});

  final List<DrawStrokeMessage> strokes;

  /// In-progress stroke on the drawing side (null elsewhere).
  final List<double>? live;

  static const Color _color = Color(0xFFE53935);
  static const double _width = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..strokeWidth = _width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      _drawPoints(canvas, size, stroke.points, paint);
    }
    final live = this.live;
    if (live != null && live.length >= 2) {
      _drawPoints(canvas, size, live, paint);
    }
  }

  void _drawPoints(Canvas canvas, Size size, List<double> pts, Paint paint) {
    if (pts.length < 2) return;
    if (pts.length == 2) {
      // A single tap — draw a dot.
      canvas.drawCircle(
        Offset(pts[0] * size.width, pts[1] * size.height),
        _width / 2,
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
      return;
    }
    final path = Path()
      ..moveTo(pts[0] * size.width, pts[1] * size.height);
    for (var i = 2; i + 1 < pts.length; i += 2) {
      path.lineTo(pts[i] * size.width, pts[i + 1] * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StrokePainter old) =>
      old.strokes != strokes || old.live != live;
}
