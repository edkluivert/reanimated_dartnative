import 'dart:math' as math;

import 'package:dartnative/dartnative.dart' show Color;

/// Color space [interpolateColor] blends in.
enum ColorSpace {
  /// Red, green and blue channels, blended in linear light (see
  /// [InterpolateColorOptions.gamma]).
  rgb,

  /// Hue, saturation and value; the hue takes the short way round the wheel.
  hsv,

  /// Oklab, a perceptually uniform space: equal steps look equally far apart.
  lab,
}

/// Options for [interpolateColor].
class InterpolateColorOptions {
  const InterpolateColorOptions({
    this.gamma = 2.2,
    this.useCorrectedHSVInterpolation = true,
  });

  /// Gamma used to linearise channels for [ColorSpace.rgb]. `1.0` blends the
  /// raw sRGB values.
  final double gamma;

  /// With [ColorSpace.hsv], take the shorter way round the hue wheel.
  final bool useCorrectedHSVInterpolation;
}

/// Maps [value] from [inputRange] to a color between [outputRange]'s colors.
///
/// Colors may be [Color]s, ARGB ints (`0xFFFF0000`) or CSS strings: `#rgb`,
/// `#rrggbb`, `#rrggbbaa`, `rgb()`, `rgba()`, `hsl()`, `hsla()` and the
/// common named colors. Values outside [inputRange] are clamped to its ends.
///
/// ```dart
/// final color = interpolateColor(
///   progress.value,
///   [0, 1],
///   ['red', 'green'],
/// );
/// ```
Color interpolateColor(
  double value,
  List<double> inputRange,
  List<Object> outputRange, [
  ColorSpace colorSpace = ColorSpace.rgb,
  InterpolateColorOptions options = const InterpolateColorOptions(),
]) {
  if (inputRange.length != outputRange.length) {
    throw ArgumentError(
        'inputRange (${inputRange.length}) and outputRange '
        '(${outputRange.length}) must have the same length.');
  }
  if (inputRange.length < 2) {
    throw ArgumentError('interpolateColor needs at least two colors.');
  }
  final colors = [
    for (final c in outputRange)
      parseColor(c) ?? (throw ArgumentError('Unrecognised color: $c')),
  ];

  final v = value.clamp(inputRange.first, inputRange.last).toDouble();
  var i = 0;
  while (i < inputRange.length - 2 && v > inputRange[i + 1]) {
    i++;
  }
  final x0 = inputRange[i], x1 = inputRange[i + 1];
  final t = x1 == x0 ? 0.0 : (v - x0) / (x1 - x0);
  final c0 = colors[i], c1 = colors[i + 1];

  switch (colorSpace) {
    case ColorSpace.rgb:
      return _mixRgb(c0, c1, t, options.gamma);
    case ColorSpace.hsv:
      return _mixHsv(c0, c1, t, options.useCorrectedHSVInterpolation);
    case ColorSpace.lab:
      return _mixOklab(c0, c1, t);
  }
}

/// Returns white or black, whichever contrasts more with [backgroundColor]
/// (WCAG 2.1 contrast ratio; alpha is ignored; a tie returns white), as
/// Reanimated's `contrastColor`. Every background gets at least about 4.58:1,
/// which meets WCAG AA for normal text.
Color contrastColor(Object backgroundColor) {
  final bg = parseColor(backgroundColor) ??
      (throw ArgumentError('Unrecognised color: $backgroundColor'));
  final l = relativeLuminance(bg);
  final withWhite = 1.05 / (l + 0.05);
  final withBlack = (l + 0.05) / 0.05;
  return withWhite >= withBlack
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
}

/// WCAG 2.1 relative luminance of [color], from 0 (black) to 1 (white).
double relativeLuminance(Color color) {
  double lin(int c) {
    final s = c / 255.0;
    return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  final v = color.value;
  return 0.2126 * lin((v >> 16) & 0xFF) +
      0.7152 * lin((v >> 8) & 0xFF) +
      0.0722 * lin(v & 0xFF);
}

/// Parses a [Color], an ARGB int or a CSS color string. Returns null when
/// [input] is not a color.
Color? parseColor(Object? input) {
  if (input is Color) return input;
  if (input is int) return Color(input);
  if (input is! String) return null;
  final s = input.trim().toLowerCase();
  final named = _namedColors[s];
  if (named != null) return Color(named);

  if (s.startsWith('#')) {
    var hex = s.substring(1);
    if (hex.length == 3 || hex.length == 4) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    final n = int.tryParse(hex, radix: 16);
    if (n == null) return null;
    if (hex.length == 6) return Color(0xFF000000 | n);
    if (hex.length == 8) {
      // CSS order: #RRGGBBAA.
      return Color(((n & 0xFF) << 24) | (n >> 8));
    }
    return null;
  }

  final match = RegExp(r'^(rgba?|hsla?)\((.*)\)$').firstMatch(s);
  if (match == null) return null;
  final parts = match
      .group(2)!
      .split(RegExp(r'[\s,/]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length < 3) return null;
  double num(String p, double scale) => p.endsWith('%')
      ? double.parse(p.substring(0, p.length - 1)) / 100 * scale
      : double.parse(p.replaceAll('deg', ''));
  final alpha = parts.length > 3 ? num(parts[3], 1).clamp(0.0, 1.0) : 1.0;
  final a = (alpha * 255).round();
  if (match.group(1)!.startsWith('rgb')) {
    int ch(String p) => num(p, 255).round().clamp(0, 255);
    return Color.fromARGB(a, ch(parts[0]), ch(parts[1]), ch(parts[2]));
  }
  final h = num(parts[0], 360);
  final sat = num(parts[1], 1).clamp(0.0, 1.0);
  final light = num(parts[2], 1).clamp(0.0, 1.0);
  final c = (1 - (2 * light - 1).abs()) * sat;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = light - c / 2;
  final rgb = _hueSector(h, c, x);
  int ch(double v) => ((v + m) * 255).round().clamp(0, 255);
  return Color.fromARGB(a, ch(rgb.$1), ch(rgb.$2), ch(rgb.$3));
}

(double, double, double) _hueSector(double h, double c, double x) {
  final hue = (h % 360 + 360) % 360;
  if (hue < 60) return (c, x, 0);
  if (hue < 120) return (x, c, 0);
  if (hue < 180) return (0, c, x);
  if (hue < 240) return (0, x, c);
  if (hue < 300) return (x, 0, c);
  return (c, 0, x);
}

int _a(Color c) => (c.value >> 24) & 0xFF;
int _r(Color c) => (c.value >> 16) & 0xFF;
int _g(Color c) => (c.value >> 8) & 0xFF;
int _b(Color c) => c.value & 0xFF;

double _lerp(double a, double b, double t) => a + (b - a) * t;

Color _mixRgb(Color c0, Color c1, double t, double gamma) {
  int ch(int a, int b) {
    final la = math.pow(a / 255, gamma), lb = math.pow(b / 255, gamma);
    return (math.pow(_lerp(la.toDouble(), lb.toDouble(), t), 1 / gamma) * 255)
        .round()
        .clamp(0, 255);
  }

  return Color.fromARGB(
    _lerp(_a(c0).toDouble(), _a(c1).toDouble(), t).round(),
    ch(_r(c0), _r(c1)),
    ch(_g(c0), _g(c1)),
    ch(_b(c0), _b(c1)),
  );
}

(double h, double s, double v) _toHsv(Color c) {
  final r = _r(c) / 255, g = _g(c) / 255, b = _b(c) / 255;
  final max = math.max(r, math.max(g, b)), min = math.min(r, math.min(g, b));
  final d = max - min;
  var h = 0.0;
  if (d != 0) {
    if (max == r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (max == g) {
      h = 60 * ((b - r) / d + 2);
    } else {
      h = 60 * ((r - g) / d + 4);
    }
  }
  if (h < 0) h += 360;
  return (h, max == 0 ? 0 : d / max, max);
}

Color _mixHsv(Color c0, Color c1, double t, bool shortestHue) {
  final (h0, s0, v0) = _toHsv(c0);
  final (h1, s1, v1) = _toHsv(c1);
  var dh = h1 - h0;
  if (shortestHue) {
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
  }
  final h = h0 + dh * t, s = _lerp(s0, s1, t), v = _lerp(v0, v1, t);
  final c = v * s;
  final x = c * (1 - ((((h % 360) + 360) % 360 / 60) % 2 - 1).abs());
  final m = v - c;
  final rgb = _hueSector(h, c, x);
  int ch(double val) => ((val + m) * 255).round().clamp(0, 255);
  return Color.fromARGB(
    _lerp(_a(c0).toDouble(), _a(c1).toDouble(), t).round(),
    ch(rgb.$1),
    ch(rgb.$2),
    ch(rgb.$3),
  );
}

double _toLinear(int c) {
  final s = c / 255;
  return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

int _fromLinear(double l) {
  final v = l <= 0.0031308 ? 12.92 * l : 1.055 * math.pow(l, 1 / 2.4) - 0.055;
  return (v * 255).round().clamp(0, 255);
}

double _cbrt(double x) => x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

(double, double, double) _toOklab(Color c) {
  final r = _toLinear(_r(c)), g = _toLinear(_g(c)), b = _toLinear(_b(c));
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

Color _mixOklab(Color c0, Color c1, double t) {
  final (l0, a0, b0) = _toOklab(c0);
  final (l1, a1, b1) = _toOklab(c1);
  final L = _lerp(l0, l1, t), A = _lerp(a0, a1, t), B = _lerp(b0, b1, t);
  final l = math.pow(L + 0.3963377774 * A + 0.2158037573 * B, 3).toDouble();
  final m = math.pow(L - 0.1055613458 * A - 0.0638541728 * B, 3).toDouble();
  final s = math.pow(L - 0.0894841775 * A - 1.2914855480 * B, 3).toDouble();
  return Color.fromARGB(
    _lerp(_a(c0).toDouble(), _a(c1).toDouble(), t).round(),
    _fromLinear(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    _fromLinear(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    _fromLinear(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
  );
}

const Map<String, int> _namedColors = {
  'transparent': 0x00000000,
  'black': 0xFF000000,
  'white': 0xFFFFFFFF,
  'red': 0xFFFF0000,
  'green': 0xFF008000,
  'lime': 0xFF00FF00,
  'blue': 0xFF0000FF,
  'yellow': 0xFFFFFF00,
  'cyan': 0xFF00FFFF,
  'aqua': 0xFF00FFFF,
  'magenta': 0xFFFF00FF,
  'fuchsia': 0xFFFF00FF,
  'gray': 0xFF808080,
  'grey': 0xFF808080,
  'silver': 0xFFC0C0C0,
  'maroon': 0xFF800000,
  'olive': 0xFF808000,
  'navy': 0xFF000080,
  'purple': 0xFF800080,
  'teal': 0xFF008080,
  'orange': 0xFFFFA500,
  'pink': 0xFFFFC0CB,
  'gold': 0xFFFFD700,
  'indigo': 0xFF4B0082,
  'violet': 0xFFEE82EE,
  'coral': 0xFFFF7F50,
  'salmon': 0xFFFA8072,
  'crimson': 0xFFDC143C,
  'tomato': 0xFFFF6347,
  'turquoise': 0xFF40E0D0,
  'skyblue': 0xFF87CEEB,
  'royalblue': 0xFF4169E1,
  'hotpink': 0xFFFF69B4,
  'plum': 0xFFDDA0DD,
  'chocolate': 0xFFD2691E,
  'tan': 0xFFD2B48C,
  'beige': 0xFFF5F5DC,
  'lavender': 0xFFE6E6FA,
};
