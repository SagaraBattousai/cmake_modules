macro(set_language_standards)
  set(options REQUIRED)
  set(oneValueArgs C CXX CUDA HIP OBJC OBJCXX)
  
  cmake_parse_arguments(arg_set_standards "${options}" "${oneValueArgs}" "" ${ARGN})

  # Could probably clean up (although not the if split as we want separate DEBUG messages
  # Forcing myself to be an early moring person is messing with my coding ability

  # Leave C++ standard up to the root application, so set it only if this is the
  # current top-level CMake project.
  if(PROJECT_IS_TOP_LEVEL)
    message(DEBUG "Project is top level so setting standards:")
    foreach(lang IN LISTS oneValueArgs)
      if(DEFINED "arg_set_standards_${lang}")
        set(curr_standard "CMAKE_${lang}_STANDARD")
        set(curr_standard_value "${arg_set_standards_${lang}}")
        message(DEBUG "Setting ${curr_standard} to ${curr_standard_value}")
        set("${curr_standard}" "${curr_standard_value}")
        if(arg_set_standards_REQUIRED)
          message(DEBUG "and requiring said standard.")
          set("${curr_standard}_REQUIRED" ON)
        endif()
      endif()
    endforeach()
  elseif(arg_set_standards_REQUIRED)
    message(DEBUG "Project is NOT top level but standards are required so enforcing languages are at least value:")
    foreach(lang IN LISTS oneValueArgs)
      set(curr_standard "CMAKE_${lang}_STANDARD")
      set(curr_standard_value "${arg_set_standards_${lang}}")
      if(DEFINED "arg_set_standards_${lang}")
        message(DEBUG "Requiring ${curr_standard} to be at least ${curr_standard_value}")
        if("${curr_standard}" LESS "${curr_standard_value}")
          message(
            FATAL_ERROR
            "${PROJECT_NAME} requires ${curr_standard} >= ${curr_standard_value} (got: ${CMAKE_${lang}_STANDARD})")
        endif()
      endif()
    endforeach()
  endif()

endmacro()

#TODO: Test but for now..... Ive wasted too much time.
function(set_cache_choices var)
  set(options FORCE)
  # TODO: Help string and DEFAULT value
  set(oneValueArgs HELP VALUE)
  set(multiValueArgs CHOICES) 
  cmake_parse_arguments(PARSE_ARGV 1 arg 
    "${options}" "${oneValueArgs}" "${multiValueArgs}")

  if(DEFINED arg_KEYWORDS_MISSING_VALUES AND multiValueArgs IN_LIST arg_KEYWORDS_MISSING_VALUES)
    message(WARNING "CHOICES keyword given but no values pased")
    return()
  endif()

  if(NOT DEFINED arg_HELP)
    set(arg_HELP "")
  endif()

  if(NOT DEFINED arg_VALUE)
    set(arg_VALUE "")
  endif()

  if(arg_FORCE)
    set(force_cache_value "FORCE")
  endif()

  set(CACHE{${var}} TYPE STRING HELP arg_HELP ${force_cache_value} VALUE arg_VALUE)

  if(NOT DEFINED arg_CHOICES)
    message(WARNING "No Choices passed")
  else()
    set_property(CACHE ${var} PROPERTY STRINGS ${arg_CHOICES})
  endif()

endfunction()
