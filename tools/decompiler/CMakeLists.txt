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

project(sleigh_decompiler
  VERSION "${ghidra_version}"
  DESCRIPTION "Sleigh decompiler"
  HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
  LANGUAGES CXX
)

include(../../cmake/project-is-top-level.cmake)

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
include(CheckIncludeFileCXX)
check_include_file_cxx(termios.h HAVE_TERMIOS_H)
if(HAVE_TERMIOS_H)
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

find_package(ZLIB REQUIRED)
target_link_libraries(sleigh_decompiler PRIVATE ZLIB::ZLIB)

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include("GNUInstallDirs")

  install(
    TARGETS sleigh_decompiler
    EXPORT sleighTargets
    RUNTIME COMPONENT sleigh_Runtime
  )

  if(PROJECT_IS_TOP_LEVEL)
    include(CPack)
  endif()
endif()
