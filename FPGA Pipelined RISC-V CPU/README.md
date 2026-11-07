# FPGA Pipelined RISC-V CPU

This project copy is the starting point for FPGA and ASIC synthesis experiments.

- `rtl/` contains the existing design. `rtl/files.f` lists the RTL in compile order, with the shared package first and `cpu` last.
- `sim/tb/` contains the testbenches and their include file. `sim/support/` contains the debug package, and `sim/fixtures/` contains the two memory images.
- `sim/files.f` combines the RTL and simulation sources for simulators that support nested file lists. Resolve paths relative to this project directory.
- `synth/` contains the Design Compiler RTL import and notes on what the synthesis flow needs.

## Behavioral simulation

In Vivado, open `PIPE-RISC-V-CPU.xpr` and run **Run Behavioral Simulation**. The simulation top is `cpu_tb`. The other benches are available under Simulation Sources.

For a standalone simulator, select `cpu_tb` and make the two files from `sim/fixtures/` available by basename in the simulator's run directory. The legacy CPU uses those basenames in its memory initialization parameters. Keep generated build files outside the source folders.

## Synthesis

The Vivado design top is `cpu`. For Design Compiler, see [synthesis setup](synth/README.md).
