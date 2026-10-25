/// A hardware sensor `useAnimatedSensor` can read. [T] is the reading's
/// type: [Value3D] for every sensor but [rotation], which gives
/// [ValueRotation].
final class SensorType<T> {
  const SensorType._(this.name);

  /// Native channel name.
  final String name;

  /// Acceleration including gravity, in m/s².
  static const accelerometer = SensorType<Value3D>._('accelerometer');

  /// Rotation rate, in rad/s.
  static const gyroscope = SensorType<Value3D>._('gyroscope');

  /// The direction of gravity, in m/s².
  static const gravity = SensorType<Value3D>._('gravity');

  /// Magnetic field, in µT.
  static const magneticField = SensorType<Value3D>._('magneticField');

  /// Device attitude as a quaternion and Euler angles (radians).
  static const rotation = SensorType<ValueRotation>._('rotation');

  static const List<SensorType<Object>> values = [
    accelerometer,
    gyroscope,
    gravity,
    magneticField,
    rotation,
  ];

  @override
  String toString() => 'SensorType.$name';
}

/// How often a sensor reports, as Reanimated's `interval` option.
final class SensorInterval {
  const SensorInterval._(this.milliseconds);

  /// Matches the screen's refresh rate (Reanimated's `'auto'`).
  static const auto = SensorInterval._(null);

  /// Every [ms] milliseconds. Sensors report at most about 100 times a
  /// second, so values below 10 ms behave like 10.
  const SensorInterval.milliseconds(int ms) : milliseconds = ms;

  /// Null for [auto].
  final int? milliseconds;

  @override
  String toString() =>
      milliseconds == null ? 'SensorInterval.auto' : 'SensorInterval(${milliseconds}ms)';
}

/// Reference frame for [SensorType.rotation] on iOS, as CoreMotion's
/// `CMAttitudeReferenceFrame`. Ignored on Android.
enum IOSReferenceFrame {
  xArbitraryZVertical,
  xArbitraryCorrectedZVertical,

  /// Needs a calibrated magnetometer.
  xMagneticNorthZVertical,

  /// Needs location services, to correct magnetic north to true north.
  xTrueNorthZVertical,

  /// [xArbitraryCorrectedZVertical] when the device has a magnetometer,
  /// [xArbitraryZVertical] otherwise.
  auto,
}

/// The screen's rotation when a reading was taken.
enum InterfaceOrientation { rotation0, rotation90, rotation180, rotation270 }

/// Options for `useAnimatedSensor`.
class SensorConfig {
  const SensorConfig({
    this.interval = SensorInterval.auto,
    this.adjustToInterfaceOrientation = true,
    this.iosReferenceFrame = IOSReferenceFrame.auto,
  });

  final SensorInterval interval;

  /// Rotate readings so x and y follow the screen when the interface is
  /// rotated, instead of the device's natural orientation.
  final bool adjustToInterfaceOrientation;

  final IOSReferenceFrame iosReferenceFrame;

  @override
  String toString() =>
      'SensorConfig(interval: $interval, adjustToInterfaceOrientation: '
      '$adjustToInterfaceOrientation, iosReferenceFrame: $iosReferenceFrame)';
}

/// A three-axis reading.
class Value3D {
  const Value3D({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.interfaceOrientation = InterfaceOrientation.rotation0,
  });

  final double x;
  final double y;
  final double z;
  final InterfaceOrientation interfaceOrientation;

  @override
  bool operator ==(Object other) =>
      other is Value3D &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.interfaceOrientation == interfaceOrientation;

  @override
  int get hashCode => Object.hash(x, y, z, interfaceOrientation);

  @override
  String toString() => 'Value3D(x: $x, y: $y, z: $z, $interfaceOrientation)';
}

/// A rotation reading: a quaternion and Euler angles in radians.
class ValueRotation {
  const ValueRotation({
    this.qw = 1,
    this.qx = 0,
    this.qy = 0,
    this.qz = 0,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.interfaceOrientation = InterfaceOrientation.rotation0,
  });

  final double qw;
  final double qx;
  final double qy;
  final double qz;
  final double yaw;
  final double pitch;
  final double roll;
  final InterfaceOrientation interfaceOrientation;

  @override
  bool operator ==(Object other) =>
      other is ValueRotation &&
      other.qw == qw &&
      other.qx == qx &&
      other.qy == qy &&
      other.qz == qz &&
      other.yaw == yaw &&
      other.pitch == pitch &&
      other.roll == roll &&
      other.interfaceOrientation == interfaceOrientation;

  @override
  int get hashCode =>
      Object.hash(qw, qx, qy, qz, yaw, pitch, roll, interfaceOrientation);

  @override
  String toString() =>
      'ValueRotation(yaw: $yaw, pitch: $pitch, roll: $roll, '
      'q: ($qw, $qx, $qy, $qz), $interfaceOrientation)';
}
