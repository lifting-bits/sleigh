#include "Support.h"

namespace sleigh {

namespace {

static const char *gSearchPaths[] = {
    // Derived from the installation
    SLEIGH_SPEC_INSTALL_DIR "\0",
    // Derived from the build
    SLEIGH_SPEC_BUILD_DIR "\0",
    // Common install locations
    "/usr/local/share/sleigh", "/usr/share/sleigh", "/share/sleigh"};

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

std::optional<std::filesystem::path>
FindSpecFile(std::string_view file_name,
             const std::vector<std::filesystem::path> &search_paths) {
  // Try paths supplied by the caller first
  for (const auto &path : search_paths) {
    auto file_path = FindSpecFileInSearchPath(file_name, path);
    if (file_path) {
      return file_path;
    }
  }
  // Now try the default paths
  for (const auto *path : gSearchPaths) {
    auto file_path = FindSpecFileInSearchPath(file_name, path);
    if (file_path) {
      return file_path;
    }
  }
  // Cannot find the spec file
  return {};
}

} // namespace sleigh
