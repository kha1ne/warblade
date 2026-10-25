# Warblade

A minimal C++ starter for a future Warblade remake. It currently prints:

```text
Hello, Warblade!
```

There is one executable and one source file, plus the original Warblade icon.
No SDL, gameplay assets, test framework, or engine code is included yet.
vcpkg is connected in manifest mode with an empty
dependency list, ready for libraries when needed.

## Requirements

- Windows x64 and Git for Windows.
- Visual Studio Build Tools 2026, including MSVC x64/x86 and a Windows SDK.
  Import `cpp-gamedev-buildtools.vsconfig` into the **Build Tools** installer.
  It also selects **MSVC AddressSanitizer**, required for the `asan` mode.
  The full Visual Studio IDE is unnecessary. Insiders installations are supported.
- Internet access for the first tool setup and configure (vcpkg may fetch helper tools).
- `setup.ps1` also prepares Inno Setup 7.1.0 under `.tools` for installer creation.
  It uses the official compiler's portable mode without registering it globally.

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
| Inno Setup x64 | [7.1.0](https://github.com/jrsoftware/issrc/releases/tag/is-7_1_0) |
| Compiler | Installed MSVC x64 toolset |
| Language | C++23 minimum; MSVC latest draft mode with the pinned CMake |

`setup.ps1` downloads official CMake/Ninja releases and the Inno Setup compiler,
verifies their SHA-256 hashes, then checks out the pinned vcpkg release and runs
its official bootstrap.
It stores everything under ignored `.tools/`; no global tool installation is changed.
Rerunning setup reuses existing tools. vcpkg's bootstrap selects the executable
version recorded by its release; its version date can differ from the registry tag.

The Windows presets use Ninja, separate Debug/ASan/Release build directories, and the
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

## Windows installer

Create an Inno Setup `.exe` installer from an ordinary PowerShell terminal:

```powershell
.\build.bat release package
```

This configures and builds Release, then invokes `cpack --preset release`.
For version 0.1.0 the output is:

```text
dist/Warblade-0.1.0-windows-x64-setup.exe
```

The output directory is ignored by Git. Debug/ASan packaging is rejected. There
are no archive or MSI generators configured. The CMake workflow preset `installer`
also runs configure, build, and package when invoked from an MSVC-initialized
environment. The `build.bat` command initializes that environment automatically.

The installer targets Windows 10+ x64-compatible systems and defaults to
`%LOCALAPPDATA%\Programs\Warblade` without requesting administrator rights. It
creates Start Menu and uninstall entries, offers an optional desktop shortcut,
and remembers the selected installation directory on upgrades. The stable
`AppId` in `cmake/Packaging.cmake` must remain unchanged between releases.
There is no automatic updater; install a newer installer to update the game.

The package includes only files selected by CMake `install()` rules:

- `warblade.exe` and runtime DLLs declared through linked CMake shared-library targets.
- `licenses/warblade.txt` containing this project's license.
- `licenses/warblade-icon.txt` documenting the original icon's origin and license exclusion.
- Contents of `assets/game/`, if present, installed under `data/`.

The starter currently has no gameplay assets or third-party runtime DLLs. When introducing
libraries, add their required license notices and any plugins or dynamically
loaded dependencies not represented in CMake's target graph. PDBs, source code,
Debug/ASan runtimes, `.tools`, and reference assets are excluded. Keep matching
Release PDBs separately for crash diagnosis. Store future saves/settings outside
the installation directory; the installer does not create or remove that data.

`project(... VERSION ...)` in `CMakeLists.txt` controls the installer version,
filename, and Windows executable version metadata. Edit packaging settings in
`cmake/Packaging.cmake`, not the generated `.iss` script under `dist/`.

`packaging/warblade.ico` is the unchanged icon from the original Warblade 1.34
installation. It is embedded in Debug, ASan, and Release executables and the
installer. Start Menu and desktop shortcuts use the installed executable's icon;
the uninstall entry also points to it. No separate runtime `.ico` file is needed.
The icon contains 16x16, 32x32, and 48x48 images. Its provenance and exclusion from
the MIT license are recorded in `packaging/warblade-icon.txt`, which is also shipped
in the installer. Redistribution permission for this original asset has not been
established by this project.

### Optional signing

By default the installer is unsigned for development. No signing certificate or
private key is included. To sign a release, make a real code-signing certificate
and its private key available to Windows SDK SignTool in the current user's
certificate store/provider, then set these environment variables before packaging:

```powershell
$env:WARBLADE_SIGN_CERT_SHA1 = '<40-character certificate thumbprint>'
$env:WARBLADE_SIGN_TIMESTAMP_URL = '<provider RFC 3161 timestamp URL>'
.\build.bat release package
```

Replace both placeholders with your provider's actual values. `/sha1` selects the
certificate by thumbprint; the file and timestamp digests use **SHA-256**.
The build wrapper supplies the Windows SDK SignTool path. CPack signs staged
executables/DLLs that do not already have valid signatures, and Inno Setup signs
the installer and uninstaller. Payload/package signatures are verified, and
signing failures stop packaging. Original build outputs are not modified.

This hook supports certificate-store/provider signing with SignTool. Other cloud
signing integrations may require adapting `cmake/Signing.cmake`. Keep credentials
out of Git; `.pfx`, `.p12`, and `.key` files are ignored. Signing identifies the
publisher but does not guarantee immediate SmartScreen reputation. See
[Microsoft's signing guidance](https://learn.microsoft.com/windows/apps/package-and-deploy/smartscreen-reputation).
Actual trusted signing cannot be verified until a signing identity is configured.

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
| Create installer | **Tasks: Run Task > Package: Windows installer** |
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
build.bat                        Configure, build, run, or package Release
cmake/                           Installer payload, CPack configuration, optional signing
packaging/warblade.rc.in          Windows executable icon and version metadata
packaging/warblade.ico            Original game icon for executable, shortcuts, and installer
packaging/warblade-icon.txt       Original icon provenance and license exclusion
assets/game/                     Future distributable assets (installed as data/)
dist/                            Generated installer and CPack staging (ignored)
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
from it are incorporated into this starter. The original icon was copied from the
installed game and is excluded from this project's MIT license; other original
Warblade game assets are not included. Dependencies retain their own licenses.

## Verification

Debug, ASan, and Release were configured, built, and run on Windows with MSVC
19.52.37025.0, CMake 4.4.4, Ninja 1.13.2, and the pinned vcpkg release. All three
printed `Hello, Warblade!` and exited successfully. The ASan executable also ran
directly outside the MSVC environment. An ignored, deliberately faulty probe
reported `heap-use-after-free` and exited with an error, verifying the sanitizer
runtime detects a real memory error. Setup was also rerun to
verify reuse of the installed tools. VS Code's GUI build/debug actions have
not been exercised; the ordinary-terminal build path above has been verified.

The unsigned Inno Setup installer was built and installed into an isolated test
directory. Its installed executable, license, Start Menu shortcut, and uninstall
registration were checked. A test 0.1.1 installer upgraded the 0.1.0 installation
without being given the previous directory. Uninstallation removed the registered
files/shortcuts and preserved a user-created file. The test registration was cleaned
up. Debug/ASan builds still ran successfully after packaging was added.

All four original icon images were verified byte-for-byte in the Debug, ASan,
Release, and installer executable resources. A fresh isolated installation verified
the installed executable's icon, Start Menu shortcut target, uninstall display
icon, and installed icon provenance notice. The test installation and shortcuts
were removed afterward. The generated installer script also points the optional
desktop shortcut to the same executable.

Debug packaging was rejected. A requested signing run with a nonexistent certificate
failed during staging before installer compilation. Successful trusted signing is
not tested because no code-signing identity has been configured.
