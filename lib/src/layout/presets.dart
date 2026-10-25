// Reanimated's predefined entering and exiting animations.
//
// Each entering preset gives the style a view starts from; it animates to
// the view's own style. Each exiting preset gives the style a view leaves
// towards. Transforms pivot on the view's center.

import 'dart:math' as math;

import '../core/animated_style.dart';
import 'layout_animation.dart';

typedef _Frames = List<LayoutFrame> Function(LayoutValues v);

const _rest = AnimatedStyle.empty;

List<LayoutFrame> _in(AnimatedStyle from) =>
    [LayoutFrame(0, from), const LayoutFrame(1, _rest)];
List<LayoutFrame> _out(AnimatedStyle to) =>
    [const LayoutFrame(0, _rest), LayoutFrame(1, to)];

/// An entering preset defined by its frames.
class _Entering extends EntryAnimation {
  _Entering(this._frames, [this._duration = const Duration(milliseconds: 300)]);
  final _Frames _frames;
  final Duration _duration;
  @override
  Duration get defaultDuration => _duration;
  @override
  List<LayoutFrame> buildFrames(LayoutValues values) => _frames(values);
}

class _Exiting extends ExitAnimation {
  _Exiting(this._frames, [this._duration = const Duration(milliseconds: 300)]);
  final _Frames _frames;
  final Duration _duration;
  @override
  Duration get defaultDuration => _duration;
  @override
  List<LayoutFrame> buildFrames(LayoutValues values) => _frames(values);
}

const _bounce = Duration(milliseconds: 600);
const _deg90 = math.pi / 2;

// Fade

class FadeIn extends _Entering {
  FadeIn() : super((_) => _in(const AnimatedStyle(opacity: 0)));
}

class FadeInRight extends _Entering {
  FadeInRight() : super((_) => _in(const AnimatedStyle(opacity: 0, translateX: 25)));
}

class FadeInLeft extends _Entering {
  FadeInLeft() : super((_) => _in(const AnimatedStyle(opacity: 0, translateX: -25)));
}

class FadeInUp extends _Entering {
  FadeInUp() : super((_) => _in(const AnimatedStyle(opacity: 0, translateY: 25)));
}

class FadeInDown extends _Entering {
  FadeInDown() : super((_) => _in(const AnimatedStyle(opacity: 0, translateY: -25)));
}

class FadeOut extends _Exiting {
  FadeOut() : super((_) => _out(const AnimatedStyle(opacity: 0)));
}

class FadeOutRight extends _Exiting {
  FadeOutRight() : super((_) => _out(const AnimatedStyle(opacity: 0, translateX: 25)));
}

class FadeOutLeft extends _Exiting {
  FadeOutLeft() : super((_) => _out(const AnimatedStyle(opacity: 0, translateX: -25)));
}

class FadeOutUp extends _Exiting {
  FadeOutUp() : super((_) => _out(const AnimatedStyle(opacity: 0, translateY: -25)));
}

class FadeOutDown extends _Exiting {
  FadeOutDown() : super((_) => _out(const AnimatedStyle(opacity: 0, translateY: 25)));
}

// Slide

class SlideInRight extends _Entering {
  SlideInRight() : super((v) => _in(AnimatedStyle(translateX: v.windowWidth)));
}

class SlideInLeft extends _Entering {
  SlideInLeft() : super((v) => _in(AnimatedStyle(translateX: -v.windowWidth)));
}

class SlideInUp extends _Entering {
  SlideInUp() : super((v) => _in(AnimatedStyle(translateY: v.windowHeight)));
}

class SlideInDown extends _Entering {
  SlideInDown() : super((v) => _in(AnimatedStyle(translateY: -v.windowHeight)));
}

class SlideOutRight extends _Exiting {
  SlideOutRight() : super((v) => _out(AnimatedStyle(translateX: v.windowWidth)));
}

class SlideOutLeft extends _Exiting {
  SlideOutLeft() : super((v) => _out(AnimatedStyle(translateX: -v.windowWidth)));
}

class SlideOutUp extends _Exiting {
  SlideOutUp() : super((v) => _out(AnimatedStyle(translateY: -v.windowHeight)));
}

class SlideOutDown extends _Exiting {
  SlideOutDown() : super((v) => _out(AnimatedStyle(translateY: v.windowHeight)));
}

// Zoom

class ZoomIn extends _Entering {
  ZoomIn() : super((_) => _in(const AnimatedStyle(scale: 0)));
}

class ZoomInRotate extends _Entering {
  ZoomInRotate() : super((_) => _in(const AnimatedStyle(scale: 0, rotate: 0.3)));
}

class ZoomInLeft extends _Entering {
  ZoomInLeft() : super((v) => _in(AnimatedStyle(translateX: -v.windowWidth, scale: 0)));
}

class ZoomInRight extends _Entering {
  ZoomInRight() : super((v) => _in(AnimatedStyle(translateX: v.windowWidth, scale: 0)));
}

class ZoomInUp extends _Entering {
  ZoomInUp() : super((v) => _in(AnimatedStyle(translateY: -v.windowHeight, scale: 0)));
}

class ZoomInDown extends _Entering {
  ZoomInDown() : super((v) => _in(AnimatedStyle(translateY: v.windowHeight, scale: 0)));
}

class ZoomInEasyUp extends _Entering {
  ZoomInEasyUp() : super((v) => _in(AnimatedStyle(translateY: -v.height, scale: 0)));
}

class ZoomInEasyDown extends _Entering {
  ZoomInEasyDown() : super((v) => _in(AnimatedStyle(translateY: v.height, scale: 0)));
}

class ZoomOut extends _Exiting {
  ZoomOut() : super((_) => _out(const AnimatedStyle(scale: 0)));
}

class ZoomOutRotate extends _Exiting {
  ZoomOutRotate() : super((_) => _out(const AnimatedStyle(scale: 0, rotate: 0.3)));
}

class ZoomOutLeft extends _Exiting {
  ZoomOutLeft() : super((v) => _out(AnimatedStyle(translateX: -v.windowWidth, scale: 0)));
}

class ZoomOutRight extends _Exiting {
  ZoomOutRight() : super((v) => _out(AnimatedStyle(translateX: v.windowWidth, scale: 0)));
}

class ZoomOutUp extends _Exiting {
  ZoomOutUp() : super((v) => _out(AnimatedStyle(translateY: -v.windowHeight, scale: 0)));
}

class ZoomOutDown extends _Exiting {
  ZoomOutDown() : super((v) => _out(AnimatedStyle(translateY: v.windowHeight, scale: 0)));
}

class ZoomOutEasyUp extends _Exiting {
  ZoomOutEasyUp() : super((v) => _out(AnimatedStyle(translateY: -v.height, scale: 0)));
}

class ZoomOutEasyDown extends _Exiting {
  ZoomOutEasyDown() : super((v) => _out(AnimatedStyle(translateY: v.height, scale: 0)));
}

// Bounce (keyframed, 600 ms)

List<LayoutFrame> _bounceIn(AnimatedStyle Function(double k) at) => [
      LayoutFrame(0, at(0)),
      LayoutFrame(0.55, at(1)),
      LayoutFrame(0.7, at(2)),
      LayoutFrame(0.85, at(3)),
      const LayoutFrame(1, _rest),
    ];

List<LayoutFrame> _bounceOut(AnimatedStyle Function(double k) at) => [
      const LayoutFrame(0, _rest),
      LayoutFrame(0.15, at(1)),
      LayoutFrame(0.3, at(2)),
      LayoutFrame(0.45, at(3)),
      LayoutFrame(1, at(4)),
    ];

class BounceIn extends _Entering {
  BounceIn()
      : super((_) => _bounceIn((k) => AnimatedStyle(scale: const [0.0, 1.2, 0.9, 1.1][k.toInt()])), _bounce);
}

class BounceInDown extends _Entering {
  BounceInDown()
      : super((v) => _bounceIn((k) => AnimatedStyle(translateY: [-v.windowHeight, 20.0, -10.0, 10.0][k.toInt()])), _bounce);
}

class BounceInUp extends _Entering {
  BounceInUp()
      : super((v) => _bounceIn((k) => AnimatedStyle(translateY: [v.windowHeight, -20.0, 10.0, -10.0][k.toInt()])), _bounce);
}

class BounceInLeft extends _Entering {
  BounceInLeft()
      : super((v) => _bounceIn((k) => AnimatedStyle(translateX: [-v.windowWidth, 20.0, -10.0, 10.0][k.toInt()])), _bounce);
}

class BounceInRight extends _Entering {
  BounceInRight()
      : super((v) => _bounceIn((k) => AnimatedStyle(translateX: [v.windowWidth, -20.0, 10.0, -10.0][k.toInt()])), _bounce);
}

class BounceOut extends _Exiting {
  BounceOut()
      : super((_) => _bounceOut((k) => AnimatedStyle(scale: const [1.0, 1.1, 0.9, 1.2, 0.0][k.toInt()])), _bounce);
}

class BounceOutDown extends _Exiting {
  BounceOutDown()
      : super((v) => _bounceOut((k) => AnimatedStyle(translateY: [0.0, -10.0, 10.0, -20.0, v.windowHeight][k.toInt()])), _bounce);
}

class BounceOutUp extends _Exiting {
  BounceOutUp()
      : super((v) => _bounceOut((k) => AnimatedStyle(translateY: [0.0, 10.0, -10.0, 20.0, -v.windowHeight][k.toInt()])), _bounce);
}

class BounceOutLeft extends _Exiting {
  BounceOutLeft()
      : super((v) => _bounceOut((k) => AnimatedStyle(translateX: [0.0, 10.0, -10.0, 20.0, -v.windowWidth][k.toInt()])), _bounce);
}

class BounceOutRight extends _Exiting {
  BounceOutRight()
      : super((v) => _bounceOut((k) => AnimatedStyle(translateX: [0.0, -10.0, 10.0, -20.0, v.windowWidth][k.toInt()])), _bounce);
}

// Flip

class FlipInXUp extends _Entering {
  FlipInXUp() : super((v) => _in(AnimatedStyle(rotateX: _deg90, translateY: -v.height, perspective: 500)));
}

class FlipInXDown extends _Entering {
  FlipInXDown() : super((v) => _in(AnimatedStyle(rotateX: -_deg90, translateY: v.height, perspective: 500)));
}

class FlipInYLeft extends _Entering {
  FlipInYLeft() : super((v) => _in(AnimatedStyle(rotateY: -_deg90, translateX: -v.width, perspective: 500)));
}

class FlipInYRight extends _Entering {
  FlipInYRight() : super((v) => _in(AnimatedStyle(rotateY: _deg90, translateX: v.width, perspective: 500)));
}

class FlipInEasyX extends _Entering {
  FlipInEasyX() : super((_) => _in(const AnimatedStyle(rotateX: _deg90, perspective: 500)));
}

class FlipInEasyY extends _Entering {
  FlipInEasyY() : super((_) => _in(const AnimatedStyle(rotateY: _deg90, perspective: 500)));
}

class FlipOutXUp extends _Exiting {
  FlipOutXUp() : super((v) => _out(AnimatedStyle(rotateX: _deg90, translateY: -v.height, perspective: 500)));
}

class FlipOutXDown extends _Exiting {
  FlipOutXDown() : super((v) => _out(AnimatedStyle(rotateX: -_deg90, translateY: v.height, perspective: 500)));
}

class FlipOutYLeft extends _Exiting {
  FlipOutYLeft() : super((v) => _out(AnimatedStyle(rotateY: -_deg90, translateX: -v.width, perspective: 500)));
}

class FlipOutYRight extends _Exiting {
  FlipOutYRight() : super((v) => _out(AnimatedStyle(rotateY: _deg90, translateX: v.width, perspective: 500)));
}

class FlipOutEasyX extends _Exiting {
  FlipOutEasyX() : super((_) => _out(const AnimatedStyle(rotateX: _deg90, perspective: 500)));
}

class FlipOutEasyY extends _Exiting {
  FlipOutEasyY() : super((_) => _out(const AnimatedStyle(rotateY: _deg90, perspective: 500)));
}

// LightSpeed (skew is not supported by DartNative transforms; the slide and
// fade carry the effect)

class LightSpeedInRight extends _Entering {
  LightSpeedInRight() : super((v) => _in(AnimatedStyle(translateX: v.windowWidth, opacity: 0)));
}

class LightSpeedInLeft extends _Entering {
  LightSpeedInLeft() : super((v) => _in(AnimatedStyle(translateX: -v.windowWidth, opacity: 0)));
}

class LightSpeedOutRight extends _Exiting {
  LightSpeedOutRight() : super((v) => _out(AnimatedStyle(translateX: v.windowWidth, opacity: 0)));
}

class LightSpeedOutLeft extends _Exiting {
  LightSpeedOutLeft() : super((v) => _out(AnimatedStyle(translateX: -v.windowWidth, opacity: 0)));
}

// Pinwheel

class PinwheelIn extends _Entering {
  PinwheelIn() : super((_) => _in(const AnimatedStyle(opacity: 0, scale: 0, rotate: 5)));
}

class PinwheelOut extends _Exiting {
  PinwheelOut() : super((_) => _out(const AnimatedStyle(opacity: 0, scale: 0, rotate: 5)));
}

// Roll

class RollInLeft extends _Entering {
  RollInLeft() : super((v) => _in(AnimatedStyle(translateX: -v.windowWidth, rotate: -math.pi)));
}

class RollInRight extends _Entering {
  RollInRight() : super((v) => _in(AnimatedStyle(translateX: v.windowWidth, rotate: math.pi)));
}

class RollOutLeft extends _Exiting {
  RollOutLeft() : super((v) => _out(AnimatedStyle(translateX: -v.windowWidth, rotate: -math.pi)));
}

class RollOutRight extends _Exiting {
  RollOutRight() : super((v) => _out(AnimatedStyle(translateX: v.windowWidth, rotate: math.pi)));
}

// Rotate: a quarter turn about a corner, expressed as a turn about the
// center plus the offset that puts the corner back in place.

AnimatedStyle _corner(LayoutValues v, double angle, double sx, double sy) {
  final dx = (v.width - v.height) / 2;
  return AnimatedStyle(opacity: 0, rotate: angle, translateX: sx * dx, translateY: sy * dx);
}

class RotateInDownLeft extends _Entering {
  RotateInDownLeft() : super((v) => _in(_corner(v, -_deg90, 1, -1)));
}

class RotateInDownRight extends _Entering {
  RotateInDownRight() : super((v) => _in(_corner(v, _deg90, -1, -1)));
}

class RotateInUpLeft extends _Entering {
  RotateInUpLeft() : super((v) => _in(_corner(v, _deg90, 1, 1)));
}

class RotateInUpRight extends _Entering {
  RotateInUpRight() : super((v) => _in(_corner(v, -_deg90, -1, 1)));
}

class RotateOutDownLeft extends _Exiting {
  RotateOutDownLeft() : super((v) => _out(_corner(v, _deg90, 1, 1)));
}

class RotateOutDownRight extends _Exiting {
  RotateOutDownRight() : super((v) => _out(_corner(v, -_deg90, -1, 1)));
}

class RotateOutUpLeft extends _Exiting {
  RotateOutUpLeft() : super((v) => _out(_corner(v, -_deg90, 1, -1)));
}

class RotateOutUpRight extends _Exiting {
  RotateOutUpRight() : super((v) => _out(_corner(v, _deg90, -1, -1)));
}

// Stretch

class StretchInX extends _Entering {
  StretchInX() : super((_) => _in(const AnimatedStyle(scaleX: 0)));
}

class StretchInY extends _Entering {
  StretchInY() : super((_) => _in(const AnimatedStyle(scaleY: 0)));
}

class StretchOutX extends _Exiting {
  StretchOutX() : super((_) => _out(const AnimatedStyle(scaleX: 0)));
}

class StretchOutY extends _Exiting {
  StretchOutY() : super((_) => _out(const AnimatedStyle(scaleY: 0)));
}
