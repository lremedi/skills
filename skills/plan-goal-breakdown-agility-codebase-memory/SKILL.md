---
name: plan-goal-breakdown-agility-codebase-memory
description: "Break a Story/Defect into dependency-aware, commit-sized goals and mirror to Agility Tasks/Tests using codebase-memory MCP for code navigation."
argument-hint: "Story/Defect number + objective + scope constraints + user context (project folder/domain) + project name if needed"
user-invocable: true
disable-model-invocation: false
metadata:
  id: plan-goal-breakdown-agility-codebase-memory
  inherits: "plan-goal-breakdown-base, codebase-memory"
  parent-files: "../plan-goal-breakdown-base/SKILL.md, ../codebase-memory/SKILL.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from BOTH
parent skill files, resolved relative to this file's directory:

1. `../plan-goal-breakdown-base/SKILL.md` — the process and output contract.
2. `../codebase-memory/SKILL.md` — the knowledge-graph tool reference.

Treat their contents as your primary global constraints, then apply the specialized rules below.
Where they overlap, follow the precedence order in the base skill's Inheritance Contract.

# Plan Goal Breakdown Agility (Codebase Memory)

Same goal-file contract as the base, plus Agility MCP context and payload artifacts **and**
graph-based code discovery via codebase-memory MCP.

## When To Use

- User asks to plan implementation from an Agility Story/Defect.
- User wants commit-sized goals plus child Task/Test payload files generated during goal creation.
- User wants manual tests generated from implementation evidence in the shared log file.
- Team wants code navigation based on codebase-memory MCP rather than grep-first exploration.

## Code Navigation Policy (Required)

- Use codebase-memory MCP as the primary way to understand architecture and dependencies.
- Tool selection, call syntax, workflows, and gotchas come from the inherited `codebase-memory`
  skill — use its Quick Decision Matrix and Exploration/Tracing Workflows rather than restating tool
  signatures here.
- Do not perform broad grep/rg scans to map architecture or call paths.
- Text search (`search_code` or Grep) can be used only for narrow confirmation after graph-driven
  discovery.

## Goal Authoring Policy (MCP-First, Required)

- Every generated goal must actively direct MCP-first exploration/execution, not just planning-time
  discovery.
- Each goal's `🧠 CONTEXT` must reference findings from codebase-memory exploration relevant to that
  goal.
- Each goal's `🗺️ PLAN` must start with MCP-based navigation steps before any narrow file-level
  confirmation.
- Each goal's `🔍 VERIFY` must include at least one MCP-based validation step (for example,
  dependency/caller re-check via graph tools) plus implementation checks.
- Do not author goals that instruct broad grep-first exploration.

## MCP Evidence Contract (Required)

Goals produced by this skill are execution instructions backed by the codebase-memory graph and
Agility asset evidence. They must not be generic implementation summaries.

- Treat every user-provided description, acceptance criterion, file path, symbol, architecture
  claim, and code reference as an unverified hypothesis. The fetched Agility description is also
  unverified implementation context. Before using any of these claims in a goal, validate it against
  the indexed current code with codebase-memory MCP; neither request text nor Agility text proves
  the current implementation.
- For each material supplied or Agility-derived claim used by a goal, record whether MCP evidence
  confirms it, corrects it, or leaves it unresolved. Cite the project, MCP tool, graph entity or
  source snippet, and the resulting current-code fact. Resolve an unresolved claim with the smallest
  additional MCP query or ask the user; never silently carry it into a materialized goal or payload.
- Before drafting, collect goal-specific evidence with `get_architecture`, `search_graph`,
  `trace_path`, and `get_code_snippet` as applicable. Record the concrete project, symbol/module,
  relationship, and source location or snippet returned by MCP.
- Every goal must name the codebase-memory project and at least one real graph entity discovered for
  that goal. A graph entity can be a symbol, route, module, type, caller, callee, dependency edge,
  or changed-file impact result.
- In every `🗺️ PLAN`, write the first one or more steps as executable MCP navigation actions. Each
  action must name its intended query/target and expected decision, for example: `search_graph` for
  `OrderService` in project `shop` to identify its command handler; `trace_path` from that handler
  to `OrderRepository` before changing persistence behavior.
- In every `🔍 VERIFY`, use MCP to re-check the exact affected caller/callee or dependency path,
  naming the source and target graph entities. Pair this with required manual QE and relevant
  implementation checks.
- A goal may only name a file after MCP identified it or after a narrow confirmation of an
  MCP-identified file. State that provenance in `🧠 CONTEXT`.
- Reject and rewrite statements such as "inspect the architecture", "find the relevant files",
  "update the service", "trace dependencies", or "verify impact" when they do not name an MCP
  project, target entity, relationship, and decision. Do not use placeholders such as
  `<symbol>`, `<file>`, or "as needed" in a materialized goal.

## Index Prerequisite (Hard Gate)

This tightens the inherited Exploration Workflow's first step into a blocking gate. Before planning
starts:

1. Check indexed projects with `list_projects`.
2. Validate project status with `index_status` when needed.
3. If the target codebase is not indexed or the index is incomplete/failed:
   - Halt planning.
   - Ask the user to index the repository first.
   - Suggested user action: run `index_repository` for the repo.
   - Continue only after the user confirms indexing is complete.

Do not silently continue with fallback grep-based discovery.

## Additional Inputs To Collect

In addition to the base inputs (the Agility asset number is promoted to the first thing you ask for):

- User context: folder/domain/repo area that affects decomposition.
- Codebase-memory project name: required when it cannot be inferred from workspace/repo context.

## Agility Context Requirement

- The asset number is mandatory before materializing goals.
- Accept only `S-#####` (story) or `D-#####` (defect).
- Fetch the parent asset title and description through Agility MCP using the provided asset number.
- Use fetched asset context plus user context and codebase-memory findings to shape decomposition and
  naming quality.

## Procedure Overrides

Base **step 1** keeps every bullet it already has, including the protected-branch check and the
working-branch confirmation. Retitle it "Verify indexing and discover context" and apply exactly
three bullet-level changes:

- **Prepend** a bullet: verify the codebase-memory project is indexed (see Index Prerequisite). This
  gates everything after it.
- **Prepend** a bullet: fetch the Story/Defect title and description using Agility MCP by asset
  number.
- **Replace** the bullet `Inspect branch/workspace changes relevant to the requested plan` with
  "Inspect workspace context and user-provided folder/domain constraints", and the bullet
  `Identify current architecture touchpoints and likely files affected` with graph exploration:
  - architecture overview: `get_architecture`
  - symbols/modules: `search_graph`
  - caller/callee/impact: `trace_path`
  - concrete code context: `get_code_snippet`
  - impact of existing local edits: `detect_changes`

In base **step 2 (Extract decision points)**, the verification scope to confirm is manual QE
(human-executed, user-facing where possible) plus what is deferred.

In base **step 3 (Decompose into goals)**, additionally embed MCP-first execution instructions in
each goal so implementers follow codebase-memory navigation during execution.

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
- Trigger rule: the final goal's PLAN/DONE WHEN/VERIFY carries the instruction for the
  `execute-goals-agility-codebase-memory` skill running the set to refresh the tests payload at
  execution time from execution-log evidence.
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
- Ensure every goal satisfies the MCP Evidence Contract and contains no generic discovery
  placeholders.
- Ensure every planned MCP query identifies a concrete project and graph target, and every
  verification query re-checks a named relationship affected by the goal.
- Ensure every material supplied or Agility-derived description and code reference used in a goal
  has a documented MCP confirmation or correction; reject a goal or payload that treats asset text
  as current-code evidence.
- Ensure each Task payload's full XHTML goal mirror preserves the concrete MCP context, plan, and
  verification instructions.

## Goal Template Overrides

Keep the base template structure exactly; replace only these bracket bodies:

- The inherited validation-ledger requirement is not replaced by the bodies below. Every `🧠 CONTEXT`
  must identify the supplied or Agility-derived claim/reference, the MCP tool and named entity/snippet
  used to validate it, and its confirmed or corrected current-code fact. An unresolved claim blocks
  materialization of both the goal and its mirrored Task payload.
- `🧠 CONTEXT:` → `[State the Agility requirement plus the codebase-memory project, concrete graph findings, and source provenance for this goal. Name the symbols/modules/routes and caller/callee or dependency relationship that constrain the change.]`
- `🗺️ PLAN:` → `[Begin with concrete codebase-memory MCP actions. For each action, name the project, symbol/module/path target, tool, expected result, and decision it unlocks. Only then list narrow edits in MCP-identified files.]`
- `🔍 VERIFY:` → `[Re-run a concrete MCP relationship check for the exact graph entities changed or affected, then state runnable commands and deterministic manual QE checks.]`

## Additional Decision Rules

- If architecture is unclear, run additional codebase-memory graph exploration before drafting.
- If indexing is unavailable, stop and ask the user to index the codebase before continuing.
- If a drafted goal implies broad grep-first discovery, rewrite it to MCP-first steps before
  finalizing.
- If Agility payload examples conflict with the required fields, prefer the required field structure
  in this skill.

The base rule "if architecture is unclear, run read-only exploration first" is superseded by the
graph-exploration rule above.

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
- Code discovery uses codebase-memory MCP.
- Every goal explicitly instructs MCP-first execution (context, plan, and verify), not grep-first
  exploration.
- Every goal meets the MCP Evidence Contract: project, graph entities, source provenance, concrete
  MCP plan queries, and an MCP relationship re-check are all present.
- Every material supplied or Agility-derived description and code reference is validated against
  current indexed code by MCP and is either confirmed or explicitly corrected before it appears in a
  goal or mirrored Task payload.
- No materialized goal uses generic discovery or implementation directions without specific
  codebase-memory targets and decisions.
- If the project is not indexed, planning halts and the user is asked to index first.
- API execution remains the user's responsibility.

## Additional Output Contract

Beyond the base artifacts, in the same goals folder:

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`

## Additional Completion Checklist

- [ ] Parent asset title and description fetched via Agility MCP.
- [ ] Codebase-memory project identified and index status verified.
- [ ] If index missing/unhealthy, user was asked to index before planning continued.
- [ ] Child Task payload file created with required field structure.
- [ ] Child Task payload has one Task per goal file (excluding index/log).
- [ ] Each Task `Description` contains full mirrored goal content in XHTML.
- [ ] Child Test payload file created with required field structure.
- [ ] Child Test payload contains only manual QE, human-executed checks (no unit/integration/e2e
      automation instructions).
- [ ] Child Test payload prioritizes user-facing behavior validation and uses smoke/regression
      checks when user-facing flows do not exist.
- [ ] The last goal's PLAN/DONE WHEN/VERIFY carries the execution-time tests-payload refresh
  instruction.
- [ ] Every goal includes MCP-first execution guidance in `🧠 CONTEXT`, `🗺️ PLAN`, and `🔍 VERIFY`.
- [ ] Every goal cites concrete codebase-memory entities and source provenance.
- [ ] Every material supplied or Agility-derived description and code reference has concrete MCP
  confirmation or an explicit correction in the goal context; unresolved claims stopped planning
  for clarification.
- [ ] Every goal begins its plan with target-specific MCP navigation and ends verification with a
  named MCP relationship re-check.
- [ ] Generic or placeholder discovery instructions were rejected before goals were materialized.
