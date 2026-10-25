import '../core/clock.dart';

/// Debugging switches, as Reanimated's "Toggle slow animations" and logger
/// configuration.
abstract final class ReanimatedDebug {
  /// Plays every animation ten times slower (frame callbacks, timestamps and
  /// CSS animations included).
  static bool get slowAnimations => AnimationClock.instance.timeScale < 1;
  static set slowAnimations(bool slow) =>
      AnimationClock.instance.timeScale = slow ? 0.1 : 1;
}
