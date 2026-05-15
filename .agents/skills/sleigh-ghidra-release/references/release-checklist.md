# Release Update Checklist

This checklist is based on the repository wiki page:
https://github.com/lifting-bits/sleigh/wiki/New-Ghidra-Release-Update-Checklist

## Files To Check

- `src/setup-ghidra-source.cmake`: stable version, stable patch list, HEAD pin, source lists.
- `src/patches/stable/`: regenerated patches for the stable Ghidra tag.
- `src/patches/HEAD/`: source patches to port to the new stable release.
- `src/spec_files_stable.cmake`: stable `.slaspec` inventory.
- `src/spec_files_HEAD.cmake`: comparison point for new spec files.
- `CMakeLists.txt`: public Ghidra headers copied into the build include directory.
- `cmake/packaging.cmake`: package version reset when relevant.

## Patch Regeneration

Preferred pattern:

```bash
git -C src/ghidra-stable checkout --detach Ghidra_<version>_build
git -C src/ghidra-stable am --ignore-space-change --ignore-whitespace --no-gpg-sign \
  /absolute/path/to/src/patches/HEAD/*.patch
git -C src/ghidra-stable format-patch -o /private/tmp/sleigh-ghidra-stable-patches \
  Ghidra_<version>_build..HEAD
```

If a patch fails:

- Run `git -C src/ghidra-stable am --abort`.
- Inspect the failed patch and the target source.
- Decide whether the patch is already upstreamed, still needed with refreshed context, or only applicable to HEAD-only code.
- Reapply the exact applicable patch sequence or subset.
- Regenerate stable patches from the resulting commits; avoid hand-editing patch bodies unless conflict resolution requires it.

## Source And Header Lists

Find HEAD-only gates:

```bash
rg -n "sleigh_RELEASE_IS_HEAD|sleigh_RELEASE_TYPE.*HEAD" \
  CMakeLists.txt src cmake support tests
```

When a previously HEAD-only file exists in the new stable release, move it to the normal stable list and leave no dead conditional branch unless the branch still has a purpose.

## Spec Files

Build the stable inventory from the release checkout:

```bash
fd -e slaspec . src/ghidra-stable/Ghidra/Processors
```

Update `src/spec_files_stable.cmake` with sorted
`${ghidrasource_SOURCE_DIR}/...` entries. Compare against both the old stable
list and `src/spec_files_HEAD.cmake`.

## Validation

Verify the generated stable patch files directly:

```bash
git -C src/ghidra-stable checkout --detach Ghidra_<version>_build
git -C src/ghidra-stable am --ignore-space-change --ignore-whitespace --no-gpg-sign \
  /absolute/path/to/src/patches/stable/*.patch
```

Then configure and build Sleigh against the local checkout:

```bash
cmake -B build/ghidra-<version>-local -S . \
  -DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE=/absolute/path/to/src/ghidra-stable
cmake --build build/ghidra-<version>-local --parallel
ctest --test-dir build/ghidra-<version>-local --output-on-failure
```

If tests matter for the update, use a developer-mode preset or option. A plain configure may not register tests.
