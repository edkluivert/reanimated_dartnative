import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/animated_switch.dart';

/// examples/switch: a switch whose track color and thumb animate together,
/// at any size and in any colors.
class SwitchScreen extends StatefulWidget {
  const SwitchScreen({super.key});

  @override
  State<SwitchScreen> createState() => _SwitchScreenState();
}

class _SwitchScreenState extends State<SwitchScreen> with ReanimatedStateMixin {
  late final isOn = useSharedValue(false);
  late final label = useDerivedValue(() => 'Switch value: ${isOn.value}');

  void handlePress() => isOn.value = !isOn.value;

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [(900, handlePress), (1300, handlePress), (1300, handlePress), (1300, handlePress)]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Switch',
        docs: 'examples/switch',
        child: Column(
          children: [
            const SizedBox(height: 32),
            AnimatedSwitch(value: isOn, onPress: handlePress, width: 200, height: 80),
            const SizedBox(height: 16),
            AnimatedPropsBuilder(
              props: label,
              builder: (context, text) => Text(text, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 40),
            const Text('Shared value, several switches'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedSwitch(value: isOn, onPress: handlePress),
                AnimatedSwitch(
                  value: isOn,
                  onPress: handlePress,
                  width: 90,
                  height: 44,
                  trackColors: (on: Palette.purple, off: const Color(0xFFC9CCD8)),
                ),
                AnimatedSwitch(
                  value: isOn,
                  onPress: handlePress,
                  width: 50,
                  height: 28,
                  duration: const Duration(milliseconds: 900),
                  trackColors: (on: Palette.navy, off: Palette.yellow),
                ),
              ],
            ),
          ],
        ),
      );
}
