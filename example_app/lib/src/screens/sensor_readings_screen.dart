import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// Every sensor's live reading, with its availability.
class SensorReadingsScreen extends StatefulWidget {
  const SensorReadingsScreen({super.key});

  @override
  State<SensorReadingsScreen> createState() => SensorReadingsScreenState();
}

class SensorReadingsScreenState extends State<SensorReadingsScreen> with ReanimatedStateMixin {
  late final sensors = <String, AnimatedSensor<Object>>{
    'accelerometer (m/s²)': useAnimatedSensor(SensorType.accelerometer, const SensorConfig(interval: SensorInterval.milliseconds(100))),
    'gyroscope (rad/s)': useAnimatedSensor(SensorType.gyroscope, const SensorConfig(interval: SensorInterval.milliseconds(100))),
    'gravity (m/s²)': useAnimatedSensor(SensorType.gravity, const SensorConfig(interval: SensorInterval.milliseconds(100))),
    'magneticField (µT)': useAnimatedSensor(SensorType.magneticField, const SensorConfig(interval: SensorInterval.milliseconds(100))),
    'rotation (rad)': useAnimatedSensor(SensorType.rotation, const SensorConfig(interval: SensorInterval.milliseconds(100))),
  };

  String format(Object value) {
    String f(double v) => v.toStringAsFixed(2).padLeft(6);
    if (value is Value3D) return 'x ${f(value.x)}  y ${f(value.y)}  z ${f(value.z)}';
    if (value is ValueRotation) {
      String d(double r) => '${(r * 180 / math.pi).toStringAsFixed(0)}°';
      return 'yaw ${d(value.yaw)}  pitch ${d(value.pitch)}  roll ${d(value.roll)}';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Sensor readings',
        docs: 'device/useAnimatedSensor',
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in sensors.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (!e.value.isAvailable)
                    const Text('unavailable')
                  else
                    ValueListenableBuilder<Object>(
                      valueListenable: e.value.sensor,
                      builder: (context, value, _) => Text(
                        '${format(value)}   ${(value is Value3D ? value.interfaceOrientation : (value as ValueRotation).interfaceOrientation).name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      );
}
