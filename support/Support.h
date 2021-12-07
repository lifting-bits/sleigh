/*
  Copyright (c) 2021-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace sleigh {

std::string FindSpecFile(std::string_view file_name,
                         const std::vector<std::string> &search_paths = {});

} // namespace sleigh
