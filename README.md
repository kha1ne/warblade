# Warblade

A minimal C++ starter for a future Warblade remake. It currently prints:

```text
Hello, Warblade!
```

There is one executable and one source file. No SDL, game assets, test framework,
or engine code is included yet. vcpkg is connected in manifest mode with an empty
dependency list, ready for libraries when needed.

## Requirements

- Windows x64 and Git for Windows.
- Visual Studio Build Tools 2026, including MSVC x64/x86 and a Windows SDK.
  Import `cpp-gamedev-buildtools.vsconfig` into the **Build Tools** installer.
  The full Visual Studio IDE is unnecessary. Insiders installations are supported.
- Internet access for the first tool setup and configure (vcpkg may fetch helper tools).

## Build and run

Open PowerShell in this directory. Download the project-local tools once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

Then configure, build, and run:

```powershell
.\build.bat debug run
```

For an optimized build:

```powershell
.\build.bat release run
```

Omit `run` to build only. You can also run an existing executable directly:

```powershell
.\build\debug\warblade.exe
.\build\release\warblade.exe
```

The build wrapper finds Build Tools automatically (including Insiders), initializes
the x64 MSVC environment, and runs the matching CMake configure/build presets.
It works from an ordinary terminal; no permanent PATH changes are required.

## Tool versions

Latest stable releases checked on **2026-10-25**, pinned for reproducible setup:

| Tool | Version |
| --- | --- |
| CMake | [4.4.4](https://github.com/Kitware/CMake/releases/tag/v4.4.4) |
| Ninja | [1.13.2](https://github.com/ninja-build/ninja/releases/tag/v1.13.2) |
| vcpkg registry/scripts | [2026.10.16](https://github.com/microsoft/vcpkg/releases/tag/2026.10.16) |
| Compiler | Installed MSVC x64 toolset |
| Language | C++23 |

`setup.ps1` downloads official portable CMake/Ninja releases and verifies SHA-256
hashes, then checks out the pinned vcpkg release and runs its official bootstrap.
It stores everything under ignored `.tools/`; no global tool installation is changed.
Rerunning setup reuses existing tools. vcpkg's bootstrap selects the executable
version recorded by its release; its version date can differ from the registry tag.

The Windows presets use Ninja, separate Debug/Release build directories, and the
`x64-windows-static` vcpkg triplet with the matching static MSVC runtime.

## VS Code

Install the recommended **C/C++** and **CMake Tools** extensions, then run setup.
Use **CMake: Select Configure Preset** to choose `debug` or `release`, followed by
**CMake: Build** or **CMake: Debug**. The presets declare the external x64 architecture
so CMake Tools can initialize MSVC. The terminal build command above is also available.

## Layout

```text
src/main.cpp                     Hello World executable
CMakeLists.txt                   Target, C++ standard, and compiler warnings
CMakePresets.json                Ninja + vcpkg Debug/Release configuration
vcpkg.json                       Pinned dependency baseline; currently no packages
setup.ps1                        One-time local tool download
build.bat                        Configure, build, and optionally run
cpp-gamedev-buildtools.vsconfig   Minimal Microsoft Build Tools component selection
.vscode/                         Editor configuration and extension recommendations
LICENSE                          MIT license for this starter
```

## Adding dependencies

Add packages to `dependencies` in `vcpkg.json`, then use `find_package()` and
`target_link_libraries()` in `CMakeLists.txt`. The next configure installs them.
The baseline pins the dependency registry; it does not automatically follow newer
package releases. SDL3, SDL3_image, and SDL3_mixer will be separate dependencies
when graphics/audio are introduced.

## Repository and references

Remote: <https://github.com/kha1ne/warblade>.

Reviewed `C:\Development\CppApp`, the local `cpp-project` template, and these
references for structure and tooling. This starter is written independently:

- [bsamseth/cpp-project](https://github.com/bsamseth/cpp-project)
- [C++ Best Practices CMake template](https://github.com/cpp-best-practices/cmake_template)
- [Microsoft's CMake/vcpkg quick start](https://learn.microsoft.com/en-us/vcpkg/get_started/get-started)
- [CMake presets](https://cmake.org/cmake/help/v4.4/manual/cmake-presets.7.html)
- [WarbladeSR SDL branch](https://github.com/bbepis/WarbladeSR/tree/sdl)

`WarbladeSR-inspect/` is an ignored, separate reference checkout. No code or assets
from it are incorporated into this starter. Original Warblade game assets are not
included or covered by this project's MIT license. Dependencies retain their own
licenses.

## Verification

Debug and Release were configured, built, and run on Windows with MSVC
19.52.37025.0, CMake 4.4.4, Ninja 1.13.2, and the pinned vcpkg release. Both
printed `Hello, Warblade!` and exited successfully. Setup was also rerun to
verify reuse of the installed tools. VS Code's GUI build/debug actions have
not been exercised; the ordinary-terminal build path above has been verified.
