import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/chat_head.dart';

/// Chat heads: drag the front bubble and the others trail behind it, each
/// springing toward the one ahead. Let go and it flies to the nearest edge,
/// keeping the velocity of your fling; the chain follows.
///
/// Each follower is `useDerivedAnimation(() => withSpring(ahead.value))`:
/// the spring restarts whenever the bubble ahead moves and inherits its own
/// running velocity, which is what makes the trail smooth.
class ChatHeadsScreen extends StatefulWidget {
  const ChatHeadsScreen({super.key});

  @override
  State<ChatHeadsScreen> createState() => _ChatHeadsScreenState();
}

class _ChatHeadsScreenState extends State<ChatHeadsScreen> with ReanimatedStateMixin {
  static const size = 64.0;
  static const heads = [('🦊', Palette.pink), ('🐼', Palette.blue), ('🐸', Palette.yellow), ('🐙', Palette.purple)];

  late final lead = useSharedValue(const Offset(16, 120));
  late final List<SharedValue<Offset>> chain = _buildChain();

  List<SharedValue<Offset>> _buildChain() {
    final out = <SharedValue<Offset>>[lead];
    for (var i = 1; i < heads.length; i++) {
      final ahead = out[i - 1];
      out.add(useDerivedAnimation(
        ahead.value,
        () => withSpring(ahead.value, dampingRatio: 0.65, duration: const Duration(milliseconds: 300)),
      ));
    }
    return out;
  }

  void onPanEnd(DragEndDetails details, Size area) {
    final v = details.velocity.pixelsPerSecond;
    final p = lead.value;
    // Project where the fling is heading, then snap to that side.
    final projectedX = p.dx + v.dx * 0.2;
    final x = projectedX + size / 2 < area.width / 2 ? 16.0 : area.width - size - 16;
    final y = clamp(p.dy + v.dy * 0.2, 16, area.height - size - 16);
    lead.set(withSpring(Offset(x, y), velocity: v, dampingRatio: 0.7, duration: const Duration(milliseconds: 600)));
  }

  /// The latest layout size, for capture mode's scripted flings.
  Size captureArea = const Size(390, 700);

  /// Whether the current drag started on the front bubble.
  bool dragging = false;

  void onPanStart(DragStartDetails details) {
    final center = lead.value + const Offset(size / 2, size / 2);
    final d = details.localPosition - center;
    // Not Offset.distance: in DartNative 1.4.0 it returns the squared length.
    dragging = math.sqrt(d.dx * d.dx + d.dy * d.dy) <= size * 0.75;
    if (dragging) cancelAnimation(lead);
  }

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    if (Capture.enabled) {
      Future<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await Capture.drive(this, 1.2, (t) => lead.value = Offset(16 + 200 * t, 120 + 160 * math.sin(t * 2.6)));
        onPanEnd(const DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(900, 700))), captureArea);
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final from = lead.value;
        await Capture.drive(this, 1.3, (t) => lead.value = from + Offset(-220 * t, -150 * t + 60 * math.sin(t * 5)));
        onPanEnd(const DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(-1100, -400))), captureArea);
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        final again = lead.value;
        await Capture.drive(this, 1.0, (t) => lead.value = again + Offset(180 * t, 260 * t));
        onPanEnd(const DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(400, 900))), captureArea);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chat heads')),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            captureArea = area;
            // One detector over the whole area: the bubbles move by
            // transform, and a transformed view's touch area stays where it
            // was laid out, so the drag is caught here and started only when
            // it lands on the front bubble.
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: onPanStart,
              onPanUpdate: (d) {
                if (dragging) lead.value = lead.value + d.delta;
              },
              onPanEnd: (d) {
                if (dragging) onPanEnd(d, area);
                dragging = false;
              },
              child: Stack(
                children: [
                  SizedBox(width: area.width, height: area.height),
                  const Positioned(
                    left: 24,
                    right: 24,
                    bottom: 40,
                    child: Text(
                      'Drag the front bubble and fling it toward either side.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A8FA3)),
                    ),
                  ),
                  // Followers first, so the lead is drawn on top.
                  for (var i = heads.length - 1; i >= 0; i--)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: ChatHead(position: chain[i], color: heads[i].$2, label: heads[i].$1, size: size),
                    ),
                ],
              ),
            );
          },
        ),
      );
}
