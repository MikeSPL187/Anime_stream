# search-discovery-audit

## Purpose
Evaluate search and discovery behavior for a streaming product, focusing on findability, relevance, and recovery when the user does not know the exact title.

## When to use
- When reviewing search UX or browse/discovery modules
- When search results feel weak, noisy, or poorly ranked
- Before changing suggestions, recent searches, empty states, or discovery rails

## Inputs
- Search screen, browse screen, or discovery modules
- Known query examples if available
- Current ranking or suggestion behavior from code

## Workflow
1. Identify the search entry flow: field behavior, suggestions, recent queries, and submit behavior.
2. Inspect how results are grouped, ranked, and rendered.
3. Check whether metadata shown in results helps disambiguate titles quickly.
4. Check empty states for zero-query, no-result, and failed-request cases.
5. Check discovery surfaces for intent coverage: trending, simulcasts, genres, continue watching, or personalized rails if present.
6. Identify cases where the user might fail to find a title because of ranking, weak aliases, or poor metadata.
7. Recommend small, practical fixes before broader ranking work.

## Output format
- Search/discovery findings ordered by severity
- Likely relevance or ranking issues
- UX gaps in suggestions, empty states, and result presentation
- Recommended next fixes

## Guardrails
- Distinguish result quality problems from rendering problems.
- Do not assume provider ordering is product-quality ranking.
- Keep recommendations product-oriented rather than API-oriented.
- Separate indexing, ranking, and presentation issues when reporting findings.
- Prefer actionable fixes over abstract relevance theory.
