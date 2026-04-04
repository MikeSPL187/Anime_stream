# CODING_RULES.md

## Role
Act as tech lead and implementation engineer for a new anime streaming app.

## Primary Goal
Build a Crunchyroll-like anime streaming app with clean internal architecture and AniLibria as provider adapter.

## Non-Negotiable Rules
1. Do not couple UI or domain to AniLibria DTOs.
2. Do not implement dub-as-season.
3. Keep language/audio/subtitle model separate from season structure.
4. Treat Continue Watching, History, Watchlist, Downloads, EpisodeProgress as first-class systems.
5. Series Page must be an operational hub, not a static info page.
6. Player must be a dedicated watch-system surface.
7. Separate parity-driven behavior from proposed behavior.
8. Prefer small safe changes over broad refactors.
9. Do not add dependencies unless necessary.
10. Do not change pubspec.yaml unless required for the requested task.

## Engineering Style
- Read the current codebase before making changes.
- Reuse existing structure when reasonable.
- Avoid speculative abstractions.
- Avoid mass renames and wide cleanup unless explicitly requested.
- Leave TODOs where provider/API details are not yet finalized.
- Prefer compile-safe scaffolding over premature completeness.

## Output Style
After each task, report:
1. Created
2. Updated
3. Architectural decisions
4. Risks / TODO
5. Next recommended step
