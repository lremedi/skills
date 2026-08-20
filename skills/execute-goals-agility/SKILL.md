---
name: execute-goals-agility
description: >-
  Execute a goal set already produced by plan-goal-breakdown-agility for an Agility Story/Defect.
  Before running anything, reconciles the local goal files and shared log against the asset's
  actual child Tasks/Tests in Agility (queried via Children:Task / Children:Test on the asset
  endpoint) since Agility is the source of truth once the createMany payload has been executed
  there — reports every diff and updates local files to match. Use whenever the user asks to
  execute, run, or continue goals for an Agility-linked Story/Defect (e.g. "execute S-134278",
  "run the goals for D-98765"), or points at a ".goals/" folder whose index names an Agility asset
  ID.
argument-hint: "Agility Story/Defect ID (S-##### or D-#####) whose goal set should be executed"
user-invocable: true
disable-model-invocation: false
metadata:
  id: execute-goals-agility
  inherits: execute-goals-base
  parent-files: "../execute-goals-base/SKILL.md"
  reference-files:
    - "references/children-task-query.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, read both, resolved relative to this file's directory, and treat them
as your primary global constraints:

1. `../execute-goals-base/SKILL.md` — execution contract.
2. `references/children-task-query.md` — the reconciliation query and rules used in `## Script`.

# Execute Goals — Agility

Base execution contract plus an Agility reconciliation pass before any goal runs.

## When To Use

- Executing or continuing a goal set that traces back to an Agility Story/Defect.
- `plan-goal-breakdown-agility` already ran for this asset and its createMany payload has been (or might
  have been) executed against Agility.
- User wants execution to reflect reality in Agility — closed/edited/deleted Tasks — not just the local
  log.

## Agility Context Requirement

- Asset ID required before reconciliation: derive it from the goal set folder name
  (`.goals/<asset-id>-<feature-slug>/`) or ask. `S-#####` or `D-#####` only.

## Script

Query the asset's existing Task and Test children with the `Children:Task`/`Children:Test` downcast query
in `references/children-task-query.md`, which is authoritative once the mirrored payload has run there.
Its reconciliation rules — name matching, closed/deleted/edited Tasks, out-of-band additions, query
failures — govern step 0. Read it before step 1.

## Procedure Overrides

Insert a new step **before** base step 1:

0. **Reconcile against Agility.**
   - Run the `## Script` query for the asset.
   - Compare against local goal files and the shared log per the reference's rules; report every diff,
     even ones that change nothing.
   - Update the shared log and goal-file identity/status fields wherever they disagree with Agility; a
     stale local file never overrides Agility.
   - Query failure or tool unavailable → note it in the run summary and proceed on the local log. This
     step informs execution, never blocks it.

Base **step 2** then reads the log as updated by step 0, so a goal Agility already shows Done is skipped
rather than re-executed.

Base **step 4** additionally: when the last goal's PLAN/DONE WHEN/VERIFY calls for it, refresh
`payload.tests.<asset-id>-<feature-slug>.json` from the shared log's actual outcomes, verification
results, and deviations — not from the goal's PLAN.

## Additional Decision Rules

- Agility wins any disagreement with local files — reconcile toward Agility, never the reverse.
- A goal whose mirrored Task was deleted in Agility is blocked, not dropped or re-created — creating goals
  belongs to `plan-goal-breakdown-agility`.
- A reconciliation query failure is informational, not a gate.

## Additional Quality Bar

- Children:Task/Children:Test were queried before determining what still needs to run (or the query's
  unavailability was explicitly noted and execution proceeded on local state).
- Every Agility-vs-local diff was reported, and local files were updated to match Agility.
- No goal ran that Agility already showed done; no goal with a deleted Agility Task ran without being
  surfaced as blocked first.
- `payload.tests.<asset-id>-<feature-slug>.json` was refreshed from the shared log when the last goal's
  sections called for it.

## Additional Output Contract

- The shared log may gain reconciliation notes (e.g. "outcome reconciled from Agility").
- Goal files may have identity/status fields — not PLAN/CONSTRAINTS/VERIFY — updated to match a changed
  Agility Name/Description.
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json` may be refreshed from
  execution-log evidence.
