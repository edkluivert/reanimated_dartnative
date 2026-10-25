import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../components/animated_switch.dart';
import '../components/bottom_sheet.dart';

/// examples/bottomsheet: a sheet slides up over a dimmed backdrop. Tap the
/// backdrop, press the button or drag the sheet down to close it.
class BottomSheetScreen extends StatefulWidget {
  const BottomSheetScreen({super.key});

  @override
  State<BottomSheetScreen> createState() => _BottomSheetScreenState();
}

class _BottomSheetScreenState extends State<BottomSheetScreen> with ReanimatedStateMixin {
  late final isOpen = useSharedValue(false);
  late final notifications = useSharedValue(true);
  late final darkMode = useSharedValue(false);

  void toggleSheet() => isOpen.value = !isOpen.value;

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (900, toggleSheet),
      (1300, () => notifications.value = !notifications.value),
      (800, () => darkMode.value = !darkMode.value),
      (1300, toggleSheet),
      (1300, toggleSheet),
      (1700, toggleSheet),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bottom sheet')),
        body: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('docs: examples/bottomsheet',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: toggleSheet, child: const Text('Toggle bottom sheet')),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBottomSheet(
                isOpen: isOpen,
                toggleSheet: toggleSheet,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    _row('Notifications', notifications),
                    _row('Dark mode', darkMode),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: toggleSheet, child: const Text('Done')),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _row(String label, SharedValue<bool> value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          AnimatedSwitch(value: value, onPress: () => value.value = !value.value),
        ]),
      );
}
