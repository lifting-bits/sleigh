#include <sleigh/loadimage.hh>
#include <sleigh/sleigh.hh>

#include <iostream>
#include <string>

static void PrintUsage(void) {
  std::cerr
      << "Usage: sleigh-lift <action> <spec_file> <bytes> <address:optional>"
      << std::endl;
}

class InMemoryLoadImage : public LoadImage {
public:
  explicit InMemoryLoadImage(unsigned long base_addr)
      : LoadImage("nofile"), base_addr(base_addr) {}

  void SetImageBuffer(std::vector<unsigned char> &&buf) {
    assert(image_buffer.empty());
    image_buffer = std::move(buf);
  }

  void loadFill(unsigned char *ptr, int size, const Address &addr) override {
    uint8_t start = addr.getOffset();
    for (int i = 0; i < size; ++i) {
      const int64_t offset = (start + i) - base_addr;
      ptr[i] = (offset >= 0 && offset < image_buffer.size())
                   ? image_buffer[offset]
                   : 0;
    }
  }

  std::string getArchType(void) const override { return "memory"; }
  void adjustVma(long) override {}

private:
  unsigned long base_addr;
  std::vector<unsigned char> image_buffer;
};

static std::vector<unsigned char>
ParseBytes(const std::string &bytes, unsigned long addr, uint64_t addr_size) {
  std::vector<unsigned char> buffer;
  for (size_t i = 0; i < bytes.size(); i += 2) {
    const char nibbles[] = {bytes[i], bytes[i + 1], '\0'};
    char *parsed_to = nullptr;
    auto byte_val = strtol(nibbles, &parsed_to, 16);
    if (parsed_to != &(nibbles[2])) {
      std::cerr << "Invalid hex byte value '" << nibbles
                << "' specified in bytes arg." << std::endl;
      exit(EXIT_FAILURE);
    }
    const uint64_t addr_mask = ~0ULL >> (64UL - addr_size);
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
    buffer.push_back(static_cast<unsigned char>(byte_val));
  }
  return buffer;
}

class AssemblyPrinter : public AssemblyEmit {
public:
  void dump(const Address &addr, const std::string &mnemonic,
            const std::string &body) override {
    addr.printRaw(std::cout);
    std::cout << ": " << mnemonic << ' ' << body << std::endl;
  }
};

static void PrintAssembly(Sleigh &engine, unsigned long addr, size_t len) {
  AssemblyPrinter asm_emit;
  Address cur_addr(engine.getDefaultCodeSpace(), addr),
      last_addr(engine.getDefaultCodeSpace(), addr + len);
  while (cur_addr < last_addr) {
    int32_t instr_len = engine.printAssembly(asm_emit, cur_addr);
    cur_addr = cur_addr + instr_len;
  }
}

static void PrintVarData(std::ostream &s, VarnodeData &data) {
  s << '(' << data.space->getName() << ',';
  data.space->printOffset(s, data.offset);
  s << ',' << std::dec << data.size << ')';
}

class PcodePrinter : public PcodeEmit {
public:
  void dump(const Address &addr, OpCode op, VarnodeData *outvar,
            VarnodeData *vars, int32_t isize) override {
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

static void PrintPcode(Sleigh &engine, unsigned long addr, size_t len) {
  PcodePrinter pcode_emit;
  Address cur_addr(engine.getDefaultCodeSpace(), addr),
      last_addr(engine.getDefaultCodeSpace(), addr + len);
  while (cur_addr < last_addr) {
    int32_t instr_len = engine.oneInstruction(pcode_emit, cur_addr);
    cur_addr = cur_addr + instr_len;
  }
}

int main(int argc, char *argv[]) {
  if (argc < 4 || argc > 5) {
    PrintUsage();
    return -1;
  }
  // Parse arguments
  const char *prog_name = argv[0];
  const std::string action = argv[1];
  const char *spec_file_path = argv[2];
  const std::string bytes = argv[3];
  const char *addr_str = argc == 5 ? argv[4] : nullptr;
  if (bytes.size() % 2 != 0) {
    std::cerr << "Must provide an even number of bytes: " << bytes << std::endl;
    return -1;
  }
  // Get the address as an integer.
  unsigned long addr = 0;
  if (addr_str) {
    try {
      addr = std::stoul(addr_str);
    } catch (std::invalid_argument &ia) {
      std::cerr << "Invalid address argument: " << addr_str << std::endl;
      return EXIT_FAILURE;
    } catch (std::out_of_range &oor) {
      std::cerr << "Address argument out of range: " << addr_str << std::endl;
      return EXIT_FAILURE;
    }
  }
  // Put together SLEIGH components
  InMemoryLoadImage load_image(addr);
  ContextInternal ctx;
  Sleigh engine(&load_image, &ctx);
  DocumentStorage storage;
  Element *root = storage.openDocument(spec_file_path)->getRoot();
  storage.registerTag(root);
  engine.initialize(storage);
  // In order to parse and validate the byte string properly, we need to get the
  // address size from SLEIGH. Therefore this needs to happen after
  // initialization.
  //
  // Ensure that we don't start disassembling until we've set the image buffer.
  std::vector<unsigned char> image_buffer =
      ParseBytes(bytes, addr, engine.getDefaultSize());
  const size_t len = image_buffer.size();
  load_image.SetImageBuffer(std::move(image_buffer));
  if (action == "disassemble") {
    PrintAssembly(engine, addr, len);
  } else if (action == "pcode") {
    PrintPcode(engine, addr, len);
  } else {
    std::cerr << "Invalid action: " << action << std::endl;
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
