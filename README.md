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
  It also selects **MSVC AddressSanitizer**, required for the `asan` mode.
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

For memory-error detection:

```powershell
.\build.bat asan run
```

Omit `run` to build only. You can also run an existing executable directly:

```powershell
.\build\debug\warblade.exe
.\build\release\warblade.exe
.\build\asan\warblade.exe
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
| Language | C++23 minimum; MSVC latest draft mode with the pinned CMake |

`setup.ps1` downloads official portable CMake/Ninja releases and verifies SHA-256
hashes, then checks out the pinned vcpkg release and runs its official bootstrap.
It stores everything under ignored `.tools/`; no global tool installation is changed.
Rerunning setup reuses existing tools. vcpkg's bootstrap selects the executable
version recorded by its release; its version date can differ from the registry tag.

The Windows presets use Ninja, separate Debug/Release build directories, and the
`x64-windows-static` vcpkg triplet with the matching static MSVC runtime.

## Compiler and build modes

The pinned CMake maps C++23 to MSVC's `/std:c++latest`. The standard is required;
it cannot silently fall back to an older mode. This enables the compiler's
implemented C++23 and later draft features; it does not imply complete C++26
support. Draft features can change with compiler updates. See Microsoft's
[/std documentation](https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version).

| Setting | Debug | ASan | Release |
| --- | --- | --- | --- |
| Optimization | `/Od /Ob0`, no IPO | `/Od /Ob0`, no IPO | `/O2 /Ob2`, IPO (`/GL` + `/LTCG`) |
| Assertions | Enabled | Enabled | Disabled by `NDEBUG` |
| Runtime checks | `/RTC1`, debug CRT/STL checks | `/fsanitize=address`, no `/RTC`; debug CRT/STL checks | No `/RTC` or ASan |
| MSVC runtime | Static debug `/MTd` | Static debug `/MTd`, plus ASan DLL | Static release `/MT` |
| Symbols | `/Zi` + `/DEBUG:FULL` PDB | `/Zi` + `/DEBUG:FULL` PDB | `/Zi` + `/DEBUG:FULL` PDB |
| Linking | Incremental; retain separate functions/data for debugging | Non-incremental; retain separate functions/data | Non-incremental; `/OPT:REF /OPT:ICF` |
| Control Flow Guard | Off | Off | `/guard:cf` at compile and link time |

All modes use `/W4`, warnings as errors, `/permissive-`, `/Zc:preprocessor`,
`/Zc:__cplusplus`, UTF-8 source handling, `/GS`, `/sdl`, and `/fp:precise`.
`/sdl` is Microsoft's security-check flag, unrelated to the SDL game library.
CMake supplies the standard optimization, exception-handling, assertion, and
incremental-linking defaults; project options add checks and Release optimizations
without replacing global compiler flags. Warnings-as-errors and IPO apply to this
project target, not all third-party library targets.

Release keeps a PDB for diagnosing crashes while still optimizing the executable.
Identical functions may be folded and variables optimized away, so use Debug for
normal stepping. The PDB does not need to be shipped to players. Fast-math and
CPU-specific instruction-set requirements are not enabled; Ninja handles parallel
compilation without `/MP`.

`WARBLADE_WARNINGS_AS_ERRORS` and `WARBLADE_ENABLE_IPO` default to `ON` and can be
changed in an ignored `CMakeUserPresets.json` or with CMake `-D` options. CMake
checks compiler IPO support before enabling it. These settings require CMake 4.0+
for its runtime-check abstraction; the setup script supplies 4.4.4.

For comparison, [WarbladeSR's SDL branch](https://github.com/bbepis/WarbladeSR/blob/sdl/CMakeLists.txt)
at commit `215a2da` uses **C17**, `/W3`, the same static runtime approach, and
standard CMake Debug/Release defaults. It also has an optional AddressSanitizer
mode that removes incompatible `/RTC` flags. Its legacy warning suppression and
entry-point override are specific to that port and are unnecessary here.

### AddressSanitizer

The `asan` preset uses the Debug build type in its own `build/asan/` directory and
enables `WARBLADE_ENABLE_ASAN`. It detects exercised memory errors such as buffer
overruns, use-after-free, and double deletion. It adds runtime/memory overhead and
is intended for development rather than the shipped game. Project sources are
instrumented; third-party vcpkg dependencies are not automatically instrumented.

For an existing Build Tools installation, import the updated `.vsconfig` or use
**Modify > Individual components > MSVC AddressSanitizer**. `setup.ps1` needs no
additional download: the sanitizer compiler libraries and runtime come from
Visual Studio Installer. `build.bat asan` selects an installation with the ASan
component, and CMake checks the selected toolset's libraries and DLLs.

MSVC's ASan runtime is a DLL even with `/MTd`. The build copies its matching DLLs
beside `warblade.exe`, so direct runs and VS Code debugging do not depend on a
developer terminal's PATH. The ASan flags disable incompatible `/RTC` checks and
incremental linking without changing the ordinary Debug preset. See Microsoft's
[ASan build reference](https://learn.microsoft.com/en-us/cpp/sanitizers/asan-building)
and [runtime documentation](https://learn.microsoft.com/en-us/cpp/sanitizers/asan-runtime).

## VS Code

Open this folder in VS Code. `.vscode/extensions.json` recommends:

- **C/C++** (`ms-vscode.cpptools`): IntelliSense, formatting, and the MSVC debugger.
- **CMake Tools** (`ms-vscode.cmake-tools`): CMake presets, targets, and IntelliSense configuration.

Open Extensions (`Ctrl+Shift+X`) and search `@recommended` to install them.
On a fresh checkout, run **Tasks: Run Task > Setup: Build tools** once; the task
uses a process-only PowerShell execution-policy bypass.

| Action | Command / shortcut |
| --- | --- |
| Build Debug | `Ctrl+Shift+B` (default build task) |
| Build Release | **Tasks: Run Task > Build: Release** |
| Build ASan | **Tasks: Run Task > Build: ASan** |
| Build and run | **Tasks: Run Task > Run: Debug**, **Run: ASan**, or **Run: Release** |
| Debug | Select **Warblade (Debug)** in Run and Debug, set a breakpoint, press `F5` |
| Debug with ASan | Select **Warblade (ASan)** in Run and Debug and press `F5` |
| Run without debugging | Select a launch configuration and press `Ctrl+F5` |

Launch configurations build their matching target first and use the integrated
terminal. Release has symbols but is optimized; use Debug for reliable stepping and breakpoints.
Build tasks call `build.bat`, which initializes MSVC without a developer terminal.

For CMake Tools and IntelliSense, use **CMake: Select Configure Preset** to select
`debug`, `asan`, or `release`, then **CMake: Configure**. The presets declare the external
x64 architecture so CMake Tools can initialize MSVC. Include paths and compiler
options come from CMake; no separate `c_cpp_properties.json` is needed.

## Layout

```text
src/main.cpp                     Hello World executable
CMakeLists.txt                   Target, C++ standard, and compiler warnings
CMakePresets.json                Ninja + vcpkg Debug/ASan/Release configuration
vcpkg.json                       Pinned dependency baseline; currently no packages
setup.ps1                        One-time local tool download
build.bat                        Configure, build, and optionally run
cpp-gamedev-buildtools.vsconfig   Minimal Microsoft Build Tools component selection
.vscode/                         Extension recommendations, build/run tasks, and debugger settings
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

Debug, ASan, and Release were configured, built, and run on Windows with MSVC
19.52.37025.0, CMake 4.4.4, Ninja 1.13.2, and the pinned vcpkg release. All three
printed `Hello, Warblade!` and exited successfully. The ASan executable also ran
directly outside the MSVC environment. An ignored, deliberately faulty probe
reported `heap-use-after-free` and exited with an error, verifying the sanitizer
runtime detects a real memory error. Setup was also rerun to
verify reuse of the installed tools. VS Code's GUI build/debug actions have
not been exercised; the ordinary-terminal build path above has been verified.
