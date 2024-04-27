
#For MSVC this adds the object files corresponding to the "expected"
#Module implementation files and aids intelisense by providing
#module interface direcetories.
function(intelisense_modules target module_paths)
  
  if(NOT MSVC)
    message(WARNING "It is unadvisable to use this function when not using \
    MSVC as your generator since this function makes some assumptions based \
    on expecting the generator to be MSVC. Please be careful, it's dangerous \
    out there.")
  endif()

  get_target_property(src_files ${target} SOURCES)

  set(INTERMEDIATE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/${target}.dir/$<CONFIG>")


  set(impl_files ${src_files})
  list(FILTER impl_files EXCLUDE REGEX ".*\\.ixx$")
  list(FILTER src_files  INCLUDE REGEX ".*\\.ixx$")
  
  list(TRANSFORM src_files REPLACE "(.*/)*(.*)\\.ixx$" "\\2")

  #TODO: See if theres a cleverer and faster way but for now I don't have time
  foreach(impl IN LISTS impl_files)
    cmake_path(GET impl STEM impl_stem)
    list(REMOVE_ITEM src_files ${impl_stem})
  endforeach()

  # Prebuild the dir may not exist but at least it wont override 
  # existing obj files by accident :)
  add_custom_command(TARGET ${target} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E touch ${src_files}
    COMMENT "Adding pseudo object files for MSVC's build system"
    )

  # Add module dir to help intelisense. Irritatingly it's global
  # but it works well and I think it's better than target_sources 
  # which didn't seem to work, possibly as they were somewhat already added.
  cmake_path(CONVERT ${module_paths} TO_NATIVE_PATH_LIST 
    native_module_paths NORMALIZE)

  set_target_properties(${target} PROPERTIES 
    VS_GLOBAL_PublicModuleDirectories 
    "${native_module_paths};$(PublicModuleDirectories)")

endfunction()
