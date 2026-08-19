# Agility Payload Artifacts

Shared reference for: `plan-goal-breakdown-agility`, `plan-goal-breakdown-agility-codebase-memory`.

## Payload Files

Required artifacts, produced in the same run that creates the goal files:

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`

Both are createMany-compatible POST body arrays sharing one item shape; the user executes the API request.

```json
[
  {
    "AssetType": "Task",
    "Name": "New Task",
    "Description": "xhtml description",
    "Parent": "S-01004"
  },
  {
    "AssetType": "Task",
    "Name": "New Task2",
    "Description": "xhtml description2",
    "Parent": "S-01004"
  }
]
```

Use only those four fields — no extra mirroring metadata, no special "last task" field. `AssetType` is
`Task` in the tasks payload and `Test` in the tests payload; `Parent` is the Story/Defect number token.

## Child Task Payload

- Agility child Tasks are the mirrored representation of goal files: exactly one Task item per `NN-*` goal
  file, excluding the index, the log, `pr-description.md`, and the payload JSONs.
- `Name`: goal-aligned title from the goal objective (include sequence/slug when it helps traceability).
- `Description`: XHTML full-fidelity mirror of the goal file — every section and the dependency metadata.
  Never collapse a goal to a summary.

## Child Test Payload

- `Name`: manual QE test title. `Description`: XHTML manual QE steps and acceptance checks a human tester
  executes.
- Created during planning from goal acceptance criteria as manual QE scenarios, then refreshed after
  implementation from `log.<asset-id>-<feature-slug>.md` outcomes, verification results, and deviations.
  Trigger: the final goal's PLAN/DONE WHEN/VERIFY carries the instruction for the executing Agility skill
  to refresh it at execution time from execution-log evidence.
- No unit-test, integration-test, or e2e automation instructions.
- Every entry traces to a specific goal's change. A goal with no user-facing behavior gets manual
  smoke/regression checks for the affected surface only (startup, key flow sanity, no-regression
  navigation) — never a general pass over untouched features.

## Payload Validations

Add to the plan's quality step:

- Both files exist and follow the required field structure exactly.
- Tasks payload maps 1:1 with goal files; each Task `Description` is XHTML carrying the full mirrored goal
  content, not a summary.
- Test entries are manual QE, human-executed checks, each tracing to a goal's change, emphasizing
  user-facing behavior and falling back to scoped smoke/regression only where none exists. No entry asks a
  tester to exercise behavior no goal touched.
- The tests payload was created during planning and stays refreshable from implementation log evidence.
