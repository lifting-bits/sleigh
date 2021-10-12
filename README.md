# SLEIGH

SLEIGH was designed for the GHIDRA reverse engineering platform and is used to describe microprocessors with enough detail to facilitate two major components of GHIDRA, the disassembly and decompilation engines.

This repository provides a CMake build of SLEIGH so that it can be built and packaged as a standalone library.

## Dependencies

| Name | Version |
| ---- | ------- |
| [Git](https://git-scm.com/) | Latest |
| [CMake](https://cmake.org/) | 3.21+ |
| [Binutils](https://www.gnu.org/software/binutils/) | Latest |
| [Zlib](https://zlib.net/) | Latest |
| [Iberty](https://gcc.gnu.org/onlinedocs/libiberty/) | Latest |
| [Doxygen](https://www.doxygen.nl/) | Latest |
| [GraphViz](https://graphviz.org/) | Latest |

## Installation

```sh
# Clone SLEIGH repository
git clone https://github.com/lifting-bits/sleigh.git

# Update the Ghidra submodule
git submodule update --init --recursive

# Create build directory
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

The CMake configuration also supports building RPM or DEB packages for SLEIGH. If the `SLEIGH_ENABLE_PACKAGING` option is set, the build will create an RPM package if it finds `rpm` in the `PATH` or a DEB package if it finds `dpkg` in the `PATH`.
```sh
cmake \
    -DSLEIGH_ENABLE_PACKAGING=ON \
    -DCMAKE_INSTALL_PREFIX="<path where SLEIGH will install>"
    -G Ninja \
    ..
```
