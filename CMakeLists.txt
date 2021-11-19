#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.21.0)

# Sets "library_root" variable for decompiler cpp root directory
# Sets "ghidra_version" for numeric version number
# Use "ghidrasource_SOURCE_DIR" variable for Ghidra repo root
include(src/setup-ghidra-source.cmake)

project("sleigh"
  VERSION "${ghidra_version}"
)

include("cmake/options.cmake")

if(SLEIGH_ENABLE_TESTS)
  include("CTest")
endif()

if(SLEIGH_ENABLE_PACKAGING)
  include("cmake/packaging.cmake")

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(WARNING "sleigh: Packaging a Debug version")
  endif()
endif()

set(sleigh_core_source_list
  "${library_root}/xml.cc"
  "${library_root}/space.cc"
  "${library_root}/float.cc"
  "${library_root}/address.cc"
  "${library_root}/pcoderaw.cc"
  "${library_root}/translate.cc"
  "${library_root}/opcodes.cc"
  "${library_root}/globalcontext.cc"
)

set(sleigh_deccore_source_list
  "${library_root}/capability.cc"
  "${library_root}/architecture.cc"
  "${library_root}/options.cc"
  "${library_root}/graph.cc"
  "${library_root}/cover.cc"
  "${library_root}/block.cc"
  "${library_root}/cast.cc"
  "${library_root}/typeop.cc"
  "${library_root}/database.cc"
  "${library_root}/cpool.cc"
  "${library_root}/comment.cc"
  "${library_root}/stringmanage.cc"
  "${library_root}/fspec.cc"
  "${library_root}/action.cc"
  "${library_root}/loadimage.cc"
  "${library_root}/grammar.cc"
  "${library_root}/varnode.cc"
  "${library_root}/op.cc"
  "${library_root}/type.cc"
  "${library_root}/variable.cc"
  "${library_root}/varmap.cc"
  "${library_root}/jumptable.cc"
  "${library_root}/emulate.cc"
  "${library_root}/emulateutil.cc"
  "${library_root}/flow.cc"
  "${library_root}/userop.cc"
  "${library_root}/funcdata.cc"
  "${library_root}/funcdata_block.cc"
  "${library_root}/funcdata_op.cc"
  "${library_root}/funcdata_varnode.cc"
  "${library_root}/pcodeinject.cc"
  "${library_root}/heritage.cc"
  "${library_root}/prefersplit.cc"
  "${library_root}/rangeutil.cc"
  "${library_root}/ruleaction.cc"
  "${library_root}/subflow.cc"
  "${library_root}/blockaction.cc"
  "${library_root}/merge.cc"
  "${library_root}/double.cc"
  "${library_root}/transform.cc"
  "${library_root}/coreaction.cc"
  "${library_root}/condexe.cc"
  "${library_root}/override.cc"
  "${library_root}/dynamic.cc"
  "${library_root}/crc32.cc"
  "${library_root}/prettyprint.cc"
  "${library_root}/printlanguage.cc"
  "${library_root}/printc.cc"
  "${library_root}/printjava.cc"
  "${library_root}/memstate.cc"
  "${library_root}/opbehavior.cc"
  "${library_root}/paramid.cc"
)

set(sleigh_extra_source_list
  "${library_root}/callgraph.cc"
  "${library_root}/ifacedecomp.cc"
  "${library_root}/ifaceterm.cc"
  "${library_root}/inject_sleigh.cc"
  "${library_root}/interface.cc"
  "${library_root}/libdecomp.cc"
  "${library_root}/loadimage_xml.cc"
  "${library_root}/raw_arch.cc"
  "${library_root}/rulecompile.cc"
  "${library_root}/sleigh_arch.cc"
  "${library_root}/testfunction.cc"
  "${library_root}/unify.cc"
  "${library_root}/xml_arch.cc"
)

set(sleigh_source_list
  "${library_root}/sleigh.cc"
  "${library_root}/pcodeparse.cc"
  "${library_root}/pcodecompile.cc"
  "${library_root}/sleighbase.cc"
  "${library_root}/slghsymbol.cc"
  "${library_root}/slghpatexpress.cc"
  "${library_root}/slghpattern.cc"
  "${library_root}/semantics.cc"
  "${library_root}/context.cc"
  "${library_root}/filemanage.cc"
)

set(sleigh_ghidra_source_list
  "${library_root}/ghidra_arch.cc"
  "${library_root}/inject_ghidra.cc"
  "${library_root}/ghidra_translate.cc"
  "${library_root}/loadimage_ghidra.cc"
  "${library_root}/typegrp_ghidra.cc"
  "${library_root}/database_ghidra.cc"
  "${library_root}/ghidra_context.cc"
  "${library_root}/cpool_ghidra.cc"
  "${library_root}/ghidra_process.cc"
  "${library_root}/comment_ghidra.cc"
  "${library_root}/string_ghidra.cc"
)

set(sleigh_slacomp_source_list
  "${library_root}/slgh_compile.cc"
  "${library_root}/slghparse.cc"
  "${library_root}/slghscan.cc"
)

#
# sleigh settings
#

add_library(sleigh_settings INTERFACE)
add_library(sleigh::sleigh_settings ALIAS sleigh_settings)
target_compile_features(sleigh_settings INTERFACE
  cxx_std_17
)

set_target_properties(sleigh_settings PROPERTIES
  INTERFACE_POSITION_INDEPENDENT_CODE ON
)

if(SLEIGH_ENABLE_SANITIZERS)
  message(STATUS "sleigh: Sanitizers have been enabled")

  if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(WARNING "sleigh: Debug builds are preferred when sanitizers are enabled")
  endif()

  set(flag_list
    -fno-omit-frame-pointer -fsanitize=undefined,address
  )

  target_compile_options(sleigh_settings INTERFACE ${flag_list})
  target_link_options(sleigh_settings INTERFACE ${flag_list})
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(debug_setting_list
    OPACTION_DEBUG
    MERGEMULTI_DEBUG
    BLOCKCONSISTENT_DEBUG
    DFSVERIFY_DEBUG
  )

  foreach(debug_setting ${debug_setting_list})
    if(NOT SLEIGH_${debug_setting})
      continue()
    endif()

    message(STATUS "sleigh: Enabling debug setting: SLEIGH_${debug_setting}")

    target_compile_definitions(sleigh_settings INTERFACE
      ${debug_setting}
    )
  endforeach()
endif()

set(internal_setting_list
  CPUI_STATISTICS
  CPUI_RULECOMPILE
)

foreach(internal_setting ${internal_setting_list})
  if(NOT SLEIGH_${internal_setting})
    continue()
  endif()

  message(STATUS "sleigh: Enabling internal setting: SLEIGH_${internal_setting}")

  target_compile_definitions(sleigh_settings INTERFACE
    ${internal_setting}
  )
endforeach()

#
# decomp_opt, decomp_dbg
#

add_executable(decomp_opt
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_extra_source_list}
  ${sleigh_source_list}

  "${library_root}/consolemain.cc"
)
add_executable(sleigh::decomp_opt ALIAS decomp_opt)
if("${SLEIGH_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
  target_sources(decomp_opt PRIVATE
    "${library_root}/testfunction.cc"
  )
endif()

target_compile_definitions(decomp_opt PRIVATE
  __TERMINAL__
)

target_link_libraries(decomp_opt PRIVATE
  sleigh::sleigh_settings
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_definitions(decomp_opt PRIVATE
    CPUI_DEBUG
  )

  set_target_properties(decomp_opt PROPERTIES
    OUTPUT_NAME "decomp_dbg"
  )
endif()

#
# ghidra_test_dbg
#

if(SLEIGH_ENABLE_TESTS)
  add_executable(ghidra_test_dbg
    ${sleigh_core_source_list}
    ${sleigh_deccore_source_list}
    ${sleigh_source_list}
    ${sleigh_extra_source_list}

    "${library_root}/test.cc"
    "${library_root}/../unittests/testfloatemu.cc"
  )
  if("${SLEIGH_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
    target_sources(ghidra_test_dbg PRIVATE
      "${library_root}/../unittests/testtypes.cc"
      "${library_root}/../unittests/testcirclerange.cc"
    )
  endif()

  target_link_libraries(ghidra_test_dbg PRIVATE
    sleigh::sleigh_settings
  )

  target_compile_definitions(ghidra_test_dbg PRIVATE
    __TERMINAL__
  )

  target_include_directories(ghidra_test_dbg PRIVATE
    "${library_root}"
  )

  set(extra_test_args "")
  if("${SLEIGH_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
    # We compile the sla files in our build directory
    set(extra_test_args -sleighpath "${CMAKE_CURRENT_BINARY_DIR}")
  endif()
  add_test(
    NAME ghidra_test_dbg
    COMMAND ghidra_test_dbg ${extra_test_args} unittests
  )
endif()

#
# ghidra_opt, ghidra_dbg
#

add_executable(ghidra_opt
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_ghidra_source_list}
)
add_executable(sleigh::ghidra_opt ALIAS ghidra_opt)
if("${SLEIGH_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
  target_sources(ghidra_opt PRIVATE
    $<$<CONFIG:DEBUG>:
      "${library_root}/testfunction.cc"
    >
  )
endif()

target_link_libraries(ghidra_opt PRIVATE
  sleigh::sleigh_settings
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_sources(ghidra_opt PRIVATE
    "${library_root}/callgraph.cc"
    "${library_root}/ifacedecomp.cc"
    "${library_root}/ifaceterm.cc"
    "${library_root}/interface.cc"
  )

  target_compile_definitions(ghidra_opt PRIVATE
    CPUI_DEBUG
  )

  set_target_properties(ghidra_opt PROPERTIES
    OUTPUT_NAME "ghidra_dbg"
  )
endif()

#
# sleigh_opt, sleigh_dbg
#

add_executable(sleigh_opt
  ${sleigh_core_source_list}
  ${sleigh_source_list}
  ${sleigh_slacomp_source_list}
)
add_executable(sleigh::sleigh_opt ALIAS sleigh_opt)

target_link_libraries(sleigh_opt PRIVATE
  sleigh::sleigh_settings
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set_target_properties(sleigh_opt PROPERTIES
    OUTPUT_NAME "sleigh_dbg"
  )
endif()

#
# sla, sla_dbg
#

add_library(sla
  ${sleigh_core_source_list}
  ${sleigh_source_list}

  "${library_root}/loadimage.cc"
  "${library_root}/sleigh.cc"
  "${library_root}/memstate.cc"
  "${library_root}/emulate.cc"
  "${library_root}/opbehavior.cc"
)
add_library(sleigh::sla ALIAS sla)

target_link_libraries(sla PUBLIC
  sleigh::sleigh_settings
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_definitions(sla PRIVATE
    YYDEBUG
  )

  set_target_properties(sla PROPERTIES
    OUTPUT_NAME "sla_dbg"
  )
endif()

#
# decomp, decomp_dbg
#

add_library(decomp
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_extra_source_list}
  ${sleigh_source_list}
)
add_library(sleigh::decomp ALIAS decomp)

target_link_libraries(decomp PUBLIC
  sleigh::sleigh_settings
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set_target_properties(decomp PROPERTIES
    OUTPUT_NAME "decomp_dbg"
  )
endif()

#
# Documentation
#

if(SLEIGH_ENABLE_DOCUMENTATION)
  message(STATUS "sleigh: Documentation has been enabled")

  find_package(Doxygen COMPONENTS dot)
  if(DOXYGEN_FOUND)
    set(working_directory "${CMAKE_CURRENT_BINARY_DIR}/doxygen_src")

    add_custom_command(
      OUTPUT "${working_directory}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${working_directory}"
      COMMENT "sleigh: Generating the Doxygen working directory"
      VERBATIM
    )

    add_custom_target(sleigh_doxygen_cwd_builder
      DEPENDS "${working_directory}"
    )

    set(documentation_output "${CMAKE_CURRENT_BINARY_DIR}/doc/html")

    add_custom_command(
      OUTPUT "${documentation_output}"
      COMMAND Doxygen::doxygen "${library_root}/Doxyfile"
      COMMENT "sleigh: Generating the Doxygen documentation"
      WORKING_DIRECTORY "${working_directory}"
      VERBATIM
    )

    add_custom_target(sleigh_documentation ALL
      DEPENDS "${documentation_output}"
    )

    add_dependencies(
      sleigh_documentation
      sleigh_doxygen_cwd_builder
    )

  else()
    message(FATAL_ERROR "sleigh: Doxygen was not found")
  endif()
endif()

#
# Spec files
#
# Sets 'spec_file_list' variable
if(NOT "${SLEIGH_GHIDRA_RELEASE_TYPE}" STREQUAL "HEAD")
  include(spec-files-list/spec_files_stable.cmake)
else()
  include(spec-files-list/spec_files_HEAD.cmake)
endif()

# This prefix should match the Ghidra repo to where the sla spec files are located
set(spec_files_dir_prefix Ghidra/Processors)
# This is the root directory where all individual processor spec file directories will be created
set(spec_files_build_dir "${CMAKE_CURRENT_BINARY_DIR}/specfiles")
# This is where we will be copying the generated artifacts for each processor
set(spec_files_root_dir "${spec_files_build_dir}/${spec_files_dir_prefix}")
set(spec_files_build_log_dir ${CMAKE_CURRENT_BINARY_DIR}/spec_build_logs)

add_custom_command(
  OUTPUT ${spec_files_build_log_dir}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${spec_files_build_log_dir}
)

# Start processing all `.slaspec` files individually
set(spec_targets)
set(spec_files)
# Example: '<ghidra_source_prefix>/Ghidra/Processors/8051/data/languages/mx51.slaspec'
foreach(spec_file ${spec_file_list})
  # Get 'mx51'
  cmake_path(GET spec_file STEM LAST_ONLY spec_name)
  # Get '<ghidra_source_prefix>/Ghidra/Processors/8051/data/languages'
  cmake_path(GET spec_file PARENT_PATH spec_dir)
  # Get '8051/data/languages'
  cmake_path(RELATIVE_PATH spec_dir
    BASE_DIRECTORY "${ghidrasource_SOURCE_DIR}/${spec_files_dir_prefix}"
    OUTPUT_VARIABLE spec_proc_dir
  )

  set(spec_build_log "${spec_files_build_log_dir}/${spec_name}_build.log")
  # Combine back again for the build directory output like
  # '<build_prefix>/Ghidra/Processors/8051/data/languages'
  set(spec_out_dir "${spec_files_root_dir}/${spec_proc_dir}")
  # '<build_prefix>/Ghidra/Processors/8051/data/languages/mx51.sla'
  set(spec_out "${spec_out_dir}/${spec_name}.sla")

  # Copy all other files from the slaspec source directory:
  # '<ghidra_source_prefix>/Ghidra/Processors/8051/data/languages'
  # TODO: This only copies the directory once, so you will need to remove the whole directory if you update any of
  #  the other files, like '*.cspec' or '*.ldef' files
  # CMake only guarantees update monitoring for file listed explicitly
  add_custom_command(
    OUTPUT "${spec_out_dir}"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${spec_dir}" "${spec_out_dir}"
  )

  # Compile the sla file
  add_custom_command(
    OUTPUT "${spec_out}"
    DEPENDS "${spec_file}" "${spec_out_dir}" "${spec_files_build_log_dir}"
    COMMAND "$<TARGET_FILE:sleigh::sleigh_opt>" ${spec_file} "${spec_out}" > ${spec_build_log} 2>&1
    WORKING_DIRECTORY "${spec_dir}"
    COMMENT "sleigh: Compiling the ${spec_name} spec file (${spec_build_log})"
    BYPRODUCTS ${spec_build_log}
    VERBATIM
  )

  string(REPLACE "." "_" spec_target_name ${spec_name})
  set(spec_target "sleigh_spec_${spec_target_name}")
  add_custom_target(${spec_target}
    DEPENDS ${spec_out}
  )

  list(APPEND spec_targets ${spec_target})
  list(APPEND spec_files ${spec_out})
endforeach()

# All of the sla spec targets are combined into this one
add_custom_target(sleigh_all_sla_specs ALL DEPENDS
  ${spec_targets}
)

#
# Examples
#

if(SLEIGH_ENABLE_EXAMPLES)
  add_executable(sleighexample
    "${library_root}/sleighexample.cc"
  )

  target_link_libraries(sleighexample PRIVATE
    sla
    decomp
  )

  add_custom_target(sleighexample_runner
    "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/specfiles"
    COMMAND "${CMAKE_COMMAND}" -E create_symlink "${spec_files_root_dir}/x86/data/languages/x86.sla" "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla"
    COMMAND sleighexample disassemble
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  )

  add_dependencies(
    sleighexample_runner
    sleigh_spec_x86
  )
endif()

#
# Install targets
#

if(SLEIGH_ENABLE_INSTALL)
  include("GNUInstallDirs")

  install(
    TARGETS
      sleigh_settings

    EXPORT
      "${PROJECT_NAME}"
  )

  install(
    TARGETS
      decomp_opt
      ghidra_opt
      sleigh_opt

    EXPORT
      "${PROJECT_NAME}"

    DESTINATION
      "${CMAKE_INSTALL_BINDIR}"

    PERMISSIONS
      OWNER_READ OWNER_WRITE OWNER_EXECUTE
      GROUP_READ GROUP_EXECUTE
      WORLD_READ WORLD_EXECUTE
  )

  install(
    TARGETS
      sla
      decomp

    EXPORT
      "${PROJECT_NAME}"

    LIBRARY DESTINATION
      "${CMAKE_INSTALL_LIBDIR}"

    INCLUDES DESTINATION
      include

    PUBLIC_HEADER DESTINATION
      "${CMAKE_INSTALL_INCLUDEDIR}/sleigh"

    PERMISSIONS
      OWNER_READ OWNER_WRITE OWNER_EXECUTE
      GROUP_READ GROUP_EXECUTE
      WORLD_READ WORLD_EXECUTE
  )

  # Install the compiled sla files found in 'Ghidra' top-level directory
  install(
    DIRECTORY
      "${spec_files_build_dir}"

    DESTINATION
      "${CMAKE_INSTALL_DATADIR}/sleigh"
  )

  set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_DATAROOTDIR}/doc/sleigh")

  install(
    DIRECTORY
      "${documentation_output}"

    DESTINATION
      "${CMAKE_INSTALL_DOCDIR}"
  )

  set(public_include_header_list
    "${library_root}/address.hh"
    "${library_root}/context.hh"
    "${library_root}/emulate.hh"
    "${library_root}/error.hh"
    "${library_root}/float.hh"
    "${library_root}/globalcontext.hh"
    "${library_root}/loadimage.hh"
    "${library_root}/memstate.hh"
    "${library_root}/opbehavior.hh"
    "${library_root}/opcodes.hh"
    "${library_root}/partmap.hh"
    "${library_root}/pcoderaw.hh"
    "${library_root}/semantics.hh"
    "${library_root}/sleighbase.hh"
    "${library_root}/sleigh.hh"
    "${library_root}/slghpatexpress.hh"
    "${library_root}/slghpattern.hh"
    "${library_root}/slghsymbol.hh"
    "${library_root}/space.hh"
    "${library_root}/translate.hh"
    "${library_root}/types.h"
    "${library_root}/xml.hh"
    "${PROJECT_SOURCE_DIR}/include/libsleigh.hh"
  )

  install(
    FILES
      ${public_include_header_list}

    DESTINATION
      "${CMAKE_INSTALL_INCLUDEDIR}/sleigh"
  )

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(output_folder_path "${CMAKE_CURRENT_BINARY_DIR}/symlinks")

    add_custom_command(
      OUTPUT "${output_folder_path}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/symlinks"
      COMMENT "sleigh: Generating symlink folder"
      VERBATIM
    )

    add_custom_target(sleigh_symlinks_folder_builder DEPENDS
      "${output_folder_path}"
    )

    add_custom_target(sleigh_symlinks_builder ALL)

    foreach(target_name "decomp"
                        "ghidra"
                        "sleigh")

      set(source_name "${target_name}_dbg")
      set(destination_name "${target_name}_opt")
      set(output_path "${output_folder_path}/${destination_name}")

      add_custom_command(
        OUTPUT "${output_path}"
        COMMAND "${CMAKE_COMMAND}" -E create_symlink "${source_name}" "${destination_name}"
        WORKING_DIRECTORY "${output_folder_path}"
        COMMENT "sleigh: Generating executable symlink: ${source_name} -> ${destination_name}"
        VERBATIM
      )

      set(target_name "sleigh_${source_name}_symlink_builder")
      add_custom_target("${target_name}" DEPENDS
        "${output_path}"
      )

      add_dependencies("${target_name}"
        sleigh_symlinks_folder_builder
      )

      add_dependencies(sleigh_symlinks_builder
        "${target_name}"
      )

      install(
        FILES
          "${output_path}"

        DESTINATION
          "${CMAKE_INSTALL_BINDIR}"

        PERMISSIONS
          OWNER_READ OWNER_WRITE OWNER_EXECUTE
          GROUP_READ GROUP_EXECUTE
          WORLD_READ WORLD_EXECUTE
      )
    endforeach()
  endif()

  install(
    EXPORT "${PROJECT_NAME}"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
    NAMESPACE "${PROJECT_NAME}::"
    FILE "${PROJECT_NAME}Config.cmake"
  )
endif()

add_subdirectory(tools)
