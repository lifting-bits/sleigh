#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

# Generate the build and install directories to use in the support helpers
set(SLEIGH_SPEC_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/share/sleigh/specfiles/")
set(SLEIGH_SPEC_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/specfiles/")
configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/SpecFilePaths.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/SpecFilePaths.h"
  @ONLY
)

set(sleigh_support_source_list
  Support.cpp
)

add_library(support
  ${sleigh_support_source_list}
)

add_library(sleigh::support ALIAS support)

target_link_libraries(support PUBLIC
  sleigh::sleigh_settings
)
target_include_directories(support PRIVATE "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>")
