
#Make Smarter
function(add_qt_cmake_to_prefix_path)
  if(DEFINED ENV{Qt_CMAKE_MODULE_PATH})
    list(APPEND CMAKE_PREFIX_PATH "$ENV{Qt_CMAKE_MODULE_PATH}")
  endif()
  # for msvc could use ${MSVC_TOOLSET_VERSION} to convert to year and ${CMAKE_VS_PLATFORM_NAME} for arch but too much as also need qt version
  return(PROPAGATE CMAKE_PREFIX_PATH) 
endfunction()
