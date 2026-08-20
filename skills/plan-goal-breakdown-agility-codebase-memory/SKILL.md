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

Before processing any user request, read all four, resolved relative to this file's directory, and treat
them as your primary global constraints (on overlap, follow the base's precedence order):

1. `../plan-goal-breakdown-base/SKILL.md` — process and output contract.
2. `../codebase-memory/SKILL.md` — knowledge-graph tool reference.
3. `references/agility-payloads.md` — payload artifacts, mirror rules, validations.
4. `../plan-goal-breakdown-codebase-memory/references/mcp-evidence-contract.md` — navigation, evidence,
   and index-prerequisite rules, including its Agility-only additions.

# Plan Goal Breakdown Agility (Codebase Memory)

Base goal-file contract plus Agility MCP context and payload artifacts **and** graph-based code
discovery via codebase-memory MCP.

## When To Use

- Planning implementation from an Agility Story/Defect.
- User wants child Task/Test payload files generated during goal creation.
- User wants manual tests generated from shared-log implementation evidence.
- Code navigation should be codebase-memory MCP, not grep-first.

## Goal Authoring Policy (MCP-First, Required)

Generated goals must direct MCP-first execution, not just planning-time discovery:

- `🧠 CONTEXT` cites codebase-memory findings relevant to that goal.
- `🗺️ PLAN` starts with MCP navigation before any file-level confirmation.
- `🔍 VERIFY` includes at least one MCP validation step (e.g. dependency/caller re-check) plus
  implementation checks.
- Never author a goal that instructs broad grep-first exploration.

## Additional Inputs To Collect

The Agility asset number is promoted to the first thing you ask for.

9. User context: folder/domain/repo area affecting decomposition.
10. Codebase-memory project name: required when it cannot be inferred from workspace/repo context.

## Agility Context Requirement

- Asset number mandatory before materializing goals; `S-#####` or `D-#####` only.
- Fetch the parent asset title and description via Agility MCP by asset number.
- Shape decomposition and naming from fetched asset context plus user context and graph findings.

## Procedure Overrides

Base **step 1** keeps every bullet, including the protected-branch check and branch confirmation.
Retitle it "Verify indexing and discover context", plus:

- **Prepend**: verify the codebase-memory project is indexed (Index Prerequisite). Gates everything after
  it.
- **Prepend**: fetch the Story/Defect title and description via Agility MCP by asset number.
- **Replace** `Inspect branch/workspace changes relevant to the plan` with "Inspect workspace context and
  user-provided folder/domain constraints", and `Identify current architecture touchpoints and likely
  files affected` with graph exploration: `get_architecture` (overview), `search_graph`
  (symbols/modules), `trace_path` (caller/callee/impact), `get_code_snippet` (concrete code),
  `detect_changes` (impact of local edits).

Base **step 2**: the verification scope to confirm is manual QE (human-executed, user-facing where
possible) plus what is deferred.

Base **step 3**: additionally embed MCP-first execution instructions in each goal.

Insert the rules from `references/agility-payloads.md` as substeps 5a (payload artifacts and mirror), 5b
(Task/Test payloads), and 5c (payload validations), between base steps 5 and 6.

## Goal Template Overrides

Structure unchanged; replace only these bracket bodies. The inherited validation-ledger requirement
still applies: every `🧠 CONTEXT` names the supplied or Agility-derived claim, the MCP tool and
entity/snippet validating it, and the confirmed or corrected current-code fact. An unresolved claim
blocks materialization of both the goal and its mirrored Task payload.

- `🧠 CONTEXT:` → `[State the Agility requirement plus the codebase-memory project, concrete graph findings, and source provenance for this goal. Name the symbols/modules/routes and caller/callee or dependency relationship that constrain the change.]`
- `🗺️ PLAN:` → `[Begin with concrete codebase-memory MCP actions. For each, name the project, symbol/module/path target, tool, expected result, and decision it unlocks. Only then list narrow edits in MCP-identified files.]`
- `🔍 VERIFY:` → `[Re-run a concrete MCP relationship check for the exact graph entities changed or affected, then state runnable commands and deterministic manual QE checks, each scoped to this goal's change per the base Test Scoping Policy.]`

## Additional Decision Rules

- Architecture unclear → more codebase-memory graph exploration before drafting. Supersedes the base
  rule "run read-only exploration first".
- Indexing unavailable → stop and ask the user to index.
- A drafted goal implying grep-first discovery → rewrite it MCP-first before finalizing.
- Payload examples conflicting with the required fields → the required field structure wins.

## Additional Quality Bar

- Every validation in `references/agility-payloads.md` ("Payload Validations") passes; both payload files
  exist and were created in the same run as the goal files.
- The last goal's PLAN/DONE WHEN/VERIFY carries the execution-time tests-payload refresh instruction.
- The parent asset title and description were fetched via Agility MCP; API execution stays the user's
  responsibility.
- The codebase-memory project was identified, its index verified, and discovery ran through MCP; index
  missing/unhealthy → planning halted and the user was asked to index first.
- Every goal instructs MCP-first execution across CONTEXT, PLAN, and VERIFY, and meets the MCP evidence
  contract: project, graph entities, source provenance, concrete plan queries, relationship re-check.
- Every material supplied or Agility-derived description and code reference was MCP-validated and is
  confirmed or explicitly corrected before appearing in a goal or Task payload; unresolved claims stopped
  planning for clarification.
- No goal carries generic or placeholder discovery/implementation directions without specific
  codebase-memory targets and decisions.

## Additional Output Contract

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`
