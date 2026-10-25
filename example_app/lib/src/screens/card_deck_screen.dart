import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/swipe_card.dart';

/// A swipeable card deck: the top card follows your finger and tilts, a
/// stamp fades in as you commit, the next card grows into place, and a
/// fling sends the card off screen at the speed you threw it (otherwise it
/// springs back, keeping your velocity).
class CardDeckScreen extends StatefulWidget {
  const CardDeckScreen({super.key});

  @override
  State<CardDeckScreen> createState() => _CardDeckScreenState();
}

class _CardDeckScreenState extends State<CardDeckScreen> with ReanimatedStateMixin {
  static const cards = [
    ('Springs', Palette.purple),
    ('Decay', Palette.blue),
    ('Keyframes', Palette.pink),
    ('Layout', Palette.yellow),
    ('Sensors', Color(0xFF7FD1FA)),
  ];

  late final translation = useSharedValue(Offset.zero);
  List<int> order = List.generate(cards.length, (i) => i);
  String last = '';

  /// The deck's width, for capture mode's scripted swipes.
  double captureWidth = 320;

  void onPanEnd(DragEndDetails details, double width) {
    final v = details.velocity.pixelsPerSecond;
    final t = translation.value;
    final throwRight = t.dx > width / 3 || v.dx > 900;
    final throwLeft = t.dx < -width / 3 || v.dx < -900;
    if (!throwRight && !throwLeft) {
      translation.set(withSpring(Offset.zero, velocity: v, dampingRatio: 0.6, duration: const Duration(milliseconds: 500)));
      return;
    }
    final target = Offset((throwRight ? 1.6 : -1.6) * width, t.dy + v.dy * 0.15);
    translation.set(withTiming(
      target,
      duration: const Duration(milliseconds: 280),
      easing: Easing.out(Easing.quad),
      callback: (finished) {
        if (!finished || !mounted) return;
        setState(() {
          last = '${throwRight ? 'Liked' : 'Passed'} ${cards[order.first].$1}';
          order = [...order.skip(1), order.first];
        });
        translation.value = Offset.zero;
      },
    ));
  }

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    if (Capture.enabled) {
      Future<void>(() async {
        Future<void> swipe(Offset to, Offset velocity, double seconds) async {
          await Capture.drive(this, seconds, (t) => translation.value = to * (t / seconds));
          onPanEnd(DragEndDetails(velocity: Velocity(pixelsPerSecond: velocity)), captureWidth);
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }

        await Future<void>.delayed(const Duration(milliseconds: 800));
        await swipe(Offset(captureWidth * 0.45, 30), const Offset(1500, 120), 0.6);
        await swipe(Offset(-captureWidth * 0.5, -20), const Offset(-1600, 0), 0.6);
        await swipe(const Offset(70, 15), Offset.zero, 0.5);
        await swipe(Offset(captureWidth * 0.5, -40), const Offset(1400, -200), 0.5);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 64;
    captureWidth = width;
    return DemoPage(
      title: 'Card deck',
      docs: 'fundamentals/handling-gestures',
      child: Column(
        children: [
          const SizedBox(height: 16),
          // One detector over the deck: the top card moves by transform,
          // and its touch area stays where it was laid out.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => cancelAnimation(translation),
            onPanUpdate: (d) => translation.value = translation.value + d.delta,
            onPanEnd: (d) => onPanEnd(d, width),
            child: SizedBox(
              width: width,
              height: width * 1.3 + 30,
              child: Stack(
                children: [
                  SizedBox(width: width, height: width * 1.3 + 30),
                  // Back to front. A Stack matches children by index, so each
                  // index keeps its depth and only the card shown there changes.
                  for (var depth = order.length - 1; depth >= 0; depth--)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: SwipeCard(
                        translation: translation,
                        depth: depth,
                        width: width,
                        color: cards[order[depth]].$2,
                        title: cards[order[depth]].$1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(last, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
