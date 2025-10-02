/*
* Module: Control_Unit.v
* Description: Decodes the opcode of the current instruction and generates all necessary control signals 
*              required to drive the datapath components, including ImmediateSrc, ALUOp, ALUSrc1&2, MemRead, 
*              MemWrite, RegWrite, TargetSel, and MemToReg. Handles control for RV32I and RV32M instructions.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//(* dont_touch = "true" *)
module Control_Unit #(
    parameter WIDTH       = 32,
    parameter INSTR_WIDTH = 32
    )(
    input  wire [INSTR_WIDTH-1:0] Instr_RV32IM,  
    
    output reg [2:0]              ALUOp,
    output reg                    MDSel,
    output reg [2:0]              ImmediateSrc,
    output reg [3:0]              TargetSel,
    output reg                    RegWrite,
    output reg                    MemRead,
    output reg                    MemWrite,
    output reg [1:0]              MemToReg,
    output reg [2:0]              MemDataType,
    output reg                    ALUSrc1, ALUSrc2
    );
    
    wire [6:0] Opcode = Instr_RV32IM[6:0];      // Instruction length Not parameterized because Instruction decoding...
    wire [6:0] funct7 = Instr_RV32IM[31:25];    // ...and is standard for all RV ISA specs.
    wire [2:0] funct3 = Instr_RV32IM[14:12];    //Hardcoded for standard format instead.
    
    wire [14:0] Control_unused = {Instr_RV32IM[24:15], Instr_RV32IM[11:7]};    //to avoid linter violations
    
    always @(*) begin
        case (Opcode)
        
            `OPCODE_RTYPE:  begin            //R-type Instructions
            
                case (funct7)
                    7'b0000000,
                    7'b0100000: begin
                        ALUOp = `ALUOP_RTYPE;                           //RV32I
                        MDSel = 1'b0;                                   //Initiates ALU_RV32I
                    end
                    
                    7'b0000001: begin
                        ALUOp = `ALUOP_RMUL;                            //RV32M
                        MDSel = 1'b1;                                   //Initiates ALU_RV32M
                    end
                    
                    default:    begin
                        ALUOp = `ALUOP_NOP;                             //fallback
                        MDSel = 1'b0;
                    end
                    
                endcase
                
                ImmediateSrc = `IMM_NONE;
                TargetSel    = `TR_NOP; 
                RegWrite     = 1'b1;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b00;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b0;
                ALUSrc2      = 1'b0;
            end
            
            `OPCODE_ITYPE:  begin            //I-type Arithmetic and Logical Instructions
                ALUOp        = `ALUOP_ITYPE;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_I;
                TargetSel    = `TR_NOP; 
                RegWrite     = 1'b1;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b00;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b0;
                ALUSrc2      = 1'b1;
            end
            
            `OPCODE_LOAD:   begin            //Load Instructions (I-type)
                ALUOp        = `ALUOP_LSJ;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_I;
                TargetSel    = `TR_NOP; 
                RegWrite     = 1'b1;
                MemRead      = 1'b1;
                MemWrite     = 1'b0;
                MemToReg     = 2'b01;
                
                case(funct3)
                    `MEM_BYTE_SIGNED,                                   //LB
                    `MEM_HALF_SIGNED,                                   //LH
                    `MEM_WORD,                                          //LW
                    `MEM_BYTE_UNSIGNED,                                 //LBU
                    `MEM_HALF_UNSIGNED:  MemDataType  = funct3;         //LHU                  
                    default:             MemDataType  = `MEM_INVALID;   //fallback
                endcase
                
                ALUSrc1      = 1'b0;
                ALUSrc2      = 1'b1;
            end
            
            `OPCODE_STORE:  begin            //SW (S-type Instruction)
                ALUOp        = `ALUOP_LSJ;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_S;
                TargetSel    = `TR_NOP; 
                RegWrite     = 1'b0;
                MemRead      = 1'b0;
                MemWrite     = 1'b1;
                MemToReg     = 2'bxx;
                
                case(funct3)
                    `MEM_BYTE_SIGNED,                                   //SB
                    `MEM_HALF_SIGNED,                                   //SH
                    `MEM_WORD:           MemDataType  = funct3;         //SW                 
                    default:             MemDataType  = `MEM_INVALID;   //fallback
                endcase
                
                ALUSrc1      = 1'b0;
                ALUSrc2      = 1'b1;
            end
            
            `OPCODE_BRANCH: begin            //B-type Instructions
                ALUOp        = `ALUOP_BRANCH;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_B;
                
                case ({1'b0,funct3})        //since TargetSel is 4 bits long to account for JALR in branch/jump target selection
                    `BR_EQ,
                    `BR_NE,
                    `BR_LT,
                    `BR_GE,
                    `BR_LTU,
                    `BR_GEU: TargetSel = {1'b0,funct3}; 
                    default: TargetSel = `TR_NOP;
                endcase
                
                RegWrite     = 1'b0;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'bxx;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b0;
                ALUSrc2      = 1'b0;
            end
            
            `OPCODE_LUI:    begin            //LUI (U-type Instruction)
                ALUOp        = `ALUOP_UTYPE;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_U;
                TargetSel    = `TR_NOP; 
                RegWrite     = 1'b1;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b00;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b0;     
                ALUSrc2      = 1'b1;
            end
            
            `OPCODE_AUIPC:  begin            //AUIPC (U-type Instruction)
                ALUOp        = `ALUOP_UTYPE;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_U;
                TargetSel    = `TR_NOP; 
                RegWrite     = 1'b1;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b00;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b1;
                ALUSrc2      = 1'b1;
            end
                
            `OPCODE_JAL:    begin            //JAL (J-type Instruction)
                ALUOp        = `ALUOP_JUMP;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_J;
                TargetSel    = `UJ_AL; 
                RegWrite     = 1'b1;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b10;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b1;            //PC
                ALUSrc2      = 1'b1;            //Imm
            end
            
            `OPCODE_JALR:   begin            //JALR (I-type Instruction)
                ALUOp        = `ALUOP_LSJ;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_I;
                TargetSel    = `UJ_ALR; 
                RegWrite     = 1'b1;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b10;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b0;            //Rs1
                ALUSrc2      = 1'b1;            //Imm
            end
            
            default:        begin            //Default fallback
                ALUOp        = `ALUOP_NOP;
                MDSel        = 1'b0;
                ImmediateSrc = `IMM_NONE;
                TargetSel    = `TR_NOP;
                RegWrite     = 1'b0;
                MemRead      = 1'b0;
                MemWrite     = 1'b0;
                MemToReg     = 2'b00;
                MemDataType  = `MEM_INVALID; 
                ALUSrc1      = 1'b0;
                ALUSrc2      = 1'b0;
            end
        endcase
    end
    
endmodule