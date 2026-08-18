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
  parent-files: "../execute-goals-base/SKILL.md, references/children-task-query.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from the base
skill file `../execute-goals-base/SKILL.md`, resolved relative to this file's directory. Treat its
contents as your primary global constraints, then apply the specialized rules below.

Also read `references/children-task-query.md`, resolved relative to this file's directory — it defines
the query and reconciliation rules used in `## Script` below.

# Execute Goals — Agility

Same execution contract as the base, plus an Agility reconciliation pass before any goal runs.

## When To Use

- User asks to execute or continue a goal set that traces back to an Agility Story/Defect.
- `plan-goal-breakdown-agility` has already run for this asset and its createMany Task/Test payload
  has been (or might have been) executed against Agility.
- User wants execution to reflect reality in Agility — closed/edited/deleted Tasks — rather than only
  what the local shared log says.

## Agility Context Requirement

- The asset ID is required before reconciliation can run; derive it from the goal set folder name
  (`.goals/<asset-id>-<feature-slug>/`) or ask if it can't be determined.
- Accept only `S-#####` (story) or `D-#####` (defect).

## Script

Before determining which goals still need to run, query the asset's existing Task and Test children so
local state can be reconciled against Agility. Use the `Children:Task`/`Children:Test` downcast
query documented in `references/children-task-query.md`, which is authoritative once the mirrored
payload has been executed there.

Full reconciliation rules — matching by name, how to handle closed/deleted/edited Tasks, out-of-band
additions, and query failures — are in `references/children-task-query.md`. Read it before step 1.

## Procedure Overrides

Insert a new step **before** base step 1 (Locate the goal set and confirm the branch):

0. **Reconcile against Agility.**
   - Run the `## Script` query for the asset.
   - Compare the result against the local goal files and shared log, applying the rules in
     `references/children-task-query.md`.
   - Report every diff found — even ones that don't change what happens next.
   - Update the shared log and goal-file identity/status fields to match Agility wherever they
     disagree; never let a local file's stale state override what Agility currently says.
   - If the query fails or the tool is unavailable, note that in the run summary and proceed with the
     local shared log as-is — this step must inform execution, never block it.

Base **step 2 (Read the shared log and determine what still needs to run)** now reads the log as
updated by step 0, so a goal Agility already shows Done is skipped here rather than re-executed.

## Procedure Overrides

- Add to base step 4: when the last goal's PLAN/DONE WHEN/VERIFY calls for it, refresh
  `payload.tests.<asset-id>-<feature-slug>.json` at execution time from the shared log's actual
  outcomes, verification results, and deviations — not from the goal's PLAN.

## Additional Decision Rules

- Agility wins on any disagreement between it and local files — reconcile toward Agility, never the
  reverse.
- A goal whose mirrored Task was deleted in Agility is blocked, not silently dropped or re-created —
  creating goals belongs to `plan-goal-breakdown-agility`, not this skill.
- A reconciliation query failure is informational, not a gate — proceed with the local log and say so.

## Additional Quality Bar

Beyond the base bar:

- The asset's existing Children:Task/Children:Test were queried before determining what still needs to
  run (or the query's unavailability was explicitly noted).
- Every diff between Agility and local state was reported, and local files were updated to match
  Agility for anything it disagreed with.
- No goal was executed that Agility already shows as done; no goal whose Agility Task was deleted ran
  without being surfaced as blocked first.
- `payload.tests.<asset-id>-<feature-slug>.json` was refreshed from the shared log's actual outcomes,
  verification results, and deviations when the last goal's sections called for it.

## Additional Output Contract

Beyond the base artifacts:

- The shared log may gain reconciliation notes (e.g. "outcome reconciled from Agility") in addition to
  normal execution entries.
- Goal files may have their identity/status fields (not PLAN/CONSTRAINTS/VERIFY) updated to match a
  changed Name/Description in Agility.
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json` may be refreshed
  from execution-log evidence.

## Additional Completion Checklist

- [ ] Asset's Children:Task/Children:Test queried before reading the shared log (or its unavailability
      was noted and execution proceeded on local state alone).
- [ ] Every Agility-vs-local diff was reported in the run summary.
- [ ] Local shared log and goal-file identity/status fields were updated to match Agility.
- [ ] No goal ran that Agility already showed done; no goal with a deleted Agility Task ran without
      being marked blocked first.
- [ ] `payload.tests.<asset-id>-<feature-slug>.json` was refreshed from the shared log when the last
  goal's sections required it.
