/*
* Module: Instruction_Memory_tb.v
* Descrition: Testbench for Instruction_Memory.v
*             Corner-case verification of IMEM  with a Golden memory reference.
*             Memory preload is used to test the internal RAM block.
* Author: Aashrith S Narayn
* Date: 22/09/2025
*/

`timescale 1ns/1ps
`include "CPU_Control_Codes_TB.vh"   //for `IMEM_HEX_PROGRAM

module Instruction_Memory_TB;

    parameter PC_WIDTH    = 32;
    parameter INSTR_WIDTH = 32;
    parameter IMEM_DEPTH  = 16;                     //using a small depth for test purposes
    
    localparam BYTE_RANGE  = $clog2(4*IMEM_DEPTH);

    reg     [PC_WIDTH-1:0]    PC;
    
    wire    [INSTR_WIDTH-1:0] Instr_RV32IM;

    //Reference Model Array
    reg     [INSTR_WIDTH-1:0] Golden_Mem [0:IMEM_DEPTH-1];
    reg                       Result_Check;        
    integer                   i;

    Instruction_Memory #(
        .PC_WIDTH(PC_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH),
        .IMEM_DEPTH (IMEM_DEPTH)
    ) 
    CPU_IMEM (
        .PC(PC),
        .Instr_RV32IM(Instr_RV32IM)
    );
    
    
    //Task to compare UUT output with reference model
    task IMEM_Test;
        input          [PC_WIDTH-1:0]    pc_val;        
        input          [INSTR_WIDTH-1:0] expInstr;
        input  integer                   num;
        output                           result;
        output integer                   num_plus;
        
        begin
            expInstr = Golden_Mem[pc_val[BYTE_RANGE-1:2]];
            
            #5;                 //allowing combinational logic to settle (IMEM read combinational)
            num_plus = num + 1;
                        
            if (Instr_RV32IM !== expInstr) begin
                $display("ERROR: PC=%h  Got=%h  Exp=%h", pc_val, Instr_RV32IM, expInstr);
                result = 0;
            end else begin
                $display("PASS : PC=%h  Instr=%h", pc_val, Instr_RV32IM);
                result = 1;
            end
        end
        
    endtask
    

//Stimulus
initial begin
    PC = 0;
    i  = 0;  

    $display("=== Instruction_Memory Corner-Case Test ===");
    $readmemh(`IMEM_HEX_PROGRAM, Golden_Mem);       //preloading golden reference array

    //Sequential read of entire memory                          //1
    $display("\n-- Full sweep --");
    repeat (IMEM_DEPTH) begin : FULL_SWEEP
        IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);
        PC = PC + 4;
    end

    //Misaligned addresses (lower bits ignored)                 //2
    $display("\n-- Misalignment test --");
    PC = 8'h04 + 1; IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);
    PC = 8'h08 + 2; IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);
    PC = 8'h0C + 3; IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);

    //Upper-bit masking (beyond BYTE_RANGE)                     //3
    $display("\n-- Upper bits masking --");
    PC = {20'hABCDE, 12'h000}; IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);
    PC = {20'hFFFFF, 12'h00C}; IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);

    //Out-of-range access (expect X or dont-care)               //4
    $display("\n-- Out of range --");
    PC = (IMEM_DEPTH*4); IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);
    $display("PC=%h  DUT=%h (Expected: X, undefined, or NOP)", PC, Instr_RV32IM);

    //Randomised sweep                                          //5
    $display("\n-- Randomised --");
    repeat (10) begin
        PC = {$random} % (IMEM_DEPTH*4);
        IMEM_Test(PC, Golden_Mem[PC[BYTE_RANGE-1:2]], i, Result_Check, i);
    end

    $display("\n=== Test Completed ===");
    $finish;
end

endmodule
