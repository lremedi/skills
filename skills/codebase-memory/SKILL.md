---
name: codebase-memory
description: Use the codebase knowledge graph for structural code queries. 
Triggers on: explore the codebase, understand the architecture, what functions exist, show me the structure, who calls this function, what does X call, trace the call chain, find callers of, show dependencies, impact analysis, dead code, unused functions, high fan-out, refactor candidates, code quality audit, graph query syntax, Cypher query examples, edge types, how to use search_graph.
metadata:
  id: codebase-memory
  role: mixin
  abstract: false
  inherited-by: "plan-goal-breakdown-codebase-memory, plan-goal-breakdown-agility-codebase-memory, execute-goals-codebase-memory, execute-goals-agility-codebase-memory"
---

# Codebase Memory — Knowledge Graph Tools

Graph tools return precise structural results in ~500 tokens vs ~80K for grep.

Usable standalone, and also inherited as the tool-mechanics authority by skills that declare
`inherits: ... codebase-memory` (currently `plan-goal-breakdown-codebase-memory`,
`plan-goal-breakdown-agility-codebase-memory`, `execute-goals-codebase-memory`, and
`execute-goals-agility-codebase-memory`). Inheritors rely on the tool names, parameters, workflows, and
gotchas below being correct — when they change here, they change everywhere.

## `project` is required on every query tool

`search_graph`, `trace_path`, `get_code_snippet`, `get_architecture`, `detect_changes`, and
`query_graph` all take `project` as a **required** parameter. Every example below passes it. Omitting it
is a validation error, not a default-to-current-repo. Get the name from `list_projects`.

## Quick Decision Matrix

| Question | Tool call |
|----------|----------|
| Who calls X? | `trace_path(project="myproj", function_name="X", direction="inbound")` |
| What does X call? | `trace_path(project="myproj", function_name="X", direction="outbound")` |
| Full call context | `trace_path(project="myproj", function_name="X", direction="both")` |
| Where does this value flow? | `trace_path(project="myproj", function_name="X", mode="data_flow")` |
| Across service boundaries | `trace_path(project="myproj", function_name="X", mode="cross_service")` |
| Natural-language discovery | `search_graph(project="myproj", query="update settings")` |
| Find by name pattern | `search_graph(project="myproj", name_pattern=".*Pattern.*")` |
| Bridge vocabulary | `search_graph(project="myproj", semantic_query=["send","publish"])` |
| Dead code | `search_graph(project="myproj", max_degree=0, exclude_entry_points=true)` |
| Read source | `get_code_snippet(project="myproj", qualified_name="path.To.FuncName")` |
| Cross-service edges | `query_graph(project="myproj", query="<Cypher>")` |
| Impact of local changes | `detect_changes(project="myproj")` |
| Risk-classified trace | `trace_path(project="myproj", function_name="X", risk_labels=true)` |
| Text search | `search_code` or Grep |

## `search_graph` has three independent modes

Combinable in a single call:

1. `query="update settings"` — BM25 ranked full-text. Tokens split on whitespace; camelCase identifiers
   are indexed as separate words (`updateCloudClient` → update, cloud, client). Structural boosting:
   Functions/Methods +10, Routes +8, Classes/Interfaces +5. Noise labels (File/Folder/Module/Variable)
   are filtered out. **When `query` is provided, `name_pattern` is ignored.** Best default for
   natural-language discovery.
2. `name_pattern=".*regex.*"` / `qn_pattern=...` — exact pattern matching on name / qualified name.
3. `semantic_query=["send","pubsub","publish"]` — vector cosine search that bridges vocabulary (finds
   "publish" when you search "send"). **Must be an array of keyword strings, not a single string.** Each
   keyword is scored independently via per-keyword min-cosine, so results score well on *all* keywords.
   Requires moderate/full index mode. Results land in a separate `semantic_results` field.

Narrow with `label`, `file_pattern`, `min_degree`/`max_degree`, `relationship`, `exclude_entry_points`
before paginating a large set.

## `trace_path` has three modes

`mode` defaults to `calls` and is a **separate axis from `direction`**:

- `mode="calls"` — follows CALLS edges. The default.
- `mode="data_flow"` — follows CALLS + DATA_FLOWS, with argument expressions at each hop. Scope to one
  parameter with `parameter_name="..."`.
- `mode="cross_service"` — follows HTTP_CALLS + ASYNC_CALLS + DATA_FLOWS through Route nodes. This is
  the only way to trace across a service boundary.

Also: `depth` (default 3), `edge_types`, `risk_labels` (adds CRITICAL/HIGH/MEDIUM/LOW by hop distance),
and `include_tests` (default false — test files are filtered out unless you ask for them, and arrive
marked `is_test=true`).

## Exploration Workflow
1. `list_projects` — get the project name; everything below requires it
2. `get_graph_schema` — understand node/edge types
3. `search_graph(project="myproj", query="thing you're looking for")` — or `name_pattern` if you know it
4. `get_code_snippet(project="myproj", qualified_name="path.To.FuncName")` — read source

## Tracing Workflow
1. `search_graph(project="myproj", name_pattern=".*FuncName.*")` — discover the exact name
2. `trace_path(project="myproj", function_name="FuncName", direction="both", depth=3)` — trace
3. `detect_changes(project="myproj")` — map git diff to affected symbols

`detect_changes` compares against `base_branch` (default `main`) and accepts `since` for a git ref or
date (`HEAD~5`, `v0.5.0`, `2026-01-01`), plus `depth` (default 2) and `scope`.

## Quality Analysis
- Dead code: `search_graph(project="myproj", max_degree=0, exclude_entry_points=true)`
- High fan-out: `search_graph(project="myproj", min_degree=10, relationship="CALLS", direction="outbound")`
- High fan-in: `search_graph(project="myproj", min_degree=10, relationship="CALLS", direction="inbound")`

## 14 MCP Tools
`index_repository`, `index_status`, `list_projects`, `delete_project`,
`search_graph`, `search_code`, `trace_path`, `detect_changes`,
`query_graph`, `get_graph_schema`, `get_code_snippet`, `get_architecture`,
`manage_adr`, `ingest_traces`

## Edge Types
CALLS, HTTP_CALLS, ASYNC_CALLS, DATA_FLOWS, IMPORTS, DEFINES, DEFINES_METHOD,
HANDLES, IMPLEMENTS, OVERRIDE, USAGE, FILE_CHANGES_WITH,
CONTAINS_FILE, CONTAINS_FOLDER, CONTAINS_PACKAGE

## Cypher Examples (for query_graph)
```
MATCH (a)-[r:HTTP_CALLS]->(b) RETURN a.name, b.name, r.url_path, r.confidence LIMIT 20
MATCH (f:Function) WHERE f.name =~ '.*Handler.*' RETURN f.name, f.file_path
MATCH (a)-[r:CALLS]->(b) WHERE a.name = 'main' RETURN b.name
```

### Complexity and hot-path properties

Every Function and Method node carries queryable complexity properties, so bottleneck hunting is one
Cypher query rather than a reading exercise:

- Intraprocedural: `complexity` (cyclomatic), `cognitive`, `loop_count`, `loop_depth` (max nested-loop
  depth — a polynomial-degree proxy), `recursive`.
- Interprocedural: `transitive_loop_depth` (worst-case nested-loop degree propagated along CALLS edges).
- Hot-path signals: `linear_scan_in_loop` (find/contains/indexOf-style scans inside a loop — the hidden
  O(n²) that `loop_depth` misses), `alloc_in_loop`, `recursion_in_loop`, `unguarded_recursion`.
- Structure smells: `param_count`, `max_access_depth`.

```
MATCH (f:Function) WHERE f.transitive_loop_depth >= 3 OR f.linear_scan_in_loop >= 1
RETURN f.qualified_name, f.transitive_loop_depth, f.linear_scan_in_loop
ORDER BY f.transitive_loop_depth DESC
```

## Gotchas
1. `search_graph(project="myproj", relationship="HTTP_CALLS")` filters nodes by degree — it does not return edges. Use `query_graph` with Cypher to see actual edges.
2. `query_graph` has a hard 100k-row ceiling and no offset support. Add `LIMIT` in the Cypher itself, or pass `max_rows`; for paginated browsing use `search_graph` instead.
3. `trace_path` needs exact names — use `search_graph` with `name_pattern` first.
4. `direction` and `mode` are different axes. `direction="both"` does not reach across services — that needs `mode="cross_service"`, which follows HTTP_CALLS/ASYNC_CALLS through Route nodes.
5. `search_graph` returns up to `limit` results, default **200**. Broad queries are silently truncated, so check `has_more` (true when `total > offset + returned`) and page by incrementing `offset` — don't assume the first response is the whole set.
6. `semantic_query` takes an array. Passing a single string is the most common call error.
