import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/credit_card_faces.dart';
import '../components/flip_card.dart';
import '../components/spinnable_card.dart';

/// examples/flipCard: the site's toggle-driven flip card, and a card you
/// spin with your finger in 3D.
class FlipCardScreen extends StatefulWidget {
  const FlipCardScreen({super.key});

  @override
  State<FlipCardScreen> createState() => _FlipCardScreenState();
}

class _FlipCardScreenState extends State<FlipCardScreen> with ReanimatedStateMixin {
  late final isFlipped = useSharedValue(false);
  FlipDirection direction = FlipDirection.y;

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (5600, () => isFlipped.value = true),
      (1400, () => isFlipped.value = false),
    ]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Flip card',
        docs: 'examples/flipCard',
        child: Column(
          children: [
            const Section(
              title: 'Spin it',
              note: 'Drag sideways to spin, up and down to tip. Fling hard and it '
                  'spins several times before settling on a face. Tap to flip.',
              child: Center(
                child: SpinnableCard(front: CreditCardFront(), back: CreditCardBack()),
              ),
            ),
            Section(
              title: 'The site\'s FlipCard',
              note: 'isFlipped toggles; each face turns with withTiming(500 ms).',
              child: Column(
                children: [
                  FlipCard(
                    key: ValueKey(direction),
                    isFlipped: isFlipped,
                    direction: direction,
                    regularContent: const SizedBox(width: 280, height: 175, child: CreditCardFront()),
                    flippedContent: const SizedBox(width: 280, height: 175, child: CreditCardBack()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => isFlipped.value = !isFlipped.value,
                    child: const Text('Toggle card'),
                  ),
                  const SizedBox(height: 8),
                  ChoiceChips<FlipDirection>(
                    options: FlipDirection.values,
                    selected: direction,
                    label: (d) => 'direction: ${d.name}',
                    onSelected: (d) => setState(() {
                      direction = d;
                      isFlipped.value = false;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
