#include "SpecFilePaths.h"

#include "Support.h"

namespace sleigh {

namespace {

std::optional<std::filesystem::path>
FindSpecFileInSearchPath(std::string_view file_name,
                         std::filesystem::path search_path) {
  search_path.append("Processors");
  // Check whether a SLEIGH installation exists at this path
  if (!std::filesystem::is_directory(search_path)) {
    return {};
  }
  // Each directory under Processors/ represents a family of architectures
  //
  // Spec files should reside under:
  // <install_prefix>/Processors/<arch>/data/languages
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
    kSleighSpecInstallDir,
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