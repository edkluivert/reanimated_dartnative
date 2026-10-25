import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/table_of_contents.dart';

/// examples/sectionlist: scrolling the cards updates the table of contents
/// (the section nearest the top wins); tapping a name scrolls to its
/// section. The underline springs between names.
class SectionListScreen extends StatefulWidget {
  const SectionListScreen({super.key});

  @override
  State<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends State<SectionListScreen> with ReanimatedStateMixin {
  static const sectionHeight = 320.0;
  static const sections = [
    ('Accordion', 'Show and hide content with a measured, animated height.', Palette.purple),
    ('Bottom sheet', 'A sheet that slides over a fading backdrop and can be flung away.', Palette.blue),
    ('Flip card', 'Two faces turning in 3D with their backs hidden.', Palette.pink),
    ('Floating action button', 'Buttons that spring out with a stagger.', Palette.yellow),
    ('Marquee', 'An endless ticker driven by a frame callback.', Color(0xFF7FD1FA)),
    ('Section list', 'This screen.', Palette.purple),
    ('Slider', 'A draggable knob resizing a box.', Palette.blue),
    ('Switch', 'Track color and thumb animated together.', Palette.pink),
  ];

  final cardsController = ScrollController();
  final tocController = ScrollController();
  late final visibleIndex = useSharedValue(0);

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (1000, () => scrollToSection(3)),
      (1800, () => scrollToSection(6)),
      (1800, () => scrollToSection(1)),
    ]);
    useAnimatedScrollHandler(cardsController, onScroll: (event, _) {
      // The section whose start is nearest the top.
      final index = (event.contentOffset / sectionHeight).round().clamp(0, sections.length - 1);
      if (visibleIndex.value != index) visibleIndex.value = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
    cardsController.dispose();
    tocController.dispose();
  }

  void scrollToSection(int index) => scrollTo(cardsController, 0, index * sectionHeight, true);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Section list')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A horizontal scroll view takes all the height it is offered;
            // give the table of contents its own.
            SizedBox(
              height: 52,
              child: TableOfContents(
                names: [for (final s in sections) s.$1],
                visibleIndex: visibleIndex,
                onSelect: scrollToSection,
                controller: tocController,
              ),
            ),
            Expanded(
              child: ListView(
                controller: cardsController,
                children: [
                  for (final (name, content, color) in sections)
                    SizedBox(
                      height: sectionHeight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                                child: Text(content, style: const TextStyle(fontSize: 17, color: Palette.navy)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 400),
                ],
              ),
            ),
          ],
        ),
      );
}
