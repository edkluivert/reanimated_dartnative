import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'src/capture/capture.dart';
import 'src/components/animated_switch.dart';
import 'src/screens/accordion_screen.dart';
import 'src/screens/airplane_screen.dart';
import 'src/screens/animated_list_screen.dart';
import 'src/screens/animated_sensor_screen.dart';
import 'src/screens/applying_modifiers_screen.dart';
import 'src/screens/bottom_sheet_screen.dart';
import 'src/screens/card_deck_screen.dart';
import 'src/screens/chat_heads_screen.dart';
import 'src/screens/css_animations_screen.dart';
import 'src/screens/css_transitions_screen.dart';
import 'src/screens/customizing_animation_screen.dart';
import 'src/screens/derived_and_reaction_screen.dart';
import 'src/screens/entering_exiting_screen.dart';
import 'src/screens/first_animation_screen.dart';
import 'src/screens/flip_card_screen.dart';
import 'src/screens/floating_action_button_screen.dart';
import 'src/screens/frame_callback_screen.dart';
import 'src/screens/handling_gestures_screen.dart';
import 'src/screens/keyframe_animation_screen.dart';
import 'src/screens/layout_transitions_screen.dart';
import 'src/screens/marquee_screen.dart';
import 'src/screens/measure_screen.dart';
import 'src/screens/reduced_motion_screen.dart';
import 'src/screens/scroll_screen.dart';
import 'src/screens/section_list_screen.dart';
import 'src/screens/sensor_readings_screen.dart';
import 'src/screens/shared_element_screen.dart';
import 'src/screens/slider_screen.dart';
import 'src/screens/styles_and_props_screen.dart';
import 'src/screens/switch_screen.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const ReanimatedExamplesApp());
}

class ReanimatedExamplesApp extends StatelessWidget {
  const ReanimatedExamplesApp({super.key});

  @override
  Widget build(BuildContext context) => App(
        title: 'Reanimated examples',
        home: Capture.enabled ? CaptureRunner(screens: _captured) : const ExamplesMenu(),
      );
}

typedef _Example = (String title, String subtitle, Widget Function() screen);

/// Screens recorded for the README's GIFs (tool/make_gifs.sh), with how
/// many seconds each plays.
final _captured = <(String, Widget Function(), int)>[
  ('accordion', AccordionScreen.new, 7),
  ('bottom_sheet', BottomSheetScreen.new, 9),
  ('flip_card', FlipCardScreen.new, 9),
  ('floating_action_button', FloatingActionButtonScreen.new, 7),
  ('marquee', MarqueeScreen.new, 7),
  ('section_list', SectionListScreen.new, 7),
  ('slider', SliderScreen.new, 7),
  ('switch', SwitchScreen.new, 6),
  ('airplane', AirplaneScreen.new, 9),
  ('chat_heads', ChatHeadsScreen.new, 9),
  ('card_deck', CardDeckScreen.new, 9),
  ('first_animation', FirstAnimationScreen.new, 5),
  ('entering_exiting', EnteringExitingScreen.new, 10),
  ('animated_list', AnimatedListScreen.new, 8),
  ('keyframe', KeyframeScreen.new, 7),
  ('layout_transitions', LayoutTransitionsScreen.new, 9),
  ('css_animations', CSSAnimationsScreen.new, 6),
  ('css_transitions', CSSTransitionsScreen.new, 6),
];

/// The screens, grouped as on the Reanimated site.
final _sections = <(String, List<_Example>)>[
  ('Examples', [
    ('Accordion', 'measured height, withTiming', AccordionScreen.new),
    ('Bottom sheet', 'slide, backdrop, drag to dismiss', BottomSheetScreen.new),
    ('Flip card', '3D flip, hidden backfaces', FlipCardScreen.new),
    ('Floating action button', 'staggered springs', FloatingActionButtonScreen.new),
    ('Marquee', 'endless ticker on a frame callback', MarqueeScreen.new),
    ('Section list', 'scroll-tracked table of contents', SectionListScreen.new),
    ('Slider', 'drag, animated props', SliderScreen.new),
    ('Switch', 'interpolateColor, withTiming', SwitchScreen.new),
    ('Airplane', 'tilt to fly: sensor, springs, parallax, contrail', AirplaneScreen.new),
    ('Chat heads', 'chained springs, velocity on release', ChatHeadsScreen.new),
    ('Card deck', 'swipe, tilt, fling', CardDeckScreen.new),
  ]),
  ('Fundamentals', [
    ('Your first animation', 'useSharedValue, withSpring', FirstAnimationScreen.new),
    ('Animating styles and props', 'useAnimatedStyle, useAnimatedProps', StylesAndPropsScreen.new),
    ('Customizing animation', 'withTiming easings, withSpring playground', CustomizingScreen.new),
    ('Applying modifiers', 'withRepeat, withSequence, withDelay, withClamp', ModifiersScreen.new),
    ('Handling gestures', 'tap, pan, withDecay', GesturesScreen.new),
  ]),
  ('Layout animations', [
    ('Entering / exiting', 'every preset family', EnteringExitingScreen.new),
    ('Animated list', 'staggered entering, exiting, layout springs', AnimatedListScreen.new),
    ('Keyframe animations', 'Keyframe with per-step easing', KeyframeScreen.new),
    ('Layout transitions', 'Linear, Sequenced, Fading, Jumping, Curved, EntryExit', LayoutTransitionsScreen.new),
    ('Shared element transitions', 'sharedTransitionTag across a push', SharedElementScreen.new),
  ]),
  ('CSS', [
    ('CSS animations', 'keyframes, iteration, direction, fill, play state', CSSAnimationsScreen.new),
    ('CSS transitions', 'properties, timing functions, delay, events', CSSTransitionsScreen.new),
  ]),
  ('Core & advanced', [
    ('Derived values & reactions', 'useDerivedValue, useAnimatedReaction', DerivedAndReactionScreen.new),
    ('useFrameCallback', 'per-frame updates, useTimestamp', FrameCallbackScreen.new),
    ('measure', 'useAnimatedRef, measure, getRelativeCoords', MeasureScreen.new),
    ('Scroll', 'useScrollOffset, useAnimatedScrollHandler, scrollTo', ScrollScreen.new),
  ]),
  ('Device', [
    ('useAnimatedSensor', 'gravity and rotation driving views', AnimatedSensorScreen.new),
    ('Sensor readings', 'every sensor, live', SensorReadingsScreen.new),
    ('Reduced motion', 'useReducedMotion, ReducedMotionConfig', ReducedMotionScreen.new),
  ]),
];

class ExamplesMenu extends StatefulWidget {
  const ExamplesMenu({super.key});

  @override
  State<ExamplesMenu> createState() => _ExamplesMenuState();
}

class _ExamplesMenuState extends State<ExamplesMenu> with ReanimatedStateMixin {
  late final slow = useSharedValue(ReanimatedDebug.slowAnimations);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reanimated examples')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ListTile(
              title: const Text('Slow animations (10×)'),
              subtitle: const Text('Reanimated\'s debug toggle'),
              trailing: AnimatedSwitch(
                value: slow,
                onPress: () {
                  slow.value = !slow.value;
                  ReanimatedDebug.slowAnimations = slow.value;
                },
              ),
            ),
            for (final (section, examples) in _sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(section, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              for (final (title, subtitle, screen) in examples)
                ListTile(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  onTap: () => Navigator.of(context).push(PageRoute(builder: (_) => screen())),
                ),
            ],
          ],
        ),
      );
}
