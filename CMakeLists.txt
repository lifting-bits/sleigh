#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.15)

include(cmake/prelude.cmake)

# Sets "library_root" variable for decompiler cpp root directory
# Sets "ghidra_version" for numeric version number
# Use "ghidrasource_SOURCE_DIR" variable for Ghidra repo root
include(src/setup-ghidra-source.cmake)

project(sleigh
  VERSION "${ghidra_version}"
  DESCRIPTION "Unofficial CMake build for Ghidra SLEIGH"
  HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
  LANGUAGES CXX
)

include(cmake/project-is-top-level.cmake)
include(cmake/options.cmake)

set(public_include_header_list
  "${library_root}/address.hh"
  "${library_root}/context.hh"
  "${library_root}/emulate.hh"
  "${library_root}/error.hh"
  "${library_root}/float.hh"
  "${library_root}/globalcontext.hh"
  "${library_root}/loadimage.hh"
  "${library_root}/memstate.hh"
  "${library_root}/opbehavior.hh"
  "${library_root}/opcodes.hh"
  "${library_root}/partmap.hh"
  "${library_root}/pcoderaw.hh"
  "${library_root}/semantics.hh"
  "${library_root}/sleigh.hh"
  "${library_root}/sleighbase.hh"
  "${library_root}/slghpatexpress.hh"
  "${library_root}/slghpattern.hh"
  "${library_root}/slghsymbol.hh"
  "${library_root}/space.hh"
  "${library_root}/translate.hh"
  "${library_root}/types.h"
  "${library_root}/xml.hh"
)
# Create custom target so that IDEs know these files are part of the sources
add_custom_target(sleigh_all_headers SOURCES ${public_include_header_list})
set(public_headers_dir ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY "${public_headers_dir}/sleigh")
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
if("${sleigh_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
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
# decomp
#

add_executable(sleigh_decompiler
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_extra_source_list}
  ${sleigh_source_list}

  "${library_root}/consolemain.cc"
)
add_executable(sleigh::decompiler ALIAS sleigh_decompiler)

target_compile_features(sleigh_decompiler PUBLIC cxx_std_11)
target_include_directories(sleigh_decompiler PRIVATE "$<BUILD_INTERFACE:${library_root}>")
if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  target_compile_definitions(sleigh_decompiler PRIVATE
    __TERMINAL__
  )
endif()
target_compile_definitions(sleigh_decompiler PRIVATE
  $<$<CONFIG:Debug>:CPUI_DEBUG>
)
sleigh_add_optional_defines(sleigh_decompiler PRIVATE)

set_target_properties(sleigh_decompiler PROPERTIES
  EXPORT_NAME decompiler
  OUTPUT_NAME decomp
  OUTPUT_NAME_DEBUG decomp_dbg
)

#
# ghidra
#

add_executable(sleigh_ghidra
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_ghidra_source_list}

  "$<$<CONFIG:Debug>:${library_root}/callgraph.cc>"
  "$<$<CONFIG:Debug>:${library_root}/ifacedecomp.cc>"
  "$<$<CONFIG:Debug>:${library_root}/ifaceterm.cc>"
  "$<$<CONFIG:Debug>:${library_root}/interface.cc>"
  "$<$<CONFIG:Debug>:${library_root}/testfunction.cc>"
)
add_executable(sleigh::ghidra ALIAS sleigh_ghidra)

target_compile_features(sleigh_ghidra PUBLIC cxx_std_11)
target_include_directories(sleigh_ghidra PRIVATE "$<BUILD_INTERFACE:${library_root}>")
target_compile_definitions(sleigh_ghidra PRIVATE
  $<$<CONFIG:Debug>:CPUI_DEBUG>
)
sleigh_add_optional_defines(sleigh_ghidra PRIVATE)

set_target_properties(sleigh_ghidra PROPERTIES
  EXPORT_NAME ghidra
  OUTPUT_NAME ghidra
  OUTPUT_NAME_DEBUG ghidra_dbg
)

#
# sleigh
#

add_executable(sleigh_sleigh
  ${sleigh_core_source_list}
  ${sleigh_source_list}
  ${sleigh_slacomp_source_list}
)
add_executable(sleigh::sleigh ALIAS sleigh_sleigh)

target_compile_features(sleigh_sleigh PUBLIC cxx_std_11)
target_include_directories(sleigh_sleigh PRIVATE "$<BUILD_INTERFACE:${library_root}>")
sleigh_add_optional_defines(sleigh_sleigh PRIVATE)
set_target_properties(sleigh_sleigh PROPERTIES
  EXPORT_NAME sleigh
  OUTPUT_NAME sleigh
  OUTPUT_NAME_DEBUG sleigh_dbg
)

#
# sla
#

add_library(sleigh_sla
  ${sleigh_core_source_list}
  ${sleigh_source_list}

  "${library_root}/loadimage.cc"
  "${library_root}/sleigh.cc"
  "${library_root}/memstate.cc"
  "${library_root}/emulate.cc"
  "${library_root}/opbehavior.cc"
)
add_library(sleigh::sla ALIAS sleigh_sla)

target_compile_features(sleigh_sla PUBLIC cxx_std_11)
# Private include search path '#include "..."
target_include_directories(sleigh_sla PRIVATE "$<BUILD_INTERFACE:${library_root}>")
# Public include search path in build directory
target_include_directories(
  sleigh_sla SYSTEM
  INTERFACE "$<BUILD_INTERFACE:${public_headers_dir}>"
)
target_compile_definitions(sleigh_sla PRIVATE "$<$<CONFIG:Debug>:YYDEBUG>")
sleigh_add_optional_defines(sleigh_sla PUBLIC)

set_target_properties(sleigh_sla PROPERTIES
  EXPORT_NAME sla
  OUTPUT_NAME sla
  OUTPUT_NAME_DEBUG sla_dbg
)

#
# decomp
#

add_library(sleigh_decomp
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_extra_source_list}
  ${sleigh_source_list}
)
add_library(sleigh::decomp ALIAS sleigh_decomp)

target_compile_features(sleigh_decomp PUBLIC cxx_std_11)
# Private include search path '#include "..."
target_include_directories(sleigh_decomp PRIVATE "$<BUILD_INTERFACE:${library_root}>")
# Public include search path in build directory
target_include_directories(
  sleigh_decomp SYSTEM
  INTERFACE "$<BUILD_INTERFACE:${public_headers_dir}>"
)
sleigh_add_optional_defines(sleigh_decomp PUBLIC)

set_target_properties(sleigh_decomp PROPERTIES
  EXPORT_NAME decomp
  OUTPUT_NAME decomp
  OUTPUT_NAME_DEBUG decomp_dbg
)

#
# Spec files
#

# Sets 'spec_file_list' variable
if(NOT "${sleigh_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
  include(spec-files-list/spec_files_stable.cmake)
else()
  include(spec-files-list/spec_files_HEAD.cmake)
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
    COMPILER "$<TARGET_FILE:sleigh::sleigh>"
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
# Included Example
#

if(PROJECT_IS_TOP_LEVEL)
  option(sleigh_BUILD_EXAMPLE "Build included sleigh example" "${sleigh_DEVELOPER_MODE}")
  if(sleigh_BUILD_EXAMPLE)
    add_executable(sleigh_example
      "${library_root}/sleighexample.cc"
    )

    target_compile_features(sleigh_example PRIVATE cxx_std_11)
    sleigh_add_optional_defines(sleigh_example PRIVATE)
    target_link_libraries(sleigh_example PRIVATE
      sleigh::sla
      sleigh::decomp
    )

    add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/specfiles"
      COMMAND "${CMAKE_COMMAND}" -E create_symlink
        "${spec_files_root_dir}/x86/data/languages/x86.sla"
        "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla"
      MAIN_DEPENDENCY "${spec_files_root_dir}/x86/data/languages/x86.sla"
    )
    add_custom_target(sleigh_example_x86_symlink DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla")

    add_custom_target(sleigh_example_runner)
    set(example_actions disassemble pcode emulate)
    foreach(action ${example_actions})
      add_custom_target(sleigh_example_${action}
        COMMAND sleigh_example ${action}
        COMMENT "Running example ${action}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
      )
      add_dependencies(sleigh_example_${action} sleigh_example_x86_symlink)
      add_dependencies(sleigh_example_runner sleigh_example_${action})
    endforeach()
  endif()
endif()

#
# Install rules
#

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(cmake/install-rules.cmake)
endif()

#
# Extras provided by Trail of Bits
#

if(sleigh_BUILD_EXTRATOOLS)
  add_subdirectory(tools)
endif()

if(sleigh_BUILD_SUPPORT)
  # Add support library before configuring install targets
  add_subdirectory(support)
endif()

#
# Developer mode
#
if(NOT sleigh_DEVELOPER_MODE)
  return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
  message(
    AUTHOR_WARNING
    "Developer mode is intended for developers of sleigh"
  )
endif()

include(cmake/dev-mode.cmake)
