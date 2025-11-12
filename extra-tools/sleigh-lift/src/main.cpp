/*
  Copyright (c) 2021-present, Trail of Bits, Inc.
  All rights reserved.

  This source code is licensed in accordance with the terms specified in
  the LICENSE file found in the root directory of this source tree.
*/

#include <sleigh/libsleigh.hh>

#include <cassert>
#include <iostream>
#include <string>

static void PrintUsage(std::ostream &os) {
  os << "Usage: sleigh-lift [action] [sla_file] [bytes] [-a address] "
        "[-p root_sla_dir] [-s pspec_file]"
     << std::endl;
}

static void PrintVersion(void) {
  std::cout << "sleigh-lift " << sleigh::GetGhidraVersion() << '\n';

  // Print out the commit info for the underlying GHIDRA checkout
  std::cout << "GHIDRA Version: " << sleigh::GetGhidraVersion() << '\n'
            << "GHIDRA Commit Hash: " << sleigh::GetGhidraCommitHash() << '\n'
            << "GHIDRA Release Type: " << sleigh::GetGhidraReleaseType()
            << '\n';

  // Now print out the Git commit information
  if (sleigh::HasVersionData()) {
    std::cout << "Commit Hash: " << sleigh::GetCommitHash() << '\n'
              << "Commit Date: " << sleigh::GetCommitDate() << '\n'
              << "Last commit by: " << sleigh::GetAuthorName() << " ["
              << sleigh::GetAuthorEmail() << "]\n"
              << "Commit Subject: [" << sleigh::GetCommitSubject() << "]\n"
              << '\n';
    if (sleigh::HasUncommittedChanges()) {
      std::cout << "Uncommitted changes were present during build.\n";
    } else {
      std::cout << "All changes were committed prior to building.\n";
    }
  } else {
    std::cout << "No extended version information found!\n";
  }
}

class InMemoryLoadImage : public ghidra::LoadImage {
public:
  explicit InMemoryLoadImage(uint64_t base_addr)
      : LoadImage("nofile"), base_addr(base_addr) {}

  void SetImageBuffer(std::string &&buf) {
    assert(image_buffer.empty());
    image_buffer = std::move(buf);
  }

  void loadFill(unsigned char *ptr, int size,
                const ghidra::Address &addr) override {
    uint64_t start = addr.getOffset();
    for (int i = 0; i < size; ++i) {
      uint64_t offset = start + i;
      if (offset >= base_addr) {
        offset -= base_addr;
        ptr[i] = offset < image_buffer.size() ? image_buffer[offset] : 0;
      } else {
        ptr[i] = 0;
      }
    }
  }

  std::string getArchType(void) const override { return "memory"; }
  void adjustVma(long) override {}

private:
  const uint64_t base_addr;
  std::string image_buffer;
};

static std::string ParseHexBytes(std::string_view bytes, uint64_t addr,
                                 uint64_t addr_size) {
  std::string buffer;
  for (size_t i = 0; i < bytes.size(); i += 2) {
    const char nibbles[] = {bytes[i], bytes[i + 1], '\0'};
    char *parsed_to = nullptr;
    auto byte_val = strtol(nibbles, &parsed_to, 16);
    if (parsed_to != &(nibbles[2])) {
      std::cerr << "Invalid hex byte value '" << nibbles
                << "' specified in bytes arg." << std::endl;
      exit(EXIT_FAILURE);
    }
    const uint64_t addr_mask = ~0ULL >> (64UL - addr_size * 8);
    auto byte_addr = addr + (i / 2);
    auto masked_addr = byte_addr & addr_mask;
    // Make sure that if a really big number is specified for `address`,
    // that we don't accidentally wrap around and start filling out low
    // byte addresses.
    if (masked_addr < byte_addr) {
      std::cerr << "Too many bytes specified to bytes arg, would result "
                << "in a 32-bit overflow.";
      exit(EXIT_FAILURE);
    } else if (masked_addr < addr) {
      std::cerr << "Too many bytes specified to bytes arg, would result "
                << "in a 64-bit overflow.";
      exit(EXIT_FAILURE);
    }
    buffer.push_back(static_cast<char>(byte_val));
  }
  return buffer;
}

class AssemblyPrinter : public ghidra::AssemblyEmit {
public:
  void dump(const ghidra::Address &addr, const std::string &mnemonic,
            const std::string &body) override {
    addr.printRaw(std::cout);
    std::cout << ": " << mnemonic << ' ' << body << std::endl;
  }
};

static void PrintAssembly(ghidra::Sleigh &engine, uint64_t addr, size_t len) {
  AssemblyPrinter asm_emit;
  ghidra::Address cur_addr(engine.getDefaultCodeSpace(), addr),
      last_addr(engine.getDefaultCodeSpace(), addr + len);
  while (cur_addr < last_addr) {
    try {
      int32_t instr_len = engine.printAssembly(asm_emit, cur_addr);
      cur_addr = cur_addr + instr_len;
    }
    catch(ghidra::UnimplError &err) {
      std::cerr << "UnimplError @ " << cur_addr << " (addr 0x" << addr << ", len 0x" << len << "): " << err.explain << "\n";
      break;
    }
    catch (ghidra::BadDataError &err) {
      std::cerr << "BadDataError @ " << cur_addr << " (addr 0x" << addr << ", len 0x" << len << "): " << err.explain << "\n";
      break;
    }
  }
}

static void PrintVarData(std::ostream &s, ghidra::VarnodeData &data) {
  s << '(' << data.space->getName() << ',';
  data.space->printOffset(s, data.offset);
  s << ',' << std::dec << data.size << ')';
}

class PcodePrinter : public ghidra::PcodeEmit {
public:
  void dump(const ghidra::Address &, ghidra::OpCode op,
            ghidra::VarnodeData *outvar, ghidra::VarnodeData *vars,
            int32_t isize) override {
    if (outvar) {
      PrintVarData(std::cout, *outvar);
      std::cout << " = ";
    }
    std::cout << get_opname(op);
    for (int32_t i = 0; i < isize; ++i) {
      std::cout << ' ';
      PrintVarData(std::cout, vars[i]);
    }
    std::cout << std::endl;
  }
};

static void PrintPcode(ghidra::Sleigh &engine, uint64_t addr, size_t len) {
  PcodePrinter pcode_emit;
  ghidra::Address cur_addr(engine.getDefaultCodeSpace(), addr),
      last_addr(engine.getDefaultCodeSpace(), addr + len);
  while (cur_addr < last_addr) {
    try {
      int32_t instr_len = engine.oneInstruction(pcode_emit, cur_addr);
      cur_addr = cur_addr + instr_len;
    }
    catch(ghidra::UnimplError &err) {
      std::cerr << "UnimplError @ " << cur_addr << " (addr 0x" << addr << ", len 0x" << len << "): " << err.explain << "\n";
      break;
    }
    catch(ghidra::BadDataError &err) {
      std::cerr << "BadDataError @ " << cur_addr << " (addr 0x" << addr << ", len 0x" << len << "): " << err.explain << "\n";
      break;
    }
  }
}

struct LiftArgs {
  const std::string action, sla_file_name, bytes;
  const std::optional<uint64_t> addr;
  const std::optional<std::string> root_sla_dir, pspec_file_name;
};

std::optional<LiftArgs> ParseArgs(int argc, char *argv[]) {
  // Too few args
  if (argc < 4) {
    return {};
  }

  // Get positional args
  int arg_index = 1;
  std::string action = argv[arg_index++];
  std::string sla_file_name = argv[arg_index++];
  std::string bytes = argv[arg_index++];
  if (bytes.size() % 2 != 0) {
    std::cerr << "Must provide an even number of bytes: " << bytes << std::endl;
    return {};
  }

  // Get optional args
  std::optional<uint64_t> addr;
  std::optional<std::string> root_sla_dir, pspec_file_name;
  while (arg_index < argc) {
    const std::string flag = argv[arg_index++];
    if (arg_index == argc) {
      std::cerr << "Flag " << flag << " has no value" << std::endl;
      return {};
    }
    if (flag == "-a") {
      if (addr) {
        std::cerr << "-a flag provided multiple times" << std::endl;
        return {};
      }
      const char *addr_str = argv[arg_index++];
      try {
        addr = std::stoul(addr_str);
      } catch (const std::invalid_argument &) {
        std::cerr << "Invalid address argument: " << addr_str << std::endl;
        return {};
      } catch (const std::out_of_range &) {
        std::cerr << "Address argument out of range: " << addr_str << std::endl;
        return {};
      }
    } else if (flag == "-p") {
      if (root_sla_dir) {
        std::cerr << "-p flag provided multiple times" << std::endl;
        return {};
      }
      root_sla_dir = argv[arg_index++];
    } else if (flag == "-s") {
      if (pspec_file_name) {
        std::cerr << "-s flag provided multiple times" << std::endl;
        return {};
      }
      pspec_file_name = argv[arg_index++];
    } else {
      std::cerr << "Unrecognised optional flag: " << flag << std::endl;
      return {};
    }
  }
  return LiftArgs{std::move(action),       std::move(sla_file_name),
                  std::move(bytes),        addr,
                  std::move(root_sla_dir), std::move(pspec_file_name)};
}

int main(int argc, char *argv[]) {
  // Check for `--help` or `--version`
  if (argc == 2) {
    const std::string cmd = argv[1];
    if (cmd == "--help") {
      PrintUsage(std::cout);
      return EXIT_SUCCESS;
    } else if (cmd == "--version") {
      PrintVersion();
      return EXIT_SUCCESS;
    }
  }
  const auto args = ParseArgs(argc, argv);
  if (!args) {
    PrintUsage(std::cerr);
    return EXIT_FAILURE;
  }
  const uint64_t addr = args->addr ? *args->addr : 0;
  // Find SLA file path
  const auto sla_file_path =
      args->root_sla_dir
          ? sleigh::FindSpecFile(args->sla_file_name, {*args->root_sla_dir})
          : sleigh::FindSpecFile(args->sla_file_name);
  if (!sla_file_path) {
    std::cerr << "Could not find SLA file: " << args->sla_file_name
              << std::endl;
    return EXIT_FAILURE;
  }
  // Put together Sleigh components
  ghidra::AttributeId::initialize();
  ghidra::ElementId::initialize();
  InMemoryLoadImage load_image(addr);
  ghidra::ContextInternal ctx;
  ghidra::Sleigh engine(&load_image, &ctx);
  ghidra::DocumentStorage storage;
  std::istringstream sla("<sleigh>" + sla_file_path->string() + "</sleigh>");
  ghidra::Element *root =
      storage.parseDocument(sla)->getRoot();
  storage.registerTag(root);
  std::optional<std::filesystem::path> pspec_file_path;
  if (args->pspec_file_name) {
    // A PSPEC file was explicitly supplied
    pspec_file_path = args->root_sla_dir
                          ? sleigh::FindSpecFile(*args->pspec_file_name,
                                                 {*args->root_sla_dir})
                          : sleigh::FindSpecFile(*args->pspec_file_name);
    if (!pspec_file_path) {
      std::cerr << "Could not find PSPEC file: " << *args->pspec_file_name
                << std::endl;
      return EXIT_FAILURE;
    }
  } else {
    // Otherwise, see if there's a PSPEC file named identically to the SLA file
    pspec_file_path = *sla_file_path;
    pspec_file_path->replace_extension(".pspec");
    if (!std::filesystem::exists(*pspec_file_path)) {
      // If a file with that extension doesn't exist, don't attempt to load it
      pspec_file_path = {};
    }
  }
  if (pspec_file_path) {
    ghidra::Element *pspec_root =
        storage.openDocument(pspec_file_path->string())->getRoot();
    storage.registerTag(pspec_root);
  }
  engine.initialize(storage);
  engine.allowContextSet(false);
  // Now that context symbol names are loaded by the translator
  // we can set the default context
  // This imitates what is done in
  //   void Architecture::parseProcessorConfig(DocumentStorage &store)
  const ghidra::Element *el = storage.getTag("processor_spec");
  if (el) {
    ghidra::XmlDecode decoder(&engine, el);
    ghidra::uint4 elemId = decoder.openElement(ghidra::ELEM_PROCESSOR_SPEC);
    for (;;) {
      ghidra::uint4 subId = decoder.peekElement();
      if (subId == 0)
        break;
      else if (subId == ghidra::ELEM_CONTEXT_DATA) {
        ctx.decodeFromSpec(decoder);
        break;
      } else {
        decoder.openElement();
        decoder.closeElementSkipping(subId);
      }
    }
    decoder.closeElement(elemId);
  }

  // In order to parse and validate the byte string properly, we need to get the
  // address size from Sleigh. Therefore this needs to happen after
  // initialization.
  //
  // Ensure that we don't start disassembling until we've set the image buffer.
  std::string image_buffer =
      ParseHexBytes(args->bytes, addr, engine.getDefaultSize());
  const size_t len = image_buffer.size();
  load_image.SetImageBuffer(std::move(image_buffer));
  if (args->action == "disassemble") {
    PrintAssembly(engine, addr, len);
  } else if (args->action == "pcode") {
    PrintPcode(engine, addr, len);
  } else {
    std::cerr << "Invalid action: " << args->action << std::endl;
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
