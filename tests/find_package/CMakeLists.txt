#
# Copyright (c) 2021-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

cmake_minimum_required(VERSION 3.21.0)
project("sleigh_find_package_test")

find_package(sleigh REQUIRED)

add_executable(sleigh_test
  src/main.cpp
)

target_link_libraries(sleigh_test PRIVATE
  sleigh::sla
  sleigh::decomp
)
