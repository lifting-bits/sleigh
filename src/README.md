# Ghidra Source code

This project uses CMake's [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html) module to set up the Ghidra source tree. This means we can apply [patches](../patches) that live only in this repo for small changes to features like packaging or running tests.

By default, CMake pulls a stable version of Ghidra. You may use a more recent commit by specifying `-Dsleigh_RELEASE_TYPE=HEAD` during CMake configuration.

See the `sleigh_GHIDRA_*` CMake cache variable comments for more details on how to customize your Ghidra source checkout.

## Advanced Usage Notes

Always reference the [CMake Documentation](https://cmake.org/cmake/help/latest/) for explanation of features and cache variable usages/effects.

### Using your own Ghidra checkout

This method is useful for developing new features on top of the latest commits in Ghidra's default branch. If the commit(s) at the tip of Ghidra's default branch are not supported by this repo, we welcome pull requests to update support and pin that commit.

**Arbitrary Ghidra checkouts are not officially supported.**

If you want to use your own Ghidra source checkout, then set the following during CMake configuration:

* `-Dsleigh_RELEASE_TYPE=HEAD` if using commits on Ghidra's default branch (`master`) or any branch that may be incompatible with the current stable version.

* `-DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE=<path to your own Ghidra source>`. Remember, no existing [patches](../patches/HEAD) will be applied to your own source directory.

```bash
git clone https://github.com/NationalSecurityAgency/ghidra src/ghidra

cmake -B build-dev-head -S . \
  -Dsleigh_RELEASE_TYPE=HEAD \
  -DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE="$(pwd)/src/ghidra"
```

### Reusing Downloaded Ghidra Source

If you want to share a single Ghidra source checkout/clone for multiple build directories, the [_FetchContent Base Directory_](https://cmake.org/cmake/help/latest/module/FetchContent.html#variable:FETCHCONTENT_BASE_DIR) (`FETCHCONTENT_BASE_DIR`) should encode the build generator name and be located outside of the build directory (the name would look something like `cmake_fc_ghidra_${sleigh_RELEASE_TYPE}_${CMAKE_GENERATOR}`).

Initially, this means that every new build generator used for building the project will have to re-download the ghidra source tree, but any subsequent run with an already-initialize generator should be faster and skip the download.

```bash
$ cmake -B build-release -S . -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DFETCHCONTENT_BASE_DIR=./src/cmake_fc_ghidra_stable_Ninja
-- Using Ghidra version 10.0.4 at commit 5b07797
-- Populating ghidrasource
-- Configuring done
-- Generating done
-- Build files have been written to: /Users/me/sleigh/src/cmake_fc_ghidra_stable_Ninja/ghidrasource-subbuild
[1/9] Creating directories for 'ghidrasource-populate'
[1/9] Performing download step (git clone) for 'ghidrasource-populate'
Cloning into 'ghidrasource-src'...
remote: Enumerating objects: 129964, done.
remote: Counting objects: 100% (4238/4238), done.
remote: Compressing objects: 100% (1889/1889), done.
remote: Total 129964 (delta 2078), reused 3993 (delta 2038), pack-reused 125726
Receiving objects: 100% (129964/129964), 172.50 MiB | 15.10 MiB/s, done.
Resolving deltas: 100% (79637/79637), done.
HEAD is now at 5b07797cb Updated 10.0.4 Change History
[2/9] Performing update step for 'ghidrasource-populate'
[4/9] No patch step for 'ghidrasource-populate'
[5/9] No configure step for 'ghidrasource-populate'
[6/9] No build step for 'ghidrasource-populate'
[7/9] No install step for 'ghidrasource-populate'
[8/9] No test step for 'ghidrasource-populate'
[9/9] Completed 'ghidrasource-populate'
-- Ghidra source located at '/Users/me/sleigh/src/cmake_fc_ghidra_stable_Ninja/ghidrasource-src'
-- The C compiler identification is AppleClang 13.0.0.13000029
-- The CXX compiler identification is AppleClang 13.0.0.13000029
...

$ cmake -B build-debug -S . -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DFETCHCONTENT_BASE_DIR=./src/cmake_fc_ghidra_stable_Ninja
-- Using Ghidra version 10.0.4 at commit 5b07797
-- Populating ghidrasource
-- Configuring done
-- Generating done
-- Build files have been written to: /Users/me/sleigh/src/cmake_fc_ghidra_stable_Ninja/ghidrasource-subbuild
[0/7] Performing update step for 'ghidrasource-populate'
[2/7] No patch step for 'ghidrasource-populate'
[3/7] No configure step for 'ghidrasource-populate'
[4/7] No build step for 'ghidrasource-populate'
[5/7] No install step for 'ghidrasource-populate'
[6/7] No test step for 'ghidrasource-populate'
[7/7] Completed 'ghidrasource-populate'
-- Ghidra source located at '/Users/me/sleigh/src/cmake_fc_ghidra_stable_Ninja/ghidrasource-src'
-- The C compiler identification is AppleClang 13.0.0.13000029
-- The CXX compiler identification is AppleClang 13.0.0.13000029
...
```

The above also works when using `HEAD` commit of Ghidra.

```bash
$ cmake -B build-head-release -S . -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -Dsleigh_RELEASE_TYPE=HEAD \
    -DFETCHCONTENT_BASE_DIR=./src/cmake_fc_ghidra_HEAD_Ninja
...

$ cmake -B build-head-debug -S . -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -Dsleigh_RELEASE_TYPE=HEAD \
    -DFETCHCONTENT_BASE_DIR=./src/cmake_fc_ghidra_HEAD_Ninja
...
```

This setup is nice if you want to clear the project build directories but don't want to re-download Ghidra source code every time. However, to be safe, you should remove these directories if you change the Ghidra git commit SHA of stable or HEAD.
