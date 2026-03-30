# RV32I RISC-V Processor

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-RV32I-orange.svg)
![EDA](https://img.shields.io/badge/EDA-Xilinx_Vivado-lightgrey.svg)

This repository contains my SystemVerilog implementation of the RV32I base integer instruction set architecture.

## Overview

1. **Standard RISC-V CPU:** A single-cycle implementation designed for simplicity and baseline instruction verification.
2. **5-Stage Pipelined RISC-V CPU:** A high-performance pipelined architecture featuring the classic 5-stages:
    1. **IF** - Instruction Fetch
    2. **ID** - Instruction Decode
    3. **EX** - Execute
    4. **MEM** - Memory
    5. **WB** - Write Back

## Folder Structure

The repository is organized into two main Xilinx Vivado projects, each containing modularized SystemVerilog source code (`.sv`) and testbenches (`_tb.sv`):

- `Standard RISC-V CPU/` - Contains the single-cycle processor project.
- `5-Stage Pipelined RISC-V CPU/` - Contains the pipelined processor project.
  - `PIPE-RISC-V-CPU.srcs/PipeRegisters/` - Contains the inter-stage pipeline registers.

**Shared Source Directory Structure:**
- `ALU/`: Arithmetic Logic Unit and corresponding testbench.
- `be_decoder/`: Branch/Exception decoding logic.
- `control/`: Main control unit logic.
- `cpu/`: Top-level CPU wrappers and main testbenches. Includes memory initialization files (`instr_mem_test.hex`, `data_mem_test.hex`).
- `memory/`: Instruction and Data memory modules.
- `reader/`: Instruction reading logic.
- `registers/`: The 32x32 register file implementation.
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

## 📚 Resources

- **RISC-V ISA Manuals:**
  - [The RISC-V Instruction Set Manual Volume I: User-Level ISA (v2.2)](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)
  - [The RISC-V Instruction Set Manual Volume I: Unprivileged ISA (20191213)](https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf)

## 🤝 Contributors

- [Siddarth Kota](https://github.com/your-username)
