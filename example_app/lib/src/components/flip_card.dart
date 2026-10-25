import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// Which axis a [FlipCard] turns about.
enum FlipDirection { x, y }

/// The Reanimated site's `FlipCard`: the front turns 0° → 180° and the back
/// 180° → 360° with withTiming, both with their backface hidden, so one
/// face always shows.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.isFlipped,
    required this.regularContent,
    required this.flippedContent,
    this.direction = FlipDirection.y,
    this.duration = const Duration(milliseconds: 500),
  });

  final SharedValue<bool> isFlipped;
  final Widget regularContent;
  final Widget flippedContent;
  final FlipDirection direction;
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with ReanimatedStateMixin {
  // The Reanimated original is:
  //   withTiming(interpolate(Number(isFlipped.value), [0, 1], [0, 180]))
  // Here the angle is in radians: 0 for the front, π for the back.
  late final spin = useDerivedAnimation(
    0.0,
    () => withTiming(
      interpolate(widget.isFlipped.value ? 1 : 0, [0, 1], [0, math.pi]),
      duration: widget.duration,
    ),
  );

  AnimatedStyle _rotation(double angle) => widget.direction == FlipDirection.x
      ? AnimatedStyle(rotateX: angle, perspective: 1000)
      : AnimatedStyle(rotateY: angle, perspective: 1000);

  late final regularCardAnimatedStyle = useAnimatedStyle(() => _rotation(spin.value));
  late final flippedCardAnimatedStyle = useAnimatedStyle(() => _rotation(spin.value + math.pi));

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          AnimatedView(
            style: regularCardAnimatedStyle,
            backfaceVisibility: false,
            child: widget.regularContent,
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: AnimatedView(
              style: flippedCardAnimatedStyle,
              backfaceVisibility: false,
              child: widget.flippedContent,
            ),
          ),
        ],
      );
}
