import 'dart:math' as math;

import 'animation.dart';

/// Spring settings, as Reanimated 4's `withSpring` config.
///
/// A spring is either physics-based ([stiffness], [damping]) or
/// duration-based ([duration], [dampingRatio]). Setting [duration] or
/// [dampingRatio] makes it duration-based, and the physics values are then
/// ignored, as in Reanimated.
class SpringConfig {
  const SpringConfig({
    this.mass = 4,
    this.stiffness = 900,
    this.damping = 120,
    this.duration,
    this.dampingRatio,
    this.velocity,
    this.overshootClamping = false,
    this.energyThreshold = 6e-9,
    this.clamp,
  });

  /// Inertia: heavier springs start and stop more slowly.
  final double mass;

  /// Bounciness: stiffer springs move faster and overshoot more.
  final double stiffness;

  /// How quickly the spring settles.
  final double damping;

  /// Perceptual duration of a duration-based spring. The spring settles at
  /// about 1.5 × this, as in Reanimated 4. Default 550 ms when only
  /// [dampingRatio] is given.
  final Duration? duration;

  /// Damping of a duration-based spring: below 1 bounces, 1 is critically
  /// damped (no bounce). Default 1 when only [duration] is given.
  final double? dampingRatio;

  /// Starting velocity in units per second: a number, or a value of the
  /// same type as the shared value. When null, the spring inherits the
  /// velocity of the animation it interrupts.
  final Object? velocity;

  /// Stop as soon as the spring reaches its target instead of bouncing past.
  final bool overshootClamping;

  /// The spring is at rest when its energy (kinetic plus potential) falls
  /// below this fraction of the energy it started with.
  final double energyThreshold;

  /// Bounds the spring should not bounce past. Damping is raised until the
  /// motion stays inside them.
  final ({double? min, double? max})? clamp;

  bool get isDurationBased => duration != null || dampingRatio != null;
}

/// A physics spring, solved in closed form for each component.
class SpringAnimation extends ReanimatedAnimation {
  SpringAnimation(
    this.toValue, {
    this.config = const SpringConfig(),
    super.reduceMotion,
    super.callback,
  });

  final Object toValue;
  final SpringConfig config;

  late List<double> _to;
  late List<double> _x0; // displacement from target at start
  late List<double> _v0;
  late List<bool> _settled;
  double _m = 1, _k = 1, _c = 1;
  double _elapsed = 0;
  double _energy0 = 0;
  double? _endTime;

  @override
  List<double>? get target => _to;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    _to = reverseTo ?? codec.encodeAny(toValue);
    _x0 = [for (var i = 0; i < from.length; i++) from[i] - _to[i]];
    _v0 = config.velocity != null
        ? codec.encodeAny(config.velocity)
        : (previousVelocity != null && previousVelocity.length == from.length
            ? List<double>.of(previousVelocity)
            : List<double>.filled(from.length, 0));
    velocity = List<double>.of(_v0);
    _settled = List<bool>.filled(from.length, false);
    _elapsed = 0;

    _m = config.mass > 0 ? config.mass : 1;
    if (config.isDurationBased) {
      final perceptual =
          (config.duration ?? const Duration(milliseconds: 550)).inMicroseconds /
              1e6;
      final zeta = config.dampingRatio ?? 1.0;
      final omega0 = 2 * math.pi / perceptual;
      _k = _m * omega0 * omega0;
      _c = 2 * zeta * _m * omega0;
      _endTime = perceptual * 1.5;
    } else {
      _k = config.stiffness > 0 ? config.stiffness : 1;
      _c = config.damping >= 0 ? config.damping : 0;
      _endTime = null;
    }
    if (config.clamp != null) _fitDampingToClamp();

    _energy0 = _energy(_x0, _v0);
  }

  double _energy(List<double> x, List<double> v) {
    var e = 0.0;
    for (var i = 0; i < x.length; i++) {
      e += 0.5 * _k * x[i] * x[i] + 0.5 * _m * v[i] * v[i];
    }
    return e;
  }

  /// Raises damping until no component's path leaves the clamp bounds, as
  /// Reanimated lowers the bounce when `clamp` would be exceeded.
  void _fitDampingToClamp() {
    final lo = config.clamp!.min, hi = config.clamp!.max;
    final critical = 2 * math.sqrt(_k * _m);
    bool fits() {
      for (var t = 0.0; t < 3; t += 1 / 120) {
        for (var i = 0; i < _to.length; i++) {
          final x = _solve(i, t).$1 + _to[i];
          if ((lo != null && x < lo - 1e-6) || (hi != null && x > hi + 1e-6)) {
            return false;
          }
        }
      }
      return true;
    }

    while (_c < critical && !fits()) {
      _c = math.min(critical, _c + critical * 0.05);
    }
  }

  /// Displacement and velocity of component [i] at time [t].
  (double, double) _solve(int i, double t) {
    final x0 = _x0[i], v0 = _v0[i];
    final omega0 = math.sqrt(_k / _m);
    final gamma = _c / (2 * _m);
    final zeta = gamma / omega0;
    if (zeta < 1 - 1e-6) {
      final omega1 = math.sqrt(omega0 * omega0 - gamma * gamma);
      final b = (v0 + gamma * x0) / omega1;
      final e = math.exp(-gamma * t);
      final cos = math.cos(omega1 * t), sin = math.sin(omega1 * t);
      return (
        e * (x0 * cos + b * sin),
        e * ((omega1 * b - gamma * x0) * cos - (omega1 * x0 + gamma * b) * sin),
      );
    }
    if (zeta <= 1 + 1e-6) {
      final b = v0 + gamma * x0;
      final e = math.exp(-gamma * t);
      return (e * (x0 + b * t), e * (b - gamma * (x0 + b * t)));
    }
    final alpha = math.sqrt(gamma * gamma - omega0 * omega0);
    final r1 = -gamma + alpha, r2 = -gamma - alpha;
    final c1 = (v0 - r2 * x0) / (r1 - r2);
    final c2 = x0 - c1;
    final e1 = math.exp(r1 * t), e2 = math.exp(r2 * t);
    return (c1 * e1 + c2 * e2, c1 * r1 * e1 + c2 * r2 * e2);
  }

  void _snapToTarget() {
    current = List<double>.of(_to);
    velocity = List<double>.filled(_to.length, 0);
    finish(true);
  }

  @override
  bool step(double dt) {
    if (shouldReduceMotion || _energy0 < 1e-12) {
      _snapToTarget();
      return true;
    }
    _elapsed += dt;
    final x = List<double>.filled(_to.length, 0);
    final v = List<double>.filled(_to.length, 0);
    for (var i = 0; i < _to.length; i++) {
      if (_settled[i]) continue;
      final (xi, vi) = _solve(i, _elapsed);
      if (config.overshootClamping && _x0[i] != 0 && xi.sign != _x0[i].sign) {
        _settled[i] = true; // crossed the target
        continue;
      }
      x[i] = xi;
      v[i] = vi;
    }
    current = [for (var i = 0; i < _to.length; i++) _to[i] + x[i]];
    velocity = v;

    final allSettled = _settled.every((s) => s);
    final atRest = _energy(x, v) / _energy0 < config.energyThreshold;
    final timeUp = _endTime != null && _elapsed >= _endTime!;
    if (allSettled || atRest || timeUp) {
      _snapToTarget();
      return true;
    }
    final clamp = config.clamp;
    if (clamp != null) {
      current = [
        for (final c in current)
          c.clamp(clamp.min ?? double.negativeInfinity,
              clamp.max ?? double.infinity),
      ];
    }
    return false;
  }
}

/// Animates a shared value to [toValue] with spring physics, as
/// Reanimated's `withSpring`.
///
/// Reanimated 4 defaults: mass 4, stiffness 900, damping 120 (critically
/// damped, no bounce). Pass [duration] and/or [dampingRatio] for a
/// duration-based spring (550 ms perceptual, ratio 1 by default). With no
/// [velocity], a spring that interrupts another animation keeps that
/// animation's velocity.
///
/// ```dart
/// offset.set(withSpring(0, dampingRatio: 0.5, duration: Duration(milliseconds: 800)));
/// ```
SpringAnimation withSpring(
  Object toValue, {
  double mass = 4,
  double stiffness = 900,
  double damping = 120,
  Duration? duration,
  double? dampingRatio,
  Object? velocity,
  bool overshootClamping = false,
  double energyThreshold = 6e-9,
  ({double? min, double? max})? clamp,
  ReduceMotion? reduceMotion,
  AnimationCallback? callback,
}) =>
    SpringAnimation(
      toValue,
      config: SpringConfig(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
        duration: duration,
        dampingRatio: dampingRatio,
        velocity: velocity,
        overshootClamping: overshootClamping,
        energyThreshold: energyThreshold,
        clamp: clamp,
      ),
      reduceMotion: reduceMotion,
      callback: callback,
    );
