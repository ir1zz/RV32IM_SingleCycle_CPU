/*
* Module: WriteBack_Mux.v
* Description: Selects write-back data for the register file based on MemToReg,
*              with full support for RV32IM ISA.
* Author: Aashrith S Narayn
* Date: 06/07/2025
*/

`timescale 1ns / 1ps

//(* dont_touch = "true" *)
module WriteBack_Mux #(
    parameter WIDTH    = 32,
    parameter PC_WIDTH = 32
    )(
    input  wire [WIDTH-1:0]     ALUResult,
    input  wire [WIDTH-1:0]     ReadData,
    input  wire [PC_WIDTH-1:0]  PC_Plus_4,
    input  wire [1:0]           MemToReg,
    output reg  [WIDTH-1:0]     WriteData
    );
    
    always @(*) begin
    
       case (MemToReg)
           2'b00:   WriteData = ALUResult;
           2'b01:   WriteData = ReadData;
           2'b10:   WriteData = PC_Plus_4;
           default: WriteData = ALUResult;  //default fallback
           
       endcase 
       
    end
    
endmodule
