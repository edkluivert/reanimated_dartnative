import 'package:dartnative/dartnative.dart';

/// Keeps removed children on screen while their exiting animations play.
///
/// In React Native a component's `exiting` animation runs when it unmounts.
/// A DartNative widget is gone as soon as its parent rebuilds without it, so
/// the list that children come and go from is wrapped in an
/// [AnimatedPresence]: when a keyed child disappears from [children], it
/// stays in place, every `AnimatedView` inside it plays its `exiting`
/// animation, and then it is removed.
///
/// ```dart
/// AnimatedPresence(
///   children: [
///     if (visible)
///       AnimatedView(
///         key: const ValueKey('box'),
///         entering: FadeIn(),
///         exiting: FadeOut(),
///         child: box,
///       ),
///   ],
/// )
/// ```
///
/// Children need keys. [builder] lays them out (a [Column] by default).
class AnimatedPresence extends StatefulWidget {
  const AnimatedPresence({super.key, required this.children, this.builder});

  final List<Widget> children;
  final Widget Function(BuildContext context, List<Widget> children)? builder;

  @override
  State<AnimatedPresence> createState() => _AnimatedPresenceState();
}

class _Entry {
  _Entry(this.key, this.widget);
  final Key key;
  Widget widget;
  bool exiting = false;
  int pending = 0;
  bool removed = false;
}

class _AnimatedPresenceState extends State<AnimatedPresence> {
  List<_Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _entries = [for (final c in widget.children) _Entry(_keyOf(c), c)];
  }

  Key _keyOf(Widget child) {
    final key = child.key;
    if (key == null) {
      throw ArgumentError('AnimatedPresence children need keys.');
    }
    return key;
  }

  @override
  void didUpdateWidget(AnimatedPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = <_Entry>[];
    final byKey = {for (final e in _entries) e.key: e};
    final newKeys = <Key>{};
    for (final child in widget.children) {
      final key = _keyOf(child);
      newKeys.add(key);
      final existing = byKey[key];
      if (existing != null) {
        existing
          ..widget = child
          ..exiting = false;
        next.add(existing);
      } else {
        next.add(_Entry(key, child));
      }
    }
    // Removed children keep their place, after the entry that preceded them.
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (newKeys.contains(e.key)) continue;
      if (!e.exiting) {
        e.exiting = true;
        e.pending = 0;
        _scheduleRemovalCheck(e);
      }
      var insertAt = 0;
      for (var j = i - 1; j >= 0; j--) {
        final idx = next.indexWhere((n) => n.key == _entries[j].key);
        if (idx >= 0) {
          insertAt = idx + 1;
          break;
        }
      }
      next.insert(insertAt, e);
    }
    _entries = next;
  }

  /// A child with no exiting animation is removed after one frame.
  void _scheduleRemovalCheck(_Entry e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && e.exiting && e.pending == 0) _remove(e);
    });
  }

  void _remove(_Entry e) {
    if (e.removed || !e.exiting) return;
    e.removed = true;
    setState(() => _entries.remove(e));
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final e in _entries)
        ExitingScope(
          key: e.key,
          exiting: e.exiting,
          onBegin: () => e.pending++,
          onDone: () {
            e.pending--;
            if (e.pending <= 0) _remove(e);
          },
          child: e.widget,
        ),
    ];
    final builder = widget.builder;
    return builder != null
        ? builder(context, children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// Tells the `AnimatedView`s below whether their subtree is leaving.
class ExitingScope extends InheritedWidget {
  const ExitingScope({
    super.key,
    required this.exiting,
    required this.onBegin,
    required this.onDone,
    required super.child,
  });

  final bool exiting;

  /// An exiting animation started; the subtree waits for its [onDone].
  final VoidCallback onBegin;
  final VoidCallback onDone;

  static ExitingScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExitingScope>();

  @override
  bool updateShouldNotify(ExitingScope oldWidget) => exiting != oldWidget.exiting;
}
