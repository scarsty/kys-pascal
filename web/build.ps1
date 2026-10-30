param(
    [string]$GameData,
    [string]$EmsdkRoot = $env:EMSDK,
    [string]$WasmDeps,
    [string]$MlccDir = $env:MLCC_DIR
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$projects = Split-Path -Parent $repo
$reference = Join-Path $projects 'kys-cpp/kys-cpp'
if (-not $GameData) { $GameData = Join-Path $repo 'game-data/kys-dragon' }
if (-not $EmsdkRoot) { $EmsdkRoot = Join-Path $projects 'emsdk' }
if (-not $WasmDeps) { $WasmDeps = Join-Path $reference 'wasm/vcpkg_installed/wasm32-emscripten' }
if (-not $MlccDir) { $MlccDir = Join-Path $reference 'mlcc' }

foreach ($required in @(
    (Join-Path $GameData 'kysmod.ini'),
    (Join-Path $EmsdkRoot 'emsdk_env.ps1'),
    (Join-Path $WasmDeps 'lib/libSDL3.a'),
    (Join-Path $MlccDir 'filefunc.cpp')
)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing build input: $required" }
}

$env:EMSDK_QUIET = '1'
& (Join-Path $EmsdkRoot 'emsdk_env.ps1') | Out-Null
$build = Join-Path $repo 'tmp/wasm/build'
$toolchain = Join-Path $EmsdkRoot 'upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake'
cmake -S (Join-Path $repo 'bin-c') -B $build -G Ninja `
    "-DCMAKE_TOOLCHAIN_FILE=$toolchain" "-DWASM_DEPS_DIR=$WasmDeps" `
    "-DMLCC_DIR=$MlccDir" -DKYS_BUILD_MCP=OFF -DCMAKE_BUILD_TYPE=Release
if ($LASTEXITCODE -ne 0) { throw 'WebAssembly configure failed' }
cmake --build $build --parallel 6
if ($LASTEXITCODE -ne 0) { throw 'WebAssembly build failed' }
python -B (Join-Path $PSScriptRoot 'package_assets.py') $GameData (Join-Path $PSScriptRoot 'dist')
if ($LASTEXITCODE -ne 0) { throw 'Asset packaging failed (Python, Pillow and fontTools are required)' }
