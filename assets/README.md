# Game assets

Place distributable game assets in `assets/game/`. Release installers copy its
contents into the installed `data/` directory while preserving subdirectories.
There are no game assets in the starter yet. This README is not installed.

Keep original reference assets under ignored `assets/original/` if needed.
Only add assets you intend to distribute to `assets/game/`. Include any required
asset attribution/license files there. Add third-party library notices to the
CMake install rules when dependencies are introduced.

Saves, profiles, and settings belong in a separate per-user application-data
directory, not in this source folder or the installed `data/` directory.
