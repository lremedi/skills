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

Before processing any user request, read `../plan-goal-breakdown-base/SKILL.md`, resolved relative to
this file's directory, and treat it as your primary global constraints. Then apply the rules below.

# Plan Goal Breakdown

Baseline variant: local repository exploration, no work-tracking integration, no graph-index gate.

## When To Use

- "Plan this", "break into goals", "make commit-sized goals", "persist goals in files".
- Work needs dependency ordering and safe parallel execution.
- Team wants deterministic implementation slices with clear done criteria.

## Specialization

- Verification scope is typecheck/unit/e2e as the repo actually provides; confirm which are in scope and
  which are deferred (scoping per the base Test Scoping Policy).
- Discovery is ordinary read-only repository exploration.
- No artifacts beyond the base Output Contract.

Everything else is inherited unchanged.
