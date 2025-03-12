# This module configures ccache to work with MSVC
# Based on: https://github.com/ccache/ccache/wiki/MS-Visual-Studio

# Only do this for Windows MSVC builds
if(NOT WIN32 OR NOT CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  return()
endif()

# Assume the parent environment has this set
# Chocolatey creates a shim which doesn't work when renamed
set(CCACHE_EXE "$ENV{CCACHE_EXE}")
if(NOT CCACHE_EXE)
  message(STATUS "ccache not found - MSVC ccache support disabled")
  return()
endif()
message(STATUS "Found ccache - ${CCACHE_EXE}")

message(STATUS "Configuring ccache for MSVC")

file(COPY_FILE
    "${CCACHE_EXE}" "${CMAKE_BINARY_DIR}/cl.exe"
    ONLY_IF_DIFFERENT)

# By default Visual Studio generators will use /Zi which is not compatible
# with ccache, so tell Visual Studio to use /Z7 instead.
message(STATUS "Setting MSVC debug information format to 'Embedded'")
set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<$<CONFIG:Debug,RelWithDebInfo>:Embedded>")

set(CMAKE_VS_GLOBALS
    "CLToolExe=cl.exe"
    "CLToolPath=${CMAKE_BINARY_DIR}"
    "UseMultiToolTask=true"
    "DebugInformationFormat=OldStyle"
    )
