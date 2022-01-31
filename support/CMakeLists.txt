#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

# Generate the build and install directories to use in the support helpers
configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/SpecFilePaths.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/SpecFilePaths.h"
  @ONLY
  )

configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/GhidraVersion.cpp.in"
  "${CMAKE_CURRENT_BINARY_DIR}/GhidraVersion.cpp"
  @ONLY
  )

# Based on: https://github.com/andrew-hardin/cmake-git-version-tracking/blob/master/better-example/CMakeLists.txt
# By Andrew Hardin
# Released under the MIT License.
# https://raw.githubusercontent.com/andrew-hardin/cmake-git-version-tracking/master/LICENSE
#
# Define the two required variables before including
# the source code for watching a git repository.
set(PRE_CONFIGURE_FILE "${CMAKE_CURRENT_LIST_DIR}/Version.cpp.in")
set(POST_CONFIGURE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Version.cpp")
set(GIT_FAIL_IF_NONZERO_EXIT OFF)
include("${PROJECT_SOURCE_DIR}/cmake/git_watcher.cmake")

set(sleigh_support_source_list
  Support.cpp
  ${POST_CONFIGURE_FILE}
  "${CMAKE_CURRENT_BINARY_DIR}/GhidraVersion.cpp"
)

add_library(support
  ${sleigh_support_source_list}
)

add_library(sleigh::support ALIAS support)

target_link_libraries(support PUBLIC
  sleigh::sleigh_settings
)
target_include_directories(support PRIVATE
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
  "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/support>"
)
