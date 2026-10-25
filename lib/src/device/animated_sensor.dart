import 'package:meta/meta.dart' show visibleForTesting;

import '../channel/reanimated_ffi_bindings.dart';
import '../core/shared_value.dart';
import 'sensor_types.dart';

/// Live readings from a hardware sensor, as the object Reanimated's
/// `useAnimatedSensor` returns.
///
/// [sensor] is a [SharedValue] the native side writes on every reading, so
/// an animated style that reads it follows the device without rebuilding
/// anything else.
class AnimatedSensor<T> {
  AnimatedSensor(this.type, {this.config = const SensorConfig()})
      : sensor = SharedValue<T>(_initial(type)) {
    _register();
  }

  static T _initial<T>(SensorType<T> type) =>
      (identical(type, SensorType.rotation)
          ? const ValueRotation()
          : const Value3D()) as T;

  final SensorType<T> type;
  final SensorConfig config;

  /// The latest reading.
  final SharedValue<T> sensor;

  bool _available = false;
  int? _token;

  /// Whether the device has this sensor and it is reporting. False when the
  /// sensor is missing, after [unregister], and in unit tests.
  bool get isAvailable => _available;

  void _register() {
    if (!ReanimatedFFIBindings.isLoaded) return;
    final token = ReanimatedFFIBindings.registerHandler(_onReading);
    final interval = config.interval.milliseconds ?? -1;
    final args = 'interval=$interval;'
        'adjust=${config.adjustToInterfaceOrientation ? 1 : 0};'
        'frame=${config.iosReferenceFrame.name}';
    final rc = ReanimatedFFIBindings.listen(token, type.name, args);
    if (rc == ReanimatedResult.ok) {
      _token = token;
      _available = true;
    } else {
      ReanimatedFFIBindings.removeHandler(token);
    }
  }

  void _onReading(int eventType, String payload) {
    if (eventType != ReanimatedEventType.success || _token == null) return;
    final reading = parseReading(type, payload);
    if (reading != null) sensor.value = reading;
  }

  /// Parses a native payload: `x,y,z,orientation` for three-axis sensors,
  /// `qw,qx,qy,qz,yaw,pitch,roll,orientation` for rotation.
  @visibleForTesting
  static T? parseReading<T>(SensorType<T> type, String payload) {
    final parts = payload.split(',');
    final n = [for (final p in parts) double.tryParse(p) ?? 0.0];
    InterfaceOrientation orientation(int i) => i < n.length
        ? InterfaceOrientation.values[n[i].round().clamp(0, 3)]
        : InterfaceOrientation.rotation0;
    if (identical(type, SensorType.rotation)) {
      if (n.length < 7) return null;
      return ValueRotation(
        qw: n[0],
        qx: n[1],
        qy: n[2],
        qz: n[3],
        yaw: n[4],
        pitch: n[5],
        roll: n[6],
        interfaceOrientation: orientation(7),
      ) as T;
    }
    if (n.length < 3) return null;
    return Value3D(x: n[0], y: n[1], z: n[2], interfaceOrientation: orientation(3))
        as T;
  }

  /// Stops listening to the sensor, as Reanimated's `unregister`. The last
  /// reading stays in [sensor].
  void unregister() {
    final token = _token;
    if (token == null) return;
    _token = null;
    _available = false;
    ReanimatedFFIBindings.cancel(token);
    ReanimatedFFIBindings.removeHandler(token);
  }

  /// Writes a reading as if the hardware had sent it, for tests and
  /// previews without the sensor.
  @visibleForTesting
  void debugEmit(T reading) => sensor.value = reading;

  /// [unregister]s and disposes [sensor].
  void dispose() {
    unregister();
    sensor.dispose();
  }
}

/// Starts reading a hardware sensor, as Reanimated's `useAnimatedSensor`.
///
/// ```dart
/// final gravity = useAnimatedSensor(SensorType.gravity);
///
/// final animatedStyle = useAnimatedStyle(() => AnimatedStyle(
///       translateX: gravity.sensor.value.x * 20,
///       translateY: gravity.sensor.value.y * 20,
///     ));
/// ```
///
/// Three-axis sensors give [Value3D] and [SensorType.rotation] gives
/// [ValueRotation]; the type follows from [type]. Readings use the same axes
/// and units on iOS and Android: accelerometer and gravity in m/s² (+9.81 on
/// z with the device flat, screen up), gyroscope in rad/s, magnetic field in
/// µT.
AnimatedSensor<T> useAnimatedSensor<T>(
  SensorType<T> type, [
  SensorConfig config = const SensorConfig(),
]) =>
    AnimatedSensor<T>(type, config: config);
