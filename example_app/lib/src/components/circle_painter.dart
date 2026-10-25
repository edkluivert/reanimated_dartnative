import 'package:dartnative/dartnative.dart';

import '../common/common.dart';

/// Paints a filled circle of radius [r], for the useAnimatedProps example.
class CirclePainter extends CustomPainter {
  CirclePainter(this.r);
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, Paint()..color = Palette.purple);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => oldDelegate.r != r;
}
