import 'dart:async';

import 'package:dartnative/dartnative.dart';

/// Capture mode, used to record the README's GIFs on a simulator with
/// `tool/make_gifs.sh` (which runs the app with `--dart-define=CAPTURE=true`).
///
/// The app then plays each showcased screen in turn, and those screens run
/// scripted versions of the interactions a user would make (see
/// [Capture.play]). Outside capture mode none of this runs.
abstract final class Capture {
  static const bool enabled = bool.fromEnvironment('CAPTURE');

  /// Runs [steps] in order once [state] is mounted: each waits its delay
  /// (milliseconds after the previous step), then runs its action. Does
  /// nothing outside capture mode.
  static void play(State state, List<(int ms, void Function())> steps) {
    if (!enabled) return;
    Future<void>(() async {
      for (final (ms, action) in steps) {
        await Future<void>.delayed(Duration(milliseconds: ms));
        if (!state.mounted) return;
        action();
      }
    });
  }

  /// Calls [onFrame] with the seconds elapsed, every 16 ms, for [seconds].
  static Future<void> drive(State state, double seconds, void Function(double t) onFrame) async {
    final sw = Stopwatch()..start();
    while (state.mounted && sw.elapsedMicroseconds / 1e6 < seconds) {
      onFrame(sw.elapsedMicroseconds / 1e6);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }
}

/// Plays [screens] one after another, each for its duration, and prints a
/// timeline line per screen (`CAPTURE_TIMELINE name startMs endMs`, wall-clock
/// epoch milliseconds), which tool/make_gifs.sh reads from the `dn run` log
/// to cut the recording.
class CaptureRunner extends StatefulWidget {
  const CaptureRunner({super.key, required this.screens});

  final List<(String name, Widget Function() screen, int seconds)> screens;

  @override
  State<CaptureRunner> createState() => _CaptureRunnerState();
}

class _CaptureRunnerState extends State<CaptureRunner> {
  String status = 'Capture mode: starting…';

  @override
  void initState() {
    super.initState();
    Future<void>(_run);
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 8)); // time to start recording
    for (final (name, screen, seconds) in widget.screens) {
      if (!mounted) return;
      setState(() => status = 'Capture mode: $name');
      Navigator.of(context).push(PageRoute(builder: (_) => screen(), transition: RouteTransition.none));
      final start = DateTime.now().millisecondsSinceEpoch;
      await Future<void>.delayed(Duration(seconds: seconds));
      final end = DateTime.now().millisecondsSinceEpoch;
      // ignore: avoid_print
      print('CAPTURE_TIMELINE $name $start $end');
      if (!mounted) return;
      Navigator.of(context).pop();
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    // ignore: avoid_print
    print('CAPTURE_DONE');
    setState(() => status = 'Capture mode: done');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reanimated examples')),
        body: Center(child: Text(status)),
      );
}
