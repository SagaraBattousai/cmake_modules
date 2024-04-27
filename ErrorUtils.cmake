
function(func_call_text variable func_name) # ARGN =  func_args
  list(JOIN ARGN " " args)
  set(${variable} "${func_name}(${args})" PARENT_SCOPE)
endfunction()
