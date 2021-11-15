# SLEIGH Library

[SLEIGH](https://ghidra.re/courses/languages/html/sleigh.html) is a language used to describe the semantics of instruction sets of general-purpose microprocessors, with enough detail to facilitate the reverse engineering of software compiled for these architectures. It is part of the [GHIDRA reverse engineering platform](https://github.com/NationalSecurityAgency/ghidra), and underpins two of its major components: its disassembly and decompilation engines.

This repository provides a CMake-based build project for SLEIGH so that it can be built and packaged as a standalone library, and be reused in projects other than GHIDRA.

## Supported Platforms

| Name | Support |
| ---- | ------- |
| Linux | Yes |
| macOS | Yes |
| Windows | Not yet |

## Dependencies and Prerequisites

### Required

| Name | Version | Linux Package to Install | macOS Homebrew Package to Install |
| ---- | ------- | ------------------------ | --------------------------------- |
| [Git](https://git-scm.com/) | Latest | git | N/A |
| [CMake](https://cmake.org/) | 3.21+ | cmake | cmake |

### Optional

| Name | Version | Linux Package to Install | macOS Homebrew Package to Install |
| ---- | ------- | ------------------------ | --------------------------------- |
| [Doxygen](https://www.doxygen.nl/) | Latest | doxygen | doxygen |
| [GraphViz](https://graphviz.org/) | Latest | graphviz | graphviz |

## Build and Install the SLEIGH Library

```sh
# Clone this repository (CMake project for SLEIGH)
git clone https://github.com/lifting-bits/sleigh.git
cd sleigh

# Configure CMake
cmake -B build -S . \
    -DSLEIGH_ENABLE_INSTALL=ON    

# Build SLEIGH
cmake --build build -j

# Install SLEIGH
cmake --install build --prefix <path where SLEIGH will install>
```

### Note on Ghidra source code

The Ghidra source code is not actually included in this git repo, and by default, CMake will automatically pull a stable version for you.

Please see [`src/README.md`](./src/README.md) for more information on how to customize which Ghidra source code commit will be used/compiled.

## Packaging

The CMake configuration also supports building packages for SLEIGH. If the `SLEIGH_ENABLE_PACKAGING` option is set during the configuration step, the build step will generate a tarball containing the SLEIGH installation. Additionally, the build will create an RPM package if it finds `rpm` in the `PATH` and/or a DEB package if it finds `dpkg` in the `PATH`.

For example:

```sh
cmake -B build -S . \
    -DSLEIGH_ENABLE_PACKAGING=ON

# Build SLEIGH
cmake --build build -j

# Package SLEIGH
cmake --build build --target package
```

## API Usage

An example program called `sleigh-lift` has been included to demonstrate how to use the SLEIGH API. It takes a hexadecimal string of bytes and either disassembles it or lifts it to p-code. The program can be invoked like so, where the `action` argument must be either `disassemble` or `pcode`:

```sh
sleigh-lift [action] [sla_file] [bytes] [address:OPTIONAL]
```

For example, to disassemble the following byte string:

```sh
$ sleigh-lift disassemble <path where SLEIGH is installed>/share/sleigh/Processors/x86/data/languages/x86-64.sla 4881ecc00f0000
0x00000000: SUB RSP,0xfc0
```

And to lift it to p-code:

```sh
$ sleigh-lift pcode <path where SLEIGH is installed>/share/sleigh/Processors/x86/data/languages/x86-64.sla 4881ecc00f0000
(register,0x200,1) = INT_LESS (register,0x20,8) (const,0xfc0,8)
(register,0x20b,1) = INT_SBORROW (register,0x20,8) (const,0xfc0,8)
(register,0x20,8) = INT_SUB (register,0x20,8) (const,0xfc0,8)
(register,0x207,1) = INT_SLESS (register,0x20,8) (const,0x0,8)
(register,0x206,1) = INT_EQUAL (register,0x20,8) (const,0x0,8)
(unique,0x12c00,8) = INT_AND (register,0x20,8) (const,0xff,8)
(unique,0x12c80,1) = POPCOUNT (unique,0x12c00,8)
(unique,0x12d00,1) = INT_AND (unique,0x12c80,1) (const,0x1,1)
(register,0x202,1) = INT_EQUAL (unique,0x12d00,1) (const,0x0,1)
```

The `SLEIGH_ENABLE_EXAMPLES` option must be set to `TRUE` during the configuration step in order to build `sleigh-lift`.

## License

See the LICENSE file in the top directory of this repo.
