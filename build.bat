@echo off
setlocal
set "CONFIG=%~1"
if not defined CONFIG set "CONFIG=debug"
if not "%CONFIG%"=="debug" if not "%CONFIG%"=="release" goto usage
if not "%~2"=="" if not "%~2"=="run" goto usage
if not "%~3"=="" goto usage

set "CMAKE=%~dp0.tools\cmake-4.4.4-windows-x86_64\bin\cmake.exe"
if not exist "%CMAKE%" goto setup
if not exist "%~dp0.tools\ninja\ninja.exe" goto setup
if not exist "%~dp0.tools\vcpkg\vcpkg.exe" goto setup

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo Visual Studio Build Tools was not found. See README.md.
    exit /b 1
)
set "VS="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -prerelease -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS=%%i"
if not defined VS (
    echo Install the MSVC x64/x86 component using cpp-gamedev-buildtools.vsconfig.
    exit /b 1
)
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1

cd /d "%~dp0"
"%CMAKE%" --preset %CONFIG%
if errorlevel 1 exit /b 1
"%CMAKE%" --build --preset %CONFIG%
if errorlevel 1 exit /b 1
if "%~2"=="run" (
    "build\%CONFIG%\warblade.exe"
    exit /b
)
exit /b 0

:setup
echo Run this once, then retry:
echo powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
exit /b 1

:usage
echo Usage: build.bat [debug^|release] [run]
exit /b 2
