# Public certificate thumbprint only; the private key stays in its signing provider.
function(warblade_sign_command out_var)
    if("$ENV{WARBLADE_SIGN_CERT_SHA1}" STREQUAL "" AND
       "$ENV{WARBLADE_SIGN_TIMESTAMP_URL}" STREQUAL "")
        set(${out_var} "" PARENT_SCOPE)
        return()
    endif()
    string(LENGTH "$ENV{WARBLADE_SIGN_CERT_SHA1}" thumbprint_length)
    if(NOT thumbprint_length EQUAL 40 OR
       NOT "$ENV{WARBLADE_SIGN_CERT_SHA1}" MATCHES "^[0-9A-Fa-f]+$")
        message(FATAL_ERROR "WARBLADE_SIGN_CERT_SHA1 must be a 40-digit certificate thumbprint.")
    endif()
    if(NOT "$ENV{WARBLADE_SIGN_TIMESTAMP_URL}" MATCHES "^https?://[^ ;\"\r\n]+$")
        message(FATAL_ERROR "Set WARBLADE_SIGN_TIMESTAMP_URL to your provider's RFC 3161 URL.")
    endif()
    find_program(sign_tool NAMES signtool.exe REQUIRED)
    set(${out_var} "${sign_tool};sign;/sha1;$ENV{WARBLADE_SIGN_CERT_SHA1};/fd;SHA256;/tr;$ENV{WARBLADE_SIGN_TIMESTAMP_URL};/td;SHA256" PARENT_SCOPE)
endfunction()
