---
name: pr-description
description: >-
  Write a pull request description (the write-up a reviewer sees when the PR opens) for a set of
  committed changes: technical enough to name the exact files, functions, routes, and mechanisms
  that changed, and descriptive enough that a reviewer who didn't write the code understands why it
  exists and how to check it. Use whenever the user asks to write a "PR description," "PR comment,"
  "PR summary," or to "describe this branch/PR for review" — with or without a plan-goal-breakdown
  goal set behind it. Also used automatically when a goal set's final goal calls for producing
  pr-description.md once every other goal's shared-log entry is terminal.
argument-hint: "Branch/commit range or .goals/ folder to describe, plus the Agility asset ID if there is one"
user-invocable: true
disable-model-invocation: false
metadata:
  id: pr-description
  role: standalone
---

# PR Description

Two ways this gets used: someone asks for it directly against a branch or diff, or a
`plan-goal-breakdown` goal set's final goal calls for it once every goal in the set has landed. Either
way, the job is the same — turn a set of real commits into a description a reviewer can act on without
re-deriving the diff themselves.

Goal files reach this skill **by name**, never by path: a `.goals/` folder can't resolve a path relative
to the skills directory. The `execute-goals` family loads this file from its own location when a goal
calls for `pr-description.md` (see its "PR Description Handoff"). If you're editing a goal template or
stub, keep the reference as the skill name.

## Inputs To Collect

1. What to describe: a branch name / commit range, or a `.goals/<asset-id>-<feature-slug>/` folder.
   If both a goal set and a branch are available, prefer the goal set — it already carries structured
   evidence (CONTEXT, CONSTRAINTS, VERIFY, and the shared log's actual outcomes) that a raw diff
   doesn't.
2. The base branch the PR will open against, if it isn't obvious from the repo's default.

## Gathering Evidence

- **From a goal set (preferred when available).** Read the index file for the overview and dependency
  graph, read every goal file for GOAL/CONTEXT/CONSTRAINTS/VERIFY, and read the shared log for what
  actually happened — files changed, commit hashes, verify results, notes. The log is ground truth; a
  goal's PLAN was the intent, the log entry is what landed. Where they disagree, the log wins.
- **From a branch/commit range (no goal set).** Inspect the real commit log and the diff against the
  base branch. Don't describe intent you can't see in the diff — if a commit message claims something
  the diff doesn't show, note the discrepancy instead of repeating the claim.
- Either way, treat every claim the way the breakdown/execution skills do: confirmed by something you
  actually read (a log entry, a diff, a commit), never assumed from a title or ticket text alone.

## Required Structure

Use this template. Every section is required or explicitly omitted per Decision Rules — keep prose
tight rather than padding it; reviewers skim.

```markdown
## <asset-id or branch> — <concise title>

### Summary
2-4 sentences, plain language: what problem existed, what this changes, and why now. A reviewer who
never saw the ticket should understand the motivation from this paragraph alone.

### What changed
Prose, not a changelog — name the exact files, functions, routes, or components touched and the
mechanism of the change. "AttachmentListQueryService now filters the picker's candidate list to eight
supported content types before it reaches the bridge," not "updated attachment filtering." Group by
concern (contract, plumbing, tests) rather than listing files in isolation if there were several.

### Why this approach
Only the decisions that weren't obvious: a rejected alternative, a constraint that shaped the design, a
tradeoff a reviewer would otherwise question. Omit this section entirely if nothing here isn't already
self-evident from "What changed."

### How to verify
The exact commands a reviewer can run themselves, plus deterministic manual QE steps. Pull these
directly from each goal's VERIFY section when working from a goal set, or reconstruct them from the
repo's actual test/lint scripts when working from a bare diff. Never list a command that wasn't
actually run.

### Risk / rollback
Blast radius, feature flags, migration or rollback notes — only if there's something a reviewer needs
beyond "revert the commit." Omit if there's genuinely nothing here.

### Linked work
Agility asset ID and any mirrored Task/Test links, if applicable. Omit if there's no tracker involved.
```

## Decision Rules

- If a section would just restate the one above it in different words, cut it — don't pad structure
  for its own sake.
- When working from a goal set, the shared log's "Notes" fields often already contain the "why" and
  "risk" content — read them before writing those sections from scratch.
- If a goal in the set is ⚠️ partial or ❌ blocked, say so plainly in Summary and Risk/rollback. A PR
  description that smooths over incomplete work is worse than no description.
- "Technical" and "descriptive" aren't in tension: name the real symbol/file (technical) while still
  explaining what it's for in a sentence a non-implementer could follow (descriptive). Neither should
  crowd the other out.

## Output Contract

- Invoked directly: return the description in the response, and offer to save it as a file if the user
  wants one.
- Invoked from a goal set's final goal: write it to
  `.goals/<asset-id>-<feature-slug>/pr-description.md`, replacing any planning-time stub.

## Completion Checklist

- [ ] Evidence came from the shared log/goal files (if a goal set exists) or the actual diff/commit
  log (if not) — never from an unverified title or ticket text alone.
- [ ] Every required section present, or explicitly omitted per Decision Rules — none left as a
  placeholder.
- [ ] "What changed" names real files/functions/mechanisms, not a generic paraphrase.
- [ ] "How to verify" lists only commands that were actually run or scripts that actually exist.
- [ ] Any ⚠️ partial or ❌ blocked goal in the set is disclosed, not smoothed over.
