include(PropertyUtils)
# include(PathUtils)

# Sets out-var to the sources of the passed in targets' to be documented by
# Doxygen.
function(_get_target_doxygen_sources out_var)

  set(options)
  set(oneValueArgs DOXYGEN_DIRECTORY)
  set(multiValueArgs TARGETS)

  cmake_parse_arguments(PARSE_ARGV 1 GTDS "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED GTDS_TARGETS)
    message(
      FATAL_ERROR
        "TARGETS keyword must specified with at least \
    one target passed to this function \
    whos source files require/want documentation.")
  endif()

  if(NOT DEFINED GTDS_DOXYGEN_DIRECTORY)
    message(AUTHOR_WARNING "DOXYGEN_DIRECTORY not specified. \
    Defaulting to ${CMAKE_CURRENT_LIST_DIR}")

    set(GTDS_DOXYGEN_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
  elseif(NOT IS_ABSOLUTE ${GTDS_DOXYGEN_DIRECTORY})
    set(GTDS_DOXYGEN_DIRECTORY
        "${CMAKE_CURRENT_LIST_DIR}/${GTDS_DOXYGEN_DIRECTORY}")
  endif()

  foreach(target ${GTDS_TARGETS})
    get_sources_and_headers(_TARGET_SOURCES ${target})

    # I was going to extract but somewhat specific use case so leave it for now
    # Plus so much time wasted!!
    foreach(source_path ${_TARGET_SOURCES})
      if(NOT IS_ABSOLUTE ${source_path})
        get_target_property(_TARGET_SOURCE_DIR ${target} SOURCE_DIR)
        set(source_path "${_TARGET_SOURCE_DIR}/${source_path}")
      endif()
      cmake_path(
        RELATIVE_PATH source_path BASE_DIRECTORY ${GTDS_DOXYGEN_DIRECTORY}
        OUTPUT_VARIABLE source_relative_to_doxygen)

      list(APPEND DOCUMENTED_SOURCES ${source_relative_to_doxygen})
    endforeach()
  endforeach()

  list(JOIN DOCUMENTED_SOURCES " " ${out_var})
  return(PROPAGATE ${out_var})

endfunction()

# The following Variables will be set and used in configuiring Doxyfile.in: {
# DOXYGEN_INPUT_FILES, DOXYGEN_OUTPUT_DIRECTORY, DOXYGEN_XML_INDEX_FILE,
# DOXYFILE_IN, DOXYFILE_OUT }
#
# TODO: Decide whether to add flag to let target be added to ALL
#
function(add_doxygen_docs target_name)

  set(options DOXYGEN_GENERATE_XML DOXYGEN_GENERATE_HTML DOXYGEN_GENERATE_MAN
              DOXYGEN_GENERATE_LATEX DOXYGEN_JAVADOC_BANNER)
  set(oneValueArgs DOXYFILE_ROOT_DIRECTORY DOXYGEN_OUTPUT_DIRECTORY DOXYFILE_IN
                   DOXYFILE_OUT)
  set(multiValueArgs TARGETS)

  cmake_parse_arguments(PARSE_ARGV 1 ADD "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  if(NOT DEFINED ADD_TARGETS)
    message(
      FATAL_ERROR
        "TARGETS keyword must specified with at least one target passed \
        to this function whos source files require/want documentation.")
  endif()

  # When configuring DOXYFILE_IN DOXYGEN_OUTPUT_DIRECTORY must be relative in
  # order for rtd to work as this variable gets set in the resulting Doxyfile.
  # We use DOXYGEN_OUTPUT_DIRECTORY_ABS for CMake commands which is the absolute
  # path variant
  if(NOT DEFINED ADD_DOXYGEN_OUTPUT_DIRECTORY)
    set(DOXYGEN_OUTPUT_DIRECTORY "doxygen_build")
    set(DOXYGEN_OUTPUT_DIRECTORY_ABS
        "${CMAKE_CURRENT_LIST_DIR}/${DOXYGEN_OUTPUT_DIRECTORY}")
    message(AUTHOR_WARNING "DOXYGEN_OUTPUT_DIRECTORY not specified.\
    Defaulting to ${DOXYGEN_OUTPUT_DIRECTORY_ABS}")
  else()
    if(IS_ABSOLUTE ${ADD_DOXYGEN_OUTPUT_DIRECTORY})
      set(DOXYGEN_OUTPUT_DIRECTORY_ABS ${ADD_DOXYGEN_OUTPUT_DIRECTORY})
      cmake_path(
        RELATIVE_PATH ADD_DOXYGEN_OUTPUT_DIRECTORY BASE_DIRECTORY
        ${CMAKE_CURRENT_LIST_DIR} OUTPUT_VARIABLE DOXYGEN_OUTPUT_DIRECTORY)
    else()
      set(DOXYGEN_OUTPUT_DIRECTORY ${ADD_DOXYGEN_OUTPUT_DIRECTORY})
      cmake_path(
        ABSOLUTE_PATH ADD_DOXYGEN_OUTPUT_DIRECTORY BASE_DIRECTORY
        ${CMAKE_CURRENT_LIST_DIR} OUTPUT_VARIABLE DOXYGEN_OUTPUT_DIRECTORY_ABS)
    endif()
  endif()

  if(NOT DEFINED ADD_DOXYFILE_IN)
    if(NOT DEFINED ADD_DOXYFILE_ROOT_DIRECTORY)
      set(DOXYFILE_IN "${CMAKE_CURRENT_LISTS_DIR}/Doxyfile.in")
      message(
        AUTHOR_WARNING
          "Neither DOXYFILE_IN or DOXYFILE_ROOT_DIRECTORY are specified.\
        Defaulting to ${DOXYFILE_IN}")
    else()
      set(DOXYFILE_IN "${ADD_DOXYFILE_ROOT_DIRECTORY}/Doxyfile.in")
      message(
        AUTHOR_WARNING "DOXYFILE_IN not specified. Defaulting to ${DOXYFILE_IN}"
      )
    endif()
  else()
    set(DOXYFILE_IN ${ADD_DOXYFILE_IN})
  endif()

  if(NOT DEFINED ADD_DOXYFILE_OUT)
    if(NOT DEFINED ADD_DOXYFILE_ROOT_DIRECTORY)
      set(DOXYFILE_OUT "${CMAKE_CURRENT_LISTS_DIR}/Doxyfile")
      message(
        AUTHOR_WARNING
          "Neither DOXYFILE_OUT or DOXYFILE_ROOT_DIRECTORY are specified.\
        Defaulting to ${DOXYFILE_OUT}")
    else()
      set(DOXYFILE_OUT "${ADD_DOXYFILE_ROOT_DIRECTORY}/Doxyfile")
      message(
        AUTHOR_WARNING
          "DOXYFILE_OUT not specified. Defaulting to ${DOXYFILE_OUT}")
    endif()
  else()
    set(DOXYFILE_OUT ${ADD_DOXYFILE_OUT})
  endif()

  # TRUE and FALSE may work but ... better safe than sorry (for now)
  if(ADD_DOXYGEN_GENERATE_XML)
    set(DOXYGEN_GENERATE_XML YES)
  else()
    set(DOXYGEN_GENERATE_XML NO)
  endif()

  if(ADD_DOXYGEN_GENERATE_HTML)
    set(DOXYGEN_GENERATE_HTML YES)
  else()
    set(DOXYGEN_GENERATE_HTML NO)
  endif()

  if(ADD_DOXYGEN_GENERATE_MAN)
    set(DOXYGEN_GENERATE_MAN YES)
  else()
    set(DOXYGEN_GENERATE_MAN NO)
  endif()

  if(ADD_DOXYGEN_GENERATE_LATEX)
    set(DOXYGEN_GENERATE_LATEX YES)
  else()
    set(DOXYGEN_GENERATE_LATEX NO)
  endif()

  if(ADD_DOXYGEN_JAVADOC_BANNER)
    set(DOXYGEN_JAVADOC_BANNER YES)
  else()
    set(DOXYGEN_JAVADOC_BANNER NO)
  endif()

  set(DOXYGEN_XML_OUTPUT_FILE "${DOXYGEN_OUTPUT_DIRECTORY_ABS}/xml/index.xml")

  # input files must be relative to working directory calling Doxygen 
  # (and needs to be the same as sphinx's so ..... 
  # for now just CMAKE_CURRENT_LIST_DIR 
  # (and/or potentially add function argument but far far too much time wasted)
  # cmake_path(GET DOXYFILE_IN PARENT_PATH DOXYGEN_CONFIG_DIRECTORY)

  set(DOXYGEN_WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})

  # May need to pass directory above this.
  _get_target_doxygen_sources(
    DOXYGEN_INPUT_FILES DOXYGEN_DIRECTORY ${DOXYGEN_WORKING_DIRECTORY} TARGETS
    ${ADD_TARGETS})

  configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

  # Can't use doxygen_add_docs as we need doxyfile to be usable for
  # read-the-docs.
  add_custom_command(
    OUTPUT ${DOXYGEN_XML_OUTPUT_FILE}
    DEPENDS ${DOXYFILE_IN}
    COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
    MAIN_DEPENDENCY ${DOXYFILE_OUT}
    WORKING_DIRECTORY ${DOXYGEN_WORKING_DIRECTORY}
    COMMENT "Generating Doxygen Documentation ...")

  # Might be possible to combine with the above ... 
  # lets see (one day, we've wasted a whole day on this!!!).
  add_custom_target(${target_name} DEPENDS ${DOXYGEN_XML_OUTPUT_FILE})
  add_dependencies(${target_name} ${ADD_TARGETS})

endfunction()
