/*
* Module: Instruction_Memory.v
* Description: Stores and serves 32-bit instructions to the CPU based on the current 
*              Program Counter (PC). Supports synchronous fetch from an initialized 
*              instruction memory ROM. Read-only in RV32IM single-cycle architecture.
* Author: Aashrith S Narayn
* Date: 06/07/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//(* dont_touch = "true" *)
module Instruction_Memory #(
    parameter PC_WIDTH    = 32,
    parameter INSTR_WIDTH = 32,
    parameter IMEM_DEPTH  = 256
    )(
    input  wire [PC_WIDTH-1:0]    PC,            //we use PC[9:2] to navigate 
    output reg  [INSTR_WIDTH-1:0] Instr_RV32IM  
    );
    
    localparam BYTE_RANGE = $clog2(4*IMEM_DEPTH);
    
    //Instruction Memory Array - byte wise mem access
    (* ram_style = "block" *)    
    reg [INSTR_WIDTH-1:0] InstrMem [0:IMEM_DEPTH-1];
    
    //Instruction Read logic (Combinational)
    always @(*) begin
        Instr_RV32IM = InstrMem[PC[BYTE_RANGE-1:2]];
    end
    
    
    
    //WARNING
    //the following block is not needed as part of Official design
    //Prevent optimization
    /*
    always @(posedge PC[0]) begin
        InstrMem[0] <= InstrMem[0]; // Dummy driver to prevent optimization
    end
    */
    
    wire [PC_WIDTH-BYTE_RANGE-1:0] IMEM_unused_bits = |{PC[PC_WIDTH-1:BYTE_RANGE], PC[1:0]};    //to avoid linter violations
    
    //pragma synthesis off
    
    //Initialising InstrMem with a set of assembly codes during simulation (preload)
    initial begin
        $readmemh(`IMEM_HEX_PROGRAM, InstrMem);
        //$display("IMEM[0]=%h IMEM[1]=%h", InstrMem[0], InstrMem[1]);
    end
    
    /*
    initial begin
        //waiting for simulation to end
        #(`SIM_TIME);
        
        //instruction memory dump
        $writememh(`IMEM_HEX_DUMP, CPU_DataPath.CPU_IMEM.InstrMem);
    end  
    */
    
    //pragma synthesis on

endmodule
