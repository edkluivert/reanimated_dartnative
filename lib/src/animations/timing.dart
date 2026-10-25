import '../easing/easing.dart';
import 'animation.dart';

/// The easing [withTiming] uses when none is given.
final EasingFunction defaultTimingEasing = Easing.inOut(Easing.quad);

/// Animates to [toValue] over [duration] along [easing].
class TimingAnimation extends ReanimatedAnimation {
  TimingAnimation(
    this.toValue, {
    this.duration = const Duration(milliseconds: 300),
    EasingFunction? easing,
    super.reduceMotion,
    super.callback,
  }) : easing = easing ?? defaultTimingEasing;

  /// A number, [Color] (or CSS color string), `Offset`, `Size` or
  /// `List<double>`, matching the shared value it is assigned to.
  final Object toValue;
  final Duration duration;
  final EasingFunction easing;

  late List<double> _from;
  late List<double> _to;
  double _elapsed = 0;

  @override
  List<double>? get target => _to;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    _from = List<double>.of(from);
    _to = reverseTo ?? codec.encodeAny(toValue);
    _elapsed = 0;
  }

  @override
  bool step(double dt) {
    final total = duration.inMicroseconds / 1e6;
    if (shouldReduceMotion || total <= 0) {
      current = List<double>.of(_to);
      velocity = List<double>.filled(_to.length, 0);
      finish(true);
      return true;
    }
    _elapsed += dt;
    // Tolerate rounding in summed frame times so an animation ends on the
    // frame its duration does.
    final t = _elapsed >= total - 1e-6 ? 1.0 : (_elapsed / total).clamp(0.0, 1.0);
    final e = easing(t);
    final next = [
      for (var i = 0; i < _to.length; i++) _from[i] + (_to[i] - _from[i]) * e,
    ];
    velocity = [
      for (var i = 0; i < next.length; i++)
        dt > 0 ? (next[i] - current[i]) / dt : 0.0,
    ];
    current = next;
    if (t >= 1) {
      current = List<double>.of(_to);
      finish(true);
      return true;
    }
    return false;
  }
}

/// Animates a shared value to [toValue] over [duration] along [easing], as
/// Reanimated's `withTiming`.
///
/// Defaults: 300 ms, `Easing.inOut(Easing.quad)`, [ReduceMotion.system].
///
/// ```dart
/// width.set(withTiming(width.value + 50,
///     duration: const Duration(milliseconds: 500),
///     easing: Easing.inOut(Easing.quad)));
/// ```
TimingAnimation withTiming(
  Object toValue, {
  Duration duration = const Duration(milliseconds: 300),
  EasingFunction? easing,
  ReduceMotion? reduceMotion,
  AnimationCallback? callback,
}) =>
    TimingAnimation(
      toValue,
      duration: duration,
      easing: easing,
      reduceMotion: reduceMotion,
      callback: callback,
    );
