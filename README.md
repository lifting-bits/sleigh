# SLEIGH Library

[SLEIGH](https://ghidra.re/courses/languages/html/sleigh.html) is a language used to describe the semantics of instruction sets of general-purpose microprocessors, with enough detail to facilitate the reverse engineering of software compiled for these architectures. It is part of the [GHIDRA reverse engineering platform](https://github.com/NationalSecurityAgency/ghidra), and underpins two of its major components: its disassembly and decompilation engines.

This repository provides a CMake-based build project for SLEIGH so that it can be built and packaged as a standalone library, and be reused in projects other than GHIDRA.

## Supported Platforms

| Name | Support |
| ---- | ------- |
| Linux | Yes |
| macOS | Not yet |
| Windows | Not yet |

## Dependencies and Prerequisites

| Name | Version | Linux Package to Install |
| ---- | ------- | ------- |
| [Git](https://git-scm.com/) | Latest | git |
| [Ninja](https://ninja-build.org/) | Latest | ninja-build |
| [CMake](https://cmake.org/) | 3.21+ | cmake |
| [Binutils](https://www.gnu.org/software/binutils/) | Latest | binutils and binutils-dev |
| [Zlib](https://zlib.net/) | Latest | zlib |
| [Iberty](https://gcc.gnu.org/onlinedocs/libiberty/) | Latest | libiberty-dev |
| [Doxygen](https://www.doxygen.nl/) | Latest | doxygen |
| [GraphViz](https://graphviz.org/) | Latest | graphviz |

## Build and Install the SLEIGH Library

```sh
# Clone this repository (CMake project for SLEIGH)
git clone https://github.com/lifting-bits/sleigh.git
cd sleigh

# Update the GHIDRA submodule
git submodule update --init --recursive --progress

# Create a build directory
mkdir build
cd build

# Configure CMake
cmake \
    -DSLEIGH_ENABLE_INSTALL=ON \
    -DCMAKE_INSTALL_PREFIX="<path where SLEIGH will install>" \
    -G Ninja \
    ..

# Build SLEIGH
cmake --build .

# Install SLEIGH
cmake --build . --target install
```

## Packaging

The CMake configuration also supports building packages for SLEIGH. If the `SLEIGH_ENABLE_PACKAGING` option is set during the configuration step, the build step will generate a tarball containing the SLEIGH installation. Additionally, the build will create an RPM package if it finds `rpm` in the `PATH` and/or a DEB package if it finds `dpkg` in the `PATH`.

For example:

```sh
cmake \
    -DSLEIGH_ENABLE_PACKAGING=ON \
    -DCMAKE_INSTALL_PREFIX="<path where SLEIGH will install>" \
    -G Ninja \
    ..

# Build SLEIGH
cmake --build .

# Package SLEIGH
cmake --build . --target package
```

## License

See the LICENSE file in the top directory of this repo.
