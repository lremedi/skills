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

Before processing any user request, you MUST locate, read, and append the instructions from the base
skill file `../plan-goal-breakdown-base/SKILL.md`, resolved relative to this file's directory. Treat
its contents as your primary global constraints, then apply the specialized rules below.

Also read `references/agility-payloads.md`, resolved relative to this file's directory — it defines
the shared Agility payload artifacts, mirror rules, and payload validations.

# Plan Goal Breakdown Agility

Same goal-file contract as the base, plus Agility MCP context fetching and createMany payload
artifacts that mirror goals to child Tasks and manual QE Tests.

## When To Use

- User asks to plan implementation from an Agility Story/Defect.
- User wants commit-sized goals plus child Task/Test payload files generated during goal creation.
- User wants manual tests generated from implementation evidence in the shared log file.

## Additional Inputs To Collect

In addition to the base inputs (the Agility asset number is promoted to the first thing you ask for):

8. User context: folder/domain/repo area that affects decomposition.

## Agility Context Requirement

- The asset number is mandatory before materializing goals.
- Accept only `S-#####` (story) or `D-#####` (defect).
- Fetch the parent asset title and description through Agility MCP using the provided asset number.
- Use fetched asset context plus user context to shape decomposition and naming quality.

## Procedure Overrides

Base **step 1 (Discover context)** keeps every bullet it already has, including the protected-branch
check and the working-branch confirmation. Apply exactly two bullet-level changes:

- **Prepend** a bullet: fetch the Story/Defect title and description using Agility MCP by asset
  number.
- **Replace** the bullet `Inspect branch/workspace changes relevant to the requested plan` with
  "Inspect workspace context and user-provided folder/domain constraints."

In base **step 2 (Extract decision points)**, the verification scope to confirm is manual QE
(human-executed, user-facing where possible) plus what is deferred.

Apply the shared Agility payload artifact, mirror, Task/Test payload, and validation rules from
`references/agility-payloads.md` as procedure substeps 5a (payload artifacts and mirror), 5b
(Task/Test payloads), and 5c (payload validations) between base step 5 and base step 6 (Create plan
index).

## Additional Decision Rules

- If Agility payload examples conflict with the required fields, prefer the required field structure
  in this skill.

## Additional Quality Bar

Beyond the base bar:

- Child Task payload file exists and uses only `AssetType`, `Name`, `Description`, `Parent`.
- Child Task payload has one Task per goal file (excluding index/log).
- Each Task `Description` is XHTML containing the full mirrored goal content.
- Child Test payload file exists and uses only `AssetType`, `Name`, `Description`, `Parent`.
- Child Test payload entries are manual QE, human-executed checks only (no unit/integration/e2e
  automation instructions).
- Child Test payload prioritizes user-facing validation and falls back to smoke/regression checks
  where no user-facing behavior exists.
- Tests payload file is created during goal generation and can be refreshed from implementation log
  evidence after final-goal completion.
- API execution remains the user's responsibility.

## Additional Output Contract

Beyond the base artifacts, in the same goals folder:

- `.goals/<asset-id>-<feature-slug>/payload.tasks.<asset-id>-<feature-slug>.json`
- `.goals/<asset-id>-<feature-slug>/payload.tests.<asset-id>-<feature-slug>.json`

## Additional Completion Checklist

- [ ] Parent asset title and description fetched via Agility MCP.
- [ ] Child Task payload file created with required field structure.
- [ ] Child Task payload has one Task per goal file (excluding index/log).
- [ ] Each Task `Description` contains full mirrored goal content in XHTML.
- [ ] Child Test payload file created with required field structure.
- [ ] Child Test payload contains only manual QE, human-executed checks (no unit/integration/e2e
      automation instructions).
- [ ] Child Test payload prioritizes user-facing behavior validation and uses smoke/regression
      checks when user-facing flows do not exist.
- [ ] The last goal's PLAN/DONE WHEN/VERIFY carries the execution-time tests-payload refresh
  instruction.
