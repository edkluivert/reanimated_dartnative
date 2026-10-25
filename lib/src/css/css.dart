import '../core/animated_style.dart';
import '../easing/easing.dart';
import '../layout/layout_animation.dart';

/// CSS timing functions, as accepted by Reanimated 4's
/// `animationTimingFunction` and `transitionTimingFunction`.
abstract final class CSSTimingFunction {
  static double linear(double t) => t;

  /// CSS `ease`, the default: `cubic-bezier(0.25, 0.1, 0.25, 1)`.
  static final EasingFunction ease = Easing.bezier(0.25, 0.1, 0.25, 1);
  static final EasingFunction easeIn = Easing.bezier(0.42, 0, 1, 1);
  static final EasingFunction easeOut = Easing.bezier(0, 0, 0.58, 1);
  static final EasingFunction easeInOut = Easing.bezier(0.42, 0, 0.58, 1);

  /// CSS `step-start`: jumps to the end immediately.
  static double stepStart(double t) => t > 0 ? 1 : 0;

  /// CSS `step-end`: holds the start until the very end.
  static double stepEnd(double t) => t >= 1 ? 1 : 0;

  /// CSS `cubic-bezier(x1, y1, x2, y2)`.
  static EasingFunction cubicBezier(double x1, double y1, double x2, double y2) =>
      Easing.bezier(x1, y1, x2, y2);

  /// CSS `steps(n, position)`.
  static EasingFunction steps(int n, [StepPosition position = StepPosition.jumpEnd]) {
    if (n <= 0 || (position == StepPosition.jumpNone && n < 2)) {
      throw ArgumentError('Invalid number of steps: $n.');
    }
    // The CSS Easing Functions spec's step algorithm.
    final jumps = switch (position) {
      StepPosition.jumpStart || StepPosition.start => n,
      StepPosition.jumpEnd || StepPosition.end => n,
      StepPosition.jumpNone => n - 1,
      StepPosition.jumpBoth => n + 1,
    };
    final jumpsAtStart = position == StepPosition.jumpStart ||
        position == StepPosition.start ||
        position == StepPosition.jumpBoth;
    return (t) {
      var step = (t * n).floor();
      if (jumpsAtStart) step += 1;
      if (t >= 0 && step < 0) step = 0;
      if (t <= 1 && step > jumps) step = jumps;
      return step / jumps;
    };
  }

  /// CSS `linear(...)`: straight lines through [points] (outputs at evenly
  /// spaced inputs, or `(output, input)` pairs with explicit positions).
  static EasingFunction linearPoints(List<Object> points) {
    final xs = <double>[], ys = <double>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p is num) {
        ys.add(p.toDouble());
        xs.add(double.nan);
      } else if (p is (num, num)) {
        ys.add(p.$1.toDouble());
        xs.add(p.$2.toDouble());
      } else {
        throw ArgumentError('linear() points are numbers or (output, input) pairs.');
      }
    }
    if (ys.length < 2) throw ArgumentError('linear() needs at least two points.');
    if (xs.first.isNaN) xs[0] = 0;
    if (xs.last.isNaN) xs[xs.length - 1] = 1;
    // Spread unpositioned points evenly between positioned neighbours.
    var i = 0;
    while (i < xs.length) {
      if (!xs[i].isNaN) {
        i++;
        continue;
      }
      final start = i - 1;
      var end = i;
      while (xs[end].isNaN) {
        end++;
      }
      for (var k = start + 1; k < end; k++) {
        xs[k] = xs[start] + (xs[end] - xs[start]) * (k - start) / (end - start);
      }
      i = end;
    }
    return (t) {
      if (t <= xs.first) return ys.first;
      for (var k = 0; k < xs.length - 1; k++) {
        if (t <= xs[k + 1]) {
          final span = xs[k + 1] - xs[k];
          return span == 0 ? ys[k + 1] : ys[k] + (ys[k + 1] - ys[k]) * (t - xs[k]) / span;
        }
      }
      return ys.last;
    };
  }
}

/// Where the jumps of [CSSTimingFunction.steps] fall.
enum StepPosition { jumpStart, jumpEnd, jumpNone, jumpBoth, start, end }

/// Keyframes of a CSS animation, as Reanimated 4's `animationName` object.
///
/// Keys are `'from'`, `'to'`, percentage strings (`'50%'`) or numbers from
/// 0 to 1. A frame may be a [KeyframeStyle] carrying the timing function for
/// the stretch leading up to it. At least one keyframe is required; a
/// missing start or end uses the view's own style.
class CSSKeyframes {
  CSSKeyframes(Map<Object, AnimatedStyle> frames) : frames = _parse(frames);

  /// Frames sorted by offset (0–1).
  final List<(double offset, AnimatedStyle style)> frames;

  static List<(double, AnimatedStyle)> _parse(Map<Object, AnimatedStyle> map) {
    if (map.isEmpty) throw ArgumentError('CSSKeyframes needs at least one keyframe.');
    double offsetOf(Object key) {
      if (key == 'from') return 0;
      if (key == 'to') return 1;
      if (key is num) return key.toDouble();
      if (key is String && key.endsWith('%')) {
        return double.parse(key.substring(0, key.length - 1)) / 100;
      }
      throw ArgumentError('Invalid keyframe offset "$key".');
    }

    final list = [for (final e in map.entries) (offsetOf(e.key), e.value)];
    list.sort((a, b) => a.$1.compareTo(b.$1));
    return list;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CSSKeyframes || other.frames.length != frames.length) return false;
    for (var i = 0; i < frames.length; i++) {
      if (frames[i].$1 != other.frames[i].$1 || frames[i].$2 != other.frames[i].$2) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(frames.map((f) => Object.hash(f.$1, f.$2)));
}

enum AnimationDirection { normal, reverse, alternate, alternateReverse }

enum AnimationFillMode { none, forwards, backwards, both }

enum AnimationPlayState { running, paused }

/// Payload of CSS animation callbacks.
class CSSAnimationEvent {
  const CSSAnimationEvent(this.elapsedTime);

  /// Seconds the animation has been running, excluding delay.
  final double elapsedTime;
}

/// A CSS animation, as Reanimated 4's `animation*` style properties.
///
/// ```dart
/// AnimatedView(
///   cssAnimations: [
///     CSSAnimation(
///       keyframes: CSSKeyframes({
///         'to': const AnimatedStyle(rotate: 2 * math.pi),
///       }),
///       duration: const Duration(seconds: 3),
///       iterationCount: double.infinity,
///       timingFunction: CSSTimingFunction.linear,
///     ),
///   ],
///   child: ...,
/// )
/// ```
class CSSAnimation {
  CSSAnimation({
    required this.keyframes,
    this.duration = Duration.zero,
    this.delay = Duration.zero,
    EasingFunction? timingFunction,
    this.iterationCount = 1,
    this.direction = AnimationDirection.normal,
    this.fillMode = AnimationFillMode.none,
    this.playState = AnimationPlayState.running,
    this.onStart,
    this.onIteration,
    this.onEnd,
    this.onCancel,
  }) : timingFunction = timingFunction ?? CSSTimingFunction.ease {
    if (iterationCount < 0) throw ArgumentError('iterationCount must be >= 0.');
  }

  final CSSKeyframes keyframes;
  final Duration duration;

  /// Wait before starting. A negative delay starts partway through.
  final Duration delay;

  /// Timing between each pair of keyframes (CSS applies it per segment).
  final EasingFunction timingFunction;

  /// Number of iterations; fractions stop partway, [double.infinity] loops.
  final double iterationCount;
  final AnimationDirection direction;
  final AnimationFillMode fillMode;
  final AnimationPlayState playState;

  final void Function(CSSAnimationEvent)? onStart;
  final void Function(CSSAnimationEvent)? onIteration;
  final void Function(CSSAnimationEvent)? onEnd;
  final void Function(CSSAnimationEvent)? onCancel;
}

/// Plays one [CSSAnimation]: the style at a given time and the events.
class CSSAnimationPlayer {
  CSSAnimationPlayer(this.animation);

  CSSAnimation animation;
  double _elapsed = 0; // seconds since start, including delay
  bool _started = false;
  bool _ended = false;
  int _iteration = 0;

  bool get isEnded => _ended;

  /// Advances by [dt] seconds (no time passes while paused).
  void advance(double dt) {
    if (animation.playState == AnimationPlayState.paused || _ended) return;
    _elapsed += dt;
    final active = _elapsed - _seconds(animation.delay);
    final total = _seconds(animation.duration) * animation.iterationCount;
    if (active >= 0 && !_started) {
      _started = true;
      animation.onStart?.call(CSSAnimationEvent(active));
    }
    if (!_started) return;
    final d = _seconds(animation.duration);
    if (d > 0 && animation.iterationCount > 1) {
      final it = (active / d).floor();
      while (_iteration < it && _iteration + 1 < animation.iterationCount) {
        _iteration++;
        animation.onIteration?.call(CSSAnimationEvent(_iteration * d));
      }
    }
    if (active >= total) {
      _ended = true;
      animation.onEnd?.call(CSSAnimationEvent(total));
    }
  }

  /// Fires `onCancel` when the animation is removed before it ended.
  void cancel() {
    if (_started && !_ended) {
      _ended = true;
      animation.onCancel?.call(
          CSSAnimationEvent(_elapsed - _seconds(animation.delay)));
    }
  }

  static double _seconds(Duration d) => d.inMicroseconds / 1e6;

  /// The style now, with [base] (the view's own style) filling missing
  /// start and end frames. Null when the animation has no effect (before
  /// its delay or after its end without a fill mode).
  AnimatedStyle? style(AnimatedStyle base) {
    final a = animation;
    final d = _seconds(a.duration);
    final active = _elapsed - _seconds(a.delay);
    final fill = a.fillMode;
    double iterationProgress; // overall progress in iterations
    if (active < 0) {
      if (fill != AnimationFillMode.backwards && fill != AnimationFillMode.both) return null;
      iterationProgress = 0;
    } else if (d <= 0 || active >= d * a.iterationCount) {
      if (fill != AnimationFillMode.forwards && fill != AnimationFillMode.both) return null;
      iterationProgress = a.iterationCount;
    } else {
      iterationProgress = active / d;
    }

    var index = iterationProgress.floor();
    var local = iterationProgress - index;
    if (local == 0 && index > 0 && iterationProgress >= a.iterationCount) {
      // Exactly at the end of the last iteration: show its final frame.
      index -= 1;
      local = 1;
    }
    final reversed = switch (a.direction) {
      AnimationDirection.normal => false,
      AnimationDirection.reverse => true,
      AnimationDirection.alternate => index.isOdd,
      AnimationDirection.alternateReverse => index.isEven,
    };
    return _sample(reversed ? 1 - local : local, base, reversed);
  }

  AnimatedStyle _sample(double t, AnimatedStyle base, bool reversed) {
    final frames = [...animation.keyframes.frames];
    if (frames.first.$1 > 0) frames.insert(0, (0.0, AnimatedStyle.empty));
    if (frames.last.$1 < 1) frames.add((1.0, AnimatedStyle.empty));
    final names = {for (final f in frames) ...f.$2.toMap().keys};
    final rest = AnimatedStyle.fromMap({
      for (final n in names) n: base[n] ?? AnimatedStyle.identityOf(n),
    });
    final layout = completeFrames([
      for (final f in frames)
        LayoutFrame(f.$1, rest.merge(f.$2),
            f.$2 is KeyframeStyle ? (f.$2 as KeyframeStyle).easing : null),
    ]);
    var i = 0;
    while (i < layout.length - 2 && t > layout[i + 1].offset) {
      i++;
    }
    final from = layout[i], to = layout[i + 1];
    final span = to.offset - from.offset;
    final u = span == 0 ? 1.0 : ((t - from.offset) / span).clamp(0.0, 1.0);
    // Per-keyframe timing belongs to the stretch it starts in CSS; in
    // reverse playback the curve is mirrored.
    final ease = to.easing ?? animation.timingFunction;
    final eased = reversed ? 1 - ease(1 - u) : ease(u);
    return AnimatedStyle.lerp(from.style, to.style, eased);
  }
}

/// CSS transitions, as Reanimated 4's `transition*` style properties: when
/// the view's (non-shared-value) style changes between builds, the listed
/// [properties] animate to their new values.
///
/// ```dart
/// AnimatedView(
///   style: AnimatedStyle(width: expanded ? 240 : 120),
///   cssTransition: CSSTransition(
///     properties: const ['width'],
///     duration: const Duration(milliseconds: 500),
///   ),
///   child: ...,
/// )
/// ```
class CSSTransition {
  CSSTransition({
    this.properties = const ['all'],
    this.duration = Duration.zero,
    this.delay = Duration.zero,
    EasingFunction? timingFunction,
    this.onRun,
    this.onStart,
    this.onEnd,
    this.onCancel,
  }) : timingFunction = timingFunction ?? CSSTimingFunction.ease;

  /// Property names (see `AnimatedStyle.propertyNames`), or `['all']`.
  final List<String> properties;
  final Duration duration;
  final Duration delay;
  final EasingFunction timingFunction;

  final void Function(CSSTransitionEvent)? onRun;
  final void Function(CSSTransitionEvent)? onStart;
  final void Function(CSSTransitionEvent)? onEnd;
  final void Function(CSSTransitionEvent)? onCancel;

  bool covers(String property) =>
      properties.contains('all') || properties.contains(property);
}

/// Payload of CSS transition callbacks.
class CSSTransitionEvent {
  const CSSTransitionEvent(this.propertyName, this.elapsedTime);
  final String propertyName;
  final double elapsedTime;
}

/// Runs the transitions of one view: one track per changing property.
class CSSTransitionPlayer {
  final Map<String, _Track> _tracks = {};
  AnimatedStyle? _lastTarget;

  bool get isActive => _tracks.isNotEmpty;

  /// Call with the view's style each build. Changed properties covered by
  /// [transition] start a track from what is on screen now.
  void update(AnimatedStyle target, CSSTransition? transition) {
    final previous = _lastTarget;
    _lastTarget = target;
    if (previous == null || transition == null) return;
    final now = current(previous);
    for (final name in AnimatedStyle.propertyNames) {
      if (!transition.covers(name)) continue;
      final to = target[name], was = previous[name];
      if (to == was) continue;
      final from = now[name] ?? AnimatedStyle.identityOf(name);
      final dest = to ?? AnimatedStyle.identityOf(name);
      if (from == null || dest == null) continue;
      final old = _tracks.remove(name);
      if (old != null && !old.ended) {
        transition.onCancel?.call(CSSTransitionEvent(name, old.elapsed));
      }
      final track = _Track(name, from, dest, transition);
      _tracks[name] = track;
      transition.onRun?.call(CSSTransitionEvent(name, 0));
    }
  }

  void advance(double dt) {
    for (final track in _tracks.values.toList()) {
      track.advance(dt);
      if (track.ended) _tracks.remove(track.name);
    }
  }

  /// [target] with running transitions' values on top.
  AnimatedStyle current(AnimatedStyle target) {
    if (_tracks.isEmpty) return target;
    final map = target.toMap().cast<String, Object?>();
    for (final t in _tracks.values) {
      map[t.name] = t.value;
    }
    return AnimatedStyle.fromMap(map);
  }

  void cancelAll() {
    for (final t in _tracks.values) {
      if (!t.ended) t.transition.onCancel?.call(CSSTransitionEvent(t.name, t.elapsed));
    }
    _tracks.clear();
  }
}

class _Track {
  _Track(this.name, this.from, this.to, this.transition);
  final String name;
  final Object from, to;
  final CSSTransition transition;
  double _time = 0;
  bool started = false, ended = false;

  double get elapsed => (_time - transition.delay.inMicroseconds / 1e6).clamp(0, double.infinity);

  void advance(double dt) {
    _time += dt;
    final active = _time - transition.delay.inMicroseconds / 1e6;
    if (active >= 0 && !started) {
      started = true;
      transition.onStart?.call(CSSTransitionEvent(name, 0));
    }
    final d = transition.duration.inMicroseconds / 1e6;
    if (active >= d) {
      ended = true;
      transition.onEnd?.call(CSSTransitionEvent(name, d));
    }
  }

  Object get value {
    final d = transition.duration.inMicroseconds / 1e6;
    final active = _time - transition.delay.inMicroseconds / 1e6;
    final t = d <= 0 ? (active >= 0 ? 1.0 : 0.0) : (active / d).clamp(0.0, 1.0);
    final e = transition.timingFunction(t);
    final a = AnimatedStyle.fromMap({name: from}), b = AnimatedStyle.fromMap({name: to});
    return AnimatedStyle.lerp(a, b, e)[name]!;
  }
}
