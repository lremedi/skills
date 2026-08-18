---
name: plan-goal-breakdown-agility
description: "Break a Story/Defect into dependency-aware, commit-sized goals and mirror them to Agility child Tasks and log-derived child Tests via user-executed createMany payloads."
argument-hint: "Story/Defect number + objective + scope constraints + user context (project folder/domain)"
user-invocable: true
disable-model-invocation: false
metadata:
  id: plan-goal-breakdown-agility
  inherits: plan-goal-breakdown-base
  parent-files: "../plan-goal-breakdown-base/SKILL.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from the base
skill file `../plan-goal-breakdown-base/SKILL.md`, resolved relative to this file's directory. Treat
its contents as your primary global constraints, then apply the specialized rules below.

# Plan Goal Breakdown Agility

Same goal-file contract as the base, plus Agility MCP context fetching and createMany payload
artifacts that mirror goals to child Tasks and manual QE Tests.

## When To Use

- User asks to plan implementation from an Agility Story/Defect.
- User wants commit-sized goals plus child Task/Test payload files generated during goal creation.
- User wants manual tests generated from implementation evidence in the shared log file.

## Additional Inputs To Collect

In addition to the base inputs (the Agility asset number is promoted to the first thing you ask for):

- User context: folder/domain/repo area that affects decomposition.

## Agility Context Requirement

- The asset number is mandatory before materializing goals.
- Accept only `S-#####` (story) or `D-#####` (defect).
- Fetch the parent asset title and description through Agility MCP using the provided asset number.
- Use fetched asset context plus user context to shape decomposition and naming quality.

## Procedure Overrides

Base **step 1 (Discover context)** keeps every bullet it already has, including the protected-branch
check and the working-branch confirmation. Apply exactly two bullet-level changes:

- **Prepend** a bullet: fetch the Story/Defect title and description using Agility MCP by asset
  number.
- **Replace** the bullet `Inspect branch/workspace changes relevant to the requested plan` with
  "Inspect workspace context and user-provided folder/domain constraints."

In base **step 2 (Extract decision points)**, the verification scope to confirm is manual QE
(human-executed, user-facing where possible) plus what is deferred.

Insert the following steps between base step 5 (Materialize goal files) and base step 6 (Create plan
index):

6. Create Agility payload files as part of goal creation.

- Generate and save two createMany-compatible JSON payload files in the same goals folder:
  - `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
  - `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`
- These files are required artifacts and must be produced in the same run that creates goal files.

Agility goal mirror rule (required):

- Treat Agility child Tasks as the mirrored representation of goal files.
- Mirror only the `NN-*` goal files: create exactly one Task payload item per goal file, excluding the
  index, the log, `pr-description.md`, and the payload JSONs.
- Task `Description` must contain the full goal content converted to XHTML, preserving all goal
  sections and dependency metadata.
- Do not collapse a goal to a short summary in Task `Description`.

7. Build and save child Task payload.

- Create a createMany-compatible POST body array draft where each goal maps to one child Task.
- Use only this field structure for each item:
  - `AssetType`: `Task`
  - `Name`: goal-aligned title derived from the goal objective (include goal sequence/slug when
    useful for traceability)
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

8. Build and save child Test payload.

- Create the initial tests payload file during planning from goal acceptance criteria as manual QE
  scenarios.
- Update/refine the same tests payload after implementation using
  `.goals/<asset-id>-<feature-slug>/log.<asset-id>-<feature-slug>.md` outcomes, verification
  results, and deviations.
- Create a createMany-compatible POST body array for child Tests using only:
  - `AssetType`: `Test`
  - `Name`: manual QE test title
  - `Description`: XHTML-safe manual QE steps and acceptance checks executed by a human tester
  - `Parent`: Story/Defect number token (example `S-01004`)
- Save this JSON into `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`.
- Trigger rule: completion of the final goal in the markdown planning flow is the LLM control signal
  to refresh the tests payload from execution-log evidence.
- Do not add a special "last task" field in Agility payloads.
- Do not include unit-test, integration-test, or e2e automation instructions in test payload entries.
- If a goal has no direct user-facing behavior, produce manual smoke/regression checks for the
  affected surface (for example, startup, key flow sanity, and no-regression navigation).

Test payload pattern:

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

Then continue with base step 6 (Create plan index) and base step 7 (Validate quality), adding these
validations to step 7:

- Ensure both payload files exist and follow the required Task/Test structure exactly.
- Ensure the tasks payload contains a 1:1 mapping between goal files and Task items.
- Ensure each Task `Description` is XHTML and contains the full mirrored goal content, not a summary.
- Ensure test payload entries are manual QE, human-executed checks (not unit/integration/e2e
  automation items).
- Ensure each test emphasizes user-facing behavior; when not available, ensure smoke/regression
  sanity checks are provided.
- Ensure the test payload is initially created during planning and later refreshable from
  implementation log evidence.

## Additional Decision Rules

- If Agility payload examples conflict with the required fields, prefer the required field structure
  in this skill.

## Additional Quality Bar

Beyond the base bar:

- Child Task payload file exists and uses only `AssetType`, `Name`, `Description`, `Parent`.
- Child Task payload has one Task per goal file (excluding index/log).
- Each Task `Description` is XHTML containing the full mirrored goal content.
- Child Test payload file exists and uses only `AssetType`, `Name`, `Description`, `Parent`.
- Child Test payload entries are manual QE, human-executed checks only (no unit/integration/e2e
  automation instructions).
- Child Test payload prioritizes user-facing validation and falls back to smoke/regression checks
  where no user-facing behavior exists.
- Tests payload file is created during goal generation and can be refreshed from implementation log
  evidence after final-goal completion.
- API execution remains the user's responsibility.

## Additional Output Contract

Beyond the base artifacts, in the same goals folder:

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`

## Additional Completion Checklist

- [ ] Parent asset title and description fetched via Agility MCP.
- [ ] Child Task payload file created with required field structure.
- [ ] Child Task payload has one Task per goal file (excluding index/log).
- [ ] Each Task `Description` contains full mirrored goal content in XHTML.
- [ ] Child Test payload file created with required field structure.
- [ ] Child Test payload contains only manual QE, human-executed checks (no unit/integration/e2e
      automation instructions).
- [ ] Child Test payload prioritizes user-facing behavior validation and uses smoke/regression
      checks when user-facing flows do not exist.
- [ ] Final-goal completion used as the LLM trigger to refresh the test payload from implementation
      log evidence.
