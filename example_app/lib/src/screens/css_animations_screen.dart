import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// docs/css-animations: keyframes with duration, iteration count,
/// direction, timing functions (also per keyframe), fill mode and play
/// state.
class CSSAnimationsScreen extends StatefulWidget {
  const CSSAnimationsScreen({super.key});

  @override
  State<CSSAnimationsScreen> createState() => _CSSAnimationsScreenState();
}

class _CSSAnimationsScreenState extends State<CSSAnimationsScreen> {
  static final spin = CSSKeyframes({'to': AnimatedStyle(rotate: deg(360))});
  static final pulse = CSSKeyframes({
    'from': const AnimatedStyle(scale: 1, opacity: 1),
    'to': const AnimatedStyle(scale: 1.4, opacity: 0.4),
  });
  static final bounce = CSSKeyframes({
    '0%': const AnimatedStyle(translateY: 0),
    '50%': KeyframeStyle(translateY: -80, easing: CSSTimingFunction.cubicBezier(0, 0, 0.2, 1)),
    '100%': KeyframeStyle(translateY: 0, easing: CSSTimingFunction.cubicBezier(0.8, 0, 1, 1)),
  });
  static final slideIn = CSSKeyframes({
    'from': const AnimatedStyle(translateX: -120, opacity: 0),
  });

  bool paused = false;
  int replay = 0;
  String events = '';

  static const box = AnimatedStyle(width: 70, height: 70, backgroundColor: Palette.purple, borderRadius: 14);

  @override
  Widget build(BuildContext context) {
    final playState = paused ? AnimationPlayState.paused : AnimationPlayState.running;
    return DemoPage(
      title: 'CSS animations',
      docs: 'css-animations/animation-name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Section(
            title: 'Infinite, linear / alternate / per-keyframe easing',
            child: Stage(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedView(
                    style: box,
                    cssAnimations: [
                      CSSAnimation(
                        keyframes: spin,
                        duration: const Duration(seconds: 3),
                        iterationCount: double.infinity,
                        timingFunction: CSSTimingFunction.linear,
                        playState: playState,
                      ),
                    ],
                  ),
                  AnimatedView(
                    style: box.merge(const AnimatedStyle(backgroundColor: Palette.blue, borderRadius: 35)),
                    cssAnimations: [
                      CSSAnimation(
                        keyframes: pulse,
                        duration: const Duration(milliseconds: 800),
                        iterationCount: double.infinity,
                        direction: AnimationDirection.alternate,
                        timingFunction: CSSTimingFunction.easeInOut,
                        playState: playState,
                      ),
                    ],
                  ),
                  AnimatedView(
                    style: box.merge(const AnimatedStyle(backgroundColor: Palette.pink, width: 40, height: 40, borderRadius: 20)),
                    cssAnimations: [
                      CSSAnimation(
                        keyframes: bounce,
                        duration: const Duration(milliseconds: 900),
                        iterationCount: double.infinity,
                        playState: playState,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => paused = !paused),
            child: Text(paused ? 'animationPlayState: running' : 'animationPlayState: paused'),
          ),
          const SizedBox(height: 24),
          Section(
            title: 'Delay, fill mode and events',
            note: '500 ms delay, fill mode backwards (hidden while waiting), '
                'two iterations of steps(5).',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stage(
                  height: 120,
                  child: AnimatedView(
                    key: ValueKey(replay),
                    style: box.merge(const AnimatedStyle(backgroundColor: Palette.navy)),
                    cssAnimations: [
                      CSSAnimation(
                        keyframes: slideIn,
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 500),
                        iterationCount: 2,
                        timingFunction: CSSTimingFunction.steps(5),
                        fillMode: AnimationFillMode.backwards,
                        onStart: (_) => setState(() => events = 'onStart'),
                        onIteration: (e) => setState(() => events += ' → onIteration (${e.elapsedTime.toStringAsFixed(1)} s)'),
                        onEnd: (e) => setState(() => events += ' → onEnd (${e.elapsedTime.toStringAsFixed(1)} s)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(events),
                ElevatedButton(
                  onPressed: () => setState(() {
                    events = '';
                    replay++;
                  }),
                  child: const Text('Replay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
