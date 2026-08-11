# Breaking changes and what to actually do about them

This maps each "signal" the migrator's heuristic scan can flag to what it
means and the recommended fix, based on standard .NET Framework → modern
.NET migration guidance.

## WCF (`System.ServiceModel`)

Not fully supported on modern .NET. Options, roughly in order of
recommendation:
- **gRPC** — best for internal, performance-sensitive service-to-service
  calls. Requires rewriting service contracts as `.proto` definitions;
  real rework, but pays off in throughput and cross-platform hosting.
- **REST (ASP.NET Core Web API)** — best when simplicity and broad client
  compatibility matter more than raw performance.
- **CoreWCF** — a community-maintained partial port of WCF. Workable for
  basic scenarios as a stopgap, but not recommended as the long-term target
  for anything beyond simple bindings.
- **Message queues** (RabbitMQ, Azure Service Bus, SQS) — best when the
  communication is genuinely async/decoupled rather than request/response.

Budget real time for this. It is consistently the hardest single piece of
a Framework migration.

## Remoting (`System.Runtime.Remoting`) / `AppDomain.CreateDomain`

Both are gone in modern .NET. Remoting → gRPC or a REST API between
processes. AppDomain-based isolation → separate OS processes, or
`AssemblyLoadContext` if you only need plugin-style assembly loading
within one process (note: `AssemblyLoadContext` is not a security boundary
the way AppDomains were sometimes used as one — don't rely on it for that).

## System.Web / ASP.NET MVC

No compatibility shim exists — this is a genuine rewrite to ASP.NET Core
MVC. The mental model changes too: DI is required (not optional), the
middleware pipeline replaces HTTP modules/handlers, and configuration moves
to the Options pattern. Controllers/actions/routing concepts carry over
conceptually, but the code needs to be rewritten, not just recompiled.

## System.Web.Http (ASP.NET Web API)

Same story as MVC — target ASP.NET Core Web API (minimal APIs or
controller-based). Attribute routing concepts mostly carry over.

## Entity Framework 6 (`System.Data.Entity`)

EF Core is a different library, not just a new EF6 version. Common friction
points: lazy-loading behavior differs, some LINQ patterns translate to SQL
differently (test with real data volumes, not just unit tests), raw SQL
APIs changed shape, and migrations are regenerated (don't try to port EF6
migration files directly — regenerate against the EF Core model). Consider
this a genuine migration project of its own, not a mechanical package swap.

## ConfigurationManager / app.config / web.config

The migrator auto-converts `appSettings` and `connectionStrings` into
`appsettings.json`. Anything using **custom `configSections`** is not
touched — those need to become strongly-typed options classes bound via
the Options pattern (`IOptions<T>`), which requires understanding what the
custom section actually represents.

## Windows-only APIs (Registry, WMI, `System.DirectoryServices`)

These still work on Windows under modern .NET, but block cross-platform
(Linux container) deployment, which is usually a big part of the
motivation to migrate in the first place. If cross-platform deployment
matters to the user, these need a platform-guarded abstraction or a
different implementation. The .NET SDK's built-in Platform Compatibility
Analyzer can help enumerate every call site.

## `System.Drawing`

Historically GDI+-backed and not reliably supported cross-platform on
modern .NET outside Windows. If cross-platform matters, plan to replace it
with `System.Drawing.Common`'s documented alternatives (e.g.
`SixLabors.ImageSharp`) rather than assuming it "just works" on Linux.

## Legacy SignalR (`Microsoft.AspNet.SignalR`)

Replaced by `Microsoft.AspNetCore.SignalR`, which ships as part of
ASP.NET Core rather than a separate NuGet package. Hub code concepts carry
over reasonably well, but client connection setup and hosting are
different enough to need real testing, not just a recompile.

## Third-party NuGet packages generally

Before assuming a package "just needs a version bump," check its NuGet
page for actual modern-.NET (`net8.0`+/`netstandard2.0`+) support. A
meaningful fraction of packages in any real legacy codebase will have
either no modern-.NET build, a different recommended replacement package,
or (occasionally) no viable replacement at all — in which case budget time
to reimplement that slice of functionality in-house.
