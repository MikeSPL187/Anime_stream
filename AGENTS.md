# AGENTS.md

## Project Operating Contract

### Mission
Develop `anime_stream_app` through small, controlled, verifiable changes that preserve architectural clarity and keep the repository safe to evolve.

### Core Working Rules
- Start by understanding the current implementation before making changes.
- Follow the workflow `discovery -> plan -> implement -> verify`.
- Make minimal, targeted changes that solve the requested task.
- Reuse existing structure when it is good enough.
- Do not perform random architectural reshaping, broad cleanup, or speculative abstraction work.
- If behavior is unknown, implement the safest minimum and label it as proposed behavior.

### Repository Structure
This structure is partly present today and partly inferred from the current folder layout:
- `lib/features`: presentation-facing feature areas and screens.
- `lib/domain`: product-facing models, repository contracts, and use cases.
- `lib/data`: provider adapters, DTOs, mappers, and repository implementations.
- `lib/shared`: reusable app-wide widgets, state helpers, and utilities.
- `lib/app`: app shell concerns such as routing, DI, and theme.

Treat this as the current intended layering unless the repository later defines something more specific.

### Current Product Assumptions
These are current project/domain assumptions, not general operating rules:
- Build a Flutter anime streaming product with AniLibria as a provider adapter.
- UI and domain should not depend directly on AniLibria DTOs or response models.
- Series Page is intended to be an operational hub.
- Player is intended to be a dedicated watch-system surface.
- Continue Watching, History, Watchlist, Downloads, and EpisodeProgress are first-class systems.
- Language, audio, and subtitle modeling should stay separate from season structure.
- Do not use dub-as-season.

### Expected Workflow
1. Discovery
   Read the relevant files first. Identify entry points, state holders, repositories, adapters, and affected screens before touching code.
2. Plan
   Define the smallest safe change set that solves the task. Keep the plan narrow and explicit about touched files and validation.
3. Implement
   Change only the files required for the task. Prefer focused edits over refactors.
4. Verify
   Validate with the best available project commands and report the results.

### When To Use `/plan`
Use `/plan` when:
- the request is ambiguous or spans multiple layers
- the work crosses domain, data, and UI boundaries
- the task may affect player flows, watch systems, navigation, or state architecture
- the change requires sequencing, migration, or tradeoff discussion
- you need to surface blockers before implementation

Do not default to `/plan` for small, local, mechanical edits.

### When To Use `/review`
Use `/review` when:
- reviewing a bugfix for regressions or missed edge cases
- reviewing risky UI changes, player behavior, search/discovery logic, or state transitions
- checking a refactor before merge
- validating whether a change stayed within scope

`/review` should focus on bugs, regressions, missing validation, and behavioral risk before style concerns.

### UI Task Rules
- Understand the existing screen structure, routing, and state inputs before editing widgets.
- Keep UI aligned with product behavior, not provider response shape.
- Do not invent parity facts. If behavior is inferred, mark it as proposed behavior.
- Respect visual hierarchy, spacing, safe areas, responsiveness, loading states, empty states, and error states.
- For streaming surfaces, verify CTA clarity, episode affordances, watch-state visibility, and navigation continuity.
- Avoid cosmetic rewrites unless the task explicitly asks for them.

### Bugfix Task Rules
- Reproduce the bug from code paths and state flow before changing logic.
- Find the narrowest fix that addresses the root cause.
- Check nearby flows that could regress, especially watch progress, player state, search results, lists, and navigation.
- Do not quietly mix unrelated cleanup into the fix.
- State the likely cause, the exact fix, and the verification steps used.

### Refactoring Rules
- Refactor only when it directly supports the requested task or removes a concrete blocker.
- Preserve behavior unless the task explicitly changes behavior.
- Avoid wide file moves, renames, or architectural reshaping without necessity.
- Keep interfaces product-oriented and provider-agnostic.
- If a larger redesign is warranted but not requested, leave a concise note instead of expanding scope.

### Change Reporting
After changes:
- list the exact changed files
- describe behavior changes
- call out any proposed behavior
- state the validation run, including commands and outcomes
- mention residual risks, TODOs, or blockers

### Default Validation Commands
Unless the repository defines more specific project commands, use these as default validation commands where relevant:
- `flutter analyze`
- `flutter test`
- `dart format .`

## Safety Boundaries
- Do not change code blindly. Read the current implementation first.
- Do not perform broad architectural rewrites without explicit need.
- Do not add dependencies or modify `pubspec.yaml` unless the task truly requires it.
- Do not leak AniLibria DTOs into domain or UI.
- Do not use dub-as-season, even as a temporary shortcut.
- Do not change unrelated files just because they are nearby.
- Do not fake verification. If something was not run, say so.
- Do not treat unknown product behavior as confirmed parity.

## Definition of Done
- The requested change is implemented and stays within scope.
- Existing architecture boundaries remain intact.
- Only necessary files were touched.
- The final report includes exact changed files, behavior changes, proposed behavior, validation run, and residual risks.
- The changed behavior is explained clearly.
- Validation was run with available project commands, and the outcome is reported.
- Residual risks, TODOs, and proposed behavior are explicitly called out.
