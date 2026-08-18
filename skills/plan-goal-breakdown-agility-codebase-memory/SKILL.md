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
  reference-files:
    - "references/agility-payloads.md"
    - "../plan-goal-breakdown-codebase-memory/references/mcp-evidence-contract.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from BOTH
parent skill files, resolved relative to this file's directory:

1. `../plan-goal-breakdown-base/SKILL.md` — the process and output contract.
2. `../codebase-memory/SKILL.md` — the knowledge-graph tool reference.

Treat their contents as your primary global constraints, then apply the specialized rules below.
Where they overlap, follow the precedence order in the base skill's Inheritance Contract.

Also read `references/agility-payloads.md` and
`../plan-goal-breakdown-codebase-memory/references/mcp-evidence-contract.md`, resolved relative to
this file's directory — they define the shared Agility payload and codebase-memory evidence rules.

# Plan Goal Breakdown Agility (Codebase Memory)

Same goal-file contract as the base, plus Agility MCP context and payload artifacts **and**
graph-based code discovery via codebase-memory MCP.

## When To Use

- User asks to plan implementation from an Agility Story/Defect.
- User wants commit-sized goals plus child Task/Test payload files generated during goal creation.
- User wants manual tests generated from implementation evidence in the shared log file.
- Team wants code navigation based on codebase-memory MCP rather than grep-first exploration.

The shared codebase-memory navigation, evidence, and index-prerequisite rules are defined in
`../plan-goal-breakdown-codebase-memory/references/mcp-evidence-contract.md`.

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

The shared code-navigation, evidence, and index-prerequisite rules are defined in
`../plan-goal-breakdown-codebase-memory/references/mcp-evidence-contract.md`; its Agility-only
additions apply here.

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

Apply the shared Agility payload artifact, mirror, Task/Test payload, and validation rules from
`references/agility-payloads.md`.

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
- Every goal meets the shared MCP evidence contract: project, graph entities, source provenance, concrete
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
