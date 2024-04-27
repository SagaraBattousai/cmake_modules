# Don't (potentially yet) support the Stable Application Binary Interface
# Extension version True support only if using find_package(Python3 ...) /
# FindPython3. If using FindPython or FindPython2 please set
# <PYTHON_EXTENSION_SUFFIX> Otherwise if(WIN32) .pyd else .so
macro(set_python_extension_suffix target)
  if(NOT DEFINED PYTHON_EXTENSION_SUFFIX)
    if(NOT Python3_FOUND)
      message(WARNING "Python3_FOUND is false, using basic extension setting \
          if(WIN32) .pyd else .so")
      if(WIN32)
        set(PYTHON_EXTENSION_SUFFIX ".pyd")
      else()
        set(PYTHON_EXTENSION_SUFFIX ".so")
      endif()
    else()
      # Actually im not so keen on SOABI as it strips the leading . and ending
      # .so or .pyd
      #
      # On WIN32 theres an issue if INTERPRETER isnt required or looked for as
      # it can't call python to get the EXT_SUFFIX additionally we have a "fix"
      # for WIN32 and LINUX (we wont say unix for now to be safe!)
      if(NOT (Python3_SOABI STREQUAL "" AND (WIN32 OR LINUX)))
        if(Python3_SOABI STREQUAL "")
          message(STATUS "HUH")
        endif()
        set(PYTHON_EXTENSION_SUFFIX ".${Python3_SOABI}")
        if(WIN32)
          set(PYTHON_EXTENSION_SUFFIX "${PYTHON_EXTENSION_SUFFIX}.pyd")
        else()
          set(PYTHON_EXTENSION_SUFFIX "${PYTHON_EXTENSION_SUFFIX}.so")
        endif()
      # Using string(JOIN ...) allows multiline to keep source code neat
      elseif(WIN32)
        string(JOIN "_" PYTHON_EXTENSION_SUFFIX
               ".cp${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}-win"
               "${CMAKE_SYSTEM_PROCESSOR}.pyd")
        string(TOLOWER ${PYTHON_EXTENSION_SUFFIX} PYTHON_EXTENSION_SUFFIX)
      elseif(LINUX)
        string(JOIN "-" PYTHON_EXTENSION_SUFFIX ".cpython"
               "${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}"
               "${CMAKE_LIBRARY_ARCHITECTURE}.so")
      endif()
    endif()
  endif()
  set_target_properties(${target} PROPERTIES SUFFIX
                                             "${PYTHON_EXTENSION_SUFFIX}")
  message(STATUS "Python extension suffix = ${PYTHON_EXTENSION_SUFFIX}")
endmacro()
