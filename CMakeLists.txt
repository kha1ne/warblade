cmake_minimum_required(VERSION 4.0...4.4)

project(warblade VERSION 0.1.0 LANGUAGES C)

option(WARBLADE_WARNINGS_AS_ERRORS "Treat game compiler warnings as errors" OFF)
option(WARBLADE_ENABLE_IPO "Enable link-time optimization in Release" ON)
option(WARBLADE_ENABLE_ASAN "Instrument project code with MSVC AddressSanitizer" OFF)

find_package(SDL3 CONFIG REQUIRED)
find_package(SDL3_image CONFIG REQUIRED)
find_package(SDL3_mixer CONFIG REQUIRED)
find_package(ZLIB REQUIRED)

file(GLOB_RECURSE WARBLADE_SOURCES CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/src/*.c")
# The report helper is compiled only in the ASan configuration.
list(REMOVE_ITEM WARBLADE_SOURCES "${PROJECT_SOURCE_DIR}/src/core/asan_report.c")
add_executable(warblade ${WARBLADE_SOURCES})
target_include_directories(warblade PRIVATE include)
target_link_libraries(warblade PRIVATE
    SDL3::SDL3 SDL3_image::SDL3_image SDL3_mixer::SDL3_mixer ZLIB::ZLIB
)
if(WIN32)
    set(WARBLADE_ICON_FILE "${CMAKE_CURRENT_SOURCE_DIR}/packaging/warblade.ico")
    configure_file(packaging/warblade.rc.in "${CMAKE_CURRENT_BINARY_DIR}/warblade.rc" @ONLY)
    set_source_files_properties("${CMAKE_CURRENT_BINARY_DIR}/warblade.rc" PROPERTIES
        OBJECT_DEPENDS "${WARBLADE_ICON_FILE}"
    )
    target_sources(warblade PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/warblade.rc")
endif()
set_target_properties(warblade PROPERTIES
    WIN32_EXECUTABLE "$<CONFIG:Release>"
    C_STANDARD 17
    C_STANDARD_REQUIRED YES
    C_EXTENSIONS OFF
    COMPILE_WARNING_AS_ERROR "${WARBLADE_WARNINGS_AS_ERRORS}"
)

add_custom_target(warblade_assets
    COMMAND "${CMAKE_COMMAND}"
            "-DSOURCE=${PROJECT_SOURCE_DIR}/assets"
            "-DDESTINATION=$<TARGET_FILE_DIR:warblade>/assets"
            -P "${PROJECT_SOURCE_DIR}/cmake/StageAssets.cmake"
    COMMENT "Preparing assets beside warblade.exe"
    VERBATIM
)
add_dependencies(warblade warblade_assets)

if(MSVC)
    set_target_properties(warblade PROPERTIES
        MSVC_DEBUG_INFORMATION_FORMAT ProgramDatabase
        MSVC_RUNTIME_CHECKS "$<$<CONFIG:Debug>:StackFrameErrorCheck;UninitializedVariable>"
    )
    target_compile_options(warblade PRIVATE
        /W3 /utf-8 /GS /sdl /fp:precise /diagnostics:column
        "$<$<CONFIG:Release>:/Gy;/Gw;/guard:cf>"
    )
    target_compile_definitions(warblade PRIVATE _CRT_SECURE_NO_WARNINGS)
    target_link_options(warblade PRIVATE
        /DEBUG:FULL
        "$<$<CONFIG:Debug>:/OPT:NOREF;/OPT:NOICF>"
        "$<$<CONFIG:Release>:/OPT:REF;/OPT:ICF;/guard:cf>"
    )
    # CMake supplies /Od /Ob0 and incremental linking for Debug, and
    # /O2 /Ob2 /DNDEBUG and non-incremental linking for Release.
else()
    target_compile_options(warblade PRIVATE -Wall -Wextra -Wpedantic)
endif()

if(WARBLADE_ENABLE_ASAN)
    if(NOT CMAKE_C_COMPILER_ID STREQUAL "MSVC" OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
        message(FATAL_ERROR "The ASan mode currently requires MSVC targeting Windows x64.")
    endif()
    get_filename_component(msvc_bin_dir "${CMAKE_C_COMPILER}" DIRECTORY)
    get_filename_component(msvc_root "${msvc_bin_dir}/../../.." ABSOLUTE)
    file(GLOB asan_runtime_dlls CONFIGURE_DEPENDS "${msvc_bin_dir}/clang_rt.asan*-x86_64.dll")
    if(NOT asan_runtime_dlls OR
       NOT EXISTS "${msvc_root}/lib/x64/clang_rt.asan_dynamic-x86_64.lib")
        message(FATAL_ERROR "MSVC AddressSanitizer is missing from the selected toolset. "
                            "Import cpp-gamedev-buildtools.vsconfig in Visual Studio Installer "
                            "or add the MSVC AddressSanitizer individual component.")
    endif()
    # /RTC and incremental linking are incompatible with AddressSanitizer.
    set_property(TARGET warblade PROPERTY MSVC_RUNTIME_CHECKS "")
    target_sources(warblade PRIVATE src/core/asan_report.c)
    target_compile_definitions(warblade PRIVATE WARBLADE_ENABLE_ASAN=1)
    target_compile_options(warblade PRIVATE /fsanitize=address)
    target_link_options(warblade PRIVATE /INCREMENTAL:NO)
    add_custom_command(TARGET warblade POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                ${asan_runtime_dlls} "$<TARGET_FILE_DIR:warblade>"
        COMMAND_EXPAND_LISTS
        VERBATIM
    )
endif()

if(WARBLADE_ENABLE_IPO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_supported OUTPUT ipo_error LANGUAGES C)
    if(NOT ipo_supported)
        message(FATAL_ERROR "Release IPO is unavailable: ${ipo_error}\n"
                            "Configure with -DWARBLADE_ENABLE_IPO=OFF to disable it.")
    endif()
    set_property(TARGET warblade PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
endif()

if(WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Release" AND NOT WARBLADE_ENABLE_ASAN)
    include(cmake/Packaging.cmake)
endif()
