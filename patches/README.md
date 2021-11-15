# Ghidra Patches

This directory contains small patches that should not affect any deployed source code functionality.

These patches primarily support packaging, testing, or critical fixes that prevent building for one reason or another.

The two directories are detailed below:

* [`stable`](./stable) --- Patches applied to the officially released _stable_ version of Ghidra.
* [`HEAD`](./HEAD) --- Patches applied to Ghidra's newer _HEAD_ commit (as listed in [`../src/setup-ghidra-source.cmake`](../src/setup-ghidra-source.cmake) file).

See the [`../src/README.md`](../src/README.md) for more details on how these are used.
