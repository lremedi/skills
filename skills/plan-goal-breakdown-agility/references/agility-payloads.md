# Agility Payload Artifacts

Shared reference for: `plan-goal-breakdown-agility`, `plan-goal-breakdown-agility-codebase-memory`.

## Payload Files

Create Agility payload files as part of goal creation. Generate and save two createMany-compatible JSON payload files in the same goals folder:

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`

These files are required artifacts and must be produced in the same run that creates goal files.

## Agility Goal Mirror Rule

- Treat Agility child Tasks as the mirrored representation of goal files.
- Mirror only the `NN-*` goal files: create exactly one Task payload item per goal file, excluding the index, the log, `pr-description.md`, and the payload JSONs.
- Task `Description` must contain the full goal content converted to XHTML, preserving all goal sections and dependency metadata.
- Do not collapse a goal to a short summary in Task `Description`.

## Child Task Payload

Create a createMany-compatible POST body array draft where each goal maps to one child Task.

- Use only this field structure for each item:
  - `AssetType`: `Task`
  - `Name`: goal-aligned title derived from the goal objective (include goal sequence/slug when useful for traceability)
  - `Description`: XHTML-safe full-fidelity mirror of the corresponding goal file content
  - `Parent`: Story/Defect number token (example `S-01004`)
- Do not add extra mirroring metadata fields.
- Save this JSON into `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`.
- User executes the API request using the generated file.

Task payload pattern:

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

## Child Test Payload

- Create the initial tests payload file during planning from goal acceptance criteria as manual QE scenarios.
- Update/refine the same tests payload after implementation using `.goals/<asset-id>-<feature-slug>/log.<asset-id>-<feature-slug>.md` outcomes, verification results, and deviations.
- Create a createMany-compatible POST body array for child Tests using only:
  - `AssetType`: `Test`
  - `Name`: manual QE test title
  - `Description`: XHTML-safe manual QE steps and acceptance checks executed by a human tester
  - `Parent`: Story/Defect number token (example `S-01004`)
- Save this JSON into `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`.
- Trigger rule: the final goal's PLAN/DONE WHEN/VERIFY carries the instruction for the executing Agility skill to refresh the tests payload at execution time from execution-log evidence.
- Do not add a special "last task" field in Agility payloads.
- Do not include unit-test, integration-test, or e2e automation instructions in test payload entries.
- Scope every entry to behavior this asset's goals actually change: each entry must trace to a specific goal's change, and the smoke/regression fallback covers only the touched area, never a general pass over untouched features.
- If a goal has no direct user-facing behavior, produce manual smoke/regression checks for the affected surface (for example, startup, key flow sanity, and no-regression navigation).

Test payloads share the Task payload shape:

```json
[
  {
    "AssetType": "Test",
    "Name": "New Test",
    "Description": "xhtml description",
    "Parent": "S-01004"
  },
  {
    "AssetType": "Test",
    "Name": "New Test2",
    "Description": "xhtml description2",
    "Parent": "S-01004"
  }
]
```

## Payload Validations

Add these validations to the plan's quality step:

- Ensure both payload files exist and follow the required Task/Test structure exactly.
- Ensure the tasks payload contains a 1:1 mapping between goal files and Task items.
- Ensure each Task `Description` is XHTML and contains the full mirrored goal content, not a summary.
- Ensure test payload entries are manual QE, human-executed checks (not unit/integration/e2e automation items).
- Ensure each test emphasizes user-facing behavior; when not available, ensure smoke/regression sanity checks are provided.
- Ensure each entry traces to a specific goal's change and that no entry asks a tester to exercise behavior no goal touched.
- Ensure the test payload is initially created during planning and later refreshable from implementation log evidence.
