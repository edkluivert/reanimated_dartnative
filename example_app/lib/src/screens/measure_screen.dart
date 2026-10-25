import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// docs/advanced/measure and docs/utilities/getRelativeCoords: tap the box
/// to measure it; tap anywhere on the stage to see the tap relative to it.
class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> with ReanimatedStateMixin {
  final animatedRef = useAnimatedRef();
  final stageRef = useAnimatedRef();
  late final width = useSharedValue(120.0);
  late final style = useAnimatedStyle(() => AnimatedStyle(width: width.value));

  String measured = 'Tap the box';
  String relative = '';

  void handlePress() {
    final m = measure(animatedRef, relativeTo: stageRef);
    setState(() => measured = m == null
        ? 'not mounted'
        : 'x ${m.x.toStringAsFixed(0)}, y ${m.y.toStringAsFixed(0)}, '
            '${m.width.toStringAsFixed(0)} × ${m.height.toStringAsFixed(0)}\n'
            'pageX ${m.pageX.toStringAsFixed(0)}, pageY ${m.pageY.toStringAsFixed(0)}');
    width.set(withSpring(width.value > 150 ? 120.0 : 200.0));
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'measure',
        docs: 'advanced/measure',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTapUp: (d) {
                final p = getRelativeCoords(animatedRef, d.globalPosition.dx, d.globalPosition.dy);
                setState(() => relative = p == null
                    ? ''
                    : 'tap relative to the box: (${p.dx.toStringAsFixed(0)}, ${p.dy.toStringAsFixed(0)})');
              },
              child: Container(
                key: stageRef,
                height: 220,
                decoration: BoxDecoration(color: Palette.grey, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: handlePress,
                  child: AnimatedView(
                    key: animatedRef,
                    style: Styles([const AnimatedStyle(height: 100, backgroundColor: Palette.purple, borderRadius: 20), style]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(measured),
            const SizedBox(height: 6),
            Text(relative),
          ],
        ),
      );
}
