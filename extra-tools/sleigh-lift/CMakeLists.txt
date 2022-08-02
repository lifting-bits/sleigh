#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.18)

project(sleighLift CXX)

include(../../cmake/project-is-top-level.cmake)

if(PROJECT_IS_TOP_LEVEL)
  find_package(sleigh REQUIRED COMPONENTS Support)
endif()

add_executable(sleigh_lift
  src/main.cpp
)
add_executable(sleigh::lift ALIAS sleigh_lift)

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

  set(
    sleigh_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/sleigh"
    CACHE PATH "CMake package config location relative to the install prefix"
  )
  mark_as_advanced(sleigh_INSTALL_CMAKEDIR)

  install(
    TARGETS sleigh_lift
    EXPORT sleighExtraToolsTargets
    RUNTIME #
      COMPONENT sleigh_ExtraToolsRuntime
  )
  install(
    EXPORT sleighExtraToolsTargets
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    NAMESPACE sleigh::
    COMPONENT sleigh_ExtraToolsDevelopment
  )
endif()
