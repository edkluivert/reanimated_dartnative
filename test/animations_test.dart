import 'package:dartnative/dartnative.dart' show Color, Offset;
import 'package:reanimated_dartnative/reanimated_dartnative.dart';
import 'package:test/test.dart';

final clock = AnimationClock.instance;

void step(double seconds) => clock.manualStep(seconds);

void main() {
  setUpAll(() => clock.manual = true);
  setUp(() {
    ReducedMotionConfig.mode = ReduceMotion.system;
    ReducedMotion.debugSetEnabled(false);
  });

  group('withTiming', () {
    test('defaults to 300 ms along inOut(quad)', () {
      final sv = SharedValue(0.0);
      bool? finished;
      sv.set(withTiming(100, callback: (f) => finished = f));
      step(0.15);
      expect(sv.value, closeTo(50, 0.5)); // inOut(quad) is symmetric
      step(0.075);
      expect(sv.value, closeTo(100 * Easing.inOut(Easing.quad)(0.75), 1.5));
      step(0.2);
      expect(sv.value, 100);
      expect(finished, isTrue);
      expect(sv.isAnimating, isFalse);
    });

    test('animates colors and offsets component-wise', () {
      final color = SharedValue(const Color(0xFFFF0000));
      color.set(withTiming('blue', duration: const Duration(milliseconds: 100)));
      step(0.2);
      expect(color.value.value, 0xFF0000FF);

      final offset = SharedValue(Offset.zero);
      offset.set(withTiming(const Offset(10, -20)));
      step(0.5);
      expect(offset.value, const Offset(10, -20));
    });

    test('an int shared value rounds', () {
      final sv = SharedValue(0);
      sv.set(withTiming(10, duration: const Duration(milliseconds: 100)));
      step(0.05);
      expect(sv.value, isA<int>());
      step(0.1);
      expect(sv.value, 10);
    });
  });

  group('withSpring', () {
    test('Reanimated 4 defaults settle without overshoot', () {
      final sv = SharedValue(0.0);
      var max = 0.0;
      sv.addListener(() => max = sv.value > max ? sv.value : max);
      sv.set(withSpring(100));
      clock.runUntilIdle();
      expect(sv.value, 100);
      expect(max, lessThanOrEqualTo(100.0001));
    });

    test('a bouncy spring overshoots; overshootClamping stops at the target', () {
      final bouncy = SharedValue(0.0);
      var max = 0.0;
      bouncy.addListener(() => max = bouncy.value > max ? bouncy.value : max);
      bouncy.set(withSpring(100, damping: 10, stiffness: 100, mass: 1));
      clock.runUntilIdle();
      expect(max, greaterThan(110));

      final clamped = SharedValue(0.0);
      var cmax = 0.0;
      clamped.addListener(() => cmax = clamped.value > cmax ? clamped.value : cmax);
      clamped.set(withSpring(100, damping: 10, stiffness: 100, mass: 1, overshootClamping: true));
      clock.runUntilIdle();
      expect(cmax, lessThanOrEqualTo(100));
      expect(clamped.value, 100);
    });

    test('clamp raises damping to stay within bounds', () {
      final sv = SharedValue(0.0);
      var max = 0.0;
      sv.addListener(() => max = sv.value > max ? sv.value : max);
      sv.set(withSpring(100, dampingRatio: 0.2, clamp: (min: null, max: 105)));
      clock.runUntilIdle();
      expect(max, lessThanOrEqualTo(105.0001));
      expect(sv.value, 100);
    });

    test('a duration-based spring settles by 1.5 × duration', () {
      final sv = SharedValue(0.0);
      sv.set(withSpring(1, duration: const Duration(milliseconds: 400), dampingRatio: 0.5));
      step(0.61);
      expect(sv.value, 1);
      expect(sv.isAnimating, isFalse);
    });

    test('a spring interrupting another keeps its velocity', () {
      final sv = SharedValue(0.0);
      sv.set(withTiming(100, duration: const Duration(milliseconds: 200), easing: Easing.linear));
      step(0.1);
      final before = sv.value;
      sv.set(withSpring(before));
      step(1 / 60);
      // Still moving forward on momentum, though the spring's target is here.
      expect(sv.value, greaterThan(before));
      clock.runUntilIdle();
    });

    test('replacing an animation calls the old callback with false', () {
      final sv = SharedValue(0.0);
      bool? first;
      sv.set(withSpring(1, callback: (f) => first = f));
      step(0.05);
      sv.set(withTiming(0));
      expect(first, isFalse);
      clock.runUntilIdle();
    });
  });

  group('withDecay', () {
    test('slows to a stop, about velocity × 0.5 s with 0.998', () {
      final sv = SharedValue(0.0);
      sv.set(withDecay(velocity: 1000));
      clock.runUntilIdle();
      expect(sv.value, closeTo(1000 * 0.998 / (1 - 0.998) / 1000, 15));
    });

    test('stops at clamp', () {
      final sv = SharedValue(0.0);
      sv.set(withDecay(velocity: 2000, clamp: (-50, 100)));
      clock.runUntilIdle();
      expect(sv.value, 100);
    });

    test('rubber band overshoots and settles on the bound', () {
      final sv = SharedValue(0.0);
      var max = 0.0;
      sv.addListener(() => max = sv.value > max ? sv.value : max);
      sv.set(withDecay(velocity: 2000, clamp: (-50, 100), rubberBandEffect: true));
      clock.runUntilIdle();
      expect(max, greaterThan(100));
      expect(sv.value, 100);
    });

    test('rubberBandEffect requires clamp', () {
      expect(() => withDecay(velocity: 1, rubberBandEffect: true), throwsArgumentError);
    });

    test('2D fling with an Offset velocity', () {
      final sv = SharedValue(Offset.zero);
      sv.set(withDecay(velocity: const Offset(500, -500)));
      clock.runUntilIdle();
      expect(sv.value.dx, greaterThan(200));
      expect(sv.value.dy, lessThan(-200));
    });
  });

  group('modifiers', () {
    test('withSequence runs in order', () {
      final sv = SharedValue(0.0);
      sv.set(withSequence([
        withTiming(10, duration: const Duration(milliseconds: 100)),
        withTiming(-10, duration: const Duration(milliseconds: 100)),
      ]));
      step(0.1);
      expect(sv.value, closeTo(10, 0.01));
      step(0.12);
      expect(sv.value, -10);
    });

    test('withRepeat defaults to 2 repetitions, restarting each time', () {
      final sv = SharedValue(0.0);
      var resets = 0;
      double last = 0;
      sv.addListener(() {
        if (sv.value < last - 50) resets++;
        last = sv.value;
      });
      sv.set(withRepeat(withTiming(100, duration: const Duration(milliseconds: 100))));
      clock.runUntilIdle();
      expect(resets, 1);
      expect(sv.value, 100);
    });

    test('withRepeat reverse goes back and forth', () {
      final sv = SharedValue(0.0);
      sv.set(withRepeat(
        withTiming(100, duration: const Duration(milliseconds: 100)),
        numberOfReps: 3,
        reverse: true,
      ));
      step(0.1);
      expect(sv.value, closeTo(100, 0.01));
      step(0.1);
      expect(sv.value, closeTo(0, 0.01));
      clock.runUntilIdle();
      expect(sv.value, 100);
    });

    test('withRepeat with numberOfReps <= 0 runs until cancelled', () {
      final sv = SharedValue(0.0);
      bool? finished;
      sv.set(withRepeat(withTiming(1, duration: const Duration(milliseconds: 50)),
          numberOfReps: -1, reverse: true, callback: (f) => finished = f));
      step(5);
      expect(sv.isAnimating, isTrue);
      cancelAnimation(sv);
      expect(finished, isFalse);
      expect(sv.isAnimating, isFalse);
    });

    test('withDelay holds, then runs', () {
      final sv = SharedValue(0.0);
      sv.set(withDelay(const Duration(milliseconds: 200),
          withTiming(1, duration: const Duration(milliseconds: 100))));
      step(0.15);
      expect(sv.value, 0);
      step(0.2);
      expect(sv.value, 1);
    });

    test('withClamp limits a bouncy spring', () {
      final sv = SharedValue(0.0);
      var max = 0.0;
      sv.addListener(() => max = sv.value > max ? sv.value : max);
      sv.set(withClamp(max: 100, withSpring(100, damping: 5, stiffness: 100, mass: 1)));
      clock.runUntilIdle();
      expect(max, lessThanOrEqualTo(100));
    });
  });

  group('reduce motion', () {
    test('timing and spring jump to the end', () {
      ReducedMotion.debugSetEnabled(true);
      final sv = SharedValue(0.0);
      sv.set(withSpring(5));
      step(1 / 60);
      expect(sv.value, 5);
      sv.set(withTiming(9, duration: const Duration(seconds: 5)));
      step(1 / 60);
      expect(sv.value, 9);
    });

    test('ReduceMotion.never animates anyway', () {
      ReducedMotion.debugSetEnabled(true);
      final sv = SharedValue(0.0);
      sv.set(withTiming(9, reduceMotion: ReduceMotion.never));
      step(1 / 60);
      expect(sv.value, lessThan(9));
      clock.runUntilIdle();
    });

    test('infinite repeats do not start; delays are skipped', () {
      ReducedMotionConfig.mode = ReduceMotion.always;
      final sv = SharedValue(0.0);
      sv.set(withRepeat(withTiming(1), numberOfReps: 0));
      step(1 / 60);
      expect(sv.value, 0);
      expect(sv.isAnimating, isFalse);
      sv.set(withDelay(const Duration(seconds: 3), withTiming(4)));
      step(1 / 60);
      expect(sv.value, 4);
    });

    test('decay stays where it is', () {
      ReducedMotionConfig.mode = ReduceMotion.always;
      final sv = SharedValue(3.0);
      sv.set(withDecay(velocity: 1000));
      step(1 / 60);
      expect(sv.value, 3);
    });
  });
}
