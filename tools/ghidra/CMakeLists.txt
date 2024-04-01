#
# Copyright (c) 2022-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.18)

include(../../cmake/prelude.cmake)
include(../../src/setup-ghidra-source.cmake)

project(sleigh_ghidra
  VERSION "${ghidra_version}"
  DESCRIPTION "Sleigh ghidra service"
  HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
  LANGUAGES CXX
)

include(../../cmake/project-is-top-level.cmake)

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

if(sleigh_RELEASE_IS_HEAD)
  find_package(ZLIB REQUIRED)
  target_link_libraries(sleigh_ghidra PRIVATE ZLIB::ZLIB)
endif()

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include("GNUInstallDirs")

  install(
    TARGETS sleigh_ghidra
    EXPORT sleighTargets
    RUNTIME COMPONENT sleigh_Runtime
  )

  if(PROJECT_IS_TOP_LEVEL)
    include(CPack)
  endif()
endif()
