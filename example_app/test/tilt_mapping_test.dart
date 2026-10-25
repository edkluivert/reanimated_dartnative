// Checks which way tilting the device moves things, without a device.
//
// A pose is built from first principles: the device starts flat, screen up
// (x to its right edge, y to its top edge, z out of the screen), is rolled
// (right edge down), then pitched (top edge up). The gravity reading for
// that pose is the world's up direction in device coordinates × 9.81, the
// convention the plugin uses on both platforms (Android's raw values; iOS
// is converted, checked by ios/Tests/main.swift).

import 'dart:math' as math;

import 'package:reanimated_dartnative/reanimated_dartnative.dart';
import 'package:reanimated_dartnative_example/src/components/tilt_mapping.dart';
import 'package:test/test.dart';

/// The gravity reading for a device rolled [rollDeg] (right edge down) and
/// then pitched [pitchDeg] (top edge up).
Value3D pose({double rollDeg = 0, double pitchDeg = 0}) {
  final r = rollDeg * math.pi / 180, p = pitchDeg * math.pi / 180;
  // Device axes in world coordinates; only their z (up) parts matter.
  final xUp = -math.sin(r);
  final y0Up = 0.0, z0Up = math.cos(r);
  final yUp = math.cos(p) * y0Up + math.sin(p) * z0Up;
  final zUp = -math.sin(p) * y0Up + math.cos(p) * z0Up;
  return Value3D(x: xUp * 9.81, y: yUp * 9.81, z: zUp * 9.81);
}

void main() {
  group('the pose model', () {
    test('matches the documented sensor readings', () {
      expect(pose().z, closeTo(9.81, 1e-9)); // flat, screen up
      expect(pose(rollDeg: 30).x, lessThan(0)); // right edge down
      expect(pose(pitchDeg: 90).y, closeTo(9.81, 1e-9)); // upright
    });
  });

  group('useAnimatedSensor box (slides toward the lower edge)', () {
    test('flat: stays centered', () {
      final o = gravityToBoxOffset(pose());
      expect(o.dx, closeTo(0, 1e-9));
      expect(o.dy, closeTo(0, 1e-9));
    });

    test('right edge down: slides right', () {
      expect(gravityToBoxOffset(pose(rollDeg: 25)).dx, greaterThan(0));
    });

    test('left edge down: slides left', () {
      expect(gravityToBoxOffset(pose(rollDeg: -25)).dx, lessThan(0));
    });

    test('top edge up (bottom lower): slides down the screen', () {
      expect(gravityToBoxOffset(pose(pitchDeg: 40)).dy, greaterThan(0));
    });

    test('top edge down: slides up the screen', () {
      expect(gravityToBoxOffset(pose(pitchDeg: -40)).dy, lessThan(0));
    });

    test('more tilt, further; never past the limit', () {
      final small = gravityToBoxOffset(pose(rollDeg: 10)).dx;
      final big = gravityToBoxOffset(pose(rollDeg: 20)).dx;
      expect(big, greaterThan(small));
      expect(gravityToBoxOffset(pose(pitchDeg: 90)).dy, 100);
    });
  });

  group('airplane steering', () {
    test('roll right: steers right; roll left: steers left', () {
      expect(gravityToSteer(pose(rollDeg: 20, pitchDeg: 45)).dx, greaterThan(0));
      expect(gravityToSteer(pose(rollDeg: -20, pitchDeg: 45)).dx, lessThan(0));
    });

    test('tipping the top away from you climbs toward the top of the screen', () {
      final upright = gravityToSteer(pose(pitchDeg: 90)).dy;
      final reading = gravityToSteer(pose(pitchDeg: 45)).dy;
      final flat = gravityToSteer(pose()).dy;
      expect(reading, lessThan(upright));
      expect(flat, lessThan(reading));
      expect(flat, -1); // flat: full climb
      expect(upright, 1); // upright: low and slow
    });

    test('held at a natural reading angle, the plane sits near the middle', () {
      final steer = gravityToSteer(pose(pitchDeg: 30));
      expect(steer.dx, closeTo(0, 1e-9));
      expect(steer.dy.abs(), lessThan(0.3));
    });
  });
}
