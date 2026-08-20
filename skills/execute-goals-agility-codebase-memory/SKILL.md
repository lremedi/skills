---
name: execute-goals-agility-codebase-memory
description: >-
  Execute a goal set already produced by plan-goal-breakdown-agility-codebase-memory for an
  Agility Story/Defect. Combines Agility reconciliation (Children:Task / Children:Test on the
  asset endpoint, since Agility is the source of truth once its createMany payload has run) with
  codebase-memory MCP re-confirmation of each goal's CONTEXT and VERIFY sections instead of
  grep-first exploration. Use whenever the user asks to execute or run goals for an Agility-linked
  Story/Defect whose goal files were authored against a codebase-memory-indexed project (they cite
  MCP tools like search_graph / trace_path / get_code_snippet in CONTEXT or PLAN).
argument-hint: "Agility Story/Defect ID (S-##### or D-#####) whose goal set should be executed, plus codebase-memory project name if it can't be inferred"
user-invocable: true
disable-model-invocation: false
metadata:
  id: execute-goals-agility-codebase-memory
  inherits: "execute-goals-base, codebase-memory"
  parent-files: "../execute-goals-base/SKILL.md, ../codebase-memory/SKILL.md"
  reference-files:
    - "../execute-goals-agility/references/children-task-query.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, read all three, resolved relative to this file's directory, and treat
them as your primary global constraints (on overlap, follow the base's precedence order):

1. `../execute-goals-base/SKILL.md` — execution contract.
2. `../codebase-memory/SKILL.md` — knowledge-graph tool reference.
3. `../execute-goals-agility/references/children-task-query.md` — Agility reconciliation query and rules
   used in `## Script`.

# Execute Goals — Agility (Codebase Memory)

Base execution contract plus Agility reconciliation **and** codebase-memory-driven context
re-confirmation and verification re-checks.

## When To Use

- Executing or continuing an Agility Story/Defect goal set authored with
  `plan-goal-breakdown-agility-codebase-memory`.
- Team wants both: local state kept honest against Agility, and code-context drift caught via the graph
  before editing.

## Agility Context Requirement

- Asset ID required before reconciliation: derive it from the goal set folder name
  (`.goals/<asset-id>-<feature-slug>/`) or ask. `S-#####` or `D-#####` only.

## Code Navigation Policy (Required)

- codebase-memory MCP is the primary way to re-confirm CONTEXT claims and re-check VERIFY relationships;
  tool selection and syntax come from the inherited `codebase-memory` skill.
- Text search is narrow confirmation after graph discovery, never the first move.

## Index Prerequisite (Hard Gate)

Before executing any goal: `list_projects`, then `index_status`. Not indexed, or incomplete/failed →
halt, ask the user to index (`index_repository`), continue only after they confirm. Never fall back to
grep-based discovery.

## Script

Query the asset's existing Task and Test children with the `Children:Task`/`Children:Test` downcast query
in `../execute-goals-agility/references/children-task-query.md`, which is authoritative once the mirrored
payload has run there. Its reconciliation rules govern step 0. Read it before step 1.

## Procedure Overrides

Insert a new step **before** base step 1:

0. **Reconcile against Agility.**
   - Run the `## Script` query for the asset.
   - Compare against local goal files and the shared log per the reference's rules; report every diff;
     update local state wherever it disagrees with Agility.
   - Query failure or tool unavailable → note it and proceed on the local log. This step informs
     execution, never blocks it.

Base **step 4** keeps every bullet, plus:

- **Replace** the CONTEXT-confirmation bullet with: "Re-confirm every CONTEXT claim and named
  symbol/module/route via codebase-memory MCP (`search_graph`, `get_code_snippet`, `trace_path`,
  `get_architecture` as applicable) before editing anything. Flag drift when the graph no longer supports
  a claim the goal was written against."
- **Prepend** to the VERIFY bullet: "Re-run at least one codebase-memory relationship check (e.g.
  `trace_path` between the caller/callee pair the goal names) before the goal's own VERIFY commands, to
  confirm the dependency shape VERIFY assumes still holds."
- Additionally: when the last goal's PLAN/DONE WHEN/VERIFY calls for it, refresh
  `payload.tests.<asset-id>-<feature-slug>.json` from the shared log's actual outcomes, verification
  results, and deviations — not from the goal's PLAN.

## Additional Decision Rules

- Supersedes the base Autonomy Contract bullet "Only three things legitimately interrupt a run": a missing
  or unhealthy codebase-memory index is a fourth legitimate interrupt — halt and ask the user to index.
- Agility wins any disagreement with local files.
- A goal whose mirrored Task was deleted in Agility is blocked, not dropped or re-created.
- Graph re-confirmation contradicting a goal's CONTEXT → stop and flag the drift.
- A reconciliation or graph query failure is informational for the check it belongs to, not a gate —
  proceed on the remaining working checks and say so.

## Additional Quality Bar

- Children:Task/Children:Test were queried and reconciled before determining what still needs to run (or
  the unavailability was noted); every Agility-vs-local diff was reported and local state updated to match.
- The project's index was verified before any goal ran; not indexed → execution halted and the user was
  asked to index first.
- Every executed goal's CONTEXT was re-confirmed via MCP with drift flagged, and every VERIFY pass includes
  a named graph relationship re-check.
- No goal ran that Agility already showed done; no goal with a deleted Agility Task ran unmarked.
- `payload.tests.<asset-id>-<feature-slug>.json` was refreshed from the shared log when the last goal's
  sections called for it.

## Additional Output Contract

- The shared log may gain reconciliation notes.
- Goal files may have identity/status fields — not PLAN/CONSTRAINTS/VERIFY — updated to match Agility.
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json` may be refreshed from
  execution-log evidence.
