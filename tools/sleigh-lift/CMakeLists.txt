#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

add_executable(sleigh-lift
  src/main.cpp
)

target_compile_options(sleigh-lift PRIVATE
  -Wall
  -Werror
  -Wextra
)

target_include_directories(sleigh-lift PRIVATE
  "${library_root}"
)

target_link_libraries(sleigh-lift PRIVATE
  sla
  decomp
)

if(SLEIGH_ENABLE_INSTALL)
  install(
    TARGETS
      sleigh-lift

    EXPORT
      "${PROJECT_NAME}"

    DESTINATION
      "${CMAKE_INSTALL_BINDIR}"

    PERMISSIONS
      OWNER_READ OWNER_WRITE OWNER_EXECUTE
      GROUP_READ GROUP_EXECUTE
      WORLD_READ WORLD_EXECUTE
  )
endif()
