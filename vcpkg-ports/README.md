# vcpkg overlays

`sdl3-mixer/` adapts the official vcpkg 2026.10.16 port for SDL_mixer 3.2.4.
The copied port files retain Microsoft's MIT license in `LICENSE.txt`.

Changes enable SDL_mixer's bundled dr_mp3 through the `drmp3` feature and keep
bundled stb_vorbis enabled for OGG. `libxmp` handles tracker music. This provides
the audio formats used by the included assets without adding another MP3 library.
Bundled codec notices are included in the installed copyright file.

`sdl3/` adapts the official SDL 3.4.18 port using the same ten subsystem exclusions
as WarbladeSR: GPU API, GPU renderer, camera, haptics, power information, sensors,
native dialogs, tray support, OpenGL ES, and HIDAPI. Direct3D, desktop OpenGL,
Vulkan, and generic joystick/XInput support remain available. Disabling the GPU
API does not disable the other hardware-accelerated renderer backends. Dedicated
HIDAPI controller drivers and the haptic API are not included in this profile.

The project manifest selects both overlays using a relative path. SDL3_image uses
the unmodified port from the pinned registry. Review both overlays against their
official ports when updating the vcpkg baseline, retaining source checksums,
applicable patches, and Microsoft's MIT notice in `LICENSE.txt`.
