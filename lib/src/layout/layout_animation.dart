import 'dart:math' as math;

import '../animations/animation.dart';
import '../animations/modifiers.dart';
import '../animations/spring.dart';
import '../animations/timing.dart';
import '../core/animated_style.dart';
import '../easing/easing.dart';

/// Sizes a layout animation can build its frames from, as the `values` a
/// Reanimated custom layout animation receives.
class LayoutValues {
  const LayoutValues({
    required this.windowWidth,
    required this.windowHeight,
    this.width = 0,
    this.height = 0,
  });

  final double windowWidth;
  final double windowHeight;

  /// The animated view's own size (0 before it has been laid out).
  final double width;
  final double height;
}

/// One step of a layout animation: [style] at [offset] (0 to 1), reached
/// along [easing] from the previous step.
class LayoutFrame {
  const LayoutFrame(this.offset, this.style, [this.easing]);

  final double offset;
  final AnimatedStyle style;
  final EasingFunction? easing;
}

/// A style frame of a [Keyframe] or `CSSKeyframes` that can carry its own
/// easing, used for the stretch leading up to it.
class KeyframeStyle extends AnimatedStyle {
  const KeyframeStyle({
    super.opacity,
    super.translateX,
    super.translateY,
    super.scale,
    super.scaleX,
    super.scaleY,
    super.rotate,
    super.rotateX,
    super.rotateY,
    super.perspective,
    super.width,
    super.height,
    super.backgroundColor,
    super.borderRadius,
    this.easing,
  });

  /// Easing from the previous keyframe to this one.
  final EasingFunction? easing;
}

/// The style at progress [p] through [frames]. Missing properties are filled
/// from neighbouring frames so every property moves continuously.
AnimatedStyle evaluateFrames(List<LayoutFrame> frames, double p) {
  if (frames.isEmpty) return AnimatedStyle.empty;
  if (frames.length == 1) return frames.single.style;
  if (frames.length == 2) {
    // Two frames: extrapolate past 1 so springs can overshoot.
    final a = frames.first, b = frames.last;
    final span = b.offset - a.offset;
    final t = span == 0 ? 1.0 : (p - a.offset) / span;
    return AnimatedStyle.lerp(a.style, b.style, (b.easing ?? Easing.linear)(t.clamp(0.0, 1.0)) + (t > 1 ? t - 1 : 0));
  }
  final q = p.clamp(0.0, 1.0);
  var i = 0;
  while (i < frames.length - 2 && q > frames[i + 1].offset) {
    i++;
  }
  final a = frames[i], b = frames[i + 1];
  final span = b.offset - a.offset;
  final t = span == 0 ? 1.0 : ((q - a.offset) / span).clamp(0.0, 1.0);
  return AnimatedStyle.lerp(a.style, b.style, (b.easing ?? Easing.linear)(t));
}

/// Fills every frame's unset properties so each animated property has a
/// value in every frame: from the nearest earlier frame, else the nearest
/// later one.
List<LayoutFrame> completeFrames(List<LayoutFrame> frames) {
  final names = <String>{
    for (final f in frames) ...f.style.toMap().keys,
  };
  final out = <LayoutFrame>[];
  for (var i = 0; i < frames.length; i++) {
    final map = frames[i].style.toMap();
    for (final name in names) {
      if (map.containsKey(name)) continue;
      Object? v;
      for (var j = i - 1; j >= 0 && v == null; j--) {
        v = frames[j].style[name];
      }
      for (var j = i + 1; j < frames.length && v == null; j++) {
        v = frames[j].style[name];
      }
      if (v != null) map[name] = v;
    }
    out.add(LayoutFrame(frames[i].offset, AnimatedStyle.fromMap(map), frames[i].easing));
  }
  return out;
}

/// Base of every entering, exiting and keyframe layout animation: the
/// builder modifiers Reanimated's presets share.
///
/// ```dart
/// AnimatedView(
///   entering: FadeIn().duration(const Duration(milliseconds: 500)).delay(...),
///   exiting: SlideOutLeft().springify().damping(30),
///   child: ...,
/// )
/// ```
///
/// Modifiers change this builder and return it. Like in Reanimated, create
/// builders once (a `static final` or a `State` field) rather than in
/// `build`.
abstract class LayoutAnimation {
  LayoutAnimation();

  Duration? _duration;
  Duration _delay = Duration.zero;
  bool _randomDelay = false;
  EasingFunction? _easing;
  bool _spring = false;
  double _damping = 120, _mass = 4, _stiffness = 900, _energyThreshold = 6e-9;
  double? _dampingRatio;
  Duration? _springDuration;
  bool _overshootClamping = false;
  ReduceMotion? _reduceMotion;
  AnimatedStyle? _initialValues;
  AnimatedStyle? _targetValues;
  AnimationCallback? _callback;

  /// Whether this animation plays as a view leaves (false: as it appears).
  bool get isExiting;

  /// Default length when [duration] is not set.
  Duration get defaultDuration => const Duration(milliseconds: 300);

  /// The animation's frames for a view of the given size.
  List<LayoutFrame> buildFrames(LayoutValues values);

  LayoutAnimation duration(Duration value) {
    _duration = value;
    return this;
  }

  LayoutAnimation delay(Duration value) {
    _delay = value;
    return this;
  }

  /// Waits a random time up to [delay] (or up to a second when no delay is
  /// set) before starting.
  LayoutAnimation randomDelay() {
    _randomDelay = true;
    return this;
  }

  /// Easing of a timing-based animation. Ignored once [springify]'d.
  LayoutAnimation easing(EasingFunction value) {
    _easing = value;
    return this;
  }

  /// Runs on a spring instead of a timing curve. [duration] makes it a
  /// duration-based spring. Ignored by multi-step presets (Bounce) and
  /// [Keyframe]s.
  LayoutAnimation springify([Duration? duration]) {
    _spring = true;
    _springDuration = duration;
    return this;
  }

  LayoutAnimation damping(double value) {
    _spring = true;
    _damping = value;
    return this;
  }

  LayoutAnimation mass(double value) {
    _spring = true;
    _mass = value;
    return this;
  }

  LayoutAnimation stiffness(double value) {
    _spring = true;
    _stiffness = value;
    return this;
  }

  LayoutAnimation dampingRatio(double value) {
    _spring = true;
    _dampingRatio = value;
    return this;
  }

  LayoutAnimation overshootClamping(bool value) {
    _spring = true;
    _overshootClamping = value;
    return this;
  }

  LayoutAnimation energyThreshold(double value) {
    _spring = true;
    _energyThreshold = value;
    return this;
  }

  LayoutAnimation reduceMotion(ReduceMotion value) {
    _reduceMotion = value;
    return this;
  }

  /// Overrides the style the animation starts from.
  LayoutAnimation withInitialValues(AnimatedStyle values) {
    _initialValues = values;
    return this;
  }

  /// Overrides the style the animation ends at.
  LayoutAnimation withTargetValues(AnimatedStyle values) {
    _targetValues = values;
    return this;
  }

  /// Called when the animation ends; `finished` is false if it was
  /// interrupted.
  LayoutAnimation withCallback(AnimationCallback callback) {
    _callback = callback;
    return this;
  }

  /// The frames to play, with [withInitialValues], [withTargetValues] and
  /// the view's resting [base] style applied.
  List<LayoutFrame> resolveFrames(LayoutValues values, AnimatedStyle base) {
    var frames = List.of(buildFrames(values));
    if (_initialValues != null) {
      frames = [
        LayoutFrame(frames.first.offset, frames.first.style.merge(_initialValues), frames.first.easing),
        ...frames.skip(1),
      ];
    }
    if (_targetValues != null) {
      frames = [
        ...frames.take(frames.length - 1),
        LayoutFrame(frames.last.offset, frames.last.style.merge(_targetValues), frames.last.easing),
      ];
    }
    // The resting end (target for entering, start for exiting) defaults to
    // the view's own style, else to the neutral value.
    frames = List.of(frames);
    final names = {for (final f in frames) ...f.style.toMap().keys};
    final rest = <String, Object?>{
      for (final n in names) n: base[n] ?? AnimatedStyle.identityOf(n),
    };
    final restStyle = AnimatedStyle.fromMap(rest);
    if (isExiting) {
      final first = frames.first;
      frames[0] = LayoutFrame(first.offset, restStyle.merge(first.style), first.easing);
    } else {
      final last = frames.last;
      frames[frames.length - 1] = LayoutFrame(last.offset, restStyle.merge(last.style), last.easing);
    }
    return completeFrames(frames);
  }

  /// The animation driving progress from 0 to 1.
  ReanimatedAnimation progressAnimation({required bool multiStep, AnimationCallback? onEnd}) {
    void callback(bool finished) {
      _callback?.call(finished);
      onEnd?.call(finished);
    }

    final ReanimatedAnimation main;
    if (_spring && !multiStep) {
      main = withSpring(
        1.0,
        mass: _mass,
        stiffness: _stiffness,
        damping: _damping,
        dampingRatio: _dampingRatio,
        duration: _springDuration,
        overshootClamping: _overshootClamping,
        energyThreshold: _energyThreshold,
        reduceMotion: _reduceMotion,
        callback: callback,
      );
    } else {
      main = withTiming(
        1.0,
        duration: _duration ?? defaultDuration,
        easing: multiStep ? Easing.linear : (_easing ?? defaultTimingEasing),
        reduceMotion: _reduceMotion,
        callback: callback,
      );
    }
    var delay = _delay;
    if (_randomDelay) {
      final maxMs = delay > Duration.zero ? delay.inMilliseconds : 1000;
      delay = Duration(milliseconds: math.Random().nextInt(maxMs + 1));
    }
    if (delay <= Duration.zero) return main;
    return withDelay(delay, main, reduceMotion: _reduceMotion);
  }
}

/// An entering animation (plays as a view appears).
abstract class EntryAnimation extends LayoutAnimation {
  @override
  bool get isExiting => false;
}

/// An exiting animation (plays as a view leaves).
abstract class ExitAnimation extends LayoutAnimation {
  @override
  bool get isExiting => true;
}

/// A layout animation built from keyframes, as Reanimated's `Keyframe`.
///
/// Keys are percentages (`0`–`100`) or `'from'`/`'to'`. Keyframe 0 (or
/// `'from'`) is required and gives every animated property's starting
/// value. Per-step easing goes on the frame it leads to, with
/// [KeyframeStyle.easing]; it defaults to linear.
///
/// ```dart
/// final keyframe = Keyframe({
///   0: const AnimatedStyle(rotate: 0),
///   45: KeyframeStyle(rotate: deg(100), easing: Easing.exp),
///   100: const AnimatedStyle(rotate: 0),
/// }).duration(const Duration(milliseconds: 2000));
///
/// AnimatedView(entering: keyframe, ...)
/// ```
///
/// Used as `entering` it plays forward; as `exiting` it also plays forward,
/// from its first frame to its last.
class Keyframe extends LayoutAnimation {
  Keyframe(Map<Object, AnimatedStyle> definitions, {this.exiting = false})
      : _frames = _parse(definitions);

  /// Whether to treat this keyframe as an exiting animation when it is not
  /// passed to `exiting:` (where it always is).
  final bool exiting;

  final List<LayoutFrame> _frames;

  @override
  bool get isExiting => exiting;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 500);

  static List<LayoutFrame> _parse(Map<Object, AnimatedStyle> defs) {
    double offsetOf(Object key) {
      if (key == 'from') return 0;
      if (key == 'to') return 100;
      if (key is num) return key.toDouble();
      if (key is String && key.endsWith('%')) {
        return double.parse(key.substring(0, key.length - 1));
      }
      throw ArgumentError('Invalid keyframe key "$key".');
    }

    final seen = <double>{};
    final frames = <LayoutFrame>[];
    for (final e in defs.entries) {
      final offset = offsetOf(e.key);
      if (offset < 0 || offset > 100) {
        throw ArgumentError('Keyframe offsets must be between 0 and 100.');
      }
      if (!seen.add(offset)) {
        throw ArgumentError('Keyframe $offset is defined twice '
            '(e.g. both 0 and "from", or 100 and "to").');
      }
      final style = e.value;
      final easing = style is KeyframeStyle ? style.easing : null;
      if (offset == 0 && easing != null) {
        throw ArgumentError('Keyframe 0 cannot have an easing.');
      }
      frames.add(LayoutFrame(offset / 100, style, easing));
    }
    if (!seen.contains(0)) {
      throw ArgumentError('A Keyframe needs a 0 (or "from") frame.');
    }
    frames.sort((a, b) => a.offset.compareTo(b.offset));
    final initial = frames.first.style.toMap().keys.toSet();
    for (final f in frames) {
      for (final key in f.style.toMap().keys) {
        if (!initial.contains(key)) {
          throw ArgumentError(
              'Keyframe property "$key" has no initial value in frame 0.');
        }
      }
    }
    if (frames.last.offset < 1) {
      frames.add(LayoutFrame(1, frames.last.style));
    }
    return frames;
  }

  @override
  List<LayoutFrame> buildFrames(LayoutValues values) => List.of(_frames);

  @override
  List<LayoutFrame> resolveFrames(LayoutValues values, AnimatedStyle base) {
    // Keyframes are explicit: no resting style is filled in.
    return completeFrames(buildFrames(values));
  }
}

/// A layout animation whose frames you compute, as Reanimated's custom
/// entering/exiting animations: [builder] receives the window and view size
/// and returns the starting and final style.
///
/// ```dart
/// final entering = CustomEntering((v) => (
///       initial: AnimatedStyle(translateY: -v.windowHeight, opacity: 0),
///       target: const AnimatedStyle(translateY: 0, opacity: 1),
///     )).springify();
/// ```
class CustomEntering extends EntryAnimation {
  CustomEntering(this.builder);
  final ({AnimatedStyle initial, AnimatedStyle target}) Function(LayoutValues) builder;

  @override
  List<LayoutFrame> buildFrames(LayoutValues values) {
    final r = builder(values);
    return [LayoutFrame(0, r.initial), LayoutFrame(1, r.target)];
  }
}

/// The exiting counterpart of [CustomEntering].
class CustomExiting extends ExitAnimation {
  CustomExiting(this.builder);
  final ({AnimatedStyle initial, AnimatedStyle target}) Function(LayoutValues) builder;

  @override
  List<LayoutFrame> buildFrames(LayoutValues values) {
    final r = builder(values);
    return [LayoutFrame(0, r.initial), LayoutFrame(1, r.target)];
  }
}
