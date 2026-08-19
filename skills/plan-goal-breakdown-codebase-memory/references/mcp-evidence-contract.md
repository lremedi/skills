# Codebase-Memory Planning Evidence

Shared reference for: `plan-goal-breakdown-codebase-memory`, `plan-goal-breakdown-agility-codebase-memory`.

## Code Navigation Policy (Required)

- codebase-memory MCP is the primary way to navigate code and architecture.
- Tool selection, syntax, workflows, and gotchas come from the inherited `codebase-memory` skill — use its
  Quick Decision Matrix and Exploration/Tracing Workflows rather than restating signatures here.
- No broad grep/rg scanning to understand architecture or call chains.
- Limited text search (`search_code` or Grep) only after graph discovery, for narrow confirmation in
  already-identified files.

## MCP Evidence Contract (Required)

Goals from this skill are graph-backed execution instructions, not generic implementation summaries.

- Treat every supplied description, acceptance criterion, path, symbol, architecture claim, and code
  reference — plus, for the Agility variant, the fetched Agility description — as an unverified
  hypothesis. Validate against indexed current code with MCP before using it in a goal; request text and
  tracker text never prove the current implementation.
- For each material claim, record confirmed / corrected / unresolved, citing project, MCP tool, graph
  entity or snippet, and the resulting current-code fact. Resolve an unresolved claim with the smallest
  extra MCP query or ask the user — never carry it silently into a materialized goal.
- Collect goal-specific evidence before drafting with `get_architecture`, `search_graph`, `trace_path`,
  `get_code_snippet` as applicable, recording concrete project, symbol/module, relationship, and source
  location.
- Every goal names the project and at least one real graph entity found for it (symbol, route, module,
  type, caller, callee, dependency edge, changed-file impact).
- Every `🗺️ PLAN` opens with executable MCP navigation actions, each naming its query/target and the
  decision it unlocks — e.g. `search_graph` for `OrderService` in project `shop` to find its command
  handler; `trace_path` from that handler to `OrderRepository` before changing persistence behavior.
- Every `🔍 VERIFY` re-checks the exact affected caller/callee or dependency path via MCP, naming source
  and target entities, paired with runnable and deterministic manual checks.
- A goal may name a file only after MCP identified it, or after narrow confirmation of an MCP-identified
  file. State that provenance in `🧠 CONTEXT`.
- Rewrite vague directions — "inspect the architecture", "find the relevant files", "update the service",
  "trace dependencies", "verify impact" — into ones naming project, target entity, relationship, and
  decision. No `<symbol>`, `<file>`, or "as needed" placeholders in a materialized goal.

Agility variant only, additionally:

- An unresolved claim blocks materialization of both the goal and its mirrored Task payload.
- Each Task payload's XHTML goal mirror preserves the concrete MCP context, plan, and verification
  instructions.
- Fetch the Story/Defect title and description via Agility MCP by asset number, and shape decomposition
  and naming from that plus user context and graph findings.
- Its final checks are called "deterministic manual QE checks" (human-executed, per its payload contract)
  rather than "deterministic manual checks". Wording only — the evidence requirement is identical.

## Index Prerequisite (Hard Gate)

Before any decomposition or architecture analysis:

1. `list_projects` to check indexed projects.
2. `index_status` when project health is unclear.
3. Not indexed, or indexing incomplete/failed → stop planning, ask the user to run `index_repository` for
   the repo, and resume only after they confirm it completed.

Never silently continue with fallback grep when indexing is missing.
