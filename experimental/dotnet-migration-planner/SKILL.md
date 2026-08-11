---
name: dotnet-migration-planner
description: Use this skill whenever the user wants to plan, order, or scope a migration of a .NET Framework solution (.sln) to modern .NET — including phrases like "migrate my .NET Framework solution", "what order should I migrate these projects in", "plan a .NET upgrade", or when a .sln file with old-style (non-SDK) .csproj projects is present. This skill analyzes the solution's project dependency graph and produces a phased, dependency-safe migration order (leaves/class-libraries first, entry points last) as migration-plan.json and migration-plan.md. It does NOT perform the actual project migration — hand off each project, in the order this skill produces, to the dotnet-project-migrator skill. Always run this skill BEFORE dotnet-project-migrator on a multi-project solution.
---

# .NET Migration Planner

Determines a safe, dependency-respecting migration order for every project in
a .NET Framework solution, so that a multi-project migration can proceed
project-by-project without ever migrating a project before its dependencies.

This is the **parent/orchestrator** skill. Its sibling skill,
`dotnet-project-migrator`, generates the per-project goals/task files that
drive the actual migration work. This skill only plans; it never modifies
the original repository.

## Why order matters

Migrating a project before the projects it depends on forces you to deal with
mixed old-style/SDK-style references and framework mismatches simultaneously.
The safe approach (per standard .NET migration guidance) is **incremental,
bottom-up migration**: shared class libraries first, then the data-access
layer, then business logic/services, and application entry points
(web apps, WCF hosts, console/worker apps) last, since they depend on
everything else.

## Workflow

1. **Locate the solution file.** Ask the user for the `.sln` path if it
   isn't obvious from context. Confirm you have read access to it and to
   every referenced `.csproj`.

2. **Run the analyzer.** PowerShell 7+ (`pwsh`), cross-platform, no external
   modules required:

   ```powershell
   pwsh ./scripts/Analyze-Solution.ps1 -SlnPath /path/to/Solution.sln -OutDir /path/to/plan-dir
   ```

   This produces two files in `plan-dir`:
   - `migration-plan.json` — machine-readable; **this is the contract
     `dotnet-project-migrator` expects**. Each entry has `Order`, `Name`,
     `CsprojPath`, `Phase`, `DependsOn`, `Signals` (risk flags like WCF,
     EF6, System.Web), `UsesPackagesConfig`, and `IsTestProject`.
   - `migration-plan.md` — human-readable, grouped by phase, for you to
     review with the user before starting.

3. **Review the plan with the user before migrating anything.** Surface in
   particular:
   - Any `CyclicOrUnresolved` entries — these must be broken manually
     (usually by extracting a shared interface project) before migration
     can proceed, since a clean topological order doesn't exist.
   - Projects flagged with `wcf`, `remoting`, or `entity_framework6` signals
     — these are the hardest parts per the migration guide and deserve
     extra planning/time budget, not just mechanical conversion.
   - Test projects (`IsTestProject: true`) — recommend migrating each
     test project immediately after (or alongside) the project it covers,
     not saving all tests for the end, so regressions are caught early.

4. **Decide the target framework together with the user.** Default to the
   current stable LTS release (this skill's sibling defaults to `net10.0`,
   the LTS current through late 2028 as of mid-2026) unless the user has a
   specific reason to target something else — check `dotnet --list-sdks`
   locally, or ask, if a newer LTS/STS has since shipped.

5. **Hand off projects to `dotnet-project-migrator` in `MigrationOrder`
   sequence, one at a time.** That skill generates a `GOALS.md` + `goals.json`
   per project rather than migrating it outright — after goals are
   generated for a project, work through that project's goals (as this
   agent or handed to another) before moving to the next project, so a
   downstream project's goals never get generated against an unmigrated
   dependency's stale API shape.

6. **Track progress.** Keep `plan-dir` around across the whole migration —
   it's the shared state between this skill and the migrator. If the user
   pauses and resumes later, re-read `migration-plan.json` rather than
   re-analyzing the solution, unless the source `.sln` has changed.

## Notes on the analyzer's heuristics

- Dependency detection is based on `<ProjectReference>` elements only —
  it does not resolve `packages.config`/NuGet dependencies between projects.
- "Signals" (WCF, EF6, System.Web, etc.) come from a plain text search across
  `.cs`/`.vb`/`.config` files in each project folder. This is a heuristic
  for prioritization and risk-flagging, not a guarantee of completeness —
  always still run a full build and test pass per project.
- Phase classification (`1-class-libraries`, `2-data-access`,
  `3-business-logic-services`, `4-entry-points`, `0-tests`) is a best-effort
  guess from output type and signals. If it misclassifies a project, the
  user's own knowledge of the architecture should override it — the JSON's
  `Order` field is still valid for dependency-safety even if you manually
  re-bucket the phase label.

## Script reference

`scripts/Analyze-Solution.ps1` — PowerShell 7+ only, no external modules
(uses built-in `[xml]`, `Get-ChildItem`, `ConvertTo-Json`). Works identically
on Windows, Linux, or macOS wherever `pwsh` is installed, and whether
invoked by Claude, another agent/CLI, or a human directly — nothing in it
depends on any specific assistant's tool-calling conventions. Run
`Get-Help ./scripts/Analyze-Solution.ps1 -Full` for the full parameter list.
