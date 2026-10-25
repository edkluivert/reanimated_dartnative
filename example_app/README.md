# reanimated_dartnative examples

The examples from the
[Reanimated docs](https://docs.swmansion.com/react-native-reanimated/docs/),
written with reanimated_dartnative. Each screen keeps the docs' values
(sizes, colors, durations, spring configs).

Every screen is one file in `lib/src/screens/`; reusable pieces (the
accordion item, bottom sheet, flip card, switch, marquee, …) are in
`lib/src/components/`.

**The Reanimated site's examples** (docs.swmansion.com/react-native-reanimated/examples):

| Screen | File |
| --- | --- |
| Accordion | `accordion_screen.dart` |
| Bottom sheet | `bottom_sheet_screen.dart` |
| Flip card | `flip_card_screen.dart` |
| Floating action button | `floating_action_button_screen.dart` |
| Marquee | `marquee_screen.dart` |
| Section list | `section_list_screen.dart` |
| Slider | `slider_screen.dart` |
| Switch | `switch_screen.dart` |
| Airplane (showpiece) | `airplane_screen.dart` |
| Chat heads (showpiece) | `chat_heads_screen.dart` |
| Card deck (showpiece) | `card_deck_screen.dart` |

**The docs' API examples:**

| Screen | Docs page | File |
| --- | --- | --- |
| Your first animation | fundamentals/your-first-animation | `first_animation_screen.dart` |
| Animating styles and props | fundamentals/animating-styles-and-props | `styles_and_props_screen.dart` |
| Customizing animation | fundamentals/customizing-animation | `customizing_animation_screen.dart` |
| Applying modifiers | fundamentals/applying-modifiers | `applying_modifiers_screen.dart` |
| Handling gestures | fundamentals/handling-gestures | `handling_gestures_screen.dart` |
| Entering / exiting | layout-animations/entering-exiting-animations | `entering_exiting_screen.dart` |
| Animated list | layout-animations/layout-transitions | `animated_list_screen.dart` |
| Keyframe animations | layout-animations/keyframe-animations | `keyframe_animation_screen.dart` |
| Layout transitions | layout-animations/layout-transitions | `layout_transitions_screen.dart` |
| Shared element transitions | shared-element-transitions/overview | `shared_element_screen.dart`, `shared_element_detail_screen.dart` |
| CSS animations | css-animations | `css_animations_screen.dart` |
| CSS transitions | css-transitions | `css_transitions_screen.dart` |
| Derived values & reactions | core/useDerivedValue, advanced/useAnimatedReaction | `derived_and_reaction_screen.dart` |
| useFrameCallback | advanced/useFrameCallback | `frame_callback_screen.dart` |
| measure | advanced/measure | `measure_screen.dart` |
| Scroll | scroll/* | `scroll_screen.dart` |
| useAnimatedSensor | device/useAnimatedSensor | `animated_sensor_screen.dart` |
| Sensor readings | device/useAnimatedSensor | `sensor_readings_screen.dart` |
| Reduced motion | device/useReducedMotion | `reduced_motion_screen.dart` |

The menu has Reanimated's "slow animations" debug switch.

## Run it

```sh
dn pub get
dn run -d <device-id>
```

Sensors report only on a real device. To see reduced motion, turn on
Settings › Accessibility › Motion › Reduce Motion on iOS, or Settings ›
Accessibility › Remove animations on Android. The app follows the change
while it runs.

DartNative apps need a licence. Subscribe at
[dartpub.dev/framework](https://dartpub.dev/framework), then:

```sh
dn config --license-key dnk_...
```
