#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

set(PACKAGE_VERSION 1)
if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
  set(PACKAGE_VERSION "DEV.${ghidra_short_commit}")
endif()

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "SLEIGH was designed for the GHIDRA reverse engineering platform built by the National Security Agency and is used to describe microprocessors with enough detail to facilitate two major components of GHIDRA, the disassembly and decompilation engines. This is an unofficial release by Trail of Bits.")
set(CPACK_PACKAGE_NAME "sleigh")
set(CPACK_PACKAGE_VENDOR "Trail of Bits")
set(CPACK_PACKAGE_CONTACT "info@trailofbits.com")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/lifting-bits/sleigh")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${PROJECT_VERSION}-${PACKAGE_VERSION}.${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_PACKAGE_RELOCATABLE ON)

set(CPACK_GENERATOR "TGZ")

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  unset(rpm_executable_path CACHE)
  find_program(rpm_executable_path "rpm")
  if("${rpm_executable_path}" STREQUAL "rpm_executable_path-NOTFOUND")
    message(WARNING "sleigh: the RPM package generator requires the 'rpm' tool")
  else()
    list(APPEND CPACK_GENERATOR "RPM")
    message(STATUS "sleigh: the RPM generator has been enabled")
  endif()
  set(CPACK_RPM_PACKAGE_RELEASE_DIST "${PACKAGE_VERSION}")
  set(CPACK_RPM_PACKAGE_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")
  set(CPACK_RPM_PACKAGE_GROUP "default")

  unset(dpkg_executable_path CACHE)
  find_program(dpkg_executable_path "dpkg")
  if("${dpkg_executable_path}" STREQUAL "dpkg_executable_path-NOTFOUND")
    message(WARNING "sleigh: the DEB package generator requires the 'dpkg' tool")
  else()
    list(APPEND CPACK_GENERATOR "DEB")
    message(STATUS "sleigh: the DEB generator has been enabled")
  endif()
  set(CPACK_DEBIAN_PACKAGE_RELEASE "${PACKAGE_VERSION}")
  set(CPACK_DEBIAN_PACKAGE_PRIORITY "extra")
  set(CPACK_DEBIAN_PACKAGE_SECTION "default")
  set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "${CPACK_PACKAGE_HOMEPAGE_URL}")
endif()

include(CPack)
