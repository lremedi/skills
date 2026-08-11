<#
.SYNOPSIS
    Agent-agnostic .NET Framework solution analyzer. Cross-platform PowerShell
    (7+), no external modules required.

.DESCRIPTION
    Given a .sln file, this script:
      1. Parses the solution file to find every project and its path.
      2. Parses each .csproj to find ProjectReferences, output type, target
         framework, package management style (packages.config vs
         PackageReference), and "signal" APIs that indicate migration risk
         (WCF, Remoting, EF6, System.Web, etc).
      3. Builds a dependency graph (A -> B means "A references B") and
         computes a bottom-up topological order: projects with no
         un-migrated internal dependencies come first (leaves-first, the
         order the migration guide recommends: class libraries first,
         entry points last).
      4. Buckets projects into phases (Libraries / Data Access / Business
         Logic / Entry Points / Tests) matching the 4-phase strategy from
         the guide.
      5. Writes migration-plan.json (machine-readable, consumed by the
         dotnet-project-migrator skill) and migration-plan.md
         (human-readable).

.PARAMETER SlnPath
    Path to the .sln file to analyze.

.PARAMETER OutDir
    Directory to write migration-plan.json / migration-plan.md into.
    Defaults to the current directory.

.EXAMPLE
    ./Analyze-Solution.ps1 -SlnPath ./MySolution.sln -OutDir ./plan
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SlnPath,

    [Parameter(Mandatory = $false)]
    [string]$OutDir = "."
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Signal patterns: cheap text-search heuristics for migration-risk APIs.
# ---------------------------------------------------------------------------
$SignalPatterns = [ordered]@{
    "wcf"                = 'System\.ServiceModel'
    "remoting"            = 'System\.Runtime\.Remoting'
    "appdomain"           = 'AppDomain\.CreateDomain'
    "webforms_or_mvc"     = 'System\.Web(\.Mvc)?(?!\.Http)'
    "webapi"              = 'System\.Web\.Http'
    "entity_framework6"   = '\bEntityFramework\b|System\.Data\.Entity'
    "config_manager"      = 'System\.Configuration\.ConfigurationManager|ConfigurationManager\.'
    "windows_specific"    = 'Microsoft\.Win32|System\.Management\b|System\.DirectoryServices'
    "signalr_legacy"      = 'Microsoft\.AspNet\.SignalR'
}

$TestPackageHints = @("MSTest", "nunit", "xunit", "Microsoft.NET.Test.Sdk")

function ConvertTo-NativePath {
    param([string]$Path)
    # .sln/.csproj files always use Windows-style backslashes regardless of
    # the OS this script runs on; normalize to forward slashes, which
    # Join-Path / Resolve-Path handle fine on every platform.
    return $Path -replace '\\', '/'
}

function Get-SolutionProjects {
    param([string]$Path)

    $slnDir = Split-Path -Parent (Resolve-Path $Path)
    $content = Get-Content -Raw -Path $Path -Encoding UTF8

    $pattern = 'Project\("\{[0-9A-Fa-f-]+\}"\)\s*=\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"\{([0-9A-Fa-f-]+)\}"'
    $matches = [regex]::Matches($content, $pattern)

    $projects = @()
    foreach ($m in $matches) {
        $name    = $m.Groups[1].Value
        $relPath = $m.Groups[2].Value
        $guid    = $m.Groups[3].Value.ToUpper()

        if ($relPath -notmatch '\.(csproj|vbproj)$') { continue }

        $relPathNative = ConvertTo-NativePath $relPath
        $absPath = [System.IO.Path]::GetFullPath((Join-Path $slnDir $relPathNative))

        $projects += [pscustomobject]@{
            Name    = $name
            Guid    = $guid
            RelPath = $relPath
            AbsPath = $absPath
        }
    }
    return $projects
}

function Get-ProjectDetails {
    param([pscustomobject]$Project)

    $path = $Project.AbsPath
    $exists = Test-Path -LiteralPath $path -PathType Leaf

    $details = [pscustomobject]@{
        Exists                 = $exists
        ProjectReferences      = @()
        OutputType             = $null
        TargetFrameworkVersion = $null
        IsSdkStyle             = $false
        UsesPackagesConfig     = $false
        Signals                = @()
        IsTestProject          = $false
        ParseError             = $false
    }

    if (-not $exists) { return $details }

    $projDir = Split-Path -Parent $path

    $packagesConfigPath = Join-Path $projDir "packages.config"
    if (Test-Path -LiteralPath $packagesConfigPath -PathType Leaf) {
        $details.UsesPackagesConfig = $true
        try {
            $pkgContent = Get-Content -Raw -Path $packagesConfigPath -Encoding UTF8
            foreach ($hint in $TestPackageHints) {
                if ($pkgContent -match [regex]::Escape($hint)) {
                    $details.IsTestProject = $true
                    break
                }
            }
        } catch { }
    }

    try {
        [xml]$xml = Get-Content -Raw -Path $path -Encoding UTF8
    } catch {
        $details.ParseError = $true
        return $details
    }

    $root = $xml.DocumentElement
    if ($root.Attributes["Sdk"]) { $details.IsSdkStyle = $true }

    # OutputType / TargetFrameworkVersion / TargetFramework
    $outputTypeNode = $xml.SelectSingleNode("//*[local-name()='OutputType']")
    if ($outputTypeNode) { $details.OutputType = $outputTypeNode.InnerText.Trim() }

    $tfvNode = $xml.SelectSingleNode("//*[local-name()='TargetFrameworkVersion']")
    if ($tfvNode) { $details.TargetFrameworkVersion = $tfvNode.InnerText.Trim() }
    else {
        $tfNode = $xml.SelectSingleNode("//*[local-name()='TargetFramework']")
        if ($tfNode) { $details.TargetFrameworkVersion = $tfNode.InnerText.Trim() }
    }

    # ProjectReference
    $projRefNodes = $xml.SelectNodes("//*[local-name()='ProjectReference']")
    foreach ($node in $projRefNodes) {
        $include = $node.GetAttribute("Include")
        if ($include) {
            $includeNative = ConvertTo-NativePath $include
            $resolved = [System.IO.Path]::GetFullPath((Join-Path $projDir $includeNative))
            $details.ProjectReferences += $resolved
        }
    }

    # PackageReference / Reference -> test project detection
    $pkgRefNodes = $xml.SelectNodes("//*[local-name()='PackageReference']")
    foreach ($node in $pkgRefNodes) {
        $pkgId = $node.GetAttribute("Include")
        if (-not $pkgId) { $pkgId = $node.GetAttribute("Update") }
        foreach ($hint in $TestPackageHints) {
            if ($pkgId -and $pkgId -match [regex]::Escape($hint)) { $details.IsTestProject = $true }
        }
    }
    $refNodes = $xml.SelectNodes("//*[local-name()='Reference']")
    foreach ($node in $refNodes) {
        $include = $node.GetAttribute("Include")
        foreach ($hint in $TestPackageHints) {
            if ($include -and $include -match [regex]::Escape($hint)) { $details.IsTestProject = $true }
        }
    }

    # Scan source files for signal APIs (cheap heuristic, not a full analyzer)
    $signalsFound = New-Object System.Collections.Generic.HashSet[string]
    $files = Get-ChildItem -Path $projDir -Recurse -File -Include *.cs, *.config, *.vb -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch [regex]::Escape([IO.Path]::DirectorySeparatorChar + "bin" + [IO.Path]::DirectorySeparatorChar) -and
            $_.FullName -notmatch [regex]::Escape([IO.Path]::DirectorySeparatorChar + "obj" + [IO.Path]::DirectorySeparatorChar) -and
            $_.FullName -notmatch '\.vs' -and
            $_.FullName -notmatch [regex]::Escape([IO.Path]::DirectorySeparatorChar + "packages" + [IO.Path]::DirectorySeparatorChar)
        }
    foreach ($file in $files) {
        $text = Get-Content -Raw -Path $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $text) { continue }
        foreach ($key in $SignalPatterns.Keys) {
            if (-not $signalsFound.Contains($key) -and $text -match $SignalPatterns[$key]) {
                [void]$signalsFound.Add($key)
            }
        }
    }
    $details.Signals = @($signalsFound | Sort-Object)

    return $details
}

function Get-ProjectPhase {
    param([pscustomobject]$Proj)

    if ($Proj.IsTestProject) { return "0-tests" }
    if ($Proj.Signals -contains "wcf" -or $Proj.Signals -contains "remoting") { return "3-business-logic-services" }
    if ($Proj.Signals -contains "entity_framework6") { return "2-data-access" }

    $outType = if ($Proj.OutputType) { $Proj.OutputType.ToLower() } else { "" }
    if ($outType -in @("exe", "winexe") -or $Proj.Signals -contains "webforms_or_mvc" -or $Proj.Signals -contains "webapi") {
        return "4-entry-points"
    }
    return "1-class-libraries"
}

function Get-MigrationOrder {
    param([hashtable]$ByPath)

    # dependency edges limited to in-solution projects
    $deps = @{}
    foreach ($path in $ByPath.Keys) {
        $deps[$path] = @($ByPath[$path].ProjectReferences | Where-Object { $ByPath.ContainsKey($_) })
    }

    $dependents = @{}
    foreach ($path in $ByPath.Keys) { $dependents[$path] = @() }
    foreach ($path in $deps.Keys) {
        foreach ($d in $deps[$path]) {
            $dependents[$d] += $path
        }
    }

    $indegree = @{}
    foreach ($path in $ByPath.Keys) { $indegree[$path] = $deps[$path].Count }

    $visited = New-Object System.Collections.Generic.HashSet[string]
    $order = New-Object System.Collections.Generic.List[string]
    $ready = New-Object System.Collections.Generic.List[string]
    foreach ($path in $indegree.Keys) { if ($indegree[$path] -eq 0) { $ready.Add($path) } }

    while ($ready.Count -gt 0) {
        $sorted = @($ready | Sort-Object { $ByPath[$_].Name })
        $current = $sorted[0]
        $ready.Remove($current) | Out-Null
        if ($visited.Contains($current)) { continue }
        [void]$visited.Add($current)
        $order.Add($current)
        foreach ($dependent in $dependents[$current]) {
            $indegree[$dependent] -= 1
            if ($indegree[$dependent] -eq 0 -and -not $visited.Contains($dependent)) {
                $ready.Add($dependent)
            }
        }
    }

    $cyclic = @($ByPath.Keys | Where-Object { -not $visited.Contains($_) })
    return @{ Order = $order; Cyclic = $cyclic; Deps = $deps }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $SlnPath -PathType Leaf)) {
    Write-Error "Solution file not found: $SlnPath"
    exit 1
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$projects = Get-SolutionProjects -Path $SlnPath
if ($projects.Count -eq 0) {
    Write-Error "No C#/VB projects found in solution (check the .sln path)."
    exit 1
}

$byPath = @{}
foreach ($p in $projects) {
    $details = Get-ProjectDetails -Project $p
    $merged = [pscustomobject]@{
        Name                   = $p.Name
        Guid                   = $p.Guid
        RelPath                = $p.RelPath
        AbsPath                = $p.AbsPath
        Exists                 = $details.Exists
        ProjectReferences      = $details.ProjectReferences
        OutputType             = $details.OutputType
        TargetFrameworkVersion = $details.TargetFrameworkVersion
        IsSdkStyle             = $details.IsSdkStyle
        UsesPackagesConfig     = $details.UsesPackagesConfig
        Signals                = $details.Signals
        IsTestProject          = $details.IsTestProject
    }
    $byPath[$p.AbsPath] = $merged
}

$result = Get-MigrationOrder -ByPath $byPath
$order = $result.Order
$cyclic = $result.Cyclic
$deps = $result.Deps

$phaseRank = @{
    "1-class-libraries"          = 0
    "2-data-access"              = 1
    "3-business-logic-services"  = 2
    "4-entry-points"             = 3
    "0-tests"                    = 4
}

$plan = New-Object System.Collections.Generic.List[pscustomobject]
$i = 1
foreach ($path in $order) {
    $p = $byPath[$path]
    $phase = Get-ProjectPhase -Proj $p
    $dependsOnNames = @($deps[$path] | ForEach-Object { $byPath[$_].Name })
    $plan.Add([pscustomobject]@{
        Order                   = $i
        Name                    = $p.Name
        CsprojPath              = $p.AbsPath
        RelPath                 = $p.RelPath
        Phase                   = $phase
        OutputType              = $p.OutputType
        CurrentTargetFramework  = $p.TargetFrameworkVersion
        IsSdkStyle              = $p.IsSdkStyle
        UsesPackagesConfig      = $p.UsesPackagesConfig
        IsTestProject           = $p.IsTestProject
        DependsOn               = $dependsOnNames
        Signals                 = $p.Signals
        Exists                  = $p.Exists
    })
    $i++
}

# Re-sort by phase, then by the topological order already assigned, so
# libraries always precede entry points even when the graph alone doesn't
# force that (e.g. independent libraries with no shared dependents).
$sortedPlan = @($plan | Sort-Object @{Expression = { $phaseRank[$_.Phase] } }, Order)
$i = 1
foreach ($item in $sortedPlan) { $item.Order = $i; $i++ }

$cyclicNames = @($cyclic | ForEach-Object { $byPath[$_].Name })

$resultObj = [pscustomobject]@{
    Solution           = (Resolve-Path $SlnPath).Path
    ProjectCount       = $projects.Count
    CyclicOrUnresolved = $cyclicNames
    MigrationOrder     = $sortedPlan
}

$jsonPath = Join-Path $OutDir "migration-plan.json"
$resultObj | ConvertTo-Json -Depth 8 | Out-File -FilePath $jsonPath -Encoding UTF8

$mdPath = Join-Path $OutDir "migration-plan.md"
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Migration Plan for $(Split-Path -Leaf $SlnPath)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Total projects: $($projects.Count)")
[void]$sb.AppendLine("")
if ($cyclicNames.Count -gt 0) {
    [void]$sb.AppendLine("> ⚠️ **Unresolved / cyclic dependencies detected** — fix these manually before migrating: $($cyclicNames -join ', ')")
    [void]$sb.AppendLine("")
}

$phaseTitles = @{
    "1-class-libraries"         = "Phase 1 — Class Libraries"
    "2-data-access"             = "Phase 2 — Data Access Layer"
    "3-business-logic-services" = "Phase 3 — Business Logic / Services (incl. WCF)"
    "4-entry-points"            = "Phase 4 — Application Entry Points"
    "0-tests"                   = "Test Projects (migrate alongside the project they cover)"
}

$currentPhase = $null
foreach ($item in $sortedPlan) {
    if ($item.Phase -ne $currentPhase) {
        $currentPhase = $item.Phase
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## $($phaseTitles[$currentPhase])")
        [void]$sb.AppendLine("")
    }
    $flags = New-Object System.Collections.Generic.List[string]
    if ($item.UsesPackagesConfig) { $flags.Add("packages.config") }
    if ($item.Signals.Count -gt 0) { $flags.Add("signals: " + ($item.Signals -join ", ")) }
    if (-not $item.Exists) { $flags.Add("⚠️ csproj not found on disk") }
    $flagStr = if ($flags.Count -gt 0) { " — " + ($flags -join " | ") } else { "" }
    $depsStr = if ($item.DependsOn.Count -gt 0) { " (depends on: $($item.DependsOn -join ', '))" } else { "" }
    [void]$sb.AppendLine("$($item.Order). **$($item.Name)** ($($item.RelPath))$depsStr$flagStr")
}
$sb.ToString() | Out-File -FilePath $mdPath -Encoding UTF8

Write-Host "Wrote $jsonPath"
Write-Host "Wrote $mdPath"
Write-Host ""
Write-Host "$($projects.Count) projects planned. Migration order (leaves first):"
foreach ($item in $sortedPlan) {
    Write-Host ("  {0,2}. [{1}] {2}" -f $item.Order, $item.Phase, $item.Name)
}
