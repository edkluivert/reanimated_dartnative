import 'package:dartnative/dartnative.dart';

import '../animations/animation.dart' show ReduceMotion;
import '../device/reduced_motion.dart' as rm;

/// Skips entering and/or exiting animations below it, as Reanimated's
/// `<LayoutAnimationConfig skipEntering skipExiting>`.
///
/// [skipEntering] only applies to views that mount together with this
/// widget (its first build), so a list can appear without every row
/// animating in while rows added later still animate. [skipExiting] applies
/// for as long as it is set. Configs can be nested; the nearest one wins.
class LayoutAnimationConfig extends StatefulWidget {
  const LayoutAnimationConfig({
    super.key,
    this.skipEntering = false,
    this.skipExiting = false,
    required this.child,
  });

  final bool skipEntering;
  final bool skipExiting;
  final Widget child;

  /// The nearest config's state for [context], or null.
  static LayoutAnimationConfigScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LayoutAnimationConfigScope>();

  @override
  State<LayoutAnimationConfig> createState() => _LayoutAnimationConfigState();
}

class _LayoutAnimationConfigState extends State<LayoutAnimationConfig> {
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _firstBuild = false);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutAnimationConfigScope(
        skipEntering: widget.skipEntering && _firstBuild,
        skipExiting: widget.skipExiting,
        child: widget.child,
      );
}

/// What [LayoutAnimationConfig] tells the animated views below it.
class LayoutAnimationConfigScope extends InheritedWidget {
  const LayoutAnimationConfigScope({
    super.key,
    required this.skipEntering,
    required this.skipExiting,
    required super.child,
  });

  final bool skipEntering;
  final bool skipExiting;

  @override
  bool updateShouldNotify(LayoutAnimationConfigScope oldWidget) =>
      skipEntering != oldWidget.skipEntering || skipExiting != oldWidget.skipExiting;
}

/// Sets how every animation treats the reduce-motion setting while it is
/// mounted, as Reanimated's `<ReducedMotionConfig mode={...} />`.
///
/// ```dart
/// ReducedMotionConfigScope(mode: ReduceMotion.never, child: app)
/// ```
class ReducedMotionConfigScope extends StatefulWidget {
  const ReducedMotionConfigScope({super.key, required this.mode, required this.child});

  final ReduceMotion mode;
  final Widget child;

  @override
  State<ReducedMotionConfigScope> createState() => _ReducedMotionConfigScopeState();
}

class _ReducedMotionConfigScopeState extends State<ReducedMotionConfigScope> {
  late ReduceMotion _previous;

  @override
  void initState() {
    super.initState();
    _previous = rm.ReducedMotionConfig.mode;
    rm.ReducedMotionConfig.mode = widget.mode;
  }

  @override
  void didUpdateWidget(ReducedMotionConfigScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    rm.ReducedMotionConfig.mode = widget.mode;
  }

  @override
  void dispose() {
    rm.ReducedMotionConfig.mode = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
