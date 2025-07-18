#
# Copyright (c) 2022-present, Trail of Bits, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.
#

# ---- Setup Ghidra Source code ----
include_guard(GLOBAL)

# Set up Ghidra repo human-readable version settings
set(sleigh_RELEASE_TYPE "stable" CACHE
  STRING "Release type to use. 'HEAD' is used for active development purposes."
)

# This is just helper for CMake UIs. CMake does not enforce that the value matches one of those listed.
set_property(CACHE sleigh_RELEASE_TYPE PROPERTY STRINGS "stable" "HEAD")

# **** Setup pinned git info ****

find_package(Git REQUIRED)

# Ghidra pinned stable version commit
set(ghidra_version "11.4")
set(ghidra_git_tag "Ghidra_${ghidra_version}_build")
set(ghidra_shallow TRUE)

set(sleigh_ADDITIONAL_PATCHES "" CACHE STRING
  "The accepted patch format is git patch files, to be applied via git am. The format of the list is a CMake semicolon separated list.")

# See this thread for more details https://github.community/t/github-actions-bot-email-address/17204/5
set(ghidra_patch_user "github-actions[bot]")
set(ghidra_patch_email "41898282+github-actions[bot]@users.noreply.github.com")

# pinned stable patches list
set(ghidra_patches
  PATCH_COMMAND "${GIT_EXECUTABLE}" config user.name "${ghidra_patch_user}" &&
  "${GIT_EXECUTABLE}" config user.email "${ghidra_patch_email}" &&
  "${GIT_EXECUTABLE}" am --ignore-space-change --ignore-whitespace --no-gpg-sign
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0001-Fix-UBSAN-errors-in-decompiler.patch"
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0002-Use-stroull-instead-of-stroul-to-parse-address-offse.patch"
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0003-Use-string-resize-instead-of-reserve.patch"
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0004-Ignore-floating-point-test-due-to-compilation-differ.patch"
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0005-Allow-positive-or-negative-NAN-in-decompiler-floatin.patch"
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0006-decompiler-Fix-strict-weak-ordering-TypePartialEnum.patch"
  "${CMAKE_CURRENT_LIST_DIR}/patches/stable/0007-Backport-fix-for-datatests-retstruct.xml-tests.patch"
)

# Ghidra pinned commits used for pinning last known working HEAD commit
if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
  # TODO: Try to remember to look at Ghidra/application.properties
  # TODO: CMake only likes numeric characters in the version string....
  set(ghidra_head_version "11.5")
  set(ghidra_version "${ghidra_head_version}")
  set(ghidra_head_git_tag "8c48d9f1168275a039d7803267399bf418d827dd")
  set(ghidra_git_tag "${ghidra_head_git_tag}")
  set(ghidra_shallow FALSE)
  set(ghidra_patches
    PATCH_COMMAND "${GIT_EXECUTABLE}" config user.name "${ghidra_patch_user}" &&
    "${GIT_EXECUTABLE}" config user.email "${ghidra_patch_email}" &&
    "${GIT_EXECUTABLE}" am --ignore-space-change --ignore-whitespace --no-gpg-sign
    "${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0001-Fix-UBSAN-errors-in-decompiler.patch"
    "${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0002-Use-stroull-instead-of-stroul-to-parse-address-offse.patch"
    "${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0003-Use-string-resize-instead-of-reserve.patch"
    "${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0004-Ignore-floating-point-test-due-to-compilation-differ.patch"
    "${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0005-Allow-positive-or-negative-NAN-in-decompiler-floatin.patch"
    "${CMAKE_CURRENT_LIST_DIR}/patches/HEAD/0006-decompiler-Fix-strict-weak-ordering-TypePartialEnum.patch"
  )
  string(SUBSTRING "${ghidra_git_tag}" 0 7 ghidra_short_commit)
else()
  set(ghidra_short_commit "${ghidra_git_tag}")
endif()

list(APPEND ghidra_patches ${sleigh_ADDITIONAL_PATCHES})

message(STATUS "Using Ghidra version ${ghidra_version} at git ref ${ghidra_short_commit}")

include(FetchContent)

# Verbose fetch content updates
set(FETCHCONTENT_QUIET OFF)

# Write out source directory with identifiable version info
FetchContent_Declare(GhidraSource
  GIT_REPOSITORY https://github.com/NationalSecurityAgency/ghidra
  GIT_TAG ${ghidra_git_tag}
  GIT_PROGRESS TRUE
  GIT_SHALLOW ${ghidra_shallow}
  ${ghidra_patches}
)
FetchContent_MakeAvailable(GhidraSource)

message(STATUS "Ghidra source located at '${ghidrasource_SOURCE_DIR}'")

# Sanity check on Ghidra source code checkout
set(library_root "${ghidrasource_SOURCE_DIR}/Ghidra/Features/Decompiler/src/decompile/cpp")

if(NOT EXISTS "${library_root}/sleigh.hh")
  message(FATAL_ERROR "The Ghidra source directory has not been initialized correctly. Could not find '${library_root}'")
endif()

# Source collection variables
set(sleigh_core_source_list
  "${library_root}/xml.cc"
  "${library_root}/space.cc"
  "${library_root}/float.cc"
  "${library_root}/address.cc"
  "${library_root}/pcoderaw.cc"
  "${library_root}/translate.cc"
  "${library_root}/opcodes.cc"
  "${library_root}/globalcontext.cc"
  "${library_root}/marshal.cc"
)
#if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
#  list(APPEND sleigh_core_source_list
#  )
#endif()

set(sleigh_deccore_source_list
  "${library_root}/capability.cc"
  "${library_root}/architecture.cc"
  "${library_root}/options.cc"
  "${library_root}/graph.cc"
  "${library_root}/cover.cc"
  "${library_root}/block.cc"
  "${library_root}/cast.cc"
  "${library_root}/typeop.cc"
  "${library_root}/database.cc"
  "${library_root}/cpool.cc"
  "${library_root}/comment.cc"
  "${library_root}/stringmanage.cc"
  "${library_root}/fspec.cc"
  "${library_root}/action.cc"
  "${library_root}/loadimage.cc"
  "${library_root}/grammar.cc"
  "${library_root}/varnode.cc"
  "${library_root}/op.cc"
  "${library_root}/type.cc"
  "${library_root}/variable.cc"
  "${library_root}/varmap.cc"
  "${library_root}/jumptable.cc"
  "${library_root}/emulate.cc"
  "${library_root}/emulateutil.cc"
  "${library_root}/flow.cc"
  "${library_root}/userop.cc"
  "${library_root}/funcdata.cc"
  "${library_root}/funcdata_block.cc"
  "${library_root}/funcdata_op.cc"
  "${library_root}/funcdata_varnode.cc"
  "${library_root}/pcodeinject.cc"
  "${library_root}/heritage.cc"
  "${library_root}/prefersplit.cc"
  "${library_root}/rangeutil.cc"
  "${library_root}/ruleaction.cc"
  "${library_root}/subflow.cc"
  "${library_root}/blockaction.cc"
  "${library_root}/merge.cc"
  "${library_root}/double.cc"
  "${library_root}/transform.cc"
  "${library_root}/coreaction.cc"
  "${library_root}/condexe.cc"
  "${library_root}/override.cc"
  "${library_root}/dynamic.cc"
  "${library_root}/crc32.cc"
  "${library_root}/prettyprint.cc"
  "${library_root}/printlanguage.cc"
  "${library_root}/printc.cc"
  "${library_root}/printjava.cc"
  "${library_root}/memstate.cc"
  "${library_root}/opbehavior.cc"
  "${library_root}/paramid.cc"
  "${library_root}/unionresolve.cc"
  "${library_root}/modelrules.cc"
  "${library_root}/signature.cc"
  "${library_root}/multiprecision.cc"
  "${library_root}/constseq.cc"
)
#if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
#  list(APPEND sleigh_deccore_source_list
#  )
#endif()

set(sleigh_extra_source_list
  "${library_root}/callgraph.cc"
  "${library_root}/ifacedecomp.cc"
  "${library_root}/ifaceterm.cc"
  "${library_root}/inject_sleigh.cc"
  "${library_root}/interface.cc"
  "${library_root}/libdecomp.cc"
  "${library_root}/loadimage_xml.cc"
  "${library_root}/raw_arch.cc"
  "${library_root}/rulecompile.cc"
  "${library_root}/sleigh_arch.cc"
  "${library_root}/testfunction.cc"
  "${library_root}/unify.cc"
  "${library_root}/xml_arch.cc"
)

set(sleigh_source_list
  "${library_root}/sleigh.cc"
  "${library_root}/pcodeparse.cc"
  "${library_root}/pcodecompile.cc"
  "${library_root}/sleighbase.cc"
  "${library_root}/slghsymbol.cc"
  "${library_root}/slghpatexpress.cc"
  "${library_root}/slghpattern.cc"
  "${library_root}/semantics.cc"
  "${library_root}/context.cc"
  "${library_root}/filemanage.cc"
  "${library_root}/slaformat.cc"
  "${library_root}/compression.cc"
)
# if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
#   list(APPEND sleigh_source_list
#   )
# endif()

set(sleigh_ghidra_source_list
  "${library_root}/ghidra_arch.cc"
  "${library_root}/inject_ghidra.cc"
  "${library_root}/ghidra_translate.cc"
  "${library_root}/loadimage_ghidra.cc"
  "${library_root}/typegrp_ghidra.cc"
  "${library_root}/database_ghidra.cc"
  "${library_root}/ghidra_context.cc"
  "${library_root}/cpool_ghidra.cc"
  "${library_root}/ghidra_process.cc"
  "${library_root}/comment_ghidra.cc"
  "${library_root}/string_ghidra.cc"
  "${library_root}/signature_ghidra.cc"
)
# if("${sleigh_RELEASE_TYPE}" STREQUAL "HEAD")
#   list(APPEND sleigh_ghidra_source_list
#   )
# endif()

set(sleigh_slacomp_source_list
  "${library_root}/slgh_compile.cc"
  "${library_root}/slghparse.cc"
  "${library_root}/slghscan.cc"
)

# Include separate file to make it easier to find user-specified compile
# options
include("${CMAKE_CURRENT_LIST_DIR}/compile_options.cmake")

# Sets 'spec_file_list' variable
if(sleigh_RELEASE_IS_HEAD)
  include("${CMAKE_CURRENT_LIST_DIR}/spec_files_HEAD.cmake")
else()
  include("${CMAKE_CURRENT_LIST_DIR}/spec_files_stable.cmake")
endif()
