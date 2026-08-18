---
name: execute-goals-base
description: >-
  Abstract base for the execute-goals skill family. Defines the shared contract for executing a
  goal set already produced by the plan-goal-breakdown family: locating the index and shared log,
  resuming from logged outcomes, building run order from the dependency graph, running each goal's
  own GOAL/CONTEXT/CONSTRAINTS/PRIORITY/PLAN/DONE WHEN/VERIFY/COMMIT/SAFETY NET/LOG/DEPENDENCIES
  sections faithfully, concurrency for parallel-safe goals, block-cascade handling, and the final
  report.
user-invocable: false
disable-model-invocation: true
metadata:
  id: execute-goals-base
  abstract: true
  role: base
  inherited-by: "execute-goals, execute-goals-agility, execute-goals-codebase-memory, execute-goals-agility-codebase-memory"
  references: "../pr-description/SKILL.md"
---

# Execute Goals — Base

Abstract base skill. Not directly invocable: `user-invocable: false` hides it from the `/` menu and
`disable-model-invocation: true` stops the agent from auto-loading it. It is only ever reached by a
child reading this file.

Child skills inherit this file and layer their own specialization on top. Everything below is a
global constraint for every child unless that child explicitly declares an override.

This is the execution half of the `plan-goal-breakdown` family: something else already negotiated the
scoping, dependency analysis, and exact verification/commit steps and wrote them into goal files. Your
job is to carry out what's already been decided, faithfully, one goal at a time, and leave an honest
record of what happened — not to re-plan the work.

## Inheritance Contract

Inheritance is not a native frontmatter feature — VS Code accepts only `name`, `description`,
`license`, `compatibility`, `metadata`, `argument-hint`, `user-invocable`,
`disable-model-invocation`, and `context` in a skill file. So it is expressed in two parts:

- **Declared** in the supported free-form `metadata` map, for humans and tooling to read:
  ```yaml
  metadata:
    id: execute-goals-agility
    inherits: execute-goals-base
    parent-files: "../execute-goals-base/SKILL.md"
  ```
- **Enforced** by the child's `# ⚠️ System Initialization Hook` section, which instructs the agent to
  read every path in `metadata.parent-files` before processing any user request. The hook is the
  actual mechanism; `metadata` is only the declaration. Keep the two in sync — if you add a parent,
  add it to both.

Rules:

- Children list parents most general first, and must read every parent they list.
- Children may **add** sections (new policies, new procedure steps, new artifacts).
- Children may **override** a section only by naming it explicitly under one of the canonical
  extension-point headings below. Silent divergence is not allowed.

Canonical extension-point headings — use these exact names so a reader can diff any two children:

| Heading | Purpose |
|---|---|
| `## Specialization` | one-paragraph statement of what this variant changes |
| `## Additional Inputs To Collect` | extra inputs, numbered continuing from the base list |
| `## Procedure Overrides` | bullet-level deltas to the base procedure |
| `## Additional Decision Rules` | extra rules, plus any base rule explicitly superseded |
| `## Additional Quality Bar` | extra pass/fail criteria |
| `## Additional Output Contract` | extra artifacts or tracker side-effects |
| `## Additional Completion Checklist` | extra operator checks |

Anything a child declares outside these headings is a new policy of its own, not an override.
An override must be the **smallest possible delta, and must never restate inherited text.** Quote the
base bullet or step being changed and say prepend / replace / drop — do not re-type a whole procedure
step to alter one bullet of it.

Precedence, highest first:

1. A child's explicitly declared override.
2. This base — authoritative for the execution contract: how to read a goal set, run order, per-goal
   procedure, concurrency, blocking, and the completion report.
3. Any additional parent — authoritative only within its own domain (for example, `codebase-memory` is
   the authority for knowledge-graph tool names and call syntax; it never changes the execution
   contract above).

Where a child's rule conflicts with this base and no override is declared, this base wins.

## Anatomy of a Goal Set (Read-Only Input)

You do not create or restructure these files — the `plan-goal-breakdown` family does. You consume them
exactly as written:

- **`00-<id>-index.md`** — ordered execution list, dependency graph, parallelization notes, and the
  working branch.
- **`NN-<id>-<slug>.md`** — one goal per file: 🎯 GOAL, 🧠 CONTEXT, 📏 CONSTRAINTS, 📊 PRIORITY,
  🗺️ PLAN, 🛑 DONE WHEN, 🔍 VERIFY, ✅ COMMIT, 🛡️ SAFETY NET, 📝 LOG, 🔗 DEPENDENCIES.
- **`log.<asset-id>-<feature-slug>.md`** — the shared file every goal appends one entry to on completion
  or block.
- **`pr-description.md`** — a planning-time stub. The one exception to "read-only input": the last goal
  in the sequence finalizes this file as part of its own PLAN/DONE WHEN/VERIFY (see PR Description
  Handoff below). No other goal touches it.

Treat the labels, not the emoji, as the contract — a plain-text variant means the same thing. What each
section obligates you to do:

| Section | What it gives you | What it obligates |
|---|---|---|
| GOAL | The one-sentence outcome | Nothing to build beyond this |
| CONTEXT | Confirmed facts about the current code | Trust it as verified, not assumed — but if the environment contradicts it, stop and treat that as new information, not a reason to force the plan through |
| CONSTRAINTS | The scope boundary | A hard edge — a step that seems to need something outside it is a signal to stop and check, not to quietly expand scope |
| PRIORITY | Where this goal sits relative to others | Informs ordering only within what the dependency graph already allows — it never overrides a DEPENDENCIES constraint |
| PLAN | Numbered steps | Work them in order — later steps often assume earlier ones actually happened |
| DONE WHEN | The acceptance test in plain language | Check your work against this before you even start verifying |
| VERIFY | The exact commands/checks that prove it | Run every one, read the real output, don't infer success |
| COMMIT | The exact commit command | Run it verbatim — no reworded message, no co-author trailers |
| SAFETY NET | What to inspect first if stuck, and how many focused attempts you get | A budget, not a suggestion |
| LOG | Where and how to record the outcome | Mandatory on every path — done, partial, or blocked |
| DEPENDENCIES | What must precede this, what it unlocks, what can run alongside it | Determines run order and concurrency |

## Inputs To Collect

1. The goal set to execute: a story/defect ID, a `.goals/` subfolder path, or an index file path.
   If more than one goal set could match, ask which one rather than guessing.

## Autonomy Contract (Required)

The goal set in front of you is not a proposal to review — it's already-negotiated, execution-ready
work. GOAL, CONTEXT, CONSTRAINTS, PRIORITY, PLAN, DONE WHEN, VERIFY, COMMIT, SAFETY NET, LOG, and
DEPENDENCIES together are the full authorization to act. There is nothing left to confirm before
starting an eligible goal, so don't.

**Terminal** means a goal's most recent shared-log entry is `✅ done`, `⚠️ partial`, or `❌ blocked`.
Those are the only three outcomes the log can record, they are the only three that end a goal's run, and
all three satisfy a gate that waits on "every other goal terminal" — `⚠️ partial` included. A partial
outcome still names its shortfall in the final report, and a gate that consumes it discloses it rather
than hiding it.

- **Act immediately on invocation.** When you're handed a goal, an index, or an asset ID with a goal
  set behind it, start the Procedure below — don't summarize the goal back and wait for a go-ahead,
  and don't ask whether to proceed with a plan the goal file already states as decided.
- **Keep going without pausing between goals.** Work straight through every eligible goal in the run
  order. Finishing one goal is not a checkpoint to ask "should I continue?" — the answer is yes, move
  to the next eligible goal, until the run order in front of you is exhausted.
- **Don't re-ask what a goal already answered.** The goal file's COMMIT section is already the
  standing instruction to commit once VERIFY passes — running VERIFY commands and committing on that
  basis doesn't need a separate go-ahead. Re-litigating a decision the goal file already made just
  adds a stop the goal set wasn't designed to have.
- **A run ends in exactly one terminal state, per goal:** `✅ done` (DONE WHEN met, VERIFY passed, commit
  landed, log entry written), `⚠️ partial` (part of it demonstrably landed and the rest didn't), or
  `❌ blocked` (SAFETY NET's stated attempt budget exhausted, or a dependency that is itself blocked,
  with no path forward that doesn't require a human decision). Reach one of those for every eligible
  goal before stopping; don't stop partway through an eligible goal because progress feels uncertain —
  that's what the attempt budget is for.
- **Only three things legitimately interrupt a run:** a protected/ambiguous working-branch situation
  the goal set didn't anticipate — two rules govern this, and they are the whole of it: **a protected
  trunk means halt** (`main`, `master`, `trunk`, `default`, `develop`, `development`, `dev`, `release`,
  `release/*`, `hotfix/*`, `support/*`, case-insensitively, plus anything the user or repo config calls
  protected), and **never rename a branch yourself** — a SAFETY NET section explicitly naming something
  only a human can decide
  (a credential, a product/UX call, a missing fixture), or an environment/tool failure that makes
  further progress on that specific goal impossible. Even then, only the affected goal is blocked —
  every other still-eligible, independent goal keeps running. A single blocked goal is not a reason to
  stop the whole session and ask what to do next; report it and continue with what's still runnable,
  then give the full picture in the final report once truly nothing eligible remains.

## PR Description Handoff (Required)

The last goal in a goal set produced by the `plan-goal-breakdown` family carries one extra deliverable:
finalize `pr-description.md` in the goals folder. That goal names the **`pr-description` skill** as the
authority on structure and evidence rules — it does not, and must not, carry a path to that skill,
because a path written from inside `.goals/` can't reach the skills folder.

Resolving it is this skill's job, not the goal file's:

- When an eligible goal's PLAN/DONE WHEN/VERIFY calls for producing or finalizing `pr-description.md`,
  read `../pr-description/SKILL.md` — resolved relative to **this file's directory**, inside the skills
  folder — before writing anything into that file. Follow its Required Structure, Gathering Evidence
  rules, and Output Contract.
- Read it at that point, not up front: it's needed by exactly one goal in the set, so it stays out of
  the eager `parent-files` load every run pays for.
- A goal file that does carry a literal `../pr-description/SKILL.md` (or any other skills-relative
  path) is a planning defect from an older run. Don't try to resolve the path from the goals folder and
  don't treat its failure as a blocker — resolve the skill from this file's directory as above, note the
  stale reference in the run summary, and continue.
- If `../pr-description/SKILL.md` genuinely isn't readable from this skill's directory, that's a real
  tool/environment failure for that one goal: say so plainly, leave the stub as-is rather than
  improvising a structure, and treat the goal per the normal SAFETY NET path. Never fabricate the
  skill's required structure from memory of what a PR description usually looks like.

## Procedure

1. **Locate the goal set and confirm the branch.**
   - Find `00-<id>-index.md` first — don't jump straight to a numbered goal file. It carries the
     working branch, dependency graph, and parallelization notes that a single goal file doesn't
     repeat.
   - Confirm you're on the branch the index names before making any change; switch to it if it already
     exists. A goal executed on the wrong branch is a goal you'll have to redo.
   - Never create a branch and carry on, and never proceed onto a protected trunk. If the index names no
     branch, names one that doesn't exist, or points at a protected trunk, that's the branch interrupt in
     the Autonomy Contract — halt and ask.

2. **Read the shared log and determine what still needs to run.**
   - Match log entries to goals by slug — the filename with both the sequence number and the asset ID
     stripped, e.g. `01-S-12345-filter-supported-attachment-types.md` matches the log header
     `## filter-supported-attachment-types`.
   - Most recent entry ✅ done → skip executing it; trust the record unless something you encounter
     later directly contradicts it.
   - Most recent entry ⚠️ partial, ❌ blocked, or no entry at all → still needs work.

3. **Build the run order from the dependency graph**, not just the index's numbered list — the
   numbers are a reasonable default ordering, but a goal's own DEPENDENCIES section is the
   authoritative constraint. A goal is eligible to start only once everything it depends on has a
   ✅ done log entry.

4. **Run each eligible goal, section by section, in the order the goal file lists them.**
   - Do the CONTEXT-confirmation part of the plan before editing anything, even when it feels
     redundant — it exists to catch drift between what the goal assumed and what's actually true now.
   - Stay inside CONSTRAINTS even under pressure to "also fix" something adjacent. A constraint that
     seems to conflict with a plan step is exactly what SAFETY NET is for — pause and resolve it
     there rather than picking a side yourself.
   - Verification is not optional and not skimmable. Run every command VERIFY lists — tests,
     typecheck, lint, architecture checks — and read the real output. Reason explicitly through any
     "manual QE" description you can't literally click through rather than skipping it.
   - If verification fails, go to SAFETY NET. Use exactly the attempt budget and inspection order it
     states, no more. Exhausting it means the goal is ❌ blocked (or ⚠️ partial if some of it
     demonstrably landed) — not something to keep improvising against.
   - If a step of this goal calls for producing or finalizing `pr-description.md`, load the
     `pr-description` skill first per PR Description Handoff above, and write the file from the shared
     log's actual entries rather than from this goal's own PLAN.
   - Only commit after verification fully passes, using the COMMIT section's command exactly as
     written.
   - Whatever happened, append the LOG entry in the exact format given, to the exact file named,
     before considering the goal finished — for blocked and partial outcomes too, not just success.
   - Never fabricate a tool result, test run, or commit hash. If a tool a goal names isn't actually
     available, say so and stop rather than approximating what it probably would have said.

5. **Use concurrency where the goal set allows it.** The index's parallelization notes and each goal's
   own "Parallel:" line identify goals that are independent of each other once shared dependencies are
   satisfied. If your environment lets you spawn parallel sub-agents or sub-tasks, use that for
   parallel-safe goals. If it doesn't, run them back to back in either order — correctness doesn't
   depend on which parallel-eligible goal goes first, only that both finish before the pair is treated
   as done.

6. **On a ❌ blocked outcome**, log it exactly as specified, then don't execute any goal whose
   DEPENDENCIES list the blocked one — they were scoped assuming the blocked goal's outcome exists.
   Mark them skipped-due-to-blocked-dependency in your own summary. Keep going on any goal that's
   independent of the block; a block shouldn't stall unrelated work that was already clear to proceed.

7. **Wrap up.** Stop only when every goal has reached a terminal outcome or is skipped-due-to-a-blocked-
   dependency — not before. Report per goal — outcome, commit hash if any, one line on why if blocked
   or skipped — and point to the shared log as the full record rather than re-pasting it.

## Decision Rules

- If a goal's CONTEXT claim no longer matches the environment, stop and flag it — don't force the plan
  through on a stale assumption.
- If a constraint and a plan step conflict, resolve it via SAFETY NET, not by silently picking one.
- If a tool a goal names is unavailable, say so and stop rather than approximating its result.
- If a goal is blocked, cascade the skip to its dependents only, and keep executing every other
  eligible, independent goal — a single blocked goal is never a reason to end the run early.
- Do not pause the run to ask whether to continue after a goal reaches a terminal outcome; only the
  three situations in the Autonomy Contract warrant stopping short of the full run order.

## Quality Bar

A valid execution run must satisfy all:

- Every goal actually eligible to run (dependencies satisfied, not already ✅ done) reached a terminal
  outcome — done, partial, or blocked — without a mid-run pause to ask whether to continue.
- Every VERIFY command was actually run, with real output read, not inferred.
- Every completed goal's commit used exactly its COMMIT section's message, with a recorded hash.
- Every attempted goal — done, partial, or blocked — has exactly one new LOG entry in the shared log
  file the goal names.
- No goal ran outside its CONSTRAINTS.
- No downstream goal ran on top of an unresolved ❌ blocked dependency.
- Any goal that finalized `pr-description.md` did so with the `pr-description` skill actually loaded
  from this skill's own directory — not from a path resolved inside `.goals/`, and not from memory of
  the expected structure.
- Parallel-safe goals were run concurrently where the environment supports it.

## Output Contract

Base artifacts touched or produced during execution:

- `log.<asset-id>-<feature-slug>.md` — gains one entry per attempted goal.
- `pr-description.md` — the planning-time stub is replaced with the finished description, but only by
  the last goal in the set and only when that goal's own sections call for it, per the `pr-description`
  skill's Output Contract.
- Working-tree changes and commits, scoped exactly to each goal's CONSTRAINTS and COMMIT message.

This skill does not create or restructure goal files, the index, or `.goals/` folder layout — that
remains the responsibility of the `plan-goal-breakdown` family. Children that produce or touch
additional artifacts (tracker updates, reconciliation notes) declare them in their own
`## Additional Output Contract`.

## Completion Checklist

The Quality Bar is authoritative; this checklist is the final operator pass before returning output.

- [ ] Goal set located via its index file; working branch confirmed or switched before any change.
- [ ] Shared log read first; already-✅-done goals skipped, ⚠️/❌/missing ones treated as pending.
- [ ] Run order built from each goal's DEPENDENCIES, not just index numbering.
- [ ] Every eligible goal executed section-by-section: context confirmed, constraints respected, every
  VERIFY command actually run, commit run verbatim only after verification passed.
- [ ] Every attempted goal has exactly one new shared-log entry, in the exact required format.
- [ ] Any goal calling for `pr-description.md` loaded `../pr-description/SKILL.md` from this skill's
  directory first, and wrote the file from shared-log evidence.
- [ ] Blocked goals stopped their dependents; independent goals still ran.
- [ ] Parallel-safe goals ran concurrently where possible.
- [ ] No mid-run pause asked whether to continue after a goal reached a terminal outcome — the run
  continued on its own until every eligible goal was terminal.
- [ ] Final report given per goal (outcome, commit hash, blocked/skipped reason), pointing to the
  shared log rather than re-pasting it.
