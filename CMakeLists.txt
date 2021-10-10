# Copyright (c) 2021-present Trail of Bits, Inc.

cmake_minimum_required(VERSION 3.18)

project(sleigh
  LANGUAGES CXX C
  DESCRIPTION "A machine language translation and disassembly engine")

set(CMAKE_CXX_STANDARD 11)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(prevent_in_source_builds)
include(GNUInstallDirs)
include(project_settings)

# Sleigh build settings
add_library(sleigh_settings INTERFACE)

target_include_directories(sleigh_settings INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
  $<INSTALL_INTERFACE:include>
  )

include(compiler_warnings)
set_project_warnings(sleigh_settings)

include(sanitizers)
enable_sanitizers(sleigh_settings)

include(static_analyzers)

# Sleigh library
add_subdirectory(src)

if(DEFINED WIN32)
  set(install_folder "${CMAKE_INSTALL_PREFIX}/sleigh")
else()
  set(install_folder "${CMAKE_INSTALL_PREFIX}")
endif()

install(
  TARGETS sleigh
  EXPORT sleighTargets
  RUNTIME DESTINATION "${install_folder}/bin"
  )

install(
  TARGETS libsleigh
  EXPORT sleighTargets
  LIBRARY DESTINATION "${install_folder}/lib"
  )

install(
  DIRECTORY "${SLEIGH_SOURCE_DIR}/"
  INCLUDES DESTINATION "${install_folder}/include/sleigh"
  FILES_MATCHING PATTERN "*.hh"
  )

set(sleigh_cmake_config
  "${CMAKE_CURRENT_BINARY_DIR}/sleighConfig.cmake"
  )

configure_file(
  "${PROJECT_SOURCE_DIR}/cmake/sleighConfig.cmake.in"
  "${sleigh_cmake_config}"
  @ONLY
  )

install(
  FILES "${sleigh_cmake_config}"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/sleigh"
  )

install(
  EXPORT sleighTargets
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/sleigh"
  )
