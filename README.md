# RV32IM Single-Cycle CPU

## Project Overview / Unique Features

This project implements a **fully modular RV32IM Single-Cycle CPU** with extensive RTL coverage and configurable datapath. It is designed for clarity, scalability, and educational value, while also serving as a foundation for more advanced 5-stage pipelined implementation.

### Key Highlights

* **Full RV32IM ISA Support**: Implements both RV32I and RV32M instructions, including integer arithmetic, logic, multiplication, and division.
* **Separate ALUs**: Distinct ALU blocks for RV32I and RV32M operations, improving future critical path management when pipelining and modularity.
* **Single-Cycle Execution**: Every instruction completes in a single clock cycle, making timing predictable and easy to analyze. This is the simplest version of a RISC-V CPU possible. More advanced designs are based off of this initial approach.
* **Modular RTL Architecture**: The CPU consists of 17 parameterized modules, including:

  * Program Counter & PC Incrementer
  * Instruction Memory & Register File
  * Immediate Generator
  * Control Unit with full signal decoding for RV32IM
  * ALU Input Selector & ALU Control Generator
  * Separate RV32I and RV32M ALUs
  * Branch and Jump Target Generators
  * Target Controller, ALU Select Mux, Writeback Mux, and PC Next Mux
  * Data Memory supporting variable-width reads and writes (LW, LH, LB, LHU, LBU, SW, SH, SB)
* **Parameterization for Expansion**: All modules are parameterized to support future upgrades, including multi-stage pipelining.
* **Testbench Coverage**: Individual module testbenches with corner-case verification; full datapath testbenches in progress.
* **Debug-Friendly Design**: Exposed ports and structured naming allow easy waveform observation and integration with simulation tools.
* **Scalable and Educational**: Designed for both learning and practical RTL experimentation, with clean, modular coding conventions.

This CPU project provides a solid foundation for exploring **RISC-V CPU design**, datapath optimization, and modular hardware development
