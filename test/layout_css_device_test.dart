import 'package:reanimated_dartnative/reanimated_dartnative.dart';
import 'package:test/test.dart';

const values = LayoutValues(windowWidth: 400, windowHeight: 800, width: 100, height: 50);

void main() {
  setUpAll(() => AnimationClock.instance.manual = true);

  group('layout animations', () {
    test('entering presets end at the view\'s own style', () {
      final frames = FadeInUp().resolveFrames(values, const AnimatedStyle(opacity: 0.6));
      expect(evaluateFrames(frames, 0).opacity, 0);
      expect(evaluateFrames(frames, 0).translateY, 25);
      expect(evaluateFrames(frames, 1).opacity, 0.6);
      expect(evaluateFrames(frames, 1).translateY, 0);
    });

    test('exiting presets start from the view\'s style', () {
      final frames = SlideOutLeft().resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(frames, 0).translateX, 0);
      expect(evaluateFrames(frames, 1).translateX, -400);
    });

    test('bounce is keyframed over 600 ms', () {
      final bounce = BounceIn();
      expect(bounce.defaultDuration, const Duration(milliseconds: 600));
      final frames = bounce.resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(frames, 0.55).scale, closeTo(1.2, 1e-9));
      expect(evaluateFrames(frames, 1).scale, 1);
    });

    test('withInitialValues / withTargetValues override the ends', () {
      final frames = FadeIn()
          .withInitialValues(const AnimatedStyle(opacity: 0.2))
          .withTargetValues(const AnimatedStyle(opacity: 0.9))
          .resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(frames, 0).opacity, closeTo(0.2, 1e-9));
      expect(evaluateFrames(frames, 1).opacity, closeTo(0.9, 1e-9));
    });

    test('springified progress overshoots past 1 and is extrapolated', () {
      final frames = ZoomIn().resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(frames, 1.1).scale, closeTo(1.1, 1e-9));
    });

    test('Keyframe rules', () {
      expect(() => Keyframe({50: const AnimatedStyle(opacity: 1)}), throwsArgumentError);
      expect(
          () => Keyframe({
                0: const AnimatedStyle(opacity: 0),
                'from': const AnimatedStyle(opacity: 0),
              }),
          throwsArgumentError);
      expect(() => Keyframe({0: const KeyframeStyle(opacity: 0, easing: Easing.quad)}),
          throwsArgumentError);
      expect(
          () => Keyframe({
                0: const AnimatedStyle(opacity: 0),
                100: const AnimatedStyle(opacity: 1, scale: 2),
              }),
          throwsArgumentError); // scale has no initial value

      final kf = Keyframe({
        0: const AnimatedStyle(rotate: 0),
        45: const KeyframeStyle(rotate: 1, easing: Easing.quad),
        100: const AnimatedStyle(rotate: 0),
      });
      expect(kf.defaultDuration, const Duration(milliseconds: 500));
      final frames = kf.resolveFrames(values, AnimatedStyle.empty);
      expect(evaluateFrames(frames, 0.225).rotate, closeTo(0.25, 1e-9)); // quad(0.5)
      expect(evaluateFrames(frames, 0.45).rotate, closeTo(1, 1e-9));
    });

    test('LinearTransition starts at the old place and ends at the new', () {
      final t = LinearTransition();
      expect(t.styleAt(0, 30, -10, 2, 1).translateX, 30);
      expect(t.styleAt(0, 30, -10, 2, 1).scaleX, 2);
      expect(t.styleAt(1, 30, -10, 2, 1).translateX, 0);
    });

    test('SequencedTransition moves x first', () {
      final t = SequencedTransition();
      final mid = t.styleAt(0.5, 30, 40, 1, 1);
      expect(mid.translateX, 0);
      expect(mid.translateY, 40);
    });
  });

  group('CSS animations', () {
    CSSKeyframes spin() => CSSKeyframes({'to': const AnimatedStyle(rotate: 100)});

    test('plays forward and ends without fill', () {
      final events = <String>[];
      final p = CSSAnimationPlayer(CSSAnimation(
        keyframes: spin(),
        duration: const Duration(seconds: 1),
        timingFunction: CSSTimingFunction.linear,
        onStart: (_) => events.add('start'),
        onEnd: (_) => events.add('end'),
      ));
      p.advance(0.5);
      expect(p.style(AnimatedStyle.empty)!.rotate, closeTo(50, 1e-9));
      p.advance(0.6);
      expect(p.style(AnimatedStyle.empty), isNull);
      expect(events, ['start', 'end']);
    });

    test('fill forwards, alternate direction, iterations', () {
      var iterations = 0;
      final p = CSSAnimationPlayer(CSSAnimation(
        keyframes: spin(),
        duration: const Duration(seconds: 1),
        timingFunction: CSSTimingFunction.linear,
        iterationCount: 2,
        direction: AnimationDirection.alternate,
        fillMode: AnimationFillMode.forwards,
        onIteration: (_) => iterations++,
      ));
      p.advance(1.25);
      expect(p.style(AnimatedStyle.empty)!.rotate, closeTo(75, 1e-9));
      p.advance(1);
      expect(iterations, 1);
      expect(p.style(AnimatedStyle.empty)!.rotate, closeTo(0, 1e-9));
    });

    test('delay with backwards fill, negative delay', () {
      final p = CSSAnimationPlayer(CSSAnimation(
        keyframes: CSSKeyframes({'from': const AnimatedStyle(opacity: 0)}),
        duration: const Duration(seconds: 1),
        delay: const Duration(milliseconds: 500),
        timingFunction: CSSTimingFunction.linear,
        fillMode: AnimationFillMode.backwards,
      ));
      p.advance(0.1);
      expect(p.style(const AnimatedStyle(opacity: 1))!.opacity, 0);

      final q = CSSAnimationPlayer(CSSAnimation(
        keyframes: spin(),
        duration: const Duration(seconds: 1),
        delay: const Duration(milliseconds: -500),
        timingFunction: CSSTimingFunction.linear,
      ));
      q.advance(0);
      expect(q.style(AnimatedStyle.empty)!.rotate, closeTo(50, 1e-9));
    });

    test('paused animations hold still', () {
      final p = CSSAnimationPlayer(CSSAnimation(
        keyframes: spin(),
        duration: const Duration(seconds: 1),
        playState: AnimationPlayState.paused,
      ));
      p.advance(0.5);
      expect(p.style(AnimatedStyle.empty)!.rotate, 0);
    });
  });

  group('CSS transitions', () {
    test('changed properties animate to their new value', () {
      final player = CSSTransitionPlayer();
      final t = CSSTransition(
        properties: const ['width'],
        duration: const Duration(seconds: 1),
        timingFunction: CSSTimingFunction.linear,
      );
      player.update(const AnimatedStyle(width: 100, opacity: 1), t);
      player.update(const AnimatedStyle(width: 200, opacity: 0.5), t);
      player.advance(0.5);
      final s = player.current(const AnimatedStyle(width: 200, opacity: 0.5));
      expect(s.width, closeTo(150, 1e-9));
      expect(s.opacity, 0.5); // not listed: jumps
      player.advance(1);
      expect(player.isActive, isFalse);
    });
  });

  group('sensors', () {
    test('parses native payloads', () {
      final v = AnimatedSensor.parseReading(SensorType.gravity, '1.5,-2,9.81,1')!;
      expect(v.x, 1.5);
      expect(v.z, 9.81);
      expect(v.interfaceOrientation, InterfaceOrientation.rotation90);
      final r = AnimatedSensor.parseReading(SensorType.rotation, '1,0,0,0,0.1,0.2,0.3,0')!;
      expect(r.qw, 1);
      expect(r.roll, 0.3);
    });

    test('without the native side the sensor is unavailable', () {
      final s = useAnimatedSensor(SensorType.accelerometer);
      expect(s.isAvailable, isFalse);
      expect(s.sensor.value, const Value3D());
      s.debugEmit(const Value3D(x: 1));
      expect(s.sensor.value.x, 1);
      s.dispose();
    });
  });
}
