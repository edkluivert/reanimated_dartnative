import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// One puff of the contrail, smaller and fainter toward the end.
class ContrailDot extends StatefulWidget {
  const ContrailDot({super.key, required this.position, required this.index, required this.length});
  final SharedValue<Offset> position;
  final int index;
  final int length;

  @override
  State<ContrailDot> createState() => _ContrailDotState();
}

class _ContrailDotState extends State<ContrailDot> with ReanimatedStateMixin {
  double get _size => 12 - 7 * widget.index / widget.length;

  late final style = useAnimatedStyle(() => AnimatedStyle(
        translateX: widget.position.value.dx - _size / 2,
        translateY: widget.position.value.dy,
        opacity: 0.75 * (1 - widget.index / widget.length),
      ));

  @override
  Widget build(BuildContext context) => AnimatedView(
        style: Styles([
          AnimatedStyle(width: _size, height: _size, borderRadius: _size / 2, backgroundColor: const Color(0xFFFFFFFF)),
          style,
        ]),
      );
}
