/*
  Copyright (c) 2021-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#include "sleigh/Support.h"

#include "sleigh/SpecFilePaths.h"

namespace sleigh {

namespace {

std::optional<std::filesystem::path>
FindSpecFileInSearchPath(std::string_view file_name,
                         std::filesystem::path search_path) {
  search_path.append("Ghidra").append("Processors");
  // Check whether a Sleigh installation exists at this path
  if (!std::filesystem::is_directory(search_path)) {
    return {};
  }
  // Each directory under Processors/ represents a family of architectures
  //
  // Spec files should reside under:
  // <root_sla_dir>/Ghidra/Processors/<arch>/data/languages
  std::filesystem::directory_iterator install_iter(search_path);
  for (auto &dir_entry : install_iter) {
    if (!dir_entry.is_directory()) {
      continue;
    }
    // Check whether the spec file exists under data/languages/
    auto dir_path = dir_entry.path();
    dir_path.append("data").append("languages").append(file_name);
    if (!std::filesystem::exists(dir_path)) {
      continue;
    }
    return dir_path;
  }
  return {};
}

} // namespace

const std::vector<std::filesystem::path> gDefaultSearchPaths = {
    // Derived from the installation
    kSleighFullSpecInstallDir,
    // Derived from the build
    kSleighSpecBuildDir,
    // Common install locations
    "/usr/local/share/sleigh/specfiles", "/usr/share/sleigh/specfiles",
    "/share/sleigh/specfiles"};

std::optional<std::filesystem::path>
FindSpecFile(std::string_view file_name,
             const std::vector<std::filesystem::path> &search_paths) {
  // Search each path for spec files
  for (const auto &path : search_paths) {
    auto file_path = FindSpecFileInSearchPath(file_name, path);
    if (file_path) {
      return file_path;
    }
  }
  // Cannot find the spec file
  return {};
}

} // namespace sleigh
