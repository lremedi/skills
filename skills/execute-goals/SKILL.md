---
name: execute-goals
description: >-
  Execute a goal set already produced by plan-goal-breakdown — reads the index and dependency
  graph, resumes from the shared log, runs each goal file's GOAL/CONTEXT/CONSTRAINTS/PRIORITY/PLAN/DONE
  WHEN/VERIFY/COMMIT/SAFETY NET/LOG/DEPENDENCIES sections faithfully, and reports outcomes. Use
  whenever the user asks to execute, run, work through, implement, or "kick off" a goal set, points
  at a ".goals/" folder or an index file like "00-story-id-index.md", or names a story/defect ID
  that already has goal files generated (e.g. "execute S-134278", "run the plan in .goals/..."). No
  external work-tracking integration — for Agility-linked goal sets use execute-goals-agility
  instead.
argument-hint: "Story/Defect ID or .goals/ folder path to execute"
user-invocable: true
disable-model-invocation: false
metadata:
  id: execute-goals
  inherits: execute-goals-base
  parent-files: "../execute-goals-base/SKILL.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from the base
skill file `../execute-goals-base/SKILL.md`, resolved relative to this file's directory. Treat its
contents as your primary global constraints, then apply the specialized rules below.

# Execute Goals

The baseline variant of the family: local repository execution, no external work-tracking
integration, no graph-index prerequisite. Same contract as the base with no additions.

## When To Use

- User asks to execute, run, or continue a goal set that was planned locally (no Agility Story/Defect
  behind it).
- User wants goals executed section-by-section with resumable, logged progress.

## Specialization

Nothing is added or changed beyond the base contract — this variant exists so a plain goal set has a
concrete, invocable skill without pulling in Agility or codebase-memory specifics.
