/*
* Module: Program_Counter.v
* Description: Holds the address of the current instruction and updates it on
*              each clock cycle if PCWrite is asserted. Supports synchronous reset.
* Author: Aashrith S Narayn
* Date: 04/07/2025
*/

`timescale 1ns / 1ps

//(* dont_touch = "true" *)
module Program_Counter #(
    parameter PC_WIDTH     = 32,
    parameter PC_STEP      = 4
    )(
    input  wire [PC_WIDTH-1:0] PC_Next,
    input  wire                CPU_clk,
    input  wire                CPU_rst_n, 
    input  wire                PCWrite,
    output reg  [PC_WIDTH-1:0] PC    
    );
    
    localparam RESET_PC = 32'hFFFFFFFC;     //PC Reset value before clock update
    
    always @(posedge CPU_clk or negedge CPU_rst_n) begin
       if (!CPU_rst_n) begin
           PC <= RESET_PC;      //ensures that on next PC update, PC wraps to 0 
       end else begin
           PC <= (PCWrite) ? PC_Next : PC;
       end
    end
    
endmodule
