/*
* Module: Branch_Target_Gen.v
* Description: Computes the branch target address by adding 
*              the already-aligned Immediate (from Imm_Gen) 
*              to the current PC.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps


//top level module for Branch Target Calculation
//(* dont_touch = "true" *)
module Branch_Target_Gen #(
    parameter WIDTH = 32,       //NOTE: PC_WIDTH AND WIDTH SHOULD BE THE SAME
    parameter PC_WIDTH = 32 
    )(
    input  wire [WIDTH-1:0]    Immediate,
    input  wire [PC_WIDTH-1:0] PC,
    output reg  [PC_WIDTH-1:0] BranchTarget
    );
    
    always @(*) begin
        BranchTarget = PC + Immediate;
    end
    
endmodule
