# flutter-ui-audit

## Purpose
Run a practical UI audit for Flutter screens in the streaming app and identify issues that affect clarity, usability, and production polish.

## When to use
- When reviewing a screen before or after UI work
- When a layout feels off but the exact issue is unclear
- Before shipping changes to browse, series, player-adjacent, search, or list screens

## Inputs
- Target screen or widget tree
- Screenshots, recordings, or code paths if available
- Device context if relevant: phone, tablet, portrait, landscape

## Workflow
1. Check visual hierarchy: primary action, secondary actions, metadata ordering, and content emphasis.
2. Check spacing and rhythm: padding, grouping, list density, and alignment consistency.
3. Check consistency: typography, button treatment, icon sizing, chips, cards, and loading visuals.
4. Check responsiveness across narrow and wide layouts.
5. Check tap targets, gesture affordances, and scroll comfort.
6. Check safe areas, keyboard overlap, and system UI collisions.
7. Check loading, empty, and error states for completeness and clarity.
8. Summarize the highest-impact fixes first.

## Output format
- Findings ordered by severity
- File or widget references when available
- Recommended fixes with highest-impact items first
- Residual risks or unverified states

## Guardrails
- Focus on product-facing issues, not personal style preferences.
- Do not recommend a redesign when a targeted improvement is enough.
- Do not ignore loading, empty, and error states just because the happy path looks good.
- Separate structural UX issues from purely visual polish issues.
- For streaming surfaces, verify that watch actions remain obvious during scroll and content density changes.
