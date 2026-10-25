import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import 'shared_element_screen.dart';

/// The second screen of the shared element transition.
class SharedElementDetailScreen extends StatelessWidget {
  const SharedElementDetailScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Tile ${index + 1}')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedView(
              sharedTransitionTag: 'tile-$index',
              style: AnimatedStyle(height: 320, backgroundColor: SharedElementScreen.colors[index], borderRadius: 0),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Go back to see the tile return to its place.'),
            ),
          ],
        ),
      );
}
