import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// A circle whose color animates with withTiming, in linear light.
class ColorToggle extends StatefulWidget {
  const ColorToggle({super.key});

  @override
  State<ColorToggle> createState() => ColorToggleState();
}

class ColorToggleState extends State<ColorToggle> with ReanimatedStateMixin {
  late final color = useSharedValue(Palette.purple);
  late final style = useAnimatedStyle(() => AnimatedStyle(backgroundColor: color.value));

  @override
  Widget build(BuildContext context) => Row(children: [
        AnimatedView(
          style: Styles([const AnimatedStyle(width: 80, height: 80, borderRadius: 40), style]),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => color.set(withTiming(
            color.value == Palette.purple ? Palette.yellow : Palette.purple,
            duration: const Duration(milliseconds: 800),
          )),
          child: const Text('Toggle color'),
        ),
      ]);
}
