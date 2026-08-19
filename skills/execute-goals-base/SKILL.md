---
name: execute-goals-base
description: >-
  Abstract base for the execute-goals skill family. Shared contract for executing a goal set already
  produced by the plan-goal-breakdown family: locating the index and shared log, resuming from logged
  outcomes, building run order from the dependency graph, running each goal's own sections faithfully,
  concurrency for parallel-safe goals, block-cascade handling, and the final report.
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

Abstract base: `user-invocable: false` + `disable-model-invocation: true`, reached only by a child
reading this file. Children layer specialization on top; everything here binds every child that does
not declare an override.

This is the execution half of `plan-goal-breakdown`. Scoping, dependency analysis, and the exact
verification/commit steps were already decided and written into goal files. Carry them out faithfully,
one goal at a time, and leave an honest record — do not re-plan the work.

## Inheritance Contract

Frontmatter has no inheritance key, so inheritance is declared in `metadata` and enforced by the
child's `# ⚠️ System Initialization Hook`, which reads every declared path before handling the request.
Keep both in sync:

```yaml
metadata:
  inherits: "execute-goals-base, codebase-memory"          # parents, most general first
  parent-files: "../execute-goals-base/SKILL.md, ../codebase-memory/SKILL.md"
  reference-files: ["references/children-task-query.md"]   # shared docs, not parents
```

- Children add sections freely; they change base behavior only under a canonical heading below.
- An override is the smallest possible delta and never restates inherited text: quote the base bullet,
  then say prepend / replace / drop. Base text copied verbatim into a child is a bug.

| Heading | Purpose |
|---|---|
| `## When To Use` | invocation scope |
| `## Specialization` | one paragraph on what this variant changes |
| `## Additional Inputs To Collect` | extra inputs, numbered on from the base list |
| `## Procedure Overrides` | bullet-level deltas to the base procedure |
| `## Additional Decision Rules` | extra rules, plus any base rule explicitly superseded |
| `## Additional Quality Bar` | extra pass/fail criteria |
| `## Additional Output Contract` | extra artifacts or tracker side-effects |
| `## Code Navigation Policy` | codebase-memory navigation and search restrictions |
| `## Index Prerequisite` | codebase-memory indexing hard gate |
| `## Agility Context Requirement` | Agility asset context and validation |
| `## Goal Authoring Policy` | codebase-memory goal-authoring requirements |
| `## Script` | executable reconciliation or integration procedure |

Anything outside these headings is a new policy, not an override.

Precedence: child override → this base (execution contract) → other parents, authoritative only in
their own domain (`codebase-memory` owns graph tool syntax, never the execution contract). Conflict with
no declared override: base wins.

This family has no completion checklist. The Quality Bar is the single gate — never add a second list
restating it.

## Output Discipline (Required)

- Answer first. No preamble, no recap of the goal file back to the user, no "now I will…" narration.
- Show, don't explain: the command you ran, its real output, the commit hash, the file path.
- Build exactly what the goal specifies. No adjacent refactors, extra tests, doc updates, or comments
  the goal did not ask for.
- Report per goal in one line plus outcome; the shared log is the full record, so don't re-paste it.

## Anatomy of a Goal Set (Read-Only Input)

You never create or restructure these — `plan-goal-breakdown` does. Consume them exactly as written:

- **`00-<id>-index.md`** — ordered execution list, dependency graph, parallelization notes, working
  branch.
- **`NN-<id>-<slug>.md`** — one goal per file: 🎯 GOAL, 🧠 CONTEXT, 📏 CONSTRAINTS, 📊 PRIORITY, 🗺️ PLAN,
  🛑 DONE WHEN, 🔍 VERIFY, ✅ COMMIT, 🛡️ SAFETY NET, 📝 LOG, 🔗 DEPENDENCIES.
- **`log.<asset-id>-<feature-slug>.md`** — the shared file every goal appends one entry to.
- **`pr-description.md`** — optional planning-time stub, present only when the set was planned with one.
  When present it is the single exception to read-only: the last goal finalizes it per its own sections
  (see PR Description Handoff). Its absence is a planning decision, not a file to create.

Treat the labels, not the emoji, as the contract — a plain-text variant means the same thing.

| Section | What it obligates |
|---|---|
| GOAL | Nothing to build beyond this one sentence |
| CONTEXT | Trust it as verified; if the environment contradicts it, stop — that's new information, not a reason to force the plan through |
| CONSTRAINTS | A hard edge; a step that seems to need more is a signal to stop and check, not to expand scope |
| PRIORITY | Orders work only within what DEPENDENCIES already allows; it never overrides a dependency |
| PLAN | Work the steps in order — later ones assume earlier ones happened |
| DONE WHEN | Check your work against it before verifying |
| VERIFY | Run every check, read real output, never infer success |
| COMMIT | Run it verbatim — no reworded message, no co-author trailers |
| SAFETY NET | An attempt budget and inspection order, not a suggestion |
| LOG | Mandatory on every path — done, partial, or blocked |
| DEPENDENCIES | Determines run order and concurrency |

## Inputs To Collect

1. The goal set: a story/defect ID, a `.goals/` subfolder path, or an index file path. If several could
   match, ask which — don't guess.

## Autonomy Contract (Required)

A goal set is already-negotiated, execution-ready work, not a proposal to review. Its sections are the
full authorization to act; there is nothing to confirm before starting an eligible goal.

**Terminal** = the goal's most recent log entry is `✅ done`, `⚠️ partial`, or `❌ blocked`. Those are the
only outcomes, all three end a run, and all three satisfy a gate waiting on "every other goal terminal".
A partial still names its shortfall in the final report.

- **Act immediately on invocation.** Handed a goal, an index, or an asset ID, start the Procedure — no
  summarizing back, no asking whether to proceed with what the goal already states as decided.
- **Never pause between goals.** Finishing one is not a checkpoint; move to the next eligible goal until
  the run order is exhausted.
- **Don't re-ask what a goal answered.** COMMIT is the standing instruction to commit once VERIFY
  passes.
- **Every eligible goal reaches exactly one terminal state:** `✅ done` (DONE WHEN met, VERIFY passed,
  commit landed, log written), `⚠️ partial` (part demonstrably landed), `❌ blocked` (SAFETY NET budget
  exhausted, or a blocked dependency, with no path forward that doesn't need a human). Uncertainty is
  what the attempt budget is for — don't stop partway.
- **Only three things legitimately interrupt a run:** an unanticipated branch situation (protected trunk
  → halt: `main`, `master`, `trunk`, `default`, `develop`, `development`, `dev`, `release`, `release/*`,
  `hotfix/*`, `support/*`, case-insensitively, plus anything the user or repo config calls protected;
  and never rename a branch yourself); a SAFETY NET item only a human can decide (credential, product/UX
  call, missing fixture); or an environment/tool failure blocking that one goal. Even then only that
  goal is blocked — every other independent eligible goal keeps running.

## PR Description Handoff (Required When Present)

A PR description is optional at planning time, so the last goal *may* carry one extra deliverable:
finalize `pr-description.md`. If no goal's sections call for it, there is nothing to hand off — don't
create the file, don't load the skill, don't treat the missing stub as a defect.

When a goal does call for it, that goal names the **`pr-description` skill**, never a path — a path
written from inside `.goals/` cannot reach the skills folder. Resolving it is this skill's job:

- Read `../pr-description/SKILL.md`, relative to **this file's directory**, before writing anything into
  that file, and follow its Required Structure, Gathering Evidence rules, and Output Contract.
- Read it at that moment, not up front — one goal in the set needs it, so it stays out of the eager
  `parent-files` load.
- A goal file carrying a literal skills-relative path is a planning defect from an older run: resolve
  the skill from this file's directory anyway, note the stale reference in the summary, continue.
- If `../pr-description/SKILL.md` genuinely isn't readable, that's a tool failure for that one goal —
  say so, leave the stub untouched, take the SAFETY NET path. Never reconstruct the structure from
  memory.

## Procedure

1. **Locate the goal set and confirm the branch.**
   - Find `00-<id>-index.md` first, not a numbered goal file — it holds the branch, dependency graph,
     and parallelization notes no single goal repeats.
   - Confirm you are on the branch the index names before any change; switch to it if it exists.
   - Never create a branch and carry on, never proceed onto a protected trunk. No branch named, a
     missing branch, or a protected trunk → the branch interrupt above: halt and ask.

2. **Read the shared log and determine what still needs to run.** Match entries to goals by slug — the
   filename with sequence number and asset ID stripped, e.g.
   `01-S-12345-filter-supported-attachment-types.md` ↔ `## filter-supported-attachment-types`. Latest
   entry `✅ done` → skip, trusting the record unless something later contradicts it. `⚠️ partial`,
   `❌ blocked`, or no entry → still needs work.

3. **Build run order from the dependency graph**, not the index numbering — numbers are a default
   ordering, DEPENDENCIES is the constraint. A goal is eligible once everything it depends on has a
   `✅ done` entry.

4. **Run each eligible goal, section by section, in file order.**
   - Do the CONTEXT-confirmation part of the plan before editing anything — it catches drift.
   - Stay inside CONSTRAINTS even under pressure to "also fix" something adjacent; a constraint that
     seems to conflict with a step is what SAFETY NET is for.
   - Run every VERIFY command — tests, typecheck, lint, architecture checks — and read the real output.
     Reason explicitly through any manual QE step you cannot literally click through.
   - Run them as written and stop there: VERIFY's test scope was deliberately narrowed at planning time,
     so never widen a filtered invocation into a whole-repo run, and never add suites, coverage runs, or
     test files the goal didn't ask for. A failure outside this goal's scope is log/SAFETY NET
     information, not new work.
   - A VERIFY command that no longer exists (missing script, moved path, no test setup) is drift: say so,
     fall back to the goal's manual checks, record it in the log Notes. Don't stand up a runner or
     substitute a suite.
   - Verification failure → SAFETY NET, using exactly its attempt budget and inspection order.
     Exhausted → `❌ blocked`, or `⚠️ partial` if part demonstrably landed. Don't keep improvising.
   - A step calling for `pr-description.md` → load the `pr-description` skill first per the handoff, and
     write from the shared log's entries, not from this goal's PLAN.
   - Commit only after verification fully passes, using COMMIT's command exactly.
   - Append the LOG entry in the exact format, to the exact file, before considering the goal finished —
     blocked and partial included.
   - Never fabricate a tool result, test run, or commit hash. A named tool that isn't available → say so
     and stop.

5. **Use concurrency where the set allows it.** The index's parallelization notes and each goal's
   `Parallel:` line identify independent goals. Spawn parallel sub-agents if the environment supports it;
   otherwise run them back to back in either order.

6. **On `❌ blocked`**, log it as specified, then skip every goal whose DEPENDENCIES name it, marking them
   skipped-due-to-blocked-dependency in your summary. Keep executing everything independent of the block.

7. **Wrap up** only when every goal is terminal or skipped-due-to-blocked-dependency. Report per goal:
   outcome, commit hash if any, one line on why if blocked or skipped.

## Decision Rules

- A CONTEXT claim no longer matching the environment → stop and flag it, don't force a stale assumption.
- A constraint conflicting with a plan step → resolve via SAFETY NET, never by silently picking one.
- A named tool unavailable → say so and stop; never approximate its result.
- A blocked goal → cascade the skip to its dependents only, and keep running every other eligible goal.
- Never pause to ask whether to continue after a terminal outcome; only the Autonomy Contract's three
  situations justify stopping short.

## Quality Bar

The single gate. A valid run satisfies all:

- Every eligible goal (dependencies satisfied, not already `✅ done`) reached a terminal outcome, with no
  mid-run pause asking whether to continue.
- Every VERIFY command was actually run, with real output read, not inferred, and as written — not
  widened, not supplemented with extra suites, coverage runs, test files, or a substituted runner. A
  command that no longer exists was reported and logged as drift.
- Every completed goal's commit used exactly its COMMIT message, with a recorded hash.
- Every attempted goal — done, partial, or blocked — has exactly one new entry in the shared log file it
  names, in the required format.
- No goal ran outside its CONSTRAINTS, and no downstream goal ran on an unresolved `❌ blocked`
  dependency; blocked goals stopped their dependents while independent goals still ran.
- Any goal that finalized `pr-description.md` did so with the `pr-description` skill loaded from this
  skill's own directory and wrote it from shared-log evidence — not from a `.goals/`-relative path, and
  not from memory of the structure.
- Parallel-safe goals ran concurrently where the environment supports it.
- The final report covers each goal (outcome, commit hash, blocked/skipped reason) and points at the
  shared log instead of re-pasting it.

## Output Contract

- `log.<asset-id>-<feature-slug>.md` — one new entry per attempted goal.
- `pr-description.md` — stub replaced with the finished description, only by the last goal and only when
  its own sections call for it, per the `pr-description` skill's Output Contract.
- Working-tree changes and commits, scoped exactly to each goal's CONSTRAINTS and COMMIT message.

This skill never creates or restructures goal files, the index, or `.goals/` layout — that stays with
`plan-goal-breakdown`. Children declare additional artifacts or tracker side-effects in their own
`## Additional Output Contract`.
