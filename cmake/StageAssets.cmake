if(NOT IS_DIRECTORY "${SOURCE}" OR "${DESTINATION}" STREQUAL "")
    message(FATAL_ERROR "Source assets and a destination path are required.")
endif()
file(REAL_PATH "${SOURCE}" source_path)
if(EXISTS "${DESTINATION}" OR IS_SYMLINK "${DESTINATION}")
    file(REAL_PATH "${DESTINATION}" existing_path)
    if(NOT existing_path STREQUAL source_path)
        message(FATAL_ERROR "${DESTINATION} already exists and does not point to the project assets. "
                            "It has been left unchanged.")
    endif()
    return()
endif()

# A junction needs no administrator rights on Windows and reflects asset edits
# immediately. Other hosts use a directory symlink. Never replace existing data.
if(CMAKE_HOST_WIN32)
    file(TO_NATIVE_PATH "${DESTINATION}" destination_native)
    file(TO_NATIVE_PATH "${source_path}" source_native)
    execute_process(COMMAND cmd /d /c mklink /J "${destination_native}" "${source_native}"
                    RESULT_VARIABLE result OUTPUT_QUIET ERROR_VARIABLE error)
else()
    file(CREATE_LINK "${source_path}" "${DESTINATION}" SYMBOLIC RESULT result)
endif()
if(NOT result STREQUAL "0")
    message(FATAL_ERROR "Could not prepare ${DESTINATION}: ${result} ${error}")
endif()
