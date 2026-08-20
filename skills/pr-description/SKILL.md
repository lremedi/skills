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

Invoked directly against a branch or diff, or by a `plan-goal-breakdown` goal set's final goal once every
other goal has landed. Either way: turn real commits into a description a reviewer can act on without
re-deriving the diff.

Goal artifacts reference this skill **by name**, never by path — a `.goals/` folder cannot resolve a
skills-relative path. The `execute-goals` family loads this file from its own location (see its "PR
Description Handoff"). Keep templates and stubs referencing the skill name.

## Inputs To Collect

1. What to describe: a branch/commit range, or a `.goals/<asset-id>-<feature-slug>/` folder. With both
   available, prefer the goal set — it carries structured evidence (CONTEXT, CONSTRAINTS, VERIFY, and the
   shared log's actual outcomes) a raw diff doesn't.
2. The base branch the PR opens against, if not obvious from the repo default.

## Gathering Evidence

- **From a goal set (preferred).** Index for the overview and dependency graph, every goal file for
  GOAL/CONTEXT/CONSTRAINTS/VERIFY, and the shared log for what actually happened — files changed, commit
  hashes, verify results, notes. PLAN was intent; the log is ground truth. Where they disagree, the log
  wins.
- **From a branch/commit range.** Read the real commit log and the diff against the base branch. Never
  describe intent the diff doesn't show — a commit message claiming more than the diff delivers is a
  discrepancy to note, not a claim to repeat.
- Either way: every statement traces to something you read (log entry, diff, commit), never to a title or
  ticket text.

## Required Structure

Every section is required or explicitly omitted per Decision Rules. Reviewers skim — keep it tight.

```markdown
## <asset-id or branch> — <concise title>

### Summary
2-4 sentences, plain language: what problem existed, what this changes, why now. A reviewer who never saw
the ticket should get the motivation from this paragraph alone.

### What changed
Prose, not a changelog — name the exact files, functions, routes, or components touched and the mechanism.
"AttachmentListQueryService now filters the picker's candidate list to eight supported content types before
it reaches the bridge," not "updated attachment filtering." Group by concern (contract, plumbing, tests)
rather than listing files in isolation.

### Why this approach
Only non-obvious decisions: a rejected alternative, a constraint that shaped the design, a tradeoff a
reviewer would question. Omit if it's already self-evident from "What changed."

### How to verify
The exact commands a reviewer can run, plus deterministic manual QE steps — pulled from each goal's VERIFY
section, or reconstructed from the repo's actual test/lint scripts for a bare diff. Scoped to what this
change touches: the specific test files or filters that were run, never a whole-suite command nobody ran.
Never list a command that wasn't actually run.

### Risk / rollback
Blast radius, feature flags, migration or rollback notes — only if a reviewer needs more than "revert the
commit." Omit if there's nothing.

### Linked work
Agility asset ID and any mirrored Task/Test links. Omit if there's no tracker.
```

## Decision Rules

- A section that restates the one above it in other words gets cut — no padding structure for its own sake,
  and no section left as a placeholder.
- From a goal set: the shared log's "Notes" fields usually already hold the "why" and "risk" content — read
  them before writing those sections from scratch.
- A ⚠️ partial or ❌ blocked goal is disclosed plainly in Summary and Risk/rollback. A description that
  smooths over incomplete work is worse than none.
- "Technical" and "descriptive" aren't in tension: name the real symbol/file, then say what it's for in a
  sentence a non-implementer follows.

## Output Contract

- Invoked directly → return the description in the response; offer to save it as a file.
- Invoked from a goal set's final goal → write
  `.goals/<asset-id>-<feature-slug>/pr-description.md`, replacing any planning-time stub.
