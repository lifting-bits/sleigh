# Ghidra Source code

This directory is empty until the project is configured with CMake.

CMake will automatically download the version of Ghidra you configured to this directory and apply any patches, as specified in the top-level [patches](./patches) directory.

See the `SLEIGH_GHIDRA_*` CMake cache variables for more details.

## Implementation Note

Due to wanting to share a single source checkout for multiple build directories, the [_FetchContent Base Directory_](https://cmake.org/cmake/help/latest/module/FetchContent.html#variable:FETCHCONTENT_BASE_DIR) (`FETCHCONTENT_BASE_DIR`) encodes the build generator name and will be located alongside the actual Ghidra source directory checkout (`cmake_fc_${CMAKE_GENERATOR}_ghidra_*` at time of writing; see `setup-ghidra-source.cmake` for implementation).

Initially, this means that every new build generator used for building the project will have to re-download the ghidra source tree, but any subsequent run with an already-initialize generator should be faster and skip the download.

## Using your own Ghidra checkout

This project uses CMake's [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html) module to set up the Ghidra source tree. This means we can apply [patches](./patches) that live only in this repo for small changes to things like packaging or running tests. If you want to use your own Ghidra source checkout, then run include the following in the root of the repository, making sure to set `-DSLEIGH_GHIDRA_RELEASE_TYPE=HEAD` before pointing `FETCHCONTENT_SOURCE_DIR_GHIDRASOURCE` to your own checkout. No existing patches will be applied on your own specified source directory.

```sh
git clone https://github.com/NationalSecurityAgency/ghidra src/ghidra
cmake -B build-dev-head -S . \
  -DSLEIGH_GHIDRA_RELEASE_TYPE=HEAD \
  -DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE="$(pwd)/src/ghidra"
```
