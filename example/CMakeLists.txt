cmake_minimum_required(VERSION 3.18)

include(../cmake/prelude.cmake)
include(../src/setup-ghidra-source.cmake)

project(sleigh_example
    VERSION "${ghidra_version}"
    DESCRIPTION "Sleigh example"
    HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
    LANGUAGES CXX
)

include(../cmake/project-is-top-level.cmake)

if(PROJECT_IS_TOP_LEVEL)
  find_package(sleigh)
  if(sleigh_NOT_FOUND)
    message(WARNING "Could not find sleigh, building from source")
  endif()
endif()

if(NOT TARGET sleigh::sla)
  add_subdirectory(.. sleigh EXCLUDE_FROM_ALL)
endif()

add_executable(sleigh_example
  "${library_root}/sleighexample.cc"
)

target_compile_features(sleigh_example PRIVATE cxx_std_11)
sleigh_add_optional_defines(sleigh_example PRIVATE)
target_link_libraries(sleigh_example PRIVATE
  sleigh::sla
)

#
# Compile our required sleigh spec file
#
# Get the native machine's sleigh compiler or use the one we're about to build
# if not cross compiling
if(CMAKE_CROSSCOMPILING)
  find_program(
    SLEIGH_EXECUTABLE sleigh
    DOC "Path to host system sleigh compiler"
  )
else()
  if(NOT TARGET sleigh::sleigh)
    add_subdirectory(../tools/spec-compiler)
  endif()
  set(
    SLEIGH_EXECUTABLE "$<TARGET_FILE:sleigh::sleigh>"
    CACHE FILEPATH "Path to host system sleigh compiler"
  )
endif()

if(NOT DEFINED sleigh_compile)
  include(../cmake/modules/sleighCompile.cmake)
endif()

# Compile the sla file
sleigh_compile(
  TARGET sleigh_example_sleigh_spec_x86
  COMPILER "${SLEIGH_EXECUTABLE}"
  SLASPEC "${ghidrasource_SOURCE_DIR}/Ghidra/Processors/x86/data/languages/x86.slaspec"
  LOG_FILE "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla.log"
  OUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/specfiles/x86.sla"
)
set_property(
  TARGET sleigh_example_sleigh_spec_x86
  PROPERTY EXCLUDE_FROM_ALL FALSE
)

#
# Run the example
#
add_custom_target(sleigh_example_runner)
set(example_actions disassemble pcode emulate)
foreach(action ${example_actions})
  add_custom_target(sleigh_example_${action}
    COMMAND sleigh_example ${action}
    COMMENT "Running example ${action}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  )
  add_dependencies(sleigh_example_${action} sleigh_example_sleigh_spec_x86)
  add_dependencies(sleigh_example_runner sleigh_example_${action})
endforeach()
