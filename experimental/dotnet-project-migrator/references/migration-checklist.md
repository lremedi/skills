# Per-project sign-off checklist

Run through this before considering a single project's migration "done" and
moving on to the next one in the plan.

## Build & structure
- [ ] `migration-report.md` build check succeeded (or the failure is
      understood and being worked through, not ignored)
- [ ] No stray references to the old repo path anywhere in the new project
      (check `ProjectReference` paths and any hardcoded file paths in code)
- [ ] `Project.csproj.oldstyle.bak` reviewed side-by-side with the new
      SDK-style csproj at least once, to sanity-check nothing important was
      dropped (custom MSBuild targets, pre/post-build steps, conditional
      compilation symbols)

## Packages
- [ ] Every package under "needs manual replacement" in the report has been
      resolved (replacement package chosen, or in-house reimplementation
      planned/scoped)
- [ ] Package versions in the new csproj are pinned to versions that
      actually support the target framework (don't assume the packages.config
      version is compatible)

## Configuration
- [ ] `appsettings.json` (if generated) reviewed for correctness —
      especially connection strings, which sometimes have provider-specific
      syntax differences between `System.Data.SqlClient` (old) and
      `Microsoft.Data.SqlClient` (modern)
- [ ] Any custom `configSections` in the original `app.config`/`web.config`
      have an explicit migration plan (Options pattern classes), not just a
      TODO

## Code (manual/Roslyn-tool territory)
- [ ] Every item under "Needs human / Roslyn-level review" in the report has
      an owner and is tracked (not silently deferred)
- [ ] WCF/Remoting endpoints: replacement approach (gRPC/REST/CoreWCF/queue)
      decided and either implemented or explicitly scheduled
- [ ] EF6 → EF Core: queries tested against real data volumes, not just unit
      tests with in-memory providers
- [ ] Windows-only API usage: platform-guarded or replaced if cross-platform
      deployment is a goal

## Testing
- [ ] The project's own test project (if one exists) has also been migrated
      and passes against the migrated code
- [ ] If no test project existed, at least smoke-tested manually — don't
      let "no tests" become "no verification"

## Only after all of the above
- [ ] Mark this project complete in your tracking (e.g. update
      `migration-plan.json`/a status file) and move to the next project in
      dependency order.
