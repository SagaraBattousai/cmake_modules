
function(func_call_text variable func_name func_args)
  list(JOIN func_args " " args)
  set(${variable} "${func_name}(${args})" PARENT_SCOPE)
endfunction()
