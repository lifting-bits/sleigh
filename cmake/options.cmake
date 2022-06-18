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
  option(sleigh_DEVELOPER_MODE "Enable developer mode" OFF)
  option(BUILD_SHARED_LIBS "Build shared libs. (Untested and not supported)" OFF)
endif()

if(sleigh_DEVELOPER_MODE)
  option(sleigh_BUILD_DOCUMENTATION "Build documentation using Doxygen" OFF)
  set(
    DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/docs"
    CACHE PATH "Path for the generated Doxygen documentation"
  )
endif()

set(
  DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/docs"
  CACHE PATH "Path for the generated Doxygen documentation"
)


# Add-ons by ToB
option(sleigh_BUILD_SUPPORT "Build ToB support libraries")
option(sleigh_BUILD_EXTRATOOLS "Build extra ToB sleigh tools")
if(sleigh_BUILD_EXTRATOOLS)
  set(sleigh_BUILD_SUPPORT ON CACHE BOOL "Build ToB support libraries" FORCE)
endif()

# Internal settings
option(sleigh_CPUI_RULECOMPILE "Allow user defined dynamic rules")
option(sleigh_CPUI_STATISTICS "Turn on collection of cover and cast statistics")

# Internal debug settings (naming is swapped to help with discoverability in CMake options)
option(sleigh_DEBUG_BLOCKCONSISTENT "Check that block graph structure is consistent")
option(sleigh_DEBUG_DFSVERIFY "Make sure that the block ordering algorithm produces a true depth first traversal of the dominator tree")
option(sleigh_DEBUG_MERGEMULTI "Check for MULTIEQUAL and INDIRECT intersections")
option(sleigh_DEBUG_OPACTION "Turns on all the action tracing facilities")

macro(sleigh_add_optional_defines target visibility)
  set(opt_defines "")
  if(sleigh_CPUI_RULECOMPILE)
    list(APPEND opt_defines "CPUI_RULECOMPILE")
  endif()
  if(sleigh_CPUI_STATISTICS)
    list(APPEND opt_defines "CPUI_STATISTICS")
  endif()
  if(sleigh_DEBUG_BLOCKCONSISTENT)
    list(APPEND opt_defines "BLOCKCONSISTENT_DEBUG")
  endif()
  if(sleigh_DEBUG_DFSVERIFY)
    list(APPEND opt_defines "DFSVERIFY_DEBUG")
  endif()
  if(sleigh_DEBUG_MERGEMULTI)
    list(APPEND opt_defines "MERGEMULTI_DEBUG")
  endif()
  if(sleigh_DEBUG_OPACTION)
    list(APPEND opt_defines "OPACTION_DEBUG")
  endif()
  target_compile_definitions("${target}" ${visibility} ${opt_defines})
endmacro()

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
