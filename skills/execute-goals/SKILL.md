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

Before processing any user request, read `../execute-goals-base/SKILL.md`, resolved relative to this
file's directory, and treat it as your primary global constraints. Then apply the rules below.

# Execute Goals

Baseline variant: local repository execution, no work-tracking integration, no graph-index gate.

## When To Use

- Execute, run, or continue a locally planned goal set (no Agility Story/Defect behind it).
- User wants goals executed section-by-section with resumable, logged progress.

## Specialization

Nothing added or changed beyond the base contract — this variant exists so a plain goal set has a
concrete, invocable skill without Agility or codebase-memory specifics.
