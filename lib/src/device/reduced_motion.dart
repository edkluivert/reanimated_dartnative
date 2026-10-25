import 'dart:async';

import '../animations/animation.dart' show ReduceMotion;

/// The device's reduce-motion accessibility setting.
///
/// On iOS this is Settings > Accessibility > Motion > Reduce Motion; on
/// Android, Settings > Accessibility > Remove animations (animator duration
/// scale 0). The plugin reads it when it loads and keeps it current while the
/// app runs.
abstract final class ReducedMotion {
  static bool _enabled = false;
  static final StreamController<bool> _changes =
      StreamController<bool>.broadcast();

  /// Whether the device asks for reduced motion.
  static bool get isEnabled => _enabled;

  /// Fires when the device setting changes.
  static Stream<bool> get onChange => _changes.stream;

  /// Updates the stored setting. The native side calls this; tests may too.
  static void debugSetEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    _changes.add(enabled);
  }
}

/// App-wide override for how animations treat reduce motion, as
/// Reanimated's `<ReducedMotionConfig mode={...} />`. The
/// `ReducedMotionConfigScope` widget sets it for as long as it is mounted.
abstract final class ReducedMotionConfig {
  /// The global mode. [ReduceMotion.system] follows the device.
  static ReduceMotion mode = ReduceMotion.system;

  /// Whether animations that follow the system setting should skip motion.
  static bool get shouldReduceMotion {
    switch (mode) {
      case ReduceMotion.always:
        return true;
      case ReduceMotion.never:
        return false;
      case ReduceMotion.system:
        return ReducedMotion.isEnabled;
    }
  }
}

/// Whether the device's reduce-motion setting is on, as Reanimated's
/// `useReducedMotion()`. Unlike a hook it is not reactive; listen to
/// [ReducedMotion.onChange] to follow changes.
bool useReducedMotion() => ReducedMotion.isEnabled;
