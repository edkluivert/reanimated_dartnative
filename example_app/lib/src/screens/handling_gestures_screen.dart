import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// docs/fundamentals/handling-gestures: a draggable ball that springs back,
/// and one flung with withDecay between the screen's edges.
class GesturesScreen extends StatefulWidget {
  const GesturesScreen({super.key});

  @override
  State<GesturesScreen> createState() => _GesturesScreenState();
}

class _GesturesScreenState extends State<GesturesScreen> with ReanimatedStateMixin {
  static const size = 120.0;

  // First stage: press to grow, drag to move, release to spring back.
  late final pressed = useSharedValue(false);
  late final offset = useSharedValue(0.0);
  late final scale = useSharedValue(1.0);
  late final animatedStyles = useAnimatedStyle(() => AnimatedStyle(
        translateX: offset.value,
        scale: scale.value,
        backgroundColor: pressed.value ? Palette.yellow : Palette.purple,
      ));

  @override
  void initState() {
    super.initState();
    // The pressed state animates scale with withTiming, as the docs'
    // `scale: withTiming(pressed.value ? 1.2 : 1)`.
    useAnimatedReaction(
      () => pressed.value,
      (isPressed, _) => scale.set(withTiming(isPressed ? 1.2 : 1.0)),
    );
  }

  // Second stage: fling the ball and let withDecay slow it down.
  late final decayOffset = useSharedValue(0.0);
  late final decayStyle = useAnimatedStyle(() => AnimatedStyle(translateX: decayOffset.value));

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final ball = const AnimatedStyle(width: size, height: size, borderRadius: size / 2);
    return DemoPage(
      title: 'Handling gestures',
      docs: 'fundamentals/handling-gestures',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Section(
            title: 'Tap and pan',
            note: 'Press: grows and turns yellow. Drag: follows your finger. '
                'Release: springs back to the center.',
            // The detector covers the whole stage: a view moved by a
            // transform keeps its touch area where it was laid out, so the
            // stage, not the ball, receives the drag.
            child: GestureDetector(
              onTapDown: (_) => pressed.value = true,
              onTapUp: (_) => pressed.value = false,
              onTapCancel: () => pressed.value = false,
              onPanStart: (_) => pressed.value = true,
              onPanUpdate: (d) => offset.value += d.delta.dx,
              onPanEnd: (_) {
                offset.set(withSpring(0));
                pressed.value = false;
              },
              child: Stage(
                height: 200,
                child: AnimatedView(style: Styles([ball, animatedStyles])),
              ),
            ),
          ),
          Section(
            title: 'withDecay',
            note: 'Fling it: it keeps the release velocity, slows down, and '
                'rubber-bands off the edges.',
            child: GestureDetector(
              onPanStart: (_) => cancelAnimation(decayOffset),
              onPanUpdate: (d) => decayOffset.value += d.delta.dx,
              onPanEnd: (d) => decayOffset.set(withDecay(
                velocity: d.velocity.pixelsPerSecond.dx,
                rubberBandEffect: true,
                clamp: (-(width / 2) + size / 2, width / 2 - size / 2),
              )),
              child: Stage(
                height: 200,
                child: AnimatedView(
                  style: Styles([ball.merge(const AnimatedStyle(backgroundColor: Palette.blue)), decayStyle]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
