#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

option(sleigh_ENABLE_TESTS "Set to true to enable tests" ON)
option(sleigh_ENABLE_EXAMPLES "Set to true to build examples" ON)
option(sleigh_ENABLE_DOCUMENTATION "Set to true to enable the documentation")
option(sleigh_ENABLE_PACKAGING "Set to true to enable packaging")
option(sleigh_ENABLE_SANITIZERS "Set to true to enable sanitizers")
option(sleigh_ADDITIONAL_PATCHES "The accepted patch format is git patch files, to be applied via git am. The format of the list is a CMake semicolon separated list." "")

# Internal debug settings
option(sleigh_OPACTION_DEBUG "Turns on all the action tracing facilities")
option(sleigh_MERGEMULTI_DEBUG "Check for MULTIEQUAL and INDIRECT intersections")
option(sleigh_BLOCKCONSISTENT_DEBUG "Check that block graph structure is consistent")
option(sleigh_DFSVERIFY_DEBUG "Make sure that the block ordering algorithm produces a true depth first traversal of the dominator tree")

# Additional internal settings
option(sleigh_CPUI_STATISTICS "Turn on collection of cover and cast statistics")
option(sleigh_CPUI_RULECOMPILE "Allow user defined dynamic rules")

# Sanity checking
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  set(sleigh_ENABLE_DOCUMENTATION OFF CACHE BOOL "Unsupported on Windows" FORCE)
endif()

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
