# SLEIGH

SLEIGH is a machine language translation and disassembly engine that is leveraged as part of the Ghidra decompiler.

This repository exposes a CMake build for SLEIGH so that it can be integrated into other projects.

### Build

```sh
mkdir build/
cd build/
cmake \
    -DCMAKE_INSTALL_PREFIX="<path where sleigh will install>" \
    -G Ninja \
    ../
cmake --build .
cmake --build . --target install
```
