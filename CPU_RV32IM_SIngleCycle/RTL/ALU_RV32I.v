/*
* Module: ALU_RV32I.v
* Description: Performs combinational operations as required
*              by the RV32I instruction set and sends result.
*              Leaves RV32M instructions for ALU_RV32M.v
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//NOTE: This ALU can be scaled from 32 bit to any instruction length using the parameter WIDTH
//(* dont_touch = "true" *)
module ALU_RV32I #(parameter WIDTH = 32)(       //NOTE: PC_WIDTH must be the same as WIDTH due to both register and PC being operands in the same ALU
    input  wire signed [WIDTH-1:0] Op1, Op2,    //NOTE below
    input  wire        [5:0]       ALUControl,
    input  wire                    MDSel,
    output reg         [WIDTH-1:0] ALUResult_I,
    output wire                    Zero_I
    );
    
    //0 and 1 notation for width-parametrized ALU use
    localparam [WIDTH-1:0] ZERO      = {WIDTH{1'b0}};
    localparam [WIDTH-1:0] ONE       = {{WIDTH-1{1'b0}}, 1'b1}; 
    
    //NOTE: operations that require signed inputs need the inputs to be declared as signed at the module definition
    //This means unsigned operations within the ALU logic need to be explicitly casted using temp variables
    //Output ALUResult_I need not be casted as signed within module definition
    
    //unsigned temps
    wire [WIDTH-1:0] uOp1 = $unsigned(Op1);
    wire [WIDTH-1:0] uOp2 = $unsigned(Op2);

    
    always @(*) begin
        
        if (MDSel) begin
            ALUResult_I = ZERO;  //Zero default for when MDSel is asserted in this ALU
        end else begin
            case (ALUControl) 
            
                //Arithmetic and Logical Ops (R and I type, Load and Store) & Some Branches
                `ALU_ADD,
                `ALU_AUIPC,
                `ALU_JAL:    ALUResult_I = Op1 + Op2;                                    //ADD, ADDI, LW, SW, JALR - Rs1 + Imm, (JAL, AUIPC} - PC + Imm
                `ALU_SUB:    ALUResult_I = Op1 - Op2;                                    //SUB
                `ALU_AND:    ALUResult_I = Op1 & Op2;                                    //AND, ANDI
                `ALU_OR:     ALUResult_I = Op1 | Op2;                                    //OR, ORI
                `ALU_XOR:    ALUResult_I = Op1 ^ Op2;                                    //XOR, XORI
                `ALU_SLL:    ALUResult_I = Op1 << Op2[$clog2(WIDTH)-1:0];                //SLL, SLLI
                `ALU_SRL:    ALUResult_I = Op1 >> Op2[$clog2(WIDTH)-1:0];                //SRL, SRLI
                `ALU_SRA:    ALUResult_I = Op1 >>> Op2[$clog2(WIDTH)-1:0];               //SRA, SRAI
                `ALU_SLT,
                `ALU_BLT,
                `ALU_BGE:    ALUResult_I = (Op1 < Op2) ? ONE : ZERO;                     //SLT, SLTI, BLT, BGE
                `ALU_SLTU,
                `ALU_BLTU,
                `ALU_BGEU:   ALUResult_I = (uOp1 < uOp2) ? ONE : ZERO;                   //SLTU, SLTIU, BGEU
                `ALU_BEQ,
                `ALU_BNE:    ALUResult_I = ((Op1 - Op2) == 0) ? ZERO : ONE;              //BEQ, BNE
                `ALU_LUI:    ALUResult_I = Op2;                                          //LUI - Result = Imm
                        
                //default cases
                `ALU_NOP:    ALUResult_I = ZERO;                                         //NOP
                default:     ALUResult_I = ZERO;                                         //Unknown ALUControl, default to NOP
                
            endcase
             
        end
        
    end
    
    assign Zero_I = (ALUResult_I == ZERO);        //NOTE: This flag is used as a condition flag for BEQ
                                                  //and as an inverted condition flag for BNE, BLT, BGE, BLTU, BGEU
    
endmodule
