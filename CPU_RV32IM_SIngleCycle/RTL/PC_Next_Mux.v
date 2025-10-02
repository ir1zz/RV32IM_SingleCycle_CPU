/*
* Module: PC_Next_Mux.v
* Description: Selects next Program Counter value based on jump/branch conditions 
*              and control signals. Supports JAL, JALR, Branch and PC+4 updates.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps

//(* dont_touch = "true" *)
module PC_Next_Mux #(
    parameter PC_WIDTH = 32,
    parameter WIDTH    = 32
    )(
    input  wire [PC_WIDTH-1:0] PC_Plus_4,
    input  wire [PC_WIDTH-1:0] BranchTarget,
    input  wire [WIDTH-1:0]    JumpTarget,
    input  wire [1:0]          PCSrc,
    output reg  [PC_WIDTH-1:0] PC_Next
    );
    
    always @(*) begin
    
        case (PCSrc)
            2'b00:   PC_Next = PC_Plus_4;
            2'b01:   PC_Next = BranchTarget;
            2'b10:   PC_Next = JumpTarget;
            default: PC_Next = PC_Plus_4;   //default fallback
            
        endcase
    
    end
    
endmodule
