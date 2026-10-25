import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';

import '../animations/animation.dart' show ReanimatedAnimation;
import '../core/animated_style.dart';
import '../core/clock.dart';
import '../core/shared_value.dart';
import '../css/css.dart';
import '../device/reduced_motion.dart' as rm;
import '../layout/layout_animation.dart';
import '../layout/layout_transition.dart';
import 'animated_presence.dart';
import 'layout_animation_config.dart';

/// A view whose style animates, as Reanimated's `Animated.View`.
///
/// * [style]: an [AnimatedStyle], the handle from `useAnimatedStyle`, or
///   several merged with [Styles]. Shared-value changes update this view
///   directly, without rebuilding its parent.
/// * [entering] / [exiting]: layout animations played as the view appears
///   and (inside an [AnimatedPresence]) as it leaves.
/// * [layout]: a [LayoutTransition] played when the view moves or resizes.
/// * [cssAnimations] / [cssTransition]: Reanimated 4's CSS animations and
///   transitions.
/// * [sharedTransitionTag]: a shared element transition across a
///   `Navigator.push`, run by DartNative's [Hero].
///
/// ```dart
/// final width = useSharedValue(100.0);
/// late final animatedStyle = useAnimatedStyle(() => AnimatedStyle(width: width.value));
///
/// AnimatedView(
///   style: Styles([const AnimatedStyle(height: 100, backgroundColor: Color(0xFFB58DF1)), animatedStyle]),
/// )
/// ```
class AnimatedView extends StatefulWidget {
  const AnimatedView({
    super.key,
    this.style,
    this.entering,
    this.exiting,
    this.layout,
    this.cssAnimations = const [],
    this.cssTransition,
    this.sharedTransitionTag,
    this.onLayout,
    this.backfaceVisibility = true,
    this.child,
  });

  final StyleSource? style;
  final LayoutAnimation? entering;
  final LayoutAnimation? exiting;
  final LayoutTransition? layout;
  final List<CSSAnimation> cssAnimations;
  final CSSTransition? cssTransition;
  final Object? sharedTransitionTag;

  /// Called with the view's laid-out size after it first lays out and
  /// whenever the size changes, as React Native's `onLayout`.
  final void Function(Size size)? onLayout;

  /// Whether the view shows when a 3D rotation turns its back to the
  /// viewer, as `backfaceVisibility` (false = `'hidden'`).
  final bool backfaceVisibility;
  final Widget? child;

  @override
  State<AnimatedView> createState() => _AnimatedViewState();
}

class _AnimatedViewState extends State<AnimatedView> implements FrameDriven {
  final GlobalKey _layoutKey = GlobalKey();
  Listenable? _listenable;

  // Entering / exiting.
  final SharedValue<double> _layoutProgress = SharedValue(1);
  List<LayoutFrame>? _layoutFrames;
  LayoutAnimation? _runningLayout;
  bool _enteringHandled = false;
  bool _exiting = false;

  // Layout transitions.
  final SharedValue<double> _transitionProgress = SharedValue(1);
  LayoutTransition? _transition;
  double _dx = 0, _dy = 0, _sx = 1, _sy = 1;
  (Offset, Size)? _lastRect;

  // CSS.
  final Map<CSSKeyframes, CSSAnimationPlayer> _cssPlayers = {};
  final CSSTransitionPlayer _cssTransitions = CSSTransitionPlayer();
  bool _ticking = false;

  // Wrappers ever needed; kept once used so the subtree never remounts.
  final Set<String> _wrappers = {};

  @override
  void initState() {
    super.initState();
    _subscribe();
    _layoutProgress.addListener(_markDirty);
    _transitionProgress.addListener(_markDirty);
    _syncCss(initial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_enteringHandled) {
      _enteringHandled = true;
      _startEntering();
    }
    final scope = ExitingScope.of(context);
    if (scope != null && scope.exiting && !_exiting) {
      _startExiting(scope);
    } else if (scope != null && !scope.exiting && _exiting) {
      // Brought back before the exit finished.
      _exiting = false;
      _runningLayout = null;
      _layoutFrames = null;
      _layoutProgress.value = 1;
    }
  }

  @override
  void didUpdateWidget(AnimatedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style?.listenable != widget.style?.listenable) {
      _listenable?.removeListener(_markDirty);
      _subscribe();
    }
    _syncCss();
  }

  void _subscribe() {
    _listenable = widget.style?.listenable;
    _listenable?.addListener(_markDirty);
  }

  void _markDirty() {
    if (mounted) setState(() {});
  }

  LayoutValues _values() {
    final window = MediaQuery.sizeOf(context);
    final size = _layoutKey.currentContext?.size ?? Size.zero;
    return LayoutValues(
      windowWidth: window.width,
      windowHeight: window.height,
      width: size.width,
      height: size.height,
    );
  }

  AnimatedStyle _restingStyle() => widget.style?.resolve() ?? AnimatedStyle.empty;

  // Entering

  void _startEntering() {
    final entering = widget.entering;
    if (entering == null) return;
    if (LayoutAnimationConfig.of(context)?.skipEntering ?? false) return;
    _runningLayout = entering;
    _layoutFrames = entering.resolveFrames(_values(), _restingStyle());
    _layoutProgress.value = 0;
    // Wait one frame so the view has a size for size-based presets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _runningLayout != entering) return;
      _layoutFrames = entering.resolveFrames(_values(), _restingStyle());
      _runLayout(entering);
    });
  }

  void _runLayout(LayoutAnimation animation, {VoidCallback? onDone}) {
    final frames = _layoutFrames!;
    final ReanimatedAnimation progress = animation.progressAnimation(
      multiStep: frames.length > 2,
      onEnd: (finished) {
        if (_runningLayout == animation && !animation.isExiting) {
          _runningLayout = null;
          _layoutFrames = null;
          _markDirty();
        }
        onDone?.call();
      },
    );
    _layoutProgress.value = 0;
    _layoutProgress.set(progress);
  }

  // Exiting

  void _startExiting(ExitingScope scope) {
    _exiting = true;
    final exiting = widget.exiting;
    if (exiting == null) return;
    if (LayoutAnimationConfig.of(context)?.skipExiting ?? false) return;
    // Reduced motion omits exiting animations.
    if (rm.ReducedMotionConfig.shouldReduceMotion) return;
    scope.onBegin();
    _runningLayout = exiting;
    _layoutFrames = exiting.resolveFrames(_values(), _currentStyle());
    var done = false;
    _runLayout(exiting, onDone: () {
      if (done) return;
      done = true;
      scope.onDone();
    });
  }

  // Layout transitions

  void _scheduleMeasure() {
    if (widget.layout == null && _lastRect == null && widget.onLayout == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _layoutKey.currentContext;
      final box = ctx?.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      final rect = (box.localToGlobal(Offset.zero), box.size);
      final last = _lastRect;
      _lastRect = rect;
      if (last == null || last.$2 != rect.$2) widget.onLayout?.call(rect.$2);
      final layout = widget.layout;
      if (last == null || layout == null || _exiting) return;
      if (last.$1 == rect.$1 && last.$2 == rect.$2) return;
      _startTransition(layout, last, rect);
    });
  }

  void _startTransition(LayoutTransition layout, (Offset, Size) from, (Offset, Size) to) {
    // Start from where the view is drawn now, if a transition is running.
    final now = _transition == null
        ? AnimatedStyle.empty
        : _transition!.styleAt(_transitionProgress.value, _dx, _dy, _sx, _sy);
    final oldCenter = from.$1 + Offset(from.$2.width / 2, from.$2.height / 2);
    final newCenter = to.$1 + Offset(to.$2.width / 2, to.$2.height / 2);
    _dx = oldCenter.dx - newCenter.dx + (now.translateX ?? 0);
    _dy = oldCenter.dy - newCenter.dy + (now.translateY ?? 0);
    _sx = to.$2.width == 0 ? 1 : from.$2.width * (now.scaleX ?? 1) / to.$2.width;
    _sy = to.$2.height == 0 ? 1 : from.$2.height * (now.scaleY ?? 1) / to.$2.height;
    if (layout is EntryExitTransition) layout.values = _values();
    _transition = layout;
    _transitionProgress.value = 0;
    _transitionProgress.set(layout.progressAnimation(
      multiStep: false,
      onEnd: (_) {
        if (_transition == layout) {
          _transition = null;
          _markDirty();
        }
      },
    ));
  }

  // CSS

  void _syncCss({bool initial = false}) {
    final keep = <CSSKeyframes>{};
    for (final animation in widget.cssAnimations) {
      keep.add(animation.keyframes);
      final player = _cssPlayers[animation.keyframes];
      if (player == null) {
        _cssPlayers[animation.keyframes] = CSSAnimationPlayer(animation);
      } else {
        player.animation = animation; // same keyframes: update in place
      }
    }
    for (final key in _cssPlayers.keys.toList()) {
      if (!keep.contains(key)) _cssPlayers.remove(key)!.cancel();
    }
    final source = widget.style;
    if (source != null && source.listenable == null) {
      _cssTransitions.update(source.resolve(), widget.cssTransition);
    }
    if (_cssPlayers.values.any((p) => !p.isEnded) || _cssTransitions.isActive) {
      _startTicking();
    }
  }

  void _startTicking() {
    if (_ticking) return;
    _ticking = true;
    AnimationClock.instance.add(this);
  }

  @override
  bool onFrame(double dt, Duration timestamp) {
    if (!mounted) return _ticking = false;
    for (final p in _cssPlayers.values) {
      p.advance(dt);
    }
    _cssTransitions.advance(dt);
    _markDirty();
    final paused = _cssPlayers.values.every((p) =>
        p.isEnded || p.animation.playState == AnimationPlayState.paused);
    final keepGoing = !paused || _cssTransitions.isActive;
    if (!keepGoing) _ticking = false;
    return keepGoing;
  }

  // Style

  AnimatedStyle _currentStyle() {
    final resting = _restingStyle();
    final source = widget.style;
    var style = source != null && source.listenable == null
        ? _cssTransitions.current(resting)
        : resting;
    for (final player in _cssPlayers.values) {
      final s = player.style(style);
      if (s != null) style = style.merge(s);
    }
    final frames = _layoutFrames;
    if (frames != null && _runningLayout != null) {
      style = style.merge(evaluateFrames(frames, _layoutProgress.value));
    }
    final transition = _transition;
    if (transition != null) {
      final o = transition.styleAt(_transitionProgress.value, _dx, _dy, _sx, _sy);
      style = style.merge(AnimatedStyle(
        translateX: o.translateX == null ? null : (style.translateX ?? 0) + o.translateX!,
        translateY: o.translateY == null ? null : (style.translateY ?? 0) + o.translateY!,
        scaleX: o.scaleX == null ? null : (style.scaleX ?? 1) * o.scaleX!,
        scaleY: o.scaleY == null ? null : (style.scaleY ?? 1) * o.scaleY!,
        opacity: o.opacity == null ? null : (style.opacity ?? 1) * o.opacity!,
      ));
    }
    return style;
  }

  @override
  void dispose() {
    _listenable?.removeListener(_markDirty);
    _layoutProgress.dispose();
    _transitionProgress.dispose();
    for (final p in _cssPlayers.values) {
      p.cancel();
    }
    _cssTransitions.cancelAll();
    if (_ticking) AnimationClock.instance.remove(this);
    super.dispose();
  }

  /// Whether a 3D rotation shows the view's back.
  static bool _facesAway(AnimatedStyle s) {
    bool away(double? a) {
      if (a == null) return false;
      final turn = (a % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
      return turn > math.pi / 2 && turn < 3 * math.pi / 2;
    }

    return away(s.rotateX) != away(s.rotateY);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    final s = _currentStyle();
    void use(String name, bool when) {
      if (when) _wrappers.add(name);
    }

    use('box', s.width != null || s.height != null || s.backgroundColor != null || s.borderRadius != null);
    use('scale', s.scale != null || s.scaleX != null || s.scaleY != null);
    use('perspective', s.rotateX != null || s.rotateY != null);
    use('rotate', s.rotate != null);
    use('translate', s.translateX != null || s.translateY != null);
    use('opacity', s.opacity != null);

    Widget w = widget.child ?? const SizedBox.shrink();
    if (_wrappers.contains('box')) {
      final radius = s.borderRadius;
      w = Container(
        width: s.width,
        height: s.height,
        decoration: BoxDecoration(
          color: s.backgroundColor,
          borderRadius: radius == null ? null : BorderRadius.circular(radius),
        ),
        child: w,
      );
    }
    if (_wrappers.contains('scale')) {
      final k = s.scale ?? 1;
      w = Transform.scale(
          scaleX: k * (s.scaleX ?? 1), scaleY: k * (s.scaleY ?? 1), alignment: Alignment.center, child: w);
    }
    if (_wrappers.contains('perspective')) {
      w = Transform.perspective(
        rotateX: s.rotateX ?? 0,
        rotateY: s.rotateY ?? 0,
        depth: s.perspective ?? 900,
        alignment: Alignment.center,
        child: w,
      );
    }
    if (_wrappers.contains('rotate')) {
      w = Transform.rotate(angle: s.rotate ?? 0, alignment: Alignment.center, child: w);
    }
    if (_wrappers.contains('translate')) {
      w = Transform.translate(offset: Offset(s.translateX ?? 0, s.translateY ?? 0), child: w);
    }
    var opacity = s.opacity;
    if (!widget.backfaceVisibility && _facesAway(s)) opacity = 0;
    use('opacity', opacity != null);
    if (_wrappers.contains('opacity')) {
      w = Opacity(opacity: (opacity ?? 1).clamp(0.0, 1.0), child: w);
    }
    // An untransformed box around everything: its frame is the view's
    // layout slot, measured for layout transitions and size-based presets.
    w = Container(key: _layoutKey, child: w);
    final tag = widget.sharedTransitionTag;
    if (tag != null) w = Hero(tag: tag, child: w);
    return w;
  }
}

/// Builds a widget from [AnimatedProps] (or any shared value) and rebuilds
/// only it when they change.
class AnimatedPropsBuilder<P> extends StatelessWidget {
  const AnimatedPropsBuilder({super.key, required this.props, required this.builder});

  final ValueListenable<P> props;
  final Widget Function(BuildContext context, P props) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<P>(
        valueListenable: props,
        builder: (context, value, _) => builder(context, value),
      );
}
