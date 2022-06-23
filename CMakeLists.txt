#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.15)

# Sets "library_root" variable for decompiler cpp root directory
# Sets "ghidra_version" for numeric version number
# Use "ghidrasource_SOURCE_DIR" variable for Ghidra repo root
include(src/setup-ghidra-source.cmake)
set(sleigh_RELEASE_IS_HEAD FALSE)
if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
  set(sleigh_RELEASE_IS_HEAD TRUE)
endif()

project("sleigh"
  VERSION "${ghidra_version}"
)

include("cmake/options.cmake")

if(sleigh_ENABLE_TESTS)
  include("CTest")
endif()

if(sleigh_ENABLE_PACKAGING)
  include("cmake/packaging.cmake")

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(WARNING "sleigh: Packaging a Debug version")
  endif()
endif()

set(public_include_header_list
  "${PROJECT_SOURCE_DIR}/include/libsleigh.hh"
  "${PROJECT_SOURCE_DIR}/support/Support.h"
  "${PROJECT_SOURCE_DIR}/support/Version.h"

  "${library_root}/action.hh"
  "${library_root}/address.hh"
  "${library_root}/architecture.hh"
  "${library_root}/block.hh"
  "${library_root}/blockaction.hh"
  "${library_root}/callgraph.hh"
  "${library_root}/capability.hh"
  "${library_root}/cast.hh"
  "${library_root}/codedata.hh"
  "${library_root}/comment.hh"
  "${library_root}/comment_ghidra.hh"
  "${library_root}/condexe.hh"
  "${library_root}/context.hh"
  "${library_root}/coreaction.hh"
  "${library_root}/cover.hh"
  "${library_root}/cpool.hh"
  "${library_root}/cpool_ghidra.hh"
  "${library_root}/crc32.hh"
  "${library_root}/database.hh"
  "${library_root}/database_ghidra.hh"
  "${library_root}/doccore.hh"
  "${library_root}/docmain.hh"
  "${library_root}/double.hh"
  "${library_root}/dynamic.hh"
  "${library_root}/emulate.hh"
  "${library_root}/emulateutil.hh"
  "${library_root}/error.hh"
  "${library_root}/filemanage.hh"
  "${library_root}/float.hh"
  "${library_root}/flow.hh"
  "${library_root}/fspec.hh"
  "${library_root}/funcdata.hh"
  "${library_root}/ghidra_arch.hh"
  "${library_root}/ghidra_context.hh"
  "${library_root}/ghidra_process.hh"
  "${library_root}/ghidra_translate.hh"
  "${library_root}/globalcontext.hh"
  "${library_root}/grammar.hh"
  "${library_root}/graph.hh"
  "${library_root}/heritage.hh"
  "${library_root}/ifacedecomp.hh"
  "${library_root}/ifaceterm.hh"
  "${library_root}/inject_ghidra.hh"
  "${library_root}/inject_sleigh.hh"
  "${library_root}/interface.hh"
  "${library_root}/jumptable.hh"
  "${library_root}/libdecomp.hh"
  "${library_root}/loadimage.hh"
  "${library_root}/loadimage_ghidra.hh"
  "${library_root}/loadimage_xml.hh"
  "${library_root}/memstate.hh"
  "${library_root}/merge.hh"
  "${library_root}/op.hh"
  "${library_root}/opbehavior.hh"
  "${library_root}/opcodes.hh"
  "${library_root}/options.hh"
  "${library_root}/override.hh"
  "${library_root}/paramid.hh"
  "${library_root}/partmap.hh"
  "${library_root}/pcodecompile.hh"
  "${library_root}/pcodeinject.hh"
  "${library_root}/pcodeparse.hh"
  "${library_root}/pcoderaw.hh"
  "${library_root}/prefersplit.hh"
  "${library_root}/prettyprint.hh"
  "${library_root}/printc.hh"
  "${library_root}/printjava.hh"
  "${library_root}/printlanguage.hh"
  "${library_root}/rangemap.hh"
  "${library_root}/rangeutil.hh"
  "${library_root}/raw_arch.hh"
  "${library_root}/ruleaction.hh"
  "${library_root}/rulecompile.hh"
  "${library_root}/semantics.hh"
  "${library_root}/sleigh.hh"
  "${library_root}/sleigh_arch.hh"
  "${library_root}/sleighbase.hh"
  "${library_root}/slgh_compile.hh"
  "${library_root}/slghparse.hh"
  "${library_root}/slghpatexpress.hh"
  "${library_root}/slghpattern.hh"
  "${library_root}/slghsymbol.hh"
  "${library_root}/space.hh"
  "${library_root}/string_ghidra.hh"
  "${library_root}/stringmanage.hh"
  "${library_root}/subflow.hh"
  "${library_root}/testfunction.hh"
  "${library_root}/transform.hh"
  "${library_root}/translate.hh"
  "${library_root}/type.hh"
  "${library_root}/typegrp_ghidra.hh"
  "${library_root}/typeop.hh"
  "${library_root}/types.h"
  "${library_root}/unify.hh"
  "${library_root}/userop.hh"
  "${library_root}/variable.hh"
  "${library_root}/varmap.hh"
  "${library_root}/varnode.hh"
  "${library_root}/xml.hh"
  "${library_root}/xml_arch.hh"
)
if(sleigh_RELEASE_IS_HEAD)
  list(APPEND public_include_header_list
    "${library_root}/unionresolve.hh"
    "${library_root}/marshal.hh"
  )
endif()
# Create custom target so that IDEs know these files are part of the sources
add_custom_target(sleigh_all_headers SOURCES ${public_include_header_list})
set(public_headers_dir ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY "${public_headers_dir}/sleigh")
configure_file(cmake/libconfig.h.in include/sleigh/libconfig.h)
# Copy the public headers into our build directory so that we can control the layout.
# Ideally, we want to let people '#include <sleigh/{header}>' without installing sleigh
foreach(public_header ${public_include_header_list})
  configure_file("${public_header}" "${public_headers_dir}/sleigh" COPYONLY)
endforeach()

set(sleigh_core_source_list
  "${library_root}/xml.cc"
  "${library_root}/space.cc"
  "${library_root}/float.cc"
  "${library_root}/address.cc"
  "${library_root}/pcoderaw.cc"
  "${library_root}/translate.cc"
  "${library_root}/opcodes.cc"
  "${library_root}/globalcontext.cc"
)
if(sleigh_RELEASE_IS_HEAD)
  list(APPEND sleigh_core_source_list
    "${library_root}/marshal.cc"
  )
endif()

set(sleigh_deccore_source_list
  "${library_root}/capability.cc"
  "${library_root}/architecture.cc"
  "${library_root}/options.cc"
  "${library_root}/graph.cc"
  "${library_root}/cover.cc"
  "${library_root}/block.cc"
  "${library_root}/cast.cc"
  "${library_root}/typeop.cc"
  "${library_root}/database.cc"
  "${library_root}/cpool.cc"
  "${library_root}/comment.cc"
  "${library_root}/stringmanage.cc"
  "${library_root}/fspec.cc"
  "${library_root}/action.cc"
  "${library_root}/loadimage.cc"
  "${library_root}/grammar.cc"
  "${library_root}/varnode.cc"
  "${library_root}/op.cc"
  "${library_root}/type.cc"
  "${library_root}/variable.cc"
  "${library_root}/varmap.cc"
  "${library_root}/jumptable.cc"
  "${library_root}/emulate.cc"
  "${library_root}/emulateutil.cc"
  "${library_root}/flow.cc"
  "${library_root}/userop.cc"
  "${library_root}/funcdata.cc"
  "${library_root}/funcdata_block.cc"
  "${library_root}/funcdata_op.cc"
  "${library_root}/funcdata_varnode.cc"
  "${library_root}/pcodeinject.cc"
  "${library_root}/heritage.cc"
  "${library_root}/prefersplit.cc"
  "${library_root}/rangeutil.cc"
  "${library_root}/ruleaction.cc"
  "${library_root}/subflow.cc"
  "${library_root}/blockaction.cc"
  "${library_root}/merge.cc"
  "${library_root}/double.cc"
  "${library_root}/transform.cc"
  "${library_root}/coreaction.cc"
  "${library_root}/condexe.cc"
  "${library_root}/override.cc"
  "${library_root}/dynamic.cc"
  "${library_root}/crc32.cc"
  "${library_root}/prettyprint.cc"
  "${library_root}/printlanguage.cc"
  "${library_root}/printc.cc"
  "${library_root}/printjava.cc"
  "${library_root}/memstate.cc"
  "${library_root}/opbehavior.cc"
  "${library_root}/paramid.cc"
)
if(sleigh_RELEASE_IS_HEAD)
  list(APPEND sleigh_deccore_source_list
    "${library_root}/unionresolve.cc"
  )
endif()

set(sleigh_extra_source_list
  "${library_root}/callgraph.cc"
  "${library_root}/ifacedecomp.cc"
  "${library_root}/ifaceterm.cc"
  "${library_root}/inject_sleigh.cc"
  "${library_root}/interface.cc"
  "${library_root}/libdecomp.cc"
  "${library_root}/loadimage_xml.cc"
  "${library_root}/raw_arch.cc"
  "${library_root}/rulecompile.cc"
  "${library_root}/sleigh_arch.cc"
  "${library_root}/testfunction.cc"
  "${library_root}/unify.cc"
  "${library_root}/xml_arch.cc"
)

set(sleigh_source_list
  "${library_root}/sleigh.cc"
  "${library_root}/pcodeparse.cc"
  "${library_root}/pcodecompile.cc"
  "${library_root}/sleighbase.cc"
  "${library_root}/slghsymbol.cc"
  "${library_root}/slghpatexpress.cc"
  "${library_root}/slghpattern.cc"
  "${library_root}/semantics.cc"
  "${library_root}/context.cc"
  "${library_root}/filemanage.cc"
)

set(sleigh_ghidra_source_list
  "${library_root}/ghidra_arch.cc"
  "${library_root}/inject_ghidra.cc"
  "${library_root}/ghidra_translate.cc"
  "${library_root}/loadimage_ghidra.cc"
  "${library_root}/typegrp_ghidra.cc"
  "${library_root}/database_ghidra.cc"
  "${library_root}/ghidra_context.cc"
  "${library_root}/cpool_ghidra.cc"
  "${library_root}/ghidra_process.cc"
  "${library_root}/comment_ghidra.cc"
  "${library_root}/string_ghidra.cc"
)

set(sleigh_slacomp_source_list
  "${library_root}/slgh_compile.cc"
  "${library_root}/slghparse.cc"
  "${library_root}/slghscan.cc"
)

#
# sleigh settings
#
add_library(sleigh_settings INTERFACE)
add_library(sleigh::sleigh_settings ALIAS sleigh_settings)

target_compile_features(sleigh_settings INTERFACE
  cxx_std_11
)

set(sleigh_SPEC_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/share/sleigh/specfiles/")
set(sleigh_SPEC_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/specfiles/")

set_target_properties(sleigh_settings PROPERTIES
  INTERFACE_POSITION_INDEPENDENT_CODE ON
)

if(sleigh_ENABLE_SANITIZERS)
  message(STATUS "sleigh: Sanitizers have been enabled")

  if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(WARNING "sleigh: Debug builds are preferred when sanitizers are enabled")
  endif()

  set(flag_list
    -fno-omit-frame-pointer -fsanitize=undefined,address
  )

  target_compile_options(sleigh_settings INTERFACE ${flag_list})
  target_link_options(sleigh_settings INTERFACE ${flag_list})
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(debug_setting_list
    OPACTION_DEBUG
    MERGEMULTI_DEBUG
    BLOCKCONSISTENT_DEBUG
    DFSVERIFY_DEBUG
  )

  foreach(debug_setting ${debug_setting_list})
    if(NOT sleigh_${debug_setting})
      continue()
    endif()

    message(STATUS "sleigh: Enabling debug setting: sleigh_${debug_setting}")

    target_compile_definitions(sleigh_settings INTERFACE
      ${debug_setting}
    )
  endforeach()
endif()

set(internal_setting_list
  CPUI_STATISTICS
  CPUI_RULECOMPILE
)

foreach(internal_setting ${internal_setting_list})
  if(NOT sleigh_${internal_setting})
    continue()
  endif()

  message(STATUS "sleigh: Enabling internal setting: sleigh_${internal_setting}")

  target_compile_definitions(sleigh_settings INTERFACE
    ${internal_setting}
  )
endforeach()

#
# decomp_opt, decomp_dbg
#
add_executable(decomp_opt
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_extra_source_list}
  ${sleigh_source_list}

  "${library_root}/consolemain.cc"
)
add_executable(sleigh::decomp_opt ALIAS decomp_opt)

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  target_compile_definitions(decomp_opt PRIVATE
    __TERMINAL__
  )
endif()

target_link_libraries(decomp_opt PRIVATE
  sleigh::sleigh_settings
)
target_include_directories(decomp_opt PRIVATE $<BUILD_INTERFACE:${library_root}>)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_definitions(decomp_opt PRIVATE
    CPUI_DEBUG
  )

  set_target_properties(decomp_opt PROPERTIES
    OUTPUT_NAME "decomp_dbg"
  )
endif()

#
# ghidra_test_dbg
#
if(sleigh_ENABLE_TESTS)
  add_executable(ghidra_test_dbg
    ${sleigh_core_source_list}
    ${sleigh_deccore_source_list}
    ${sleigh_source_list}
    ${sleigh_extra_source_list}

    "${library_root}/test.cc"

    "${library_root}/../unittests/testcirclerange.cc"
    "${library_root}/../unittests/testfloatemu.cc"
    "${library_root}/../unittests/testtypes.cc"
  )

  target_link_libraries(ghidra_test_dbg PRIVATE
    sleigh::sleigh_settings
  )
  target_include_directories(ghidra_test_dbg PRIVATE $<BUILD_INTERFACE:${library_root}>)

  if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    target_compile_definitions(ghidra_test_dbg PRIVATE
      __TERMINAL__
    )
  endif()

  add_test(
    NAME ghidra_unittest_dbg
    COMMAND ghidra_test_dbg -sleighpath "${CMAKE_CURRENT_BINARY_DIR}" unittests
  )

  add_test(
    NAME ghidra_datatest_dbg
    COMMAND ghidra_test_dbg -sleighpath "${CMAKE_CURRENT_BINARY_DIR}"
    -path "${ghidrasource_SOURCE_DIR}/Ghidra/Features/Decompiler/src/decompile/datatests"
    datatests
  )
endif()

#
# ghidra_opt, ghidra_dbg
#
add_executable(ghidra_opt
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_ghidra_source_list}
)
add_executable(sleigh::ghidra_opt ALIAS ghidra_opt)

target_link_libraries(ghidra_opt PRIVATE
  sleigh::sleigh_settings
)
target_include_directories(ghidra_opt PRIVATE $<BUILD_INTERFACE:${library_root}>)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_sources(ghidra_opt PRIVATE
    "${library_root}/callgraph.cc"
    "${library_root}/ifacedecomp.cc"
    "${library_root}/ifaceterm.cc"
    "${library_root}/interface.cc"
    "${library_root}/testfunction.cc"
  )

  target_compile_definitions(ghidra_opt PRIVATE
    CPUI_DEBUG
  )

  set_target_properties(ghidra_opt PROPERTIES
    OUTPUT_NAME "ghidra_dbg"
  )
endif()

#
# sleigh_opt, sleigh_dbg
#
add_executable(sleigh_opt
  ${sleigh_core_source_list}
  ${sleigh_source_list}
  ${sleigh_slacomp_source_list}
)
add_executable(sleigh::sleigh_opt ALIAS sleigh_opt)

target_link_libraries(sleigh_opt PRIVATE
  sleigh::sleigh_settings
)
target_include_directories(sleigh_opt PRIVATE $<BUILD_INTERFACE:${library_root}>)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set_target_properties(sleigh_opt PROPERTIES
    OUTPUT_NAME "sleigh_dbg"
  )
endif()

#
# sla, sla_dbg
#
add_library(sla
  ${sleigh_core_source_list}
  ${sleigh_source_list}

  "${library_root}/loadimage.cc"
  "${library_root}/sleigh.cc"
  "${library_root}/memstate.cc"
  "${library_root}/emulate.cc"
  "${library_root}/opbehavior.cc"
)
add_library(sleigh::sla ALIAS sla)

target_link_libraries(sla PUBLIC
  sleigh::sleigh_settings
)

# Private include search path '#include "..."
target_include_directories(sla PRIVATE $<BUILD_INTERFACE:${library_root}>)

# Public include search path in build directory
target_include_directories(
  sla SYSTEM
  INTERFACE $<BUILD_INTERFACE:${public_headers_dir}>
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_definitions(sla PRIVATE
    YYDEBUG
  )

  set_target_properties(sla PROPERTIES
    OUTPUT_NAME "sla_dbg"
  )
endif()

#
# decomp, decomp_dbg
#
add_library(decomp
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_extra_source_list}
  ${sleigh_source_list}
)
add_library(sleigh::decomp ALIAS decomp)

target_link_libraries(decomp PUBLIC
  sleigh::sleigh_settings
)

# Private include search path '#include "..."
target_include_directories(decomp PRIVATE $<BUILD_INTERFACE:${library_root}>)

# Public include search path in build directory
target_include_directories(
  decomp SYSTEM
  INTERFACE $<BUILD_INTERFACE:${public_headers_dir}>
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set_target_properties(decomp PROPERTIES
    OUTPUT_NAME "decomp_dbg"
  )
endif()

#
# Documentation
#
if(sleigh_ENABLE_DOCUMENTATION)
  message(STATUS "sleigh: Documentation has been enabled")

  find_package(Doxygen REQUIRED COMPONENTS dot)

  set(documentation_output "${CMAKE_CURRENT_BINARY_DIR}/doc")

  # Always run this target because we have no source file tracking for incremental builds
  add_custom_target(sleigh_documentation
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${library_root}/../doc" "${documentation_output}"
    COMMAND Doxygen::doxygen Doxyfile
    COMMAND "${CMAKE_COMMAND}" -E copy_directory "${library_root}/../doc" "${documentation_output}"
    COMMENT "sleigh: Generating the Doxygen documentation"
    WORKING_DIRECTORY "${library_root}"
    VERBATIM
  )
endif()

#
# Spec files
#
# Sets 'spec_file_list' variable
if(sleigh_RELEASE_IS_HEAD)
  include(spec-files-list/spec_files_HEAD.cmake)
else()
  include(spec-files-list/spec_files_stable.cmake)
endif()

# This prefix should match the Ghidra repo to where the sla spec files are located
set(spec_files_dir_prefix Ghidra/Processors)

# This is the root directory where all individual processor spec file directories will be created
set(spec_files_build_dir "${CMAKE_CURRENT_BINARY_DIR}/specfiles")

# This is where we will be copying the generated artifacts for each processor
set(spec_files_root_dir "${spec_files_build_dir}/${spec_files_dir_prefix}")
set(spec_files_build_log_dir ${CMAKE_CURRENT_BINARY_DIR}/spec_build_logs)

add_custom_command(
  OUTPUT ${spec_files_build_log_dir}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${spec_files_build_log_dir}
)

# Start processing all `.slaspec` files individually
set(spec_targets)
set(spec_files)
set(spec_dirs)
include(cmake/modules/sleighCompile.cmake)

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
    COMPILER "$<TARGET_FILE:sleigh::sleigh_opt>"
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

#
# Examples
#
if(sleigh_ENABLE_EXAMPLES)
  add_executable(sleighexample
    "${library_root}/sleighexample.cc"
  )

  target_link_libraries(sleighexample PRIVATE
    sleigh::sla
    sleigh::decomp
  )

  add_custom_target(sleighexample_runner
    "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/specfiles"
    COMMAND "${CMAKE_COMMAND}" -E create_symlink "${spec_files_root_dir}/x86/data/languages/x86.sla" "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla"
    COMMAND sleighexample disassemble
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  )

  add_dependencies(
    sleighexample_runner
    sleigh_spec_x86
  )
endif()

# Add support library before configuring install targets
add_subdirectory(support)

#
# Install targets
#
if(NOT CMAKE_SKIP_INSTALL_RULES)
  include("GNUInstallDirs")

  install(
    TARGETS
    sleigh_settings

    sla
    decomp
    support

    decomp_opt
    ghidra_opt
    sleigh_opt

    EXPORT
    sleighTargets

    INCLUDES DESTINATION
    ${CMAKE_INSTALL_INCLUDEDIR}
  )

  install(
    DIRECTORY
      "${CMAKE_CURRENT_BINARY_DIR}/include/"

    DESTINATION
    ${CMAKE_INSTALL_INCLUDEDIR}
  )

  # Install the compiled sla files found in 'Ghidra' top-level directory
  install(
    DIRECTORY
    "${spec_files_build_dir}"

    DESTINATION
    "${CMAKE_INSTALL_DATADIR}/sleigh"
  )

  set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_DATAROOTDIR}/doc/sleigh")

  if(sleigh_ENABLE_DOCUMENTATION)
    # Build docs during install
    install(CODE
      "execute_process(
        COMMAND \"${CMAKE_COMMAND}\" --build \"${CMAKE_BINARY_DIR}\" --target sleigh_documentation
        COMMAND_ECHO STDOUT
      )"
    )
    install(
      DIRECTORY
      "${documentation_output}/html/"

      DESTINATION
      "${CMAKE_INSTALL_DOCDIR}"
    )
  endif(sleigh_ENABLE_DOCUMENTATION)

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(output_folder_path "${CMAKE_CURRENT_BINARY_DIR}/symlinks")

    add_custom_command(
      OUTPUT "${output_folder_path}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/symlinks"
      COMMENT "sleigh: Generating symlink folder"
      VERBATIM
    )

    add_custom_target(sleigh_symlinks_folder_builder DEPENDS
      "${output_folder_path}"
    )

    add_custom_target(sleigh_symlinks_builder ALL)

    foreach(target_name "decomp"
      "ghidra"
      "sleigh")
      set(source_name "${target_name}_dbg")
      set(destination_name "${target_name}_opt")
      set(output_path "${output_folder_path}/${destination_name}")

      add_custom_command(
        OUTPUT "${output_path}"
        COMMAND "${CMAKE_COMMAND}" -E create_symlink "${source_name}" "${destination_name}"
        WORKING_DIRECTORY "${output_folder_path}"
        COMMENT "sleigh: Generating executable symlink: ${source_name} -> ${destination_name}"
        VERBATIM
      )

      set(target_name "sleigh_${source_name}_symlink_builder")
      add_custom_target("${target_name}" DEPENDS
        "${output_path}"
      )

      add_dependencies("${target_name}"
        sleigh_symlinks_folder_builder
      )

      add_dependencies(sleigh_symlinks_builder
        "${target_name}"
      )

      install(
        FILES
        "${output_path}"

        DESTINATION
        "${CMAKE_INSTALL_BINDIR}"

        PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE
      )
    endforeach()
  endif()

  set(
    sleigh_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/sleigh"
    CACHE PATH "CMake package config location relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_CMAKEDIR)

  install(
    EXPORT sleighTargets
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    NAMESPACE sleigh::
  )

  # Specfiles installation setup
  set(
    sleigh_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/sleigh"
    CACHE PATH "sleigh data installation location relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_DATADIR)

  set(sleigh_INSTALL_SPECDIR "${sleigh_INSTALL_DATADIR}/specfiles"
    CACHE PATH "sleigh specfile root destination relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_SPECDIR)

  include(CMakePackageConfigHelpers)

  configure_package_config_file(cmake/install-config.cmake.in
    ${PROJECT_BINARY_DIR}/install-config.cmake
    INSTALL_DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
    PATH_VARS sleigh_INSTALL_SPECDIR
  )

  install(
    FILES ${PROJECT_BINARY_DIR}/install-config.cmake
    RENAME sleighConfig.cmake
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
  )

  install(
    FILES cmake/modules/sleighCompile.cmake
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}/modules"
  )
endif()

add_subdirectory(tools)
