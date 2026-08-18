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

Before processing any user request, you MUST locate, read, and append the instructions from BOTH
parent skill files, resolved relative to this file's directory:

1. `../execute-goals-base/SKILL.md` — the execution contract.
2. `../codebase-memory/SKILL.md` — the knowledge-graph tool reference.

Treat their contents as your primary global constraints, then apply the specialized rules below.
Where they overlap, follow the precedence order in the base skill's Inheritance Contract.

# Execute Goals (Codebase Memory)

Same execution contract as the base, with codebase-memory MCP driving context re-confirmation and
verification re-checks instead of grep-first exploration.

## When To Use

- The goal set's CONTEXT/PLAN/VERIFY sections already cite codebase-memory tools or a codebase-memory
  project.
- Team wants execution-time drift checks (has the code moved since the goal was written?) done via the
  knowledge graph rather than ad hoc search.

## Code Navigation Policy (Required)

- Use codebase-memory MCP as the primary way to re-confirm a goal's CONTEXT claims and to re-check the
  relationships named in VERIFY.
- Tool selection, call syntax, workflows, and gotchas come from the inherited `codebase-memory` skill —
  use its Quick Decision Matrix and Exploration/Tracing Workflows rather than restating tool signatures
  here.
- Text search (`search_code` or Grep) is for narrow confirmation only, after graph-driven discovery —
  not the first move.

## Index Prerequisite (Hard Gate)

Before executing any goal:

1. Check indexed projects with `list_projects`.
2. Validate project status with `index_status` when needed.
3. If the target codebase is not indexed or the index is incomplete/failed: halt, ask the user to index
   the repository first (suggested action: `index_repository`), and continue only after they confirm.

Do not silently fall back to grep-based discovery when the index is missing.

## Procedure Overrides

Base **step 4 (Run each eligible goal)** keeps every bullet it already has. Apply these bullet-level
changes:

- **Replace** the bullet "Do the CONTEXT-confirmation part of the plan before editing anything..."
  with: "Re-confirm every CONTEXT claim and named symbol/module/route via codebase-memory MCP
  (`search_graph`, `get_code_snippet`, `trace_path`, `get_architecture` as applicable) before editing
  anything. If a claim no longer matches what the graph shows, treat that as drift and flag it before
  continuing — the goal was written against a snapshot of the code that may have moved."
- **Prepend** to the VERIFY bullet: "Before running the goal's listed VERIFY commands, re-run at least
  one codebase-memory relationship check (for example `trace_path` between the caller/callee pair the
  goal names) to confirm the dependency shape VERIFY assumes still holds. Run this in addition to, not
  instead of, the goal's own VERIFY commands."

## Additional Decision Rules

- Supersedes the base Autonomy Contract bullet beginning "Only three things legitimately interrupt a
  run": a missing or unhealthy codebase-memory index is a fourth legitimate interrupt.
- If the codebase-memory index is missing or unhealthy for the target project, halt and ask the user to
  index before executing any goal in the set.
- If graph-based re-confirmation contradicts a goal's CONTEXT, stop and flag the drift rather than
  editing against a claim the graph no longer supports.

## Additional Quality Bar

Beyond the base bar:

- Every executed goal's CONTEXT claims were re-confirmed via codebase-memory MCP before editing.
- Every executed goal's VERIFY pass includes at least one graph-based relationship re-check, named
  explicitly (project, tool, entities checked).
- If the project wasn't indexed, execution halted and the user was asked to index first.

## Additional Completion Checklist

- [ ] Codebase-memory project identified and index status verified before executing any goal.
- [ ] Each executed goal's CONTEXT was re-confirmed via codebase-memory MCP, with any drift flagged.
- [ ] Each executed goal's VERIFY includes a named graph-based relationship re-check.
- [ ] If indexing was missing/unhealthy, the user was asked to index before execution continued.
