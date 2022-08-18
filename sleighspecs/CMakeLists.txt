#
# Copyright (c) 2022-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.18)

include(../cmake/prelude.cmake)
include(../src/setup-ghidra-source.cmake)

project(sleigh_specs
    VERSION "${ghidra_version}"
    DESCRIPTION "Sleigh specifications"
    HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
    # Language is for installing the helper CMake file
    LANGUAGES CXX
)

include(../cmake/project-is-top-level.cmake)

# This is the root directory where all individual processor spec file directories will be created.
if(NOT DEFINED spec_files_build_dir)
  set(spec_files_build_dir "${CMAKE_CURRENT_BINARY_DIR}/specfiles")
endif()

# This prefix should match the Ghidra repo to where the sla spec files are located
set(spec_files_dir_prefix "Ghidra/Processors")

# This is where we will be copying the generated artifacts for each processor
set(spec_files_root_dir "${spec_files_build_dir}/${spec_files_dir_prefix}")
set(spec_files_build_log_dir "${CMAKE_CURRENT_BINARY_DIR}/spec_build_logs")

add_custom_command(
  OUTPUT "${spec_files_build_log_dir}"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${spec_files_build_log_dir}"
)

# Get the native machine's sleigh compiler or use the one we're about to build
# if not cross compiling
if(CMAKE_CROSSCOMPILING)
  find_program(
    SLEIGH_EXECUTABLE sleigh
    DOC "Path to host system sleigh compiler"
    REQUIRED
  )
else()
  # Try to find/acquire or bootstrap the sleigh spec compiler
  # Logic is repeated in example/CMakeLists.txt
  if(NOT TARGET sleigh::sleigh)
    find_package(sleigh QUIET)
    if(NOT sleigh_FOUND OR NOT TARGET sleigh::sleigh)
      find_program(
        SLEIGH_EXECUTABLE sleigh
        DOC "Path to host system sleigh compiler"
      )
      if(NOT SLEIGH_EXECUTABLE)
        message(WARNING "Could not find sleigh compiler, building from source")
        set(saved_skip_install_rules "${CMAKE_SKIP_INSTALL_RULES}")
        set(CMAKE_SKIP_INSTALL_RULES TRUE)
        add_subdirectory(../tools/spec-compiler spec-compiler EXCLUDE_FROM_ALL)
        set(CMAKE_SKIP_INSTALL_RULES "${saved_skip_install_rules}")
      endif()
    endif()
  endif()
endif()
if(SLEIGH_EXECUTABLE)
  set(sleigh_compiler "${SLEIGH_EXECUTABLE}")
else()
  set(sleigh_compiler "$<TARGET_FILE:sleigh::sleigh>")
endif()

# Start processing all `.slaspec` files individually
set(spec_targets)
set(spec_files)
set(spec_dirs)
include(../cmake/modules/sleighCompile.cmake)

# Example: '<ghidra_source_prefix>/Ghidra/Processors/8051/data/languages/mx51.slaspec'
foreach(spec_file ${spec_file_list})
  # Get 'mx51'
  get_filename_component(spec_name "${spec_file}" NAME_WLE)

  # Get '<ghidra_source_prefix>/Ghidra/Processors/8051/data/languages'
  get_filename_component(spec_dir "${spec_file}" DIRECTORY)

  # Get '8051/data/languages'
  file(RELATIVE_PATH spec_proc_dir
    "${ghidrasource_SOURCE_DIR}/${spec_files_dir_prefix}"
    "${spec_dir}"
  )

  # Add relative spec processor directory for later processing
  list(APPEND spec_dirs ${spec_proc_dir})

  # Get '8051'
  get_filename_component(proc_name "${spec_proc_dir}" DIRECTORY)
  get_filename_component(proc_name "${proc_name}" DIRECTORY)

  set(spec_build_log "${spec_files_build_log_dir}/${spec_name}_build.log")

  # Combine back again for the build directory output like
  # '<build_prefix>/Ghidra/Processors/8051/data/languages'
  set(spec_out_dir "${spec_files_root_dir}/${spec_proc_dir}")

  # '<build_prefix>/Ghidra/Processors/8051/data/languages/mx51.sla'
  set(spec_out "${spec_out_dir}/${spec_name}.sla")

  string(REPLACE "." "_" spec_target_name ${spec_name})
  set(spec_target "sleigh_spec_${spec_target_name}")

  # Compile the sla file
  sleigh_compile(
    TARGET "${spec_target}"
    COMPILER "${sleigh_compiler}"
    SLASPEC "${spec_file}"
    LOG_FILE "${spec_build_log}"
    OUT_FILE "${spec_out}"
  )
  add_dependencies(${spec_target} sleigh_copy_${proc_name}_dir)

  list(APPEND spec_targets ${spec_target})
  list(APPEND spec_files ${spec_out})
endforeach()

# Copy and create specfile directories
list(REMOVE_DUPLICATES spec_dirs)

foreach(spec_dir ${spec_dirs})
  set(spec_src_dir "${ghidrasource_SOURCE_DIR}/${spec_files_dir_prefix}/${spec_dir}")
  set(spec_out_dir "${spec_files_root_dir}/${spec_dir}")

  # Get the processor directory name
  get_filename_component(proc_name "${spec_dir}" DIRECTORY)
  get_filename_component(proc_name "${proc_name}" DIRECTORY)

  # Copy all other files from the slaspec source directory:
  # '<ghidra_source_prefix>/Ghidra/Processors/8051/data/languages'
  # NOTE: This only copies the directory once, so you will need to remove the
  # whole directory if you update any of the other files, like '*.cspec' or
  # '*.ldef' files
  # CMake only guarantees update monitoring for files listed explicitly
  add_custom_command(
    OUTPUT "${spec_out_dir}"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${spec_src_dir}" "${spec_out_dir}"
  )
  add_custom_target(sleigh_copy_${proc_name}_dir
    DEPENDS "${spec_out_dir}"
  )
endforeach()

# All of the sla spec targets are combined into this one
add_custom_target(sleigh_all_sla_specs ALL DEPENDS
  ${spec_targets}
)

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(GNUInstallDirs)

  # Specfiles installation setup
  set(sleigh_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/sleigh"
    CACHE PATH "sleigh data installation location relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_DATADIR)

  set(sleigh_INSTALL_SPECDIR "${sleigh_INSTALL_DATADIR}/specfiles"
    CACHE PATH "sleigh specfile root destination relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_SPECDIR)

  # Install the compiled sla files found in 'Ghidra' top-level directory
  install(
    DIRECTORY "${spec_files_build_dir}/"
    DESTINATION "${sleigh_INSTALL_SPECDIR}"
    COMPONENT sleigh_Runtime
  )

  set(
    sleigh_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/sleigh"
    CACHE PATH "CMake package config location relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_CMAKEDIR)

  include(CMakePackageConfigHelpers)
  configure_package_config_file(specfiles.cmake.in
    "${PROJECT_BINARY_DIR}/specfiles.cmake"
    INSTALL_DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
    PATH_VARS sleigh_INSTALL_SPECDIR
  )

  install(
    FILES "${PROJECT_BINARY_DIR}/specfiles.cmake"
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    COMPONENT sleigh_Development
  )

  if(PROJECT_IS_TOP_LEVEL)
    include(CPack)
  endif()
endif()
