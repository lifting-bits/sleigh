---
name: debug-test-failures
version: "1.0.0"
description: >
  This skill should be used when debugging test failures, build errors, runtime
  crashes, or assertion failures in the Sleigh/Ghidra decompiler project. It
  covers building with libc++ hardening assertions (ci-head-assertions preset),
  running ctest, obtaining stack traces from SIGABRT or crash signals, narrowing
  down which datatest triggers a failure, creating patch files for upstream Ghidra
  source in src/patches/, and recognizing common C++ bug patterns such as
  strict-weak ordering violations in comparators. Relevant when encountering
  "the build is failing", "ctest fails", decompiler crashes, or libc++ assertion
  errors.
---

# Debugging Test Failures in the Sleigh Project

This project builds the Ghidra decompiler as a standalone C++ library. Ghidra source
is fetched via CMake FetchContent and patches are applied via `git am`. The key
challenge is that bugs live in upstream Ghidra code and fixes must be packaged as
patch files.

## Quick Reference

```bash
# Build with libc++ assertions (catches strict-weak ordering, container misuse, etc.)
cmake --preset ci-head-assertions
cmake --build build/ci-head-assertions
ctest --test-dir build/ci-head-assertions --output-on-failure

# Clean cached Ghidra source (needed after adding/changing patches)
rm -rf build/ci-head-assertions/_deps/ghidrasource-*

# Where the Ghidra C++ source lives after fetch
build/ci-head-assertions/_deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/cpp/
```

## 0. Prerequisites

### Create `CMakeUserPresets.json`

The `ci-head-assertions` preset used throughout this workflow lives in
`CMakeUserPresets.json`, which is not version-controlled and does **not** exist on
a fresh checkout. You must create it in the repository root before any build
commands will work.

Create `/workspaces/sleigh/CMakeUserPresets.json` with this content:

```json
{
  "version": 2,
  "cmakeMinimumRequired": { "major": 3, "minor": 18, "patch": 0 },
  "configurePresets": [
    {
      "name": "libcxx",
      "hidden": true,
      "cacheVariables": {
        "CMAKE_CXX_COMPILER": "clang++",
        "CMAKE_CXX_FLAGS": "-stdlib=libc++ -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong",
        "CMAKE_EXE_LINKER_FLAGS": "-stdlib=libc++ -lc++abi",
        "CMAKE_SHARED_LINKER_FLAGS": "-stdlib=libc++ -lc++abi"
      }
    },
    {
      "name": "ci-head",
      "hidden": true,
      "inherits": ["ci-ubuntu"],
      "cacheVariables": { "sleigh_RELEASE_TYPE": "HEAD" }
    },
    {
      "name": "ci-head-assertions",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "inherits": ["libcxx", "ci-head"],
      "generator": "Ninja",
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug" }
    }
  ]
}
```

This file inherits from `ci-ubuntu` (defined in `CMakePresets.json`), so the
repo's version-controlled presets must also be present (they always are in a
normal checkout).

## 1. Build Presets

### The assertions preset

The `ci-head-assertions` preset (created in Section 0 above) links against libc++
with `_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG`. This enables runtime
checks that catch undefined behavior in STL usage — most importantly, it validates
that comparators passed to `std::sort` satisfy strict-weak ordering.

### Other useful presets

| Preset | Source | Purpose |
|--------|--------|---------|
| `ci-head-assertions` | `CMakeUserPresets.json` | HEAD build with libc++ debug assertions (primary debugging preset) |
| `ci-head` | `CMakeUserPresets.json` | HEAD build without assertions (faster, hidden/base preset) |
| `ci-sanitize` | `CMakePresets.json` | Stable build with ASan + UBSan (repo-controlled) |

Note: `ci-head-assertions` and `ci-head` are user-local presets created in
Section 0. `ci-sanitize` is the only sanitizer preset version-controlled in the
repo. Add your own sanitizer presets to `CMakeUserPresets.json` as needed.

## 2. Running Tests

```bash
# Run all tests
ctest --test-dir build/ci-head-assertions --output-on-failure

# Run a specific test
ctest --test-dir build/ci-head-assertions -R decomp_datatest --output-on-failure
```

There are typically 3 tests:

| Test | What it does |
|------|--------------|
| `sleigh_decomp_unittest` | Unit tests (fast) |
| `sleigh_decomp_datatest` | Decompiler data tests — runs XML test files from the `datatests/` directory |
| `sleigh_namespace_std_test` | Namespace compilation test |

The datatest exercises the most code paths and is the most likely to trigger
assertion failures from comparator bugs.

### How datatest works

The test binary loads XML files from the datatests directory in alphabetical order.
Each XML file contains binary data + expected decompiler output patterns. The test
decompiles each function and checks the output against `<stringmatch>` patterns.

The exact command ctest uses (check `tests/CTestTestfile.cmake` for the authoritative version):
```bash
./tests/sleigh_decomp_test \
  -sleighpath <build-dir> \
  -path <build-dir>/_deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/datatests \
  datatests
```

## 3. Getting a Stack Trace from a Crash

When a test crashes (e.g., SIGABRT from an assertion), you need a stack trace to
identify which comparator or code path is the culprit. The test binaries may not
have full debug symbols, so multiple techniques may be needed.

See `references/stack-trace-techniques.md` for the full details on each method.
Here's the summary:

1. **gdb**: Use `gdb -batch` for full demangled backtraces — the simplest method
2. **lldb**: Use `lldb -b` with `-k` for crash-time backtrace commands
3. **LD_PRELOAD backtrace**: Build a small shared library that catches SIGABRT and
   prints a backtrace — works when neither debugger can attach (containers)
4. **addr2line**: Resolve raw hex addresses from the backtrace to function names
   and source lines

## 4. Narrowing Down Which Test Triggers a Crash

> **Tip**: Often the stack trace from Section 3 identifies the exact function and
> source line, making this step unnecessary. Use this binary search technique only
> when the stack trace is unclear or you need to isolate which specific test input
> triggers the crash.

When you know the test crashes but can't immediately identify the cause from the
stack trace, use binary search on the test XML files.

The idea: copy subsets of test files to a temporary directory and run the test
binary against that subset. Keep halving until you isolate the triggering file.

```bash
cd build/ci-head-assertions

# Copy a subset of test files to a temporary directory
mkdir -p /tmp/test_subset
SRC=_deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/datatests
for f in $(ls $SRC/*.xml | sort | sed -n '1,20p'); do cp "$f" /tmp/test_subset/; done

# Run just those tests
./tests/sleigh_decomp_test -sleighpath . -path /tmp/test_subset datatests
```

Important: some crashes only reproduce when specific files are processed together
(accumulated state from earlier tests), so start by splitting the full set in half
rather than testing individual files. If an individual file doesn't crash alone, try
combining it with files that ran before it in alphabetical order.

## 5. Creating Patches for Ghidra Source

Patches live in `src/patches/HEAD/` (for HEAD builds) and `src/patches/stable/`
(for stable builds). They are applied via `git am` during the CMake FetchContent
step. See `references/patching-workflow.md` for the full step-by-step.

### Quick workflow

1. **Edit the bug** in `build/<preset>/_deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/cpp/`
2. **Commit**: `cd` into the ghidrasource-src dir, `git add` + `git commit`
3. **Generate patches**: `git format-patch -o /workspaces/sleigh/src/patches/HEAD/ <base_commit>..HEAD`
4. **Register** the new patch in `src/setup-ghidra-source.cmake`
5. **Clean and rebuild**: `rm -rf build/<preset>/_deps/ghidrasource-*` then reconfigure

The base commit for HEAD is the `ghidra_head_git_tag` value in `src/setup-ghidra-source.cmake`.

## 6. Common Bug Patterns

The most common bugs are **strict-weak ordering violations** in comparators used
by `std::sort` or `std::set`. These are caught by libc++ assertions at runtime.
Key patterns include null pointer sentinels that don't check self-comparison,
special index early-returns without checking the other operand, and unsafe casts
in `compareDependency` methods of TypePartial* classes.

See `references/common-bug-patterns.md` for detailed before/after code examples,
real-world instances from the codebase (e.g., `PullRecord::operator<` in
`bitfield.cc`, `FlowBlock::compareFinalOrder` in `block.cc`), and a systematic
audit checklist for finding new comparator bugs.
