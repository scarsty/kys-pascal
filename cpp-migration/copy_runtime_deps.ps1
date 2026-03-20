param(
    [Parameter(Mandatory = $true)]
    [string]$ExePath,
    [Parameter(Mandatory = $true)]
    [string]$OutputDir
)

$ErrorActionPreference = 'Stop'

function Get-DumpbinPath {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) {
        return $null
    }

    $dumpbin = & $vswhere -latest -find "VC\Tools\MSVC\**\bin\Hostx64\x64\dumpbin.exe" | Select-Object -First 1
    if (-not $dumpbin) {
        return $null
    }
    return $dumpbin
}

function Get-SearchPaths {
    param(
        [string]$Exe,
        [string]$OutDir
    )

    $paths = New-Object System.Collections.Generic.List[string]

    $exeDir = Split-Path -Parent $Exe
    $buildRoot = Split-Path -Parent $exeDir
    $debugDir = Join-Path $buildRoot "Debug"

    # Do not use exe/output directory as source to avoid recursively copying stale DLLs.
    foreach ($p in @($debugDir)) {
        if ($p -and (Test-Path $p)) {
            $paths.Add((Resolve-Path $p).Path)
        }
    }

    foreach ($p in @(
        "$env:VCPKG_ROOT\installed\x64-windows\bin",
        "$env:UserProfile\vcpkg\installed\x64-windows\bin",
        "$env:UserProfile\AppData\Local\vcpkg\installed\x64-windows\bin",
        "C:\vcpkg\installed\x64-windows\bin",
        "C:\project\smallpot\smallpot-x64",
        "C:\project\smallpot\x64\Release",
        "C:\project\smallpot\x64\Debug"
    )) {
        if ($p -and (Test-Path $p)) {
            $paths.Add((Resolve-Path $p).Path)
        }
    }

    # Unique preserve order
    $seen = @{}
    $unique = New-Object System.Collections.Generic.List[string]
    foreach ($p in $paths) {
        $k = $p.ToLowerInvariant()
        if (-not $seen.ContainsKey($k)) {
            $seen[$k] = $true
            $unique.Add($p)
        }
    }

    return $unique
}

function Is-WindowsSystemPath {
    param([string]$Path)
    if (-not $Path) {
        return $false
    }
    $p = $Path.ToLowerInvariant()
    return ($p.StartsWith("c:\\windows\\") -or $p.StartsWith("$($env:windir.ToLowerInvariant())\\"))
}

if (-not (Test-Path $ExePath)) {
    Write-Warning "EXE not found: $ExePath"
    exit 0
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Remove stale DLLs first so each build produces a deterministic dependency set.
Get-ChildItem -Path $OutputDir -Filter "*.dll" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

$dumpbin = Get-DumpbinPath
if (-not $dumpbin) {
    Write-Warning "dumpbin not found, skip recursive dependency copy"
    exit 0
}

$searchPaths = Get-SearchPaths -Exe $ExePath -OutDir $OutputDir

$skipPattern = '^(KERNEL32|USER32|WS2_32|ADVAPI32|SHELL32|ole32|OLEAUT32|GDI32|msvcrt|VCRUNTIME|ucrtbase|api-ms-).*\.dll$'
$processedDlls = @{}
$scannedFiles = @{}
$queue = New-Object System.Collections.Generic.Queue[string]
$queue.Enqueue((Resolve-Path $ExePath).Path)
$maxIterations = 5000
$iterations = 0
$copied = 0

while ($queue.Count -gt 0 -and $iterations -lt $maxIterations) {
    $iterations++
    $currentFile = $queue.Dequeue()
    $scanKey = $currentFile.ToLowerInvariant()
    if ($scannedFiles.ContainsKey($scanKey)) {
        continue
    }
    $scannedFiles[$scanKey] = $true

    $dumpOutput = & $dumpbin /dependents $currentFile 2>$null
    if (-not $dumpOutput) {
        continue
    }

    $dlls = $dumpOutput |
        Where-Object { $_ -match '^\s+\S+\.dll\s*$' } |
        ForEach-Object { $_.Trim() }

    foreach ($dll in $dlls) {
        $dllKey = $dll.ToLowerInvariant()
        if ($processedDlls.ContainsKey($dllKey)) {
            continue
        }
        $processedDlls[$dllKey] = $true

        if ($dll -match $skipPattern) {
            continue
        }

        $source = $null
        foreach ($dir in $searchPaths) {
            $candidate = Join-Path $dir $dll
            if (Test-Path $candidate) {
                $source = (Resolve-Path $candidate).Path
                break
            }
        }

        if (-not $source) {
            continue
        }

        if (Is-WindowsSystemPath -Path $source) {
            continue
        }

        $target = Join-Path $OutputDir $dll
        Copy-Item $source $target -Force
        $copied++
        $queue.Enqueue((Resolve-Path $target).Path)
    }
}

Write-Host "Recursive dependency copy finished. Copied DLLs: $copied"
