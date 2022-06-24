# Ghidra Patches

This directory contains small patches that do not affect any deployed Ghidra sleigh functionality from its original intent unless otherwise specified.

These patches primarily support packaging and testing, or fixing critical issues that prevent building for one reason or another.

The three directories are detailed below:

* [`stable`](./stable) --- Patches applied to the officially released _stable_ version of Ghidra.
* [`HEAD`](./HEAD) --- Patches applied to Ghidra's newer _HEAD_ commit (as listed in [`../src/setup-ghidra-source.cmake`](../src/setup-ghidra-source.cmake) file).
* [`remill_specific_patches`] --- Patches applied to Ghidra stable that expose pc relative computations through a claim_eq hint. (These are not enabled by default and primarily used inside remill to lift pcode->llvm)

See the [`../src/README.md`](../src/README.md) for more details on how these patches are used/applied.
