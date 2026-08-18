# Agility Reconciliation — Children:Task / Children:Test Query

Shared reference for: `execute-goals-agility`, `execute-goals-agility-codebase-memory`.

## Why this exists

`plan-goal-breakdown-agility` mirrors each goal file to a child Task (and each manual QE scenario to a
child Test) on the Story/Defect, via a createMany payload the user executes against Agility. Once that
payload runs, **Agility becomes the source of truth** for those Tasks/Tests — someone can close a Task,
edit its description, or delete it directly in Agility, and the local goal files and shared log have no
way to know that happened on their own.

Before executing anything, reconcile: pull the asset's actual child Tasks/Tests, compare them against
what the local goal files and shared log currently say, report every difference found, and update the
local files so they agree with Agility — never the other way around.

This sync is deliberately one-way: executors never write to Agility. Closing a Task is a human action;
the closed-in-Agility reconciliation rule below is how that decision reaches the goal set on the next
run.

## What to ask the Agility MCP for

VersionOne exposes a Story/Defect's Task and Test children through its `Children` relation. Downcasting
that relation to one type at a time (`Children:Task`, `Children:Test`) returns only that subtype — the
same pattern the API uses to get only Stories out of a Scope's Workitems (`Workitems:Story`). See the
asset endpoint reference for the underlying contract: https://versionone.github.io/api-docs/#restv1Data-create

Ask the Agility MCP's asset/data query tool for this shape — adapt parameter names to whatever that
tool's actual signature is, but keep the `from`, `where`, and `Children:Task`/`Children:Test` parts:

```typescript
{
  from: "Story",                   // or "Defect" — must match the asset ID prefix (S- / D-)
  where: { "Number": "S-01004" },  // the Agility asset number the goal set folder is named after
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

Match returned children to local goals by name — the same goal-aligned title
`plan-goal-breakdown-agility` used when it drafted `payload.tasks.*.json`/`payload.tests.*.json`. For
each match (or lack of one), Agility wins:

- **Task closed/done in Agility, local log says pending/blocked/partial.** Append a shared-log entry
  for that goal noting the outcome was reconciled from Agility (state the Task number and its current
  status), and skip local execution of that goal — do not re-run work Agility already shows finished.
  If no commit hash is on record locally, say so explicitly in the log entry rather than inventing one.
- **Task missing or dead (`AssetState: 255`) in Agility, local files still reference it.** Do not
  silently drop or "fix" the goal file. Mark the goal ❌ blocked in the shared log with a note that its
  mirrored Task was removed in Agility, and surface it in the run summary — a human decided to delete
  it, so a human should decide what happens to the goal too.
- **Task exists in Agility with a different Name/Description than the local goal file's mirrored
  content.** Update the local goal file's context/notes to record the current Agility Name/Description
  as authoritative, and report the diff plainly (what the local copy said vs. what Agility now says).
  Do not rewrite the goal's PLAN/CONSTRAINTS/VERIFY sections from this — those remain the execution
  contract; only the identity/status fields being reconciled change.
- **A Task/Test exists in Agility with no corresponding local goal file at all.** Report it in the run
  summary as an out-of-band addition. Do not invent a new goal file for it — creating goals is
  `plan-goal-breakdown-agility`'s job, not this skill's.
- **Query errors or the tool is unavailable.** Say so in the run summary and proceed with the local
  shared log as-is. This check exists to keep local state honest when it works; it must never block
  execution when it doesn't.

Always report every diff found, even ones that don't change what you do next — the point is that
nothing about the Agility-vs-local gap happens silently.
