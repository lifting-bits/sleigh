#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.18)

include(cmake/prelude.cmake)

# Sets "library_root" variable for decompiler cpp root directory
# Sets "ghidra_version" for numeric version number
# Use "ghidrasource_SOURCE_DIR" variable for Ghidra repo root
include(src/setup-ghidra-source.cmake)
set(sleigh_RELEASE_IS_HEAD FALSE)
if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
  set(sleigh_RELEASE_IS_HEAD TRUE)
endif()

project(sleigh
  VERSION "${ghidra_version}"
  DESCRIPTION "Unofficial CMake build for Ghidra Sleigh"
  HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
  LANGUAGES CXX
)

include(cmake/project-is-top-level.cmake)
include(cmake/options.cmake)

#
# Move headers so we can prefix with "ghidra/"
#
set(public_include_header_list
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
  "${library_root}/unionresolve.hh"
  "${library_root}/marshal.hh"
  "${library_root}/analyzesigs.hh"
  "${library_root}/modelrules.hh"
  "${library_root}/signature.hh"
  "${library_root}/signature_ghidra.hh"
)
if(sleigh_RELEASE_IS_HEAD)
  list(APPEND public_include_header_list
    "${library_root}/compression.hh"
    "${library_root}/slaformat.hh"
  )
endif()
# Create custom target so that IDEs know these files are part of the sources
add_custom_target(sleigh_all_headers SOURCES ${public_include_header_list})
set(public_headers_dir ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY "${public_headers_dir}/ghidra")
# Copy the public headers into our build directory so that we can control the layout.
# Ideally, we want to let people '#include <ghidra/{header}>' without installing sleigh
foreach(public_header ${public_include_header_list})
  configure_file("${public_header}" "${public_headers_dir}/ghidra" COPYONLY)
endforeach()
# This project also generates a helper header for managing sleigh versions.
# We intentionally use the `sleigh` directory for this header because it's
# not from upstream.
configure_file(cmake/libconfig.h.in "${public_headers_dir}/sleigh/libconfig.h")

# External Dependencies
if(sleigh_RELEASE_IS_HEAD)
  find_package(ZLIB REQUIRED)
endif()

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

if(sleigh_RELEASE_IS_HEAD)
  target_link_libraries(sleigh_sla PRIVATE ZLIB::ZLIB)
endif()

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

if(sleigh_RELEASE_IS_HEAD)
  target_link_libraries(sleigh_decomp PRIVATE ZLIB::ZLIB)
endif()

# This is the root directory where all individual processor spec file directories will be created.
# NOTE: Needs to be defined here before the install rules
set(spec_files_build_dir "${CMAKE_CURRENT_BINARY_DIR}/specfiles")

#
# Install rules
#
if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(cmake/install-rules.cmake)
endif()

#
# Build tool projects
#
if(sleigh_BUILD_TOOLS)
  add_subdirectory(tools)
endif()

#
# Spec files
#
if(sleigh_BUILD_SLEIGHSPECS)
  add_subdirectory(sleighspecs)
endif()

#
# Included Example
#
if(PROJECT_IS_TOP_LEVEL)
  include(CMakeDependentOption)
  cmake_dependent_option(sleigh_BUILD_EXAMPLE "Build included sleigh example" "${sleigh_DEVELOPER_MODE}" "sleigh_BUILD_SLEIGHSPECS" OFF)
  if(sleigh_BUILD_EXAMPLE)
    add_subdirectory(example)
  endif()
endif()

#
# Support library provided by Trail of Bits
#
if(sleigh_BUILD_SUPPORT)
  # Add support library before configuring install targets
  add_subdirectory(support)
endif()

#
# Extras provided by Trail of Bits
#
if(sleigh_BUILD_EXTRATOOLS)
  add_subdirectory(extra-tools)
endif()

#
# Developer mode
#
if(NOT sleigh_DEVELOPER_MODE)
  return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
  message(AUTHOR_WARNING "Developer mode is intended for developers of sleigh")
endif()

include(cmake/dev-mode.cmake)
