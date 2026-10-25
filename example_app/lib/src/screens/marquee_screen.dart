import 'package:dartnative/dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/marquee.dart';

/// examples/marquee: endless tickers moving at their own speeds, rows
/// alternating direction, driven by useFrameCallback.
class MarqueeScreen extends StatefulWidget {
  const MarqueeScreen({super.key});

  @override
  State<MarqueeScreen> createState() => _MarqueeScreenState();
}

class _MarqueeScreenState extends State<MarqueeScreen> {
  bool reverse = false;

  static const words = [
    ('Reanimated', Palette.purple),
    ('DartNative', Palette.blue),
    ('60 / 120 fps', Palette.pink),
    ('Shared values', Palette.yellow),
    ('Springs', Color(0xFF7FD1FA)),
  ];

  Widget _chips(int shift) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < words.length; i++)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: words[(i + shift) % words.length].$2,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(words[(i + shift) % words.length].$1,
                  style: const TextStyle(fontSize: 18, color: Palette.navy)),
            ),
        ],
      );

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [(3500, () => setState(() => reverse = !reverse))]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Marquee',
        docs: 'examples/marquee',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Marquee(reverse: reverse, duration: const Duration(seconds: 6), child: _chips(0)),
            const SizedBox(height: 14),
            Marquee(reverse: !reverse, duration: const Duration(seconds: 9), child: _chips(2)),
            const SizedBox(height: 14),
            Marquee(reverse: reverse, duration: const Duration(seconds: 4), child: _chips(4)),
            const SizedBox(height: 40),
            Marquee(
              reverse: reverse,
              duration: const Duration(seconds: 3),
              child: const Padding(
                padding: EdgeInsets.only(right: 32),
                child: Text('BREAKING · animations run on the frame clock ·',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Palette.navy)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => reverse = !reverse),
              child: const Text('Reverse'),
            ),
          ],
        ),
      );
}
