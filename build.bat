@echo off
setlocal
set "CONFIG=%~1"
if not defined CONFIG set "CONFIG=debug"
if not "%CONFIG%"=="debug" if not "%CONFIG%"=="release" if not "%CONFIG%"=="asan" goto usage
if not "%~2"=="" if not "%~2"=="run" if not "%~2"=="package" goto usage
if "%~2"=="package" if not "%CONFIG%"=="release" goto usage
if not "%~3"=="" goto usage

set "CMAKE=%~dp0.tools\cmake-4.4.4-windows-x86_64\bin\cmake.exe"
if not exist "%CMAKE%" goto setup
if not exist "%~dp0.tools\ninja\ninja.exe" goto setup
if not exist "%~dp0.tools\vcpkg\vcpkg.exe" goto setup
if "%~2"=="package" if not exist "%~dp0.tools\innosetup-7.1.0\ISCC.exe" goto setup

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo Visual Studio Build Tools was not found. See README.md.
    exit /b 1
)
set "VS="
set "COMPONENTS=Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
if "%CONFIG%"=="asan" set "COMPONENTS=%COMPONENTS% Microsoft.VisualStudio.Component.VC.ASAN"
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -prerelease -requires %COMPONENTS% -property installationPath`) do set "VS=%%i"
if not defined VS (
    echo Required MSVC components were not found. Import cpp-gamedev-buildtools.vsconfig.
    exit /b 1
)
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1

cd /d "%~dp0"
"%CMAKE%" --preset %CONFIG%
if errorlevel 1 exit /b 1
"%CMAKE%" --build --preset %CONFIG%
if errorlevel 1 exit /b 1
if "%~2"=="package" goto package
if "%~2"=="run" goto run
exit /b 0

:package
"%~dp0.tools\cmake-4.4.4-windows-x86_64\bin\cpack.exe" --preset release
exit /b %ERRORLEVEL%

:run
"build\%CONFIG%\warblade.exe"
exit /b %ERRORLEVEL%

:setup
echo Run this once, then retry:
echo powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
exit /b 1

:usage
echo Usage: build.bat [debug^|asan^|release] [run]
echo        build.bat release package
exit /b 2
