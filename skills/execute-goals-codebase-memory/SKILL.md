---
name: execute-goals-codebase-memory
description: >-
  Execute a goal set already produced by plan-goal-breakdown-codebase-memory (or any goal set
  whose CONTEXT/PLAN/VERIFY sections were authored against a codebase-memory-indexed project),
  using codebase-memory MCP to re-confirm each goal's CONTEXT claims and re-check affected
  relationships during VERIFY instead of grep-first exploration. Use when the user asks to execute
  or run goals for a codebase-memory-indexed project, or when the goal files themselves already
  cite codebase-memory tools (get_architecture, search_graph, trace_path, get_code_snippet) in
  their CONTEXT or PLAN sections.
argument-hint: "Story/Defect ID or .goals/ folder path to execute, plus codebase-memory project name if it can't be inferred"
user-invocable: true
disable-model-invocation: false
metadata:
  id: execute-goals-codebase-memory
  inherits: "execute-goals-base, codebase-memory"
  parent-files: "../execute-goals-base/SKILL.md, ../codebase-memory/SKILL.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, read both, resolved relative to this file's directory, and treat them
as your primary global constraints (on overlap, follow the base's precedence order):

1. `../execute-goals-base/SKILL.md` — execution contract.
2. `../codebase-memory/SKILL.md` — knowledge-graph tool reference.

# Execute Goals (Codebase Memory)

Base execution contract, with codebase-memory MCP driving context re-confirmation and verification
re-checks instead of grep-first exploration.

## When To Use

- The goal set's CONTEXT/PLAN/VERIFY already cite codebase-memory tools or a project.
- Team wants execution-time drift checks (has the code moved since the goal was written?) via the graph
  rather than ad hoc search.

## Code Navigation Policy (Required)

- codebase-memory MCP is the primary way to re-confirm CONTEXT claims and re-check VERIFY relationships.
- Tool selection, syntax, workflows, and gotchas come from the inherited `codebase-memory` skill — use its
  Quick Decision Matrix and workflows rather than restating signatures.
- Text search (`search_code` or Grep) is narrow confirmation after graph discovery, never the first move.

## Index Prerequisite (Hard Gate)

Before executing any goal: `list_projects`, then `index_status` when needed. Not indexed, or
incomplete/failed → halt, ask the user to index (`index_repository`), continue only after they confirm.
Never fall back to grep-based discovery.

## Procedure Overrides

Base **step 4** keeps every bullet, plus:

- **Replace** the CONTEXT-confirmation bullet with: "Re-confirm every CONTEXT claim and named
  symbol/module/route via codebase-memory MCP (`search_graph`, `get_code_snippet`, `trace_path`,
  `get_architecture` as applicable) before editing anything. A claim the graph no longer supports is
  drift — flag it before continuing."
- **Prepend** to the VERIFY bullet: "Re-run at least one codebase-memory relationship check (e.g.
  `trace_path` between the caller/callee pair the goal names) to confirm the dependency shape VERIFY
  assumes still holds — in addition to, not instead of, the goal's own VERIFY commands."

## Additional Decision Rules

- Supersedes the base Autonomy Contract bullet "Only three things legitimately interrupt a run": a
  missing or unhealthy index is a fourth legitimate interrupt — halt and ask the user to index.
- Graph re-confirmation contradicting a goal's CONTEXT → stop and flag the drift rather than editing
  against an unsupported claim.

## Additional Quality Bar

- The project was identified and its index status verified before any goal ran; if it wasn't indexed,
  execution halted and the user was asked to index first.
- Every executed goal's CONTEXT claims were re-confirmed via MCP before editing, with drift flagged.
- Every executed goal's VERIFY pass includes a named graph relationship re-check (project, tool,
  entities).
