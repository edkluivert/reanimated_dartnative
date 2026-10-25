import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// docs/css-transitions: change a style with setState and the listed
/// properties animate to it, each box with a different timing function.
class CSSTransitionsScreen extends StatefulWidget {
  const CSSTransitionsScreen({super.key});

  @override
  State<CSSTransitionsScreen> createState() => _CSSTransitionsScreenState();
}

class _CSSTransitionsScreenState extends State<CSSTransitionsScreen> {
  bool expanded = false;
  String log = '';

  static final timings = <String, EasingFunction>{
    'ease (default)': CSSTimingFunction.ease,
    'linear': CSSTimingFunction.linear,
    'ease-in-out': CSSTimingFunction.easeInOut,
    'steps(5)': CSSTimingFunction.steps(5),
    'cubic-bezier(.5,1.6,.4,.7)': CSSTimingFunction.cubicBezier(0.5, 1.6, 0.4, 0.7),
    'linear(0, 0.9, 0.5, 1)': CSSTimingFunction.linearPoints(const [0, 0.9, 0.5, 1]),
  };

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (700, () => setState(() => expanded = true)),
      (2200, () => setState(() => expanded = false)),
    ]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'CSS transitions',
        docs: 'css-transitions/transition-property',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Section(
              title: 'transitionProperty: width, 800 ms',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in timings.entries) ...[
                    Text(e.key, style: const TextStyle(fontSize: 12)),
                    AnimatedView(
                      style: AnimatedStyle(
                        width: expanded ? 280 : 60,
                        height: 28,
                        backgroundColor: Palette.purple,
                        borderRadius: 6,
                      ),
                      cssTransition: CSSTransition(
                        properties: const ['width'],
                        duration: const Duration(milliseconds: 800),
                        timingFunction: e.value,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            Section(
              title: 'transitionProperty: all, with a delay and events',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stage(
                    child: AnimatedView(
                      style: AnimatedStyle(
                        width: 100,
                        height: 100,
                        rotate: expanded ? deg(45) : 0,
                        borderRadius: expanded ? 50 : 12,
                        backgroundColor: expanded ? Palette.yellow : Palette.blue,
                      ),
                      cssTransition: CSSTransition(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        onStart: (e) => setState(() => log = 'onStart(${e.propertyName}) …'),
                        onEnd: (e) => setState(() => log = 'onEnd(${e.propertyName})'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(log),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: const Text('Toggle'),
            ),
          ],
        ),
      );
}
