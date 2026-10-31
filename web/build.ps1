param(
    [string]$GameData,
    [string]$EmsdkRoot = $env:EMSDK,
    [string]$WasmDeps,
    [string]$MlccDir = $env:MLCC_DIR,
    [string]$VcpkgRoot = $env:VCPKG_ROOT,
    [switch]$PackageOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$projects = Split-Path -Parent $repo
$reference = Join-Path $projects 'kys-cpp/kys-cpp'
if (-not $GameData) { $GameData = Join-Path $repo 'work/kys-dragon' }
if (-not (Test-Path -LiteralPath (Join-Path $GameData 'kysmod.ini'))) {
    throw "Local game data is missing: $GameData. Populate work/kys-dragon as described in docs/web-build.md; the build does not copy or select golden data."
}
$GameData = (Resolve-Path -LiteralPath $GameData).ProviderPath
Write-Host "Game data source: $GameData"

function Export-GameData {
    python -B (Join-Path $PSScriptRoot 'package_assets.py') $GameData (Join-Path $PSScriptRoot 'dist')
    if ($LASTEXITCODE -ne 0) { throw 'Asset packaging failed (install Python dependencies from web/requirements.txt)' }
}

if ($PackageOnly) {
    foreach ($name in @('kys-dragon.js', 'kys-dragon.wasm')) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "dist/$name"))) {
            throw "Missing dist/$name; run web/build.ps1 without -PackageOnly first."
        }
    }
    Export-GameData
    return
}

if (-not $EmsdkRoot) { $EmsdkRoot = Join-Path $projects 'emsdk' }
if (-not $WasmDeps) { $WasmDeps = Join-Path $reference 'wasm/vcpkg_installed/wasm32-emscripten' }
if (-not $MlccDir) { $MlccDir = Join-Path $reference 'mlcc' }
if (-not $VcpkgRoot) { $VcpkgRoot = Join-Path $projects 'vcpkg' }

foreach ($required in @(
    (Join-Path $GameData 'kysmod.ini'),
    (Join-Path $EmsdkRoot 'emsdk_env.ps1'),
    (Join-Path $WasmDeps 'lib/libSDL3.a'),
    (Join-Path $MlccDir 'filefunc.cpp')
    (Join-Path $VcpkgRoot 'vcpkg.exe')
)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing build input: $required" }
}

$env:EMSDK_QUIET = '1'
& (Join-Path $EmsdkRoot 'emsdk_env.ps1') | Out-Null
$build = Join-Path $repo 'tmp/wasm/build'
$iconvInstall = Join-Path $repo 'tmp/wasm/vcpkg_installed'
& (Join-Path $VcpkgRoot 'vcpkg.exe') install --x-wait-for-lock `
    "--x-manifest-root=$PSScriptRoot" "--x-install-root=$iconvInstall" `
    "--overlay-triplets=$(Join-Path $PSScriptRoot 'triplets')" --triplet=wasm32-emscripten `
    "--x-buildtrees-root=$(Join-Path $repo 'tmp/wasm/vcpkg-buildtrees')" `
    "--x-packages-root=$(Join-Path $repo 'tmp/wasm/vcpkg-packages')"
if ($LASTEXITCODE -ne 0) { throw 'WebAssembly encoding dependency build failed' }
$toolchain = Join-Path $EmsdkRoot 'upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake'
cmake -S (Join-Path $repo 'bin-c') -B $build -G Ninja `
    "-DCMAKE_TOOLCHAIN_FILE=$toolchain" "-DWASM_DEPS_DIR=$WasmDeps" `
    "-DMLCC_DIR=$MlccDir" "-DWASM_ICONV_DIR=$iconvInstall/wasm32-emscripten" `
    -DKYS_BUILD_MCP=OFF -DCMAKE_BUILD_TYPE=Release
if ($LASTEXITCODE -ne 0) { throw 'WebAssembly configure failed' }
cmake --build $build --parallel 6
if ($LASTEXITCODE -ne 0) { throw 'WebAssembly build failed' }
Export-GameData
