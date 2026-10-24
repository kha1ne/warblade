cmake_minimum_required(VERSION 3.25...4.4)

project(warblade VERSION 0.1.0 LANGUAGES CXX)

add_executable(warblade src/main.cpp)
target_compile_features(warblade PRIVATE cxx_std_23)
set_target_properties(warblade PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
    target_compile_options(warblade PRIVATE /W4 /permissive- /utf-8 /Zc:__cplusplus)
else()
    target_compile_options(warblade PRIVATE -Wall -Wextra -Wpedantic)
endif()
