# RV32I RISC-V Processor

This repository contains my SystemVerilog implementation of the RV32I base integer instruction set architecture. Testing and development was done in AMD Xilinx Vivado

## Overview

1. **Standard RISC-V CPU:** A single-cycle implementation designed for simplicity and baseline instruction verification.
2. **5-Stage Pipelined RISC-V CPU:** A high-performance pipelined architecture featuring the classic 5-stages:
    - **IF** - Instruction Fetch
    - **ID** - Instruction Decode
    - **EX** - Execute
    - **MEM** - Memory
    - **WB** - Write Back

## Folder Structure

The repository is organized into two main Xilinx Vivado projects, each containing modularized SystemVerilog source code (`.sv`) and testbenches (`_tb.sv`):

- `Standard RISC-V CPU/` - Contains the single-cycle processor project.
- `5-Stage Pipelined RISC-V CPU/` - Contains the pipelined processor project.
  - `PIPE-RISC-V-CPU.srcs/PipeRegisters/` - Contains the inter-stage pipeline registers.
  - `PIPE-RISC-V-CPU.srcs/forwarding/` - Contains the Forwarding Unit for data hazards
  - `PIPE-RISC-V-CPU.srcs/hazard_detection/` - Contains the Hazard Detection Unit to stall the Pipeline for load-use and control hazards.

**Shared Source Directory Structure:**
- `ALU/`: Arithmetic Logic Unit
- `be_decoder/`: Byte Enable decoding logic.
- `control/`: Main control unit logic.
- `cpu/`: Top-level CPU module. Includes memory initialization files (`instr_mem_test.hex`, `data_mem_test.hex`).
- `memory/`: Instruction and Data memory modules.
- `reader/`: Memory Alignment Unit
- `registers/`: Register Implementation
- `signextender/`: Immediate generation and sign-extension logic.

## Implemented Instructions

The following table lists the status of the RV32I base integer instructions supported by this core. 

| # | Instruction | Implemented | Tested | Working |
|---|-------------|:-----------:|:------:|:-------:|
| 1 | `LUI`       |     ✅     |   ✅   |   ✅   | 
| 2 | `AUIPC`     |     ✅     |   ✅   |   ✅   | 
| 3 | `JAL`       |     ✅     |   ✅   |   ✅   | 
| 4 | `JALR`      |     ✅     |   ✅   |   ✅   | 
| 5 | `BEQ`       |     ✅     |   ✅   |   ✅   | 
| 6 | `BNE`       |     ✅     |   ✅   |   ✅   | 
| 7 | `BLT`       |     ✅     |   ✅   |   ✅   | 
| 8 | `BGE`       |     ✅     |   ✅   |   ✅   | 
| 9 | `BLTU`      |     ✅     |   ✅   |   ✅   | 
| 10| `BGEU`      |     ✅     |   ✅   |   ✅   | 
| 11| `LB`        |     ✅     |   ✅   |   ✅   | 
| 12| `LH`        |     ✅     |   ✅   |   ✅   | 
| 13| `LW`        |     ✅     |   ✅   |   ✅   | 
| 14| `LBU`       |     ✅     |   ✅   |   ✅   | 
| 15| `LHU`       |     ✅     |   ✅   |   ✅   | 
| 16| `SB`        |     ✅     |   ✅   |   ✅   | 
| 17| `SH`        |     ✅     |   ✅   |   ✅   | 
| 18| `SW`        |     ✅     |   ✅   |   ✅   | 
| 19| `ADDI`      |     ✅     |   ✅   |   ✅   | 
| 20| `SLTI`      |     ✅     |   ✅   |   ✅   | 
| 21| `SLTIU`     |     ✅     |   ✅   |   ✅   | 
| 22| `XORI`      |     ✅     |   ✅   |   ✅   | 
| 23| `ORI`       |     ✅     |   ✅   |   ✅   | 
| 24| `ANDI`      |     ✅     |   ✅   |   ✅   | 
| 25| `SLLI`      |     ✅     |   ✅   |   ✅   | 
| 26| `SRLI`      |     ✅     |   ✅   |   ✅   | 
| 27| `SRAI`      |     ✅     |   ✅   |   ✅   | 
| 28| `ADD`       |     ✅     |   ✅   |   ✅   | 
| 29| `SUB`       |     ✅     |   ✅   |   ✅   | 
| 30| `SLL`       |     ✅     |   ✅   |   ✅   | 
| 31| `SLT`       |     ✅     |   ✅   |   ✅   | 
| 32| `SLTU`      |     ✅     |   ✅   |   ✅   | 
| 33| `XOR`       |     ✅     |   ✅   |   ✅   | 
| 34| `SRL`       |     ✅     |   ✅   |   ✅   | 
| 35| `SRA`       |     ✅     |   ✅   |   ✅   | 
| 36| `OR`        |     ✅     |   ✅   |   ✅   | 
| 37| `AND`       |     ✅     |   ✅   |   ✅   | 
| 38| `FENCE`     |     ❌     |   ❌   |   ❌   | 
| 39| `ECALL`     |     ❌     |   ❌   |   ❌   | 
| 40| `EBREAK`    |     ❌     |   ❌   |   ❌   | 

## Resources

- **RISC-V ISA Manuals:**
  - [The RISC-V Instruction Set Manual Volume I](https://riscv.org/specifications/ratified/)

## Contributors

- [Siddarth Kota](https://github.com/Siddarth-Kota)
