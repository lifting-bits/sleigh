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

project(sleigh_sleigh
  VERSION "${ghidra_version}"
  DESCRIPTION "Sleigh spec compiler"
  HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
  LANGUAGES CXX
)

include(../../cmake/project-is-top-level.cmake)

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

find_package(ZLIB REQUIRED)
target_link_libraries(sleigh_sleigh PRIVATE ZLIB::ZLIB)

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include("GNUInstallDirs")

  install(
    TARGETS sleigh_sleigh
    EXPORT sleighTargets
    RUNTIME COMPONENT sleigh_Runtime
  )

  if(PROJECT_IS_TOP_LEVEL)
    include(CPack)
  endif()
endif()
