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

project(sleigh_tools
  VERSION "${ghidra_version}"
  DESCRIPTION "Sleigh tools"
  HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
  LANGUAGES CXX
)

option(sleigh_BUILD_SPECCOMPILER "Build the sleigh spec compiler executable (\"sleigh\")" ON)
option(sleigh_BUILD_DECOMPILER "Build the decompiler executable (\"decomp\")" ON)
option(sleigh_BUILD_GHIDRA "Build the Ghidra executable (\"ghidra\")" ON)

if(sleigh_BUILD_SPECCOMPILER)
  add_subdirectory(spec-compiler)
endif()

if(sleigh_BUILD_DECOMPILER)
  add_subdirectory(decompiler)
endif()

if(sleigh_BUILD_GHIDRA)
  add_subdirectory(ghidra)
endif()
