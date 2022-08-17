cmake_minimum_required(VERSION 3.18)

include(../cmake/prelude.cmake)

# We include this because the source code for this example is in upstream
include(../src/setup-ghidra-source.cmake)

project(sleigh_example
    VERSION "${ghidra_version}"
    DESCRIPTION "Sleigh example"
    HOMEPAGE_URL "https://github.com/lifting-bits/sleigh"
    LANGUAGES CXX
)

include(../cmake/project-is-top-level.cmake)

if(NOT TARGET sleigh::sla)
  find_package(sleigh)
  if(NOT sleigh_FOUND)
    message(WARNING "Could not find sleigh library, building from source")
    # Exclude from all because there are no install rules for the example
    # See sleigh-lift for example with install rules
    add_subdirectory(.. sleigh EXCLUDE_FROM_ALL)
  endif()
endif()

add_executable(sleigh_example
  "${library_root}/sleighexample.cc"
)

target_compile_features(sleigh_example PRIVATE cxx_std_11)
sleigh_add_optional_defines(sleigh_example PRIVATE)
target_link_libraries(sleigh_example PRIVATE
  sleigh::sla
)

set_target_properties(sleigh_example PROPERTIES
  OUTPUT_NAME sleighexample
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
    REQUIRED
  )
  set(sleigh_compiler "${SLEIGH_EXECUTABLE}")
else()
  # Try to find/acquire or bootstrap the sleigh spec compiler
  # Logic is repeated in sleighspecs/CMakeLists.txt
  if(NOT TARGET sleigh::sleigh)
    find_package(sleigh QUIET)
    if(NOT sleigh_FOUND OR NOT TARGET sleigh::sleigh)
      find_program(
        SLEIGH_EXECUTABLE sleigh
        DOC "Path to host system sleigh compiler"
      )
      if(NOT SLEIGH_EXECUTABLE)
        message(WARNING "Could not find sleigh compiler, building from source")
        set(saved_skip_install_rules "${CMAKE_SKIP_INSTALL_RULES}")
        set(CMAKE_SKIP_INSTALL_RULES TRUE)
        add_subdirectory(../tools/spec-compiler spec-compiler EXCLUDE_FROM_ALL)
        set(CMAKE_SKIP_INSTALL_RULES "${saved_skip_install_rules}")
      endif()
    endif()
  endif()
endif()
if(SLEIGH_EXECUTABLE)
  set(sleigh_compiler "${SLEIGH_EXECUTABLE}")
else()
  set(sleigh_compiler "$<TARGET_FILE:sleigh::sleigh>")
endif()

# Compile the sla file
include(../cmake/modules/sleighCompile.cmake)

sleigh_compile(
  TARGET sleigh_example_sleigh_spec_x86
  COMPILER "${sleigh_compiler}"
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
