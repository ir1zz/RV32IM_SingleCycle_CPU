/*
* Module: Immediate_Gen.v
* Description: Generates 32-bit sign-extended immediate based on 
*              RV32IM instruction format. Left shifts immediates by 1 for 
*              Branch and Jump immediates.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//(* dont_touch = "true" *)
module Imm_Gen #(
    parameter WIDTH       = 32,
    parameter INSTR_WIDTH = 32
    )(
    input  wire [INSTR_WIDTH-1:0] Instr_RV32IM,
    input  wire [2:0]             ImmediateSrc,
    output reg  [WIDTH-1:0]       Immediate
    );

    reg [INSTR_WIDTH-1:0] ImmGen_unused;   //to store unused Instr_RV32IM bits and avoid linter violations
                                           //hardcoding the unused bit positions in Instr_RV32IM for simplicity
  
    //extracting immediates, combining and sign extending to 32 bits
    //Hardcoded instruction decoding followed since this is standard.
    always @(*) begin
        case (ImmediateSrc)
            `IMM_I: begin       //I-type arithmetic, logical instructions + LW & JALR
                Immediate     = {{(WIDTH-12){Instr_RV32IM[31]}}, Instr_RV32IM[31:20]};
                ImmGen_unused = {12'b0,Instr_RV32IM[19:0]}; 
            end

            `IMM_S: begin       //S-type instructions (SW)
                Immediate     = {{(WIDTH-12){Instr_RV32IM[31]}}, Instr_RV32IM[31:25], Instr_RV32IM[11:7]};
                ImmGen_unused = {12'b0,Instr_RV32IM[24:12], Instr_RV32IM[6:0]}; 
            end
            
            `IMM_B: begin       //B-type instructions (All)
                Immediate     = {{(WIDTH-12){Instr_RV32IM[31]}}, Instr_RV32IM[7], Instr_RV32IM[30:25], Instr_RV32IM[11:8], 1'b0};
                ImmGen_unused = {12'b0,Instr_RV32IM[24:12], Instr_RV32IM[6:0]};
            end
            
            `IMM_U: begin       //U-type instructions (LUI & AUIPC)
                Immediate     = {Instr_RV32IM[31:12], {(WIDTH-20){1'b0}}};
                ImmGen_unused = {20'b0,Instr_RV32IM[11:0]};
            end
            
            `IMM_J: begin       //J-type instructions (JAL only)
                Immediate     = {{(WIDTH-20){Instr_RV32IM[31]}}, Instr_RV32IM[19:12], Instr_RV32IM[20], Instr_RV32IM[30:21], 1'b0};
                ImmGen_unused = {20'b0,Instr_RV32IM[11:0]};
            end
            
            `IMM_NONE: begin     //R-Type or Invalid ImmediateSrc, default Imm 0
                Immediate     = {WIDTH{1'b0}};
                ImmGen_unused = {32'b0};

                
            end
            
            default:   begin     //default fallback, default Imm 0
                Immediate =     {WIDTH{1'b0}};
                ImmGen_unused = {32'b0};
            end
        endcase

    end
       
endmodule
