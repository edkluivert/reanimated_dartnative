import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// docs/fundamentals/your-first-animation: a box that grows by 50 on each
/// press, with a spring.
class FirstAnimationScreen extends StatefulWidget {
  const FirstAnimationScreen({super.key});

  @override
  State<FirstAnimationScreen> createState() => _FirstAnimationScreenState();
}

class _FirstAnimationScreenState extends State<FirstAnimationScreen> with ReanimatedStateMixin {
  late final width = useSharedValue(100.0);
  late final animatedStyle = useAnimatedStyle(() => AnimatedStyle(width: width.value));

  void handlePress() => width.set(withSpring(width.value + 50));

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [(800, handlePress), (900, handlePress), (900, handlePress), (1300, () => width.set(withSpring(100)))]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Your first animation',
        docs: 'fundamentals/your-first-animation',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 64),
            AnimatedView(
              style: Styles([
                const AnimatedStyle(height: 100, backgroundColor: Palette.purple, borderRadius: 20),
                animatedStyle,
              ]),
            ),
            const SizedBox(height: 64),
            ElevatedButton(onPressed: handlePress, child: const Text('Click me')),
            ElevatedButton(onPressed: () => width.set(withSpring(100)), child: const Text('Reset')),
          ],
        ),
      );
}
