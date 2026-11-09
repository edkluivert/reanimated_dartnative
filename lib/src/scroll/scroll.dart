import 'package:dartnative/dartnative.dart'
    show
        Curve,
        ScrollController,
        ScrollEndNotification,
        ScrollNotification,
        ScrollStartNotification,
        ScrollUpdateNotification;

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
/// For exact drag and momentum events, also give the handler the scroll
/// view's notifications (DartNative 1.5.0 and later):
///
/// ```dart
/// NotificationListener<ScrollNotification>(
///   onNotification: handler.onNotification,
///   child: ListView(controller: controller, children: ...),
/// )
/// ```
///
/// A drag then begins and ends with the finger, and momentum runs only
/// when a fling coasts on, from the finger lifting until the view rests,
/// as in React Native.
///
/// Without the listener, drags are read from the controller's position;
/// momentum is the motion after every drag, and it ends when the offset
/// holds still for a few frames.
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

  /// Set once [onNotification] is fed: drags and momentum then come from
  /// the notifications, not from watching the controller.
  bool _notified = false;

  ScrollEvent get _event => ScrollEvent(
        contentOffset: controller.hasClients ? controller.offset : 0,
        contentSize: controller.hasClients ? controller.contentHeight : 0,
        layoutMeasurement: controller.hasClients ? controller.viewportHeight : 0,
      );

  void _onScroll() {
    if (!_notified) _checkDrag();
    onScroll?.call(_event, context);
    if (!_notified) _watcher.moved();
  }

  /// Takes the scroll view's notifications, for a `NotificationListener`'s
  /// `onNotification`. Only the nearest scroll view's count: a nested
  /// one's bubble past. Returns false, so they keep bubbling.
  bool onNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (!_notified) {
      _notified = true;
      _watcher.stop();
    }
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) _beginDrag();
    } else if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        if (!_dragging) _beginDrag();
      } else if (_dragging) {
        // The offset moved with no finger on it: a fling coasting on.
        _dragging = false;
        onEndDrag?.call(_event, context);
        _momentum = true;
        onMomentumBegin?.call(_event, context);
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragging) {
        _dragging = false;
        onEndDrag?.call(_event, context);
      }
      if (_momentum) {
        _momentum = false;
        onMomentumEnd?.call(_event, context);
      }
    }
    return false;
  }

  void _beginDrag() {
    if (_momentum) {
      // A finger caught the coasting view.
      _momentum = false;
      onMomentumEnd?.call(_event, context);
    }
    _dragging = true;
    onBeginDrag?.call(_event, context);
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
