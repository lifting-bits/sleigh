# ---- Setup Ghidra Source code ----

# Set up Ghidra repo human-readable version settings
set(SLEIGH_GHIDRA_RELEASE_TYPE "stable" CACHE
  STRING "Ghidra release type to use. Make sure SLEIGH_GHIDRA_COMMIT is the correct corresponding commit. 'HEAD' is used for active development purposes."
)
# This is just helper for CMake UIs. CMake does not enforce that the value matches one of those listed.
set_property(CACHE SLEIGH_GHIDRA_RELEASE_TYPE PROPERTY STRINGS "stable" "HEAD")

# **** Setup pinned git info ****

# Ghidra pinned stable version commit
set(ghidra_version "10.0.4")
set(ghidra_git_tag "5b07797cb859d8801ca3a1e08bda1321ca3ce002")
# pinned stable patches list
set(ghidra_patches "")

# Ghidra pinned commits used for pinning last known working HEAD commit
if("${SLEIGH_GHIDRA_RELEASE_TYPE}" STREQUAL HEAD)
  # TODO: Try to remember to look at Ghidra/application.properties
  # TODO: CMake only likes numeric characters in the version string....
  set(ghidra_version "10.1")
  set(ghidra_git_tag "55b8fcf7d4aeaca37ffb5c947340915d69c84224")
  set(ghidra_patches
    PATCH_COMMAND git am --ignore-space-change --ignore-whitespace --no-gpg-sign
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/HEAD/0001-Fix-arg-parsing-in-sleigh-C-test-runner.patch"
  )
endif()

# For use in the CMake `project` command to set version
set(SLEIGH_GHIDRA_VERSION "${ghidra_version}" CACHE
  STRING "Numeric Ghidra version corresponding to SLEIGH_GHIDRA_RELEASE_TYPE and SLEIGH_GHIDRA_COMMIT. This is used during packaging"
)

set(SLEIGH_GHIDRA_COMMIT "${ghidra_git_tag}" CACHE
  STRING "Ghidra repo commit to use/checkout. Ensure this correct with respect to SLEIGH_GHIDRA_VERSION and SLEIGH_GHIDRA_RELEASE_TYPE."
)
string(SUBSTRING "${ghidra_git_tag}" 0 7 ghidra_short_commit)

message(STATUS "Using Ghidra version ${SLEIGH_GHIDRA_VERSION} at commit ${ghidra_short_commit}")

include(FetchContent)

# Verbose fetch content updates
set(FETCHCONTENT_QUIET OFF)

# Reuse the checkout for multiple build directories
# See https://stackoverflow.com/a/56330645
# Needs to include the generator because it's part of the build, which only
# certain generators understand
get_filename_component(fc_base "./src/cmake_fc_${CMAKE_GENERATOR}_ghidra_${SLEIGH_GHIDRA_RELEASE_TYPE}" REALPATH BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(FETCHCONTENT_BASE_DIR "${fc_base}")

# Write out source directory with identifiable version info
FetchContent_Declare(GhidraSource
  GIT_REPOSITORY https://github.com/NationalSecurityAgency/ghidra
  GIT_TAG "${SLEIGH_GHIDRA_COMMIT}"
  GIT_PROGRESS TRUE
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/ghidra_${SLEIGH_GHIDRA_RELEASE_TYPE}_${SLEIGH_GHIDRA_VERSION}_${ghidra_short_commit}"
  ${ghidra_patches}
)
FetchContent_MakeAvailable(GhidraSource)

message(STATUS "Ghidra source located at '${ghidrasource_SOURCE_DIR}'")

# Sanity check on Ghidra source code checkout
set(library_root "${ghidrasource_SOURCE_DIR}/Ghidra/Features/Decompiler/src/decompile/cpp")
if(NOT EXISTS "${library_root}/sleigh.hh")
  message(FATAL_ERROR "The Ghidra source directory has not been initialized correctly. Could not find '${library_root}'")
endif()
