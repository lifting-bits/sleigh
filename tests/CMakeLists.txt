#
# Tests from ghidra repo
#

add_executable(sleigh_ghidra_test
  ${sleigh_core_source_list}
  ${sleigh_deccore_source_list}
  ${sleigh_source_list}
  ${sleigh_extra_source_list}

  "${library_root}/test.cc"

  "${library_root}/../unittests/testcirclerange.cc"
  "${library_root}/../unittests/testfloatemu.cc"
  "${library_root}/../unittests/testtypes.cc"
)

target_compile_features(sleigh_ghidra_test PRIVATE cxx_std_11)
target_include_directories(sleigh_ghidra_test PRIVATE "${library_root}")
if(WIN32)
  target_compile_definitions(sleigh_ghidra_test PRIVATE
    __TERMINAL__
  )
endif()
sleigh_add_optional_defines(sleigh_ghidra_test PRIVATE)

add_test(
  NAME sleigh_ghidra_unittest
  COMMAND sleigh_ghidra_test -sleighpath "${PROJECT_BINARY_DIR}" unittests
)

add_test(
  NAME sleigh_ghidra_datatest
  COMMAND sleigh_ghidra_test -sleighpath "${PROJECT_BINARY_DIR}"
    -path "${library_root}/../datatests"
    datatests
)
