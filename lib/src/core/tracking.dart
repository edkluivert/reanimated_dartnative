import 'package:dartnative/dartnative.dart' show Listenable;

/// Records which reactive values an updater reads, so `useDerivedValue`,
/// `useAnimatedStyle`, `useAnimatedProps` and `useAnimatedReaction` follow
/// their dependencies without a dependency list, as Reanimated's worklets do.
///
/// Reading `SharedValue.value` (or `get()`) inside [track] registers the
/// value. Each run records afresh, so a branch that stops reading a value
/// stops depending on it.
abstract final class DependencyTracker {
  static final List<Set<Listenable>> _stack = [];

  /// Called by every reactive value when it is read.
  static void reportRead(Listenable source) {
    if (_stack.isNotEmpty) _stack.last.add(source);
  }

  /// Runs [body] and returns its result with the values it read.
  static (R result, Set<Listenable> dependencies) track<R>(R Function() body) {
    final deps = <Listenable>{};
    _stack.add(deps);
    try {
      return (body(), deps);
    } finally {
      _stack.removeLast();
    }
  }

  /// Runs [body] without recording reads (for example a callback fired from
  /// inside an updater).
  static R untracked<R>(R Function() body) {
    final saved = List<Set<Listenable>>.of(_stack);
    _stack.clear();
    try {
      return body();
    } finally {
      _stack.addAll(saved);
    }
  }
}

/// Subscribes to a changing set of [Listenable]s and calls [onChange] when
/// any of them notifies. [update] swaps the subscriptions for a new set.
class DependencySubscription {
  DependencySubscription(this.onChange);

  final void Function() onChange;
  Set<Listenable> _current = const {};

  void update(Set<Listenable> next) {
    for (final dep in _current) {
      if (!next.contains(dep)) dep.removeListener(onChange);
    }
    for (final dep in next) {
      if (!_current.contains(dep)) dep.addListener(onChange);
    }
    _current = next;
  }

  void dispose() => update(const {});
}
