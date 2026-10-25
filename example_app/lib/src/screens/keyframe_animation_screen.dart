import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// docs/layout-animations/keyframe-animations: the docs' keyframe, which
/// swings the box to 100° with an exponential ease and back over 2 s.
class KeyframeScreen extends StatefulWidget {
  const KeyframeScreen({super.key});

  @override
  State<KeyframeScreen> createState() => _KeyframeScreenState();
}

class _KeyframeScreenState extends State<KeyframeScreen> {
  bool show = false;

  // Built once, outside build, as the docs recommend.
  final enteringAnimation = Keyframe({
    0: const AnimatedStyle(rotate: 0),
    45: KeyframeStyle(rotate: deg(100), easing: Easing.exp),
    100: const AnimatedStyle(rotate: 0),
  }).duration(const Duration(milliseconds: 2000));

  final exitingAnimation = Keyframe({
    0: const AnimatedStyle(opacity: 1, scale: 1),
    30: const AnimatedStyle(opacity: 1, scale: 1.2),
    100: KeyframeStyle(opacity: 0, scale: 0.2, easing: Easing.in_(Easing.quad)),
  }, exiting: true)
      .duration(const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (500, () => setState(() => show = true)),
      (2700, () => setState(() => show = false)),
      (1100, () => setState(() => show = true)),
    ]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Keyframe animations',
        docs: 'layout-animations/keyframe-animations',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stage(
              height: 260,
              child: AnimatedPresence(children: [
                if (show)
                  AnimatedView(
                    key: const ValueKey('keyframe'),
                    entering: enteringAnimation,
                    exiting: exitingAnimation,
                    style: const AnimatedStyle(
                        width: 120, height: 120, backgroundColor: Palette.purple, borderRadius: 20),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => show = !show),
              child: Text(show ? 'Remove' : 'Add'),
            ),
          ],
        ),
      );
}
