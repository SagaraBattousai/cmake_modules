# SPDX-License-Identifier: BSD-3-Clause
# Copyright © 2024-2026 James Calo

# Make Smarter
function(add_qt_cmake_to_prefix_path)
  if(DEFINED ENV{QT_CMAKE_MODULE_PATH})
    list(APPEND CMAKE_PREFIX_PATH "$ENV{QT_CMAKE_MODULE_PATH}")
  endif()
  # for msvc could use ${MSVC_TOOLSET_VERSION} to convert to year and
  # ${CMAKE_VS_PLATFORM_NAME} for arch but too much as also need qt version
  return(PROPAGATE CMAKE_PREFIX_PATH)
endfunction()

# TODO: Improve somewhat when you have time
function(find_windeployqt)
  if(NOT DEFINED windeployqt_EXECUTABLE OR windeployqt_EXECUTABLE STREQUAL
                                           "windeployqt_EXECUTABLE-NOTFOUND")
    # Hints get searched before the system paths. They should only be set by
    # some source of knowledge, location of other files, etc and not populated
    # with "guesses" or default locations.
    set(_WINDEPLOYQT_ROOT_HINTS ${QT_ROOT} ENV QT_ROOT # Uses ENV var <QT_ROOT>
                                                       # as hint if it exists
    )

    # Paths get searched after system locations. This is the place to put
    # default locations. set(_WINDEPLOYQT_ROOT_PATHS ${QT_ROOT}/bin )

    find_program(
      windeployqt_EXECUTABLE
      NAMES windeployqt
      HINTS ${_WINDEPLOYQT_ROOT_HINTS}
      # PATHS ${_WINDEPLOYQT_ROOT_PATHS}
      PATH_SUFFIXES bin
      DOC "Path to windeployqt executable")
  endif()
  return(PROPAGATE windeployqt_EXECUTABLE)
endfunction()

function(windeployqt target)
  find_windeployqt()
  #TODO: probably should add check here but cba right now, too much to do


  add_custom_command(
    TARGET ${target} POST_BUILD
    COMMAND ${windeployqt_EXECUTABLE} "$<TARGET_FILE_DIR:${target}>"
    VERBATIM)

endfunction()
