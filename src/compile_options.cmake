#
# Copyright (c) 2022-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

# Internal settings
option(sleigh_CPUI_RULECOMPILE "Allow user defined dynamic rules")
option(sleigh_CPUI_STATISTICS "Turn on collection of cover and cast statistics")

# Internal debug settings (naming is swapped to help with discoverability in CMake options)
option(sleigh_DEBUG_BLOCKCONSISTENT "Check that block graph structure is consistent")
option(sleigh_DEBUG_DFSVERIFY "Make sure that the block ordering algorithm produces a true depth first traversal of the dominator tree")
option(sleigh_DEBUG_MERGEMULTI "Check for MULTIEQUAL and INDIRECT intersections")
option(sleigh_DEBUG_OPACTION "Turns on all the action tracing facilities")

#
# Common options that can apply to all project targets
#
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
  if(WIN32)
    list(APPEND opt_defines "_WINDOWS")
  endif()
  target_compile_definitions("${target}" ${visibility} ${opt_defines})
endmacro()
