---
name: series-detail-page-review
description: Review the series detail page for CTA clarity, episode structure, and operational-hub usability.
---

# series-detail-page-review

## Purpose
Review the series detail page as an operational hub and identify issues in hierarchy, CTA logic, episode structure, and scroll composition.

## When to use
- When designing, reviewing, or refactoring the series page
- When the detail page feels informative but not actionable
- Before shipping changes to hero blocks, CTAs, metadata, season pickers, or recommendation modules

## Inputs
- Series page implementation
- Current states available to the page: watch progress, availability, watchlist, downloads, episode list
- Screenshots or recordings if available

## Workflow
1. Review the hero or media block for clarity, density, and immediate watch affordance.
2. Review metadata hierarchy: title, subtitle, status, language context, tags, synopsis, and support data.
3. Review CTA hierarchy: primary watch action, continue/resume state, watchlist, downloads, and secondary actions.
4. Review season and episode structure without using dub-as-season assumptions.
5. Review recommendation or related-content modules for placement and interruption cost.
6. Review scroll composition so the page feels like a control surface rather than a static info page.
7. Identify whether critical watch-system actions remain visible and understandable through the full page.

## Output format
- Findings ordered by impact on watch intent
- CTA and hierarchy issues
- Season/episode structure issues
- Recommended changes with affected page areas
- Proposed behavior notes where product rules are not yet finalized

## Guardrails
- Treat the Series Page as an operational hub first.
- Do not accept metadata density that hides the primary watch action.
- Do not let recommendation modules break the main watch flow.
- Separate confirmed current behavior from suggested future behavior.
- Do not model language variants as seasons.
