import 'reactive.dart';

/// Props computed from shared values, as Reanimated's `useAnimatedProps`.
///
/// Where `useAnimatedStyle` covers a view's style, animated props cover
/// anything else a widget takes: a painter's radius, a progress value, a
/// text. [P] is whatever type holds them, often a record. Read them with
/// `AnimatedPropsBuilder` (or any `ValueListenableBuilder`).
class AnimatedProps<P> extends DerivedValue<P> {
  AnimatedProps(super.updater);
}

/// Creates [AnimatedProps], as Reanimated's `useAnimatedProps`.
///
/// ```dart
/// final animatedProps = useAnimatedProps(() => (radius: r.value));
///
/// AnimatedPropsBuilder(
///   props: animatedProps,
///   builder: (context, props) =>
///       CustomPaint(painter: CirclePainter(props.radius)),
/// )
/// ```
AnimatedProps<P> useAnimatedProps<P>(P Function() updater) =>
    AnimatedProps<P>(updater);
