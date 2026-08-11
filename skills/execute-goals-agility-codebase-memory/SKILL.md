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
  parent-files: "../execute-goals-base/SKILL.md, ../codebase-memory/SKILL.md, ../execute-goals-agility/references/children-task-query.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from ALL parent
files, resolved relative to this file's directory:

1. `../execute-goals-base/SKILL.md` — the execution contract.
2. `../codebase-memory/SKILL.md` — the knowledge-graph tool reference.
3. `../execute-goals-agility/references/children-task-query.md` — the Agility reconciliation query
   and rules used in `## Script` below.

Treat their contents as your primary global constraints, then apply the specialized rules below.
Where they overlap, follow the precedence order in the base skill's Inheritance Contract.

# Execute Goals — Agility (Codebase Memory)

Same execution contract as the base, plus Agility reconciliation **and** codebase-memory-driven
context re-confirmation and verification re-checks.

## When To Use

- User asks to execute or continue a goal set from an Agility Story/Defect whose goal files were
  authored with `plan-goal-breakdown-agility-codebase-memory`.
- Team wants both: local state kept honest against Agility, and code-context drift caught via the
  knowledge graph before editing.

## Agility Context Requirement

- The asset ID is required before reconciliation can run; derive it from the goal set folder name
  (`.goals/<asset-id>-<feature-slug>/`) or ask if it can't be determined.
- Accept only `S-#####` (story) or `D-#####` (defect).

## Code Navigation Policy (Required)

- Use codebase-memory MCP as the primary way to re-confirm a goal's CONTEXT claims and to re-check the
  relationships named in VERIFY.
- Tool selection, call syntax, workflows, and gotchas come from the inherited `codebase-memory` skill.
- Text search is for narrow confirmation only, after graph-driven discovery.

## Index Prerequisite (Hard Gate)

Before executing any goal: check indexed projects with `list_projects`, validate with `index_status`,
and halt to ask the user to index (`index_repository`) if the target codebase isn't indexed or the
index is incomplete/failed. Continue only after they confirm. Do not fall back to grep-based discovery.

## Script

Before determining which goals still need to run, query the asset's existing Task and Test children so
local state can be reconciled against Agility. VersionOne exposes them through the asset's `Children`
relation, downcast to one type at a time (`Children:Task`, `Children:Test`) — the same downcast
pattern documented on the asset endpoint: https://versionone.github.io/api-docs/#restv1Data-create

```typescript
{
  from: "Story",                   // or "Defect" — must match the asset ID prefix (S- / D-)
  where: { "Number": "S-01004" },  // the Agility asset number the goal set folder is named after
  select: [
    "Children:Task.Number",
    "Children:Task.Name",
    "Children:Task.Description",
    "Children:Task.AssetState",
    "Children:Test.Number",
    "Children:Test.Name",
    "Children:Test.Description",
    "Children:Test.AssetState",
  ],
}
```

Full reconciliation rules are in `../execute-goals-agility/references/children-task-query.md`. Read it
before step 1.

## Procedure Overrides

Insert a new step **before** base step 1 (Locate the goal set and confirm the branch):

0. **Reconcile against Agility.**
   - Run the `## Script` query for the asset.
   - Compare against local goal files and the shared log per
     `../execute-goals-agility/references/children-task-query.md`; report every diff; update local
     state to match Agility wherever they disagree.
   - If the query fails or the tool is unavailable, note that and proceed with the local shared log
     as-is — this step informs execution, it never blocks it.

Base **step 4 (Run each eligible goal)** keeps every bullet it already has. Apply these changes:

- **Replace** the CONTEXT-confirmation bullet with: "Re-confirm every CONTEXT claim and named
  symbol/module/route via codebase-memory MCP (`search_graph`, `get_code_snippet`, `trace_path`,
  `get_architecture` as applicable) before editing anything. Flag drift if the graph no longer
  supports a claim the goal was written against."
- **Prepend** to the VERIFY bullet: "Re-run at least one codebase-memory relationship check (for
  example `trace_path` between the caller/callee pair the goal names) before the goal's own VERIFY
  commands, to confirm the dependency shape VERIFY assumes still holds."

## Additional Decision Rules

- Agility wins on any disagreement between it and local files.
- A goal whose mirrored Task was deleted in Agility is blocked, not silently dropped or re-created.
- If the codebase-memory index is missing/unhealthy, halt and ask the user to index before executing
  any goal.
- If graph-based re-confirmation contradicts a goal's CONTEXT, stop and flag the drift.
- A reconciliation or graph query failure is informational, not a gate, for the check it belongs to —
  proceed on the remaining, working checks and say so.

## Additional Quality Bar

Beyond the base bar:

- Children:Task/Children:Test were queried and reconciled before determining what still needs to run.
- Every executed goal's CONTEXT was re-confirmed via codebase-memory MCP; every VERIFY pass includes a
  named graph-based relationship re-check.
- If the project wasn't indexed, execution halted and the user was asked to index first.
- No goal ran that Agility already showed done; no goal with a deleted Agility Task ran unmarked.

## Additional Output Contract

Beyond the base artifacts:

- The shared log may gain reconciliation notes in addition to normal execution entries.
- Goal files may have identity/status fields (not PLAN/CONSTRAINTS/VERIFY) updated to match Agility.

## Additional Completion Checklist

- [ ] Codebase-memory project identified and index status verified before executing any goal.
- [ ] Children:Task/Children:Test queried and reconciled before reading the shared log (or its
      unavailability was noted).
- [ ] Every Agility-vs-local diff was reported; local state updated to match Agility.
- [ ] Each executed goal's CONTEXT was re-confirmed via codebase-memory MCP, with drift flagged.
- [ ] Each executed goal's VERIFY includes a named graph-based relationship re-check.
- [ ] No goal ran that Agility already showed done; no goal with a deleted Agility Task ran unmarked.
