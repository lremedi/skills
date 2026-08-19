# Agility Reconciliation — Children:Task / Children:Test Query

Shared reference for: `execute-goals-agility`, `execute-goals-agility-codebase-memory`.

## Why

`plan-goal-breakdown-agility` mirrors each goal file to a child Task (and each manual QE scenario to a
child Test) via a createMany payload the user executes. Once it runs, **Agility is the source of truth**:
someone can close, edit, or delete a Task there and the local files have no way to know.

So before executing: pull the asset's actual children, compare with local goal files and the shared log,
report every difference, and update local files to agree with Agility — never the reverse. The sync is
one-way; executors never write to Agility. Closing a Task is a human action, and the closed-in-Agility rule
below is how that decision reaches the goal set on the next run.

## Query

VersionOne exposes children through the asset's `Children` relation; downcasting to one type at a time
returns only that subtype (same pattern as `Workitems:Story`). Contract:
https://versionone.github.io/api-docs/#restv1Data-create

Ask the Agility MCP asset/data query tool for this shape — adapt parameter names to its actual signature,
but keep `from`, `where`, and the `Children:Task`/`Children:Test` selects:

```typescript
{
  from: "Story",                   // or "Defect" — must match the asset ID prefix (S- / D-)
  where: { "Number": "S-01004" },  // the asset number the goal set folder is named after
  select: [
    "Children:Task.Number",
    "Children:Task.Name",
    "Children:Task.Description",
    "Children:Task.AssetState",
    "Children:Test.Number",
    "Children:Test.Name",
    "Children:Test.Description",
    "Children:Test.AssetState",
  ],
}
```

## Reconciliation rules

Match children to local goals by name — the goal-aligned title used in `payload.tasks.*.json` /
`payload.tests.*.json`. Agility wins every time:

- **Closed/done in Agility, local log says pending/blocked/partial** → append a shared-log entry noting the
  outcome was reconciled from Agility (Task number and current status) and skip local execution. No local
  commit hash on record → say so explicitly rather than inventing one.
- **Missing or dead (`AssetState: 255`) in Agility, local files still reference it** → mark the goal
  ❌ blocked in the shared log noting the mirrored Task was removed, and surface it in the run summary. A
  human deleted it; a human decides what happens to the goal. Never silently drop or "fix" the goal file.
- **Different Name/Description than the local mirror** → record the current Agility Name/Description as
  authoritative in the goal file's context/notes and report the diff (local said X, Agility says Y). Only
  identity/status fields change; PLAN/CONSTRAINTS/VERIFY remain the execution contract.
- **Exists in Agility with no local goal file** → report as an out-of-band addition. Never invent a goal
  file; creating goals is `plan-goal-breakdown-agility`'s job.
- **Query error or tool unavailable** → say so in the run summary and proceed on the local shared log. This
  check keeps local state honest when it works; it never blocks execution when it doesn't.

Report every diff, including ones that change nothing — the point is that no Agility-vs-local gap passes
silently.
