import 'package:dartnative/dartnative.dart' show ScrollController, State, StatefulWidget;

import '../core/animated_props.dart';
import '../core/animated_style.dart';
import '../core/frame_callback.dart';
import '../core/reactive.dart';
import '../core/shared_value.dart';
import '../device/animated_sensor.dart';
import '../device/sensor_types.dart';
import '../scroll/scroll.dart';

/// Gives a [State] Reanimated's hooks, and disposes what they create when
/// the state is disposed.
///
/// Inside the state these methods take the place of the top-level
/// functions of the same name. Call them in field initialisers (`late
/// final`) or `initState`, never in `build`.
///
/// ```dart
/// class _BoxState extends State<Box> with ReanimatedStateMixin {
///   late final offset = useSharedValue(0.0);
///   late final animatedStyles = useAnimatedStyle(
///       () => AnimatedStyle(translateX: offset.value));
///
///   @override
///   Widget build(BuildContext context) =>
///       AnimatedView(style: animatedStyles, child: ...);
/// }
/// ```
mixin ReanimatedStateMixin<T extends StatefulWidget> on State<T> {
  final List<void Function()> _disposers = [];

  R _own<R>(R value, void Function() dispose) {
    _disposers.add(dispose);
    return value;
  }

  SharedValue<V> useSharedValue<V>(V initialValue) {
    final v = SharedValue<V>(initialValue);
    return _own(v, v.dispose);
  }

  DerivedValue<V> useDerivedValue<V>(V Function() updater) {
    final v = DerivedValue<V>(updater);
    return _own(v, v.dispose);
  }

  DerivedAnimation<V> useDerivedAnimation<V>(V initialValue, Object? Function() updater) {
    final v = DerivedAnimation<V>(initialValue, updater);
    return _own(v, v.dispose);
  }

  AnimatedStyleHandle useAnimatedStyle(AnimatedStyle Function() updater) {
    final v = AnimatedStyleHandle(updater);
    return _own(v, v.dispose);
  }

  AnimatedProps<P> useAnimatedProps<P>(P Function() updater) {
    final v = AnimatedProps<P>(updater);
    return _own(v, v.dispose);
  }

  AnimatedReaction<V> useAnimatedReaction<V>(
    V Function() prepare,
    void Function(V current, V? previous) react,
  ) {
    final v = AnimatedReaction<V>(prepare, react);
    return _own(v, v.dispose);
  }

  AnimatedSensor<V> useAnimatedSensor<V>(
    SensorType<V> type, [
    SensorConfig config = const SensorConfig(),
  ]) {
    final v = AnimatedSensor<V>(type, config: config);
    return _own(v, v.dispose);
  }

  FrameCallback useFrameCallback(
    void Function(FrameInfo frameInfo) callback, {
    bool autostart = true,
  }) {
    final v = FrameCallback(callback, autostart: autostart);
    return _own(v, v.dispose);
  }

  TimestampValue useTimestamp({bool isActive = true}) {
    final v = TimestampValue(isActive: isActive);
    return _own(v, v.dispose);
  }

  ScrollOffset useScrollOffset(ScrollController controller) {
    final v = ScrollOffset(controller);
    return _own(v, v.dispose);
  }

  AnimatedScrollHandler useAnimatedScrollHandler(
    ScrollController controller, {
    void Function(ScrollEvent event, Map<String, Object?> context)? onScroll,
    void Function(ScrollEvent event, Map<String, Object?> context)? onBeginDrag,
    void Function(ScrollEvent event, Map<String, Object?> context)? onEndDrag,
    void Function(ScrollEvent event, Map<String, Object?> context)? onMomentumBegin,
    void Function(ScrollEvent event, Map<String, Object?> context)? onMomentumEnd,
  }) {
    final v = AnimatedScrollHandler(
      controller,
      onScroll: onScroll,
      onBeginDrag: onBeginDrag,
      onEndDrag: onEndDrag,
      onMomentumBegin: onMomentumBegin,
      onMomentumEnd: onMomentumEnd,
    );
    return _own(v, v.dispose);
  }

  @override
  void dispose() {
    for (final d in _disposers.reversed) {
      d();
    }
    _disposers.clear();
    super.dispose();
  }
}
