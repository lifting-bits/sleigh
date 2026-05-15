---
name: sleigh-ghidra-release
description: Update the lifting-bits/sleigh repository for a new upstream Ghidra stable release. Use when bumping Ghidra stable tags or versions, porting or regenerating src/patches/stable from HEAD patches, updating Ghidra source or spec file lists, moving HEAD-only source/header entries into stable, validating local Ghidra builds, or preparing release-update commits and PRs.
---

# Sleigh Ghidra Release

## Overview

Update this repository after NSA publishes a new Ghidra release. Prefer the repo's existing release-update shape: verify the upstream tag, reuse `src/ghidra-stable`, regenerate stable patches mechanically from HEAD patches where possible, update CMake lists, and validate with a local build.

Read [references/release-checklist.md](references/release-checklist.md) when doing the update; it contains the detailed checklist and decision points.

## Workflow

1. Inspect state before changing anything:
   - Run `git status --short`.
   - Treat existing edits and untracked files as user-owned unless the task clearly says otherwise.
   - Keep unrelated files out of release-update commits.

2. Verify the target release:
   - Use official upstream sources for release and tag facts.
   - Prefer Exa MCP tools for web lookup when available.
   - Confirm the tag format, usually `Ghidra_<version>_build`.

3. Prepare `src/ghidra-stable`:
   - Use the existing checkout when present.
   - If a clone is needed, clone under `src/`.
   - Normalize `origin` to HTTPS if the remote uses a local SSH alias:

```bash
git -C src/ghidra-stable remote set-url origin https://github.com/NationalSecurityAgency/ghidra.git
```

   - Fetch and check out the release tag:

```bash
git -C src/ghidra-stable fetch origin tag Ghidra_<version>_build --depth=1
git -C src/ghidra-stable checkout --detach Ghidra_<version>_build
git -C src/ghidra-stable config user.name "github-actions[bot]"
git -C src/ghidra-stable config user.email "41898282+github-actions[bot]@users.noreply.github.com"
```

4. Regenerate stable patches mechanically:
   - Start from a clean `Ghidra_<version>_build` checkout.
   - Try applying HEAD patches in order.
   - If a HEAD patch fails, inspect whether it is already upstreamed, still needed with adjusted context, or only applies to HEAD-only code. Abort and retry with the applicable subset when needed.
   - Use `format-patch` from `Ghidra_<version>_build..HEAD` to create the new stable patch files.
   - Update `src/setup-ghidra-source.cmake` patch ordering to match the regenerated files.

5. Update release metadata and lists:
   - Set `ghidra_version` in `src/setup-ghidra-source.cmake`.
   - Search for `sleigh_RELEASE_IS_HEAD`; move entries into stable when the release now contains those sources or headers.
   - Update `src/spec_files_stable.cmake` from the release checkout's `.slaspec` inventory.
   - Check `cmake/packaging.cmake` and reset `PACKAGE_VERSION` to `1` when the release cycle requires it.

6. Validate the exact files CMake will use:
   - Re-checkout the release tag in `src/ghidra-stable`.
   - Apply `src/patches/stable/*.patch`.
   - Configure with `FETCHCONTENT_SOURCE_DIR_GHIDRASOURCE` pointing at the local checkout.
   - Build with `cmake --build ... --parallel`.
   - Run `ctest`; if no developer-mode configure was used, `No tests were found` may be expected.

7. Review and commit only when asked:
   - Use `git diff --cached --stat`, `git diff --cached --name-status`, and `git diff --cached --check`.
   - `git diff --check` may flag generated `git format-patch` signature lines; inspect before changing generated patch files.
   - Commit messages must follow the repo's 50/72 rule.
