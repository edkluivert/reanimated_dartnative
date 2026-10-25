import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// The Reanimated site's `Marquee`: [child] is measured, cloned enough
/// times to cover the width plus two, and every clone is shifted by one
/// offset that a frame callback advances by `childWidth / duration` per
/// millisecond, wrapping at one child width so the loop never shows a seam.
class Marquee extends StatefulWidget {
  const Marquee({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.reverse = false,
  });

  final Widget child;

  /// Time for the content to move by one copy of [child].
  final Duration duration;
  final bool reverse;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with ReanimatedStateMixin {
  double childrenWidth = 0;
  double childrenHeight = 0;

  late final offset = useSharedValue(0.0);
  late final coeff = useSharedValue(widget.reverse ? 1.0 : -1.0);

  @override
  void initState() {
    super.initState();
    useFrameCallback((i) {
      if (childrenWidth <= 0) return;
      final dtMs = (i.timeSincePreviousFrame?.inMicroseconds ?? 1000) / 1000;
      final ms = widget.duration.inMicroseconds / 1000;
      offset.value = (offset.value + coeff.value * dtMs * childrenWidth / ms) % childrenWidth;
    });
  }

  @override
  void didUpdateWidget(Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    coeff.value = widget.reverse ? 1.0 : -1.0;
  }

  @override
  Widget build(BuildContext context) {
    final parentWidth = MediaQuery.sizeOf(context).width;
    // First build: draw one copy invisibly, only to measure its width.
    if (childrenWidth == 0) {
      return Opacity(
        opacity: 0,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedView(
            onLayout: (size) => setState(() {
              childrenWidth = size.width;
              childrenHeight = size.height;
            }),
            child: widget.child,
          ),
        ]),
      );
    }
    final count = (parentWidth / childrenWidth).round() + 2;
    return SizedBox(
      height: childrenHeight,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (var index = 0; index < count; index++)
              Positioned(
                left: (index - 1) * childrenWidth,
                top: 0,
                child: _TranslatedElement(offset: offset, child: widget.child),
              ),
          ],
        ),
      ),
    );
  }
}

/// One clone, shifted by the shared offset.
class _TranslatedElement extends StatefulWidget {
  const _TranslatedElement({required this.offset, required this.child});
  final SharedValue<double> offset;
  final Widget child;

  @override
  State<_TranslatedElement> createState() => _TranslatedElementState();
}

class _TranslatedElementState extends State<_TranslatedElement> with ReanimatedStateMixin {
  late final animatedStyle = useAnimatedStyle(() => AnimatedStyle(translateX: widget.offset.value));

  @override
  Widget build(BuildContext context) => AnimatedView(style: animatedStyle, child: widget.child);
}
