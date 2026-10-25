import '../core/value_codec.dart';
import '../device/reduced_motion.dart';

/// Called when an animation ends: `finished` is true when it ran to its end,
/// false when it was cancelled or replaced by another animation.
typedef AnimationCallback = void Function(bool finished);

/// How an animation responds to the system's reduce-motion setting.
enum ReduceMotion {
  /// Follow the device setting (the default).
  system,

  /// Always behave as if reduce motion were on.
  always,

  /// Always animate, whatever the device setting.
  never,
}

/// Base class of every animation object: what `withTiming`, `withSpring`,
/// `withDecay` and the modifiers return.
///
/// An animation is assigned to a `SharedValue` with `sv.set(animation)`,
/// which starts it from the value's current state, as assigning an animation
/// to `sv.value` does in Reanimated. Like Reanimated's animation objects, each
/// instance runs once; create a new one for each assignment.
abstract class ReanimatedAnimation {
  ReanimatedAnimation({this.callback, this.reduceMotion});

  /// Called once when the animation ends.
  final AnimationCallback? callback;

  /// This animation's reduce-motion setting. Null inherits from the
  /// enclosing modifier, and at the top level means [ReduceMotion.system].
  final ReduceMotion? reduceMotion;

  late ValueCodec<Object?> codec;

  /// Current value of each component.
  List<double> current = const [];

  /// Current velocity of each component, in units per second.
  List<double> velocity = const [];

  bool _ended = false;

  /// Whether the animation has ended (finished or cancelled).
  bool get isFinished => _ended;

  ReduceMotion? _inherited;

  /// Whether this run should skip motion.
  bool get shouldReduceMotion {
    switch (reduceMotion ?? _inherited ?? ReduceMotion.system) {
      case ReduceMotion.always:
        return true;
      case ReduceMotion.never:
        return false;
      case ReduceMotion.system:
        return ReducedMotionConfig.shouldReduceMotion;
    }
  }

  /// Starts (or restarts) the animation from [from].
  ///
  /// [previousVelocity] is the velocity of the animation this one replaces,
  /// so a spring that interrupts another keeps its momentum. [reverseTo],
  /// set by `withRepeat(reverse: true)`, makes the animation head back to
  /// that value instead of its own target.
  void start(
    List<double> from, {
    required ValueCodec<Object?> codec,
    List<double>? previousVelocity,
    List<double>? reverseTo,
    ReduceMotion? inherited,
  }) {
    this.codec = codec;
    _inherited = inherited;
    _ended = false;
    current = List<double>.of(from);
    velocity = List<double>.filled(from.length, 0);
    onStart(from, previousVelocity, reverseTo);
  }

  /// Subclass setup for [start].
  void onStart(
      List<double> from, List<double>? previousVelocity, List<double>? reverseTo);

  /// Advances by [dt] seconds. Returns true once the animation has reached
  /// its end; it then calls [finish] itself.
  bool step(double dt);

  /// The value the animation is heading for, when it has one (decay has
  /// none until it stops).
  List<double>? get target => null;

  /// Ends the animation and fires [callback] once.
  void finish(bool finished) {
    if (_ended) return;
    _ended = true;
    callback?.call(finished);
  }

  /// Stops the animation where it is; [callback] receives false.
  void cancel() => finish(false);

  /// The reduce-motion setting children inherit from this animation.
  ReduceMotion? get inheritedForChildren => reduceMotion ?? _inherited;
}
