import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';

/// A two-faced card you spin with your finger.
///
/// Horizontal drags turn it about its vertical axis and vertical drags tip
/// it toward you. On release it snaps to whichever face the fling is
/// heading for, keeping the fling's velocity, so a hard flick spins it
/// several times before settling. While held it lifts (scale and shadow).
/// A tap flips it.
class SpinnableCard extends StatefulWidget {
  const SpinnableCard({
    super.key,
    required this.front,
    required this.back,
    this.width = 320,
    this.height = 200,
  });

  final Widget front;
  final Widget back;
  final double width;
  final double height;

  @override
  State<SpinnableCard> createState() => _SpinnableCardState();
}

class _SpinnableCardState extends State<SpinnableCard> with ReanimatedStateMixin {
  /// Rotation about the vertical axis, radians.
  late final spin = useSharedValue(0.0);

  /// Tip toward the viewer, radians.
  late final tilt = useSharedValue(0.0);
  late final held = useSharedValue(false);

  late final lift = useDerivedAnimation(0.0, () => withSpring(held.value ? 1.0 : 0.0, dampingRatio: 0.6));

  double get _radiansPerPixel => math.pi / widget.width;

  AnimatedStyle _face(double extra) => AnimatedStyle(
        rotateY: spin.value + extra,
        rotateX: tilt.value,
        perspective: 800,
        scale: 1 + 0.06 * lift.value,
      );

  late final frontStyle = useAnimatedStyle(() => _face(0));
  late final backStyle = useAnimatedStyle(() => _face(math.pi));

  // A soft shadow under the card that spreads and drops as it lifts.
  late final shadowStyle = useAnimatedStyle(() => AnimatedStyle(
        opacity: 0.18 + 0.17 * lift.value,
        scaleX: (0.9 + 0.08 * lift.value) * math.cos(spin.value).abs().clamp(0.35, 1.0),
        translateY: 14 + 16 * lift.value,
      ));

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    if (Capture.enabled) {
      Future<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        held.value = true;
        await Capture.drive(this, 0.9, (t) {
          spin.value = t * 1.4;
          tilt.value = -0.35 * t;
        });
        onPanEnd(const DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(2600, -300))));
        await Future<void>.delayed(const Duration(milliseconds: 2400));
        flip();
      });
    }
  }

  void onPanEnd(DragEndDetails details) {
    held.value = false;
    final v = details.velocity.pixelsPerSecond;
    final angularVelocity = v.dx * _radiansPerPixel;
    // Where the fling would carry it, rounded to a face.
    final projected = spin.value + angularVelocity * 0.25;
    final target = (projected / math.pi).round() * math.pi;
    spin.set(withSpring(target, velocity: angularVelocity, dampingRatio: 0.65, duration: const Duration(milliseconds: 900)));
    tilt.set(withSpring(0.0, velocity: -v.dy * _radiansPerPixel * 0.4, dampingRatio: 0.5));
  }

  void flip() {
    final target = ((spin.value / math.pi).round() + 1) * math.pi;
    spin.set(withSpring(target, dampingRatio: 0.7, duration: const Duration(milliseconds: 800)));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: flip,
        onPanStart: (_) {
          held.value = true;
          cancelAnimation(spin);
          cancelAnimation(tilt);
        },
        onPanUpdate: (d) {
          spin.value += d.delta.dx * _radiansPerPixel;
          tilt.value = clamp(tilt.value - d.delta.dy * _radiansPerPixel * 0.5, -0.6, 0.6);
        },
        onPanEnd: onPanEnd,
        child: SizedBox(
          width: widget.width + 40,
          height: widget.height + 70,
          child: Stack(
            children: [
              SizedBox(width: widget.width + 40, height: widget.height + 70),
              Positioned(
                left: 40,
                top: widget.height - 20,
                child: AnimatedView(
                  style: Styles([
                    AnimatedStyle(width: widget.width - 40, height: 30, borderRadius: 15, backgroundColor: const Color(0xFF001A72)),
                    shadowStyle,
                  ]),
                ),
              ),
              Positioned(
                left: 20,
                top: 10,
                child: AnimatedView(
                  style: frontStyle,
                  backfaceVisibility: false,
                  child: SizedBox(width: widget.width, height: widget.height, child: widget.front),
                ),
              ),
              Positioned(
                left: 20,
                top: 10,
                child: AnimatedView(
                  style: backStyle,
                  backfaceVisibility: false,
                  child: SizedBox(width: widget.width, height: widget.height, child: widget.back),
                ),
              ),
            ],
          ),
        ),
      );
}
