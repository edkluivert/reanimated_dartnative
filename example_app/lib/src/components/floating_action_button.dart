import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// Distance between the expanded buttons.
const double fabOffset = 60;

/// One of the buttons a [ExpandingFab] fans out, as the site's
/// `FloatingActionButton`: it springs up `fabOffset × index` (duration 1200,
/// dampingRatio 0.8, overshoot clamped) and scales in after index × 100 ms.
class FabItem extends StatefulWidget {
  const FabItem({
    super.key,
    required this.isExpanded,
    required this.index,
    required this.label,
    required this.color,
  });

  final SharedValue<bool> isExpanded;
  final int index;
  final String label;
  final Color color;

  @override
  State<FabItem> createState() => _FabItemState();
}

class _FabItemState extends State<FabItem> with ReanimatedStateMixin {
  late final translateY = useDerivedAnimation(
    0.0,
    () => withSpring(
      -(widget.isExpanded.value ? fabOffset * widget.index : 0),
      duration: const Duration(milliseconds: 1200),
      overshootClamping: true,
      dampingRatio: 0.8,
    ),
  );
  late final scale = useDerivedAnimation(
    0.0,
    () => withDelay(
      Duration(milliseconds: widget.index * 100),
      withTiming(widget.isExpanded.value ? 1.0 : 0.0),
    ),
  );
  late final animatedStyles = useAnimatedStyle(() => AnimatedStyle(
        translateY: translateY.value,
        scale: scale.value,
      ));

  @override
  Widget build(BuildContext context) => AnimatedView(
          style: Styles([
            AnimatedStyle(width: 40, height: 40, borderRadius: 20, backgroundColor: widget.color),
            animatedStyles,
          ]),
          child: Center(
            child: Text(widget.label,
                style: const TextStyle(color: Color(0xFFF8F9FF), fontWeight: FontWeight.w600)),
          ),
      );
}

/// The site's whole floating action button: a "+" that turns 45° into an ×,
/// with [items] fanning out above it.
class ExpandingFab extends StatefulWidget {
  const ExpandingFab({super.key, required this.items, this.onSelected});

  final List<(String label, Color color)> items;
  final void Function(String label)? onSelected;

  @override
  State<ExpandingFab> createState() => _ExpandingFabState();
}

class _ExpandingFabState extends State<ExpandingFab> with ReanimatedStateMixin {
  late final isExpanded = useSharedValue(false);

  late final plusTranslate = useDerivedAnimation(
    0.0,
    () => withTiming(interpolate(isExpanded.value ? 1 : 0, [0, 1], [0, 2])),
  );
  late final plusRotate = useDerivedAnimation(
    0.0,
    () => withTiming(isExpanded.value ? deg(45) : 0.0),
  );
  late final plusIconStyle = useAnimatedStyle(() => AnimatedStyle(
        translateX: plusTranslate.value,
        rotate: plusRotate.value,
      ));

  void handlePress() => isExpanded.value = !isExpanded.value;

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (900, handlePress),
      (1800, handlePress),
      (1000, handlePress),
      (1600, () {
        widget.onSelected?.call(widget.items[1].$1);
        isExpanded.value = false;
      }),
    ]);
  }

  double get _height => 60 + fabOffset * widget.items.length;

  /// The items move by transform, which leaves their touch areas behind, so
  /// taps are caught over the whole FAB and matched to a button here.
  void _onTapUp(TapUpDetails details) {
    final fromBottom = _height - details.localPosition.dy;
    if (fromBottom <= 60) return handlePress();
    if (!isExpanded.value) return;
    for (var i = 0; i < widget.items.length; i++) {
      final center = 30 + fabOffset * (i + 1);
      if ((fromBottom - center).abs() <= 22) {
        widget.onSelected?.call(widget.items[i].$1);
        isExpanded.value = false;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        child: SizedBox(
        width: 60,
        height: _height,
        child: Stack(
          children: [
            for (var i = 0; i < widget.items.length; i++)
              Positioned(
                bottom: 10,
                left: 10,
                child: FabItem(
                  isExpanded: isExpanded,
                  index: i + 1,
                  label: widget.items[i].$1,
                  color: widget.items[i].$2,
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: Palette.navy, borderRadius: BorderRadius.circular(30)),
                alignment: Alignment.center,
                child: AnimatedView(
                  style: plusIconStyle,
                  child: const Text('+', style: TextStyle(fontSize: 34, color: Color(0xFFF8F9FF))),
                ),
              ),
            ),
          ],
        ),
      ),
      );
}
