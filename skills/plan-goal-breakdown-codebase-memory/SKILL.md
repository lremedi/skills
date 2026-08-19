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

Before processing any user request, read all three, resolved relative to this file's directory, and treat
them as your primary global constraints (on overlap, follow the base's precedence order):

1. `../plan-goal-breakdown-base/SKILL.md` — process and output contract.
2. `../codebase-memory/SKILL.md` — knowledge-graph tool reference.
3. `references/mcp-evidence-contract.md` — navigation, evidence, and index-prerequisite rules.

# Plan Goal Breakdown (Codebase Memory)

Base goal-file contract, with code discovery driven by the codebase-memory knowledge graph instead of
grep-first exploration.

## When To Use

- "Plan this", "break into goals", "make commit-sized goals", "persist goals in files".
- Work needs dependency ordering and safe parallel execution.
- Discovery should be graph-based via codebase-memory MCP, not grep-first.

## Additional Inputs To Collect

9. Codebase-memory project name: required when it cannot be inferred from workspace/repo context.

## Procedure Overrides

Base **step 1** keeps every bullet, including the protected-branch check and branch confirmation.
Retitle it "Verify indexing and discover context", plus:

- **Prepend**: validate the codebase-memory project exists and is indexed (Index Prerequisite). Gates
  everything after it.
- **Replace** `Identify current architecture touchpoints and likely files affected` with graph
  exploration: `get_architecture` (map), `search_graph` (symbols), `trace_path` (caller/dependency
  chains), `get_code_snippet` (exact source), `detect_changes` (impact of local edits).

Base **step 7**: read manifests generally, not `package.json` specifically, and add these validations:

- Every goal satisfies the MCP Evidence Contract with no generic discovery placeholders.
- Every planned MCP query names a concrete project and graph target; every verification query re-checks a
  named relationship the goal affects.
- Every material supplied description and code reference has a documented MCP confirmation or
  correction — request text is never current-code evidence.
- Reject goals whose context lacks provenance from `get_code_snippet`, `search_graph`, `trace_path`,
  `get_architecture`, or `detect_changes`.

## Goal Template Overrides

Structure unchanged; replace only these bracket bodies. The inherited validation-ledger requirement
still applies: every `🧠 CONTEXT` names the supplied claim, the MCP tool and entity/snippet validating
it, and the confirmed or corrected current-code fact. An unresolved claim blocks materialization.

- `🧠 CONTEXT:` → `[State the codebase-memory project, concrete graph findings, and source provenance for this goal. Name the symbols/modules/routes and caller/callee or dependency relationship that constrain the change.]`
- `🗺️ PLAN:` → `[Begin with concrete codebase-memory MCP actions. For each, name the project, symbol/module/path target, tool, expected result, and decision it unlocks. Only then list narrow edits in MCP-identified files.]`
- `🔍 VERIFY:` → `[Re-run a concrete MCP relationship check for the exact graph entities changed or affected, then state runnable commands and deterministic manual checks, each scoped to this goal's change per the base Test Scoping Policy.]`

## Additional Decision Rules

- Architecture unclear → more codebase-memory graph exploration before drafting. Supersedes the base
  rule "run read-only exploration first".
- Indexing unavailable → stop and ask the user to index; never substitute broad grep exploration.

## Additional Quality Bar

- Code discovery and dependency tracing ran through codebase-memory MCP, and the project was identified
  with its index status verified.
- Every goal meets the MCP evidence contract: project, graph entities, source provenance, concrete MCP
  plan queries, and an MCP relationship re-check in VERIFY.
- Every material supplied description and code reference was MCP-validated and is confirmed or explicitly
  corrected in the goal; unresolved claims stopped planning for clarification.
- No goal carries generic or placeholder discovery/implementation directions without specific
  codebase-memory targets and decisions.
- Index missing/unhealthy → planning halted and the user was asked to index first.
