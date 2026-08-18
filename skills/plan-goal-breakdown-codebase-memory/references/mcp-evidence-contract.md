# Codebase-Memory Planning Evidence

Shared reference for: `plan-goal-breakdown-codebase-memory`, `plan-goal-breakdown-agility-codebase-memory`.

## Code Navigation Policy (Required)

- Use codebase-memory MCP as the primary way to navigate code and architecture.
- Tool selection, call syntax, workflows, and gotchas come from the inherited `codebase-memory` skill — use its Quick Decision Matrix and Exploration/Tracing Workflows rather than restating tool signatures here.
- Do not do broad grep/rg scanning to understand architecture or call chains.
- Limited text search (`search_code` or Grep) is allowed only after graph discovery, for narrow confirmation in already-identified files.

## MCP Evidence Contract (Required)

Goals produced by this skill are execution instructions backed by the codebase-memory graph. They must not be generic implementation summaries.

- Treat every user-provided description, acceptance criterion, file path, symbol, architecture claim, and code reference as an unverified hypothesis. Before using it in a goal, validate it against the indexed current code with codebase-memory MCP; do not treat request text or referenced code as proof.
- For each material supplied claim used by a goal, record whether MCP evidence confirms it, corrects it, or leaves it unresolved. Cite the project, MCP tool, graph entity or source snippet, and the resulting current-code fact. Resolve an unresolved claim with the smallest additional MCP query or ask the user; never silently carry it into a materialized goal.
- Before drafting, collect goal-specific evidence with `get_architecture`, `search_graph`, `trace_path`, and `get_code_snippet` as applicable. Record the concrete project, symbol/module, relationship, and source location or snippet returned by MCP.
- Every goal must name the codebase-memory project and at least one real graph entity discovered for that goal. A graph entity can be a symbol, route, module, type, caller, callee, dependency edge, or changed-file impact result.
- In every `🗺️ PLAN`, write the first one or more steps as executable MCP navigation actions. Each action must name its intended query/target and expected decision, for example: `search_graph` for `OrderService` in project `shop` to identify its command handler; `trace_path` from that handler to `OrderRepository` before changing persistence behavior.
- In every `🔍 VERIFY`, use MCP to re-check the exact affected caller/callee or dependency path, naming the source and target graph entities. Pair this with relevant runnable and deterministic manual checks.
- A goal may only name a file after MCP identified it or after a narrow confirmation of an MCP-identified file. State that provenance in `🧠 CONTEXT`.
- Reject and rewrite statements such as "inspect the architecture", "find the relevant files", "update the service", "trace dependencies", or "verify impact" when they do not name an MCP project, target entity, relationship, and decision. Do not use placeholders such as `<symbol>`, `<file>`, or "as needed" in a materialized goal.

### Agility-only evidence additions

The `plan-goal-breakdown-agility-codebase-memory` consumer additionally applies these rules:

- Treat every user-provided description, acceptance criterion, file path, symbol, architecture claim, and code reference, including the fetched Agility description, as an unverified implementation hypothesis. Validate it against indexed current code with codebase-memory MCP; neither request text nor Agility text proves the current implementation.
- For each material supplied or Agility-derived claim used by a goal, record whether MCP evidence confirms it, corrects it, or leaves it unresolved. Cite the project, MCP tool, graph entity or source snippet, and the resulting current-code fact. Resolve an unresolved claim with the smallest additional MCP query or ask the user; never silently carry it into a materialized goal or payload.
- An unresolved claim blocks materialization of both the goal and its mirrored Task payload.
- Each Task payload's full XHTML goal mirror must preserve the concrete MCP context, plan, and verification instructions.

## Index Prerequisite (Hard Gate)

Before any decomposition or architecture analysis:

1. Check indexed projects using `list_projects`.
2. If needed, check status with `index_status`.
3. If the target codebase is not indexed or indexing is incomplete/failed:
   - Stop planning.
   - Ask the user to index the repository first.
   - Suggested action for the user: run `index_repository` for the repo.
   - Resume only after the user confirms indexing completed.

Do not silently continue with fallback grep when indexing is missing.

The plain codebase-memory variant calls its final checks "deterministic manual checks"; the Agility
codebase-memory variant calls them "deterministic manual QE checks" because its payload contract
requires human-executed QE. This wording difference is intentional and does not change the evidence
requirement.

## Agility Variant Index and Context Additions

The `plan-goal-breakdown-agility-codebase-memory` consumer also requires:

- Before planning starts, validate the codebase-memory project with `list_projects` and `index_status`; if it is missing or incomplete/failed, halt and ask the user to index it first.
- Fetch the Story/Defect title and description through Agility MCP using the provided asset number.
- Use the fetched asset context plus user context and codebase-memory findings to shape decomposition and naming quality.
