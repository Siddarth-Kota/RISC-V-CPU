# Synthesis setup

From Design Compiler, after sourcing the lab's setup, run:

```tcl
source {synth/read_rtl.tcl}
```

This command assumes the current directory is the FPGA project. You can also source the script by absolute path from a separate run directory. The script reads `rtl/files.f` and analyzes the design sources. It excludes the testbenches, debug package, and memory images.

The current `cpu` top has only clock and reset inputs, with simulation-initialized memory inside it. Before collecting timing, utilization, or PPA results, give the synthesized top observable interfaces and choose a memory implementation. Then add the target's real constraints and libraries. For Vivado, this means the selected device and an XDC. For Design Compiler, this means the lab's target and link libraries, clock and I/O constraints, and SRAM timing views if using hard macros.
