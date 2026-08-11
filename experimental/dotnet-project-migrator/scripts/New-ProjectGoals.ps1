<#
.SYNOPSIS
    Generates a per-project migration GOALS file (and machine-readable
    goals.json) at a new location, instead of performing the migration
    itself. Cross-platform PowerShell (7+), no external modules required.

.DESCRIPTION
    This script does NOT convert, rewrite, or "migrate" the project. It:
      1. Stages a copy of the project's source tree at the new location
         (mirroring the project's path relative to the solution), excluding
         bin/obj/.vs/packages, so an agent has the actual code to work from.
      2. Tries Microsoft's `upgrade-assistant analyze` (a real, deterministic
         MSBuild/NuGet-aware tool) against the staged project first — this is
         Tier 1 and, when available, is trusted over this script's own
         heuristics for package-compatibility and API-usage findings.
      3. If upgrade-assistant is not installed, not on PATH, or its analyze
         run fails/errors, falls back to Tier 2: this script's own text-scan
         heuristics, explicitly marked lower-confidence and flagged in the
         goals file as needing an AI/agent code-review pass rather than
         being treated as verified findings.
      4. Writes GOALS.md — a concrete, ordered task list for THIS project,
         in the style of a Claude Code goals/task file: specific, checkable,
         scoped to what this project actually needs (not generic advice),
         and honest about which tier (tool-verified vs. heuristic/AI-review)
         each finding came from.
      5. Writes goals.json — the same information as structured data, so
         a downstream agent/script can track completion per task.

    The actual csproj conversion, package migration, config transform, and
    code rewrites are left as goals for whichever agent (or human) executes
    them next — this script's job is to stage the workspace and write an
    accurate, specific brief, not to do the work.

.PARAMETER CsprojPath
    Path to the OLD .csproj (inside the original repo).

.PARAMETER SolutionRoot
    Path to the folder containing the original .sln.

.PARAMETER OutputRoot
    Path to the NEW solution tree where goals + staged source will be
    written. Must be OUTSIDE SolutionRoot.

.PARAMETER TargetFramework
    Target framework moniker to put in the goals, e.g. net10.0 (current
    LTS as of mid-2026). Default: net10.0.

.PARAMETER SkipUpgradeAssistant
    Skip trying upgrade-assistant even if it's installed, and go straight to
    the Tier 2 heuristic/AI-review path. Useful if you already know the tool
    doesn't handle this project type well, or to keep runs fast/offline.

.EXAMPLE
    ./New-ProjectGoals.ps1 -CsprojPath ../OldRepo/Data/Data.csproj `
        -SolutionRoot ../OldRepo -OutputRoot ../OldRepo-net10 -TargetFramework net10.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsprojPath,

    [Parameter(Mandatory = $true)]
    [string]$SolutionRoot,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [Parameter(Mandatory = $false)]
    [string]$TargetFramework = "net10.0",

    [Parameter(Mandatory = $false)]
    [switch]$SkipUpgradeAssistant
)

$ErrorActionPreference = "Stop"

$IgnoreDirNames = @("bin", "obj", ".vs", "packages", "TestResults")

$SignalPatterns = [ordered]@{
    "WCF (System.ServiceModel)"                          = 'System\.ServiceModel'
    "Remoting (System.Runtime.Remoting)"                 = 'System\.Runtime\.Remoting'
    "AppDomain.CreateDomain"                             = 'AppDomain\.CreateDomain'
    "System.Web / MVC (needs ASP.NET Core rewrite)"      = 'System\.Web(\.Mvc)?(?!\.Http)'
    "System.Web.Http (Web API)"                          = 'System\.Web\.Http'
    "EF6 (System.Data.Entity)"                           = 'System\.Data\.Entity'
    "ConfigurationManager"                               = 'ConfigurationManager\.'
    "Windows-only API"                                   = 'Microsoft\.Win32|System\.Management\b|System\.DirectoryServices'
    "SignalR (legacy)"                                   = 'Microsoft\.AspNet\.SignalR'
    "System.Drawing (GDI+, not cross-platform)"          = 'System\.Drawing\b'
}

# Packages with no direct modern-.NET PackageReference equivalent — these
# need a human/agent decision, not an automatic remap.
$NoDirectEquivalent = @(
    "Microsoft.AspNet.WebApi.Core",
    "Microsoft.AspNet.Mvc",
    "EntityFramework",
    "Microsoft.AspNet.SignalR.Core"
)

function ConvertTo-NativePath {
    param([string]$Path)
    return $Path -replace '\\', '/'
}

function Copy-ProjectTree {
    param([string]$Src, [string]$Dest)

    if (Test-Path -LiteralPath $Dest) { Remove-Item -LiteralPath $Dest -Recurse -Force }
    New-Item -ItemType Directory -Path $Dest -Force | Out-Null

    Get-ChildItem -LiteralPath $Src -Recurse -Force | ForEach-Object {
        $relative = $_.FullName.Substring($Src.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/')
        $segments = $relative -split '[\\/]'
        if ($segments | Where-Object { $IgnoreDirNames -contains $_ }) { return }

        $destPath = Join-Path $Dest $relative
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        } else {
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $destPath -Force
        }
    }
}

function Get-PackagesConfigEntries {
    param([string]$Path)
    $packages = @()
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $packages }
    try {
        [xml]$xml = Get-Content -Raw -Path $Path -Encoding UTF8
        foreach ($pkg in $xml.SelectNodes("//package")) {
            $packages += [pscustomobject]@{ Id = $pkg.GetAttribute("id"); Version = $pkg.GetAttribute("version") }
        }
    } catch { }
    return $packages
}

function Get-OldCsprojInfo {
    param([string]$Path)

    [xml]$xml = Get-Content -Raw -Path $Path -Encoding UTF8

    $info = [pscustomobject]@{
        OutputType         = "Library"
        AssemblyName       = $null
        RootNamespace      = $null
        ProjectReferences  = @()
        AssemblyReferences = @()
    }

    $outputTypeNode = $xml.SelectSingleNode("//*[local-name()='OutputType']")
    if ($outputTypeNode) { $info.OutputType = $outputTypeNode.InnerText.Trim() }

    $asmNode = $xml.SelectSingleNode("//*[local-name()='AssemblyName']")
    if ($asmNode) { $info.AssemblyName = $asmNode.InnerText.Trim() }

    $nsNode = $xml.SelectSingleNode("//*[local-name()='RootNamespace']")
    if ($nsNode) { $info.RootNamespace = $nsNode.InnerText.Trim() }

    foreach ($node in $xml.SelectNodes("//*[local-name()='ProjectReference']")) {
        $include = $node.GetAttribute("Include")
        if ($include) { $info.ProjectReferences += (ConvertTo-NativePath $include) }
    }

    foreach ($node in $xml.SelectNodes("//*[local-name()='Reference']")) {
        $include = $node.GetAttribute("Include")
        $hasHint = $false
        foreach ($child in $node.ChildNodes) {
            if ($child.LocalName -eq "HintPath") { $hasHint = $true }
        }
        if (-not $hasHint -and $include) {
            $info.AssemblyReferences += ($include -split ',')[0]
        }
    }

    return $info
}

function Invoke-UpgradeAssistantAnalyze {
    <#
        Tier 1: try Microsoft's real upgrade-assistant tool against the
        STAGED (already-copied) csproj — it's read-only (analyze, not
        upgrade) but we still point it at the copy, never the original repo,
        to keep this script's "never touch the original repo" guarantee
        absolute regardless of what the tool does internally.

        Returns @{ Success; Reason; Output; ReportPath }
    #>
    param([string]$StagedCsprojPath)

    $cmd = Get-Command "upgrade-assistant" -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return [pscustomobject]@{
            Success = $false
            Reason  = "upgrade-assistant CLI not found on PATH. Install with: dotnet tool install -g upgrade-assistant"
            Output  = $null
            ReportPath = $null
        }
    }

    try {
        $output = & upgrade-assistant analyze $StagedCsprojPath 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            return [pscustomobject]@{
                Success = $false
                Reason  = "upgrade-assistant analyze exited with code $exitCode"
                Output  = $output
                ReportPath = $null
            }
        }
        return [pscustomobject]@{
            Success = $true
            Reason  = $null
            Output  = $output
            ReportPath = $null
        }
    } catch {
        return [pscustomobject]@{
            Success = $false
            Reason  = "upgrade-assistant analyze threw: $($_.Exception.Message)"
            Output  = $null
            ReportPath = $null
        }
    }
}

function Find-Signals {
    param([string]$ProjDir)

    $found = [ordered]@{}
    $files = Get-ChildItem -Path $ProjDir -Recurse -File -Include *.cs, *.vb, *.config -ErrorAction SilentlyContinue |
        Where-Object {
            $segments = $_.FullName.Substring($ProjDir.Length) -split '[\\/]'
            -not ($segments | Where-Object { $IgnoreDirNames -contains $_ })
        }
    foreach ($file in $files) {
        $text = Get-Content -Raw -Path $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $text) { continue }
        foreach ($label in $SignalPatterns.Keys) {
            if ($text -match $SignalPatterns[$label]) {
                if (-not $found.Contains($label)) { $found[$label] = @() }
                $found[$label] += (Resolve-Path -Relative -Path $file.FullName -RelativeBasePath $ProjDir -ErrorAction SilentlyContinue)
                if (-not $found[$label][-1]) { $found[$label][-1] = $file.FullName.Substring($ProjDir.Length).TrimStart('\','/') }
            }
        }
    }
    return $found
}

function Convert-ConfigAppSettingsPreview {
    # Returns a preview hashtable of what a mechanical appSettings/
    # connectionStrings -> appsettings.json conversion WOULD produce, so the
    # goal file can show the agent the concrete target instead of vague advice.
    param([string]$ConfigPath)

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { return $null }
    try { [xml]$xml = Get-Content -Raw -Path $ConfigPath -Encoding UTF8 } catch { return $null }

    $result = [ordered]@{}
    $appSettingsNode = $xml.SelectSingleNode("//appSettings")
    if ($appSettingsNode) {
        $settings = [ordered]@{}
        foreach ($add in $appSettingsNode.SelectNodes("add")) {
            $key = $add.GetAttribute("key")
            if ($key) { $settings[$key] = $add.GetAttribute("value") }
        }
        if ($settings.Count -gt 0) { $result["AppSettings"] = $settings }
    }
    $connNode = $xml.SelectSingleNode("//connectionStrings")
    if ($connNode) {
        $conns = [ordered]@{}
        foreach ($add in $connNode.SelectNodes("add")) {
            $name = $add.GetAttribute("name")
            if ($name) { $conns[$name] = $add.GetAttribute("connectionString") }
        }
        if ($conns.Count -gt 0) { $result["ConnectionStrings"] = $conns }
    }
    if ($result.Count -eq 0) { return $null }
    return $result
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$csprojFull = (Resolve-Path -LiteralPath $CsprojPath).Path
$solutionRootFull = (Resolve-Path -LiteralPath $SolutionRoot).Path
if (-not (Test-Path -LiteralPath $OutputRoot)) { New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null }
$outputRootFull = (Resolve-Path -LiteralPath $OutputRoot).Path

if ($outputRootFull -eq $solutionRootFull -or $outputRootFull.StartsWith($solutionRootFull + [IO.Path]::DirectorySeparatorChar)) {
    Write-Error "OutputRoot must be OUTSIDE SolutionRoot (goals + staged source must not live inside the original repo)."
    exit 1
}

$srcProjDir = Split-Path -Parent $csprojFull
$relProjDir = $srcProjDir.Substring($solutionRootFull.Length).TrimStart('\', '/')
$destProjDir = Join-Path $outputRootFull $relProjDir
$projFileName = Split-Path -Leaf $csprojFull

Write-Host "Staging: $relProjDir"
Write-Host "  Source: $srcProjDir"
Write-Host "  Dest:   $destProjDir"

# 1. Stage source tree (unmodified copy — this script does not convert it)
Copy-ProjectTree -Src $srcProjDir -Dest $destProjDir

# 1.5. Tier 1: try upgrade-assistant analyze against the STAGED copy (never
#      the original repo). If it's unavailable or fails, fall back to Tier 2
#      (this script's own heuristics), and mark the goals file accordingly so
#      the executing agent knows to do its own code-review pass rather than
#      trusting the heuristic hits as verified.
$stagedCsprojPath = Join-Path $destProjDir $projFileName
$uaResult = $null
if ($SkipUpgradeAssistant) {
    $uaResult = [pscustomobject]@{ Success = $false; Reason = "Skipped (-SkipUpgradeAssistant)."; Output = $null; ReportPath = $null }
} else {
    Write-Host "  Trying upgrade-assistant analyze (Tier 1)..."
    $uaResult = Invoke-UpgradeAssistantAnalyze -StagedCsprojPath $stagedCsprojPath
}

$analysisMode = if ($uaResult.Success) { "tool-verified (upgrade-assistant)" } else { "ai-fallback (heuristic scan + agent review required)" }

if ($uaResult.Success) {
    Write-Host "  upgrade-assistant analyze succeeded — using tool-verified findings (Tier 1)."
    $uaReportPath = Join-Path $destProjDir "upgrade-assistant-report.txt"
    $uaResult.Output | Out-File -FilePath $uaReportPath -Encoding UTF8
} else {
    Write-Host "  upgrade-assistant unavailable/failed ($($uaResult.Reason)) — falling back to Tier 2 (heuristic scan + AI/agent review)." -ForegroundColor Yellow
    $uaReportPath = $null
}

# 2. Analyze the OLD project
$info = Get-OldCsprojInfo -Path $csprojFull
$oldPackages = Get-PackagesConfigEntries -Path (Join-Path $srcProjDir "packages.config")
$signals = Find-Signals -ProjDir $destProjDir

$needsManualPackage = @($oldPackages | Where-Object { $NoDirectEquivalent -contains $_.Id })
$autoMappablePackages = @($oldPackages | Where-Object { $NoDirectEquivalent -notcontains $_.Id })

$sdk = if ($signals.Contains("System.Web / MVC (needs ASP.NET Core rewrite)") -or $signals.Contains("System.Web.Http (Web API)")) {
    "Microsoft.NET.Sdk.Web"
} else {
    "Microsoft.NET.Sdk"
}

$configPreview = $null
$configFileFound = $null
foreach ($name in @("app.config", "web.config", "App.config", "Web.config")) {
    $candidate = Join-Path $destProjDir $name
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $configFileFound = $name
        $configPreview = Convert-ConfigAppSettingsPreview -ConfigPath $candidate
        break
    }
}

# 3. Write goals.json (structured, resumable task list)
$tasks = New-Object System.Collections.Generic.List[pscustomobject]
$taskId = 1
function Add-Task {
    param([string]$Category, [string]$Description, [string]$Confidence, [string[]]$Details = @())
    $script:tasks.Add([pscustomobject]@{
        Id          = $script:taskId
        Category    = $Category
        Description = $Description
        Confidence  = $Confidence
        Details     = $Details
        Done        = $false
    })
    $script:taskId++
}

Add-Task -Category "project-file" -Confidence "high" `
    -Description "Convert $projFileName to SDK-style ($sdk), targeting $TargetFramework." `
    -Details @(
        "Preserve OutputType=$($info.OutputType), AssemblyName=$($info.AssemblyName), RootNamespace=$($info.RootNamespace) where set.",
        "Set <Nullable>disable</Nullable> initially; flip to enable once nullable warnings are triaged."
    )

if ($info.ProjectReferences.Count -gt 0) {
    Add-Task -Category "project-references" -Confidence "high" `
        -Description "Re-add ProjectReference entries, verified to resolve within the new output tree." `
        -Details $info.ProjectReferences
}

if ($autoMappablePackages.Count -gt 0) {
    $details = @($autoMappablePackages | ForEach-Object { "$($_.Id) $($_.Version)" })
    Add-Task -Category "packages" -Confidence "high" `
        -Description "Add these as <PackageReference> items (verify each version supports $TargetFramework)." `
        -Details $details
}

if ($needsManualPackage.Count -gt 0) {
    $details = @($needsManualPackage | ForEach-Object { "$($_.Id) $($_.Version) — no direct modern-.NET package; needs a replacement decision, see references/breaking-changes.md" })
    Add-Task -Category "packages-manual" -Confidence "needs-human-decision" `
        -Description "Resolve packages with no direct modern-.NET equivalent." `
        -Details $details
}

if ($info.AssemblyReferences.Count -gt 0) {
    Add-Task -Category "assembly-references" -Confidence "medium" `
        -Description "Verify these framework/GAC references still exist or have a replacement on $TargetFramework." `
        -Details $info.AssemblyReferences
}

if ($configFileFound) {
    if ($configPreview) {
        $previewJson = ($configPreview | ConvertTo-Json -Depth 6)
        Add-Task -Category "configuration" -Confidence "high" `
            -Description "Create appsettings.json from $configFileFound's appSettings/connectionStrings (mechanical subset)." `
            -Details @($previewJson -split "`n")
    }
    Add-Task -Category "configuration-manual" -Confidence "needs-human-decision" `
        -Description "Review $configFileFound for custom configSections not covered by the mechanical appSettings/connectionStrings conversion; port to Options pattern (IOptions<T>) classes."
}

if ($uaResult.Success) {
    Add-Task -Category "analysis" -Confidence "tool-verified" `
        -Description "Review upgrade-assistant-report.txt (Tier 1, real MSBuild/NuGet-aware analysis) alongside the heuristic findings below." `
        -Details @("Report: $uaReportPath")
} else {
    Add-Task -Category "analysis" -Confidence "needs-ai-review" `
        -Description "upgrade-assistant was unavailable/failed ($($uaResult.Reason)) — the findings below came from a plain text-search heuristic, not a real MSBuild/NuGet-aware tool. Before trusting them, do an AI/agent code-review pass over the staged source to confirm and expand on them (don't skip straight to fixes based on the heuristic alone)." `
        -Details @("Consider installing upgrade-assistant for future runs: dotnet tool install -g upgrade-assistant")
}

$codeReviewConfidence = if ($uaResult.Success) { "needs-human-or-roslyn-tool (heuristic seed, corroborate against upgrade-assistant-report.txt)" } else { "needs-ai-review (Tier 1 tool unavailable — treat as unverified until an agent/human confirms)" }

foreach ($label in $signals.Keys) {
    Add-Task -Category "code-review" -Confidence $codeReviewConfidence `
        -Description "$label — review and rewrite per references/breaking-changes.md; not auto-fixed." `
        -Details $signals[$label]
}

Add-Task -Category "build-and-test" -Confidence "n/a" `
    -Description "Run 'dotnet build' on the converted project and fix errors before moving to the next project in the migration plan."

Add-Task -Category "build-and-test" -Confidence "n/a" `
    -Description "Migrate this project's own test project (if any) and confirm it passes against the migrated code."

$goalsObj = [pscustomobject]@{
    Project                   = $projFileName
    SourcePath                = $csprojFull
    StagedPath                = (Join-Path $destProjDir $projFileName)
    TargetFramework           = $TargetFramework
    TargetSdk                 = $sdk
    AnalysisMode              = $analysisMode
    UpgradeAssistantAvailable = $uaResult.Success
    UpgradeAssistantReason    = $uaResult.Reason
    UpgradeAssistantReportPath = $uaReportPath
    GeneratedAt               = (Get-Date).ToString("o")
    Tasks                     = $tasks
}
$goalsJsonPath = Join-Path $destProjDir "goals.json"
$goalsObj | ConvertTo-Json -Depth 8 | Out-File -FilePath $goalsJsonPath -Encoding UTF8

# 4. Write GOALS.md (human/agent-readable checklist)
$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# Migration Goals — $projFileName")
[void]$md.AppendLine("")
[void]$md.AppendLine("> Generated by dotnet-project-migrator. This file lists what needs to be done")
[void]$md.AppendLine("> to migrate this project to **$TargetFramework** ($sdk). The source in this")
[void]$md.AppendLine("> folder is a staged, UNMODIFIED copy of the original — nothing below has been")
[void]$md.AppendLine("> done automatically yet. Work through the checklist in order, checking items")
[void]$md.AppendLine("> off as you complete them (mirrors goals.json for tracking).")
[void]$md.AppendLine("")
[void]$md.AppendLine("Original project: ``$csprojFull``")
[void]$md.AppendLine("")
[void]$md.AppendLine("**Analysis mode:** $analysisMode")
[void]$md.AppendLine("")
if (-not $uaResult.Success) {
    [void]$md.AppendLine("> ⚠️ upgrade-assistant (Tier 1, deterministic) was unavailable or failed: $($uaResult.Reason)")
    [void]$md.AppendLine("> The code-review findings below came from a plain text-search heuristic only.")
    [void]$md.AppendLine("> Treat them as a starting point, not verified findings — do an AI/agent review pass to confirm.")
    [void]$md.AppendLine("")
}

$byCategory = $tasks | Group-Object Category
foreach ($group in $byCategory) {
    [void]$md.AppendLine("## $($group.Name)")
    [void]$md.AppendLine("")
    foreach ($t in $group.Group) {
        [void]$md.AppendLine("- [ ] **(#$($t.Id), confidence: $($t.Confidence))** $($t.Description)")
        foreach ($d in $t.Details) {
            if ($d) { [void]$md.AppendLine("      - $d") }
        }
    }
    [void]$md.AppendLine("")
}

[void]$md.AppendLine("## Reference")
[void]$md.AppendLine("")
[void]$md.AppendLine("See ``references/breaking-changes.md`` and ``references/migration-checklist.md``")
[void]$md.AppendLine("in the dotnet-project-migrator skill for what each flagged item actually requires.")

$md.ToString() | Out-File -FilePath (Join-Path $destProjDir "GOALS.md") -Encoding UTF8

Write-Host "  Goals:  $(Join-Path $destProjDir 'GOALS.md')"
Write-Host "  Tasks:  $($tasks.Count) ($($signals.Keys.Count) flagged for manual/Roslyn-tool review)"
