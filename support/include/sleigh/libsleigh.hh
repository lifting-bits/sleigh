/*
  Copyright (c) 2021-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#include <sleigh/libconfig.h>

#pragma once
#ifndef _MSC_VER
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated"
#pragma GCC diagnostic ignored "-Wsign-compare"
#pragma GCC diagnostic ignored "-Wunused-parameter"
#endif
#include <ghidra/action.hh>
#include <ghidra/address.hh>
#include <ghidra/architecture.hh>
#include <ghidra/block.hh>
#include <ghidra/blockaction.hh>
#include <ghidra/callgraph.hh>
#include <ghidra/capability.hh>
#include <ghidra/cast.hh>
#include <ghidra/codedata.hh>
#include <ghidra/comment.hh>
#include <ghidra/comment_ghidra.hh>
#include <ghidra/condexe.hh>
#include <ghidra/context.hh>
#include <ghidra/coreaction.hh>
#include <ghidra/cover.hh>
#include <ghidra/cpool.hh>
#include <ghidra/cpool_ghidra.hh>
#include <ghidra/crc32.hh>
#include <ghidra/database.hh>
#include <ghidra/database_ghidra.hh>
#include <ghidra/doccore.hh>
#include <ghidra/docmain.hh>
#include <ghidra/double.hh>
#include <ghidra/dynamic.hh>
#include <ghidra/emulate.hh>
#include <ghidra/emulateutil.hh>
#include <ghidra/error.hh>
#include <ghidra/filemanage.hh>
#include <ghidra/float.hh>
#include <ghidra/flow.hh>
#include <ghidra/fspec.hh>
#include <ghidra/funcdata.hh>
#include <ghidra/ghidra_arch.hh>
#include <ghidra/ghidra_context.hh>
#include <ghidra/ghidra_process.hh>
#include <ghidra/ghidra_translate.hh>
#include <ghidra/globalcontext.hh>
#include <ghidra/grammar.hh>
#include <ghidra/graph.hh>
#include <ghidra/heritage.hh>
#include <ghidra/ifacedecomp.hh>
#include <ghidra/ifaceterm.hh>
#include <ghidra/inject_ghidra.hh>
#include <ghidra/inject_sleigh.hh>
#include <ghidra/interface.hh>
#include <ghidra/jumptable.hh>
#include <ghidra/libdecomp.hh>
#include <ghidra/loadimage.hh>
#include <ghidra/loadimage_ghidra.hh>
#include <ghidra/loadimage_xml.hh>
#include <ghidra/memstate.hh>
#include <ghidra/merge.hh>
#include <ghidra/op.hh>
#include <ghidra/opbehavior.hh>
#include <ghidra/opcodes.hh>
#include <ghidra/options.hh>
#include <ghidra/override.hh>
#include <ghidra/paramid.hh>
#include <ghidra/partmap.hh>
#include <ghidra/pcodecompile.hh>
#include <ghidra/pcodeinject.hh>
#include <ghidra/pcodeparse.hh>
#include <ghidra/pcoderaw.hh>
#include <ghidra/prefersplit.hh>
#include <ghidra/prettyprint.hh>
#include <ghidra/printc.hh>
#include <ghidra/printjava.hh>
#include <ghidra/printlanguage.hh>
#include <ghidra/rangemap.hh>
#include <ghidra/rangeutil.hh>
#include <ghidra/raw_arch.hh>
#include <ghidra/ruleaction.hh>
#include <ghidra/rulecompile.hh>
#include <ghidra/semantics.hh>
#include <ghidra/sleigh.hh>
#include <ghidra/sleigh_arch.hh>
#include <ghidra/sleighbase.hh>
#include <ghidra/slgh_compile.hh>
// This is required because slghparse.hh does not have a namespace block
namespace ghidra {
#include <ghidra/slghparse.hh>
} // End namespace ghidra
#include <ghidra/slghpatexpress.hh>
#include <ghidra/slghpattern.hh>
#include <ghidra/slghsymbol.hh>
#include <ghidra/space.hh>
#include <ghidra/string_ghidra.hh>
#include <ghidra/stringmanage.hh>
#include <ghidra/subflow.hh>
#include <ghidra/testfunction.hh>
#include <ghidra/transform.hh>
#include <ghidra/translate.hh>
#include <ghidra/type.hh>
#include <ghidra/typegrp_ghidra.hh>
#include <ghidra/typeop.hh>
#include <ghidra/types.h>
#include <ghidra/unify.hh>
#include <ghidra/userop.hh>
#include <ghidra/variable.hh>
#include <ghidra/varmap.hh>
#include <ghidra/varnode.hh>
#include <ghidra/xml.hh>
#include <ghidra/xml_arch.hh>
#include <ghidra/unionresolve.hh>
#include <ghidra/marshal.hh>
#include <ghidra/analyzesigs.hh>
#include <ghidra/modelrules.hh>
#include <ghidra/signature.hh>
#include <ghidra/signature_ghidra.hh>
#include <ghidra/compression.hh>
#include <ghidra/multiprecision.hh>
#include <ghidra/slaformat.hh>

// #ifdef sleigh_RELEASE_IS_HEAD
// #endif

#ifndef _MSC_VER
#pragma GCC diagnostic pop
#endif

#include <sleigh/Support.h>
#include <sleigh/Version.h>
