import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// docs/fundamentals/applying-modifiers: withRepeat, withSequence and
/// withDelay (the shake), plus withClamp.
class ModifiersScreen extends StatefulWidget {
  const ModifiersScreen({super.key});

  @override
  State<ModifiersScreen> createState() => _ModifiersScreenState();
}

class _ModifiersScreenState extends State<ModifiersScreen> with ReanimatedStateMixin {
  // withRepeat: slide between +120 and -120 forever, reversing each time.
  late final offset = useSharedValue(120.0);
  late final repeatStyle = useAnimatedStyle(() => AnimatedStyle(translateX: offset.value));

  // The shake from the docs: a quick wobble built from withSequence.
  static const shakeOffset = 40.0;
  static const time = Duration(milliseconds: 250);
  static const delay = Duration(milliseconds: 400);
  late final shake = useSharedValue(0.0);
  late final shakeStyle = useAnimatedStyle(() => AnimatedStyle(translateX: shake.value));

  // withClamp: two bars on the same bouncy spring; only the first is clamped.
  late final clampWidth = useSharedValue(100.0);
  late final clampStyle = useAnimatedStyle(() => AnimatedStyle(width: clampWidth.value));
  late final freeWidth = useSharedValue(100.0);
  late final freeStyle = useAnimatedStyle(() => AnimatedStyle(width: freeWidth.value));

  @override
  void initState() {
    super.initState();
    offset.set(withRepeat(withTiming(-offset.value), numberOfReps: -1, reverse: true));
  }

  void handleShake() {
    shake.set(withDelay(
      delay,
      withSequence([
        // Swing to -40 first,
        withTiming(-shakeOffset, duration: time ~/ 2),
        // then swing between -40 and 40 five times,
        withRepeat(withTiming(shakeOffset, duration: time), numberOfReps: 5, reverse: true),
        // and settle back at 0.
        withTiming(0, duration: time ~/ 2),
      ]),
    ));
  }

  void toggleClamp() {
    final to = clampWidth.value > 150 ? 100.0 : 220.0;
    SpringAnimation bouncy(double to) => withSpring(to, stiffness: 300, damping: 6, mass: 1);
    freeWidth.set(bouncy(to));
    clampWidth.set(withClamp(min: 100, max: 220, bouncy(to)));
  }

  static const box = AnimatedStyle(width: 100, height: 100, backgroundColor: Palette.purple, borderRadius: 20);

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Applying modifiers',
        docs: 'fundamentals/applying-modifiers',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Section(
              title: 'withRepeat',
              note: 'withRepeat(withTiming(-offset.value), -1, true): forever, reversing.',
              child: Stage(child: AnimatedView(style: Styles([box, repeatStyle]))),
            ),
            Section(
              title: 'withSequence + withDelay: shake',
              note: 'After a 400 ms delay: to -40, five 250 ms swings, back to 0.',
              child: Column(children: [
                Stage(child: AnimatedView(style: Styles([box, shakeStyle]))),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: handleShake, child: const Text('Shake')),
              ]),
            ),
            Section(
              title: 'withClamp',
              note: 'The same bouncy spring; the top bar is clamped to 100–220.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedView(
                    style: Styles([const AnimatedStyle(height: 40, backgroundColor: Palette.blue, borderRadius: 8), clampStyle]),
                  ),
                  const SizedBox(height: 8),
                  AnimatedView(
                    style: Styles([const AnimatedStyle(height: 40, backgroundColor: Palette.pink, borderRadius: 8), freeStyle]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: toggleClamp, child: const Text('Toggle width')),
                ],
              ),
            ),
          ],
        ),
      );
}
