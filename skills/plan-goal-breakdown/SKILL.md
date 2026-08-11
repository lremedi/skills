---
name: plan-goal-breakdown
description: "Break a feature/refactor plan into dependency-aware, commit-sized goal files. Use when users ask to plan implementation, split work into goals, persist goals in files, determine parallelism, and track dependencies/dependants."
argument-hint: "Task to decompose + scope constraints + preferred goals folder"
user-invocable: true
disable-model-invocation: false
metadata:
  id: plan-goal-breakdown
  inherits: plan-goal-breakdown-base
  parent-files: "../plan-goal-breakdown-base/SKILL.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, you MUST locate, read, and append the instructions from the base
skill file `../plan-goal-breakdown-base/SKILL.md`, resolved relative to this file's directory. Treat
its contents as your primary global constraints, then apply the specialized rules below.

# Plan Goal Breakdown

The baseline variant of the family: local repository exploration, no external work-tracking
integration, no graph-index prerequisite.

## When To Use

- User asks to "plan this", "break into goals", "make commit-sized goals", or "persist goals in
  files".
- Work needs dependency ordering and safe parallel execution.
- Team wants deterministic implementation slices, each with clear done criteria.

## Specialization

- Verification scope is typecheck/unit/e2e as available in the repo; confirm which are in scope and
  which are deferred.
- Discovery is ordinary read-only repository exploration.
- No additional artifacts beyond the base Output Contract.

Everything else — inputs, Agility ID and branch rules, procedure, goal template, decision rules,
quality bar, output contract, completion checklist — is inherited unchanged from
`plan-goal-breakdown-base`.
