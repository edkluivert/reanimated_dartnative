import 'dart:math' as math;

import 'package:dartnative/dartnative.dart' show Color, Offset, Size;

import '../utilities/colors.dart';

/// Converts an animatable value to and from the list of numbers the
/// animation engine works on, so one spring or timing curve can drive a
/// number, a [Color], an [Offset], a [Size] or a `List<double>`.
///
/// Every component animates on its own curve with the same config, as
/// Reanimated does for colors, objects and arrays.
abstract class ValueCodec<T> {
  const ValueCodec();

  int get length;
  List<double> encode(T value);
  T decode(List<double> components);

  /// Encodes [value] for this codec. A plain number is accepted for any
  /// codec and applies to every component (a decay `velocity` of 0, say).
  List<double> encodeAny(Object? value) {
    if (value is T) return encode(value);
    if (value is num) return List.filled(length, value.toDouble());
    if (T == Color || this is ColorCodec) {
      final parsed = parseColor(value);
      if (parsed != null) return encode(parsed as T);
    }
    throw ArgumentError(
        'Cannot animate a $T value to ${value.runtimeType} ($value).');
  }

  /// The codec for [value]'s type.
  static ValueCodec<T> of<T>(T value) {
    final Object? v = value;
    if (v is int) return const IntCodec() as ValueCodec<T>;
    if (v is num) return const DoubleCodec() as ValueCodec<T>;
    if (v is Color) return const ColorCodec() as ValueCodec<T>;
    if (v is Offset) return const OffsetCodec() as ValueCodec<T>;
    if (v is Size) return const SizeCodec() as ValueCodec<T>;
    if (v is List<double>) return ListCodec(v.length) as ValueCodec<T>;
    throw UnsupportedError(
        'SharedValue<${v.runtimeType}> cannot be animated. Animatable types: '
        'num, Color, Offset, Size and List<double>.');
  }

  /// Whether [value] has a type [of] supports.
  static bool canAnimate(Object? value) =>
      value is num ||
      value is Color ||
      value is Offset ||
      value is Size ||
      value is List<double>;
}

class DoubleCodec extends ValueCodec<double> {
  const DoubleCodec();
  @override
  int get length => 1;
  @override
  List<double> encode(double value) => [value];
  @override
  double decode(List<double> c) => c[0];
}

class IntCodec extends ValueCodec<int> {
  const IntCodec();
  @override
  int get length => 1;
  @override
  List<double> encode(int value) => [value.toDouble()];
  @override
  int decode(List<double> c) => c[0].round();
}

class OffsetCodec extends ValueCodec<Offset> {
  const OffsetCodec();
  @override
  int get length => 2;
  @override
  List<double> encode(Offset value) => [value.dx, value.dy];
  @override
  Offset decode(List<double> c) => Offset(c[0], c[1]);
}

class SizeCodec extends ValueCodec<Size> {
  const SizeCodec();
  @override
  int get length => 2;
  @override
  List<double> encode(Size value) => [value.width, value.height];
  @override
  Size decode(List<double> c) => Size(c[0], c[1]);
}

class ListCodec extends ValueCodec<List<double>> {
  const ListCodec(this.length);
  @override
  final int length;
  @override
  List<double> encode(List<double> value) {
    if (value.length != length) {
      throw ArgumentError('Expected $length numbers, got ${value.length}.');
    }
    return List<double>.of(value);
  }

  @override
  List<double> decode(List<double> c) => List<double>.unmodifiable(c);
}

/// Colors animate in linear light (gamma 2.2), Reanimated's default for
/// RGB, so a red-to-green transition does not dip through a muddy brown.
class ColorCodec extends ValueCodec<Color> {
  const ColorCodec();

  static const double gamma = 2.2;

  @override
  int get length => 4;

  @override
  List<double> encode(Color value) {
    final v = value.value;
    double lin(int shift) => math.pow(((v >> shift) & 0xFF) / 255.0, gamma).toDouble();
    return [((v >> 24) & 0xFF) / 255.0, lin(16), lin(8), lin(0)];
  }

  @override
  Color decode(List<double> c) {
    int ch(double linear) =>
        (math.pow(linear.clamp(0.0, 1.0), 1 / gamma) * 255.0).round();
    final a = (c[0].clamp(0.0, 1.0) * 255.0).round();
    return Color.fromARGB(a, ch(c[1]), ch(c[2]), ch(c[3]));
  }
}
