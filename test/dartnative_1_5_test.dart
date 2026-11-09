// Skew, LightSpeed's skew keyframes and notification-driven scroll events,
// which build on DartNative 1.5.0.

import 'dart:math' as math;

import 'package:dartnative/dartnative.dart'
    show
        AxisDirection,
        BuildContext,
        DragEndDetails,
        DragStartDetails,
        DragUpdateDetails,
        FixedScrollMetrics,
        ScrollController,
        ScrollEndNotification,
        ScrollNotification,
        ScrollStartNotification,
        ScrollUpdateNotification;
import 'package:reanimated_dartnative/reanimated_dartnative.dart';
import 'package:test/test.dart';

const values = LayoutValues(windowWidth: 400, windowHeight: 800, width: 100, height: 50);
const deg = math.pi / 180;

class _Context implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _context = _Context();
final _metrics = FixedScrollMetrics(
  minScrollExtent: 0,
  maxScrollExtent: 1000,
  pixels: 0,
  viewportDimension: 600,
  axisDirection: AxisDirection.down,
  devicePixelRatio: 3,
);

ScrollNotification _start({bool drag = true}) => ScrollStartNotification(
    metrics: _metrics, context: _context, dragDetails: drag ? const DragStartDetails() : null);
ScrollNotification _update({bool drag = true}) => ScrollUpdateNotification(
    metrics: _metrics,
    context: _context,
    dragDetails: drag ? const DragUpdateDetails() : null,
    scrollDelta: 4);
ScrollNotification _end({bool drag = false}) => ScrollEndNotification(
    metrics: _metrics, context: _context, dragDetails: drag ? const DragEndDetails() : null);

void main() {
  setUpAll(() => AnimationClock.instance.manual = true);

  group('skew', () {
    test('is a style property with a resting value of 0', () {
      const style = AnimatedStyle(skewX: 0.2, skewY: -0.1);
      expect(style['skewX'], 0.2);
      expect(style.toMap(), {'skewX': 0.2, 'skewY': -0.1});
      expect(AnimatedStyle.fromMap({'skewX': 0.2}).skewX, 0.2);
      expect(AnimatedStyle.identityOf('skewY'), 0.0);
      expect(const AnimatedStyle(skewX: 0.1).merge(const AnimatedStyle(skewY: 0.3)),
          const AnimatedStyle(skewX: 0.1, skewY: 0.3));
    });

    test('blends from rest', () {
      final mid = AnimatedStyle.lerp(AnimatedStyle.empty, const AnimatedStyle(skewX: 0.4), 0.5);
      expect(mid.skewX, closeTo(0.2, 1e-9));
    });

    test('keyframes carry it', () {
      const k = KeyframeStyle(skewX: 0.3, skewY: 0.1);
      expect(k.skewX, 0.3);
      expect(k.skewY, 0.1);
    });
  });

  group('LightSpeed', () {
    test('LightSpeedInRight leans, overshoots and settles', () {
      final frames = LightSpeedInRight().resolveFrames(values, AnimatedStyle.empty);
      final start = evaluateFrames(frames, 0);
      expect(start.translateX, 400);
      expect(start.opacity, 0);
      expect(start.skewX, closeTo(-45 * deg, 1e-9));
      expect(evaluateFrames(frames, 0.7).skewX, closeTo(10 * deg, 1e-9));
      expect(evaluateFrames(frames, 0.85).skewX, closeTo(-5 * deg, 1e-9));
      final end = evaluateFrames(frames, 1);
      expect(end.translateX, 0);
      expect(end.opacity, 1);
      expect(end.skewX, 0);
    });

    test('LightSpeedInLeft leans the other way and ends at the view\'s style', () {
      final frames = LightSpeedInLeft().resolveFrames(values, const AnimatedStyle(opacity: 0.5));
      expect(evaluateFrames(frames, 0).translateX, -400);
      expect(evaluateFrames(frames, 0).skewX, closeTo(45 * deg, 1e-9));
      expect(evaluateFrames(frames, 0.7).skewX, closeTo(-10 * deg, 1e-9));
      expect(evaluateFrames(frames, 1).opacity, 0.5);
    });

    test('exits lean as they leave', () {
      final right = LightSpeedOutRight().resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(right, 0).skewX, 0);
      expect(evaluateFrames(right, 1).skewX, closeTo(-45 * deg, 1e-9));
      expect(evaluateFrames(right, 1).translateX, 400);
      final left = LightSpeedOutLeft().resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(left, 1).skewX, closeTo(45 * deg, 1e-9));
    });
  });

  group('AnimatedScrollHandler.onNotification', () {
    late ScrollController controller;
    late List<String> calls;
    late AnimatedScrollHandler handler;

    setUp(() {
      controller = ScrollController();
      calls = [];
      handler = AnimatedScrollHandler(
        controller,
        onBeginDrag: (_, __) => calls.add('beginDrag'),
        onEndDrag: (_, __) => calls.add('endDrag'),
        onMomentumBegin: (_, __) => calls.add('momentumBegin'),
        onMomentumEnd: (_, __) => calls.add('momentumEnd'),
      );
    });

    tearDown(() => handler.dispose());

    test('a drag that stops under the finger has no momentum', () {
      for (final n in [_start(), _update(), _update(), _end(drag: true)]) {
        expect(handler.onNotification(n), isFalse);
      }
      expect(calls, ['beginDrag', 'endDrag']);
    });

    test('a fling ends the drag when it coasts and the momentum at rest', () {
      for (final n in [_start(), _update(), _update(drag: false), _update(drag: false), _end()]) {
        handler.onNotification(n);
      }
      expect(calls, ['beginDrag', 'endDrag', 'momentumBegin', 'momentumEnd']);
    });

    test('a finger catching the coasting view ends the momentum first', () {
      for (final n in [_start(), _update(), _update(drag: false), _update(), _end(drag: true)]) {
        handler.onNotification(n);
      }
      expect(calls, ['beginDrag', 'endDrag', 'momentumBegin', 'momentumEnd', 'beginDrag', 'endDrag']);
    });

    test('a scroll from the controller reports no drag', () {
      for (final n in [_start(drag: false), _update(drag: false), _end()]) {
        handler.onNotification(n);
      }
      expect(calls, isEmpty);
    });
  });
}
