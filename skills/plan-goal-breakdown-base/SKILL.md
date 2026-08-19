---
name: plan-goal-breakdown-base
description: "Abstract base for the plan-goal-breakdown skill family. Shared contract for decomposing work into dependency-aware, commit-sized goal files: Agility asset ID rules, working-branch policy, the canonical goal template, the shared execution log, test scoping, naming conventions, and the quality bar."
user-invocable: false
disable-model-invocation: true
metadata:
  id: plan-goal-breakdown-base
  abstract: true
  role: base
  inherited-by: "plan-goal-breakdown, plan-goal-breakdown-agility, plan-goal-breakdown-codebase-memory, plan-goal-breakdown-agility-codebase-memory"
  references: "../pr-description/SKILL.md"
---

# Plan Goal Breakdown — Base

Abstract base: `user-invocable: false` + `disable-model-invocation: true`, reached only by a child
reading this file. Children layer specialization on top; everything here binds every child that does
not declare an override.

Job: turn a broad task into execution-ready goal files with explicit dependencies, parallelism, and
verification criteria.

## Inheritance Contract

Frontmatter has no inheritance key, so inheritance is declared in `metadata` and enforced by the
child's `# ⚠️ System Initialization Hook`, which reads every declared path before handling the request.
Keep both in sync:

```yaml
metadata:
  inherits: "plan-goal-breakdown-base, codebase-memory"        # parents, most general first
  parent-files: "../plan-goal-breakdown-base/SKILL.md, ../codebase-memory/SKILL.md"
  reference-files: ["references/mcp-evidence-contract.md"]     # shared docs, not parents
```

- Children add sections freely; they change base behavior only under a canonical heading below.
- An override is the smallest possible delta and never restates inherited text: quote the base bullet,
  then say prepend / replace / drop. Base text copied verbatim into a child is a bug — it forks
  silently the moment the base changes.

| Heading | Purpose |
|---|---|
| `## When To Use` | invocation scope |
| `## Specialization` | one paragraph on what this variant changes |
| `## Additional Inputs To Collect` | extra inputs, numbered on from the base list |
| `## Procedure Overrides` | bullet-level deltas to the base procedure |
| `## Goal Template Overrides` | replacement bracket bodies, structure unchanged |
| `## Additional Decision Rules` | extra rules, plus any base rule explicitly superseded |
| `## Additional Quality Bar` | extra pass/fail criteria |
| `## Additional Output Contract` | extra artifacts |
| `## Code Navigation Policy` | codebase-memory navigation and search restrictions |
| `## Index Prerequisite` | codebase-memory indexing hard gate |
| `## Agility Context Requirement` | Agility asset context and validation |
| `## Goal Authoring Policy` | codebase-memory goal-authoring requirements |
| `## Test Scoping Policy` | test detection, run scoping, test-authoring limits |
| `## Script` | executable reconciliation or integration procedure |

Anything outside these headings is a new policy, not an override.

Precedence: child override → this base (process and output contract) → other parents, authoritative
only in their own domain (`codebase-memory` owns graph tool syntax, never the goal-file contract).
Conflict with no declared override: base wins.

This family has no completion checklist. The Quality Bar is the single gate — never add a second list
restating it.

## Output Discipline (Required)

Applies to your own messages and to every line written into an artifact.

- Answer first. No preamble, no recap, no "now I will…" narration, no restating the plan back.
- Show, don't explain: a command, a path, a template line, a diff. Prose only where a rule cannot be
  shown.
- State each rule once. A sentence restating its neighbor gets cut.
- Goal-file bracket bodies are instructions: one imperative sentence plus one concrete example.
- Produce only what was asked for — no extra goals, summary docs, README edits, or migration notes
  nobody requested.

## Inputs To Collect

Agility is the work-tracking system; assets are stories (`S-#####`) or defects (`D-#####`).

1. Objective: one sentence.
2. Scope: in-scope vs out-of-scope.
3. Execution policy: commit-sized goals, count driven by complexity (see Decision Rules).
4. Dependency policy: `Depends on` / `Enables` / `Parallel`.
5. Existing assets: goal templates and goals already in the repo.
6. Agility asset ID — required (see Agility ID Requirement).
7. Working branch (see Working Branch Requirement).
8. PR description: wanted or not — ask, never assume (see PR Description Requirement).

Incomplete inputs → ask concise clarifying questions before writing files.

## Agility ID Requirement

Request the asset number before materializing anything; accept only `S-#####` or `D-#####`. It drives
the goal folder, goal filenames, index filename, log filename, and commit prefixes — artifacts this
skill owns outright.

## Working Branch Requirement

Branch names are often outside the user's control, so naming is a recommendation; only a protected
branch is a hard stop.

1. Determine the current branch. Not a git repo, or detached HEAD → ask where the work lands and use
   that answer.
2. **Hard stop — protected trunk.** Halt and ask for a working branch if the current branch is, case
   insensitively, `main`, `master`, `trunk`, `default`, `develop`, `development`, `dev`, `release`,
   `release/*`, `hotfix/*`, `support/*`, or anything the user or repo config calls protected.
   Recommended new name: `<asset-id>-<feature-slug>` (e.g. `S-12345-chat-fallback`).
3. **Otherwise confirm, don't halt.** Branch name already carries the asset ID → that is the
   confirmation, continue. Otherwise state the name, note the missing asset ID, ask proceed-or-switch,
   and accept "proceed" with the name unchanged — a non-conforming name is not a defect. Never rename a
   branch yourself.
4. Record the **actual** branch name in the index and every goal's `Branch:` slot. Never synthesize an
   idealized name, and never let the branch name affect the asset ID used in folders, filenames, or
   commit prefixes.

## PR Description Requirement (Optional — Ask First)

Ask once, while collecting inputs, whether this goal set should produce a `pr-description.md`:

- **No**, or no answer available (non-interactive run) → skip everything below: no stub, no deliverable
  on the last goal, no related quality-bar item. Record the decision in the index so a rerun neither
  re-asks nor silently re-adds it, and state the assumption in your summary. The `pr-description` skill
  can still be run directly against the finished branch later, so declining costs nothing.
- **Yes** → the rest of this section applies.

Read `../pr-description/SKILL.md` (relative to this file) before materializing the final goal file. It
owns structure and evidence rules; this base only decides when and which goal produces one.

**Inside goal artifacts, reference it by skill name, never by that path.** Skills-relative paths resolve
only from the skills folder; from `.goals/` the same string points at a nonexistent
`.goals/pr-description/SKILL.md`. This holds for every skills-relative path: goal artifacts carry skill
names or repo-root-relative paths only.

- The **last goal in the ordered sequence, and only that goal**, gains one deliverable: finalize
  `pr-description.md` in the same subfolder once every other goal's shared-log entry is **terminal**
  (`✅ done`, `⚠️ partial`, or `❌ blocked` — all three end a run and all three satisfy the gate; the
  `pr-description` skill already requires disclosing partial and blocked goals).
- Put it in that goal's own PLAN (final step), DONE WHEN (binary: the file exists, follows the required
  structure, and its "What changed" / "How to verify" come from the shared log's entries, not from this
  goal's PLAN), and VERIFY (confirm every other entry is terminal first).
- No new template section — it lives inside that goal's existing sections.
- At planning time it can only be stubbed (step 6); the last goal finishes it at execution time.

## Test Scoping Policy (Required)

Tests prove *this goal's change*, not the repository's health. Applies whenever PLAN, DONE WHEN, or
VERIFY touches tests.

1. **Detect before prescribing.** In step 1, establish whether a usable test setup exists: a runner in
   the manifest (`package.json` scripts, `pytest.ini`/`pyproject.toml`, `go test`, test `*.csproj`,
   Gradle/Maven surefire, …) *and* tests covering or adjacent to the touched code. Record the finding in
   CONTEXT.
   - Available → affected tests go in VERIFY, scoped per rules 2–4.
   - None reachable → do not invent one. No new runner, harness, fixture framework, or CI wiring unless
     the requested change itself needs it. Use deterministic manual checks and say so in CONTEXT.
2. **Scope the run.** Name the narrowest invocation covering the change:
   `npm test -- src/auth/login.test.ts`, `pytest tests/auth/test_login.py::test_rejects_expired`,
   `go test ./internal/auth/...`, `dotnet test --filter FullyQualifiedName~LoginTests`. Whole-repo runs
   (`npm test`, `pytest`, `go test ./...`) only when the change is genuinely cross-cutting (shared
   contract, build config, dependency bump, wide rename) or the runner cannot filter — and the goal must
   name which reason applies.
3. **Scope the tests you write.** Cover the behavior this goal adds, fixes, or breaks, nothing more.
   Extend the nearest existing test file in its existing style. No coverage backfill for untouched code,
   no coverage-percentage targets, no restructuring existing tests unless the goal is itself a
   test-refactor goal.
4. **Verification stays in its goal.** Goal N covers its own change plus regressions it could plausibly
   cause in the same module. Full regression, e2e sweeps, and perf runs belong to an explicit later goal
   when warranted — not appended to every VERIFY.
5. **Never name an unconfirmed command.** Script names come from the manifest you read, test paths from
   files you found. An unconfirmed test command is an unresolved claim (step 1) and cannot be
   materialized.

## Procedure

1. Discover context.

- Inspect branch/workspace changes relevant to the plan.
- Treat every supplied description, acceptance criterion, path, symbol, architecture claim, and code
  reference as an unverified hypothesis until checked against the current repo with the strongest
  available read-only navigation tool. A supplied reference is never its own proof.
- Record each material claim as confirmed, corrected, or unresolved. Never materialize a goal from an
  unresolved claim: take the smallest read that resolves it, or ask.
- Check the branch against the protected list; halt if protected. Confirm the branch unless its name
  carries the asset ID.
- Identify current architecture touchpoints and likely files affected.
- Find existing planning docs or goals to avoid duplication.

2. Extract decision points: primary and fallback strategy, configuration source-of-truth and runtime
   behavior, verification scope and what is deferred.

3. Decompose into goals: variable count driven by complexity, never a fixed number; each independently
   executable and reviewable; each focused on one concern (contract, plumbing, logic, resiliency, tests,
   rollout).

4. Define dependencies and parallelism: `Depends on`, `Enables`, `Parallel` as plain-text fields at the
   bottom of each goal file, using those exact labels. Build a strict order and mark parallel branches.

5. Materialize goal files under a new `.goals/<asset-id>-<feature-slug>/`, one file per goal from the
   template below, named `<sequence>-<asset-id>-<goal-slug>.md`.

- Calculate one single-line commit message per goal: `S-##### <concise action>` /
  `D-##### <concise action>`. Mandatory, not advisory; no `Co-authored-by` or other co-author trailer.
  The goal commits it as its final action after implementation and verification pass, and is not done
  until the commit succeeds and its hash is in the shared log.
- Record the confirmed branch, exactly as named, as goal metadata.
- Conventions: apply filename naming during generation; `00` is reserved for the index and its filename
  carries the same asset ID; stop and request correction if artifact naming or commit prefixes are
  violated (branch naming is exempt — it is confirmed, never enforced); reruns update artifacts in
  place, idempotently.
- Template sections: GOAL, CONTEXT, CONSTRAINTS, PRIORITY, PLAN, DONE WHEN, VERIFY, COMMIT, SAFETY NET,
  LOG, DEPENDENCIES.

6. Create the plan index `00-<asset-id>-index.md` carrying: the confirmed branch exactly as named
   (required — the execute-goals family reads it from here), ordered execution list, dependency graph,
   parallelization notes, and one line recording whether a PR description is planned.

- Create the log stub (skip if present):
  ```markdown
  # Execution Log: <asset-id>-<feature-slug>

  <!-- Each goal appends one entry here on completion or block. -->
  ```
- Create the PR description stub **only if the user asked for one** (skip if present):
  ```markdown
  # PR Description — <asset-id>-<feature-slug>

  <!-- Finalized by the last goal in this set, once every other goal's shared-log entry is terminal.
       Structure and evidence rules: the `pr-description` skill. -->
  ```

7. Validate against the Quality Bar before returning. In particular: read the manifest for runnable
   commands, confirm every script and test path exists, and pair commands with deterministic manual
   checks (human-in-the-loop is required, not optional).

## Goal Template (Required)

Canonical for the whole family. A child may replace individual bracket bodies via a declared
`## Goal Template Overrides`, never the structure.

```markdown
🎯 GOAL:
[One sentence, exact objective. (e.g., "Rewrite the user login module to enforce Zod validation.")]

🧠 CONTEXT:
[Background plus a validation ledger for every material supplied claim or code reference: the current-code evidence/tool confirming it, the corrected fact when it differs, or `unresolved` and why planning stopped. (e.g., "Request named auth_v1.ts; navigation confirmed it owns basic password matching.")]

📏 CONSTRAINTS:
[Hard scope boundaries. (e.g., "Do not alter the database schema. Backend routes only. TypeScript only.")]

📊 PRIORITY:
[Execution order inside this goal. (e.g., "Fix TypeErrors in unit tests first, then add the validation endpoints.")]

🗺️ PLAN:
[Numbered approach; test steps cover only what this goal changes. (e.g., "1. Inspect current routes. 2. Extend auth.test.ts for the new validation. 3. Implement Zod parsing. 4. Verify.")]

🛑 DONE WHEN:
[Binary, observable outcome, stated over the tests covering this change — not the whole suite. (e.g., "The 5 tests in auth.test.ts pass and the linter exits 0.")]

🔍 VERIFY:
[Exact commands plus deterministic manual checks, each narrowed per Test Scoping Policy; a whole-repo run carries its stated reason; omit test commands entirely when no test setup exists. (e.g., "Run `npm test -- src/auth/login.test.ts` and paste the raw output into the transcript.")]

✅ COMMIT:
Mandatory final action after verification passes: `git commit -m "<calculated S-##### or D-##### message>"`,
using exactly the calculated single-line message, with no co-author attribution. Record the hash in the
shared log entry. If the commit fails, this goal is not complete.

🛡️ SAFETY NET:
[Failure path and attempt budget. (e.g., "After 3 consecutive failures, halt and request human intervention.")]

📝 LOG:
Mandatory on completion or block, before finishing: append exactly one entry to
`.goals/<asset-id>-<feature-slug>/log.<asset-id>-<feature-slug>.md`. Never skip it, defer it, or write
it elsewhere.

## <goal-slug> — <YYYY-MM-DD>

- **Outcome**: ✅ done | ⚠️ partial | ❌ blocked
- **Files changed**: <list>
- **Commit**: <commit hash or "N/A — not committed">
- **Verify result**: <key command output or "N/A">
- **Notes**: <deviations, blockers, surprises>

🔗 DEPENDENCIES:
Branch: [Actual confirmed branch name, exactly as named]
Depends on: [Prerequisite goal IDs or `none`]
Enables: [Downstream goal IDs or `none`]
Parallel: [Parallelizable goal IDs or `none`]
```

`Branch:` is where the branch metadata lives. A child may replace its bracket body, never remove or
relocate the line.

## Decision Rules

- Architecture unclear → read-only exploration first, then draft.
- User points at existing settings/mechanisms → reuse them; never invent a parallel config path.
- Goal too large for one cohesive commit, or too coarse → split until each maps to one commit.
- Tiny goals that would always ship together, or over-granular steps → merge.
- Regenerating → re-apply the filename convention idempotently.

## Quality Bar

The single gate. A valid output satisfies all:

- Every goal is commit-sized, testable, independently reviewable, with binary DONE WHEN criteria and
  verification steps.
- Dependencies are explicit and acyclic; parallel goals are marked and safe to run concurrently.
- Verification pairs runnable commands (when available) with deterministic manual checks.
- Every test command names a confirmed script and path, is scoped to that goal's change, and states its
  reason if it is a whole-repo run; no goal adds a runner, harness, fixture framework, CI wiring, or
  coverage target the change does not require; authored tests cover only the changed behavior and extend
  the nearest existing test file.
- Every supplied description, acceptance criterion, and code reference used by a goal was validated
  against current code with the strongest available tool, and any mismatch is corrected in CONTEXT. No
  goal preserves a disproven or unresolved claim.
- Every goal carries a calculated single-line commit message prefixed `S-#####`/`D-#####`, and ends with
  a successful commit using exactly that message, no co-author attribution, hash recorded in the log.
- Every goal's `🔗 DEPENDENCIES:` `Branch:` slot names the real branch, matching the index; the branch is
  not a protected trunk.
- Naming: goal filenames follow the convention and stay idempotent across reruns; the goals subfolder
  and the `00` index filename carry the same asset ID; `00` is used by nothing else.
- The folder holds one index, one log stub, one file per goal, plus a `pr-description.md` stub only if
  the user asked for one. Variants may add artifacts (e.g. agility payload JSONs).
- Every goal has a `📝 LOG:` section with the shared log path and required entry format.
- The PR description answer was acted on: requested → the last goal's PLAN/DONE WHEN/VERIFY require
  finalizing `pr-description.md` per the `pr-description` skill, gated on every other entry being
  terminal; declined → no stub, no goal mentions it, index records the decision.
- No goal artifact contains a skills-relative path (`../pr-description/SKILL.md` and the like) — skill
  references in artifacts are by skill name.
- Each goal's constraints actively prevent scope creep, and the user gets a concise summary with
  next-step options.

## Output Contract

```
.goals/<asset-id>-<feature-slug>/           # asset-id is S-##### or D-#####
  00-<asset-id>-index.md
  log.<asset-id>-<feature-slug>.md
  01-<asset-id>-<goal-slug>.md
  02-<asset-id>-<goal-slug>.md              # continue the sequence per goal
  pr-description.md                         # only when the user asked for one
```

`pr-description.md` is stubbed at planning time (step 6) and finalized by the last goal at execution
time per the PR Description Requirement (this file may cite `../pr-description/SKILL.md`; artifacts may
not). Absent by design when declined.

Naming: zero-padded sequence prefix for deterministic order, then the asset ID, then a concise slug
describing implementation intent. Children declare extra artifacts in their own Output Contract.
