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
#include <sleigh/action.hh>
#include <sleigh/address.hh>
#include <sleigh/architecture.hh>
#include <sleigh/block.hh>
#include <sleigh/blockaction.hh>
#include <sleigh/callgraph.hh>
#include <sleigh/capability.hh>
#include <sleigh/cast.hh>
#include <sleigh/codedata.hh>
#include <sleigh/comment.hh>
#include <sleigh/comment_ghidra.hh>
#include <sleigh/condexe.hh>
#include <sleigh/context.hh>
#include <sleigh/coreaction.hh>
#include <sleigh/cover.hh>
#include <sleigh/cpool.hh>
#include <sleigh/cpool_ghidra.hh>
#include <sleigh/crc32.hh>
#include <sleigh/database.hh>
#include <sleigh/database_ghidra.hh>
#include <sleigh/doccore.hh>
#include <sleigh/docmain.hh>
#include <sleigh/double.hh>
#include <sleigh/dynamic.hh>
#include <sleigh/emulate.hh>
#include <sleigh/emulateutil.hh>
#include <sleigh/error.hh>
#include <sleigh/filemanage.hh>
#include <sleigh/float.hh>
#include <sleigh/flow.hh>
#include <sleigh/fspec.hh>
#include <sleigh/funcdata.hh>
#include <sleigh/ghidra_arch.hh>
#include <sleigh/ghidra_context.hh>
#include <sleigh/ghidra_process.hh>
#include <sleigh/ghidra_translate.hh>
#include <sleigh/globalcontext.hh>
#include <sleigh/grammar.hh>
#include <sleigh/graph.hh>
#include <sleigh/heritage.hh>
#include <sleigh/ifacedecomp.hh>
#include <sleigh/ifaceterm.hh>
#include <sleigh/inject_ghidra.hh>
#include <sleigh/inject_sleigh.hh>
#include <sleigh/interface.hh>
#include <sleigh/jumptable.hh>
#include <sleigh/libdecomp.hh>
#include <sleigh/loadimage.hh>
#include <sleigh/loadimage_ghidra.hh>
#include <sleigh/loadimage_xml.hh>
#include <sleigh/memstate.hh>
#include <sleigh/merge.hh>
#include <sleigh/op.hh>
#include <sleigh/opbehavior.hh>
#include <sleigh/opcodes.hh>
#include <sleigh/options.hh>
#include <sleigh/override.hh>
#include <sleigh/paramid.hh>
#include <sleigh/partmap.hh>
#include <sleigh/pcodecompile.hh>
#include <sleigh/pcodeinject.hh>
#include <sleigh/pcodeparse.hh>
#include <sleigh/pcoderaw.hh>
#include <sleigh/prefersplit.hh>
#include <sleigh/prettyprint.hh>
#include <sleigh/printc.hh>
#include <sleigh/printjava.hh>
#include <sleigh/printlanguage.hh>
#include <sleigh/rangemap.hh>
#include <sleigh/rangeutil.hh>
#include <sleigh/raw_arch.hh>
#include <sleigh/ruleaction.hh>
#include <sleigh/rulecompile.hh>
#include <sleigh/semantics.hh>
#include <sleigh/sleigh.hh>
#include <sleigh/sleigh_arch.hh>
#include <sleigh/sleighbase.hh>
#include <sleigh/slgh_compile.hh>
#include <sleigh/slghparse.hh>
#include <sleigh/slghpatexpress.hh>
#include <sleigh/slghpattern.hh>
#include <sleigh/slghsymbol.hh>
#include <sleigh/space.hh>
#include <sleigh/string_ghidra.hh>
#include <sleigh/stringmanage.hh>
#include <sleigh/subflow.hh>
#include <sleigh/testfunction.hh>
#include <sleigh/transform.hh>
#include <sleigh/translate.hh>
#include <sleigh/type.hh>
#include <sleigh/typegrp_ghidra.hh>
#include <sleigh/typeop.hh>
#include <sleigh/types.h>
#include <sleigh/unify.hh>
#include <sleigh/userop.hh>
#include <sleigh/variable.hh>
#include <sleigh/varmap.hh>
#include <sleigh/varnode.hh>
#include <sleigh/xml.hh>
#include <sleigh/xml_arch.hh>

#ifdef sleigh_RELEASE_IS_HEAD
#include <sleigh/unionresolve.hh>
#include <sleigh/marshal.hh>
#endif

#ifndef _MSC_VER
#pragma GCC diagnostic pop
#endif

#include <sleigh/Support.h>
#include <sleigh/Version.h>
