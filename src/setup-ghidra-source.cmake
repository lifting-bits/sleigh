# ---- Setup Ghidra Source code ----

# Set up Ghidra repo human-readable version settings
set(sleigh_RELEASE_TYPE "stable" CACHE
  STRING "Release type to use. 'HEAD' is used for active development purposes."
)

# This is just helper for CMake UIs. CMake does not enforce that the value matches one of those listed.
set_property(CACHE sleigh_RELEASE_TYPE PROPERTY STRINGS "stable" "HEAD")

# **** Setup pinned git info ****

# Ghidra pinned stable version commit
set(ghidra_version "10.1.5")
set(ghidra_git_tag "Ghidra_${ghidra_version}_build")
set(ghidra_shallow TRUE)

# pinned stable patches list
set(ghidra_patches
  PATCH_COMMAND git am --ignore-space-change --ignore-whitespace --no-gpg-sign
  "${CMAKE_CURRENT_SOURCE_DIR}/patches/stable/0001-Small-improvements-to-C-decompiler-testing-from-CLI.patch"
  "${CMAKE_CURRENT_SOURCE_DIR}/patches/stable/0002-Add-include-guards-to-decompiler-C-headers.patch"
  "${CMAKE_CURRENT_SOURCE_DIR}/patches/stable/0003-Fix-UBSAN-errors-in-decompiler.patch"
)

# Ghidra pinned commits used for pinning last known working HEAD commit
if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
  # TODO: Try to remember to look at Ghidra/application.properties
  # TODO: CMake only likes numeric characters in the version string....
  set(ghidra_head_version "10.2")
  set(ghidra_version "${ghidra_head_version}")
  set(ghidra_head_git_tag "3aac7dae75b6f8cd60152086a778e1f9248ce9fb")
  set(ghidra_git_tag "${ghidra_head_git_tag}")
  set(ghidra_shallow FALSE)
  set(ghidra_patches
    PATCH_COMMAND git am --ignore-space-change --ignore-whitespace --no-gpg-sign
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/HEAD/0001-Small-improvements-to-C-decompiler-testing-from-CLI.patch"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/HEAD/0002-Initialize-ID-lookup-tables-to-fix-sleighexample.patch"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/HEAD/0003-Add-include-guards-to-decompiler-C-headers.patch"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/HEAD/0004-Fix-UBSAN-errors-in-decompiler.patch"
  )
  string(SUBSTRING "${ghidra_git_tag}" 0 7 ghidra_short_commit)
else()
  set(ghidra_short_commit "${ghidra_git_tag}")
endif()

list(APPEND ghidra_patches ${sleigh_ADDITIONAL_PATCHES})

message(STATUS "Using Ghidra version ${ghidra_version} at git ref ${ghidra_short_commit}")

include(FetchContent)

# Verbose fetch content updates
set(FETCHCONTENT_QUIET OFF)

# Write out source directory with identifiable version info
FetchContent_Declare(GhidraSource
  GIT_REPOSITORY https://github.com/NationalSecurityAgency/ghidra
  GIT_TAG ${ghidra_git_tag}
  GIT_PROGRESS TRUE
  GIT_SHALLOW ${ghidra_shallow}
  ${ghidra_patches}
)
FetchContent_MakeAvailable(GhidraSource)

message(STATUS "Ghidra source located at '${ghidrasource_SOURCE_DIR}'")

# Sanity check on Ghidra source code checkout
set(library_root "${ghidrasource_SOURCE_DIR}/Ghidra/Features/Decompiler/src/decompile/cpp")

if(NOT EXISTS "${library_root}/sleigh.hh")
  message(FATAL_ERROR "The Ghidra source directory has not been initialized correctly. Could not find '${library_root}'")
endif()
