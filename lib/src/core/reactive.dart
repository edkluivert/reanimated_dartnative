import 'shared_value.dart';
import 'tracking.dart';

/// A read-only [SharedValue] computed from other shared values, as
/// Reanimated's `useDerivedValue`. It recomputes whenever a shared value its
/// updater read changes; no dependency list is needed.
class DerivedValue<T> extends SharedValue<T> {
  DerivedValue(this._updater) : super(_initial(_updater)) {
    _subscription = DependencySubscription(_recompute);
    _recompute();
  }

  static T _initial<T>(T Function() updater) =>
      DependencyTracker.untracked(updater);

  final T Function() _updater;
  late final DependencySubscription _subscription;

  void _recompute() {
    final (result, deps) = DependencyTracker.track(_updater);
    _subscription.update(deps..remove(this));
    writeInternal(result);
  }

  @override
  set value(T newValue) =>
      throw UnsupportedError('A derived value is read-only.');

  @override
  void set(Object? valueOrAnimation) =>
      throw UnsupportedError('A derived value is read-only.');

  @override
  void dispose() {
    _subscription.dispose();
    super.dispose();
  }
}

/// Creates a [DerivedValue], as Reanimated's `useDerivedValue`.
///
/// ```dart
/// final sv = useSharedValue(0.0);
/// final derived = useDerivedValue(() => sv.value * 50);
/// ```
DerivedValue<T> useDerivedValue<T>(T Function() updater) =>
    DerivedValue<T>(updater);

/// Watches what [prepare] returns and calls [react] when it changes, as
/// Reanimated's `useAnimatedReaction`. [react] first runs once with
/// `previous` null. Shared values read in [prepare] are tracked; [react]'s
/// reads are not, so it may write to shared values (but not to one
/// [prepare] reads, which would loop).
class AnimatedReaction<T> {
  AnimatedReaction(this._prepare, this._react) {
    _subscription = DependencySubscription(_run);
    _run();
  }

  final T Function() _prepare;
  final void Function(T current, T? previous) _react;
  late final DependencySubscription _subscription;
  bool _hasRun = false;
  T? _previous;
  bool _disposed = false;

  void _run() {
    if (_disposed) return;
    final (current, deps) = DependencyTracker.track(_prepare);
    _subscription.update(deps);
    if (_hasRun && current == _previous) return;
    final previous = _hasRun ? _previous : null;
    _hasRun = true;
    _previous = current;
    DependencyTracker.untracked(() => _react(current, previous));
  }

  void dispose() {
    _disposed = true;
    _subscription.dispose();
  }
}

/// Creates an [AnimatedReaction], as Reanimated's `useAnimatedReaction`.
///
/// ```dart
/// useAnimatedReaction(
///   () => width.value,
///   (current, previous) {
///     if (current > 200) height.set(withSpring(current / 2));
///   },
/// );
/// ```
AnimatedReaction<T> useAnimatedReaction<T>(
  T Function() prepare,
  void Function(T current, T? previous) react,
) =>
    AnimatedReaction<T>(prepare, react);

/// A shared value that animates to whatever [updater] returns, as
/// Reanimated's `useDerivedValue(() => withTiming(...))` and its
/// animations-inside-`useAnimatedStyle` pattern.
///
/// [updater] returns an animation (or a plain value). It re-runs whenever a
/// shared value it read changes, and the new animation starts from where the
/// previous one is, keeping its velocity.
///
/// ```dart
/// final isExpanded = useSharedValue(false);
/// final height = useSharedValue(0.0); // measured
/// final derivedHeight = useDerivedAnimation(0.0,
///     () => withTiming(height.value * (isExpanded.value ? 1 : 0)));
/// ```
class DerivedAnimation<T> extends SharedValue<T> {
  DerivedAnimation(super.initialValue, this._updater) {
    _subscription = DependencySubscription(_recompute);
    _recompute();
  }

  final Object? Function() _updater;
  late final DependencySubscription _subscription;

  void _recompute() {
    final (result, deps) = DependencyTracker.track(_updater);
    _subscription.update(deps..remove(this));
    DependencyTracker.untracked(() => super.set(result));
  }

  @override
  void dispose() {
    _subscription.dispose();
    super.dispose();
  }
}

/// Creates a [DerivedAnimation] starting at [initialValue].
DerivedAnimation<T> useDerivedAnimation<T>(T initialValue, Object? Function() updater) =>
    DerivedAnimation<T>(initialValue, updater);
