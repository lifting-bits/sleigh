# Ghidra Patches

This directory contains small patches that should not affect any deployed Ghidra sleigh functionality from its original intent.

These patches primarily support packaging and testing, or fixing critical issues that prevent building for one reason or another.

The two directories are detailed below:

* [`stable`](./stable) --- Patches applied to the officially released _stable_ version of Ghidra.
* [`HEAD`](./HEAD) --- Patches applied to Ghidra's newer _HEAD_ commit (as listed in [`../src/setup-ghidra-source.cmake`](../src/setup-ghidra-source.cmake) file).

See the [`../src/README.md`](../src/README.md) for more details on how these patches are used/applied.
