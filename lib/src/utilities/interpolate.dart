/// What [interpolate] does with input outside its range.
enum Extrapolation {
  /// Continue the nearest segment's line (the default).
  extend,

  /// Hold the edge output value.
  clamp,

  /// Return the input value unchanged.
  identity,
}

/// Separate [Extrapolation] for each side of the input range, as
/// Reanimated's `{ extrapolateLeft, extrapolateRight }`.
class ExtrapolationConfig {
  const ExtrapolationConfig({
    this.extrapolateLeft = Extrapolation.extend,
    this.extrapolateRight = Extrapolation.extend,
  });

  final Extrapolation extrapolateLeft;
  final Extrapolation extrapolateRight;
}

/// Maps [value] from [inputRange] to [outputRange], as Reanimated's
/// `interpolate`. [extrapolate] is an [Extrapolation] for both sides or an
/// [ExtrapolationConfig].
///
/// ```dart
/// final opacity = interpolate(sv.value, [0, 100], [0, 1], Extrapolation.clamp);
/// ```
double interpolate(
  double value,
  List<double> inputRange,
  List<double> outputRange, [
  Object extrapolate = Extrapolation.extend,
]) {
  if (inputRange.length != outputRange.length) {
    throw ArgumentError('inputRange (${inputRange.length}) and outputRange '
        '(${outputRange.length}) must have the same length.');
  }
  if (inputRange.length < 2) {
    throw ArgumentError('interpolate needs at least two points.');
  }
  for (var i = 1; i < inputRange.length; i++) {
    if (inputRange[i] < inputRange[i - 1]) {
      throw ArgumentError('inputRange must be non-decreasing.');
    }
  }
  final (left, right) = switch (extrapolate) {
    Extrapolation e => (e, e),
    ExtrapolationConfig c => (c.extrapolateLeft, c.extrapolateRight),
    _ => throw ArgumentError(
        'extrapolate must be an Extrapolation or ExtrapolationConfig.'),
  };

  final n = inputRange.length;
  var i = 0;
  if (value > inputRange.first) {
    i = n - 2;
    for (var k = 0; k < n - 1; k++) {
      if (value <= inputRange[k + 1]) {
        i = k;
        break;
      }
    }
  }
  final x0 = inputRange[i], x1 = inputRange[i + 1];
  final y0 = outputRange[i], y1 = outputRange[i + 1];

  if (value < x0 && i == 0) {
    switch (left) {
      case Extrapolation.clamp:
        return y0;
      case Extrapolation.identity:
        return value;
      case Extrapolation.extend:
        break;
    }
  }
  if (value > x1 && i == n - 2) {
    switch (right) {
      case Extrapolation.clamp:
        return y1;
      case Extrapolation.identity:
        return value;
      case Extrapolation.extend:
        break;
    }
  }
  if (x1 == x0) return value <= x0 ? y0 : y1;
  return y0 + (value - x0) / (x1 - x0) * (y1 - y0);
}

/// Limits [value] to [min]..[max], as Reanimated's `clamp`.
double clamp(num value, num min, num max) {
  if (min > max) throw ArgumentError('clamp: min ($min) > max ($max).');
  return value < min ? min.toDouble() : (value > max ? max.toDouble() : value.toDouble());
}
