/*
* Module: PC_Adder.v
* Description: Computes the address of the next sequential instruction 
*              by adding 4 to the current Program Counter (PC).
* Author: Aashrith S Narayn
* Date: 04/07/2025
*/

`timescale 1ns / 1ps

//(* dont_touch = "true" *)
module PC_Incrementer #(
    parameter PC_WIDTH = 32,
    parameter PC_STEP  = 4
    )(
    input  wire [PC_WIDTH-1:0] PC,
    output reg  [PC_WIDTH-1:0] PC_Plus_4
    );
    
    always @(*) begin
        PC_Plus_4 = PC + {{(PC_WIDTH-3){1'b0}}, PC_STEP};    //incrementing PC with step size
    end
    
endmodule
