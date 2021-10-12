#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

option(SLEIGH_ENABLE_TESTS "Set to true to enable tests" ON)
option(SLEIGH_ENABLE_EXAMPLES "Set to true to build examples" ON)
option(SLEIGH_ENABLE_INSTALL "Set to true to enable the install directives")
option(SLEIGH_ENABLE_DOCUMENTATION "Set to true to enable the documentation")
option(SLEIGH_ENABLE_PACKAGING "Set to true to enable packaging")
option(SLEIGH_ENABLE_SANITIZERS "Set to true to enable sanitizers")

# Internal debug settings
option(SLEIGH_OPACTION_DEBUG "Turns on all the action tracing facilities")
option(SLEIGH_MERGEMULTI_DEBUG "Check for MULTIEQUAL and INDIRECT intersections")
option(SLEIGH_BLOCKCONSISTENT_DEBUG "Check that block graph structure is consistent")
option(SLEIGH_DFSVERIFY_DEBUG "Make sure that the block ordering algorithm produces a true depth first traversal of the dominator tree")

# Additional internal settings
option(SLEIGH_CPUI_STATISTICS "Turn on collection of cover and cast statistics")
option(SLEIGH_CPUI_RULECOMPILE "Allow user defined dynamic rules")

if(SLEIGH_ENABLE_PACKAGING)
  set(SLEIGH_ENABLE_INSTALL true CACHE BOOL "Set to true to enable the install directives (forced)" FORCE)
endif()

if(SLEIGH_ENABLE_INSTALL)
  set(SLEIGH_ENABLE_DOCUMENTATION true CACHE BOOL "Set to true to enable the documentation (forced)" FORCE)
endif()
