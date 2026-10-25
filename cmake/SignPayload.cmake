include("${CMAKE_CURRENT_LIST_DIR}/Signing.cmake")
warblade_sign_command(sign_command)
if(NOT sign_command)
    return()
endif()
list(GET sign_command 0 sign_tool)
set(payload_root "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}")
if(NOT EXISTS "${payload_root}/warblade.exe")
    message(FATAL_ERROR "The staged Warblade executable was not found for signing.")
endif()
file(GLOB_RECURSE payload_binaries "${payload_root}/*.exe"
                                 "${payload_root}/*.dll")
foreach(binary IN LISTS payload_binaries)
    # Preserve a valid signature already supplied by a third-party library.
    execute_process(COMMAND "${sign_tool}" verify /pa /q "${binary}"
                    RESULT_VARIABLE verified OUTPUT_QUIET ERROR_QUIET)
    if(NOT verified EQUAL 0)
        execute_process(COMMAND ${sign_command} "${binary}"
                        COMMAND_ERROR_IS_FATAL ANY)
    endif()
    execute_process(COMMAND "${sign_tool}" verify /pa /all /tw "${binary}"
                    COMMAND_ERROR_IS_FATAL ANY)
endforeach()
