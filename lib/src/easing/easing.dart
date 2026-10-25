import 'dart:math' as math;

/// Maps animation progress `t` in [0, 1] to eased progress.
typedef EasingFunction = double Function(double t);

/// Easing curves, as Reanimated's `Easing` (and React Native's).
///
/// Base curves ease in; wrap them in [Easing.out] or [Easing.inOut] for the
/// other directions. `Easing.in` is spelled [Easing.in_] because `in` is a
/// Dart keyword.
///
/// ```dart
/// withTiming(1, easing: Easing.inOut(Easing.quad)) // the default
/// withTiming(1, easing: Easing.bezier(0.25, 0.1, 0.25, 1))
/// ```
abstract final class Easing {
  /// `f(t) = t`.
  static double linear(double t) => t;

  /// A simple inertial curve, `bezier(0.42, 0, 1, 1)`.
  static double ease(double t) => _ease(t);
  static final EasingFunction _ease = bezier(0.42, 0, 1, 1);

  /// `f(t) = t²`.
  static double quad(double t) => t * t;

  /// `f(t) = t³`.
  static double cubic(double t) => t * t * t;

  /// `f(t) = tⁿ`.
  static EasingFunction poly(num n) => (t) => math.pow(t, n).toDouble();

  /// Sinusoidal: `1 - cos(t·π/2)`.
  static double sin(double t) => 1 - math.cos(t * math.pi / 2);

  /// Circular: `1 - √(1 - t²)`.
  static double circle(double t) => 1 - math.sqrt(1 - t * t);

  /// Exponential: `2^(10(t - 1))`.
  static double exp(double t) => math.pow(2, 10 * (t - 1)).toDouble();

  /// A spring-like oscillation. [bounciness] 1 overshoots slightly; higher
  /// values bounce more.
  static EasingFunction elastic([double bounciness = 1]) {
    final p = bounciness * math.pi;
    return (t) => 1 - math.pow(math.cos(t * math.pi / 2), 3) * math.cos(t * p);
  }

  /// Pulls back before moving forward. [s] 1.70158 overshoots by about 10%.
  static EasingFunction back([double s = 1.70158]) =>
      (t) => t * t * ((s + 1) * t - s);

  /// A bouncing ball settling at the end.
  static double bounce(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) {
      final t2 = t - 1.5 / 2.75;
      return 7.5625 * t2 * t2 + 0.75;
    }
    if (t < 2.5 / 2.75) {
      final t2 = t - 2.25 / 2.75;
      return 7.5625 * t2 * t2 + 0.9375;
    }
    final t2 = t - 2.625 / 2.75;
    return 7.5625 * t2 * t2 + 0.984375;
  }

  /// A cubic Bézier curve, as CSS `cubic-bezier(x1, y1, x2, y2)`.
  static EasingFunction bezier(double x1, double y1, double x2, double y2) {
    if (x1 < 0 || x1 > 1 || x2 < 0 || x2 > 1) {
      throw ArgumentError('bezier x values must be in [0, 1].');
    }
    return _CubicBezier(x1, y1, x2, y2).transform;
  }

  /// Steps of equal size. With [roundToNextStep] the value jumps at the
  /// start of each step, otherwise at its end.
  static EasingFunction steps([int n = 10, bool roundToNextStep = true]) {
    if (n <= 0) throw ArgumentError('steps needs at least one step.');
    return (t) {
      final v = roundToNextStep ? (t * n).ceil() / n : (t * n).floor() / n;
      return v.clamp(0.0, 1.0);
    };
  }

  /// Runs [easing] forwards (`Easing.in` in Reanimated).
  static EasingFunction in_(EasingFunction easing) => easing;

  /// Runs [easing] backwards: fast start, slow end.
  static EasingFunction out(EasingFunction easing) => (t) => 1 - easing(1 - t);

  /// [easing] for the first half, mirrored for the second.
  static EasingFunction inOut(EasingFunction easing) => (t) =>
      t < 0.5 ? easing(t * 2) / 2 : 1 - easing((1 - t) * 2) / 2;
}

/// Solves a CSS cubic Bézier for y at a given x (Newton's method with a
/// bisection fallback, as WebKit's UnitBezier).
class _CubicBezier {
  _CubicBezier(this.x1, this.y1, this.x2, this.y2)
      : _cx = 3 * x1,
        _bx = 3 * (x2 - x1) - 3 * x1,
        _ax = 1 - 3 * x1 - (3 * (x2 - x1) - 3 * x1),
        _cy = 3 * y1,
        _by = 3 * (y2 - y1) - 3 * y1,
        _ay = 1 - 3 * y1 - (3 * (y2 - y1) - 3 * y1);

  final double x1, y1, x2, y2;
  final double _ax, _bx, _cx, _ay, _by, _cy;

  double _sampleX(double t) => ((_ax * t + _bx) * t + _cx) * t;
  double _sampleY(double t) => ((_ay * t + _by) * t + _cy) * t;
  double _slopeX(double t) => (3 * _ax * t + 2 * _bx) * t + _cx;

  double transform(double x) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    if (x1 == y1 && x2 == y2) return x;
    var t = x;
    for (var i = 0; i < 8; i++) {
      final err = _sampleX(t) - x;
      if (err.abs() < 1e-7) return _sampleY(t);
      final d = _slopeX(t);
      if (d.abs() < 1e-6) break;
      t -= err / d;
    }
    var lo = 0.0, hi = 1.0;
    t = x;
    while (lo < hi) {
      final v = _sampleX(t);
      if ((v - x).abs() < 1e-7) break;
      if (x > v) {
        lo = t;
      } else {
        hi = t;
      }
      t = (lo + hi) / 2;
      if (hi - lo < 1e-9) break;
    }
    return _sampleY(t);
  }
}
