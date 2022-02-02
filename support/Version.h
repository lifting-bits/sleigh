/*
  Copyright (c) 2022-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#pragma once

#include <string_view>

namespace sleigh {

bool HasVersionData(void);

bool HasUncommittedChanges(void);

std::string_view GetAuthorName(void);

std::string_view GetAuthorEmail(void);

std::string_view GetCommitHash(void);

std::string_view GetCommitDate(void);

std::string_view GetCommitSubject(void);

std::string_view GetCommitBody(void);

std::string_view GetGhidraVersion(void);

std::string_view GetGhidraCommitHash(void);

std::string_view GetGhidraReleaseType(void);

} // namespace sleigh
