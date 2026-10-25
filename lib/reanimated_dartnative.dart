/// React Native Reanimated for DartNative.
///
/// Shared values driven by spring, timing and decay animations on the
/// display's frame clock; animated styles and props that track their
/// dependencies; layout, CSS and shared element animations; and hardware
/// sensors and the reduce-motion setting read natively over FFI.
library;

// Core
export 'src/core/animated_props.dart';
export 'src/core/animated_ref.dart';
export 'src/core/animated_style.dart';
export 'src/core/clock.dart' show AnimationClock;
export 'src/core/frame_callback.dart';
export 'src/core/reactive.dart';
export 'src/core/shared_value.dart';

// Animations
export 'src/animations/animation.dart';
export 'src/animations/decay.dart';
export 'src/animations/modifiers.dart';
export 'src/animations/spring.dart';
export 'src/animations/timing.dart';
export 'src/easing/easing.dart';

// Utilities
export 'src/utilities/colors.dart';
export 'src/utilities/interpolate.dart';

// Layout animations
export 'src/layout/layout_animation.dart';
export 'src/layout/layout_transition.dart';
export 'src/layout/presets.dart';

// CSS animations and transitions
export 'src/css/css.dart';

// Scroll
export 'src/scroll/scroll.dart';

// Device
export 'src/channel/reanimated_ffi_bindings.dart'
    show ReanimatedFFIBindings, ReanimatedResult;
export 'src/device/animated_sensor.dart';
export 'src/device/reduced_motion.dart';
export 'src/device/sensor_types.dart';

// Widgets
export 'src/widgets/animated_presence.dart';
export 'src/widgets/animated_view.dart';
export 'src/widgets/layout_animation_config.dart';
export 'src/widgets/reanimated_state_mixin.dart';

// Debugging
export 'src/debug/debug.dart';
