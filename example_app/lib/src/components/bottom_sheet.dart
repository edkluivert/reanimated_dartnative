import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// The Reanimated site's `AnimatedBottomSheet`: progress runs from 1 (closed) to 0
/// (open) with withTiming; the sheet slides by progress × 2 × its measured
/// height and the backdrop fades with 1 − progress. The sheet can also be
/// dragged down and flung closed.
class AnimatedBottomSheet extends StatefulWidget {
  const AnimatedBottomSheet({
    super.key,
    required this.isOpen,
    required this.toggleSheet,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  final SharedValue<bool> isOpen;
  final VoidCallback toggleSheet;
  final Widget child;
  final Duration duration;

  @override
  State<AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<AnimatedBottomSheet> with ReanimatedStateMixin {
  late final height = useSharedValue(0.0);
  late final progress = useDerivedAnimation(
    1.0,
    () => withTiming(widget.isOpen.value ? 0.0 : 1.0, duration: widget.duration),
  );

  /// Extra offset while the user drags the sheet down.
  late final drag = useSharedValue(0.0);

  late final sheetStyle = useAnimatedStyle(() => AnimatedStyle(
        translateY: progress.value * 2 * height.value + drag.value,
      ));
  late final backdropStyle = useAnimatedStyle(() => AnimatedStyle(
        opacity: (1 - progress.value) * (1 - (drag.value / (height.value + 1)).clamp(0.0, 1.0)),
      ));

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            // While closed the backdrop lets touches through, as the
            // site's zIndex switch does.
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.isOpen,
              builder: (context, open, _) => IgnorePointer(
                ignoring: !open,
                child: GestureDetector(
                  onTap: widget.toggleSheet,
                  child: AnimatedView(
                    // Sized explicitly: a view with no size of its own collapses.
                    style: Styles([
                      AnimatedStyle(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height,
                        backgroundColor: const Color(0x4D000000),
                      ),
                      backdropStyle,
                    ]),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (d) => drag.value = (drag.value + d.delta.dy).clamp(0.0, double.infinity),
              onVerticalDragEnd: (d) {
                final v = d.velocity.pixelsPerSecond.dy;
                if (drag.value > height.value / 3 || v > 800) {
                  widget.toggleSheet();
                  drag.set(withTiming(0, duration: widget.duration));
                } else {
                  drag.set(withSpring(0, velocity: v));
                }
              },
              child: AnimatedView(
                onLayout: (size) => height.value = size.height,
                style: Styles([
                  const AnimatedStyle(backgroundColor: Color(0xFFF8F9FF), borderRadius: 24),
                  sheetStyle,
                ]),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: const Color(0xFFC9CCD8), borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
