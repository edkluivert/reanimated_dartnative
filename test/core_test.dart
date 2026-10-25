import 'dart:math' as math;

import 'package:dartnative/dartnative.dart' show Color, Offset;
import 'package:reanimated_dartnative/reanimated_dartnative.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() => AnimationClock.instance.manual = true);

  test('SharedValue set/get/modify and listeners', () {
    final sv = useSharedValue(1.0);
    var calls = 0;
    sv.addListener(() => calls++);
    sv.set(2.0);
    expect(sv.get(), 2);
    sv.set((double v) => v * 3);
    expect(sv.value, 6);
    sv.modify((v) => v + 1);
    expect(sv.value, 7);
    expect(calls, 3);
    expect(() => sv.set('nope'), throwsArgumentError);
  });

  test('modify notifies for in-place list changes', () {
    final sv = SharedValue(<int>[1, 2]);
    var calls = 0;
    sv.addListener(() => calls++);
    sv.modify((list) => list..add(3));
    expect(sv.value, [1, 2, 3]);
    expect(calls, 1);
  });

  test('useDerivedValue tracks reads without a dependency list', () {
    final a = SharedValue(1.0), b = SharedValue(10.0), useB = SharedValue(false);
    final derived = useDerivedValue(() => useB.value ? b.value : a.value * 50);
    expect(derived.value, 50);
    a.value = 2;
    expect(derived.value, 100);
    b.value = 3; // not read yet
    expect(derived.value, 100);
    useB.value = true;
    expect(derived.value, 3);
    a.value = 9; // no longer read
    expect(derived.value, 3);
    expect(() => derived.value = 1, throwsUnsupportedError);
    derived.dispose();
  });

  test('useAnimatedStyle recomputes and notifies', () {
    final offset = SharedValue(0.0);
    final style = useAnimatedStyle(() => AnimatedStyle(translateX: offset.value));
    var notified = 0;
    style.addListener(() => notified++);
    offset.value = 40;
    expect(style.style.translateX, 40);
    expect(notified, 1);
    offset.value = 40; // unchanged
    expect(notified, 1);
    style.dispose();
  });

  test('useAnimatedReaction reports previous (null first)', () {
    final width = SharedValue(100.0);
    final log = <(double, double?)>[];
    final reaction = useAnimatedReaction(() => width.value, (c, p) => log.add((c, p)));
    width.value = 250;
    expect(log, [(100.0, null), (250.0, 100.0)]);
    reaction.dispose();
    width.value = 1;
    expect(log.length, 2);
  });

  test('useAnimatedProps', () {
    final r = SharedValue(10.0);
    final props = useAnimatedProps(() => (radius: r.value * 2));
    r.value = 20;
    expect(props.value.radius, 40);
  });

  test('styles merge in order, later wins', () {
    const base = AnimatedStyle(width: 100, height: 100, opacity: 1);
    final s = const Styles([base, AnimatedStyle(opacity: 0.5)]).resolve();
    expect(s.width, 100);
    expect(s.opacity, 0.5);
  });

  test('AnimatedStyle.lerp blends numbers and colors and fills from identity', () {
    final s = AnimatedStyle.lerp(
      const AnimatedStyle(scale: 0, backgroundColor: Color(0xFF000000)),
      const AnimatedStyle(translateX: 100, backgroundColor: Color(0xFFFFFFFF)),
      0.5,
    );
    expect(s.scale, 0.5);
    expect(s.translateX, 50);
    expect(s.backgroundColor!.value & 0xFFFFFF, isNot(0));
  });

  test('FrameCallback reports frame timing', () {
    final infos = <FrameInfo>[];
    final cb = useFrameCallback(infos.add);
    AnimationClock.instance.manualStep(0.05);
    expect(infos.first.timeSincePreviousFrame, isNull);
    expect(infos.last.timeSinceFirstFrame.inMilliseconds, inInclusiveRange(30, 40));
    cb.setActive(false);
    final n = infos.length;
    AnimationClock.instance.manualStep(0.05);
    expect(infos.length, n);
  });

  test('useTimestamp counts milliseconds', () {
    final ts = useTimestamp();
    AnimationClock.instance.manualStep(0.5);
    expect(ts.value, closeTo(483, 20));
    ts.dispose();
  });

  test('slow animations play ten times slower', () {
    ReanimatedDebug.slowAnimations = true;
    final sv = SharedValue(0.0);
    sv.set(withTiming(1, duration: const Duration(milliseconds: 100), easing: Easing.linear));
    AnimationClock.instance.manualStep(0.5);
    expect(sv.value, closeTo(0.5, 0.02));
    ReanimatedDebug.slowAnimations = false;
    AnimationClock.instance.runUntilIdle();
  });

  test('useDerivedAnimation animates to what its updater returns', () {
    final open = SharedValue(false);
    final height = SharedValue(200.0);
    final derived = useDerivedAnimation(0.0, () => withTiming(height.value * (open.value ? 1 : 0)));
    expect(derived.value, 0);
    open.value = true;
    AnimationClock.instance.manualStep(0.15);
    expect(derived.value, closeTo(100, 1));
    AnimationClock.instance.runUntilIdle();
    expect(derived.value, 200);
    height.value = 300; // a dependency changes: animates again
    AnimationClock.instance.runUntilIdle();
    expect(derived.value, 300);
    derived.dispose();
  });

  test('useDerivedAnimation follows colors', () {
    final on = SharedValue(false);
    final color = useDerivedAnimation(const Color(0xFFFA7F7C),
        () => withTiming(on.value ? const Color(0xFF82CAB2) : const Color(0xFFFA7F7C)));
    on.value = true;
    AnimationClock.instance.runUntilIdle();
    expect(color.value.value, 0xFF82CAB2);
  });

  test('a derived animation chasing a moving animated value keeps up', () {
    // Regression: listeners notified mid-frame used to restart the chaser
    // before it stepped, so it froze until its target stopped moving.
    final steer = SharedValue(Offset.zero);
    final pos = useDerivedAnimation(Offset.zero,
        () => withSpring(steer.value, dampingRatio: 0.75, duration: const Duration(milliseconds: 900)));
    final chaser = useDerivedAnimation(Offset.zero,
        () => withSpring(pos.value, dampingRatio: 1, duration: const Duration(milliseconds: 90)));
    steer.value = const Offset(100, 100);
    for (var f = 0; f < 20; f++) {
      AnimationClock.instance.manualStep(1 / 60);
    }
    expect(pos.value.dx, greaterThan(50));
    final gap = chaser.value - pos.value;
    // Not Offset.distance: in DartNative 1.4.0 it returns the squared length.
    expect(math.sqrt(gap.dx * gap.dx + gap.dy * gap.dy), lessThan(15));
    AnimationClock.instance.runUntilIdle();
    expect(chaser.value, const Offset(100, 100));
  });
}
