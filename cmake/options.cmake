#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

# ---- Developer mode ----

# Developer mode enables targets and code paths in the CMake scripts that are
# only relevant for the developer(s) of sleigh
# Targets necessary to build the project must be provided unconditionally, so
# consumers can trivially build and package the project
if(PROJECT_IS_TOP_LEVEL)
  option(sleigh_DEVELOPER_MODE "Enable developer mode")
  option(BUILD_SHARED_LIBS "Build shared libs. (Untested and not supported)")
endif()

if(sleigh_DEVELOPER_MODE)
  option(sleigh_BUILD_DOCUMENTATION "Build documentation using Doxygen")
  set(
    DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/docs"
    CACHE PATH "Path for the generated Doxygen documentation"
  )
endif()

include(CMakeDependentOption)

# Optional project target building
option(sleigh_BUILD_TOOLS "Build and install executable tools" ON)
option(sleigh_BUILD_SLEIGHSPECS "Build and install sleigh spec files" ON)

# Add-ons by ToB
option(sleigh_BUILD_SUPPORT "Build ToB support libraries" ON)
cmake_dependent_option(sleigh_BUILD_EXTRATOOLS "Build extra ToB sleigh tools" ON "sleigh_BUILD_SUPPORT" OFF)

# ---- Warning guard ----

# target_include_directories with the SYSTEM modifier will request the compiler
# to omit warnings from the provided paths, if the compiler supports that
# This is to provide a user experience similar to find_package when
# add_subdirectory or FetchContent is used to consume this project
set(warning_guard "")

if(NOT PROJECT_IS_TOP_LEVEL)
  option(sleigh_INCLUDES_WITH_SYSTEM
    "Use SYSTEM modifier for sleigh's includes, disabling warnings"
    ON
  )
  mark_as_advanced(sleigh_INCLUDES_WITH_SYSTEM)

  if(sleigh_INCLUDES_WITH_SYSTEM)
    set(warning_guard SYSTEM)
  endif()
endif()
