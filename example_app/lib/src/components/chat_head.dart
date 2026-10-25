import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

/// One bubble of the chat heads, drawn wherever [position] says.
class ChatHead extends StatefulWidget {
  const ChatHead({
    super.key,
    required this.position,
    required this.color,
    required this.label,
    this.size = 64,
  });

  final SharedValue<Offset> position;
  final Color color;
  final String label;
  final double size;

  @override
  State<ChatHead> createState() => _ChatHeadState();
}

class _ChatHeadState extends State<ChatHead> with ReanimatedStateMixin {
  late final style = useAnimatedStyle(() => AnimatedStyle(
        translateX: widget.position.value.dx,
        translateY: widget.position.value.dy,
      ));

  @override
  Widget build(BuildContext context) => AnimatedView(
        style: Styles([
          AnimatedStyle(
            width: widget.size,
            height: widget.size,
            borderRadius: widget.size / 2,
            backgroundColor: widget.color,
          ),
          style,
        ]),
        child: Center(
          child: Text(widget.label, style: TextStyle(fontSize: widget.size * 0.42)),
        ),
      );
}
