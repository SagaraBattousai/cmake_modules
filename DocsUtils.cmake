# SPDX-License-Identifier: BSD-3-Clause
# Copyright © 2024-2026 James Calo

include(PropertyUtils)
include(ErrorUtils)
# include(PathUtils)

set(_DOCS_BUILD_DIR_NAME "docs_build")

# NOTE: From what we've seen so far we want to stick to cmake_path(ABSOLUTE ..)
# as it seems to be more reliable. We will therefore make some preconditions in
# order to simplify this code as it's now wasted two full days and is overly
# complicated as it is trying way too hard to be flexable.
#
# Actually both are dodgy but ... lets just focus on the above as
# ${CMAKE_CURRENT_LIST_DIR} is absolute!
#
# Okay it seems that passing an abs path to those two functions is the key!
#
# TODO: The add_sphinx/doxygen_docs both need cleaning up for arg parsing and a
# concrete agreement on whether root directory must be specified and which
# things are relative etc
#
# TODO: maybe add target_link_documentation to handle the sphinx doxygen
# relationship
#
function(add_sphinx_docs target_name)

  set(options BREATHE_DOMAIN_ALL_CPP)
  set(oneValueArgs CONF_IN CONF_OUT ICON_IMAGE_PATH)
  set(multiValueArgs CSS JS BREATHE_DOMAIN_BY_EXTENSION_DICT RESTRUCTRED_TEXT)

  cmake_parse_arguments(PARSE_ARGV 1 SPHINX "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED SPHINX_RESTRUCTRED_TEXT)
    error_msg_with_func_call(
      MODE FATAL_ERROR MSG
      "Keyword RESTRUCTRED_TEXT must be specified with at least one file"
      ${ARGV})
  endif()

  if(NOT DEFINED SPHINX_CONF_IN)
    error_msg_with_func_call(MODE FATAL_ERROR MSG "CONF_IN must specified."
                             ${ARGV})
  else()
    cmake_path(ABSOLUTE_PATH SPHINX_CONF_IN BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR})
  endif()

  if(NOT DEFINED SPHINX_CONF_OUT)
    error_msg_with_func_call(MODE FATAL_ERROR MSG
                             "DOXYFILE_OUT must specified." ${ARGV})
  else()
    cmake_path(ABSOLUTE_PATH SPHINX_CONF_OUT BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR})
  endif()

  cmake_path(GET SPHINX_CONF_IN PARENT_PATH SPHINX_BASE_DIRECTORY)
  set(SPHINX_STATIC_DIR "${SPHINX_BASE_DIRECTORY}/_static")

  if(DEFINED SPHINX_CSS)
    list(TRANSFORM SPHINX_CSS PREPEND "\"" OUTPUT_VARIABLE
                                           SPHINX_CSS_FILES_LIST)
    list(TRANSFORM SPHINX_CSS_FILES_LIST APPEND "\",")
    # last elem should still have a , at the end
    list(JOIN SPHINX_CSS_FILES_LIST "" SPHINX_CSS_FILES_LIST)

    list(TRANSFORM SPHINX_CSS PREPEND "${SPHINX_STATIC_DIR}/")
  endif()

  if(DEFINED SPHINX_JS)
    list(TRANSFORM SPHINX_JS PREPEND "\"" OUTPUT_VARIABLE SPHINX_JS_FILES_LIST)
    list(TRANSFORM SPHINX_JS_FILES_LIST APPEND "\",")
    list(JOIN SPHINX_JS_FILES_LIST "" SPHINX_JS_FILES_LIST)

    list(TRANSFORM SPHINX_JS PREPEND "${SPHINX_STATIC_DIR}/")
  endif()

  # Is this correct? can we double quote for the caller ??
  # set(SPHINX_ICON_IMAGE_PATH "\"img/<ICON_IMAGE>.svg\"")

  # Could just call it this in the conf.py file!
  if(DEFINED SPHINX_BREATHE_DOMAIN_BY_EXTENSION_DICT)
    set(BREATHE_DOMAIN_BY_EXTENSION_DICT
        ${SPHINX_BREATHE_DOMAIN_BY_EXTENSION_DICT})
  endif()

  if(SPHINX_BREATHE_DOMAIN_ALL_CPP)
    # Now everything should be C++
    string(PREPEND BREATHE_DOMAIN_BY_EXTENSION_DICT "\"h\"   : \"cpp\",
      \"ixx\" : \"cpp\",
      ")
  endif()

  set(DOXYGEN_XML_DIR "${_DOCS_BUILD_DIR_NAME}/xml")

  cmake_path(
    ABSOLUTE_PATH DOXYGEN_XML_DIR BASE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    OUTPUT_VARIABLE SPHINX_ABSOLUTE_DOXYGEN_XML_DIR)

  cmake_path(
    RELATIVE_PATH SPHINX_ABSOLUTE_DOXYGEN_XML_DIR BASE_DIRECTORY
    ${SPHINX_BASE_DIRECTORY} OUTPUT_VARIABLE SPHINX_RELATIVE_DOXYGEN_XML_DIR)

  configure_file(${SPHINX_CONF_IN} ${SPHINX_CONF_OUT} @ONLY)

  set(SPHINX_OUTPUT_DIRECTORY "${_DOCS_BUILD_DIR_NAME}/sphinx")

  set(SPHINX_HTML_INDEX_FILE "${SPHINX_OUTPUT_DIRECTORY}/index.html")

  # Why do I need the -Dbreathe_XYZ since theyre in the conf.py but i should
  # trust old james. Haha i just added the same comment below :P
  add_custom_command(
    OUTPUT ${SPHINX_HTML_INDEX_FILE}
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${SPHINX_OUTPUT_DIRECTORY}
    COMMAND
      ${Sphinx_EXECUTABLE} -b html -j auto
      # TODO: Remember why we need these.. because rtd wont have this.. right?
      "-Dbreathe_projects.${PROJECT_NAME}=${SPHINX_ABSOLUTE_DOXYGEN_XML_DIR}"
      "-Dbreathe_default_project=${PROJECT_NAME}" ${SPHINX_BASE_DIRECTORY}
      ${SPHINX_OUTPUT_DIRECTORY}
      # Note incremental build doesn't copy over css/js however I hate having to
      # specify manually so just remember to copy over your css and js if theyre
      # different. I'll add a copy if different later.
      # ${SPHINX_RESTRUCTRED_TEXT} ${SPHINX_CSS} ${SPHINX_JS}
      WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    MAIN_DEPENDENCY ${SPHINX_CONF_OUT}
    DEPENDS ${SPHINX_RESTRUCTRED_TEXT}
            "${SPHINX_ABSOLUTE_DOXYGEN_XML_DIR}/index.xml" ${SPHINX_CSS}
            ${SPHINX_JS}
    COMMENT "Generating documentation with Sphinx")

  add_custom_target(${target_name} DEPENDS ${SPHINX_HTML_INDEX_FILE})

endfunction()

function(add_doxygen_docs target_name)

  # Possibly add ability to put in binary but not needed at all.
  set(options GENERATE_XML GENERATE_HTML GENERATE_MAN GENERATE_LATEX
              JAVADOC_BANNER ALL)
  set(oneValueArgs DOXYFILE_IN DOXYFILE_OUT)
  set(multiValueArgs TARGETS)

  cmake_parse_arguments(PARSE_ARGV 1 DOXYGEN "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED DOXYGEN_TARGETS)
    error_msg_with_func_call(
      MODE FATAL_ERROR MSG
      "TARGETS keyword must specified with at least one target." ${ARGV})
  endif()

  if(NOT DEFINED DOXYGEN_DOXYFILE_IN)
    error_msg_with_func_call(MODE FATAL_ERROR MSG "DOXYFILE_IN must specified."
                             ${ARGV})
  else()
    cmake_path(ABSOLUTE_PATH DOXYGEN_DOXYFILE_IN BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR} OUTPUT_VARIABLE DOXYFILE_IN)
  endif()

  if(NOT DEFINED DOXYGEN_DOXYFILE_OUT)
    error_msg_with_func_call(MODE FATAL_ERROR MSG
                             "DOXYFILE_OUT must specified." ${ARGV})
  else()
    cmake_path(ABSOLUTE_PATH DOXYGEN_DOXYFILE_OUT BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR} OUTPUT_VARIABLE DOXYFILE_OUT)
  endif()

  if(DOXYGEN_GENERATE_XML)
    set(DOXYGEN_GENERATE_XML YES)
  else()
    set(DOXYGEN_GENERATE_XML NO)
  endif()

  if(DOXYGEN_GENERATE_HTML)
    set(DOXYGEN_GENERATE_HTML YES)
  else()
    set(DOXYGEN_GENERATE_HTML NO)
  endif()

  if(DOXYGEN_GENERATE_MAN)
    set(DOXYGEN_GENERATE_MAN YES)
  else()
    set(DOXYGEN_GENERATE_MAN NO)
  endif()

  if(DOXYGEN_GENERATE_LATEX)
    set(DOXYGEN_GENERATE_LATEX YES)
  else()
    set(DOXYGEN_GENERATE_LATEX NO)
  endif()

  if(DOXYGEN_JAVADOC_BANNER)
    set(DOXYGEN_JAVADOC_BANNER YES)
  else()
    set(DOXYGEN_JAVADOC_BANNER NO)
  endif()

  # When set in Doxyfile it must be relative as the values set would be
  # incorrect on RTD. However for the cmake code we prefer absolute paths as we
  # can be sure this function has been called in order to configure.
  #
  set(DOXYGEN_OUTPUT_DIRECTORY ${_DOCS_BUILD_DIR_NAME})

  set(DOXYGEN_XML_OUTPUT_FILE
      "${CMAKE_CURRENT_LIST_DIR}/${DOXYGEN_OUTPUT_DIRECTORY}/xml/index.xml")

  _get_target_doxygen_sources(DOXYGEN_INPUT_FILES TARGETS ${DOXYGEN_TARGETS})

  configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

  # Can't use doxygen_add_docs as we need doxyfile to be usable for
  # read-the-docs.
  add_custom_command(
    OUTPUT ${DOXYGEN_XML_OUTPUT_FILE}
    DEPENDS ${DOXYFILE_IN}
    COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
    MAIN_DEPENDENCY ${DOXYFILE_OUT}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    COMMENT "Generating Doxygen Documentation ...")

  if(DOXYGEN_ALL)
    add_custom_target(${target_name} ALL DEPENDS ${DOXYGEN_XML_OUTPUT_FILE})
  else()
    add_custom_target(${target_name} DEPENDS ${DOXYGEN_XML_OUTPUT_FILE})
  endif()

  add_dependencies(${target_name} ${DOXYGEN_TARGETS})

endfunction()

# For documentation: TARGETS keyword must specified with at least one target
# passed to this function whos source files require/want documentation.

# Sets out-var to the sources of the passed in targets' to be documented by
# Doxygen.
function(_get_target_doxygen_sources out_var)

  set(options)
  set(oneValueArgs)
  set(multiValueArgs TARGETS)

  cmake_parse_arguments(PARSE_ARGV 1 DOXYGEN "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED DOXYGEN_TARGETS)
    error_msg_with_func_call(
      MODE FATAL_ERROR MSG
      "TARGETS keyword must specified with at least one target." ${ARGV})
  endif()

  foreach(target ${DOXYGEN_TARGETS})
    get_sources_and_headers(_TARGET_SOURCES ${target})

    foreach(source_path ${_TARGET_SOURCES})
      if(NOT IS_ABSOLUTE ${source_path})
        get_target_property(_TARGET_SOURCE_DIR ${target} SOURCE_DIR)

        # TODO: Mini bug here as INTERFACE libraries have an issue with showing
        # linkers sources as their own. However, hard to remove as they are
        # allowed to have their own sources now (Cmake 3.19 IIRC) Fix would be
        # required in PropertyUtils.
        cmake_path(ABSOLUTE_PATH source_path BASE_DIRECTORY
                   ${_TARGET_SOURCE_DIR})
      endif()
      cmake_path(
        RELATIVE_PATH source_path BASE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE source_relative_to_doxygen)

      list(APPEND DOCUMENTED_SOURCES ${source_relative_to_doxygen})
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES DOCUMENTED_SOURCES)
  list(JOIN DOCUMENTED_SOURCES " " ${out_var})
  return(PROPAGATE ${out_var})

endfunction()
