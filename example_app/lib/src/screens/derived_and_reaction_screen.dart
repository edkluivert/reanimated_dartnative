import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// docs/core/useDerivedValue and docs/advanced/useAnimatedReaction: drag the
/// slider; the bar's width is derived from it, and a reaction flags when it
/// passes 200 and springs a second bar's height.
class DerivedAndReactionScreen extends StatefulWidget {
  const DerivedAndReactionScreen({super.key});

  @override
  State<DerivedAndReactionScreen> createState() => _DerivedAndReactionScreenState();
}

class _DerivedAndReactionScreenState extends State<DerivedAndReactionScreen> with ReanimatedStateMixin {
  late final progress = useSharedValue(0.2);

  // useDerivedValue(() => sv.value * 250): no dependency list needed.
  late final width = useDerivedValue(() => progress.value * 250);
  late final barStyle = useAnimatedStyle(() => AnimatedStyle(width: width.value));
  late final label = useDerivedValue(() => 'width: ${width.value.toStringAsFixed(0)}');

  late final over = useSharedValue(false);
  late final height = useSharedValue(40.0);
  late final heightStyle = useAnimatedStyle(() => AnimatedStyle(
        height: height.value,
        backgroundColor: over.value ? Palette.pink : Palette.blue,
      ));

  @override
  void initState() {
    super.initState();
    useAnimatedReaction(
      () => width.value > 200,
      (isOver, wasOver) {
        if (isOver == wasOver) return;
        over.value = isOver;
        height.set(withSpring(isOver ? 120.0 : 40.0, dampingRatio: 0.4));
      },
    );
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Derived values & reactions',
        docs: 'core/useDerivedValue',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, _) => Slider(value: value, onChanged: (v) => progress.value = v),
            ),
            AnimatedPropsBuilder(props: label, builder: (context, text) => Text(text)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedView(
                style: Styles([const AnimatedStyle(height: 40, backgroundColor: Palette.purple, borderRadius: 8), barStyle]),
              ),
            ),
            const SizedBox(height: 24),
            const Text('useAnimatedReaction: past 200?'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedView(
                style: Styles([const AnimatedStyle(width: 80, borderRadius: 8), heightStyle]),
              ),
            ),
          ],
        ),
      );
}
