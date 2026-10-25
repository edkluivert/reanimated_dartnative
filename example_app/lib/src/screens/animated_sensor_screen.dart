import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';
import '../components/tilt_mapping.dart';

/// docs/device/useAnimatedSensor: a box that slides toward the lower edge as
/// you tilt the device (gravity, each reading eased with withSpring), a card
/// that tilts with the device's attitude (rotation), and live readings of
/// every sensor. All readings come from the hardware.
class AnimatedSensorScreen extends StatefulWidget {
  const AnimatedSensorScreen({super.key});

  @override
  State<AnimatedSensorScreen> createState() => _AnimatedSensorScreenState();
}

class _AnimatedSensorScreenState extends State<AnimatedSensorScreen> with ReanimatedStateMixin {
  late final gravity = useAnimatedSensor(SensorType.gravity);
  late final rotation = useAnimatedSensor(
    SensorType.rotation,
    const SensorConfig(interval: SensorInterval.auto),
  );

  // The docs example: translateX: withSpring(gravity.x * 20), and the same
  // for y. A new spring starts on every reading and inherits the running
  // one's velocity, so the box glides.
  late final x = useSharedValue(0.0);
  late final y = useSharedValue(0.0);
  late final animatedStyle = useAnimatedStyle(() => AnimatedStyle(translateX: x.value, translateY: y.value));

  late final cardStyle = useAnimatedStyle(() {
    final r = rotation.sensor.value;
    return AnimatedStyle(
      rotateX: r.pitch.clamp(-0.8, 0.8),
      rotateY: r.roll.clamp(-0.8, 0.8),
      perspective: 600,
    );
  });

  @override
  void initState() {
    super.initState();
    useAnimatedReaction(() => gravity.sensor.value, (g, _) {
      final target = gravityToBoxOffset(g);
      x.set(withSpring(target.dx));
      y.set(withSpring(target.dy));
    });
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'useAnimatedSensor',
        docs: 'device/useAnimatedSensor',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Section(
              title: 'Gravity',
              note: gravity.isAvailable
                  ? 'Tilt the device.'
                  : 'No gravity sensor on this device (or simulator).',
              child: Stage(
                height: 260,
                child: AnimatedView(
                  style: Styles([
                    const AnimatedStyle(width: 80, height: 80, backgroundColor: Palette.purple, borderRadius: 16),
                    animatedStyle,
                  ]),
                ),
              ),
            ),
            Section(
              title: 'Rotation',
              note: rotation.isAvailable
                  ? 'The card follows pitch and roll.'
                  : 'No rotation sensor on this device (or simulator).',
              child: Stage(
                height: 220,
                child: AnimatedView(
                  style: Styles([
                    const AnimatedStyle(width: 200, height: 130, backgroundColor: Palette.navy, borderRadius: 16),
                    cardStyle,
                  ]),
                  child: const Center(
                    child: Text('reanimated', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 20)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
