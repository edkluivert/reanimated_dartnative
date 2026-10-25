import 'package:dartnative/dartnative.dart' show Color;
import 'package:reanimated_dartnative/reanimated_dartnative.dart';
import 'package:test/test.dart';

void main() {
  group('interpolate', () {
    test('maps and extends by default', () {
      expect(interpolate(50, [0, 100], [0, 1]), 0.5);
      expect(interpolate(200, [0, 100], [0, 1]), 2);
      expect(interpolate(-50, [0, 100], [0, 1]), -0.5);
    });

    test('clamp and identity, per side', () {
      expect(interpolate(200, [0, 100], [0, 1], Extrapolation.clamp), 1);
      expect(interpolate(200, [0, 100], [0, 1], Extrapolation.identity), 200);
      const config = ExtrapolationConfig(
          extrapolateLeft: Extrapolation.clamp, extrapolateRight: Extrapolation.extend);
      expect(interpolate(-10, [0, 10], [0, 1], config), 0);
      expect(interpolate(20, [0, 10], [0, 1], config), 2);
    });

    test('multiple segments', () {
      expect(interpolate(75, [0, 50, 100], [0, 1, 0]), 0.5);
    });

    test('clamp()', () {
      expect(clamp(5, 0, 3), 3);
      expect(() => clamp(1, 3, 0), throwsArgumentError);
    });
  });

  group('colors', () {
    test('parses CSS colors', () {
      expect(parseColor('#f00')!.value, 0xFFFF0000);
      expect(parseColor('#00ff0080')!.value, 0x8000FF00); // #RRGGBBAA
      expect(parseColor('rgba(0, 0, 255, 0.5)')!.value, 0x800000FF);
      expect(parseColor('hsl(120, 100%, 50%)')!.value, 0xFF00FF00);
      expect(parseColor('teal')!.value, 0xFF008080);
      expect(parseColor('nope'), isNull);
    });

    test('interpolateColor RGB uses gamma; endpoints are exact', () {
      expect(interpolateColor(0, [0, 1], ['red', 'blue']).value, 0xFFFF0000);
      expect(interpolateColor(1, [0, 1], ['red', 'blue']).value, 0xFF0000FF);
      final mid = interpolateColor(0.5, [0, 1], ['red', 'blue']);
      // Gamma 2.2 keeps the midpoint bright (~186 per channel, not 128).
      expect((mid.value >> 16) & 0xFF, greaterThan(170));
      final raw = interpolateColor(0.5, [0, 1], ['red', 'blue'], ColorSpace.rgb,
          const InterpolateColorOptions(gamma: 1));
      expect((raw.value >> 16) & 0xFF, closeTo(128, 1));
    });

    test('HSV and Oklab', () {
      final hsv = interpolateColor(0.5, [0, 1], ['red', 'blue'], ColorSpace.hsv);
      expect(hsv.value, 0xFFFF00FF); // magenta, the short way round
      final lab = interpolateColor(0.5, [0, 1], ['black', 'white'], ColorSpace.lab);
      final g = (lab.value >> 8) & 0xFF;
      expect(g, inInclusiveRange(90, 110)); // perceptual mid grey
    });

    test('contrastColor', () {
      expect(contrastColor('#000').value, 0xFFFFFFFF);
      expect(contrastColor(const Color(0xFFFFFF00)).value, 0xFF000000);
    });
  });

  group('Easing', () {
    test('base curves', () {
      expect(Easing.quad(0.5), 0.25);
      expect(Easing.cubic(0.5), 0.125);
      expect(Easing.inOut(Easing.quad)(0.5), 0.5);
      expect(Easing.out(Easing.quad)(0.5), 0.75);
      expect(Easing.bezier(0.25, 0.1, 0.25, 1)(0.5), closeTo(0.8024, 0.001));
      expect(Easing.ease(0), 0);
      expect(Easing.ease(1), 1);
    });

    test('steps', () {
      expect(Easing.steps(4)(0.3), 0.5); // rounds up by default
      expect(Easing.steps(4, false)(0.3), 0.25);
    });
  });

  group('CSS timing functions', () {
    test('steps follow the CSS spec', () {
      expect(CSSTimingFunction.steps(4)(0.3), 0.25); // jump-end
      expect(CSSTimingFunction.steps(4, StepPosition.jumpStart)(0.3), 0.5);
      expect(CSSTimingFunction.steps(5, StepPosition.jumpNone)(0), 0);
      expect(CSSTimingFunction.steps(5, StepPosition.jumpNone)(1), 1);
      expect(CSSTimingFunction.steps(3, StepPosition.jumpBoth)(0), 0.25);
    });

    test('linear() points', () {
      final f = CSSTimingFunction.linearPoints([0, 0.25, 1]);
      expect(f(0.25), closeTo(0.125, 1e-9));
      expect(f(0.75), closeTo(0.625, 1e-9));
      final g = CSSTimingFunction.linearPoints([0, (0.9, 0.2), 1]);
      expect(g(0.2), closeTo(0.9, 1e-9));
    });
  });
}
