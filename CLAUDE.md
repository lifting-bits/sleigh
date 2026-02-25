# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sleigh is a CMake-based build system for Ghidra's Sleigh/decompiler C++ libraries (by Trail of Bits). It wraps NSA's Ghidra source code — fetched via CMake FetchContent during configure — so the Sleigh disassembly and decompilation engines can be built as standalone C++ libraries for reuse outside Ghidra.

**The actual Ghidra C++ source is not in this repo.** It is cloned from GitHub automatically during CMake configuration.

## Build Commands

```sh
# Standard build (fetches Ghidra source on first configure)
cmake -B build -S .
cmake --build build -j$(nproc)

# CI-style build with developer mode (enables tests, docs, warnings)
cmake --preset=ci-ubuntu
cmake --build build -j$(nproc)

# Build with HEAD (bleeding-edge) Ghidra instead of stable
cmake -B build -S . -Dsleigh_RELEASE_TYPE=HEAD

# Use a local Ghidra checkout (avoids re-cloning)
cmake -B build -S . -Dsleigh_RELEASE_TYPE=HEAD \
  -DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE=/path/to/ghidra

# Sanitizer build
cmake --preset=ci-sanitize
cmake --build build/sanitize -j$(nproc)
```

## Running Tests

Tests require `sleigh_DEVELOPER_MODE=ON` (enabled by all `ci-*` presets).

```sh
# Run all tests
cd build && ctest -VV

# Run specific test by name
cd build && ctest -VV -R sleigh_decomp_unittest    # unit tests
cd build && ctest -VV -R sleigh_decomp_datatest     # data-driven tests
cd build && ctest -VV -R sleigh_namespace_std_test   # header hygiene check
```

Test binary: `sleigh_decomp_test` — wraps Ghidra's own test suite. Takes `-sleighpath` for compiled .sla files and a test mode (`unittests` or `datatests`).

## Architecture

### Library Targets

| Target | Library | C++ Std | Description |
|--------|---------|---------|-------------|
| `sleigh::sla` | `sla` | C++11 | Core sleigh: disassembly, encoding, p-code, emulation |
| `sleigh::decomp` | `decomp` | C++11 | Full decompiler (superset of sla) |
| `sleigh::support` | `slaSupport` | C++17 | Trail of Bits helpers: `FindSpecFile()`, version info |

Headers: `<ghidra/*.hh>` for upstream Ghidra headers, `<sleigh/*.h>` for ToB additions.

### Key Directories

- `src/setup-ghidra-source.cmake` — Pinned Ghidra versions, FetchContent, source file lists, patch application. **This is the central file for version bumps and source management.**
- `src/patches/{stable,HEAD}/` — Git-format patches applied to Ghidra source during fetch
- `src/spec_files_{stable,HEAD}.cmake` — Lists of ~148 .slaspec files to compile
- `tools/` — Ghidra executables (sleigh compiler, decompiler, ghidra service)
- `support/` — Trail of Bits support library (C++17)
- `extra-tools/sleigh-lift/` — Demo tool for disassembly/p-code lifting
- `cmake/modules/sleighCompile.cmake` — `sleigh_compile()` function exported for downstream users

### How Ghidra Source Integration Works

1. `src/setup-ghidra-source.cmake` pins a Ghidra git ref (tag for stable, commit hash for HEAD)
2. CMake FetchContent clones from `github.com/NationalSecurityAgency/ghidra`
3. Patches from `src/patches/` are applied via `git am`
4. Source file lists reference into `Ghidra/Features/Decompiler/src/decompile/cpp/`
5. Headers are copied into `build/include/ghidra/` for clean include paths

### Two Release Tracks

- **stable** (default): Pinned to a Ghidra release tag (e.g., `Ghidra_12.0.3_build`). Shallow clone.
- **HEAD**: Pinned to a specific commit on Ghidra main. Full clone. Updated weekly by CI via `scripts/update_ghidra_head.py`.

## Patch System

Patches fix upstream Ghidra bugs (UB sanitizer issues, portability, strict weak ordering violations) without changing Sleigh functionality. They are standard `git format-patch` files.

- `src/patches/stable/` — Patches for stable release
- `src/patches/HEAD/` — Superset of stable patches plus HEAD-specific fixes
- Custom patches via: `-Dsleigh_ADDITIONAL_PATCHES="path/to/patch1;path/to/patch2"`

When adding patches: create with `git format-patch`, number sequentially, and add to both directories if applicable. Patches in HEAD must be a superset of stable patches.

## Key Gotchas

- **In-source builds are forbidden** — enforced by `cmake/prelude.cmake`
- **First configure is slow** — Ghidra repo clone takes time (especially HEAD which can't shallow clone)
- **Core libraries are C++11** — the support library and extra tools are C++17, but `sleigh::sla` and `sleigh::decomp` must stay C++11
- **Source file lists are manual** — when Ghidra adds/removes .cc files, `src/setup-ghidra-source.cmake` must be updated; the `scripts/update_ghidra_head.py` script detects new files and flags them
- **Strict weak ordering** — a recurring class of upstream bugs in Ghidra comparators; several patches fix these
- **Spec files differ between releases** — `src/spec_files_stable.cmake` and `src/spec_files_HEAD.cmake` are separate lists and must be maintained independently

## CMake Presets Reference

| Preset | Use Case |
|--------|----------|
| `ci-ubuntu` | Linux dev build with warnings and tests |
| `ci-macos` | macOS dev build |
| `ci-windows` | Windows dev build (VS 2022, vcpkg) |
| `ci-sanitize` | ASan + UBSan (builds to `build/sanitize/`) |
| `ci-coverage` | Code coverage (builds to `build/coverage/`) |

## Code Style

- `.clang-format`: BasedOnStyle LLVM
- Compiler warnings are strict in CI (see `flags-unix`/`flags-windows` presets)
