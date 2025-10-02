/*
* Module: CPU_Control_Codes.vh
* Description: Header file containing all requisite ALUControl, ALUOp,
*              BranchSel, ImmediateSrc and Opcodes with readable definitions 
*              for the Control Logic and ALU modules for readability.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`ifndef CPU_CONTROL_CODES_VH
`define CPU_CONTROL_CODES_VH


//=======================================================
//ALUControl Codes - Core Functions + Instruction Aliases
//=======================================================

//---------------- Core ALU Function Codes ------------------
`define ALU_ADD           6'b000000     //unreachable in ALU (synthesis)
`define ALU_SUB           6'b000001
`define ALU_AND           6'b000010
`define ALU_OR            6'b000011
`define ALU_XOR           6'b000100
`define ALU_SLL           6'b000101
`define ALU_SRL           6'b000110
`define ALU_SRA           6'b000111
`define ALU_SLT           6'b001000     //unreachable in ALU (synthesis)
`define ALU_SLTU          6'b001001     //unreachable in ALU (synthesis)
`define ALU_GE            6'b001010  
`define ALU_GEU           6'b001011
`define ALU_EQ            6'b001100
`define ALU_PASS_B        6'b001101
`define ALU_PC_PLUS_IMM   6'b001110


//----------- RV32M: Multiply / Divide / Remainder -----------
`define ALU_MUL           6'b010000
`define ALU_MULH          6'b010001
`define ALU_MULHU         6'b010010
`define ALU_MULHSU        6'b010011
`define ALU_DIV           6'b010100
`define ALU_DIVU          6'b010101
`define ALU_REM           6'b010110
`define ALU_REMU          6'b010111

//--------------- Instruction Aliases ------------------
//R-type and I-type
`define ALU_ADDI          `ALU_ADD
`define ALU_LW            `ALU_ADD
`define ALU_SW            `ALU_ADD
`define ALU_JALR          `ALU_ADD

`define ALU_ANDI          `ALU_AND
`define ALU_ORI           `ALU_OR
`define ALU_XORI          `ALU_XOR
`define ALU_SLLI          `ALU_SLL
`define ALU_SRLI          `ALU_SRL
`define ALU_SRAI          `ALU_SRA
`define ALU_SLTI          `ALU_SLT
`define ALU_SLTIU         `ALU_SLTU

// Branch aliases
`define ALU_BEQ           `ALU_EQ
`define ALU_BNE           `ALU_EQ
`define ALU_BLT           `ALU_SLT         
`define ALU_BGE           `ALU_GE           
`define ALU_BLTU          `ALU_SLTU       
`define ALU_BGEU          `ALU_GEU          

//Upper Immediate ops
`define ALU_LUI           `ALU_PASS_B
`define ALU_AUIPC         `ALU_PC_PLUS_IMM

//Jumps
`define ALU_JAL           `ALU_PC_PLUS_IMM

//--------------- Fallback ------------------
`define ALU_NOP           6'b111111





//=======================================================
//ALUOp Codes - to guide ALUControl submodule
//=======================================================

`define ALUOP_LSJ      3'b000   //Base load/store (add) + JALR
`define ALUOP_BRANCH   3'b001   //Branch comparisons
`define ALUOP_RTYPE    3'b010   //R-type ops
`define ALUOP_ITYPE    3'b011   //I-type ALU ops
`define ALUOP_RMUL     3'b100   //RV32M (MUL/DIV)
`define ALUOP_UTYPE    3'b101   //LUI, AUIPC
`define ALUOP_JUMP     3'b110   //JAL

//Optional NOP or fallback (not used directly)
`define ALUOP_NOP      3'b111






// ==========================================================================
// TargetSel Codes - for Target Controller to decide branch or jump behaviour
// ==========================================================================

`define BR_EQ    4'b0000   //BEQ
`define BR_NE    4'b0001   //BNE

`define UJ_AL    4'b0010   //JAL (jump always) (PC + Imm from ALU)
`define TR_NOP   4'b0011   //No branch / default
`define UJ_ALR   4'b1001   //JALR ((Rs1 + Imm) & ~1 from ALU) - JALR funct3 is 001

`define BR_LT    4'b0100   //BLT
`define BR_GE    4'b0101   //BGE
`define BR_LTU   4'b0110   //BLTU
`define BR_GEU   4'b0111   //BGEU






//=======================================================
//ImmediateSrc Codes - to select correct immediate format
//=======================================================

`define IMM_NONE 3'b000   //R-type (no immediate)
`define IMM_I    3'b001   //I-type (ADDI, LW, JALR)
`define IMM_S    3'b010   //S-type (SW)
`define IMM_B    3'b011   //B-type (branches)
`define IMM_U    3'b100   //U-type (LUI, AUIPC)
`define IMM_J    3'b101   //J-type (JAL)






//==========================================================================
//MemDataType Codes - for Load/Store Instructions (used by Control Unit)
//==========================================================================

`define MEM_BYTE_SIGNED     3'b000     // LB / SB   - Load/Store signed byte
`define MEM_HALF_SIGNED     3'b001     // LH / SH   - Load/Store signed halfword
`define MEM_WORD            3'b010     // LW / SW   - Load/Store word (32-bit)
`define MEM_BYTE_UNSIGNED   3'b100     // LBU       - Load unsigned byte
`define MEM_HALF_UNSIGNED   3'b101     // LHU       - Load unsigned halfword

//Default Fallback
`define MEM_INVALID         3'b111     // Default / Non-memory instruction






//=======================================================
//Opcodes - Instruction class identifiers (optional)
//Non-functional; for decode readability only
//=======================================================

`define OPCODE_RTYPE   7'b0110011
`define OPCODE_ITYPE   7'b0010011
`define OPCODE_LOAD    7'b0000011
`define OPCODE_STORE   7'b0100011
`define OPCODE_BRANCH  7'b1100011
`define OPCODE_LUI     7'b0110111
`define OPCODE_AUIPC   7'b0010111
`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111





//===========================================================
//Simulation Aids: Hex Files and Simulation Parameters
//Memory Hex Files: For Simulation Aid (optional)
//            1. Instruction Memory Program
//            2. Data Memory Program 
//Avoids synthezisable blocks with ifndef, for easy testing  
//===========================================================

//reading from file
`define IMEM_HEX_PROGRAM "<absolute_path>/CPU_RV32IM_SingleCycle/RTL/Mem_Hex_Files/IMEM_RV32IM_Program.hex"
`define DMEM_HEX_BLOCK   "<absolute_path>/CPU_RV32IM_SingleCycle/RTL/Mem_Hex_Files/DMEM_Data_Block.hex"

//writing to file
`define IMEM_HEX_DUMP    "<absolute_path>/CPU_RV32IM_SingleCycle/RTL/Mem_Hex_Files/IMEM_RV32IM_Dump.hex"
`define DMEM_HEX_DUMP    "<absolute_path>/CPU_RV32IM_SingleCycle/RTL/Mem_Hex_Files/DMEM_Data_Dump.hex"

//simulation params
`define SIM_TIME    5'd10000

`endif
