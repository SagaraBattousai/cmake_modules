
#Not Comprehensive,.....YET......
macro(set_system_arch_vars)
  if (CMAKE_SYSTEM_PROCESSOR MATCHES 
      "(x86)|(X86)|(x86_64)|(amd64)|(AMD64)")
    set(x86 TRUE)
  elseif (CMAKE_SYSTEM_PROCESSOR MATCHES 
      #TODO: Check the 32 bit systems names, for now they're educated guesses
      "(aarch64)|(AArch64)|(arm64)|(ARM64)|(arm)|(ARM)")
    set(ARM TRUE)
  endif()
endmacro()
