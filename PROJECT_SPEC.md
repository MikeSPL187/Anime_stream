# PROJECT_SPEC.md

## Project
New Flutter anime streaming app with Crunchyroll-like watch architecture.

## Product Goal
Build a premium-feeling anime streaming app inspired by Crunchyroll’s strongest product patterns:
- Series Page as operational hub
- state-driven primary CTA
- watched-state correction
- player settings hub
- sticky per-series audio
- Continue Watching / History / Watchlist / Downloads
- portrait watch page + landscape fullscreen

## Non-Goals
- not a literal 1:1 Crunchyroll clone
- no direct copying of branding, text, icons, or assets
- no dub-as-season architecture
- no direct UI coupling to AniLibria DTOs

## Data Source
AniLibria API via adapter layer.
AniLibria is a provider, not the app’s internal product model.

## Architecture Rules
1. Domain layer must not depend on AniLibria DTOs.
2. UI must consume domain models only.
3. Language/audio/subtitle model must be separate from seasons.
4. Continue Watching, History, Watchlist, Downloads, EpisodeProgress are first-class systems.
5. Player must receive explicit session context.
6. Unknown parity behavior must be implemented reasonably and marked as proposed behavior.

## Core Domain Entities
- Series
- Season
- Episode
- EpisodeProgress
- ContinueWatchingEntry
- HistoryEntry
- WatchlistEntry
- CustomList
- DownloadEntry
- PlaybackPreferences
- AvailabilityState

## Priority Build Order
1. Domain models + repository interfaces
2. AniLibria adapter layer
3. App shell + routing
4. Series Page
5. Player foundation
6. Watch systems
7. Browse / Search / Simulcasts
8. My Lists + Account
9. Polish

## UX Principles
- Series Page is not an info screen; it is a control surface.
- State-driven CTA must reflect watch state.
- Player settings hub must include:
  - Autoplay
  - Audio
  - Subtitles/CC
  - Quality
  - Playback Speed
  - Report a Problem
- Language is a first-class discovery axis.
- Sticky per-series audio must exist.
- Manual watched correction must exist at episode/season/series levels.

## Known Strategic Improvements vs Crunchyroll
- proper variant model instead of dub-as-season
- cleaner back-stack architecture
- optional Android PiP later
- stronger Search/Browse later

## Prompting Rules for Codex
- make small safe changes
- avoid speculative wide refactors
- explain what changed
- list touched files
- separate confirmed parity from proposed behavior
