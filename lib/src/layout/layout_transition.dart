import 'dart:math' as math;

import '../animations/animation.dart';
import '../core/animated_style.dart';
import '../easing/easing.dart';
import 'layout_animation.dart';
import 'presets.dart';

/// How a view moves when its position or size changes, as the `layout`
/// prop's transitions in Reanimated. Pass one to `AnimatedView(layout: ...)`.
///
/// The view is measured after every build; when it has moved or resized, it
/// is drawn at its old place and size and animated to the new one.
abstract class LayoutTransition extends LayoutAnimation {
  @override
  bool get isExiting => false;

  /// The offset style at progress [p], given the change from the old
  /// frame: [dx], [dy] move the view's center from new to old position;
  /// [sx], [sy] scale its new size to the old one.
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy);

  @override
  List<LayoutFrame> buildFrames(LayoutValues values) =>
      const [LayoutFrame(0, AnimatedStyle.empty), LayoutFrame(1, AnimatedStyle.empty)];

  static AnimatedStyle _flip(double k, double dx, double dy, double sx, double sy) =>
      AnimatedStyle(
        translateX: dx * k,
        translateY: dy * k,
        scaleX: 1 + (sx - 1) * k,
        scaleY: 1 + (sy - 1) * k,
      );
}

/// Moves and resizes the view in a straight line. Supports timing and
/// spring modifiers.
class LinearTransition extends LayoutTransition {
  @override
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy) =>
      LayoutTransition._flip(1 - p, dx, dy, sx, sy);
}

/// Moves horizontally first, then vertically ([reverse]: the other way
/// round). Default 500 ms.
class SequencedTransition extends LayoutTransition {
  bool _reverse = false;

  SequencedTransition reverse() {
    _reverse = true;
    return this;
  }

  @override
  Duration get defaultDuration => const Duration(milliseconds: 500);

  @override
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy) {
    final first = (p * 2).clamp(0.0, 1.0), second = (p * 2 - 1).clamp(0.0, 1.0);
    final px = _reverse ? second : first, py = _reverse ? first : second;
    return AnimatedStyle(
      translateX: dx * (1 - px),
      translateY: dy * (1 - py),
      scaleX: 1 + (sx - 1) * (1 - px),
      scaleY: 1 + (sy - 1) * (1 - py),
    );
  }
}

/// Fades out at the old place, then fades in at the new one. Default
/// 500 ms.
class FadingTransition extends LayoutTransition {
  @override
  Duration get defaultDuration => const Duration(milliseconds: 500);

  @override
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy) {
    if (p < 0.5) {
      return LayoutTransition._flip(1, dx, dy, sx, sy).merge(AnimatedStyle(opacity: 1 - p * 2));
    }
    return AnimatedStyle(opacity: (p - 0.5) * 2);
  }
}

/// Jumps to the new place in an arc.
class JumpingTransition extends LayoutTransition {
  @override
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy) {
    final hop = math.max(dx.abs(), dy.abs()) / 2;
    return LayoutTransition._flip(1 - p, dx, dy, sx, sy)
        .merge(AnimatedStyle(translateY: dy * (1 - p) - math.sin(p * math.pi) * hop));
  }
}

/// Moves with a separate easing per axis and for width and height, so the
/// path curves.
class CurvedTransition extends LayoutTransition {
  EasingFunction _ex = Easing.inOut(Easing.ease), _ey = Easing.out(Easing.exp);
  EasingFunction _ew = Easing.inOut(Easing.ease), _eh = Easing.out(Easing.exp);

  CurvedTransition easingX(EasingFunction e) {
    _ex = e;
    return this;
  }

  CurvedTransition easingY(EasingFunction e) {
    _ey = e;
    return this;
  }

  CurvedTransition easingWidth(EasingFunction e) {
    _ew = e;
    return this;
  }

  CurvedTransition easingHeight(EasingFunction e) {
    _eh = e;
    return this;
  }

  @override
  ReanimatedAnimation progressAnimation({required bool multiStep, AnimationCallback? onEnd}) {
    easing(Easing.linear); // each axis eases on its own
    return super.progressAnimation(multiStep: multiStep, onEnd: onEnd);
  }

  @override
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy) =>
      AnimatedStyle(
        translateX: dx * (1 - _ex(p)),
        translateY: dy * (1 - _ey(p)),
        scaleX: 1 + (sx - 1) * (1 - _ew(p)),
        scaleY: 1 + (sy - 1) * (1 - _eh(p)),
      );
}

/// Plays an exiting animation at the old place, then an entering one at
/// the new place. Defaults: [FadeOut], then [FadeIn]; the duration is the
/// sum of both.
class EntryExitTransition extends LayoutTransition {
  EntryAnimation _entering = FadeIn();
  ExitAnimation _exiting = FadeOut();

  EntryExitTransition entering(EntryAnimation animation) {
    _entering = animation;
    return this;
  }

  EntryExitTransition exiting(ExitAnimation animation) {
    _exiting = animation;
    return this;
  }

  LayoutValues _values = const LayoutValues(windowWidth: 0, windowHeight: 0);

  /// Called by `AnimatedView` with the window and view size before it runs.
  set values(LayoutValues v) => _values = v;

  @override
  Duration get defaultDuration =>
      _exiting.defaultDuration + _entering.defaultDuration;

  @override
  AnimatedStyle styleAt(double p, double dx, double dy, double sx, double sy) {
    final exitShare = _exiting.defaultDuration.inMicroseconds /
        defaultDuration.inMicroseconds;
    if (p < exitShare) {
      final frames = _exiting.resolveFrames(_values, AnimatedStyle.empty);
      return LayoutTransition._flip(1, dx, dy, sx, sy)
          .merge(evaluateFrames(frames, p / exitShare));
    }
    final frames = _entering.resolveFrames(_values, AnimatedStyle.empty);
    return evaluateFrames(frames, (p - exitShare) / (1 - exitShare));
  }
}
