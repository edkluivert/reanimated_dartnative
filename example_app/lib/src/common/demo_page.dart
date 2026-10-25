import 'package:dartnative/dartnative.dart';

/// A demo screen: what the docs page shows, with a note pointing at it.
class DemoPage extends StatelessWidget {
  const DemoPage({
    super.key,
    required this.title,
    required this.docs,
    required this.child,
    this.scrollable = true,
  });

  final String title;

  /// The docs page this demo follows, relative to
  /// docs.swmansion.com/react-native-reanimated/docs/.
  final String docs;
  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('docs: $docs', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          const SizedBox(height: 12),
          if (scrollable) child else Expanded(child: child),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: scrollable ? SingleChildScrollView(child: body) : body,
    );
  }
}
