@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ------------------------------------------------------------
rem 可按需修改或通过环境变量覆盖（优先级：环境变量 > 默认值）
rem ------------------------------------------------------------
if not defined PATH_CT set "PATH_CT=D:\kys-all\codetyphon"
if not defined PATH_PROJECT set "PATH_PROJECT=D:\kys-all\_pascal\kys-pascal"
if not defined PROJECT set "PROJECT=kys.lpr"
if not defined OUTPUT_SO set "OUTPUT_SO=libkys.so"

set "SCRIPT_DIR=%~dp0"
set "APP_ID=org.libsdl.kys_pascal"
set "LAUNCH_ACTIVITY=org.libsdl.app.SDLActivity"

if "%PATH_CT:~-1%"=="\" set "PATH_CT=%PATH_CT:~0,-1%"
if "%PATH_PROJECT:~-1%"=="\" set "PATH_PROJECT=%PATH_PROJECT:~0,-1%"

set "FPC_EXE=%PATH_CT%\fpc\fpc64\bin\x86_64-win64\fpc.exe"
set "PROJECT_FILE=%PATH_PROJECT%\%PROJECT%"

if not exist "%FPC_EXE%" (
  echo [ERROR] FPC not found: "%FPC_EXE%"
  exit /b 1
)
if not exist "%PROJECT_FILE%" (
  echo [ERROR] Project file not found: "%PROJECT_FILE%"
  exit /b 1
)

echo [1/4] Compile Android SO with FPC...
if not exist "%PATH_PROJECT%\tmp" md "%PATH_PROJECT%\tmp"
if not exist "%PATH_PROJECT%\tmp\android" md "%PATH_PROJECT%\tmp\android"

"%FPC_EXE%" -Tandroid -Paarch64 -MDelphi -Scghi -CX -Os3 -Xs -XX -l -vewnhibq -Fi"%PATH_PROJECT%\tmp\android" -Fl"%PATH_PROJECT%\lib" -Fl"%PATH_CT%\binLibraries\android-5.0.x-api21-aarch64" -Fl"%PATH_CT%\lib\arm64-v8a" -Fu"%PATH_PROJECT%\lib" -Fu"%PATH_CT%\typhon\lcl\units\aarch64-android\customdrawn" -Fu"%PATH_CT%\typhon\lcl\units\aarch64-android" -Fu"%PATH_CT%\typhon\components\BaseUtils\lib\aarch64-android" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\rtl-objpas" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-image" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-base" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\paszlib" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\hash" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\pasjpeg" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-process" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\chm" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-json" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\chm" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-xml" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\pthreads" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\rtl-generics" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-extra" -Fu"%PATH_CT%\fpc\fpc64\units\aarch64-android\fcl-res" -FU"%PATH_PROJECT%\android" -FE"%SCRIPT_DIR%" -o"%OUTPUT_SO%" -dLCL -dadLCL -dLCLcustomdrawn "%PROJECT_FILE%"
if errorlevel 1 (
  echo [ERROR] FPC compile failed.
  exit /b 1
)

echo [2/4] Copy SO into Android app jniLibs...
if not exist "%SCRIPT_DIR%app\lib\arm64-v8a" md "%SCRIPT_DIR%app\lib\arm64-v8a"
copy /y "%SCRIPT_DIR%%OUTPUT_SO%" "%SCRIPT_DIR%app\lib\arm64-v8a\%OUTPUT_SO%" >nul
if errorlevel 1 (
  echo [ERROR] Failed to copy %OUTPUT_SO% to app/lib/arm64-v8a.
  exit /b 1
)

echo [3/4] Build release APK...
pushd "%SCRIPT_DIR%"
call gradlew.bat assembleRelease
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

echo [4/4] Detect device and run app...
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

popd
exit /b 0
