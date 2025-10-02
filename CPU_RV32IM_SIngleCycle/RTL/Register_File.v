/*
* Module: Register_File.v
* Description: Implements the general-purpose register file (x0-x31) of 
*              the RV32IM architecture. Supports dual-port read and 
*              single-port write functionality. 
*              Register x0 is hardwired to 0.
* Author: Aashrith S Narayn
* Date: 21/09/2025
*/

`timescale 1ns / 1ps

//(* dont_touch = "true" *)
module Register_File #(
    parameter WIDTH      = 32,
    parameter REG_COUNT  = 32
    )(
    input  wire                         CPU_clk,
    input  wire                         CPU_rst_n,
    input  wire                         RegWrite,
    input  wire [$clog2(REG_COUNT)-1:0] Rs1Addr, Rs2Addr,
    input  wire [$clog2(REG_COUNT)-1:0] RdAddr,
    input  wire [WIDTH-1:0]             WriteData,
    output reg  [WIDTH-1:0]             Rs1Data, Rs2Data
    );
    
    //RV32IM Register Array
    reg [WIDTH-1:0] RegArray [0:REG_COUNT-1];
    integer i;                                      //used for resetting RegArray
    
    localparam ADDR_WIDTH = $clog2(REG_COUNT); 
    localparam DATA_ZERO  = {WIDTH{1'b0}};
    localparam ADDR_ZERO  = {ADDR_WIDTH{1'b0}};
    
    //Read Logic (Combinational)
    always @(*) begin       
        Rs1Data = (Rs1Addr == ADDR_ZERO) ? DATA_ZERO : RegArray[Rs1Addr];    //Reading Rs1
        Rs2Data = (Rs2Addr == ADDR_ZERO) ? DATA_ZERO : RegArray[Rs2Addr];    //Reading Rs2
    end
    
    //Write Logic (Sequential)
    always @(posedge CPU_clk or negedge CPU_rst_n) begin
        if (!CPU_rst_n) begin
            RegArray[0] <= DATA_ZERO;              //explicit x0 harwiring to 0 in reset
            for (i=1; i<REG_COUNT; i=i+1) begin    //setting all register contents except x0 to 0 
                RegArray[i] <= DATA_ZERO;          //for robust boot and simulation considerations
            end 
        end else begin
            if (RegWrite && RdAddr != ADDR_ZERO) begin
                RegArray[RdAddr] <= WriteData;
            end
            RegArray[0] <= DATA_ZERO;              //explicit x0 harwiring to 0
        end
    end
    
endmodule
