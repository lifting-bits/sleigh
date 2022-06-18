#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

add_executable(sleigh_lift
  src/main.cpp
)
add_executable(sleigh::sleigh_lift ALIAS sleigh_lift)

target_link_libraries(sleigh_lift PRIVATE
  sleigh::sla
  sleigh::decomp
  sleigh::support
)
target_compile_features(sleigh_lift PRIVATE cxx_std_17)
set_target_properties(sleigh_lift PROPERTIES
  EXPORT_NAME lift
  OUTPUT_NAME sleighLift
)

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(GNUInstallDirs)
  install(
    TARGETS sleigh_lift
    EXPORT sleighExtraToolsTargets
  )
  install(
    EXPORT sleighExtraToolsTargets
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    NAMESPACE sleigh::
  )
endif()
