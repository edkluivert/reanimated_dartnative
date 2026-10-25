#!/usr/bin/env python3
"""Writes doc/EXAMPLES.md and one page per example in doc/examples/.

Every page shows the example's GIF, what it demonstrates, and its full
source: the screen file plus every component it uses, read straight from
example_app/lib so the docs never drift from the code. Code that only
exists for recording the GIFs (capture mode) is left out.

    python3 tool/gen_examples_docs.py
"""

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'example_app', 'lib', 'src')
OUT = os.path.join(ROOT, 'doc', 'examples')
GIFS = os.path.join(ROOT, 'doc', 'gifs')
DOCS = 'https://docs.swmansion.com/react-native-reanimated/'

# (slug, title, screen file, gif, docs page, summary, what to look at)
EXAMPLES = [
    # The Reanimated site's examples.
    ('accordion', 'Accordion', 'accordion_screen.dart', 'accordion', 'examples/accordion',
     'Sections open and close with a smooth height animation, and the chevron turns with them.',
     ['Each body is measured with `AnimatedView(onLayout:)`, then its visible height animates between 0 and that height.',
      '`useDerivedAnimation(0.0, () => withTiming(height.value * (isExpanded.value ? 1 : 0)))` is the Dart form of Reanimated\'s `useDerivedValue(() => withTiming(...))`.',
      'Toggling `isExpanded` is all a tap does. Nothing calls `setState`.']),
    ('bottom_sheet', 'Bottom sheet', 'bottom_sheet_screen.dart', 'bottom_sheet', 'examples/bottomsheet',
     'A sheet slides up over a dimming backdrop. Tap the backdrop, press Done, or drag the sheet down to close it.',
     ['`progress` runs from 1 (closed) to 0 (open) with `withTiming`; the sheet slides by `progress × 2 × height` and the backdrop fades with `1 − progress`.',
      'A drag adds an offset. On release, the sheet closes if it was dragged a third of the way or flung, and otherwise springs back keeping the drag\'s velocity.',
      'The switches inside are the `AnimatedSwitch` from the Switch example.']),
    ('flip_card', 'Flip card', 'flip_card_screen.dart', 'flip_card', 'examples/flipCard',
     'A card you spin in 3D with your finger, and the site\'s toggle-driven flip card.',
     ['Two faces turn together, the back half a turn (π) ahead of the front; `backfaceVisibility: false` hides whichever faces away.',
      '`SpinnableCard` turns drags into rotation. On release it snaps to the face the fling is heading for, keeping the fling\'s angular velocity.',
      '`FlipCard` is the site\'s version: `withTiming` between 0 and π whenever `isFlipped` changes.']),
    ('floating_action_button', 'Floating action button', 'floating_action_button_screen.dart', 'floating_action_button', 'examples/floatingactionbutton',
     'The "+" turns into an × and three buttons spring out above it, each scaling in a little after the one below.',
     ['Each button is `useDerivedAnimation(() => withSpring(-offset × index))` plus a scale of `withDelay(index × 100 ms, withTiming(...))`, as on the site.',
      'Taps are caught once over the whole button area and matched to a button by position. The buttons move by transform, and a transformed view\'s touch area stays where it was laid out.']),
    ('marquee', 'Marquee', 'marquee_screen.dart', 'marquee', 'examples/marquee',
     'Endless tickers moving at their own speeds, rows alternating direction.',
     ['`useFrameCallback` advances one shared offset by `childWidth / duration` per millisecond, wrapping at one child width.',
      'The content is measured once, then cloned enough times to cover the screen. Every clone reads the same offset, so the loop has no seam.']),
    ('section_list', 'Section list', 'section_list_screen.dart', 'section_list', 'examples/sectionlist',
     'Scrolling the cards updates the table of contents; tapping a name scrolls to that section. The underline springs between names.',
     ['`useAnimatedScrollHandler` turns the scroll offset into `visibleIndex`.',
      'The underline\'s position and width are `useDerivedAnimation` springs to the measured position of the visible name.',
      '`scrollTo` moves both lists: the cards when you tap a name, the names when the visible section changes.']),
    ('slider', 'Slider', 'slider_screen.dart', 'slider', 'examples/slider',
     'Drag the knob: the box above follows its width, and the label reads it through animated props.',
     ['One shared value, `offset`, drives the knob, the fill, the box\'s width and color, and the label.',
      'The label is `useAnimatedProps` read by `AnimatedPropsBuilder`, so only the `Text` rebuilds.',
      'The whole track receives the touch, so tapping anywhere springs the knob there.']),
    ('switch', 'Switch', 'switch_screen.dart', 'switch', 'examples/switch',
     'A switch whose track color and thumb animate together, at any size and in any colors.',
     ['The track color is `withTiming(interpolateColor(...))` and the thumb is `withTiming(interpolate(...))`, both as `useDerivedAnimation`.',
      'Several switches share one shared value, so they all move together.']),
    # Showpieces.
    ('airplane', 'Airplane', 'airplane_screen.dart', 'airplane', 'device/useAnimatedSensor',
     'Fly a plane by tilting the phone (or by dragging, where there is no motion sensor).',
     ['Gravity readings set where you steer, and the plane follows on a spring.',
      'It banks in 3D (`rotateY`) by how far it lags behind where you steer.',
      'Three cloud layers scroll at different speeds from one `useFrameCallback`; climbing makes them faster.',
      'The contrail is a chain of springs, each chasing the one ahead.',
      '`tilt_mapping.dart` holds the tilt-to-steering maths, which `example_app/test/tilt_mapping_test.dart` checks against simulated device poses.']),
    ('chat_heads', 'Chat heads', 'chat_heads_screen.dart', 'chat_heads', 'fundamentals/handling-gestures',
     'Drag the front bubble and the others trail behind it. Fling it and it flies to the nearest edge.',
     ['Each follower is `useDerivedAnimation(() => withSpring(ahead.value))`. Its spring restarts whenever the bubble ahead moves and keeps its own velocity, which is what makes the trail smooth.',
      'On release the front bubble springs to the nearest edge with `velocity:` set to the fling.',
      'One `GestureDetector` covers the screen, and a drag only starts if it lands on the front bubble.']),
    ('card_deck', 'Card deck', 'card_deck_screen.dart', 'card_deck', 'fundamentals/handling-gestures',
     'Swipe cards away: the top card tilts as you drag, a stamp fades in, and the next card grows into place.',
     ['One `translation` shared value drives everything. The top card\'s position and tilt, the stamps\' opacity, and the next card\'s scale are all `interpolate`d from it.',
      'A fling past a third of the width, or a fast one, throws the card off with `withTiming`. Otherwise it springs back with the release velocity.',
      'DartNative\'s `Stack` matches children by index, so each index keeps its depth and only the card shown there changes.']),
    # Fundamentals.
    ('first_animation', 'Your first animation', 'first_animation_screen.dart', 'first_animation', 'fundamentals/your-first-animation',
     'A box that grows by 50 with a spring each time you press the button.',
     ['`useSharedValue` holds the width, `useAnimatedStyle` reads it, and `width.set(withSpring(...))` animates it.']),
    ('styles_and_props', 'Animating styles and props', 'styles_and_props_screen.dart', None, 'fundamentals/animating-styles-and-props',
     'A box moved by an animated style, and a circle whose radius is an animated prop.',
     ['Use animated styles for a view\'s style. Use animated props for anything else a widget takes, such as a painter\'s radius.']),
    ('customizing_animation', 'Customizing animation', 'customizing_animation_screen.dart', None, 'fundamentals/customizing-animation',
     'The easing curves side by side, a spring playground, and a color animation.',
     ['Every easing runs for the same duration, so you can compare their shapes.',
      'The playground switches between physics-based springs (mass, stiffness, damping) and duration-based ones (duration, dampingRatio).']),
    ('applying_modifiers', 'Applying modifiers', 'applying_modifiers_screen.dart', None, 'fundamentals/applying-modifiers',
     'withRepeat, the docs\' shake built from withSequence and withDelay, and withClamp.',
     ['`withRepeat(withTiming(-offset.value), numberOfReps: -1, reverse: true)` slides back and forth forever.',
      '`withClamp` keeps a bouncy spring inside its limits; the bar below it shows the same spring unclamped.']),
    ('handling_gestures', 'Handling gestures', 'handling_gestures_screen.dart', None, 'fundamentals/handling-gestures',
     'Press, drag and release a ball that springs back; fling another that slows down with withDecay.',
     ['The release velocity goes straight into `withDecay(velocity: ...)` with `rubberBandEffect`.',
      'The `GestureDetector` wraps the whole stage, not the ball, because the ball moves by transform.']),
    # Layout animations.
    ('entering_exiting', 'Entering / exiting', 'entering_exiting_screen.dart', 'entering_exiting', 'layout-animations/entering-exiting-animations',
     'Every preset family, with or without springify, and LayoutAnimationConfig.',
     ['`AnimatedPresence` keeps a removed view on screen while its `exiting` animation plays.',
      'Changing the key swaps in a new view, so the old one exits while the new one enters.']),
    ('animated_list', 'Animated list', 'animated_list_screen.dart', 'animated_list', 'layout-animations/layout-transitions',
     'Rows spring in one after another, fly out when removed, and the rest glide into the gap.',
     ['`entering`, `exiting` and `layout` on the same `AnimatedView`, inside an `AnimatedPresence`.',
      'The stagger is just `.delay()` based on the row\'s index, used only on the first build.']),
    ('keyframe', 'Keyframe animations', 'keyframe_animation_screen.dart', 'keyframe', 'layout-animations/keyframe-animations',
     'The docs\' keyframe, which swings the box to 100° with an exponential ease and back, plus a keyframed exit.',
     ['`KeyframeStyle(easing: ...)` sets the easing for the step leading to that keyframe.']),
    ('layout_transitions', 'Layout transitions', 'layout_transitions_screen.dart', 'layout_transitions', 'layout-animations/layout-transitions',
     'Shuffle or resize a grid and watch each tile travel to its new place.',
     ['Every tile has `layout: <transition>`. After a rebuild it is measured and animated from its old place and size.']),
    ('shared_element', 'Shared element transitions', 'shared_element_screen.dart', None, 'shared-element-transitions/overview',
     'A tile flies to the next screen and back.',
     ['The same `sharedTransitionTag` on both screens; DartNative\'s `Hero` runs the flight.']),
    # CSS.
    ('css_animations', 'CSS animations', 'css_animations_screen.dart', 'css_animations', 'css-animations/animation-name',
     'Keyframes with duration, iteration count, direction, timing functions (also per keyframe), fill mode and play state.',
     ['CSS animations need no shared values. They play from their settings, can be paused with `playState`, and report events.']),
    ('css_transitions', 'CSS transitions', 'css_transitions_screen.dart', 'css_transitions', 'css-transitions/transition-property',
     'Change a style with setState and the listed properties animate to it.',
     ['The same 800 ms width transition with six timing functions, side by side.']),
    # Core and advanced.
    ('derived_and_reaction', 'Derived values & reactions', 'derived_and_reaction_screen.dart', None, 'core/useDerivedValue',
     'A bar\'s width derived from a slider, and a reaction that fires when it passes 200.',
     ['`useDerivedValue` needs no dependency list; it tracks the shared values it reads.',
      '`useAnimatedReaction` gets the current and previous value, so it can react only to changes.']),
    ('frame_callback', 'useFrameCallback', 'frame_callback_screen.dart', None, 'advanced/useFrameCallback',
     'A dot tracing a figure eight frame by frame, which you can pause, and useTimestamp.',
     ['The callback gets `timeSincePreviousFrame`, so motion stays the same speed at 60 or 120 Hz.']),
    ('measure', 'measure', 'measure_screen.dart', None, 'advanced/measure',
     'Tap the box to measure it; tap the stage to see the tap relative to the box.',
     ['`useAnimatedRef()` is a `GlobalKey`: pass it as the widget\'s `key`, then call `measure(ref)` or `getRelativeCoords(ref, x, y)`.']),
    ('scroll', 'Scroll', 'scroll_screen.dart', None, 'scroll/useScrollOffset',
     'A header that shrinks and changes color as the list scrolls, the scroll handler\'s events, and scrollTo.',
     ['`useScrollOffset(controller)` gives the offset as a shared value; `interpolate` and `interpolateColor` turn it into the header\'s style.']),
    # Device.
    ('animated_sensor', 'useAnimatedSensor', 'animated_sensor_screen.dart', None, 'device/useAnimatedSensor',
     'A box that slides toward the lower edge as you tilt, and a card that tilts with the device.',
     ['A new spring starts on every gravity reading and inherits the running spring\'s velocity, so the box glides.']),
    ('sensor_readings', 'Sensor readings', 'sensor_readings_screen.dart', None, 'device/useAnimatedSensor',
     'Live readings of every sensor, with availability and interface orientation.',
     ['`sensor` is a shared value, so `ValueListenableBuilder` can show it.']),
    ('reduced_motion', 'Reduced motion', 'reduced_motion_screen.dart', None, 'device/useReducedMotion',
     'The device\'s Reduce Motion setting, followed live, and how each animation behaves under it.',
     ['Turn on Reduce Motion (iOS) or Remove animations (Android) while the screen is open and it updates.']),
]


def match_close(src, start, open_ch, close_ch):
    """Index just past the bracket closing the one at src[start]."""
    depth = 0
    i = start
    while i < len(src):
        c = src[i]
        if c in '\'"':  # skip strings
            q = c
            i += 1
            while i < len(src) and src[i] != q:
                i += 2 if src[i] == '\\' else 1
        elif c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError('unbalanced')


def strip_capture(src):
    """Removes code that only exists for recording the README's GIFs."""
    src = src.replace("import '../capture/capture.dart';\n", '')
    note = re.compile(r"\n?    // Only used when recording the README's GIFs \(capture mode\)\. It replays\n"
                      r"    // taps and drags automatically; skip it when reading the example\.\n")
    while True:
        m = note.search(src)
        if not m:
            break
        rest = src[m.end():]
        if rest.lstrip().startswith('Capture.play('):
            open_at = m.end() + rest.index('(')
            end = match_close(src, open_at, '(', ')')
            end = src.index(';', end) + 1
        elif rest.lstrip().startswith('if (Capture.enabled)'):
            open_at = m.end() + rest.index('{')
            end = match_close(src, open_at, '{', '}')
        else:
            raise ValueError('unexpected capture block')
        if src[end:end + 1] == '\n':
            end += 1
        src = src[:m.start()] + ('\n' if m.group(0).startswith('\n') else '') + src[end:]
    # An initState left with only super.initState() goes too.
    src = re.sub(r"  @override\n  void initState\(\) \{\n    super\.initState\(\);\n\s*\}\n\n", '', src)
    # Fields and assignments only the capture scripts use.
    src = re.sub(r"\n\n  /// [^\n]*capture mode[^\n]*\n  [^\n]*capture\w+ = [^\n]*;", '', src)
    src = re.sub(r"  /// [^\n]*capture mode[^\n]*\n  [^\n]*capture\w+ = [^\n]*;\n\n", '', src)
    src = re.sub(r"\n *capture\w+ = \w+;", '', src)
    src = re.sub(r"\n{3,}", '\n\n', src)
    if 'Capture' in src or 'capture' in src.replace('Capture', ''):
        leftover = [l for l in src.splitlines() if 'apture' in l]
        raise ValueError('capture code left: %s' % leftover)
    return src


def components_of(path, seen=None):
    """Component files a source file uses, recursively, in first-use order."""
    seen = seen if seen is not None else []
    src = open(path).read()
    for m in re.finditer(r"import '(?:\.\./components/|)([\w_]+\.dart)';", src):
        name = m.group(1)
        comp = os.path.join(LIB, 'components', name)
        if os.path.exists(comp) and comp not in seen and comp != path:
            seen.append(comp)
            components_of(comp, seen)
    for m in re.finditer(r"import '([\w_]+_screen\.dart)';", src):  # screens a screen pushes
        other = os.path.join(LIB, 'screens', m.group(1))
        if other not in seen and other != path:
            seen.append(other)
            components_of(other, seen)
    return seen


def code_section(path):
    rel = os.path.relpath(path, os.path.join(ROOT, 'example_app'))
    src = strip_capture(open(path).read()).rstrip() + '\n'
    return '### `%s`\n\n```dart\n%s```\n' % (rel, src)


def main():
    os.makedirs(OUT, exist_ok=True)
    index_rows = []
    for i, (slug, title, screen, gif, docs, summary, points) in enumerate(EXAMPLES):
        screen_path = os.path.join(LIB, 'screens', screen)
        files = [screen_path] + components_of(screen_path, [screen_path])[1:]
        prev_link = '[← %s](%s.md)' % (EXAMPLES[i - 1][1], EXAMPLES[i - 1][0]) if i > 0 else ''
        next_link = '[%s →](%s.md)' % (EXAMPLES[i + 1][1], EXAMPLES[i + 1][0]) if i + 1 < len(EXAMPLES) else ''
        nav = ' · '.join(x for x in [prev_link, '[All examples](../EXAMPLES.md)', next_link] if x)
        parts = ['<!-- Generated by tool/gen_examples_docs.py from example_app/lib. Do not edit. -->\n',
                 '# %s\n' % title, nav + '\n']
        has_gif = gif and os.path.exists(os.path.join(GIFS, gif + '.gif'))
        if has_gif:
            parts.append('<img src="../gifs/%s.gif" width="300" alt="%s">\n' % (gif, title))
        parts.append(summary + '\n')
        parts.append('Reanimated docs: [%s](%s%s)\n' % (docs, DOCS + ('' if docs.startswith('examples') else 'docs/'), docs))
        parts.append('## What to look at\n')
        parts.append('\n'.join('- ' + p for p in points) + '\n')
        parts.append('## Code\n')
        parts.append('The screen comes first, then the components it uses. '
                     'Shared helpers (`DemoPage`, `Section`, `Stage`, `Palette`, `Buttons`, `ChoiceChips`, '
                     '`LabeledSlider`) live in `example_app/lib/src/common/` and only do layout.\n')
        for f in files:
            parts.append(code_section(f))
        parts.append(nav + '\n')
        with open(os.path.join(OUT, slug + '.md'), 'w') as fh:
            fh.write('\n'.join(parts))
        index_rows.append((slug, title, gif if has_gif else None, summary))

    lines = ['<!-- Generated by tool/gen_examples_docs.py from example_app/lib. Do not edit. -->\n',
             '# Examples\n',
             'Every screen of the example app, with its full code. Each page shows the GIF, '
             'explains what to look at, and lists the screen\'s source and every component it uses. '
             'Run them with `cd example_app && dn run -d <device-id>`.\n',
             'Back to the [README](../README.md).\n']
    groups = [('The Reanimated site\'s examples', 0, 8), ('Showpieces', 8, 11), ('Fundamentals', 11, 16),
              ('Layout animations', 16, 21), ('CSS', 21, 23), ('Core and advanced', 23, 27), ('Device', 27, 30)]
    for name, a, b in groups:
        lines.append('## %s\n' % name)
        rows = index_rows[a:b]
        with_gif = [r for r in rows if r[2]]
        if with_gif:
            cells = ['[<img src="gifs/%s.gif" width="200" alt="%s">](examples/%s.md)<br>**%s**' % (r[2], r[1], r[0], r[1]) for r in with_gif]
            table = ['| ' + ' | '.join([''] * min(3, len(cells))) + ' |',
                     '| ' + ' | '.join([':---:'] * min(3, len(cells))) + ' |']
            for k in range(0, len(cells), 3):
                row = cells[k:k + 3]
                row += [''] * (min(3, len(cells)) - len(row))
                table.append('| ' + ' | '.join(row) + ' |')
            lines.append('\n'.join(table) + '\n')
        lines.append('\n'.join('- [%s](examples/%s.md): %s' % (r[1], r[0], r[3]) for r in rows) + '\n')
    with open(os.path.join(ROOT, 'doc', 'EXAMPLES.md'), 'w') as fh:
        fh.write('\n'.join(lines))
    print('Wrote doc/EXAMPLES.md and %d pages in doc/examples/.' % len(EXAMPLES))


if __name__ == '__main__':
    main()
