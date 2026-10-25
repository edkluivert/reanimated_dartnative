import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

// How the examples turn a gravity reading into motion. Readings use the
// plugin's axes on both platforms: x toward the device's right edge, y
// toward its top edge, and the value is the force holding the device up
// (flat, screen up: z = +9.81; right edge down: x < 0; upright: y = +9.81).
// test/tilt_mapping_test.dart checks these against simulated device poses.

/// How far the useAnimatedSensor box slides: toward whichever edge is
/// lower, as the docs example's `gravity.x * 20` (with the screen's y axis
/// pointing down), limited to [maxDistance].
Offset gravityToBoxOffset(Value3D g, {double maxDistance = 100}) => Offset(
      clamp(-g.x * 20, -maxDistance, maxDistance),
      clamp(g.y * 20, -maxDistance, maxDistance),
    );

/// The airplane's steering, from -1 to 1 on each axis: rolling right steers
/// right, and tipping the top of the device away from you (from upright
/// toward flat) climbs toward the top of the screen.
Offset gravityToSteer(Value3D g) => Offset(
      clamp(-g.x / 4.5, -1, 1),
      clamp((g.y - 5) / 4, -1, 1),
    );
