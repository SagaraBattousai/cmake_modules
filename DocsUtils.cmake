include(PropertyUtils)
# include(PathUtils)

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

function(add_sphinx_docs target_name)

  set(options BREATHE_DOMAIN_ALL_CPP)
  set(oneValueArgs DIRECTORY OUTPUT_DIRECTORY CONF_IN CONF_OUT
                   DOXYGEN_OUTPUT_DIRECTORY ICON_IMAGE_PATH)
  set(multiValueArgs CSS JS BREATHE_DOMAIN_BY_EXTENSION_DICT RESTRUCTRED_TEXT)

  cmake_parse_arguments(PARSE_ARGV 1 SPHINX "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  # TODO: I think the original comment was: Improve this as it should add sub
  # files too (new comment) instead of having to manually add all files....
  # Though that is how add_library(... <sources>) works!
  if(NOT DEFINED SPHINX_RESTRUCTRED_TEXT)
    message(
      FATAL_ERROR
        "Keyword RESTRUCTRED_TEXT must be specified with at least one file")
  endif()

  if(NOT DEFINED SPHINX_DIRECTORY)
    set(SPHINX_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
  else()
    cmake_path(ABSOLUTE_PATH SPHINX_DIRECTORY BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR})
  endif()

  if(NOT DEFINED SPHINX_OUTPUT_DIRECTORY)
    set(SPHINX_OUTPUT_DIRECTORY "${SPHINX_DIRECTORY}/sphinx_build")
  else()
    cmake_path(ABSOLUTE_PATH SPHINX_OUTPUT_DIRECTORY BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR})
  endif()

  if(NOT DEFINED SPHINX_CONF_IN)
    set(SPHINX_CONF_IN "${SPHINX_DIRECTORY}/conf.py.in")
  else()
    cmake_path(ABSOLUTE_PATH SPHINX_CONF_IN BASE_DIRECTORY ${SPHINX_DIRECTORY})
  endif()

  if(NOT DEFINED SPHINX_CONF_OUT)
    set(SPHINX_CONF_OUT "${SPHINX_DIRECTORY}/conf.py")
  else()
    cmake_path(ABSOLUTE_PATH SPHINX_CONF_OUT BASE_DIRECTORY ${SPHINX_DIRECTORY})
  endif()

  # TODO: Maybe set DOXYGEN_OUTPUT_DIRECTORY to SPHINX_OUTPUT_DIRECTORY if
  # DEFINED
  #
  # Must be relative to conf.py NOTE: (could do cleaver thing to modify rtd as
  # well!) NOTE: DOXYGEN must be relative to ../sphinx but sphinx must be
  # relative to sphinx .... I really should clean this up if I ever get time!
  if(NOT DEFINED SPHINX_DOXYGEN_OUTPUT_DIRECTORY)
    set(SPHINX_DOXYGEN_OUTPUT_DIRECTORY "doxygen_build")
  elseif(IS_ABSOLUTE ${SPHINX_DOXYGEN_OUTPUT_DIRECTORY})
    cmake_path(RELATIVE_PATH SPHINX_DOXYGEN_OUTPUT_DIRECTORY BASE_DIRECTORY
               ${SPHINX_DIRECTORY})
  else()
    set(SPHINX_DOXYGEN_OUTPUT_DIRECTORY
        "${CMAKE_CURRENT_LIST_DIR}/${SPHINX_DOXYGEN_OUTPUT_DIRECTORY}")
    cmake_path(RELATIVE_PATH SPHINX_DOXYGEN_OUTPUT_DIRECTORY BASE_DIRECTORY
               ${SPHINX_DIRECTORY})
  endif()

  # TODO: So much to do!!!

  set(SPHINX_STATIC_DIR "${SPHINX_DIRECTORY}/_static")

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

    list(TRANSFORM SPHINX_JS PREPEND "${SPHINX_STATIC_DIR}/")
  endif()

  # Could use list(TRANSFORM but atm its just as easy to write twice Order
  # matters set(SPHINX_CSS_FILES_LIST " \"css/style.css\", \"css/colours.css\",
  # \"css/defaults.css\", \"css/dark.css\", \"css/light.css\", ")

  # set(SPHINX_JS_FILES_LIST "") #"\"js/falcie_docs.js\","

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

  set(SPHINX_RELATIVE_DOXYGEN_XML_DIR "${SPHINX_DOXYGEN_OUTPUT_DIRECTORY}/xml")
  set(SPHINX_ABSOLUTE_DOXYGEN_XML_DIR
      "${SPHINX_DIRECTORY}/${SPHINX_RELATIVE_DOXYGEN_XML_DIR}")

  configure_file(${SPHINX_CONF_IN} ${SPHINX_CONF_OUT} @ONLY)

  set(SPHINX_HTML_INDEX_FILE "${SPHINX_OUTPUT_DIRECTORY}/index.html")

  # Why do I need the -Dbreathe_XYZ since theyre in the conf.py but i should
  # trust old james
  add_custom_command(
    OUTPUT ${SPHINX_HTML_INDEX_FILE}
    COMMAND ${CMAKE_COMMAND} -E rm -r ${SPHINX_OUTPUT_DIRECTORY}
    COMMAND
      ${Sphinx_EXECUTABLE} -b html -j auto
      "-Dbreathe_projects.${PROJECT_NAME}=${SPHINX_ABSOLUTE_DOXYGEN_XML_DIR}"
      "-Dbreathe_default_project=${PROJECT_NAME}" ${SPHINX_DIRECTORY}
      ${SPHINX_OUTPUT_DIRECTORY}
      # Note incremental build doesn't copy over css/js however I hate having to
      # specify manually so just remember to copy over your css and js if theyre
      # different. I'll add a copy if different later.
      # ${SPHINX_RESTRUCTRED_TEXT} ${SPHINX_CSS} ${SPHINX_JS}
    WORKING_DIRECTORY ${SPHINX_DIRECTORY}
    MAIN_DEPENDENCY ${SPHINX_CONF_OUT}
    DEPENDS ${SPHINX_RESTRUCTRED_TEXT}
            "${SPHINX_ABSOLUTE_DOXYGEN_XML_DIR}/index.xml" ${SPHINX_CSS}
            ${SPHINX_JS}
    COMMENT "Generating documentation with Sphinx")

  add_custom_target(${target_name} DEPENDS ${SPHINX_HTML_INDEX_FILE})

endfunction()

# The following Variables will be set and used in configuiring Doxyfile.in: {
# DOXYGEN_INPUT_FILES, DOXYGEN_OUTPUT_DIRECTORY, DOXYGEN_XML_INDEX_FILE,
# DOXYFILE_IN, DOXYFILE_OUT }
#
# TODO: Decide whether to add flag to let target be added to ALL
#
function(add_doxygen_docs target_name)

  set(options GENERATE_XML GENERATE_HTML GENERATE_MAN GENERATE_LATEX
              JAVADOC_BANNER)
  set(oneValueArgs DIRECTORY OUTPUT_DIRECTORY DOXYFILE_IN DOXYFILE_OUT)
  set(multiValueArgs TARGETS)

  cmake_parse_arguments(PARSE_ARGV 1 DOXYGEN "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED DOXYGEN_TARGETS)
    message(
      FATAL_ERROR "TARGETS keyword must specified with at least one target.")
  endif()

  if(NOT DEFINED DOXYGEN_DIRECTORY)
    set(DOXYGEN_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
  else()
    cmake_path(ABSOLUTE_PATH DOXYGEN_DIRECTORY BASE_DIRECTORY
               ${CMAKE_CURRENT_LIST_DIR})
  endif()

  # Also relative to run on rtd function path in sphinx.conf When configuring
  # DOXYFILE_IN, OUTPUT_DIRECTORY must be relative in order for rtd to work as
  # this variable gets set in the resulting Doxyfile. We use
  # OUTPUT_DIRECTORY_ABS for CMake commands which is the absolute path variant
  #
  # REALLY IMPORTANT TODO: INSIST OUTPUT_DIRECTORY TO SAVE THIS UBER MESSY CODE
  #
  if(NOT DEFINED DOXYGEN_OUTPUT_DIRECTORY)
    set(DOXYGEN_OUTPUT_DIRECTORY "doxygen_build")
    # set(DOXYGEN_OUTPUT_DIRECTORY_ABS
    # "${CMAKE_CURRENT_LIST_DIR}/doxygen_build")
    set(DOXYGEN_OUTPUT_DIRECTORY_ABS "${DOXYGEN_DIRECTORY}/doxygen_build")
  elseif(IS_ABSOLUTE ${DOXYGEN_OUTPUT_DIRECTORY})
    set(DOXYGEN_OUTPUT_DIRECTORY_ABS ${DOXYGEN_OUTPUT_DIRECTORY})
    cmake_path(RELATIVE_PATH DOXYGEN_OUTPUT_DIRECTORY BASE_DIRECTORY
               ${DOXYGEN_DIRECTORY})
    # ${CMAKE_CURRENT_LIST_DIR})
  else()
    cmake_path(
      ABSOLUTE_PATH DOXYGEN_OUTPUT_DIRECTORY BASE_DIRECTORY
      ${DOXYGEN_DIRECTORY} OUTPUT_VARIABLE DOXYGEN_OUTPUT_DIRECTORY_ABS)
    # ${CMAKE_CURRENT_LIST_DIR} OUTPUT_VARIABLE DOXYGEN_OUTPUT_DIRECTORY_ABS)
  endif()

  if(NOT DEFINED DOXYGEN_DOXYFILE_IN)
    set(DOXYFILE_IN "${DOXYGEN_DIRECTORY}/Doxyfile.in")
  else()
    cmake_path(ABSOLUTE_PATH DOXYGEN_DOXYFILE_IN BASE_DIRECTORY
               ${DOXYGEN_DIRECTORY} OUTPUT_VARIABLE DOXYFILE_IN)
  endif()

  if(NOT DEFINED DOXYGEN_DOXYFILE_OUT)
    set(DOXYFILE_OUT "${DOXYGEN_DIRECTORY}/Doxyfile")
  else()
    cmake_path(ABSOLUTE_PATH DOXYGEN_DOXYFILE_OUT BASE_DIRECTORY
               ${DOXYGEN_DIRECTORY} OUTPUT_VARIABLE DOXYFILE_OUT)
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

  set(DOXYGEN_XML_OUTPUT_FILE "${DOXYGEN_OUTPUT_DIRECTORY_ABS}/xml/index.xml")
  message(STATUS "set(DOXYGEN_XML_OUTPUT_FILE \"${DOXYGEN_OUTPUT_DIRECTORY_ABS}/xml/index.xml")

  # input files must be relative to working directory calling Doxygen (and needs
  # to be the same as sphinx's so ..... for now just CMAKE_CURRENT_LIST_DIR
  # (and/or potentially add function argument but far far too much time wasted)
  # cmake_path(GET DOXYFILE_IN PARENT_PATH DOXYGEN_CONFIG_DIRECTORY)

  # set(DOXYGEN_WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})

  # May need to pass directory above this. DOXYGEN_INPUT_FILES DOXYGEN_DIRECTORY
  # ${DOXYGEN_WORKING_DIRECTORY} TARGETS
  _get_target_doxygen_sources(DOXYGEN_INPUT_FILES DOXYGEN_DIRECTORY
                              ${DOXYGEN_DIRECTORY} TARGETS ${DOXYGEN_TARGETS})

  configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

  # Can't use doxygen_add_docs as we need doxyfile to be usable for
  # read-the-docs.
  add_custom_command(
    OUTPUT ${DOXYGEN_XML_OUTPUT_FILE}
    DEPENDS ${DOXYFILE_IN}
    COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
    MAIN_DEPENDENCY ${DOXYFILE_OUT}
    WORKING_DIRECTORY ${DOXYGEN_DIRECTORY}
    COMMENT "Generating Doxygen Documentation ...")

  # Might be possible to combine with the above ... lets see (one day, we've
  # wasted a whole day on this!!!).
  add_custom_target(${target_name} DEPENDS ${DOXYGEN_XML_OUTPUT_FILE})
  add_dependencies(${target_name} ${DOXYGEN_TARGETS})

endfunction()

# For documentation: TARGETS keyword must specified with at least one target
# passed to this function whos source files require/want documentation.

# Sets out-var to the sources of the passed in targets' to be documented by
# Doxygen.
function(_get_target_doxygen_sources out_var)

  set(options)
  set(oneValueArgs DIRECTORY)
  set(multiValueArgs TARGETS)

  cmake_parse_arguments(PARSE_ARGV 1 DOXYGEN "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED DOXYGEN_TARGETS)
    message(
      FATAL_ERROR "TARGETS keyword must specified with at least one target.")
  endif()

  if(NOT DEFINED DOXYGEN_DIRECTORY)
    set(DOXYGEN_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
  elseif(NOT IS_ABSOLUTE ${DOXYGEN_DIRECTORY})
    set(DOXYGEN_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/${DOXYGEN_DIRECTORY}")
  endif()

  foreach(target ${DOXYGEN_TARGETS})
    get_sources_and_headers(_TARGET_SOURCES ${target})

    # I was going to extract but somewhat specific use case so leave it for now
    # Plus so much time wasted!!
    foreach(source_path ${_TARGET_SOURCES})
      if(NOT IS_ABSOLUTE ${source_path})
        get_target_property(_TARGET_SOURCE_DIR ${target} SOURCE_DIR)
        set(source_path "${_TARGET_SOURCE_DIR}/${source_path}")
      endif()
      cmake_path(RELATIVE_PATH source_path BASE_DIRECTORY ${DOXYGEN_DIRECTORY}
                 OUTPUT_VARIABLE source_relative_to_doxygen)

      list(APPEND DOCUMENTED_SOURCES ${source_relative_to_doxygen})
    endforeach()
  endforeach()

  list(JOIN DOCUMENTED_SOURCES " " ${out_var})
  return(PROPAGATE ${out_var})

endfunction()
