# Skills

Agent skills for planning and executing dependency-aware, commit-sized work, with optional
Agility (work-tracker) mirroring and codebase-memory (MCP knowledge graph) navigation.

Invoke a skill with `/<skill-name> <args>` (see each skill's `argument-hint`), or let the agent
auto-invoke it from your request — every concrete skill below has `disable-model-invocation: false`.

## The two families

**plan-goal-breakdown** — turns a task/story into `.goals/<asset-id>-<feature-slug>/` files: an
index, a shared log, and one file per goal (GOAL/CONTEXT/CONSTRAINTS/PRIORITY/PLAN/DONE
WHEN/VERIFY/COMMIT/SAFETY NET/LOG/DEPENDENCIES).

**execute-goals** — runs a goal set that already exists: resumes from the shared log, respects the
dependency graph, executes each goal's own sections faithfully, commits, logs.

Every family member is a thin child of a shared **abstract base** (`plan-goal-breakdown-base`,
`execute-goals-base`) that owns the actual contract. Children only declare what's different.

## Pick a skill

| Work tracker? | Codebase indexed in codebase-memory? | Plan with... | Execute with... |
|---|---|---|---|
| No | No | `plan-goal-breakdown` | `execute-goals` |
| No | Yes | `plan-goal-breakdown-codebase-memory` | `execute-goals-codebase-memory` |
| Agility | No | `plan-goal-breakdown-agility` | `execute-goals-agility` |
| Agility | Yes | `plan-goal-breakdown-agility-codebase-memory` | `execute-goals-agility-codebase-memory` |

"Agility" = the goal set is for an Agility Story/Defect (`S-#####` / `D-#####`) and should mirror
to Agility child Tasks/Tests. "Codebase-memory" = use the MCP knowledge graph
(`search_graph`/`trace_path`/`get_code_snippet`/...) instead of grep-first exploration for CONTEXT
and VERIFY — worthwhile once a project is indexed (`index_repository`), pointless otherwise.

Two more skills sit outside that grid:

- **codebase-memory** — usable standalone for any structural code question ("who calls X",
  "find dead code", "trace this call chain") even with no goal set in play. Also the tool-mechanics
  reference the four `*-codebase-memory` skills inherit from.
- **pr-description** — writes a reviewer-facing PR description from real commits/diff, or from a
  finished goal set's shared log. Runs standalone, or automatically as the last goal in a goal set
  when planning opted into one.

## Typical flow

```
/plan-goal-breakdown "add rate limiting to the upload endpoint"
    → .goals/S-12345-rate-limiting/{00-index.md, log.*.md, 01-*.md, 02-*.md, ...}
/execute-goals S-12345
    → works through goals in dependency order, commits each, appends to the shared log
/pr-description S-12345          # only if you didn't opt into an auto-generated one at plan time
```

Swap in the `-agility`, `-codebase-memory`, or `-agility-codebase-memory` variant on both the plan
and execute side to match the table above — mixing families (e.g. planning with `-agility` but
executing with plain `execute-goals`) works but loses the Agility reconciliation step.

## Layout

```
skills/
  plan-goal-breakdown-base/            # abstract: shared contract, not user-invocable
  plan-goal-breakdown/                 # plain
  plan-goal-breakdown-agility/         # + Agility mirroring
  plan-goal-breakdown-codebase-memory/ # + codebase-memory navigation
  plan-goal-breakdown-agility-codebase-memory/  # both
  execute-goals-base/                  # abstract: shared contract, not user-invocable
  execute-goals/                       # plain
  execute-goals-agility/               # + Agility reconciliation
  execute-goals-codebase-memory/       # + codebase-memory re-confirmation
  execute-goals-agility-codebase-memory/        # both
  codebase-memory/                     # standalone + mixin: MCP graph tool reference
  pr-description/                      # standalone: PR write-up
```

Each concrete skill's frontmatter (`metadata.inherits` / `metadata.parent-files`) names its parents
explicitly, and its body reads those files before acting — the base/mixin files aren't meant to be
read in isolation by a human, but they're where the actual rules (branch policy, goal template,
quality bar, MCP tool syntax) live if you're editing behavior rather than just using a skill.
