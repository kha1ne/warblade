# Based on the pinned vcpkg port; changes add dr_mp3 and preserve bundled codec notices.
# Copyright (c) Microsoft Corporation. Licensed under ../LICENSE.txt.
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libsdl-org/SDL_mixer
    REF "release-${VERSION}"
    HEAD_REF main
    SHA512 f173ff0346c1645f665fc17c78021b0487fcb2742a6228663872afc0ff926c1f19e3e3c150f352020b7523bb5de924390980dd8978c4b223cde83a16048f0d2d
    PATCHES
        fluidsynth.diff
)
file(WRITE "${SOURCE_PATH}/cmake/FindFluidSynth.cmake" "# disabled by vcpkg\n")

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        fluidsynth  SDLMIXER_MIDI
        fluidsynth  SDLMIXER_MIDI_FLUIDSYNTH
        libflac     SDLMIXER_FLAC
        libflac     SDLMIXER_FLAC_LIBFLAC
        drmp3       SDLMIXER_MP3_DRMP3
        libxmp      SDLMIXER_MOD
        libxmp      SDLMIXER_MOD_XMP
        mpg123      SDLMIXER_MP3_MPG123
        opusfile    SDLMIXER_OPUS
        libvorbis   SDLMIXER_VORBIS_VORBISFILE
        wavpack     SDLMIXER_WAVPACK
)

if("drmp3" IN_LIST FEATURES OR "mpg123" IN_LIST FEATURES)
    list(APPEND FEATURE_OPTIONS -DSDLMIXER_MP3=ON)
else()
    list(APPEND FEATURE_OPTIONS -DSDLMIXER_MP3=OFF)
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        ${EXTRA_OPTIONS}
        -DSDLMIXER_STRICT=ON
        -DSDLMIXER_TESTS=OFF
        -DSDLMIXER_VENDORED=OFF
        -DSDLMIXER_DEPS_SHARED=OFF
        -DSDLMIXER_OPUS_SHARED=OFF
        -DSDLMIXER_VORBIS_VORBISFILE_SHARED=OFF
        -DSDLMIXER_FLAC_DRFLAC=OFF
        -DSDLMIXER_MIDI_TIMIDITY=OFF
        -DSDLMIXER_VORBIS_STB=ON
        -DSDLMIXER_EXAMPLES=OFF
        -DSDLMIXER_GME=OFF
        -DSDLMIXER_MOD_XMP_SHARED=${BUILD_SHARED}
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    vcpkg_cmake_config_fixup(PACKAGE_NAME "SDL3_mixer" CONFIG_PATH "cmake")
else()
    vcpkg_cmake_config_fixup(PACKAGE_NAME "SDL3_mixer" CONFIG_PATH "lib/cmake/SDL3_mixer")
endif()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/licenses")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
# Keep the bundled decoders' license blocks without shipping their entire headers.
set(codec_notices)
foreach(codec IN ITEMS dr_libs/dr_mp3.h stb_vorbis/stb_vorbis.h)
    file(READ "${SOURCE_PATH}/src/${codec}" codec_source)
    string(FIND "${codec_source}" "This software is available" license_start REVERSE)
    if(license_start LESS 0)
        message(FATAL_ERROR "Cannot locate the bundled codec license: ${codec}")
    endif()
    string(SUBSTRING "${codec_source}" ${license_start} -1 codec_license)
    get_filename_component(codec_name "${codec}" NAME_WE)
    set(notice "${CURRENT_BUILDTREES_DIR}/${codec_name}-license.txt")
    file(WRITE "${notice}" "${codec_license}")
    list(APPEND codec_notices "${notice}")
endforeach()
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt" ${codec_notices})
