# RV32IM Single-Cycle CPU

## Project Overview

This project implements a **fully modular RV32IM Single-Cycle CPU** with extensive RTL coverage and a configurable datapath. It is designed for clarity, scalability, and educational value, while also serving as a foundation for a more advanced 5-stage pipelined implementation. IThis CPU is planned to cover the complete RV32IM instruction set, featuring 40+ instructions, with unique modifications made to the data and control paths for educational research and exploration.


### Key Highlights

* **Full RV32IM ISA Support**: Implements both RV32I and RV32M instructions, including integer arithmetic, logic, multiplication, and division.
* **Separate ALUs**: Distinct ALU blocks for RV32I and RV32M operations, improving future critical path management when pipelining and modularity.
* **Single-Cycle Execution**: Every instruction completes in a single clock cycle, making timing predictable and easy to analyze. This is the simplest version of a RISC-V CPU possible. More advanced designs are based off of this initial approach.       
* **Parameterization for Expansion**: All modules are parameterized to support future upgrades, including multi-stage pipelining, RV64 ISA expansion etc.
* **Testbench Coverage**: Individual module testbenches with corner-case verification; **full datapath testbenches in progress**.
* **Debug-Friendly Design**: Exposed ports and structured naming allow easy waveform observation and integration with simulation tools.
* **Scalable and Educational**: Designed for both learning and practical RTL experimentation, with clean, modular coding conventions (pascal case nomenclature).
* **Tool Considerations**: This CPU has been designed primiarily using Vivado 2024.2 EDA Suite (ML Standard Edition). The directory structure and usage instructions are reflective of this.

### RTL Implementation
This CPU consists of 17 parameterized modules, namely:
  * 1. Program Counter
  * 2. PC Incrementer
  * 3. Instruction Memory (read only)
  * 4. Register File (dual port read/single port write)
  * 5. Immediate Generator for RV32IM
  * 6. Control Unit with full signal decoding for RV32IM
  * 7. ALU Input Selector (mux tree)
  * 8. ALU Control Generator (with custom control codes)
  * 9. ALU for RV32I insturctions
  * 10. ALU for RV32M instructions
  * 11. Branch Target Generator (offset addition)
  * 12. Jump Target Generator (masking/passthrough)
  * 13. Target Controller (for Branch and Jump decisions)
  * 14. ALU Select Mux (select between RV32I and RV32M ALUs)
  * 15. Writeback Mux
  * 16. PC Next Mux
  * 17. Data Memory (single port read/write)

### Supported Instructions by Type

This CPU fully implements the **RV32IM ISA**, including both integer and multiplication/division operations.

| Type | Instructions |
|------|--------------|
| **R-type (RV32I)** | `ADD`, `SUB`, `SLT`, `SLTU`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA` |
| **R-type (RV32M)** | `MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`, `REM`, `REMU` |
| **I-type** | `ADDI`, `SLTI`, `SLTIU`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `JALR`, `LB`, `LH`, `LW`, `LBU`, `LHU` |
| **S-type** | `SB`, `SH`, `SW` |
| **B-type** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| **U-type** | `LUI`, `AUIPC` |
| **J-type** | `JAL` |

### Schematic for Data and Control Path - RV32IM Single Cycle implementation
* ..



### Unique Features
* **Datapath Customisations based on classic designs:** This CPU has been designed with several innovations in the datapath to incorporate RV32M support and ensure adherence to the RV32IM spec.
  * With **2 ALUs present (Rv32I/RV32M)**, a seperate **ALU selector mux** has been implemented that routes the correct Result and Zero signals forward into the datapath.
  * A unified **ALU input selector mux tree** handles all the inputs (ReadData1, ReadData2, Immediate, PC) and routes them to both ALUs
  * A specialised **Target Controller** module decides PCSrc for all 6 Branch instructions based on a unqiue **Zero-based logic** with the Zero signal from the ALUs. The ALUs have also been suitably specialised to account for this logic. THis reduces the need for extra control signals for branch decisions. Jump instructions are also processed by this module.
  * Seperate **Branch Target and Jump Target Generators** have been utilised to route Branch and Jump targets respectively. Jump Targets have been routed seperately since integrating them with the Branch logic would make the Target Generator module dependent on ALU output (bottleneck for JAL).
  * The **Data Memory** module has been designed with partial width stores and loads integrated into the hardware using shift-mask and byte offset methods to ensure that the corresponding instructions are hardware optimised.
* **Control Path Customisations:** Several new and effective control signals have been impelmented as part of the Control Path, for selections between ALus, Target Control, Partial Width Load and Store etc.
* The current design uses **memory pre-loads** for Data Memory and instruction Memory for corner-case testing and verification.



This CPU project provides a solid foundation for exploring **RISC-V CPU design**, datapath optimization, and modular hardware development.
