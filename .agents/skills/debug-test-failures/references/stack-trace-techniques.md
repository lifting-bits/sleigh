# Stack Trace Techniques

When a test binary crashes (typically SIGABRT from a libc++ hardening assertion),
these techniques can be used to identify the exact function and source line.

## Method 1: gdb (simplest)

gdb in batch mode produces full demangled backtraces and works reliably in most
environments, including containers with default seccomp profiles.

```bash
cd build/ci-head-assertions

gdb -batch \
  -ex "run -sleighpath . -path _deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/datatests datatests" \
  -ex "bt" \
  ./tests/sleigh_decomp_test
```

gdb will run the program, and when it crashes (e.g., SIGABRT), it automatically
stops and prints the backtrace. The output includes fully demangled C++ function
names and source locations.

If gdb is unavailable, try lldb (Method 2). If neither debugger can attach
(restricted ptrace), fall back to Method 3.

## Method 2: lldb

Use lldb in batch mode with the full test arguments. The key is to handle SIGABRT
so it stops instead of terminating.

**Important**: Use `-k` (one-line-on-crash) for the backtrace command, not `-o`.
Commands passed via `-o` run sequentially after file load, but when lldb hits a
signal stop, it enters its event loop and won't execute subsequent `-o` commands.
The `-k` flag queues commands to run specifically when the target crashes.

```bash
cd build/ci-head-assertions

lldb -b \
  -o "process handle SIGABRT --stop true --pass false" \
  -o "run -sleighpath . -path _deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/datatests datatests" \
  -k "thread backtrace" \
  -k "quit" \
  -- ./tests/sleigh_decomp_test
```

If lldb shows full symbol names (function + file + line), you're done.

If lldb fails with "personality set failed: Operation not permitted", this is
common in Docker containers where ptrace is restricted. Use Method 3 instead.

## Method 3: LD_PRELOAD Backtrace Library

Build a small shared library that intercepts SIGABRT and prints a backtrace:

```bash
cat > /tmp/bt_preload.c << 'BTEOF'
#include <signal.h>
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void bt_handler(int sig) {
    void *array[50];
    int size = backtrace(array, 50);
    fprintf(stderr, "=== BACKTRACE (signal %d) ===\n", sig);
    backtrace_symbols_fd(array, size, STDERR_FILENO);
    fprintf(stderr, "=== END BACKTRACE ===\n");
    signal(sig, SIG_DFL);
    raise(sig);
}

__attribute__((constructor))
void install_handler(void) {
    signal(SIGABRT, bt_handler);
}
BTEOF
gcc -shared -fPIC -o /tmp/bt_preload.so /tmp/bt_preload.c -rdynamic
```

Run the test with the preloaded library:

```bash
cd build/ci-head-assertions

LD_PRELOAD=/tmp/bt_preload.so ./tests/sleigh_decomp_test \
  -sleighpath . \
  -path _deps/ghidrasource-src/Ghidra/Features/Decompiler/src/decompile/datatests \
  datatests
```

The output will look like:

```
=== BACKTRACE (signal 6) ===
./tests/sleigh_decomp_test(+0xf1a64)[0x55c312f02a64]
./tests/sleigh_decomp_test(+0xf17ea)[0x55c312f027ea]
./tests/sleigh_decomp_test(+0xef732)[0x55c312f00732]
...
=== END BACKTRACE ===
```

The addresses in parentheses (like `+0xf1a64`) are the key — these are offsets
from the binary's load address.

## Method 4: addr2line

Resolve the hex offsets from the backtrace to function names and source lines:

```bash
for addr in 0xf1a64 0xf17ea 0xef732 0x31fbd9 0x31d536; do
  echo -n "$addr: "
  addr2line -e ./tests/sleigh_decomp_test -f -C "$addr"
  echo "---"
done
```

Flags:
- `-e` specifies the executable
- `-f` prints function names
- `-C` demangles C++ names

Example output:
```
0xf1a64: void std::__1::__check_strict_weak_ordering_sorted<...>(...)
/usr/lib/llvm-21/bin/../include/c++/v1/__debug_utils/strict_weak_ordering_check.h:51
---
0x31fbd9: ghidra::BlockGraph::orderBlocks()
/path/to/block.hh:431
---
```

This tells you exactly which sort call and which comparator function triggered
the assertion.

## Putting It All Together

Typical debugging flow:

1. Run the test: `ctest --test-dir build/ci-head-assertions -R decomp_datatest --output-on-failure`
2. See assertion failure → need stack trace
3. Try gdb first (Method 1) — it typically gives the best output with full demangled symbols
4. If gdb is unavailable, try lldb (Method 2)
5. If neither debugger can attach → build LD_PRELOAD library (Method 3)
6. Resolve addresses with addr2line (Method 4) if the backtrace only has hex offsets
7. Now you know which comparator function and sort call is the problem
8. Read the comparator code and check for strict-weak ordering violations
