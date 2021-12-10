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
add_executable(sleigh::sleigh-lift ALIAS sleigh-lift)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  if(MSVC)
    target_compile_options(sleigh-lift PRIVATE
      /W4
      /WX
    )
  else()
    target_compile_options(sleigh-lift PRIVATE
      -Wall
      -Werror
      -Wextra
    )
  endif()
endif()

target_link_libraries(sleigh-lift PRIVATE
  sleigh::sla
  sleigh::decomp
  sleigh::support
)

if(SLEIGH_ENABLE_INSTALL)
  install(
    TARGETS
      sleigh-lift

    EXPORT
      "sleigh"

    DESTINATION
      "${CMAKE_INSTALL_BINDIR}"

    PERMISSIONS
      OWNER_READ OWNER_WRITE OWNER_EXECUTE
      GROUP_READ GROUP_EXECUTE
      WORLD_READ WORLD_EXECUTE
  )
endif()
