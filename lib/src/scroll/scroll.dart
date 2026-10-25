import 'package:dartnative/dartnative.dart' show Curve, ScrollController;

import '../core/clock.dart';
import '../core/shared_value.dart';
import '../easing/easing.dart';

/// A shared value that follows a scroll view's offset, as Reanimated's
/// `useScrollOffset`. Give the same [ScrollController] to the scroll view.
///
/// ```dart
/// final controller = ScrollController();
/// late final offset = useScrollOffset(controller);
///
/// ListView(controller: controller, children: ...)
/// ```
class ScrollOffset extends SharedValue<double> {
  ScrollOffset(this.controller) : super(_read(controller)) {
    controller.addListener(_sync);
  }

  final ScrollController controller;

  static double _read(ScrollController c) => c.hasClients ? c.offset : 0;

  void _sync() => value = _read(controller);

  @override
  void dispose() {
    controller.removeListener(_sync);
    super.dispose();
  }
}

/// Creates a [ScrollOffset], as Reanimated's `useScrollOffset`.
ScrollOffset useScrollOffset(ScrollController controller) => ScrollOffset(controller);

/// Scrolls [controller]'s scroll view to [y] (or to [x] for a horizontal
/// one: whichever is non-zero), as Reanimated's `scrollTo`.
void scrollTo(
  ScrollController controller,
  double x,
  double y,
  bool animated, {
  Duration duration = const Duration(milliseconds: 300),
  EasingFunction? easing,
}) {
  final target = y != 0 ? y : x;
  if (!animated) {
    controller.jumpTo(target);
    return;
  }
  controller.animateTo(target,
      duration: duration, curve: _EasingCurve(easing ?? Easing.inOut(Easing.quad)));
}

class _EasingCurve extends Curve {
  const _EasingCurve(this.easing);
  final EasingFunction easing;
  @override
  double transformInternal(double t) => easing(t);
}

/// Scroll position and sizes passed to [AnimatedScrollHandler] callbacks.
class ScrollEvent {
  const ScrollEvent({
    required this.contentOffset,
    required this.contentSize,
    required this.layoutMeasurement,
  });

  /// How far the content has scrolled.
  final double contentOffset;

  /// Total length of the content.
  final double contentSize;

  /// Length of the visible viewport.
  final double layoutMeasurement;
}

/// Scroll lifecycle callbacks for a scroll view, as Reanimated's
/// `useAnimatedScrollHandler`. Every callback receives the event and a
/// [context] map shared by all of them.
///
/// Drags are read from the controller's position; momentum is the motion
/// that continues after a drag ends, and it ends when the offset holds
/// still for a few frames.
class AnimatedScrollHandler {
  AnimatedScrollHandler(
    this.controller, {
    this.onScroll,
    this.onBeginDrag,
    this.onEndDrag,
    this.onMomentumBegin,
    this.onMomentumEnd,
  }) {
    controller.addListener(_onScroll);
    _watcher = _StillnessWatcher(this);
  }

  final ScrollController controller;
  final void Function(ScrollEvent event, Map<String, Object?> context)? onScroll;
  final void Function(ScrollEvent event, Map<String, Object?> context)? onBeginDrag;
  final void Function(ScrollEvent event, Map<String, Object?> context)? onEndDrag;
  final void Function(ScrollEvent event, Map<String, Object?> context)? onMomentumBegin;
  final void Function(ScrollEvent event, Map<String, Object?> context)? onMomentumEnd;

  /// Shared between the callbacks, as Reanimated's handler context.
  final Map<String, Object?> context = {};

  late final _StillnessWatcher _watcher;
  bool _dragging = false;
  bool _momentum = false;

  ScrollEvent get _event => ScrollEvent(
        contentOffset: controller.hasClients ? controller.offset : 0,
        contentSize: controller.hasClients ? controller.contentHeight : 0,
        layoutMeasurement: controller.hasClients ? controller.viewportHeight : 0,
      );

  void _onScroll() {
    _checkDrag();
    onScroll?.call(_event, context);
    _watcher.moved();
  }

  void _checkDrag() {
    final dragging = controller.position.isDragging;
    if (dragging && !_dragging) {
      if (_momentum) {
        _momentum = false;
        onMomentumEnd?.call(_event, context);
      }
      _dragging = true;
      onBeginDrag?.call(_event, context);
    } else if (!dragging && _dragging) {
      _dragging = false;
      onEndDrag?.call(_event, context);
      _momentum = true;
      onMomentumBegin?.call(_event, context);
    }
  }

  void _onStill() {
    _checkDrag();
    if (_momentum && !_dragging) {
      _momentum = false;
      onMomentumEnd?.call(_event, context);
    }
  }

  void dispose() {
    controller.removeListener(_onScroll);
    _watcher.stop();
  }
}

class _StillnessWatcher implements FrameDriven {
  _StillnessWatcher(this.handler);
  final AnimatedScrollHandler handler;
  int _stillFrames = 0;
  bool _running = false;

  void moved() {
    _stillFrames = 0;
    if (!_running) {
      _running = true;
      AnimationClock.instance.addCallback(this);
    }
  }

  void stop() {
    _running = false;
    AnimationClock.instance.remove(this);
  }

  @override
  bool onFrame(double dt, Duration timestamp) {
    if (!_running) return false;
    handler._checkDrag();
    if (++_stillFrames < 4) return true;
    _running = false;
    handler._onStill();
    return false;
  }
}

/// Creates an [AnimatedScrollHandler] for [controller], as Reanimated's
/// `useAnimatedScrollHandler`.
///
/// ```dart
/// final controller = ScrollController();
/// late final handler = useAnimatedScrollHandler(controller,
///     onScroll: (event, _) => translationY.value = event.contentOffset);
/// ```
AnimatedScrollHandler useAnimatedScrollHandler(
  ScrollController controller, {
  void Function(ScrollEvent event, Map<String, Object?> context)? onScroll,
  void Function(ScrollEvent event, Map<String, Object?> context)? onBeginDrag,
  void Function(ScrollEvent event, Map<String, Object?> context)? onEndDrag,
  void Function(ScrollEvent event, Map<String, Object?> context)? onMomentumBegin,
  void Function(ScrollEvent event, Map<String, Object?> context)? onMomentumEnd,
}) =>
    AnimatedScrollHandler(
      controller,
      onScroll: onScroll,
      onBeginDrag: onBeginDrag,
      onEndDrag: onEndDrag,
      onMomentumBegin: onMomentumBegin,
      onMomentumEnd: onMomentumEnd,
    );
