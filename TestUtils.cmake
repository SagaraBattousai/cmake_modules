# SPDX-License-Identifier: BSD-3-Clause
# Copyright © 2024-2026 James Calo

include(FetchContent)
include(ErrorUtils)
# Potentially better to have as a macro (especially thanks to
# cmake_parse_arguments)
function(fetch_googletest)

  set(options)
  # Hidden can be specified without value for default
  set(oneValueArgs HIDDEN HASH MASH)
  set(multiValueArgs)

  cmake_parse_arguments(PARSE_ARGV 0 FGT "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED FGT_HASH)
    func_call_text(fct "fetch_googletest" "${ARGV}")
    message(FATAL_ERROR "HASH keyword with a value must be passed to function \
      \"fetch_googletest\" instead recieved ${fct}.")
  endif()

  if(WIN32)
    set(googletest_commit_hash_and_ext "${FGT_HASH}.zip")
  else()
    set(googletest_commit_hash_and_ext "${FGT_HASH}.tar.gz")
  endif()

  # VV Faster than git repo :)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/${googletest_commit_hash_and_ext}
        DOWNLOAD_EXTRACT_TIMESTAMP
        TRUE)

  if(WIN32)
    # For Windows: Prevent overriding the project's compiler/linker settings
    set(gtest_force_shared_crt
        ON
        CACHE BOOL "" FORCE)
  endif()

  FetchContent_MakeAvailable(googletest)

  if(DEFINED FGT_HIDDEN) 
    if("HIDDEN" IN_LIST FGT_KEYWORDS_MISSING_VALUES)
      set_target_properties(gtest gtest_main gmock gmock_main
                          PROPERTIES FOLDER Tests/googletest)
    else()
      set_target_properties(gtest gtest_main gmock gmock_main
        PROPERTIES FOLDER ${FGT_HIDDEN})
    endif()
  endif()

endfunction()
