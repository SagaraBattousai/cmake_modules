function(func_call_text variable func_name) # ARGN =  func_args
  list(JOIN ARGN " " args)
  set(${variable}
      "${func_name}(${args})"
      PARENT_SCOPE)
endfunction()

macro(error_msg_with_func_call)
  set(options)
  set(oneValueArgs MODE MSG SEP FUNC_INTRO)
  set(multiValueArgs)

  cmake_parse_arguments(_ERROR "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED _ERROR_MODE)
    set(_ERROR_MODE STATUS)
  endif()

  if(NOT DEFINED _ERROR_SEP)
    set(_ERROR_SEP " ")
  endif()

  if(NOT DEFINED _ERROR_FUNC_INTRO)
    set(_ERROR_FUNC_INTRO "function called as:")
  endif()

  string(JOIN " " _ERROR_FUNC_ARGS ${_ERROR_UNPARSED_ARGUMENTS})

  # Using Join to avoid splitting string over multiple lines in message :)
  string(JOIN "" _ERROR_FULL_MESSAGE ${_ERROR_MSG} ${_ERROR_SEP}
    ${_ERROR_FUNC_INTRO} "\n${CMAKE_CURRENT_FUNCTION}(${_ERROR_FUNC_ARGS})")

  message(${_ERROR_MODE} ${_ERROR_FULL_MESSAGE})
endmacro()
