cmake_minimum_required(VERSION 3.15)

# Takes the following required arguments:
#
#   TARGET: Named target for performing sleigh compilation
#   SLASPEC: Path to slaspec file
#   LOG_FILE: File to write logs
#   OUT_FILE: Output file (should be in build directory somewhere)
function(sleigh_compile)
  set(options)
  set(oneValueArgs TARGET SLASPEC LOG_FILE OUT_FILE)
  set(multiValueArgs)
  cmake_parse_arguments(parsed
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  if(parsed_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Bad arguments: ${parsed_UNPARSED_ARGUMENTS}")
  endif()
  if(parsed_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "Missing values for: ${parsed_KEYWORDS_MISSING_VALUES}")
  endif()


  set(spec_file "${parsed_SLASPEC}")
  set(spec_build_log "${parsed_LOG_FILE}")
  get_filename_component(spec_name "${spec_file}" NAME_WE)
  get_filename_component(spec_dir "${spec_file}" DIRECTORY)
  get_filename_component(spec_build_log_dir "${parsed_LOG_FILE}" DIRECTORY)
  set(spec_out "${parsed_OUT_FILE}")
  get_filename_component(spec_out_dir "${spec_out}" DIRECTORY)

  # Compile the sla file
  # NOTE: This doesn't have _all_ dependencies for the slaspec compilation due to the ability
  #  to include other files from the spec file
  add_custom_command(
    OUTPUT "${spec_out}"
    MAIN_DEPENDENCY "${spec_file}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${spec_out_dir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${spec_build_log_dir}"
    COMMAND "$<TARGET_FILE:sleigh::sleigh_opt>" ${spec_file} "${spec_out}" > ${spec_build_log} 2>&1
    WORKING_DIRECTORY "${spec_dir}"
    COMMENT "sleigh: Compiling the ${spec_name} spec file (logs written in ${spec_build_log})"
    BYPRODUCTS ${spec_build_log}
    VERBATIM
  )

  add_custom_target(${parsed_TARGET} DEPENDS ${spec_out})
endfunction()
