import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// A card of the swipeable deck. The top card follows [translation] and
/// tilts with it; the card under it ([depth] 1) grows into place as the top
/// one moves away; deeper cards wait behind.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.translation,
    required this.depth,
    required this.width,
    required this.color,
    required this.title,
  });

  final SharedValue<Offset> translation;
  final int depth;
  final double width;
  final Color color;
  final String title;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with ReanimatedStateMixin {
  late final style = useAnimatedStyle(() {
    final t = widget.translation.value;
    switch (widget.depth) {
      case 0:
        return AnimatedStyle(
          translateX: t.dx,
          translateY: t.dy,
          rotate: interpolate(t.dx, [-widget.width, 0, widget.width], [deg(-15), 0, deg(15)]),
        );
      case 1:
        final pull = interpolate(t.dx.abs(), [0, widget.width / 2], [0, 1], Extrapolation.clamp);
        return AnimatedStyle(scale: 0.92 + 0.08 * pull, translateY: 18 * (1 - pull));
      default:
        return const AnimatedStyle(scale: 0.92, translateY: 18);
    }
  });

  late final likeStyle = useAnimatedStyle(() => AnimatedStyle(
        opacity: widget.depth == 0
            ? interpolate(widget.translation.value.dx, [0, widget.width / 4], [0, 1], Extrapolation.clamp)
            : 0,
      ));
  late final nopeStyle = useAnimatedStyle(() => AnimatedStyle(
        opacity: widget.depth == 0
            ? interpolate(widget.translation.value.dx, [-widget.width / 4, 0], [1, 0], Extrapolation.clamp)
            : 0,
      ));

  Widget _stamp(String text, Color color, AnimatedStyleHandle style, double angle) => AnimatedView(
        style: Styles([AnimatedStyle(rotate: angle), style]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: color)),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedView(
        style: Styles([
          AnimatedStyle(width: widget.width, height: widget.width * 1.3, backgroundColor: widget.color, borderRadius: 24),
          style,
        ]),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stamp('LIKE', const Color(0xFF1E9E6A), likeStyle, deg(-15)),
                  _stamp('NOPE', const Color(0xFFD9363E), nopeStyle, deg(15)),
                ],
              ),
              const Spacer(),
              Text(widget.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Palette.navy)),
              const SizedBox(height: 6),
              const Text('Swipe right to like, left to pass',
                  style: TextStyle(fontSize: 15, color: Palette.navy)),
            ],
          ),
        ),
      );
}
