import 'package:dartnative/dartnative.dart' show ValueListenable, VoidCallback;
import 'package:meta/meta.dart' show internal;

import '../animations/animation.dart';
import 'clock.dart';
import 'tracking.dart';
import 'value_codec.dart';

/// A reactive value that animations drive, as Reanimated's shared value.
///
/// * Read it with [value] or [get]. Reads inside `useDerivedValue`,
///   `useAnimatedStyle`, `useAnimatedProps` and `useAnimatedReaction` are
///   tracked, so those update when this value changes.
/// * Write a plain value with [value] or [set]; start an animation with
///   [set] (`sv.set(withSpring(1))`), the Dart spelling of Reanimated's
///   `sv.value = withSpring(1)`.
/// * Writing never rebuilds widgets by itself. `AnimatedView` and anything
///   listening (it is a [ValueListenable], so `ValueListenableBuilder` and
///   `AnimatedBuilder` work) update on their own, without `setState`.
///
/// Numbers, `Color`s, `Offset`s, `Size`s and `List<double>`s can be animated.
class SharedValue<T> implements ValueListenable<T> {
  SharedValue(T initialValue) : _value = initialValue;

  T _value;
  final List<VoidCallback> _listeners = [];
  _ActiveAnimation<T>? _active;
  List<double>? _lastVelocity;
  bool _disposed = false;

  /// The current value. Assigning cancels a running animation.
  @override
  T get value {
    DependencyTracker.reportRead(this);
    return _value;
  }

  set value(T newValue) {
    _cancelActive();
    _write(newValue);
  }

  /// Reads the value, as Reanimated 4's `sv.get()`.
  T get() => value;

  /// Sets a plain value or starts an animation, as Reanimated 4's
  /// `sv.set(...)`. [valueOrAnimation] is a `T`, a [ReanimatedAnimation], or
  /// a function from the current value to either.
  void set(Object? valueOrAnimation) {
    var next = valueOrAnimation;
    if (next is Function) {
      next = (next as dynamic)(_value);
    }
    if (next is ReanimatedAnimation) {
      _startAnimation(next);
    } else if (next is T) {
      value = next;
    } else {
      throw ArgumentError(
          'SharedValue<$T>.set expects a $T or an animation, got '
          '${next.runtimeType}.');
    }
  }

  /// Updates the value in place with [modifier], as Reanimated's
  /// `sv.modify`. Listeners are notified even when [modifier] mutates and
  /// returns the same object, which suits large lists and maps.
  void modify([T Function(T value)? modifier, bool forceUpdate = true]) {
    _cancelActive();
    final next = modifier == null ? _value : modifier(_value);
    if (forceUpdate || next != _value) {
      _value = next;
      notifyListeners();
    } else {
      _value = next;
    }
  }

  /// Starts [animation] from the current value.
  void animate(ReanimatedAnimation animation) => _startAnimation(animation);

  /// Whether an animation is running on this value.
  bool get isAnimating => _active != null;

  /// The running animation's velocity per component, in units per second
  /// (null when idle).
  List<double>? get velocity => _active?.animation.velocity;

  void _startAnimation(ReanimatedAnimation animation) {
    if (_disposed) return;
    final codec = ValueCodec.of<T>(_value);
    final previous = _active?.animation.velocity ?? _lastVelocity;
    _cancelActive();
    animation.start(
      codec.encode(_value),
      codec: codec as ValueCodec<Object?>,
      previousVelocity: previous,
    );
    final active = _ActiveAnimation<T>(this, animation, codec);
    _active = active;
    AnimationClock.instance.add(active);
  }

  void _cancelActive() {
    final active = _active;
    if (active == null) return;
    _active = null;
    _lastVelocity = null;
    AnimationClock.instance.remove(active);
    active.animation.cancel();
  }

  /// Writes without cancelling an animation. For derived values.
  @internal
  void writeInternal(T next) => _write(next);

  bool _notifyQueued = false;

  /// Writes an animation's frame value now and notifies listeners after
  /// the frame's other animations have stepped.
  void _writeFromFrame(T next) {
    if (_disposed || next == _value) return;
    _value = next;
    if (_notifyQueued) return;
    _notifyQueued = true;
    AnimationClock.instance.notifyAfterFrame(() {
      _notifyQueued = false;
      if (!_disposed) notifyListeners();
    });
  }

  void _write(T next) {
    if (_disposed) return;
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  /// Stops a running animation where it is, as Reanimated's
  /// `cancelAnimation(sv)`.
  void cancelAnimation() => _cancelActive();

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  /// Cancels any animation and drops all listeners.
  void dispose() {
    _cancelActive();
    _listeners.clear();
    _disposed = true;
  }

  @override
  String toString() => 'SharedValue<$T>($_value)';
}

class _ActiveAnimation<T> implements FrameDriven {
  _ActiveAnimation(this.owner, this.animation, this.codec);

  final SharedValue<T> owner;
  final ReanimatedAnimation animation;
  final ValueCodec<T> codec;

  @override
  bool onFrame(double dt, Duration timestamp) {
    if (owner._active != this) return false;
    final done = animation.step(dt);
    if (owner._active != this) return false; // replaced from a callback
    owner._writeFromFrame(codec.decode(animation.current));
    if (done) {
      owner._active = null;
      owner._lastVelocity = null;
      return false;
    }
    return true;
  }
}

/// Creates a [SharedValue], as Reanimated's `useSharedValue`.
///
/// Create it once (a `State` field, or `useSharedValue` from
/// `ReanimatedStateMixin`, which also disposes it) rather than in `build`.
SharedValue<T> useSharedValue<T>(T initialValue) => SharedValue<T>(initialValue);

/// Creates a [SharedValue] outside a widget, as Reanimated's `makeMutable`.
/// Nothing disposes it for you; call [SharedValue.dispose] (which also
/// cancels its animation) when done.
SharedValue<T> makeMutable<T>(T initialValue) => SharedValue<T>(initialValue);

/// Stops the animation running on [sharedValue], leaving it where it is, as
/// Reanimated's `cancelAnimation`. Does nothing when nothing is running.
void cancelAnimation(SharedValue<Object?> sharedValue) =>
    sharedValue.cancelAnimation();
