# repo-discovery

## Purpose
Study the repository before implementation so changes are based on actual entry points, state flow, and architecture rather than guesses.

## When to use
- Before starting any non-trivial task
- Before changing navigation, state management, repositories, adapters, or screen composition
- When the request references a feature but the implementation location is not obvious

## Inputs
- User request
- Relevant feature name or screen name
- Known module hints, if any

## Workflow
1. Find the entry points for the affected feature.
2. Trace the screen or route into its widget tree and state holders.
3. Identify the data flow: controllers, providers, services, repositories, adapters, DTOs, and domain models.
4. Mark the files that are definitely in scope and the files that are likely adjacent risk areas.
5. Read enough surrounding code to understand current behavior before proposing edits.
6. Summarize the current implementation and the safest edit surface.

## Output format
- Feature entry points
- State flow summary
- Data flow summary
- Files likely in scope
- Specific files to read before editing
- Risks or unknowns before implementation

## Guardrails
- Do not edit before identifying the current implementation path.
- Do not assume a screen owns its own state without tracing it.
- Do not infer architecture from folder names alone.
- Separate confirmed implementation facts from inferred structure.
- Keep discovery focused on the requested task instead of mapping the whole repo.
