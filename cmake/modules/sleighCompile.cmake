#
# Copyright (c) 2022-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.18)

# Takes the following required arguments:
#
#   TARGET: Named CMake target for performing sleigh compilation
#   COMPILER: Path to sleigh compiler executable
#   SLASPEC: Path to slaspec file
#   LOG_FILE: File to write logs
#   OUT_FILE: Compiled sleigh output file (should be in build directory somewhere)
#
# NOTE: This doesn't track _all_ dependencies for the slaspec compilation due
# to the ability for slaspec files to include other files. If you want to
# rebuild the sleigh file then you must delete the OUT_FILE
function(sleigh_compile)
  set(options)
  set(oneValueArgs TARGET COMPILER SLASPEC LOG_FILE OUT_FILE)
  set(multiValueArgs)
  cmake_parse_arguments(parsed
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  # Sanity checking for caller
  if(parsed_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Bad arguments: ${parsed_UNPARSED_ARGUMENTS}")
  endif()
  if(parsed_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "Missing values for: ${parsed_KEYWORDS_MISSING_VALUES}")
  endif()

  # Setup variables for paths/filenames
  set(spec_file "${parsed_SLASPEC}")
  get_filename_component(spec_name "${spec_file}" NAME_WE)
  get_filename_component(spec_dir "${spec_file}" DIRECTORY)

  set(spec_build_log "${parsed_LOG_FILE}")
  get_filename_component(spec_build_log_dir "${spec_build_log}" DIRECTORY)

  set(spec_out "${parsed_OUT_FILE}")
  get_filename_component(spec_out_dir "${spec_out}" DIRECTORY)

  # Custom command to compile the sla file
  add_custom_command(
    OUTPUT "${spec_out}"
    MAIN_DEPENDENCY "${spec_file}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${spec_out_dir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${spec_build_log_dir}"
    COMMAND "${parsed_COMPILER}" ${spec_file} "${spec_out}" > "${spec_build_log}" 2>&1
    WORKING_DIRECTORY "${spec_dir}"
    COMMENT "sleigh: Compiling the '${spec_name}' spec file (logs written in '${spec_build_log}')"
    BYPRODUCTS "${spec_build_log}"
    VERBATIM
  )

  # Custom target for others to depend on
  add_custom_target(${parsed_TARGET} DEPENDS "${spec_out}")
endfunction()
