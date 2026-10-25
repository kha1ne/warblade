cmake_minimum_required(VERSION 4.0...4.4)

project(warblade VERSION 0.1.0 LANGUAGES CXX)

option(WARBLADE_WARNINGS_AS_ERRORS "Treat warnings in project code as errors" ON)
option(WARBLADE_ENABLE_IPO "Enable link-time optimization in Release" ON)
option(WARBLADE_ENABLE_ASAN "Instrument project code with MSVC AddressSanitizer" OFF)

add_executable(warblade src/main.cpp)
if(WIN32)
    configure_file(packaging/warblade.rc.in "${CMAKE_CURRENT_BINARY_DIR}/warblade.rc" @ONLY)
    target_sources(warblade PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/warblade.rc")
endif()
# With the pinned CMake 4.4/MSVC toolchain, C++23 selects /std:c++latest.
# This enables implemented draft features, not complete C++26 conformance.
target_compile_features(warblade PRIVATE cxx_std_23)
set_target_properties(warblade PROPERTIES
    CXX_STANDARD 23
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS OFF
    COMPILE_WARNING_AS_ERROR "${WARBLADE_WARNINGS_AS_ERRORS}"
)

if(MSVC)
    set_target_properties(warblade PROPERTIES
        MSVC_DEBUG_INFORMATION_FORMAT ProgramDatabase
        MSVC_RUNTIME_CHECKS "$<$<CONFIG:Debug>:StackFrameErrorCheck;UninitializedVariable>"
    )
    target_compile_options(warblade PRIVATE
        /W4 /permissive- /utf-8 /Zc:__cplusplus /Zc:preprocessor
        /GS /sdl /fp:precise /diagnostics:column
        "$<$<CONFIG:Release>:/Gy;/Gw;/guard:cf>"
    )
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
    if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
        message(FATAL_ERROR "The ASan mode currently requires MSVC targeting Windows x64.")
    endif()
    get_filename_component(msvc_bin_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
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
    check_ipo_supported(RESULT ipo_supported OUTPUT ipo_error LANGUAGES CXX)
    if(NOT ipo_supported)
        message(FATAL_ERROR "Release IPO is unavailable: ${ipo_error}\n"
                            "Configure with -DWARBLADE_ENABLE_IPO=OFF to disable it.")
    endif()
    set_property(TARGET warblade PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
endif()

if(WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Release" AND NOT WARBLADE_ENABLE_ASAN)
    include(cmake/Packaging.cmake)
endif()
