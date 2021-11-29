/*
  Copyright (c) 2021-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated"
#pragma GCC diagnostic ignored "-Wsign-compare"
#pragma GCC diagnostic ignored "-Wunused-parameter"
#include "address.hh"
#include "context.hh"
#include "emulate.hh"
#include "error.hh"
#include "float.hh"
#include "globalcontext.hh"
#include "loadimage.hh"
#include "memstate.hh"
#include "opbehavior.hh"
#include "opcodes.hh"
#include "partmap.hh"
#include "pcoderaw.hh"
#include "semantics.hh"
#include "sleigh.hh"
#include "sleighbase.hh"
#include "slghpatexpress.hh"
#include "slghpattern.hh"
#include "slghsymbol.hh"
#include "space.hh"
#include "translate.hh"
#include "types.h"
#include "xml.hh"
#pragma GCC diagnostic pop

namespace sleigh {

static const char *gSearchPaths[] = {
    // Derived from the installation
    SLEIGH_SPEC_INSTALL_DIR "\0",
    // Derived from the build
    SLEIGH_SPEC_BUILD_DIR "\0",
    // Common install locations
    "/usr/local/share/sleigh", "/usr/share/sleigh", "/share/sleigh"};

std::string FindSpecFileInSearchPath(std::string_view file_name,
                                     std::string_view search_path) {
  std::filesystem::path install_path(search_path);
  install_path.append("Processors");
  // Check whether a SLEIGH installation exists at this path
  if (!std::filesystem::is_directory(install_path)) {
    return "";
  }
  // Each directory under Processors/ represents a family of architectures
  //
  // Spec files should reside under:
  // <install_prefix>/Processors/<arch>/data/languages
  std::filesystem::directory_iterator install_iter(install_path);
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
    return dir_path.string();
  }
  return "";
}

std::string FindSpecFile(std::string_view file_name,
                         const std::vector<std::string> &search_paths = {}) {
  // Try paths supplied by the caller first
  for (const auto &path : search_paths) {
    auto file_path = FindSpecFileInSearchPath(file_name, path);
    if (!file_path.empty()) {
      return file_path;
    }
  }
  // Now try the default paths
  for (const auto *path : gSearchPaths) {
    auto file_path = FindSpecFileInSearchPath(file_name, path);
    if (!file_path.empty()) {
      return file_path;
    }
  }
  // Cannot find the spec file
  return "";
}

} // namespace sleigh
