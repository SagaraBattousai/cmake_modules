# SPDX-License-Identifier: BSD-3-Clause
# Copyright © 2024-2026 James Calo

# TODO: Do it properly later but fornow well just print the formatted hex so we can copy and paste

function(embed_file_as_macro file_path ouput_path macro_name)

  set(options "")
  set(oneValueArgs HEADER_GUARD)
  set(multiValueArgs "")

  # args as prefix is apparantly a good/correct choice according to cmake docs so ...
  cmake_parse_arguments(PARSE_ARGV 3 args "${options}" "${oneValueArgs}"
                        "${multiValueArgs}")

  # Set HEADER_GUARD argument
  if(NOT DEFINED args_HEADER_GUARD)
    # No idea if this regex is correct (Trying to catch all at end, bit iffy but....)
    string(REGEX REPLACE 
      "([A-Za-z0-9_]*)\\.([A-Za-z0-9_])([A-Za-z0-9\\._\\-]*)" "__\\1_\\2__"
     args_HEADER_GUARD "${args_HEADER_GUARD}")

    string(TOUPPER "${args_HEADER_GUARD}" args_HEADER_GUARD)

    if(HEADER_GUARD IN_LIST args_KEYWORDS_MISSING_VALUES)
      func_call_text(args_FUNC_CALL_TEXT "embed_file_as_macro" "${ARGV}")
      message(
        WARNING "embed_file_as_macro called as:\n"
                "${args_FUNC_CALL_TEXT}\n"
                "HEADER_GUARD specified but not given an argument and will "
                "default to: ${args_HEADER_GUARD}")
    endif()
  endif()

  file(READ ${file_path} file_contents HEX)
  file(SIZE ${file_path} file_size)
  string(REGEX MATCHALL "[0-9a-f][0-9a-f]" hex_contents_list ${file_contents})


  # Counter to format code to 13 hex bytes per line
  set(current_hex_per_line 0)
  set(hex_read_so_far 0)
  set(byte_array "\n\t{")
  foreach(hex_byte IN LISTS hex_contents_list)
    # Could use math(EXPR ...) with output_format HEXADECIMAL ?
    string(APPEND byte_array "0x${hex_byte}")
    math(EXPR current_hex_per_line "${current_hex_per_line} + 1")
    math(EXPR hex_read_so_far "${hex_read_so_far} + 1")
    if (hex_read_so_far LESS file_size)
      string(APPEND byte_array ", ")
    endif()
    if (current_hex_per_line GREATER 12) # Change to greater equal 13 .....
      string(APPEND byte_array " \\\n\t")
      set(current_hex_per_line 0)
    endif()
  endforeach()

  message(STATUS "${file_size}")
  message(STATUS "${byte_array}")

endfunction()
