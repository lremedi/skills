---
name: plan-goal-breakdown-agility
description: "Break a Story/Defect into dependency-aware, commit-sized goals and mirror them to Agility child Tasks and log-derived child Tests via user-executed createMany payloads."
argument-hint: "Story/Defect number + objective + scope constraints + user context (project folder/domain)"
user-invocable: true
disable-model-invocation: false
metadata:
  id: plan-goal-breakdown-agility
  inherits: plan-goal-breakdown-base
  parent-files: "../plan-goal-breakdown-base/SKILL.md"
  reference-files:
    - "references/agility-payloads.md"
---

# ⚠️ System Initialization Hook (Do Not Ignore)

Before processing any user request, read both of these, resolved relative to this file's directory, and
treat them as your primary global constraints:

1. `../plan-goal-breakdown-base/SKILL.md` — process and output contract.
2. `references/agility-payloads.md` — payload artifacts, mirror rules, payload validations.

# Plan Goal Breakdown Agility

Base goal-file contract plus Agility MCP context fetching and createMany payload artifacts mirroring
goals to child Tasks and manual QE Tests.

## When To Use

- Planning implementation from an Agility Story/Defect.
- User wants child Task/Test payload files generated during goal creation.
- User wants manual tests generated from shared-log implementation evidence.

## Additional Inputs To Collect

- **Base input 6 override:** ask for the Agility asset number first; still mandatory before
  materializing goals.
9. User context: folder/domain/repo area affecting decomposition.

## Agility Context Requirement

- Asset number mandatory before materializing goals; `S-#####` or `D-#####` only.
- Fetch the parent asset title and description via Agility MCP by asset number.
- Shape decomposition and naming from fetched asset context plus user context.

## Procedure Overrides

Base **step 1** keeps every bullet, including the protected-branch check and branch confirmation, plus:

- **Prepend**: fetch the Story/Defect title and description via Agility MCP by asset number.
- **Replace** `Inspect branch/workspace changes relevant to the plan` with "Inspect workspace context and
  user-provided folder/domain constraints."

Base **step 2**: the verification scope to confirm is manual QE (human-executed, user-facing where
possible) plus what is deferred.

Insert the rules from `references/agility-payloads.md` as substeps 5a (payload artifacts and mirror), 5b
(Task/Test payloads), and 5c (payload validations), between base steps 5 and 6.

## Additional Decision Rules

- Payload examples conflicting with the required fields → the required field structure wins.

## Additional Quality Bar

- Every validation in `references/agility-payloads.md` ("Payload Validations") passes.
- Both payload files exist in the goals folder and were created in the same run as the goal files.
- The last goal's PLAN/DONE WHEN/VERIFY carries the execution-time tests-payload refresh instruction.
- The parent asset title and description were fetched via Agility MCP.
- API execution stays the user's responsibility.

## Additional Output Contract

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`
