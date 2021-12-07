#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

set(sleigh_support_source_list
  "${CMAKE_CURRENT_LIST_DIR}/Support.cpp"
)

add_library(support
  ${sleigh_support_source_list}
)

add_library(sleigh::support ALIAS support)

target_link_libraries(support PRIVATE
  sleigh::sleigh_settings
)
