import 'dart:math' as math;

import 'package:dartnative/dartnative.dart'
    show Color, Listenable, VoidCallback;

import '../utilities/colors.dart' show parseColor;
import 'value_codec.dart';
import 'tracking.dart';

/// Something `AnimatedView.style` accepts: a fixed [AnimatedStyle], the
/// handle `useAnimatedStyle` returns, or several merged with [Styles].
abstract interface class StyleSource {
  /// The style right now.
  AnimatedStyle resolve();

  /// What to listen to for changes, or null for a fixed style.
  Listenable? get listenable;
}

/// The animatable style of an `AnimatedView`: transforms, opacity, size,
/// background and corner radius.
///
/// Rotations are in radians. Transforms apply in a fixed order: translate,
/// rotate, 3D rotation ([rotateX], [rotateY], seen from [perspective]
/// pixels away), then scale, all about the view's center.
///
/// Unset (null) properties leave the view as laid out. When styles merge,
/// later non-null values win, as in `style={[a, b]}`.
class AnimatedStyle implements StyleSource {
  const AnimatedStyle({
    this.opacity,
    this.translateX,
    this.translateY,
    this.scale,
    this.scaleX,
    this.scaleY,
    this.rotate,
    this.rotateX,
    this.rotateY,
    this.perspective,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
  });

  final double? opacity;
  final double? translateX;
  final double? translateY;
  final double? scale;
  final double? scaleX;
  final double? scaleY;

  /// Rotation in the screen's plane, in radians.
  final double? rotate;

  /// Rotation about the horizontal axis, in radians.
  final double? rotateX;

  /// Rotation about the vertical axis, in radians.
  final double? rotateY;

  /// Viewing distance for [rotateX] and [rotateY], in logical pixels.
  /// Default 900.
  final double? perspective;

  final double? width;
  final double? height;
  final Color? backgroundColor;
  final double? borderRadius;

  static const AnimatedStyle empty = AnimatedStyle();

  /// The property names, as used by `CSSTransition.properties`.
  static const List<String> propertyNames = [
    'opacity',
    'translateX',
    'translateY',
    'scale',
    'scaleX',
    'scaleY',
    'rotate',
    'rotateX',
    'rotateY',
    'perspective',
    'width',
    'height',
    'backgroundColor',
    'borderRadius',
  ];

  @override
  AnimatedStyle resolve() => this;

  @override
  Listenable? get listenable => null;

  /// The value of property [name] (see [propertyNames]).
  Object? operator [](String name) {
    switch (name) {
      case 'opacity':
        return opacity;
      case 'translateX':
        return translateX;
      case 'translateY':
        return translateY;
      case 'scale':
        return scale;
      case 'scaleX':
        return scaleX;
      case 'scaleY':
        return scaleY;
      case 'rotate':
        return rotate;
      case 'rotateX':
        return rotateX;
      case 'rotateY':
        return rotateY;
      case 'perspective':
        return perspective;
      case 'width':
        return width;
      case 'height':
        return height;
      case 'backgroundColor':
        return backgroundColor;
      case 'borderRadius':
        return borderRadius;
    }
    throw ArgumentError('Unknown style property "$name".');
  }

  /// Builds a style from a property map, as Reanimated keyframes and
  /// `withInitialValues` take them. Colors may be CSS strings.
  factory AnimatedStyle.fromMap(Map<String, Object?> map) {
    double? d(String k) => (map[k] as num?)?.toDouble();
    for (final key in map.keys) {
      if (!propertyNames.contains(key)) {
        throw ArgumentError('Unknown style property "$key".');
      }
    }
    return AnimatedStyle(
      opacity: d('opacity'),
      translateX: d('translateX'),
      translateY: d('translateY'),
      scale: d('scale'),
      scaleX: d('scaleX'),
      scaleY: d('scaleY'),
      rotate: d('rotate'),
      rotateX: d('rotateX'),
      rotateY: d('rotateY'),
      perspective: d('perspective'),
      width: d('width'),
      height: d('height'),
      backgroundColor: parseColor(map['backgroundColor']),
      borderRadius: d('borderRadius'),
    );
  }

  /// The set properties as a map.
  Map<String, Object> toMap() => {
        for (final name in propertyNames)
          if (this[name] != null) name: this[name]!,
      };

  /// This style with [other]'s set properties on top.
  AnimatedStyle merge(AnimatedStyle? other) {
    if (other == null) return this;
    return AnimatedStyle(
      opacity: other.opacity ?? opacity,
      translateX: other.translateX ?? translateX,
      translateY: other.translateY ?? translateY,
      scale: other.scale ?? scale,
      scaleX: other.scaleX ?? scaleX,
      scaleY: other.scaleY ?? scaleY,
      rotate: other.rotate ?? rotate,
      rotateX: other.rotateX ?? rotateX,
      rotateY: other.rotateY ?? rotateY,
      perspective: other.perspective ?? perspective,
      width: other.width ?? width,
      height: other.height ?? height,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
    );
  }

  /// The resting value of property [name] when a style leaves it unset:
  /// 1 for opacity and scales, 0 for translations and rotations. Null for
  /// properties with no neutral value (size, color).
  static Object? identityOf(String name) {
    switch (name) {
      case 'opacity':
      case 'scale':
      case 'scaleX':
      case 'scaleY':
        return 1.0;
      case 'translateX':
      case 'translateY':
      case 'rotate':
      case 'rotateX':
      case 'rotateY':
        return 0.0;
      case 'perspective':
        return 900.0;
      default:
        return null;
    }
  }

  /// Blends from [a] to [b] by [t]. A property set on only one side blends
  /// from (or to) its resting value; one with no resting value switches at
  /// the end.
  static AnimatedStyle lerp(AnimatedStyle a, AnimatedStyle b, double t) {
    final out = <String, Object?>{};
    for (final name in propertyNames) {
      final av = a[name] ?? identityOf(name);
      final bv = b[name] ?? identityOf(name);
      if (av == null && bv == null) continue;
      if (av == null || bv == null) {
        out[name] = t >= 1 ? bv : av;
      } else if (av is double && bv is double) {
        out[name] = av + (bv - av) * t;
      } else if (av is Color && bv is Color) {
        const codec = ColorCodec();
        final ea = codec.encode(av), eb = codec.encode(bv);
        out[name] = codec.decode(
            [for (var i = 0; i < 4; i++) ea[i] + (eb[i] - ea[i]) * t]);
      }
    }
    return AnimatedStyle.fromMap(out);
  }

  @override
  bool operator ==(Object other) =>
      other is AnimatedStyle &&
      propertyNames.every((n) => this[n] == other[n]);

  @override
  int get hashCode =>
      Object.hashAll([for (final n in propertyNames) this[n]]);

  @override
  String toString() => 'AnimatedStyle(${toMap()})';
}

/// Several style sources merged in order; later ones win, as
/// `style={[styles.box, animatedStyles]}` in React Native.
class Styles implements StyleSource {
  const Styles(this.sources);

  final List<StyleSource?> sources;

  @override
  AnimatedStyle resolve() {
    var style = AnimatedStyle.empty;
    for (final s in sources) {
      if (s != null) style = style.merge(s.resolve());
    }
    return style;
  }

  @override
  Listenable? get listenable {
    final ls = [
      for (final s in sources)
        if (s?.listenable != null) s!.listenable,
    ];
    if (ls.isEmpty) return null;
    if (ls.length == 1) return ls.single;
    return _MergedListenable(ls);
  }
}

class _MergedListenable implements Listenable {
  _MergedListenable(this.children);
  final List<Listenable?> children;

  @override
  void addListener(VoidCallback listener) {
    for (final c in children) {
      c?.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final c in children) {
      c?.removeListener(listener);
    }
  }
}

/// A style computed from shared values, as Reanimated's `useAnimatedStyle`.
///
/// The updater re-runs whenever a shared value it read changes, and any
/// `AnimatedView` using the style updates without rebuilding its parent.
/// Pass it to `AnimatedView(style: ...)`.
class AnimatedStyleHandle implements StyleSource, Listenable {
  AnimatedStyleHandle(this._updater) {
    _subscription = DependencySubscription(_recompute);
    _recompute();
  }

  final AnimatedStyle Function() _updater;
  late final DependencySubscription _subscription;
  final List<VoidCallback> _listeners = [];
  AnimatedStyle _style = AnimatedStyle.empty;

  void _recompute() {
    final (style, deps) = DependencyTracker.track(_updater);
    _subscription.update(deps);
    if (style == _style) return;
    _style = style;
    for (final l in List<VoidCallback>.of(_listeners)) {
      l();
    }
  }

  /// The style right now.
  AnimatedStyle get style => _style;

  @override
  AnimatedStyle resolve() => _style;

  @override
  Listenable get listenable => this;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void dispose() {
    _subscription.dispose();
    _listeners.clear();
  }
}

/// Creates an [AnimatedStyleHandle], as Reanimated's `useAnimatedStyle`.
///
/// ```dart
/// final animatedStyles = useAnimatedStyle(() => AnimatedStyle(
///       translateX: offset.value,
///     ));
///
/// AnimatedView(style: animatedStyles, child: ...)
/// ```
AnimatedStyleHandle useAnimatedStyle(AnimatedStyle Function() updater) =>
    AnimatedStyleHandle(updater);

/// Degrees to radians, for writing rotations as Reanimated's `'45deg'`.
double deg(num degrees) => degrees * math.pi / 180;
