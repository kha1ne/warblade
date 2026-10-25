# Warblade

WarbladeSR's SDL game implementation integrated into a C17 CMake/Ninja/vcpkg
project. All 52 C source files and six headers from its `sdl` branch are retained
under `src/` and `include/`. The C entry point in `src/core/main.c` starts the
game and configures ASan reporting when enabled. There is no C++ application
target or separate game library.

Startup, the game loop, and shutdown run directly in `main`; there is no separate
`GameMain` wrapper. The program returns zero on success and a nonzero exit code
if initialization fails. This is a self-contained derivative of WarbladeSR's SDL
port, with the integrations and fixes described below; no further source
migration is required.

The original Warblade icon and unpacked graphics, music, sound effects, voice
packs, and game data are included. SDL3, SDL3_image, SDL3_mixer, and zlib are
configured and linked through vcpkg. Building and running require no original
Warblade installation, PAC archive, extraction step, or importer.

## Requirements

- Windows x64 and Git for Windows.
- Visual Studio Build Tools 2026, including MSVC x64/x86 and a Windows SDK.
  Import `cpp-gamedev-buildtools.vsconfig` into the **Build Tools** installer.
  It also selects **MSVC AddressSanitizer**, required for the `asan` mode.
  The full Visual Studio IDE is unnecessary. Insiders installations are supported.
- Internet access for the first tool setup and configure (vcpkg may fetch helper tools).
- `setup.ps1` also prepares Inno Setup 7.1.0 under `.tools` for installer creation.
  It uses the official compiler's portable mode without registering it globally.

Use the standalone Build Tools product. The official Insiders bootstrapper is
[vs_BuildTools.exe](https://aka.ms/vs/18/insiders/vs_BuildTools.exe). From Command
Prompt in this project directory, use the bootstrapper's full path if needed:

```bat
vs_BuildTools.exe --config "%CD%\cpp-gamedev-buildtools.vsconfig"
```

The configuration selects MSVC x64/x86, AddressSanitizer, one Windows SDK, CMake/
Ninja, and vcpkg. Required dependencies are added automatically; additional
workloads and the full Visual Studio IDE are unnecessary. The first build installs
the libraries declared in `vcpkg.json`. Inno Setup is prepared by `setup.ps1`, not
by a Visual Studio component.

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
The first configure downloads and builds the libraries in `vcpkg.json`, including
Debug and Release variants. Later builds reuse them and vcpkg's binary cache.

Each build prepares an `assets/` directory junction beside its executable, pointing
to the repository's assets. Asset edits appear immediately without duplicate
copies. The build wrapper and VS Code run/debug actions use the executable's
directory as their working directory. Installed games receive real asset files.

Release uses CMake's Windows GUI subsystem and SDL3's `SDL_main.h` entry point,
so launching it from Explorer does not open a terminal. Debug and ASan retain
their consoles. All three modes launch the imported game.

Settings, profiles, high scores, screenshots, playlists, and `warblade.dbg` use
SDL's per-user preference directory: `%APPDATA%\kha1ne\warblade` on Windows.
The original game's `Documents\warblade` directory is not used or imported.
For an isolated development run, set `WARBLADE_USER_DIR` to an absolute writable
directory before launching. Uninstalling leaves user data intact.

## Tool versions

Latest stable releases checked on **2026-10-25**, pinned for reproducible setup:

| Tool | Version |
| --- | --- |
| CMake | [4.4.4](https://github.com/Kitware/CMake/releases/tag/v4.4.4) |
| Ninja | [1.13.2](https://github.com/ninja-build/ninja/releases/tag/v1.13.2) |
| vcpkg registry/scripts | [2026.10.16](https://github.com/microsoft/vcpkg/releases/tag/2026.10.16) |
| Inno Setup x64 | [7.1.0](https://github.com/jrsoftware/issrc/releases/tag/is-7_1_0) |
| Compiler | Installed MSVC x64 toolset |
| Language | C17, required for all application sources |

`setup.ps1` downloads official CMake/Ninja releases and the Inno Setup compiler,
verifies their SHA-256 hashes, then checks out the pinned vcpkg release and runs
its official bootstrap.
It stores everything under ignored `.tools/`; no global tool installation is changed.
Rerunning setup reuses existing tools. vcpkg's bootstrap selects the executable
version recorded by its release; its version date can differ from the registry tag.

The Windows presets use Ninja, separate Debug/ASan/Release build directories, and the
`x64-windows-static` vcpkg triplet with the matching static MSVC runtime.

## Compiler and build modes

The application uses C17 (`/std:c17` with MSVC). CMake requires that standard
and disables language extensions; no C++ standard or draft mode is selected.
See Microsoft's
[/std documentation](https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version).

| Setting | Debug | ASan | Release |
| --- | --- | --- | --- |
| Optimization | `/Od /Ob0`, no IPO | `/Od /Ob0`, no IPO | `/O2 /Ob2`, IPO (`/GL` + `/LTCG`) |
| Assertions | Enabled | Enabled | Disabled by `NDEBUG` |
| Runtime checks | `/RTC1`, debug CRT checks | `/fsanitize=address`, no `/RTC`; debug CRT checks | No `/RTC` or ASan |
| MSVC runtime | Static debug `/MTd` | Static debug `/MTd`, plus ASan DLL | Static release `/MT` |
| Symbols | `/Zi` + `/DEBUG:FULL` PDB | `/Zi` + `/DEBUG:FULL` PDB | `/Zi` + `/DEBUG:FULL` PDB |
| Linking | Incremental; retain separate functions/data for debugging | Non-incremental; retain separate functions/data | Non-incremental; `/OPT:REF /OPT:ICF` |
| Control Flow Guard | Off | Off | `/guard:cf` at compile and link time |
| Windows subsystem | Console | Console | GUI, without an accompanying console |

The single `warblade` C17 executable uses `/W3` without warnings as errors by
default; existing conversion and format warnings remain visible. All modes use
UTF-8 source handling, `/GS`, `/sdl`, `/fp:precise`, and the optimization/runtime
settings above.
`/sdl` is Microsoft's security-check flag, unrelated to the SDL game library.
CMake supplies the standard optimization, assertion, and
incremental-linking defaults; project options add checks and Release optimizations
without replacing global compiler flags. Release IPO applies to the application,
not dependency targets.

Release keeps a PDB for diagnosing crashes while still optimizing the executable.
Identical functions may be folded and variables optimized away, so use Debug for
normal stepping. The PDB does not need to be shipped to players. Fast-math and
CPU-specific instruction-set requirements are not enabled; Ninja handles parallel
compilation without `/MP`.

`WARBLADE_WARNINGS_AS_ERRORS` defaults to `OFF` (also set by the shared preset),
and `WARBLADE_ENABLE_IPO` defaults to `ON`. Change them in an ignored
`CMakeUserPresets.json` or with CMake `-D` options. CMake
checks compiler IPO support before enabling it. These settings require CMake 4.0+
for its runtime-check abstraction; the setup script supplies 4.4.4.

For comparison, [WarbladeSR's SDL branch](https://github.com/bbepis/WarbladeSR/blob/sdl/CMakeLists.txt)
at commit `215a2da` uses **C17**, `/W3`, the same static runtime approach, and
standard CMake Debug/Release defaults. Our application keeps that language and
warning level. Its C `main` function uses SDL's platform entry point instead of
WarbladeSR's linker entry alias. Our ASan preset disables incompatible runtime
checks using CMake's target property.

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

On startup, the ASan build clears `asan.txt` beside its executable. ASan error
reports raised after application startup are copied into that file while retaining
the normal terminal/debugger output. This works for direct launches, `build.bat
asan run`, and VS Code debugging; the path does not depend on the working
directory. A clean run leaves an empty file. Runtime startup/load failures before
the application installs its report callback remain in the terminal/debugger.

The report callback lives in `src/core/asan_report.c`, with its declaration in
`include/asan_report.h`; both are C17. This helper was added here to save
`asan.txt`. WarbladeSR has no equivalent report helper: its CMake file enables
ASan and stages its runtime DLLs, leaving diagnostics to the normal ASan output.

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
- `licenses/third-party/<package>/copyright.txt` for the bundled libraries and codecs.
- All files under `assets/`, installed beside `warblade.exe` as `assets/` with the
  same subdirectories and filenames.

The game includes 946 asset files. The libraries use static linking, so Release
does not require SDL or codec DLLs. When introducing libraries, add their required
license notices and any plugins or dynamically loaded dependencies not represented
in CMake's target graph. PDBs, source code,
Debug/ASan runtimes and `.tools` are excluded. Keep matching
Release PDBs separately for crash diagnosis. Saves/settings live in the per-user
directory described above; the installer does not create or remove that data.

`project(... VERSION ...)` in `CMakeLists.txt` controls the installer version,
filename, and Windows executable version metadata. Edit packaging settings in
`cmake/Packaging.cmake`, not the generated `.iss` script under `dist/`.

`packaging/warblade.ico` is the included original Warblade 1.34 icon. It is embedded
in Debug, ASan, and Release executables and the
installer. Start Menu and desktop shortcuts use the installed executable's icon;
the uninstall entry also points to it. No separate runtime `.ico` file is needed.
The icon contains 16x16, 32x32, and 48x48 images. Original media ownership and
exclusion from the source-code MIT license are documented below.

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

Launch configurations build their matching target first and run from its output
directory. Debug and ASan retain console output; Release has no accompanying
console. Release has symbols but is optimized; use Debug for reliable stepping and breakpoints.
Build tasks call `build.bat`, which initializes MSVC without a developer terminal.

For CMake Tools and IntelliSense, use **CMake: Select Configure Preset** to select
`debug`, `asan`, or `release`, then **CMake: Configure**. The presets declare the external
x64 architecture so CMake Tools can initialize MSVC. Include paths and compiler
options come from CMake; no separate `c_cpp_properties.json` is needed.

## Layout

```text
include/                         Game headers and ASan helper declaration
src/core/main.c                  C SDL entry point, startup, and main loop
src/core/asan_report.c           ASan-only report file callback
src/core/                        SDL adapters, files, and platform helpers
src/audio/                       Music, samples, and voice playback
src/data/                        Global state and initialization tables
src/game/                        Game logic and special stages
src/gfx/                         Graphics, rendering, text, and effects
src/profile/                     Settings, profiles, saves, and high scores
src/ui/                          Menus, title screens, and controls
CMakeLists.txt                   Single C17 executable and build flags
CMakePresets.json                Ninja + vcpkg Debug/ASan/Release configuration
vcpkg.json                       Pinned SDL/image/audio/compression dependencies
vcpkg-ports/                     SDL subsystem trimming and bundled MP3 decoder overlays
setup.ps1                        One-time local tool download
build.bat                        Configure, build, run, or package Release
cmake/                           Asset staging, installer configuration, optional signing
packaging/warblade.rc.in          Windows executable icon and version metadata
packaging/warblade.ico            Original game icon for executable, shortcuts, and installer
assets/audio/                    Music, sound effects, voices, and voice metadata
assets/graphics/                 TGA, JPG, and PNG images
assets/data/                     Hit masks, levels, and attack patterns
dist/                            Generated installer and CPack staging (ignored)
cpp-gamedev-buildtools.vsconfig   Minimal Microsoft Build Tools component selection
.vscode/                         Extension recommendations, build/run tasks, and debugger settings
LICENSE                          License scope and MIT terms for independent project code
```

## Assets

All 946 files under `assets/` are part of the repository and Release installer.
The installed layout matches the repository: `warblade.exe` sits beside `assets/`.
Paths are relative to the project or installation directory; no asset manifest,
importer, or original game installation is required.

| Content | Relative path | Files |
| --- | --- | --- |
| Images: TGA, JPG, PNG | `assets/graphics/` | 407 |
| Music: MP3 and tracker modules (`.mus`) | `assets/audio/music/` | 25 |
| Sound effects: MP3 | `assets/audio/sound-effects/` | 112 |
| Voice audio: MP3 and OGG | `assets/audio/voices/` | 139 |
| Voice-pack metadata (`.id`) | `assets/audio/voices/*/metadata/` | 3 |
| Collision masks (`.hma`), levels (`.lvd`), attack patterns (`.swd`) | `assets/data/` | 260 |

Files retain their original names and bytes; Git treats them as binary to prevent
line-ending changes. The voice packs remain separate under `pack-1/` and `pack-2/`,
with their corresponding metadata. The imported game loads these sorted loose
files relative to the executable, independent of the current working directory.
Its old `PacExists`/`PacRead` interfaces are compatibility names for loose-file
loading; the archive indexer is removed. Sample and music paths use the audio
subdirectories above. The Jukebox menu action opens the bundled MP3 directory
instead of requiring the original separate Jukebox executable.

The imported game retains its original gameplay, menus, renderer options, input,
profiles, and save formats. Existing SR stubs for discontinued online services
remain stubs. Importing the code does not turn those services into working ones.

## Libraries

The dependency set follows WarbladeSR's SDL branch. The pinned registry supplies
newer SDL core than that checkout (3.4.18 versus 3.4.16), while keeping the same
image and audio feature coverage:

| Library | Pinned version | Purpose |
| --- | --- | --- |
| SDL3 | 3.4.18 | Windows, rendering, input/controllers, audio, and Vulkan support |
| SDL3_image | 3.4.8 | TGA, PNG, and JPEG images |
| SDL3_mixer | 3.2.4 | Audio loading, mixing, and playback |
| libxmp | 4.7.3 | Tracker music stored as `.mus` |
| zlib | 1.3.2 | Compression/decompression |
| libpng | 1.6.59 | PNG codec used through SDL3_image |
| libjpeg-turbo | 3.2.0 | JPEG codec used through SDL3_image |
| libspng | 0.7.4 | Transitive dependency of the pinned libjpeg-turbo port |

SDL_mixer uses its bundled **dr_mp3** for MP3 and **stb_vorbis** for OGG Vorbis;
they are built into SDL_mixer rather than installed as separate packages.
`vcpkg-ports/sdl3-mixer/` enables dr_mp3, which the registry port disables by
default. It keeps bundled stb_vorbis enabled, uses libxmp for tracker music, and
preserves the bundled codec notices in the installed copyright file.

`vcpkg-ports/sdl3/` builds SDL 3.4.18 with WarbladeSR's ten subsystem exclusions:
GPU API, GPU renderer, camera, haptics, power information, sensors, native dialogs,
tray support, OpenGL ES, and HIDAPI are all disabled. Direct3D, desktop OpenGL,
Vulkan, and generic joystick/XInput support remain available. The disabled GPU
API is separate from the hardware-accelerated renderer backends. This profile
does not include HIDAPI-specific controller drivers or the haptic API.

Both overlays adapt the official ports from the pinned vcpkg 2026.10.16 registry
and retain Microsoft's MIT notice in `vcpkg-ports/LICENSE.txt`. The project manifest
selects them through a relative overlay path. SDL3_image uses the unmodified
registry port. No WarbladeSR checkout is needed to build the project. When updating
the baseline, review both recipes against the new official ports, retaining source
checksums, applicable patches, and copyright notices.

CMake finds and links `SDL3::SDL3`, `SDL3_image::SDL3_image`,
`SDL3_mixer::SDL3_mixer`, and `ZLIB::ZLIB` to `warblade`. Image/audio codec
dependencies are linked transitively. All modes use `x64-windows-static` with
the matching MSVC runtime. Third-party libraries are not automatically ASan
instrumented. The existing build/run/package tasks need no additional commands,
and no new Build Tools components are required.

### Adding dependencies

Add packages to `dependencies` in `vcpkg.json`, then use `find_package()` and
`target_link_libraries()` in `CMakeLists.txt`. The next configure installs them.
The baseline pins the dependency registry; it does not automatically follow newer
package releases. When updating it, review both SDL overlays and the installer
license list as well.

## Repository and references

Remote: <https://github.com/kha1ne/warblade>.

Reviewed the local `CppApp` and `cpp-project` examples and these
references for structure and tooling. Build integration and the ASan report helper
were written independently; the C game implementation is imported from WarbladeSR:

- [bsamseth/cpp-project](https://github.com/bsamseth/cpp-project)
- [C++ Best Practices CMake template](https://github.com/cpp-best-practices/cmake_template)
- [Microsoft's CMake/vcpkg quick start](https://learn.microsoft.com/en-us/vcpkg/get_started/get-started)
- [CMake presets](https://cmake.org/cmake/help/v4.4/manual/cmake-presets.7.html)
- [WarbladeSR SDL branch](https://github.com/bbepis/WarbladeSR/tree/sdl)

The game files under `src/` and `include/` were imported from the `sdl` branch at commit
`215a2da173785d368e247b3928ccfb73073286bf`. All six headers and 52 C files are
included, with adaptations for the C SDL entry point, loose assets, embedded icon,
per-user data paths, explicit initialization of player-effect locals required
by our security checks, and an 800-entry audio pan table. The original table
held only 319 entries although startup writes 800; this corrupted a scratch-buffer
pointer and crashed Release shutdown with IPO. Module directories were preserved.
Headers live in root `include/`, and the module directories live directly under
`src/`, matching the upstream layout. The ASan report helper is our addition.

The referenced SDL revision contains no standalone media assets. No reference
checkout is kept in this project or needed to build it. The original media
included here came from Warblade 1.34 by Edgar M. Vigdal / EMV
Software. Graphics and game data were unpacked from its archive; music, effects,
and voice packs were copied without conversion. The original Lila voice-pack
readme credits its samples to Simon Quincey.

The MIT license applies to independently written build integration and the ASan
report helper (`src/core/asan_report.c` and `include/asan_report.h`);
adapted vcpkg port files retain the Microsoft notice in `vcpkg-ports/LICENSE.txt`.
It does not cover WarbladeSR-derived game files under `src/` and `include/`,
`assets/`, or `packaging/warblade.ico`.
The inspected WarbladeSR revision has no standalone license granting reuse of its
game sources. Imported code and original media retain their owners' rights and
restrictions; this project has not established permission to redistribute them.
Dependencies retain their own licenses; their copyright notices are included in
the installer. The packaged project license states these scope exclusions.

## Verification

The C17 application builds in Debug, ASan, and Release with MSVC 19.52.37025.0,
CMake 4.4.4, Ninja 1.13.2, and the pinned vcpkg release. Startup/shutdown checks
use isolated user-data directories and muted audio. ASan reached level 1 with
enemies rendered, saved an in-game screenshot, and exited with code 0 and an
empty `asan.txt`. Release shutdown also passed with IPO enabled after fixing the
audio pan-table overrun. These checks do not establish that every level, menu,
save path, or controller works. The imported code still has compiler warnings
and requires gameplay testing.

Compile commands confirm C17 for all application translation units and no C++
sources in any mode. PE headers confirm that Debug/ASan use the console subsystem
and Release uses the Windows GUI subsystem.

All three development asset junctions were checked against the repository's 946
files. Additions, edits, and removals appear immediately. Staging also worked with
spaces in paths and rejected an unrelated existing directory without altering it.

An ignored C17 probe compiled with the production ASan report helper detected a real
heap-use-after-free, exited unsuccessfully, and saved the diagnostic to `asan.txt`
beside the probe executable. Clean direct launches and stale-log clearing passed.
No faulty probe code is part of the game or installer.

The C17 game installer was generated successfully. Its staged Release executable
opened the game window and exited with code 0. It matches
the corrected Release build, and all 946 packaged assets match the repository by
SHA-256; eight dependency notices and the scoped project license are included.

Before the game-source migration, the unsigned installer was installed into an
isolated directory. Its GUI executable ran successfully; all 946 real asset files
matched by SHA-256, eight
dependency notices and the shortcut were checked, and the removed media notice
and ASan log were absent. Uninstallation removed the test assets, registration,
and shortcuts. Earlier checks covered icon resources and version upgrades.

Dependency smoke checks loaded all 407 images and 276 audio files, generated an
audio buffer for each, and passed a zlib compression/decompression round-trip.
The ten trimmed SDL options were verified OFF in both SDL configurations;
Direct3D, desktop OpenGL, Vulkan, and generic joystick/XInput remained enabled.

During the first dependency build, MSVC Insiders intermittently reported internal
compiler errors. Retrying with `$env:VCPKG_MAX_CONCURRENCY = '8'` succeeded without
changing optimization flags. VS Code GUI build/debug actions and successful
trusted signing have not been exercised. Debug packaging and a signing attempt
with a nonexistent certificate were correctly rejected in earlier checks.
