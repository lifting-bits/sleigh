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
  "${CMAKE_CURRENT_BINARY_DIR}/include/sleigh/SpecFilePaths.h"
  @ONLY
)

# Based on: https://github.com/andrew-hardin/cmake-git-version-tracking/blob/98441f9dc056b8d3d4b4287b09e6a99775d70305/better-example/CMakeLists.txt
# By Andrew Hardin
# Released under the MIT License.
# https://raw.githubusercontent.com/andrew-hardin/cmake-git-version-tracking/98441f9dc056b8d3d4b4287b09e6a99775d70305/LICENSE
#
# Define the two required variables before including
# the source code for watching a git repository.
set(PRE_CONFIGURE_FILE "${CMAKE_CURRENT_LIST_DIR}/Version.cpp.in")
set(POST_CONFIGURE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Version.cpp")
set(GIT_STATE_FILE "${CMAKE_CURRENT_BINARY_DIR}/git-state-sleigh")
set(GIT_WORKING_DIR "${PROJECT_SOURCE_DIR}")
set(GIT_FAIL_IF_NONZERO_EXIT OFF)
include("../cmake/git_watcher.cmake")

# Generate GHIDRA version helpers
configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/GhidraVersion.cpp.in"
  "${CMAKE_CURRENT_BINARY_DIR}/GhidraVersion.cpp"
  @ONLY
)

add_library(sleigh_support
  Support.cpp
  "${POST_CONFIGURE_FILE}"
  "${CMAKE_CURRENT_BINARY_DIR}/GhidraVersion.cpp"
)
add_library(sleigh::support ALIAS sleigh_support)

# Need to explicitly add this dependency because BYPRODUCTS doesn't work under
# CMake 3.16 with GNU Makefiles
add_dependencies(sleigh_support check_git)

target_compile_features(sleigh_support PUBLIC cxx_std_17)
set_target_properties(sleigh_support PROPERTIES
  EXPORT_NAME support
  OUTPUT_NAME slaSupport
)
target_include_directories(sleigh_support
  ${warning_guard}
  PUBLIC
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
)
target_include_directories(sleigh_support
  SYSTEM
  PUBLIC
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>"
)

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(GNUInstallDirs)

  install(
    TARGETS sleigh_support
    EXPORT sleighSupportTargets
    RUNTIME #
      COMPONENT sleigh_SupportRuntime
    LIBRARY #
      COMPONENT sleigh_SupportRuntime
      NAMELINK_COMPONENT sleigh_SupportDevelopment
    ARCHIVE #
      COMPONENT sleigh_SupportDevelopment
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  )

  install(
    DIRECTORY
      include/
      "${CMAKE_CURRENT_BINARY_DIR}/include/"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    COMPONENT sleigh_SupportDevelopment
  )

  install(
    EXPORT sleighSupportTargets
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    NAMESPACE sleigh::
    COMPONENT sleigh_SupportDevelopment
  )
endif()
