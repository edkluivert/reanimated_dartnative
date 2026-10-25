import 'dart:math' as math;

import 'animation.dart';

/// Keeps moving at [velocity] and slows down until it stops, like a flung
/// scroll view. See [withDecay].
class DecayAnimation extends ReanimatedAnimation {
  DecayAnimation({
    this.initialVelocity = 0,
    this.deceleration = 0.998,
    this.clamp,
    this.velocityFactor = 1,
    this.rubberBandEffect = false,
    this.rubberBandFactor = 0.6,
    super.reduceMotion,
    super.callback,
  }) {
    if (deceleration <= 0 || deceleration >= 1) {
      throw ArgumentError('deceleration must be between 0 and 1.');
    }
    if (rubberBandEffect && clamp == null) {
      throw ArgumentError('withDecay: rubberBandEffect needs clamp bounds.');
    }
  }

  /// Initial velocity in units per second: a number, or a value of the
  /// shared value's type (an `Offset` for a 2D fling).
  final Object initialVelocity;

  /// Rate of slowing down per millisecond. 0.998 is a scroll view's feel.
  final double deceleration;

  /// Bounds the decay stops at, or bounces off with [rubberBandEffect].
  final (double, double)? clamp;

  /// Multiplies the velocity's effect on position.
  final double velocityFactor;

  /// Overshoot [clamp] and spring back instead of stopping at it.
  final bool rubberBandEffect;

  /// Strength of the rubber band's pull back.
  final double rubberBandFactor;

  static const double _velocityEps = 1;
  static const double _derivativeEps = 0.1;

  late List<bool> _done;
  late List<bool> _springActive;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    velocity = codec.encodeAny(initialVelocity);
    _done = List<bool>.filled(from.length, false);
    _springActive = List<bool>.filled(from.length, false);
  }

  @override
  bool step(double dt) {
    if (shouldReduceMotion) {
      // Reduced motion: stay where it is (inside the bounds).
      final c = clamp;
      if (c != null) {
        current = [for (final x in current) x.clamp(c.$1, c.$2).toDouble()];
      }
      velocity = List<double>.filled(current.length, 0);
      finish(true);
      return true;
    }
    final ms = math.min(dt * 1000, 64.0);
    for (var i = 0; i < current.length; i++) {
      if (_done[i]) continue;
      if (rubberBandEffect) {
        _stepRubberBand(i, ms);
      } else {
        _stepRigid(i, ms);
      }
    }
    if (_done.every((d) => d)) {
      velocity = List<double>.filled(current.length, 0);
      finish(true);
      return true;
    }
    return false;
  }

  void _stepRigid(int i, double ms) {
    final kv = math.pow(deceleration, ms).toDouble();
    final kx = deceleration * (1 - kv) / (1 - deceleration);
    final v0 = velocity[i] / 1000 * velocityFactor;
    var x = current[i] + v0 * kx;
    final v = velocity[i] * kv;
    final c = clamp;
    if (c != null && (x <= c.$1 || x >= c.$2)) {
      x = x.clamp(c.$1, c.$2).toDouble();
      _done[i] = true;
    }
    current[i] = x;
    velocity[i] = v;
    if (v.abs() < _velocityEps) _done[i] = true;
  }

  void _stepRubberBand(int i, double ms) {
    final c = clamp!;
    final x = current[i];
    final nearest = (x - c.$1).abs() < (x - c.$2).abs() ? c.$1 : c.$2;
    var derivative = 0.0;
    if (x < c.$1 || x > c.$2) derivative = x - nearest;
    final v = velocity[i] * math.pow(deceleration, ms) -
        derivative * rubberBandFactor;
    if (derivative.abs() > _derivativeEps) {
      _springActive[i] = true;
    } else if (_springActive[i]) {
      current[i] = nearest;
      velocity[i] = 0;
      _done[i] = true;
      return;
    } else if (v.abs() < _velocityEps) {
      velocity[i] = 0;
      _done[i] = true;
      return;
    }
    current[i] = x + v * velocityFactor * ms / 1000;
    velocity[i] = v;
  }
}

/// Starts at [velocity] and slows down until it stops, as Reanimated's
/// `withDecay`. Use it with a gesture's release velocity.
///
/// ```dart
/// onPanEnd: (d) => offset.set(withDecay(
///   velocity: d.velocity.pixelsPerSecond.dx,
///   rubberBandEffect: true,
///   clamp: (-boundary, boundary),
/// )),
/// ```
DecayAnimation withDecay({
  Object velocity = 0,
  double deceleration = 0.998,
  (double, double)? clamp,
  double velocityFactor = 1,
  bool rubberBandEffect = false,
  double rubberBandFactor = 0.6,
  ReduceMotion? reduceMotion,
  AnimationCallback? callback,
}) =>
    DecayAnimation(
      initialVelocity: velocity,
      deceleration: deceleration,
      clamp: clamp,
      velocityFactor: velocityFactor,
      rubberBandEffect: rubberBandEffect,
      rubberBandFactor: rubberBandFactor,
      reduceMotion: reduceMotion,
      callback: callback,
    );
