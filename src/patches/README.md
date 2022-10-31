# Ghidra Patches

This directory contains small patches that do not affect any deployed Ghidra sleigh functionality from its original intent unless otherwise specified.

These patches primarily support packaging and testing, or fixing critical issues that prevent building for one reason or another.

The two directories are detailed below:

* [`stable`](./stable) --- Patches applied to the officially released _stable_ version of Ghidra.
* [`HEAD`](./HEAD) --- Patches applied to Ghidra's newer _HEAD_ commit (as listed in [`../setup-ghidra-source.cmake`](../setup-ghidra-source.cmake) file).

See the [`../README.md`](../README.md) for more details on how these patches are used/applied.

## Patch Generation

These patches are generated from a forked Ghidra repository with a specified branching scheme and directions for generating these patches. During the event of patch conflicts, the hope is that working on those branches will make managing patches easier.
