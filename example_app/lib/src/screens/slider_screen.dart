import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// examples/slider: drag the knob; the box above follows its width and the
/// label reads it through animated props. Tapping the track springs the
/// knob to your finger.
class SliderScreen extends StatefulWidget {
  const SliderScreen({super.key});

  @override
  State<SliderScreen> createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> with ReanimatedStateMixin {
  static const initialBoxSize = 50.0;
  static const sliderWidth = 300.0;
  static const maxValue = sliderWidth - initialBoxSize;

  late final offset = useSharedValue(0.0);
  late final pressed = useSharedValue(false);

  late final knobScale = useDerivedAnimation(1.0, () => withSpring(pressed.value ? 1.25 : 1.0, dampingRatio: 0.5));

  late final boxStyle = useAnimatedStyle(() => AnimatedStyle(
        width: initialBoxSize + offset.value,
        backgroundColor: interpolateColor(offset.value, [0, maxValue], [Palette.blue, Palette.purple]),
      ));
  late final sliderStyle = useAnimatedStyle(() => AnimatedStyle(
        translateX: offset.value,
        scale: knobScale.value,
      ));
  late final fillStyle = useAnimatedStyle(() => AnimatedStyle(width: offset.value + initialBoxSize / 2));
  late final animatedProps = useAnimatedProps(() => 'Box width: ${(initialBoxSize + offset.value).round()}');

  /// Springs the knob's center to [x].
  void jumpTo(double x) =>
      offset.set(withSpring(clamp(x - initialBoxSize / 2, 0, maxValue), dampingRatio: 0.7));

  void onChange(double changeX) {
    cancelAnimation(offset);
    offset.value = clamp(offset.value + changeX, 0, maxValue);
  }

  void press(Offset at) {
    pressed.value = true;
    jumpTo(at.dx);
  }

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (800, () => press(const Offset(210, 25))),
      (700, () => pressed.value = false),
      (900, () => offset.set(withSpring(maxValue, dampingRatio: 0.5))),
      (1200, () => press(const Offset(60, 25))),
      (600, () => pressed.value = false),
      (1000, () => offset.set(withSpring(140, dampingRatio: 0.5))),
    ]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Slider',
        docs: 'examples/slider',
        child: Column(
          children: [
            const SizedBox(height: 24),
            AnimatedPropsBuilder(
              props: animatedProps,
              builder: (context, text) => Text(text, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: sliderWidth,
              height: 120,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedView(
                  style: Styles([const AnimatedStyle(height: initialBoxSize * 2, borderRadius: 16), boxStyle]),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // The whole track takes the touch: the knob moves by transform,
            // and a transformed view's touch area stays where it was laid out.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => press(d.localPosition),
              onTapUp: (_) => pressed.value = false,
              onTapCancel: () => pressed.value = false,
              onPanStart: (d) => press(d.localPosition),
              onPanUpdate: (d) => onChange(d.delta.dx),
              onPanEnd: (_) => pressed.value = false,
              child: SizedBox(
                width: sliderWidth,
                height: initialBoxSize,
                child: Stack(
                  children: [
                    const SizedBox(width: sliderWidth, height: initialBoxSize),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: initialBoxSize / 2 - 4,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(color: const Color(0xFFE3E5EE), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: initialBoxSize / 2 - 4,
                      child: AnimatedView(
                        style: Styles([const AnimatedStyle(height: 8, backgroundColor: Palette.purple, borderRadius: 4), fillStyle]),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: AnimatedView(
                        style: Styles([
                          const AnimatedStyle(
                            width: initialBoxSize,
                            height: initialBoxSize,
                            borderRadius: initialBoxSize / 2,
                            backgroundColor: Palette.navy,
                          ),
                          sliderStyle,
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Buttons({
              'Spring to 0': () => offset.set(withSpring(0, dampingRatio: 0.5)),
              'Spring to max': () => offset.set(withSpring(maxValue, dampingRatio: 0.5)),
            }),
          ],
        ),
      );
}
