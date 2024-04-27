# Property Utils
# ---------------
#
# This module provides functions and macros for generating details from
# properties
#

include(ErrorUtils)

# get_subtargets
# ---------------
#
# `` get_subtargets(<variable> [DIRECTORY <dir>] [DEPTH <depth>])
#
# `` The ``DIRECTORY`` argument specifies another directory from which to
# retrieve the property value instead of the current directory. Relative paths
# are treated as relative to the current source directory. CMake must already
# know about the directory, either by having added it through a call to
# add_subdirectory() or being the top level directory.
#
# The ``DEPTH`` argument specifies how far down the subdirectory tree to travel.
# The default is to travel through every subdirectory and return all targets
# defined in the directory passed and below
#
function(get_subtargets variable)

  set(options "")
  set(oneValueArgs DIRECTORY DEPTH)
  set(multiValueArgs "")

  cmake_parse_arguments(PARSE_ARGV 1 GET_SUBTARGETS options "${oneValueArgs}"
                        multiValueArgs)

  # Set Directory argument
  if(NOT DEFINED GET_SUBTARGETS_DIRECTORY)
    set(GET_SUBTARGETS_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
    if(DIRECTORY IN_LIST GET_SUBTARGETS_KEYWORDS_MISSING_VALUES)
      func_call_text(GET_SUBTARGETS_FUNC_CALL_TEXT "get_subtargets" "${ARGV}")
      message(
        WARNING "get_subtargets called as:\n"
                "${GET_SUBTARGETS_FUNC_CALL_TEXT}\n"
                "DIRECTORY specified but not given an argument and will "
                "default to current directory: ${GET_SUBTARGETS_DIRECTORY}")
    endif()
  endif()

  # Set Depth argument
  if(NOT DEFINED GET_SUBTARGETS_DEPTH)
    set(GET_SUBTARGETS_DEPTH -1)
    if(DEPTH IN_LIST GET_SUBTARGETS_KEYWORDS_MISSING_VALUES)
      if(NOT DEFINED GET_SUBTARGETS_FUNC_CALL_TEXT)
        func_call_text(GET_SUBTARGETS_FUNC_CALL_TEXT "get_subtargets" "${ARGV}")
      endif()
      message(
        WARNING "get_subtargets called as:\n"
                "${GET_SUBTARGETS_FUNC_CALL_TEXT}\n"
                "DEPTH specified but not given an argument and will "
                "default to -1 i.e. it will discover all subtargets")
    endif()
  endif()

  # Here we use a unique name for the first argument (variable) in order to not
  # have an issue when we propogate the variable. For example, if we didnt do
  # this then if the passed in variable name was called "subtargets" we would
  # only get the last subtargets returned (an apparently duplicated :O )
  _get_subtargets_recursive(GET_SUBTARGETS_LIST_VAR ${GET_SUBTARGETS_DIRECTORY}
                            ${GET_SUBTARGETS_DEPTH})

  # return(PROPAGATE ${variable})
  set(${variable} ${GET_SUBTARGETS_LIST_VAR} PARENT_SCOPE)
endfunction()

function(_get_subtargets_recursive variable curr_dir depth)

  get_directory_property(subtargets DIRECTORY ${curr_dir} BUILDSYSTEM_TARGETS)

  if(NOT subtargets STREQUAL "")
    list(APPEND ${variable} "${subtargets}")
  endif()

  if(depth EQUAL 0)
    # Base Case
    return(PROPAGATE ${variable})
  else()
    # Recusive case
    math(EXPR depth "${depth} - 1")

    get_directory_property(subdirectories DIRECTORY ${curr_dir} SUBDIRECTORIES)

    # Since our loop ingnores empty we don't need an early return.

    # using IN LISTS works and is in someways nicer but on the off chance we
    # have an empty element i.e. "a;;b" then there could be an error
    foreach(sub_dir ${subdirectories})

      # Recusive call (I dont think we can make it tail rec :'( ) or is it?
      # Can't quite work out how to make pure iterative plus I've wasted more
      # than enough time :'(
      _get_subtargets_recursive(${variable} ${sub_dir} ${depth})

    endforeach()
  endif()
  return(PROPAGATE ${variable})
endfunction()

# Possible TODO: Could let you pass a function to get_subtargets but again lets
# just get on with work !!!

function(set_direct_subtargets_folder folder_name)
  get_subtargets(subtargets DIRECTORY ${CMAKE_CURRENT_LIST_DIR} DEPTH 1)
  set_target_properties(${subtargets} PROPERTIES FOLDER ${folder_name})
endfunction()

function(get_sources_and_headers out_var target)
  get_target_property(_TARGET_SOURCE_FILES ${target} SOURCES)
  if(NOT _TARGET_SOURCE_FILES STREQUAL "_TARGET_SOURCE_FILES-NOTFOUND")
    set(${out_var} ${_TARGET_SOURCE_FILES})
  endif()
  get_target_property(_HEADER_SET_NAMES ${target} HEADER_SETS)
  foreach(_header_set_name ${_HEADER_SET_NAMES})
    get_target_property(_HEADER_SET ${target} HEADER_SET_${_header_set_name})
    # TODO: Check if we need an if(DEFINED ...) here too!
    list(APPEND ${out_var} ${_HEADER_SET})
  endforeach()
  return(PROPAGATE ${out_var})
endfunction()

