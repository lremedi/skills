---
name: plan-goal-breakdown-codebase-memory
description: "Break a feature/refactor plan into dependency-aware, commit-sized goal files using codebase-memory MCP for code discovery (no grep-first exploration)."
argument-hint: "Task to decompose + scope constraints + preferred goals folder + project name if needed"
user-invocable: true
disable-model-invocation: false
metadata:
  id: plan-goal-breakdown-codebase-memory
  inherits: "plan-goal-breakdown-base, codebase-memory"
  parent-files: "../plan-goal-breakdown-base/SKILL.md, ../codebase-memory/SKILL.md"
  reference-files:
    - "references/mcp-evidence-contract.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from BOTH
parent skill files, resolved relative to this file's directory:

1. `../plan-goal-breakdown-base/SKILL.md` — the process and output contract.
2. `../codebase-memory/SKILL.md` — the knowledge-graph tool reference.

Treat their contents as your primary global constraints, then apply the specialized rules below.
Where they overlap, follow the precedence order in the base skill's Inheritance Contract.

Also read `references/mcp-evidence-contract.md`, resolved relative to this file's directory — it
defines the shared codebase-memory navigation, evidence, and index-prerequisite rules.

# Plan Goal Breakdown (Codebase Memory)

Same goal-file contract as the base, with code discovery driven by the codebase-memory knowledge
graph instead of grep-first exploration.

## When To Use

- User asks to "plan this", "break into goals", "make commit-sized goals", or "persist goals in
  files".
- Work needs dependency ordering and safe parallel execution.
- Team wants deterministic implementation slices, each with clear done criteria.
- Codebase discovery should be graph-based via codebase-memory MCP, not grep-first exploration.

The shared code-navigation, evidence, and index-prerequisite rules are defined in
`references/mcp-evidence-contract.md`.

## Additional Inputs To Collect

In addition to the base inputs:

8. Codebase-memory project name: required when the project cannot be inferred from workspace/repo
   context.

## Procedure Overrides

Base **step 1** keeps every bullet it already has, including the protected-branch check and the
working-branch confirmation. Retitle it "Verify indexing and discover context" and apply exactly two
bullet-level changes:

- **Prepend** a bullet: validate that the codebase-memory project exists and is indexed (see Index
  Prerequisite). This gates everything after it.
- **Replace** the bullet `Identify current architecture touchpoints and likely files affected` with
  graph exploration:
  - high-level map: `get_architecture`
  - symbol discovery: `search_graph`
  - dependency/caller chains: `trace_path`
  - exact source extraction: `get_code_snippet`
  - impact of existing local edits: `detect_changes`

In base **step 7 (Validate quality)**, read manifest files generally rather than `package.json`
specifically. Add these validations:

- Ensure every goal satisfies the MCP Evidence Contract and contains no generic discovery
  placeholders.
- Ensure every planned MCP query identifies a concrete project and graph target, and every
  verification query re-checks a named relationship affected by the goal.
- Ensure every material supplied description and code reference used in a goal has a documented
  MCP confirmation or correction; reject a goal that treats request text as current-code evidence.
- Reject goals whose context lacks source provenance from `get_code_snippet`, `search_graph`,
  `trace_path`, `get_architecture`, or `detect_changes`.

Every other bullet and step is inherited unchanged.

## Goal Template Overrides

Keep the base template structure exactly; replace only these bracket bodies:

- The inherited validation-ledger requirement is not replaced by the bodies below. Every `🧠 CONTEXT`
  must identify the supplied claim/reference, the MCP tool and named entity/snippet used to validate
  it, and its confirmed or corrected current-code fact. An unresolved claim blocks materialization.
- `🧠 CONTEXT:` → `[State the codebase-memory project, concrete graph findings, and source provenance for this goal. Name the symbols/modules/routes and caller/callee or dependency relationship that constrain the change.]`
- `🗺️ PLAN:` → `[Begin with concrete codebase-memory MCP actions. For each action, name the project, symbol/module/path target, tool, expected result, and decision it unlocks. Only then list narrow edits in MCP-identified files.]`
- `🔍 VERIFY:` → `[Re-run a concrete MCP relationship check for the exact graph entities changed or affected, then state runnable commands and deterministic manual checks.]`

## Additional Decision Rules

- If architecture is unclear: use additional codebase-memory graph exploration before drafting goals.
- If indexing is unavailable: stop and ask the user to index (do not substitute broad grep
  exploration).

The base rule "if architecture is unclear, run read-only exploration first" is superseded by the
graph-exploration rule above.

## Additional Quality Bar

Beyond the base bar:

- Code discovery and dependency tracing are driven by codebase-memory MCP.
- Every goal meets the shared MCP evidence contract: project, graph entities, source provenance, concrete
  MCP plan queries, and an MCP relationship re-check are all present.
- Every material supplied description and code reference is validated against current indexed code by
  MCP and is either confirmed or explicitly corrected before it appears in a goal.
- No materialized goal uses generic discovery or implementation directions without specific
  codebase-memory targets and decisions.
- If the project is not indexed, the skill halts and requests user indexing before planning
  continues.

## Additional Completion Checklist

- [ ] Codebase-memory project identified and indexing verified.
- [ ] If index missing/unhealthy, user was asked to index before planning continued.
- [ ] Every goal cites concrete codebase-memory entities and source provenance.
- [ ] Every material supplied description and code reference has concrete MCP confirmation or an
  explicit correction in the goal context; unresolved claims stopped planning for clarification.
- [ ] Every goal begins its plan with target-specific MCP navigation and ends verification with a
  named MCP relationship re-check.
- [ ] Generic or placeholder discovery instructions were rejected before goals were materialized.
