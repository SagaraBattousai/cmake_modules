# Unfortunatly this must be called in the directory where the target is defined
# so we can't get them all dynamically
#
# As post_build_copy_dlls_to_target only copies if the "target" is (re)built
# this creates a (pseudo)target that will always run and copy the dlls
#
# Could use copy_if_different but it's definatly safer to always copy! How big
# can dll's get?
function(copy_dlls_to_target target)
  # Assigning to variable to clean up COMMENT code below and to aid with
  # whitespace
  string(JOIN " " copy_comment "Copying the following dlls:"
         "[$<JOIN:$<PATH:GET_FILENAME,$<TARGET_RUNTIME_DLLS:${target}>>,, >]"
         "to $<TARGET_FILE_DIR:${target}>"
         "for Target: ${target}")

  # TODO: Is this the nicest name?
  set(COPY_DLL_TARGET_NAME "COPY_DLLS_FOR_${target}")

  add_custom_target(
    ${COPY_DLL_TARGET_NAME}
    COMMAND ${CMAKE_COMMAND} -E copy -t $<TARGET_FILE_DIR:${target}>
            $<TARGET_RUNTIME_DLLS:${target}>
    COMMENT ${copy_comment}
    COMMAND_EXPAND_LISTS)


  # Get dependant libraries (unfortunatly not only SHARED libs
  # but shouldn't be an issue)
  get_target_property(target_libraries ${target} LINK_LIBRARIES)

  # Ensure targets are built *before* the DLL's are copied
  add_dependencies(${COPY_DLL_TARGET_NAME} ${target_libraries})
  
  add_dependencies(${target} ${COPY_DLL_TARGET_NAME})

  # Store in separate folder
  set_target_properties(${COPY_DLL_TARGET_NAME}
                        PROPERTIES FOLDER "CmakeCopyDllsForTargets")

endfunction()

# Unfortunatly this must be called in the directory where the target is defined
# so we can't get them all dynamically
#
# Irritatingly if the "target" isn't (re)built then the (possibly) updated dll's
# aren't copied so use symlink_dlls_to_target
function(post_build_copy_dlls_to_target target)
  add_custom_command(
    TARGET ${target}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy -t $<TARGET_FILE_DIR:${target}>
            $<TARGET_RUNTIME_DLLS:${target}>
    COMMAND_EXPAND_LISTS)
endfunction()
