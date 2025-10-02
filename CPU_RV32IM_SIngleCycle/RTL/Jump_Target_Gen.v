/*
* Module: Jump_Target_Gen.v
* Description: Computes the Jump target address for JALR by masking LSB
*              and passing JAL target address as is.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//(* dont_touch = "true" *)
module Jump_Target_Gen #(
    parameter WIDTH = 32,
    parameter PC_WIDTH = 32)
    (
    input wire [WIDTH-1:0]    ALUResult,
    input wire [3:0]          TargetSel,
    input wire [PC_WIDTH-1:0] PC_Plus_4,
    output reg [WIDTH-1:0]    JumpTarget
    );
    
    //0 and 1 notation for width-parametrized use
    localparam ZERO = {WIDTH{1'b0}};
    localparam ONE  = {{WIDTH-1{1'b0}}, 1'b1}; 
    
    always @(*) begin
        case(TargetSel)
        `UJ_AL:  JumpTarget = ALUResult;            //passing result for JAL
        `UJ_ALR: JumpTarget = ALUResult & ~ONE;     //masking LSB for JALR
        default: JumpTarget = PC_Plus_4;            //ensures that PC+4 operation occurs even if Target Controller selects JumpTarget
        endcase
    end
    
endmodule