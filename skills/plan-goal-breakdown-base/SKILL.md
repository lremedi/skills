---
name: plan-goal-breakdown-base
description: "Abstract base for the plan-goal-breakdown skill family. Defines the shared contract for decomposing work into dependency-aware, commit-sized goal files: Agility asset ID rules, working-branch policy (protected-branch hard stop, otherwise confirm), the canonical goal template, the shared execution log, naming conventions, quality bar, and completion checklist."
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

Abstract base skill. Not directly invocable: `user-invocable: false` hides it from the `/` menu and
`disable-model-invocation: true` stops the agent from auto-loading it. It is only ever reached by a
child reading this file.

Child skills inherit this file and layer their own specialization on top. Everything below is a
global constraint for every child unless that child explicitly declares an override.

Create execution-ready goal files from a broad task, with explicit dependencies, parallelism, and
verification criteria.

## Inheritance Contract

Inheritance is not a native frontmatter feature — VS Code accepts only `name`, `description`,
`license`, `compatibility`, `metadata`, `argument-hint`, `user-invocable`,
`disable-model-invocation`, and `context` in a skill file. So it is expressed in two parts:

- **Declared** in the supported free-form `metadata` map, for humans and tooling to read:
  ```yaml
  metadata:
    id: plan-goal-breakdown-codebase-memory
    inherits: "plan-goal-breakdown-base, codebase-memory"
    parent-files: "../plan-goal-breakdown-base/SKILL.md, ../codebase-memory/SKILL.md"
  ```
- **Enforced** by the child's `# ⚠️ System Initialization Hook` section, which instructs the agent to
  read every path in `metadata.parent-files` before processing any user request. The hook is the
  actual mechanism; `metadata` is only the declaration. Keep the two in sync — if you add a parent,
  add it to both.

Rules:

- Children list parents most general first, and must read every parent they list.
- Children may **add** sections (new policies, new artifacts, new procedure steps).
- Children may **override** a section only by naming it explicitly under one of the canonical
  extension-point headings below. Silent divergence is not allowed.

Canonical extension-point headings — use these exact names so a reader can diff any two children:

| Heading | Purpose |
|---|---|
| `## Specialization` | one-paragraph statement of what this variant changes |
| `## Additional Inputs To Collect` | extra inputs, numbered continuing from the base list |
| `## Procedure Overrides` | bullet-level deltas to the base procedure |
| `## Goal Template Overrides` | replacement bracket bodies, structure unchanged |
| `## Additional Decision Rules` | extra rules, plus any base rule explicitly superseded |
| `## Additional Quality Bar` | extra pass/fail criteria |
| `## Additional Output Contract` | extra artifacts |
| `## Additional Completion Checklist` | extra operator checks |

Anything a child declares outside these headings is a new policy of its own, not an override.
- An override must be the **smallest possible delta, and must never restate inherited text.** Quote
  the base bullet or section being changed and say prepend / replace / drop — do not re-type a whole
  procedure step to alter one bullet of it. Any line copied verbatim from this base into a child is a
  bug: it silently forks the moment the base changes, and re-typing a step tends to drop the bullets
  you did not mean to touch.

Precedence, highest first:

1. A child's explicitly declared override.
2. This base — authoritative for process and output contract: inputs, asset ID and branch rules,
   procedure, goal template, naming conventions, quality bar, completion checklist.
3. Any additional parent — authoritative only within its own domain. `codebase-memory` is the
   authority for knowledge-graph tool names, call syntax, workflows, and gotchas; it never changes
   the goal-file contract above.

Where a child's rule conflicts with this base and no override is declared, this base wins.

## Inputs To Collect

Agility is the team work-tracking system where assets are identified as story IDs (`S-#####`) or
defect IDs (`D-#####`).

1. Objective: single-sentence target outcome.
2. Scope boundaries: what is in-scope vs out-of-scope.
3. Execution policy: commit-sized goals sized by task complexity (no fixed goal count; apply
   sizing/merge-split rules from Decision Rules).
4. Dependency policy: required interdependency format (`depends_on`, `enables`, parallelizable
   units).
5. Existing assets: goal templates and existing goals in repo.
6. Agility asset ID: required story or defect number for artifact naming and commit prefixes.
7. Working branch: confirmation of which branch the work lands on. Preserve whatever name it already
   has; see Working Branch Requirement.

If these are incomplete, ask concise clarifying questions before writing files.

## Agility ID Requirement

- Always request the Agility asset number before materializing goals.
- Accept only `S-#####` (story) or `D-#####` (defect) format.

The asset ID is required for **goal folder, goal filenames, index filename, log filename, and commit
message prefixes**. Those are artifacts this skill creates, so it controls their naming completely.

## Working Branch Requirement

The branch is different: its name is often outside the user's control (shared feature branch,
vendor/integration branch, a branch someone else created). Branch naming is therefore a
**recommendation**, not a gate. Only working on a protected branch is a hard stop.

1. Determine the current branch. If the workspace is not a git repository, or HEAD is detached, do
   not guess: ask the user where the work should land and treat their answer as the working branch.

2. **Hard stop — protected branch.** If the current branch is a shared/protected trunk, do not plan
   work onto it. Halt and ask the user to create or switch to a working branch first. Treat as
   protected, case-insensitively:

   - `main`, `master`, `trunk`, `default`
   - `develop`, `development`, `dev`
   - `release`, `release/*`, `hotfix/*`, `support/*`
   - any branch the user or repo config identifies as protected

   Recommended name for the new branch: `<asset-id>-<feature-slug>`, for example
   `S-12345-chat-fallback` or `D-67890-chat-fallback`.

3. **Otherwise — confirm, do not halt.** On any non-protected branch, ask the user once to confirm
   this is where they want the work to land, then proceed. Never rename the branch yourself.
   - If the branch name already contains the same asset ID: treat that as confirmation and continue
     without asking.
   - If it does not: state the branch name, note that it does not carry the asset ID, and ask whether
     to proceed here or switch. Accept "proceed" and continue with the name unchanged — a
     non-conforming name is not a defect.

4. Record the **actual** branch name in the index and in each goal's `Branch:` slot. Never synthesize an idealized
   `<asset-id>-<feature-slug>` value that does not match the real branch, and never let the branch
   name change the asset ID used for folders, filenames, or commit prefixes — those come from the
   asset ID alone and are unaffected by a non-conforming branch.

## PR Description Requirement (Required)

Before materializing the final goal file — the highest-numbered goal in the ordered sequence — read
`../pr-description/SKILL.md`, resolved relative to this file's directory. It defines the exact
structure and evidence rules for a PR description; this base only decides *when* and *which* goal
produces one, not what it should contain.

**Reference it by skill name inside goal artifacts, never by that path.** `../pr-description/SKILL.md`
is resolvable only from this file's own directory, inside the skills folder. Anything written into
`.goals/<asset-id>-<feature-slug>/` — a goal file, the index, the `pr-description.md` stub — is read
from the goals folder at execution time, where the same string resolves to
`.goals/pr-description/SKILL.md` and does not exist. In goal artifacts, name the **`pr-description`
skill**; the executing skill resolves it from its own location (see the execute-goals family's
"PR Description Handoff"). This applies to every skills-relative path, not just this one: goal
artifacts get skill names or repo-root-relative paths, never paths relative to a skill directory.

- The **last goal in the ordered sequence, and only that goal**, gets an added deliverable: finalize
  `pr-description.md` in the same subfolder, following the required structure defined by the
  `pr-description` skill, once every other goal in the set has a **terminal** shared-log entry —
  `✅ done`, `⚠️ partial`, or `❌ blocked`. All three end a goal's run and all three satisfy this gate;
  the `pr-description` skill already requires disclosing any partial or blocked goal in its Summary and
  Risk/rollback sections, so a partial sibling is something to describe honestly, not something to wait
  on forever. Write that reference into the goal as the skill name — the goal file must not carry a
  skills-relative path.
- Add this as the final step of that goal's own PLAN, and as an added binary criterion in its DONE
  WHEN: `pr-description.md` exists, follows the required structure, and its "What changed" / "How to
  verify" content is drawn from the shared log's actual entries — not restated from this one goal's
  PLAN in isolation.
- Add a corresponding VERIFY check to that goal: confirm every other goal's shared-log entry is
  terminal before treating `pr-description.md` as complete. A PR description written while sibling
  goals are still pending is incomplete by construction, not a draft to refine later.
- This does not change the Goal Template's structure. The added deliverable lives inside that one
  goal's own PLAN/DONE WHEN/VERIFY content, the same way any other task-specific detail does — no new
  template section is introduced.
- At materialization time, the description can only be scaffolded, not finished — no other goal has
  executed yet. Create the stub in step 6 below; the last goal finishes it later, at execution time.

## Procedure

1. Discover context.

- Inspect branch/workspace changes relevant to the requested plan.
- Treat every user-provided description, acceptance criterion, file path, symbol, architecture claim,
  and code reference as an unverified hypothesis until checked against the current repository. Use the
  strongest available read-only repository, language-service, or agent-provided navigation tool; do
  not use a supplied reference as proof that it is current or accurate.
- Record each material claim as confirmed, corrected, or unresolved. Do not materialize a goal from
  an unresolved claim: take the smallest additional read that can resolve it, or ask the user for
  clarification when the code cannot decide.
- Check the current branch against the protected list; halt if protected (see Working Branch
  Requirement).
- Confirm the working branch with the user unless its name already carries the asset ID.
- Identify current architecture touchpoints and likely files affected.
- Find existing planning docs or goals to avoid duplication.

2. Extract decision points.

- Decide primary strategy and fallback strategy.
- Confirm configuration source-of-truth and runtime behavior.
- Confirm verification scope and what is deferred.

3. Decompose into goals.

- Produce a variable number of commit-sized goals based on task complexity.
- Never force a fixed goal count.
- Each goal must be independently executable and reviewable.
- Keep each goal focused on one concern (contract, plumbing, logic, resiliency, tests, rollout).

4. Define dependencies and parallelism.

- For each goal specify:
  - `Depends on`
  - `Enables`
  - `Parallel`
- Build a strict order and identify parallel branches.

Dependency metadata default format:

- Keep dependency metadata in plain text fields at the bottom of each goal file.
- Use consistent labels (`Depends on`, `Enables`, `Parallel`) for easy human scanning.

5. Materialize goal files.

- Create a new subfolder under `.goals/<asset-id>-<feature-slug>/`.
- Save one file per goal using the goal template below.
- Prepend the Agility asset ID to each goal filename:
  - `<sequence>-S-#####-<goal-slug>.md`
  - `<sequence>-D-#####-<goal-slug>.md`
- Calculate one single-line commit message per goal with this format:
  - `S-##### <concise action>`
  - `D-##### <concise action>`
- Include the calculated message in the goal and execute `git commit -m "<calculated message>"` as
  the final action after all implementation and verification steps pass.
- The commit message is mandatory, not advisory. Do not add a `Co-authored-by` trailer or any other
  co-author attribution.
- Do not mark the goal done until the commit succeeds and its commit hash is recorded in the shared
  log entry.
- Include the confirmed working branch as required goal metadata for each goal, recorded exactly as
  the branch is actually named.
- Convention enforcement:
  - Apply the goal filename convention during generation.
  - `00` is reserved for the index file only, and the `00` index filename must include the same
    Agility asset ID.
  - Enforce strict validation on artifact naming and commit prefixes: if those conventions are
    violated, stop and request correction before continuing. Branch naming is excluded — it is
    confirmed with the user, never enforced.
  - Enforce idempotently when re-running the skill (update generated artifacts in place, no
    duplicated naming text).
- Goal template sections: GOAL, CONTEXT, CONSTRAINTS, PRIORITY, PLAN, DONE WHEN, VERIFY,
  SAFETY NET, LOG, DEPENDENCIES.

6. Create plan index.

- Add `00-S-#####-index.md` or `00-D-#####-index.md` with:
  - the confirmed working branch, recorded exactly as the branch is actually named (required — the
    execute-goals family reads the branch from here)
  - ordered execution list
  - dependency graph
  - parallelization notes
- Create `log.<asset-id>-<feature-slug>.md` stub in the same subfolder (skip if it already exists):
  ```markdown
  # Execution Log: <asset-id>-<feature-slug>

  <!-- Each goal appends one entry here on completion or block. -->
  ```
- Create `pr-description.md` stub in the same subfolder (skip if it already exists):
  ```markdown
  # PR Description — <asset-id>-<feature-slug>

  <!-- Finalized by the last goal in this set, once every other goal's shared-log entry is terminal.
       Structure and evidence rules: the `pr-description` skill. -->
  ```

7. Validate quality.

- Ensure no missing dependency links.
- Ensure each goal has binary done criteria and verification steps.
- Ensure every supplied description and code reference used by a goal is represented in its context
  as confirmed evidence or as an explicit correction; no goal may silently preserve a disproven or
  unresolved claim.
- Inspect `package.json` or the equivalent manifest and include runnable verification commands when
  available.
- Always include deterministic manual verification steps in addition to commands (human-in-the-loop
  validation requirement).
- Ensure constraints prevent scope creep.

## Goal Template (Required)

Use this exact template structure for every goal file. This template is the canonical source of
truth for the whole skill family; a child may replace individual bracket bodies only via a declared
`## Goal Template Overrides` section, never the structure.

```markdown
🎯 GOAL:
[State the exact, single-sentence objective. (e.g., "Rewrite the user login module to enforce Zod validation.") ]

🧠 CONTEXT:
[Provide necessary background plus a validation ledger for every material supplied claim or code reference used by this goal. State the current-code evidence/tool that confirms it, the corrected fact when it differs, or `unresolved` and why planning stopped. (e.g., "The request named auth_v1.ts; current-code navigation confirmed it owns basic password matching.")]

📏 CONSTRAINTS:
[List hard scope boundaries. (e.g., "Do not alter the database schema. Only modify backend routes. Stick to Typescript.") ]

📊 PRIORITY:
[Control execution order. (e.g., "Start by fixing TypeErrors in unit tests, then implement the new validation endpoints.")]

🗺️ PLAN:
[State the general approach explicitly to guide the agent. (e.g., "1. Inspect current routes. 2. Draft tests. 3. Implement Zod parsing. 4. Verify.")]

🛑 DONE WHEN:
[Define a binary, observable outcome. (e.g., "All 5 unit tests in auth.test.ts pass and the linter exits cleanly with 0 errors.")]

🔍 VERIFY:
[Make the agent run specific commands and deterministic manual checks to prove success. (e.g., "Run `npm run test` and paste the raw output into the session transcript.")]

✅ COMMIT:
Mandatory final action after verification passes: run `git commit -m "<calculated S-##### or D-##### message>"`.
Use exactly the calculated single-line message. Do not add `Co-authored-by` or any other co-author
attribution. Record the resulting commit hash in the shared log entry. If the commit fails, do not
mark this goal complete.

🛡️ SAFETY NET:
[State what to do on failure. (e.g., "If errors happen 3 times in a row, halt and request human intervention rather than retrying.")]

📝 LOG:
Mandatory: when this goal is completed or blocked, append exactly one entry to
`.goals/<asset-id>-<feature-slug>/log.<asset-id>-<feature-slug>.md` before finishing.
Do not skip, defer, or write the entry in any other file.

Entry format:

## <goal-slug> — <YYYY-MM-DD>

- **Outcome**: ✅ done | ⚠️ partial | ❌ blocked
- **Files changed**: <list>
- **Commit**: <commit hash or "N/A — not committed">
- **Verify result**: <paste key command output or "N/A">
- **Notes**: <deviations from plan, blockers, anything surprising>

🔗 DEPENDENCIES:
Branch: [The actual confirmed working branch name, exactly as it is named]
Depends on: [List prerequisite goal IDs or `none`]
Enables: [List downstream goal IDs or `none`]
Parallel: [List parallelizable goal IDs or `none`]
```

`Branch:` is the slot the branch metadata required by step 5 and the Quality Bar lives in. It is part of
the canonical structure, so a child may replace its bracket body via `## Goal Template Overrides` but may
not remove or relocate the line.

## Decision Rules

- If architecture is unclear: run read-only exploration first, then draft.
- If user asks for existing settings/mechanisms: reuse current system; do not invent parallel config
  paths.
- If a goal is too large for one cohesive commit: split it.
- If multiple tiny goals would always ship together: merge them.
- If goals are too coarse: split until each can map to one coherent commit.
- If goals are too granular: merge related low-risk steps.
- If regenerating goals: re-apply goal filename naming convention idempotently.

## Quality Bar

A valid output must satisfy all:

- Every goal is commit-sized and testable.
- Dependencies are explicit and acyclic.
- Parallelizable goals are marked and safe to execute concurrently.
- Verification includes runnable commands when available and deterministic manual checks when needed.
- Every user-provided description, acceptance criterion, and code reference used in a goal was
  validated against current code with the strongest available navigation/inspection tool, and any
  mismatch is explicitly corrected in goal context.
- Every goal includes a calculated, single-line commit message prefixed with `S-#####` or
  `D-#####`.
- Every completed goal ends with a successful `git commit` using exactly its calculated message,
  with no co-author attribution, and records its commit hash in the shared log.
- Every goal names the actual confirmed working branch in its `🔗 DEPENDENCIES:` block's `Branch:` slot,
  whether or not that name carries the asset ID, and the index records the same name.
- The working branch is not a protected trunk.
- Goal filename naming convention is enforced by the skill itself and remains idempotent on reruns.
- Goals subfolder naming convention includes the same `S-#####` or `D-#####` asset ID.
- `00` is used only by the index file, and the index file name includes the same `S-#####` or
  `D-#####` asset ID.
- Folder contains one index, one log stub, plus one file per goal.
- Every goal includes a `📝 LOG:` section with the shared log file path and required entry format.
- The last goal in the ordered sequence includes, in its own PLAN/DONE WHEN/VERIFY, the requirement to
  finalize `pr-description.md` per the `pr-description` skill, gated on every other goal's shared-log
  entry being terminal.
- No goal artifact (goal file, index, log, or `pr-description.md` stub) contains a skills-relative
  path such as `../pr-description/SKILL.md` — those resolve only from inside the skills folder, not
  from `.goals/`. Skill references in artifacts are by skill name.

## Output Contract

Default artifact structure:

- Story variant:
  - `.goals/S-#####-<feature-slug>/00-S-#####-index.md`
  - `.goals/S-#####-<feature-slug>/log.S-#####-<feature-slug>.md`
  - `.goals/S-#####-<feature-slug>/01-S-#####-*.md`
  - `.goals/S-#####-<feature-slug>/02-S-#####-*.md`
- Defect variant:
  - `.goals/D-#####-<feature-slug>/00-D-#####-index.md`
  - `.goals/D-#####-<feature-slug>/log.D-#####-<feature-slug>.md`
  - `.goals/D-#####-<feature-slug>/01-D-#####-*.md`
  - `.goals/D-#####-<feature-slug>/02-D-#####-*.md`
- Continue the same sequence pattern for each additional goal file.

Every variant additionally produces:

- `.goals/<asset-id>-<feature-slug>/pr-description.md` — stub created at planning time (step 6),
  finalized by the last goal at execution time per the PR Description Requirement above and the
  `pr-description` skill (this file may cite it as `../pr-description/SKILL.md`; the stub and goal
  files may not).

Children that produce extra artifacts declare them in their own Output Contract section, additive to
this list.

Goal naming convention:

- Prefix with zero-padded sequence for deterministic execution order.
- Prefix the goal slug with the Agility asset ID (`S-#####` or `D-#####`).
- Use concise slug names describing implementation intent.

## Completion Checklist

The Quality Bar is authoritative; this checklist is the final operator pass before returning output.

- [ ] Clarifications resolved or documented assumptions made.
- [ ] Every material supplied description and code reference was verified against current code with
  the strongest available tool; discrepancies are corrected in goal context and unresolved
  claims were clarified before materializing goals.
- [ ] Agility asset ID captured in `S-#####` or `D-#####` format.
- [ ] Current branch checked against the protected list; halted if protected.
- [ ] Working branch confirmed with the user (or auto-confirmed because its name carries the asset
      ID), and its name left unchanged.
- [ ] Each goal's `🔗 DEPENDENCIES:` block carries a `Branch:` line with the real branch name, the index
  records the same name, and each goal has a calculated single-line commit message.
- [ ] Each completed goal has a successful final commit using its calculated message, no co-author
  attribution, and the recorded commit hash in the shared log.
- [ ] Goal filename naming convention applied idempotently.
- [ ] Goals persisted to `.goals/<asset-id>-<feature-slug>/`.
- [ ] `00-S-#####-index.md` or `00-D-#####-index.md` created with dependency order.
- [ ] `log.<asset-id>-<feature-slug>.md` stub created in the goals folder.
- [ ] Each goal includes a `📝 LOG:` section with the correct shared log file path.
- [ ] `pr-description.md` stub created in the goals folder; the last goal's file includes the
  requirement to finalize it once every other goal's shared-log entry is terminal, referencing the
  `pr-description` skill by name rather than by a skills-relative path.
- [ ] User receives concise summary and next-step options.
