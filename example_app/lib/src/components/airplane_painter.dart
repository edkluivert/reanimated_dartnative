import 'package:dartnative/dartnative.dart';

/// A jet seen from above, nose up, drawn to fill [Size]. With [shadow] it
/// paints a flat translucent silhouette for the ground shadow.
class AirplanePainter extends CustomPainter {
  const AirplanePainter({this.shadow = false});

  final bool shadow;

  // The outline in a 100 × 110 box (x from -50 to 50, y from -55 to 55).
  static const _outline = [
    Offset(0, -55), Offset(6, -44), Offset(7, -14), Offset(50, 8), Offset(50, 15),
    Offset(7, 6), Offset(5, 34), Offset(18, 44), Offset(18, 49), Offset(2, 45),
    Offset(0, 50), Offset(-2, 45), Offset(-18, 49), Offset(-18, 44), Offset(-5, 34),
    Offset(-7, 6), Offset(-50, 15), Offset(-50, 8), Offset(-7, -14), Offset(-6, -44),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100, sy = size.height / 110;
    Offset map(Offset p) => Offset((p.dx + 50) * sx, (p.dy + 55) * sy);

    final body = Path()..moveTo(map(_outline.first).dx, map(_outline.first).dy);
    for (final p in _outline.skip(1)) {
      final q = map(p);
      body.lineTo(q.dx, q.dy);
    }
    body.close();

    if (shadow) {
      canvas.drawPath(body, Paint()..color = const Color(0x33001A72));
      return;
    }
    canvas.drawPath(body, Paint()..color = const Color(0xFFF8F9FF));
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF001A72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Cockpit and engine pods.
    canvas.drawCircle(map(const Offset(0, -38)), 3.2 * sx, Paint()..color = const Color(0xFF5B8DEF));
    for (final x in [-24.0, 24.0]) {
      canvas.drawCircle(map(Offset(x, 6)), 3 * sx, Paint()..color = const Color(0xFFB58DF1));
    }
  }

  @override
  bool shouldRepaint(AirplanePainter oldDelegate) => oldDelegate.shadow != shadow;
}
