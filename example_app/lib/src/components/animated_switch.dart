import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// The Reanimated site's `Switch`: the track's color is interpolateColor'd
/// between the off and on colors and the thumb slides across, both with
/// withTiming (400 ms). Track size is measured, so any width and height work.
class AnimatedSwitch extends StatefulWidget {
  const AnimatedSwitch({
    super.key,
    required this.value,
    required this.onPress,
    this.width = 64,
    this.height = 36,
    this.duration = const Duration(milliseconds: 400),
    this.trackColors = (on: const Color(0xFF82CAB2), off: const Color(0xFFFA7F7C)),
  });

  final SharedValue<bool> value;
  final VoidCallback onPress;
  final double width;
  final double height;
  final Duration duration;
  final ({Color on, Color off}) trackColors;

  @override
  State<AnimatedSwitch> createState() => _AnimatedSwitchState();
}

class _AnimatedSwitchState extends State<AnimatedSwitch> with ReanimatedStateMixin {
  late final height = useSharedValue(widget.height);
  late final width = useSharedValue(widget.width);

  late final trackColor = useDerivedAnimation(
    widget.value.value ? widget.trackColors.on : widget.trackColors.off,
    () => withTiming(
      interpolateColor(widget.value.value ? 1 : 0, [0, 1], [widget.trackColors.off, widget.trackColors.on]),
      duration: widget.duration,
    ),
  );
  late final thumbX = useDerivedAnimation(
    0.0,
    () => withTiming(
      interpolate(widget.value.value ? 1 : 0, [0, 1], [0, width.value - height.value]),
      duration: widget.duration,
    ),
  );

  late final trackAnimatedStyle = useAnimatedStyle(() => AnimatedStyle(
        backgroundColor: trackColor.value,
        borderRadius: height.value / 2,
      ));
  late final thumbAnimatedStyle = useAnimatedStyle(() => AnimatedStyle(
        translateX: thumbX.value,
        borderRadius: height.value / 2,
      ));

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onPress,
        child: AnimatedView(
          onLayout: (size) {
            height.value = size.height;
            width.value = size.width;
          },
          style: Styles([
            AnimatedStyle(width: widget.width, height: widget.height),
            trackAnimatedStyle,
          ]),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(widget.height * 0.08),
              child: AnimatedView(
                style: Styles([
                  AnimatedStyle(
                    width: widget.height * 0.84,
                    height: widget.height * 0.84,
                    backgroundColor: const Color(0xFFFFFFFF),
                  ),
                  thumbAnimatedStyle,
                ]),
              ),
            ),
          ),
        ),
      );
}
