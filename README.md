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

**NOTE**: This CMake project pulls the Ghidra source code from the internet during configuration. See the [note on Ghidra source code section](#note-on-ghidra-source-code) for more details.

### Optional

For building documentation:

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
cmake -B build -S .

# Build SLEIGH
cmake --build build -j

# Install SLEIGH
cmake --install build --prefix <path where SLEIGH will install>
```

### Note on Ghidra source code

The Ghidra source code is not actually included in this git repo, and by default, CMake will automatically pull a stable version from the internet for you.

Please see [`src/README.md`](./src/README.md) for more information on how to customize which Ghidra source code commit will be used/compiled, including specifying your own local copy of the Ghidra source.

## Packaging

The CMake configuration also supports building packages for SLEIGH. If the `sleigh_ENABLE_PACKAGING` option is set during the configuration step, the build step will generate a tarball containing the SLEIGH installation. Additionally, the build will create an RPM package if it finds `rpm` in the `PATH` and/or a DEB package if it finds `dpkg` in the `PATH`.

For example:

```sh
cmake -B build -S . \
    -Dsleigh_ENABLE_PACKAGING=ON

# Build SLEIGH
cmake --build build -j

# Package SLEIGH
cmake --build build --target package
```

## API Usage

An example program called `sleigh-lift` has been included to demonstrate how to use the SLEIGH API. It takes a hexadecimal string of bytes and either disassembles it or lifts it to p-code. The program can be invoked like so, where the `action` argument must be either `disassemble` or `pcode`:

```sh
sleigh-lift [action] [sla_file] [bytes] [-a address] [-p root_sla_dir] [-s pspec_file]
```

For example, to disassemble the following byte string:

```sh
$ sleigh-lift disassemble x86-64.sla 4881ecc00f0000
0x00000000: SUB RSP,0xfc0
```

And to lift it to p-code:

```sh
$ sleigh-lift pcode x86-64.sla 4881ecc00f0000
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

The `sleigh_ENABLE_EXAMPLES` option must be set to `ON` during the configuration step in order to build `sleigh-lift`.

## Helpers

This repository contains a helper that is not part of SLEIGH/GHIDRA, which can be found under `support/`. It has the following signature and can help the user find the location of a given spec file on the system:

```c++
std::optional<std::filesystem::path>
FindSpecFile(std::string_view file_name,
             const std::vector<std::filesystem::path> &search_paths =
                 gDefaultSearchPaths);
```

The `sleigh::FindSpecFile` function will search the the paths provided by the user via the `search_paths` argument for a spec file with the name `file_name`. The default argument for `search_paths` is `sleigh::gDefaultSearchPaths` which contains the install/build directories that the CMake project was configured with as well as a set of common installation locations.

## Integration as a Dependency

An installation of sleigh provides a CMake interface that can be used to assist in building your project.

An example of how to use the CMake package config file can be found in the [find_package](tests/find_package/CMakeLists.txt) example.

We also provide a CMake helper function [`sleigh_compile`](cmake/modules/sleighCompile.cmake) to compile your own `.slaspec` files using the installed sleigh compiler from this project.

Lastly, the installed compiled sleigh files can be located through the CMake variable `sleigh_INSTALL_SPECDIR`, which is an absolute path to the root directory for where the compiled sleigh files are located---you should manually inspect this to know what to expect.

Referencing the [CMake config file](cmake/install-config.cmake.in) is also suggested for learning more about the exposed CMake variables and modules.

## License

See the LICENSE file in the top directory of this repo.
