option(sleigh_BUILD_SPECCOMPILER "Build the sleigh spec compiler executable" ON)
option(sleigh_BUILD_DECOMPILER "Build the decompiler executable" ON)
option(sleigh_BUILD_GHIDRA "Build the Ghidra executable" ON)

if(sleigh_BUILD_SPECCOMPILER)
  add_subdirectory(spec-compiler)
endif()

if(sleigh_BUILD_DECOMPILER)
  add_subdirectory(decompiler)
endif()

if(sleigh_BUILD_GHIDRA)
  add_subdirectory(ghidra)
endif()
