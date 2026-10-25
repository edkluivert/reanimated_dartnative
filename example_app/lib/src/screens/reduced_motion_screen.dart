import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// docs/device/useReducedMotion and guides/accessibility: the device
/// setting, read natively and kept live, and how each kind of animation
/// behaves under it. Turn on Reduce Motion (iOS) or Remove animations
/// (Android) in the device's accessibility settings to see it change.
class ReducedMotionScreen extends StatefulWidget {
  const ReducedMotionScreen({super.key});

  @override
  State<ReducedMotionScreen> createState() => _ReducedMotionScreenState();
}

class _ReducedMotionScreenState extends State<ReducedMotionScreen> with ReanimatedStateMixin {
  ReduceMotion mode = ReduceMotion.system;
  late final StreamSubscription<bool> changes;

  late final spin = useSharedValue(0.0);
  late final slide = useSharedValue(0.0);
  late final spinStyle = useAnimatedStyle(() => AnimatedStyle(rotate: spin.value));
  late final slideStyle = useAnimatedStyle(() => AnimatedStyle(translateX: slide.value));

  @override
  void initState() {
    super.initState();
    changes = ReducedMotion.onChange.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    changes.cancel();
    super.dispose();
  }

  void run() {
    spin.value = 0;
    spin.set(withRepeat(withTiming(deg(360), duration: const Duration(seconds: 2), easing: Easing.linear),
        numberOfReps: -1));
    slide.value = -100;
    slide.set(withSpring(100));
  }

  @override
  Widget build(BuildContext context) => ReducedMotionConfigScope(
        mode: mode,
        child: DemoPage(
          title: 'Reduced motion',
          docs: 'device/useReducedMotion',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Device setting (useReducedMotion): ${useReducedMotion() ? 'on' : 'off'}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text('Animations reduce motion: ${ReducedMotionConfig.shouldReduceMotion}'),
              const SizedBox(height: 12),
              const Text('ReducedMotionConfig mode'),
              ChoiceChips<ReduceMotion>(
                options: ReduceMotion.values,
                selected: mode,
                label: (m) => m.name,
                onSelected: (m) => setState(() => mode = m),
              ),
              const SizedBox(height: 16),
              Section(
                title: 'Behaviour',
                note: 'With reduced motion, the spring jumps to its end and the '
                    'infinite repeat does not start.',
                child: Column(children: [
                  Stage(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AnimatedView(
                          style: Styles([
                            const AnimatedStyle(width: 60, height: 60, backgroundColor: Palette.purple, borderRadius: 8),
                            spinStyle,
                          ]),
                        ),
                        AnimatedView(
                          style: Styles([
                            const AnimatedStyle(width: 40, height: 40, backgroundColor: Palette.blue, borderRadius: 20),
                            slideStyle,
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: run, child: const Text('Run')),
                ]),
              ),
            ],
          ),
        ),
      );
}
