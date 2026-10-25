import 'animation.dart';

/// Runs [animations] one after another; see [withSequence].
class SequenceAnimation extends ReanimatedAnimation {
  SequenceAnimation(this.animations, {super.reduceMotion, super.callback}) {
    if (animations.isEmpty) {
      throw ArgumentError('withSequence needs at least one animation.');
    }
  }

  final List<ReanimatedAnimation> animations;
  int _index = 0;

  @override
  List<double>? get target => animations.last.target;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    _index = 0;
    _startChild(from, previousVelocity);
  }

  void _startChild(List<double> from, List<double>? previousVelocity) {
    animations[_index].start(
      from,
      codec: codec,
      previousVelocity: previousVelocity,
      inherited: inheritedForChildren,
    );
  }

  @override
  bool step(double dt) {
    while (true) {
      final child = animations[_index];
      final done = child.step(dt);
      current = child.current;
      velocity = child.velocity;
      if (!done) return false;
      _index++;
      if (_index >= animations.length) {
        finish(true);
        return true;
      }
      _startChild(current, velocity);
      dt = 0; // the next child begins on this frame
      // A child that reduces motion jumps straight to its end; keep going
      // so a reduced sequence settles in one frame.
      if (!animations[_index].shouldReduceMotion) {
        return false;
      }
    }
  }

  @override
  void cancel() {
    if (isFinished) return;
    if (_index < animations.length) animations[_index].cancel();
    finish(false);
  }
}

/// Runs [animations] in order, each starting where the previous one ended,
/// as Reanimated's `withSequence`.
///
/// ```dart
/// offset.set(withSequence([
///   withTiming(-angle, duration: const Duration(milliseconds: 50)),
///   withRepeat(withTiming(angle, duration: const Duration(milliseconds: 100)),
///       numberOfReps: 5, reverse: true),
///   withTiming(0, duration: const Duration(milliseconds: 50)),
/// ]));
/// ```
SequenceAnimation withSequence(
  List<ReanimatedAnimation> animations, {
  ReduceMotion? reduceMotion,
  AnimationCallback? callback,
}) =>
    SequenceAnimation(animations, reduceMotion: reduceMotion, callback: callback);

/// Repeats [animation]; see [withRepeat].
class RepeatAnimation extends ReanimatedAnimation {
  RepeatAnimation(
    this.animation, {
    this.numberOfReps = 2,
    this.reverse = false,
    super.reduceMotion,
    super.callback,
  });

  final ReanimatedAnimation animation;

  /// How many times to run. Zero or less repeats until cancelled.
  final int numberOfReps;

  /// Run every other repetition backwards. Works with animation functions
  /// (`withTiming`, `withSpring`), not with other modifiers, as in Reanimated.
  final bool reverse;

  bool get isInfinite => numberOfReps <= 0;

  late List<double> _startValue;
  List<double>? _forwardTarget;
  int _done = 0;
  bool _skip = false;

  @override
  List<double>? get target => animation.target;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    _startValue = List<double>.of(from);
    _forwardTarget = null;
    _done = 0;
    // Reduced motion: infinite loops and even reversed loops (which end where
    // they start) do not run at all; anything else runs once.
    _skip = shouldReduceMotion &&
        (isInfinite || (reverse && numberOfReps.isEven));
    if (!_skip) _startIteration(from, previousVelocity);
  }

  bool get _supportsReverse =>
      animation is! SequenceAnimation &&
      animation is! RepeatAnimation &&
      animation is! DelayAnimation;

  void _startIteration(List<double> from, List<double>? previousVelocity) {
    final backwards = reverse && _supportsReverse && _done.isOdd;
    animation.start(
      backwards ? from : (reverse && _supportsReverse ? from : _startValue),
      codec: codec,
      previousVelocity: previousVelocity,
      reverseTo: backwards ? _startValue : _forwardTarget,
      inherited: inheritedForChildren,
    );
  }

  @override
  bool step(double dt) {
    if (_skip) {
      finish(true);
      return true;
    }
    final done = animation.step(dt);
    current = animation.current;
    velocity = animation.velocity;
    if (!done) return false;
    if (_done == 0) _forwardTarget = animation.target ?? List.of(current);
    _done++;
    final reps = shouldReduceMotion ? 1 : numberOfReps;
    if (!isInfinite && _done >= reps || (shouldReduceMotion && _done >= 1)) {
      finish(true);
      return true;
    }
    _startIteration(current, velocity);
    return false;
  }

  @override
  void cancel() {
    if (isFinished) return;
    animation.cancel();
    finish(false);
  }
}

/// Repeats [animation] [numberOfReps] times, as Reanimated's `withRepeat`.
///
/// [numberOfReps] defaults to 2; zero or less repeats until the animation is
/// cancelled. With [reverse], every other repetition plays backwards (for
/// animation functions; modifiers replay forwards). Without it, each
/// repetition starts again from the value the repeat started at.
///
/// ```dart
/// offset.set(withRepeat(withTiming(-offset.value), numberOfReps: -1, reverse: true));
/// ```
RepeatAnimation withRepeat(
  ReanimatedAnimation animation, {
  int numberOfReps = 2,
  bool reverse = false,
  ReduceMotion? reduceMotion,
  AnimationCallback? callback,
}) =>
    RepeatAnimation(
      animation,
      numberOfReps: numberOfReps,
      reverse: reverse,
      reduceMotion: reduceMotion,
      callback: callback,
    );

/// Waits [delay] before running [animation]; see [withDelay].
class DelayAnimation extends ReanimatedAnimation {
  DelayAnimation(this.delay, this.animation, {super.reduceMotion});

  final Duration delay;
  final ReanimatedAnimation animation;

  double _waited = 0;
  bool _started = false;
  List<double>? _previousVelocity;

  @override
  List<double>? get target => animation.target;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    _waited = 0;
    _started = false;
    _previousVelocity = previousVelocity;
    _reverseTo = reverseTo;
    if (shouldReduceMotion || delay <= Duration.zero) _startInner();
  }

  List<double>? _reverseTo;

  void _startInner() {
    _started = true;
    animation.start(
      current,
      codec: codec,
      previousVelocity: _previousVelocity,
      reverseTo: _reverseTo,
      inherited: inheritedForChildren,
    );
  }

  @override
  bool step(double dt) {
    if (!_started) {
      _waited += dt;
      final total = delay.inMicroseconds / 1e6;
      if (_waited < total) return false;
      dt = _waited - total;
      _startInner();
    }
    final done = animation.step(dt);
    current = animation.current;
    velocity = animation.velocity;
    if (done) finish(true);
    return done;
  }

  @override
  void cancel() {
    if (isFinished) return;
    if (_started) animation.cancel();
    finish(false);
  }
}

/// Starts [animation] after [delay], as Reanimated's `withDelay`. With
/// reduced motion the delay is skipped.
///
/// ```dart
/// offset.set(withDelay(const Duration(milliseconds: 1000), withTiming(100)));
/// ```
DelayAnimation withDelay(
  Duration delay,
  ReanimatedAnimation animation, {
  ReduceMotion? reduceMotion,
}) =>
    DelayAnimation(delay, animation, reduceMotion: reduceMotion);

/// Keeps [animation]'s output within [min] and [max]; see [withClamp].
class ClampAnimation extends ReanimatedAnimation {
  ClampAnimation(this.animation, {this.min, this.max, super.reduceMotion}) {
    if (min != null && max != null && min! > max!) {
      throw ArgumentError('withClamp: min ($min) is greater than max ($max).');
    }
  }

  final ReanimatedAnimation animation;
  final double? min;
  final double? max;

  @override
  List<double>? get target => animation.target;

  @override
  void onStart(List<double> from, List<double>? previousVelocity,
      List<double>? reverseTo) {
    animation.start(
      from,
      codec: codec,
      previousVelocity: previousVelocity,
      reverseTo: reverseTo,
      inherited: inheritedForChildren,
    );
  }

  @override
  bool step(double dt) {
    final done = animation.step(dt);
    current = [
      for (final c in animation.current)
        c.clamp(min ?? double.negativeInfinity, max ?? double.infinity)
            .toDouble(),
    ];
    velocity = animation.velocity;
    if (done) finish(true);
    return done;
  }

  @override
  void cancel() {
    if (isFinished) return;
    animation.cancel();
    finish(false);
  }
}

/// Limits [animation]'s values to [min]..[max], as Reanimated's
/// `withClamp`. Mostly useful to stop a bouncy spring from overshooting
/// a limit.
///
/// ```dart
/// width.set(withClamp(min: 0, max: 300, withSpring(320, dampingRatio: 0.3)));
/// ```
ClampAnimation withClamp(
  ReanimatedAnimation animation, {
  double? min,
  double? max,
  ReduceMotion? reduceMotion,
}) =>
    ClampAnimation(animation, min: min, max: max, reduceMotion: reduceMotion);
