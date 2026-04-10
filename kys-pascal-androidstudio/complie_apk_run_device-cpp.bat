@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ------------------------------------------------------------
rem C++ 版本 Android APK 编译脚本
rem C++ 源码由 Gradle/CMake/NDK 自动编译，无需手动编译 SO
rem ------------------------------------------------------------

set "SCRIPT_DIR=%~dp0"
set "APP_ID=org.libsdl.kys_pascal_c"
set "LAUNCH_ACTIVITY=org.libsdl.app.SDLActivity"
set "EXPORT_DIR=%SCRIPT_DIR%export-cpp"
set "SO_NAME=libkys_pascal_c.so"
set "LOCAL_PROPERTIES=%SCRIPT_DIR%local.properties"
set "SDK_DIR="
set "NDK_DIR="
set "NDK_VERSION=29.0.14206865"
set "VCPKG_ROOT_DIR="
set "MLCC_DIR="
set "STRIPPED_SO_FILE=%SCRIPT_DIR%app\build\intermediates\stripped_native_libs\release\stripReleaseDebugSymbols\out\lib\arm64-v8a\%SO_NAME%"
set "MERGED_SO_FILE=%SCRIPT_DIR%app\build\intermediates\merged_native_libs\release\mergeReleaseNativeLibs\out\lib\arm64-v8a\%SO_NAME%"
set "SO_FILE=%STRIPPED_SO_FILE%"

if exist "%LOCAL_PROPERTIES%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%LOCAL_PROPERTIES%") do (
    if /I "%%~A"=="sdk.dir" set "SDK_DIR=%%~B"
  )
)

if defined SDK_DIR (
  set "SDK_DIR=!SDK_DIR:\:=:!"
  set "SDK_DIR=!SDK_DIR:\\=\!"
)

if defined ANDROID_SDK_ROOT if not defined SDK_DIR (
  set "SDK_DIR=%ANDROID_SDK_ROOT%"
)

if defined ANDROID_HOME if not defined SDK_DIR (
  set "SDK_DIR=%ANDROID_HOME%"
)

if defined ANDROID_NDK_VERSION (
  set "NDK_VERSION=%ANDROID_NDK_VERSION%"
)

if defined ANDROID_NDK_HOME (
  set "NDK_DIR=%ANDROID_NDK_HOME%"
) else if defined NDK_HOME (
  set "NDK_DIR=%NDK_HOME%"
) else if defined SDK_DIR if exist "%SDK_DIR%\ndk\%NDK_VERSION%" (
  set "NDK_DIR=%SDK_DIR%\ndk\%NDK_VERSION%"
) else if defined SDK_DIR if exist "%SDK_DIR%\ndk" (
  for /f "delims=" %%D in ('dir /b /ad /o-n "%SDK_DIR%\ndk"') do (
    if not defined NDK_DIR set "NDK_DIR=%SDK_DIR%\ndk\%%D"
  )
) else if defined SDK_DIR if exist "%SDK_DIR%\ndk-bundle" (
  set "NDK_DIR=%SDK_DIR%\ndk-bundle"
)

if not defined VCPKG_ROOT_DIR if defined VCPKG_ROOT (
  set "VCPKG_ROOT_DIR=%VCPKG_ROOT%"
)
if not defined VCPKG_ROOT_DIR if exist "D:\project\vcpkg\vcpkg.exe" (
  set "VCPKG_ROOT_DIR=D:\project\vcpkg"
)
if not defined VCPKG_ROOT_DIR if exist "C:\project\vcpkg\vcpkg.exe" (
  set "VCPKG_ROOT_DIR=C:\project\vcpkg"
)
if not defined VCPKG_ROOT_DIR if exist "%USERPROFILE%\vcpkg\vcpkg.exe" (
  set "VCPKG_ROOT_DIR=%USERPROFILE%\vcpkg"
)

if defined MLCC_DIR if exist "%MLCC_DIR%\filefunc.cpp" set "MLCC_DIR=%MLCC_DIR%"
if not defined MLCC_DIR if exist "%SCRIPT_DIR%..\mlcc\filefunc.cpp" (
  set "MLCC_DIR=%SCRIPT_DIR%..\mlcc"
)
if not defined MLCC_DIR if exist "C:\project\mlcc\filefunc.cpp" (
  set "MLCC_DIR=C:\project\mlcc"
)
if not defined MLCC_DIR if exist "D:\project\mlcc\filefunc.cpp" (
  set "MLCC_DIR=D:\project\mlcc"
)

if defined NDK_DIR (
  set "ANDROID_NDK_HOME=%NDK_DIR%"
  set "NDK_HOME=%NDK_DIR%"
)
if defined SDK_DIR set "ANDROID_SDK_ROOT=%SDK_DIR%"
if defined SDK_DIR set "ANDROID_HOME=%SDK_DIR%"
if defined VCPKG_ROOT_DIR set "VCPKG_ROOT=%VCPKG_ROOT_DIR%"
if defined MLCC_DIR set "MLCC_DIR=%MLCC_DIR%"
set "ANDROID_NDK_VERSION=%NDK_VERSION%"

echo Environment:
if defined SDK_DIR echo   SDK_DIR=%SDK_DIR%
if defined NDK_DIR echo   NDK_DIR=%NDK_DIR%
if defined VCPKG_ROOT_DIR echo   VCPKG_ROOT=%VCPKG_ROOT_DIR%
if defined MLCC_DIR echo   MLCC_DIR=%MLCC_DIR%

echo [1/2] Build release APK (C++ compiled by CMake/NDK)...
pushd "%SCRIPT_DIR%"
call gradlew.bat --no-daemon assembleRelease
if errorlevel 1 (
  popd
  echo [ERROR] Gradle build failed.
  exit /b 1
)

set "APK_FILE="
for %%F in ("%SCRIPT_DIR%app\build\outputs\apk\release\*.apk") do (
  set "APK_FILE=%%~fF"
)
if not defined APK_FILE (
  popd
  echo [ERROR] APK not found in app\build\outputs\apk\release.
  exit /b 1
)
copy /y "%APK_FILE%" "%SCRIPT_DIR%" >nul

echo [2/3] Export SO and NDK...
if not exist "%EXPORT_DIR%" md "%EXPORT_DIR%"

if not exist "%SO_FILE%" (
  set "SO_FILE=%MERGED_SO_FILE%"
)

if not exist "%SO_FILE%" (
  popd
  echo [ERROR] Built SO not found: "%SO_FILE%"
  exit /b 1
)

copy /y "%SO_FILE%" "%SCRIPT_DIR%%SO_NAME%" >nul
if errorlevel 1 (
  popd
  echo [ERROR] Failed to copy %SO_NAME% to script directory.
  exit /b 1
)
if /I "%SO_FILE%"=="%STRIPPED_SO_FILE%" (
  echo Exported stripped SO.
) else (
  echo [WARN] Stripped SO not found. Exported merged SO instead.
)

if defined NDK_DIR if exist "%NDK_DIR%" (
  if exist "%EXPORT_DIR%\ndk" rmdir /s /q "%EXPORT_DIR%\ndk"
  robocopy "%NDK_DIR%" "%EXPORT_DIR%\ndk" /E /NFL /NDL /NJH /NJS /NP >nul
  set "ROBOCOPY_EXIT=!ERRORLEVEL!"
  if !ROBOCOPY_EXIT! GEQ 8 (
    popd
    echo [ERROR] Failed to export NDK from "%NDK_DIR%".
    exit /b 1
  )
) else (
  echo [WARN] NDK directory not found. Skipped NDK export.
)

echo [3/3] Detect device and run app...
set "ADB_EXE=adb"
where adb >nul 2>nul
if errorlevel 1 (
  if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    set "ADB_EXE=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
  )
)

set "HAS_DEVICE=0"
for /f "skip=1 tokens=1,2" %%A in ('"%ADB_EXE%" devices 2^>nul') do (
  set "SERIAL=%%A"
  if "%%B"=="device" (
    if /I not "!SERIAL:~0,9!"=="emulator-" set "HAS_DEVICE=1"
  )
)

if "%HAS_DEVICE%"=="1" (
  echo Device detected. Installing APK...
  "%ADB_EXE%" install -r "%APK_FILE%"
  if errorlevel 1 (
    popd
    echo [ERROR] APK install failed.
    exit /b 1
  )
  echo Launching app...
  "%ADB_EXE%" shell am start -n %APP_ID%/%LAUNCH_ACTIVITY%
  if errorlevel 1 (
    popd
    echo [ERROR] App launch failed.
    exit /b 1
  )
  echo Done: built, installed and launched.
) else (
  echo No physical device detected. APK built at:
  echo   %APK_FILE%
)

echo Exported artifacts:
echo   %SCRIPT_DIR%%SO_NAME%
if defined NDK_DIR if exist "%EXPORT_DIR%\ndk" echo   %EXPORT_DIR%\ndk

popd
exit /b 0
