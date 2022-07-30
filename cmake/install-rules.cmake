if(PROJECT_IS_TOP_LEVEL)
  set(CMAKE_INSTALL_INCLUDEDIR include/sleigh CACHE PATH "")
endif()

include("GNUInstallDirs")

install(
  TARGETS
    sleigh_sla
    sleigh_decomp
  EXPORT
    sleighTargets
  RUNTIME #
    COMPONENT sleigh_Runtime
  LIBRARY #
    COMPONENT sleigh_Runtime
    NAMELINK_COMPONENT sleigh_Development
  ARCHIVE #
    COMPONENT sleigh_Development
  INCLUDES DESTINATION
    "${CMAKE_INSTALL_INCLUDEDIR}"
)

install(
  DIRECTORY "${public_headers_dir}/"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  COMPONENT sleigh_Development
)

if(sleigh_BUILD_DOCUMENTATION)
  install(
    DIRECTORY "${DOXYGEN_OUTPUT_DIRECTORY}/html/"
    DESTINATION "${CMAKE_INSTALL_DOCDIR}"
    COMPONENT sleigh_Documentation
  )
endif()

set(
  sleigh_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/sleigh"
  CACHE PATH "CMake package config location relative to the install prefix"
)
mark_as_advanced(sleigh_INSTALL_CMAKEDIR)

install(
  EXPORT sleighTargets
  DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
  NAMESPACE sleigh::
  COMPONENT sleigh_Development
)

# Specfiles installation setup
set(sleigh_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/sleigh"
  CACHE PATH "sleigh data installation location relative to the install prefix"
)
mark_as_advanced(sleigh_INSTALL_DATADIR)

set(sleigh_INSTALL_SPECDIR "${sleigh_INSTALL_DATADIR}/specfiles"
  CACHE PATH "sleigh specfile root destination relative to the install prefix"
)
mark_as_advanced(sleigh_INSTALL_SPECDIR)

if(sleigh_BUILD_SLEIGHSPECS)
  # Install the compiled sla files found in 'Ghidra' top-level directory
  install(
    DIRECTORY "${spec_files_build_dir}/"
    DESTINATION "${sleigh_INSTALL_SPECDIR}"
    COMPONENT sleigh_Runtime
  )
endif()

include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    "sleighConfigVersion.cmake"
    COMPATIBILITY SameMinorVersion
)

install(
    FILES "${PROJECT_BINARY_DIR}/sleighConfigVersion.cmake"
    DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
    COMPONENT sleigh_Development
)

configure_package_config_file(cmake/install-config.cmake.in
  ${PROJECT_BINARY_DIR}/install-config.cmake
  INSTALL_DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
  NO_CHECK_REQUIRED_COMPONENTS_MACRO
  PATH_VARS sleigh_INSTALL_SPECDIR
)

install(
  FILES ${PROJECT_BINARY_DIR}/install-config.cmake
  RENAME sleighConfig.cmake
  DESTINATION "${sleigh_INSTALL_CMAKEDIR}"
  COMPONENT sleigh_Development
)

install(
  FILES cmake/modules/sleighCompile.cmake
  DESTINATION "${sleigh_INSTALL_CMAKEDIR}/modules"
  COMPONENT sleigh_Development
)

if(PROJECT_IS_TOP_LEVEL)
  include(cmake/packaging.cmake)
endif()
