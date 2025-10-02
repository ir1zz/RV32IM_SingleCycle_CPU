/*
* Module: Immediate_Gen_TB.v
* Description: Testbench for Immediate_Gen.v
*              Verifies correct immediate decoding and sign/zero-extension
*              for every RV32IM instruction format in a single-cycle CPU.
* Author: Aashrith S Narayn
* Date: 16/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module Immediate_Gen_TB();

    parameter WIDTH       = 32;
    parameter INSTR_WIDTH = 32;

    reg     [INSTR_WIDTH-1:0] Instr_RV32IM;
    reg     [2:0]             ImmediateSrc;
    
    wire    [WIDTH-1:0]       Immediate;

    integer                   i;
    reg                       Result_Check;

    //uut
    Imm_Gen #(
        .WIDTH(WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH)
    ) CPU_ImmGen (
        .Instr_RV32IM(Instr_RV32IM),
        .ImmediateSrc(ImmediateSrc),
        .Immediate(Immediate)
    );


    //Task to apply stimulus and check output
    task Imm_Test;
        input          [INSTR_WIDTH-1:0] Instr;
        input          [2:0]             ImmSrc;
        input          [WIDTH-1:0]       Imm_expected;
        input  integer                   num;
        output                           result;
        output integer                   num_plus;
        
        begin
            Instr_RV32IM = Instr;
            ImmediateSrc = ImmSrc;
            
            #5;                     //allowing combinational logic to settle
            num_plus = num + 1;

            if (Immediate !== Imm_expected) begin
                $display("Test %0d  ERROR: Src=%b | Got Imm=%h | Expected=%h",
                          num, ImmSrc, Immediate, Imm_expected);
                result = 0;
            end else begin
                $display("Test %0d  PASS : Src=%b Imm=%h",
                          num, ImmSrc, Immediate);
                result = 1;
            end
        end
    endtask


    //Stimulus
    initial begin
        i = 0;
        Instr_RV32IM = 32'h00000000;
        ImmediateSrc = 3'b000;
        
        #20;
        
        $display("\n--- Immediate Generator Tests ---");

        //I-type (arithmetic/LW/JALR etc)
        //Positive immediate
        Imm_Test(32'b000000000101_00001_000_00010_0010011, `IMM_I, 32'h00000005, i, Result_Check, i);       //ADDI x2, x1, 5
        // Negative immediate (sign extend)
        Imm_Test(32'b111111111011_00001_100_00010_0010011, `IMM_I, 32'hFFFFFFFB, i, Result_Check, i);       //XORI x2, x1,-5


        //S-type (SW)
        //Store word with positive offset
        Imm_Test(32'b0000000_00101_00001_010_00010_0100011, `IMM_S, 32'h00000002, i, Result_Check, i);      //SW x1, x5, 2
        //Negative offset
        Imm_Test(32'b1111111_11011_00001_010_00010_0100011, `IMM_S, 32'hFFFFFFE2, i, Result_Check, i);      //SW x1, x27, -30 


        //B-type 
        //Positive branch (imm=+8 -> shifted <<1 gives 0x8)
        Imm_Test(32'b0_000000_00010_00001_000_0001_0_1100011, `IMM_B, 32'h00000002, i, Result_Check, i);    //BEQ x1, x2, 2
        //Negative branch (imm=-8)
        Imm_Test(32'b1_111111_11110_00001_101_0001_0_1100011, `IMM_B, 32'hFFFFF7E2, i, Result_Check, i);    //BGE x1, x30, -2078


        //U-type (LUI/AUIPC)
        //Upper immediate 0x12345000
        Imm_Test(32'b00010010001101000101_00010_0110111,    `IMM_U, 32'h12345000, i, Result_Check, i);      //LUI x2, 12345
        //Negative upper (sign extend)
        Imm_Test(32'b10000000000000000000_00011_0010111,    `IMM_U, 32'h80000000, i, Result_Check, i);      //AUIPC x3, 80000


        //J-type (JAL)
        //Positive jump (imm=+20 -> shifted <<1 => 0x14)
        Imm_Test(32'b0_0000000101_0_00000000_00100_1101111,    `IMM_J, 32'h0000000A, i, Result_Check, i);   //JAL x4, A
        //Negative jump (imm=-20)
        Imm_Test(32'b1_1111111011_0_00000000_00010_1101111,    `IMM_J, 32'hFFF007F6, i, Result_Check, i);   //JAL x2, negative of 007F6


        //NONE/R-type
        Imm_Test(32'b0000000_00010_00001_000_00010_0110011, `IMM_NONE, 32'h00000000, i, Result_Check, i);   //ADD x2, x1, x2
        
        #10;
        
        $display("--- End of Immediate Generator Tests ---\n");
        $finish;
    end

endmodule
