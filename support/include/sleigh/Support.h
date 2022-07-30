/*
  Copyright (c) 2021-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace sleigh {

extern const std::vector<std::filesystem::path> gDefaultSearchPaths;

std::optional<std::filesystem::path>
FindSpecFile(std::string_view file_name,
             const std::vector<std::filesystem::path> &search_paths =
                 gDefaultSearchPaths);

} // namespace sleigh
