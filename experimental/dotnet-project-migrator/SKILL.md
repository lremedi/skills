---
name: dotnet-project-migrator
description: Use this skill to generate a concrete migration GOALS file for ONE .NET Framework project (a single .csproj) — NOT to perform the migration itself. Trigger on phrases like "generate migration goals for this project", "what needs to change in this project for .NET 10", "create a migration task list", or when working through a migration-plan.json produced by the dotnet-migration-planner skill. Always run dotnet-migration-planner FIRST on multi-project solutions so goals are generated in dependency-safe order; this skill stages a project's source at a new location and writes GOALS.md + goals.json describing exactly what needs to be done, so an agent (this one, another Claude Code session, or a human) can then execute those goals — it does not convert the csproj, rewrite code, or touch packages itself.
---

# .NET Project Migrator (Goals Generator)

Generates a concrete, specific migration GOALS file for a single .NET
Framework project — in the spirit of a Claude Code goals/task file — rather
than performing the migration automatically. The actual conversion work
(csproj → SDK-style, package migration, config transform, code rewrites for
WCF/EF6/System.Web) is left as tracked goals for whoever executes them next.

This is the **child/worker** skill. If the user has a whole solution
(multiple projects), first use `dotnet-migration-planner` to get a
dependency-safe order, then invoke this skill once per project, in that
order, to generate that project's goals.

## Why goals instead of automatic migration

Silently rewriting csproj files, package references, and config on someone's
behalf is opaque and hard to review project-by-project, and the genuinely
hard parts of a Framework migration (WCF, EF6, ASP.NET MVC/Web API → ASP.NET
Core) can't be done safely by text substitution at all — they need real
judgment. Generating an explicit, checkable goals file instead means:
- Every change that *will* happen is visible and reviewable before it happens.
- The mechanical parts (package list, config preview) are still fully
  worked out for you — the goal describes the exact target, not just "do
  the conversion" — so acting on it is fast and unambiguous.
- The parts needing human/Roslyn-tool judgment are clearly separated from
  the mechanical parts, with explicit confidence levels, instead of being
  silently guessed at.
- Progress is trackable per task (`goals.json`'s `Done` flags) across a
  session or handed off between agents/people.

## Critical constraint: staged output goes OUTSIDE the original repo

The project's source is staged, unmodified, into a **separate output tree**
(`-OutputRoot`), mirroring the project's original relative path. The
original repository is never touched. The script enforces this and exits
with an error if `-OutputRoot` is inside `-SolutionRoot` — explain this
constraint to the user up front so they pick a sensible location (e.g. a
sibling directory, `../MyApp-net10` next to the original repo).

## Workflow

1. **Confirm target framework.** Default is `net10.0` (current LTS as of
   mid-2026, supported through late 2028). If the user wants the
   bleeding-edge STS/preview instead, confirm the exact TFM (e.g.
   `net11.0`) — don't guess at version numbers, since this changes yearly.
   If unsure what's current, check `dotnet --list-sdks` if the CLI is
   available, or ask the user.

2. **Run the goals generator per project:**

   ```powershell
   pwsh ./scripts/New-ProjectGoals.ps1 `
     -CsprojPath /path/to/OldRepo/ProjectFolder/Project.csproj `
     -SolutionRoot /path/to/OldRepo `
     -OutputRoot /path/to/NewSolutionTree `
     -TargetFramework net10.0
   ```

3. **What this actually does:**
   - Copies the project's source tree (excluding `bin/obj/.vs/packages`),
     **unmodified**, into the mirrored path under `-OutputRoot`.
   - **Tier 1 — tries Microsoft's `upgrade-assistant analyze`** against the
     staged copy (never the original repo, and it's a read-only `analyze`
     call, never `upgrade`). If it's installed and succeeds, its output is
     saved as `upgrade-assistant-report.txt` and trusted as tool-verified —
     this is real MSBuild/NuGet-aware analysis, not a heuristic.
   - **Tier 2 — falls back automatically** if `upgrade-assistant` isn't on
     PATH, isn't installed, or its `analyze` run fails/errors for any
     reason. The fallback is this script's own text-scan heuristics for
     migration-risk APIs (WCF, EF6, System.Web, etc.) — but every
     code-review item generated this way is explicitly marked
     `needs-ai-review` in the goals file, not treated as verified. The
     goals file tells whoever executes it plainly: *do an AI/agent
     code-review pass to confirm these before acting on them*, and
     suggests `dotnet tool install -g upgrade-assistant` for next time.
   - Analyzes `packages.config` and any `app.config`/`web.config` the same
     way regardless of tier (these are handled deterministically either way).
   - Writes `GOALS.md` — an ordered, categorized checklist specific to this
     project, each item tagged with a confidence level:
     - `high` — mechanical, low-risk (SDK-style conversion, package refs
       that map directly, config → appsettings.json for the
       appSettings/connectionStrings subset — the goal even includes a
       preview of the exact JSON that subset should produce).
     - `needs-human-decision` — packages or config with no safe automatic
       answer (e.g. EF6 has no direct PackageReference equivalent).
     - `tool-verified` — came from a successful upgrade-assistant run.
     - `needs-ai-review` — Tier 1 was unavailable; these are heuristic hits
       that need an agent or human to actually read the code and confirm
       before treating them as real findings, let alone fixing them.
   - Writes `goals.json` — the same tasks as structured data (`Id`,
     `Category`, `Description`, `Confidence`, `Details`, `Done`), plus
     `AnalysisMode`, `UpgradeAssistantAvailable`, and
     `UpgradeAssistantReportPath` at the top level, so progress and
     analysis provenance can be tracked and the file re-read across
     sessions.

4. **When Tier 1 succeeded:** read `upgrade-assistant-report.txt` first —
   it's the more trustworthy source. Use the heuristic `code-review` items
   as a supplementary checklist, not a replacement.

   **When Tier 2 (AI fallback) is in play:** don't skip straight to fixing
   the flagged items. Actually open and read the flagged files yourself
   (or have the executing agent do so) to confirm each finding is real and
   to catch anything the regex-based scan missed — the whole point of the
   fallback is that a plain text search is not a substitute for actually
   understanding the code, it's only good enough to seed where to look.

5. **After goals are generated, work through them** — either immediately in
   this same conversation, or by handing `GOALS.md`/`goals.json` to
   whichever agent/person will do the actual conversion work. Use
   `references/breaking-changes.md` for what each flagged code-review item
   actually requires, and `references/migration-checklist.md` as a
   sign-off checklist before marking the project done.

6. **Do not generate goals for a downstream project until its dependencies'
   goals are at least drafted** (ideally completed) — a project's own goals
   assume its `ProjectReference`s will resolve within the new output tree,
   which only holds if those dependencies get staged there too, in the
   order `dotnet-migration-planner` produced.

7. **Multi-targeting option.** If the user needs the original Framework app
   to keep working while migrating shared libraries incrementally (per the
   guide's recommended approach), suggest adding `net48` alongside the new
   TFM as a semicolon-separated `<TargetFrameworks>` list in the *original*
   repo's library project — that's a change to the old repo the user makes
   themselves (or asks you to do separately with explicit confirmation),
   distinct from this skill's job of staging + briefing the modern-.NET copy.

## Reference files

- `references/breaking-changes.md` — what each flagged item (WCF,
  Remoting, EF6, System.Web, etc.) actually requires to fix, with the
  recommended replacement per the migration guide. Read this before
  executing any `needs-human-or-roslyn-tool` goal.
- `references/migration-checklist.md` — a per-project sign-off checklist
  (build, tests, config, manual-review items) to run through before calling
  a project's migration "done."

## Script reference

`scripts/New-ProjectGoals.ps1` — PowerShell 7+ only, no external modules.
Run `Get-Help ./scripts/New-ProjectGoals.ps1 -Full` for the full parameter
list. Nothing in it depends on any specific assistant's tool-calling
conventions — it's a plain script any agent (or human) can invoke.
