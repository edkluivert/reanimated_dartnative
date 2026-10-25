import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';
import 'shared_element_detail_screen.dart';

/// docs/shared-element-transitions/overview: a tile flies to the next screen
/// and back. `sharedTransitionTag` matches views across a push.
class SharedElementScreen extends StatelessWidget {
  const SharedElementScreen({super.key});

  static const colors = [Palette.purple, Palette.blue, Palette.pink, Palette.yellow];

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Shared element transitions',
        docs: 'shared-element-transitions/overview',
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < colors.length; i++)
              GestureDetector(
                onTap: () => Navigator.of(context).push(PageRoute(builder: (_) => SharedElementDetailScreen(index: i))),
                child: AnimatedView(
                  sharedTransitionTag: 'tile-$i',
                  style: AnimatedStyle(width: 150, height: 150, backgroundColor: colors[i], borderRadius: 16),
                ),
              ),
          ],
        ),
      );
}
