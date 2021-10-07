# Copyright (c) 2021-present Trail of Bits, Inc.

set(SLEIGH_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ghidra/Ghidra/Features/Decompiler/src/decompile/cpp")
set(SLEIGH_SOURCE_DIR ${SLEIGH_SOURCE_DIR} PARENT_SCOPE)

set(SLEIGH_CORE
  ${SLEIGH_SOURCE_DIR}/address.cc
  ${SLEIGH_SOURCE_DIR}/context.cc
  ${SLEIGH_SOURCE_DIR}/float.cc
  ${SLEIGH_SOURCE_DIR}/globalcontext.cc
  ${SLEIGH_SOURCE_DIR}/opcodes.cc
  ${SLEIGH_SOURCE_DIR}/pcodecompile.cc
  ${SLEIGH_SOURCE_DIR}/pcodeparse.cc
  ${SLEIGH_SOURCE_DIR}/pcoderaw.cc
  ${SLEIGH_SOURCE_DIR}/semantics.cc
  ${SLEIGH_SOURCE_DIR}/sleigh.cc
  ${SLEIGH_SOURCE_DIR}/sleighbase.cc
  ${SLEIGH_SOURCE_DIR}/slghpatexpress.cc
  ${SLEIGH_SOURCE_DIR}/slghpattern.cc
  ${SLEIGH_SOURCE_DIR}/slghsymbol.cc
  ${SLEIGH_SOURCE_DIR}/space.cc
  ${SLEIGH_SOURCE_DIR}/translate.cc
  ${SLEIGH_SOURCE_DIR}/xml.cc
  )

add_library(libsleigh
  ${SLEIGH_CORE}
  )
set_target_properties(libsleigh PROPERTIES PREFIX "")

add_executable(sleigh
  ${SLEIGH_SOURCE_DIR}/filemanage.cc
  ${SLEIGH_SOURCE_DIR}/slgh_compile.cc
  ${SLEIGH_SOURCE_DIR}/slghparse.cc
  ${SLEIGH_SOURCE_DIR}/slghscan.cc
  )
target_link_libraries(sleigh libsleigh)
