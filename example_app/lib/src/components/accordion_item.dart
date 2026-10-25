import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// The Reanimated site's `AccordionItem`: the body's natural height is
/// measured, and the visible height animates between 0 and it with
/// withTiming whenever [isExpanded] changes. No React-style re-render: only
/// the shared values change.
class AccordionItem extends StatefulWidget {
  const AccordionItem({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  final SharedValue<bool> isExpanded;
  final Widget child;
  final Duration duration;

  @override
  State<AccordionItem> createState() => _AccordionItemState();
}

class _AccordionItemState extends State<AccordionItem> with ReanimatedStateMixin {
  late final height = useSharedValue(0.0);

  // The Reanimated original is:
  //   useDerivedValue(() => withTiming(height.value * Number(isExpanded.value), { duration }))
  // The visible height animates to the measured height when expanded, or to 0.
  late final derivedHeight = useDerivedAnimation(
    0.0,
    () => withTiming(
      height.value * (widget.isExpanded.value ? 1 : 0),
      duration: widget.duration,
    ),
  );

  late final bodyStyle = useAnimatedStyle(() => AnimatedStyle(height: derivedHeight.value));

  @override
  Widget build(BuildContext context) => AnimatedView(
        style: bodyStyle,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Laid out at its natural height whatever the visible height.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedView(
                  onLayout: (size) => height.value = size.height,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      );
}
