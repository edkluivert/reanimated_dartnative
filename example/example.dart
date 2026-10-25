// The "Your first animation" example from the Reanimated docs. The full set
// of examples is the app in example_app/.

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

class FirstAnimation extends StatefulWidget {
  const FirstAnimation({super.key});

  @override
  State<FirstAnimation> createState() => _FirstAnimationState();
}

class _FirstAnimationState extends State<FirstAnimation> with ReanimatedStateMixin {
  late final width = useSharedValue(100.0);
  late final animatedStyle = useAnimatedStyle(() => AnimatedStyle(width: width.value));

  void handlePress() => width.set(withSpring(width.value + 50));

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AnimatedView(
            style: Styles([
              const AnimatedStyle(height: 100, backgroundColor: Color(0xFFB58DF1), borderRadius: 20),
              animatedStyle,
            ]),
          ),
          ElevatedButton(onPressed: handlePress, child: const Text('Click me')),
        ],
      );
}
