/*
* Module: ALUControl_gen.v
* Description: Generates ALUcontrol signals based on ALUop, funct3 
*              and funct7 of instruction codes for RV32IM instructions.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//(* dont_touch = "true" *)
module ALUControl_Gen #(
    parameter WIDTH       = 32,
    parameter INSTR_WIDTH = 32
    )(
    input  wire [2:0]             ALUOp,
    input  wire [INSTR_WIDTH-1:0] Instr_RV32IM,
    output reg  [5:0]             ALUControl
    );
       
    //Obtaining codes from current Instruction  
    //Using harcoded instruction decoding
    wire [2:0] funct3  = Instr_RV32IM[14:12];      //extracted as a wire for Branch Controller
    wire [6:0] funct7  = Instr_RV32IM[31:25];
    wire [6:0] Opcode  = Instr_RV32IM[6:0];
  
  
    //un-utilised bits
    wire [14:0] ALUCtrlGen_unused = {Instr_RV32IM[24:15], Instr_RV32IM[11:7]};    //to avoid linter violations

  
    always @(*) begin
        case (ALUOp)
    
          //Load(LW) / Store(SW): ALU does ADD for memory address location calculation
          //Also used by JALR 
          `ALUOP_LSJ: begin
              ALUControl = `ALU_ADD;
          end
        
          //Branches
          `ALUOP_BRANCH: begin
              case ({1'b0,funct3})           //since TargetSel is 4 bits long to account for JALR in branch/jump target selection
                  `BR_EQ:   ALUControl = `ALU_BEQ;
                  `BR_NE:   ALUControl = `ALU_BNE;
                  `BR_LT:   ALUControl = `ALU_BLT;
                  `BR_GE:   ALUControl = `ALU_BGE;
                  `BR_LTU:  ALUControl = `ALU_BLTU;
                  `BR_GEU:  ALUControl = `ALU_BGEU;
                  default:  ALUControl = `ALU_NOP;
              endcase
          end
    
          //R-Type Integer (ADD, SUB, AND, OR...)
          `ALUOP_RTYPE:  begin
              case (funct3)
                  3'b000:  ALUControl = (funct7 == 7'b0100000) ? `ALU_SUB : `ALU_ADD;
                  3'b001:  ALUControl = `ALU_SLL;
                  3'b010:  ALUControl = `ALU_SLT;
                  3'b011:  ALUControl = `ALU_SLTU;
                  3'b100:  ALUControl = `ALU_XOR;
                  3'b101:  ALUControl = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL;
                  3'b110:  ALUControl = `ALU_OR;
                  3'b111:  ALUControl = `ALU_AND;
                  default: ALUControl = `ALU_NOP;
              endcase
          end
    
          //I-Type Integer (ADDI, ANDI, SLTI...)
          `ALUOP_ITYPE:  begin
              case (funct3)
                  3'b000:  ALUControl = `ALU_ADD;   // ADDI
                  3'b001:  ALUControl = `ALU_SLL;   // SLLI
                  3'b010:  ALUControl = `ALU_SLT;   // SLTI
                  3'b011:  ALUControl = `ALU_SLTU;  // SLTIU
                  3'b100:  ALUControl = `ALU_XOR;   // XORI
                  3'b101:  ALUControl = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL; // SRAI or SRLI
                  3'b110:  ALUControl = `ALU_OR;    // ORI
                  3'b111:  ALUControl = `ALU_AND;   // ANDI
                  default: ALUControl = `ALU_NOP;
              endcase
          end
    
          //RV32M (Multiply & Divide)
          `ALUOP_RMUL:   begin
              case (funct3)
                  3'b000:  ALUControl = `ALU_MUL;
                  3'b001:  ALUControl = `ALU_MULH;
                  3'b010:  ALUControl = `ALU_MULHSU;
                  3'b011:  ALUControl = `ALU_MULHU;
                  3'b100:  ALUControl = `ALU_DIV;
                  3'b101:  ALUControl = `ALU_DIVU;
                  3'b110:  ALUControl = `ALU_REM;
                  3'b111:  ALUControl = `ALU_REMU;
                  default: ALUControl = `ALU_NOP;
              endcase
          end
    
          //U-Type (LUI & AUPIC)
          `ALUOP_UTYPE : begin
              ALUControl = (Opcode == `OPCODE_LUI) ? `ALU_LUI : `ALU_AUIPC;
          end
    
          //Jump
          `ALUOP_JUMP:   begin
              ALUControl = `ALU_JAL;  //used by JAL
          end
    
              //default fallback (no Operation)
              default: ALUControl = `ALU_NOP;
    
        endcase
    end

endmodule
