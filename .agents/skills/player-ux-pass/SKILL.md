# player-ux-pass

## Purpose
Analyze and improve video player UX so playback remains understandable, controllable, and resilient across common watch scenarios.

## When to use
- When touching player UI or playback state logic
- When reviewing watch-page friction or fullscreen behavior
- Before shipping controls, overlays, seek interactions, or episode switching work

## Inputs
- Player surface or watch screen
- Playback states available in code
- Device orientation and fullscreen assumptions

## Workflow
1. Identify the player surfaces: embedded watch page, fullscreen, overlays, and settings entry points.
2. Review control hierarchy: play/pause, seek, timeline, subtitle/audio access, quality, speed, next episode, and back behavior.
3. Review overlay behavior: show/hide timing, tap-to-reveal, focus priority, and conflict with gestures.
4. Review seek interactions: precision, feedback, buffering transitions, and resume behavior.
5. Review episode switching: next/previous affordances, autoplay expectations, and handoff from current progress.
6. Review fullscreen and orientation handling: entry, exit, lock behavior, and continuity with portrait watch flow.
7. Review playback states: initial load, buffering, stalled playback, ended state, and failure handling.
8. Propose the smallest set of changes that improve watch continuity.

## Output format
- UX findings ordered by severity
- Affected playback states or surfaces
- Recommended changes with expected user impact
- Proposed behavior notes where parity is unknown

## Guardrails
- Treat the player as a dedicated watch-system surface, not a generic media widget.
- Do not collapse language or audio variants into season structure.
- Do not assume existing parity with Crunchyroll unless confirmed.
- Keep recommendations compatible with stable progress tracking and episode handoff.
- Preserve watch continuity, progress integrity, and back-stack clarity.
