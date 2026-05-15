# Patching Workflow for Ghidra Source

## Overview

Ghidra source is fetched via CMake FetchContent from GitHub. Patches are applied
automatically during the configure step using `git am`. The patch files live in
the Sleigh repo and are version-controlled.

## Directory Structure

```
src/patches/
├── HEAD/       # Patches for the HEAD (development) Ghidra commit
│   ├── 0001-Fix-UBSAN-errors-in-decompiler.patch
│   ├── 0002-Use-stroull-instead-of-stroul-to-parse-address-offse.patch
│   └── ...
└── stable/     # Patches for the stable Ghidra release
    ├── 0001-Fix-UBSAN-errors-in-decompiler.patch
    └── ...
```

## Key Configuration

The base commit and patch list are defined in `src/setup-ghidra-source.cmake`:

- `ghidra_head_git_tag`: The pinned HEAD commit hash
- `ghidra_version` / `ghidra_git_tag`: The stable version tag
- `ghidra_patches`: The ordered list of patch files to apply

## Step-by-Step: Creating a New Patch

### 1. Identify the build preset

Determine which build you're fixing. The Ghidra source checkout location depends
on the preset:

```
build/<preset>/_deps/ghidrasource-src/
```

For example:
```
build/ci-head-assertions/_deps/ghidrasource-src/
```

The C++ source files are in:
```
build/<preset>/_deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/cpp/
```

### 2. Make the fix

Edit the file directly in the Ghidra source checkout. The file already has all
existing patches applied, so you're working on top of the current patch stack.

### 3. Commit in the Ghidra source checkout

```bash
cd build/<preset>/_deps/ghidrasource-src

# In a fresh container, git may require identity configuration before committing:
# git config user.name "Your Name" && git config user.email "your@email.com"

git add Ghidra/Features/Decompiler/src/decompile/cpp/<file>.cc
git commit -m "decompiler: Short description

Longer explanation of the bug and fix. Mention what assertion or test
was failing and why."
```

Commit message conventions:
- Prefix with `decompiler:` for decompiler fixes
- First line should be concise (under 72 chars)
- Body explains the *why*, not just the *what*

### 4. Generate patch files

Use `git format-patch` to regenerate ALL patches from the base commit:

```bash
# Get the base commit from src/setup-ghidra-source.cmake
# For HEAD: it's the ghidra_head_git_tag value
# For stable: it's the Ghidra_X.Y.Z_build tag

git format-patch -o /workspaces/sleigh/src/patches/HEAD/ <base_commit>..HEAD
```

This regenerates patches 0001 through 000N. Existing patches will be regenerated
with updated numbering in the `[PATCH N/M]` subject line, but the content stays
the same. The new patch gets the next number.

### 5. Register in CMake

Edit `src/setup-ghidra-source.cmake` and add the new patch file to the appropriate
`ghidra_patches` list:

```cmake
"${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0006-your-new-patch-name.patch"
```

### 6. Verify from scratch

Clean the cached source so FetchContent re-fetches and applies all patches fresh:

```bash
rm -rf build/<preset>/_deps/ghidrasource-*
cmake --preset <preset>
cmake --build build/<preset>
ctest --test-dir build/<preset> --output-on-failure
```

Watch the configure output for:
```
Applying: <your commit message>
```

If a patch fails to apply, you'll see `Patch failed at NNNN ...` during configure.

## HEAD vs Stable

- **HEAD patches** (`src/patches/HEAD/`): Applied to the development commit. May
  include fixes for newly added files (e.g., `bitfield.cc` is HEAD-only).
- **Stable patches** (`src/patches/stable/`): Applied to the release tag. These
  are typically a subset of HEAD patches that also apply to stable.

Check `src/setup-ghidra-source.cmake` to see which files are HEAD-only (look for
`if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")` blocks).

## Troubleshooting

### Patch fails to apply

If `git am` fails during configure, the Ghidra source checkout may be in a dirty
state. Clean it:

```bash
rm -rf build/<preset>/_deps/ghidrasource-*
```

Then reconfigure. If the patch itself is wrong, fix it and try again.

### Patches conflict with new Ghidra commit

When updating the pinned Ghidra HEAD commit, existing patches may not apply cleanly.
See the [wiki](https://github.com/lifting-bits/sleigh/wiki/Patching-and-Updating)
for the full rebasing procedure.

### Source already patched from manual edits

If you edited files directly in the checkout and then try to reconfigure, CMake
may try to apply patches on top of already-patched code. Always clean the
`_deps/ghidrasource-*` directories before reconfiguring after generating new
patches.
