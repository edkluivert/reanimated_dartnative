import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// One cloud of a parallax layer. It sits at [x] across the sky and moves
/// down with its layer's [scroll], wrapping round once it leaves the bottom.
class SkyCloud extends StatefulWidget {
  const SkyCloud({
    super.key,
    required this.scroll,
    required this.area,
    required this.x,
    required this.y,
    required this.width,
    required this.opacity,
  });

  /// Pixels the layer has scrolled.
  final SharedValue<double> scroll;
  final SharedValue<Size> area;

  /// Position as fractions of the sky's width and height.
  final double x;
  final double y;
  final double width;
  final double opacity;

  @override
  State<SkyCloud> createState() => _SkyCloudState();
}

class _SkyCloudState extends State<SkyCloud> with ReanimatedStateMixin {
  late final style = useAnimatedStyle(() {
    final area = widget.area.value;
    final span = area.height + 200;
    final y = (widget.y * span + widget.scroll.value) % span - 120;
    return AnimatedStyle(translateX: widget.x * area.width - widget.width / 2, translateY: y);
  });

  @override
  Widget build(BuildContext context) {
    final h = widget.width * 0.42;
    Widget puff(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(size / 2)),
        );
    return AnimatedView(
      style: Styles([AnimatedStyle(opacity: widget.opacity), style]),
      child: SizedBox(
        width: widget.width,
        height: h,
        child: Stack(children: [
          SizedBox(width: widget.width, height: h),
          Positioned(left: 0, top: h * 0.35, child: puff(h * 0.65)),
          Positioned(left: widget.width * 0.22, top: 0, child: puff(h)),
          Positioned(left: widget.width * 0.5, top: h * 0.15, child: puff(h * 0.85)),
          Positioned(
            left: h * 0.3,
            top: h * 0.55,
            child: Container(
              width: widget.width - h * 0.5,
              height: h * 0.45,
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(h * 0.22)),
            ),
          ),
        ]),
      ),
    );
  }
}
