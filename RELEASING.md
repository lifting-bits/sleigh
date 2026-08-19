# Cutting a Release

Releases are built and published automatically by CI when a version tag is
pushed. This repository uses GitHub [immutable
releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases):
once a release is published, its assets and tag are permanently frozen, so
the pipeline uploads everything to a *draft* release and publishes only
after all assets are verified present.

## Prerequisites

- The Ghidra version-update PR is merged to `master` (see the
  [release update checklist](https://github.com/lifting-bits/sleigh/wiki/New-Ghidra-Release-Update-Checklist)).
- CI is green on `master` for that commit.

## Steps

1. Tag the release commit on `master`. Tags are lightweight and named
   `v<ghidra_version>`:

   ```sh
   git switch master && git pull
   git tag v12.1.3
   git push origin v12.1.3
   ```

2. Watch the `Build` workflow run for the tag. It will:
   - create a draft release titled `Sleigh v<version>` with auto-generated
     notes (`draft-release` job);
   - build on Linux/macOS/Windows and upload the five release assets to the
     draft (`.tar.gz` per OS, plus `.deb` and `.rpm` from Linux);
   - verify the draft has all five assets, then publish it
     (`publish-release` job). Publishing is what makes the release
     immutable.

3. Optionally edit the release notes. Title and notes remain editable after
   publication; only assets and the tag are frozen.

## If something goes wrong

**Before the release is published** (a build job failed, the draft is
incomplete): nothing is frozen yet. Fix the problem, delete the draft
release and the tag, and re-push the tag:

```sh
gh release delete v12.1.3 --yes
git push --delete origin v12.1.3
git tag -f v12.1.3 <fixed-commit> && git push origin v12.1.3
```

**After the release is published**: the release cannot be changed, and
deleting it permanently retires the tag name — `v12.1.3` could never be
used again, even in a recreated repository. To ship a fix for the same
Ghidra version, bump `PACKAGE_VERSION` in `cmake/packaging.cmake` (e.g. to
`2`) and tag with a suffix, e.g. `v12.1.3-2`.

Re-running the tag's workflow after publication will fail at the
asset-upload steps; that is immutability working as intended.
