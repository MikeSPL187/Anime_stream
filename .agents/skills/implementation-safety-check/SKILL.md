# implementation-safety-check

## Purpose
Run a practical safety checklist before and after implementation so changes stay within scope and do not silently break nearby flows.

## When to use
- Before editing code for any non-trivial task
- After implementing a bugfix, refactor, or UI change
- Before finalizing work that touches state, player flows, search, lists, or repositories

## Inputs
- User request
- Planned file list
- Validation commands available in the project

## Workflow
1. Confirm the requested scope in one sentence.
2. List the exact files expected to change before implementation.
3. Check whether the task touches shared models, repositories, routing, or reusable widgets.
4. Identify adjacent flows that could regress.
5. Implement the smallest targeted change set.
6. After implementation, compare the actual changed files against the expected scope.
7. Run the best available validation commands.
8. Report risks, unverified assumptions, and whether follow-up work is needed.

## Output format
- Scope summary
- Expected vs actual changed files
- Behavior changes and proposed behavior
- Validation performed with command results
- Risks, blockers, or follow-up items

## Guardrails
- Do not expand scope without a concrete reason.
- Do not mix opportunistic cleanup into targeted work.
- Flag any file that changed outside the original scope.
- If validation cannot be run, say so explicitly.
- If additional fixes seem necessary, describe them separately instead of silently including them.
