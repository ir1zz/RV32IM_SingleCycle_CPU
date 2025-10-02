/*
* Module: ALU_Input_Selector_TB.v
* Description: Testbench for ALU_Input_Selector.v
*              Verifies correct operand selection for all
*              combinations of ALUSrc1 and ALUSrc2 control signals.
* Author: Aashrith S Narayn
* Date: 17/09/2025
*/

`timescale 1ns / 1ps

module ALU_Input_Selector_TB;               //SIM TIME = 100ns

    parameter WIDTH    = 32;
    parameter PC_WIDTH = 32;

    reg     [WIDTH-1:0]    Rs1Data, Rs2Data;
    reg     [PC_WIDTH-1:0] PC;
    reg     [WIDTH-1:0]    Immediate;
    reg                    ALUSrc1, ALUSrc2;

    wire    [WIDTH-1:0]    Op1, Op2;

    integer                i;
    reg                    Result_Check;

    //uut
    ALU_Input_Selector #(
        .WIDTH(WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) 
    CPU_ALUInputSel (
        .Rs1Data(Rs1Data),
        .Rs2Data(Rs2Data),
        .PC(PC),
        .Immediate(Immediate),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .Op1(Op1),
        .Op2(Op2)
    );


    //Task to apply stimulus and check output
    task ALU_Input_Test;
        input          [WIDTH-1:0]    Rs1_in;
        input          [WIDTH-1:0]    Rs2_in;
        input          [PC_WIDTH-1:0] PC_in;
        input          [WIDTH-1:0]    Imm_in;
        input                         ALUSrc1_in;
        input                         ALUSrc2_in;
        input          [WIDTH-1:0]    Op1_expected;
        input          [WIDTH-1:0]    Op2_expected;
        input  integer                num;
        output                        result;
        output integer                num_plus;
        
        begin
            Rs1Data  = Rs1_in;
            Rs2Data  = Rs2_in;
            PC       = PC_in;
            Immediate= Imm_in;
            ALUSrc1  = ALUSrc1_in;
            ALUSrc2  = ALUSrc2_in;

            #5;                 //allow combinational logic to settle
            num_plus = num + 1;

            if ((Op1 !== Op1_expected) || (Op2 !== Op2_expected)) begin
                $display("Test %0d  ERROR:", num);
                $display("  Inputs  -> Rs1=%h  Rs2=%h  PC=%h  Imm=%h  ALUSrc1=%b ALUSrc2=%b",
                         Rs1_in, Rs2_in, PC_in, Imm_in, ALUSrc1_in, ALUSrc2_in);
                $display("  Got     -> Op1=%h  Op2=%h", Op1, Op2);
                $display("  Expected-> Op1=%h  Op2=%h", Op1_expected, Op2_expected);
                result = 0;
            end else begin
                $display("Test %0d  PASS : Op1=%h  Op2=%h", num, Op1, Op2);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        Rs1Data   = 32'h00000000;
        Rs2Data   = 32'h00000000;
        PC        = 32'h00000000;
        Immediate = 32'h00000000;
        ALUSrc1   = 0;
        ALUSrc2   = 0;
        
        #20;
        
        $display("\n--- ALU_Input_Selector Tests ---");

        //Both Op1 and Op2 from Registers
        ALU_Input_Test(32'hAAAA_BBBB, 32'h1111_2222,
                        32'h3333_4444, 32'h5555_6666,
                        1'b0, 1'b0,
                        32'hAAAA_BBBB, 32'h1111_2222,
                        i, Result_Check, i);                    //1

        //Op1 from PC, Op2 from Rs2
        ALU_Input_Test(32'h1234_5678, 32'h9ABC_DEF0,
                        32'hCAFEBABE, 32'h1111_1111,
                        1'b1, 1'b0,
                        32'hCAFEBABE, 32'h9ABC_DEF0,
                        i, Result_Check, i);                    //2

        //Op1 from Rs1, Op2 from Immediate
        ALU_Input_Test(32'h0BAD_BEEF, 32'hAAAA_AAAA,
                        32'hDEAD_BEEF, 32'hFACE_CAFE,
                        1'b0, 1'b1,
                        32'h0BAD_BEEF, 32'hFACE_CAFE,
                        i, Result_Check, i);                    //3

        //Op1 from PC, Op2 from Immediate
        ALU_Input_Test(32'h3333_3333, 32'h4444_4444,
                        32'h5555_5555, 32'h6666_6666,
                        1'b1, 1'b1,
                        32'h5555_5555, 32'h6666_6666,
                        i, Result_Check, i);                    //4
                        
        //Random
        ALU_Input_Test(32'h0000_0000, 32'hFFFF_FFFF,
                        32'hABCD_EF01, 32'h1357_9BDF,
                        1'b1, 1'b0,
                        32'hABCD_EF01, 32'hFFFF_FFFF,
                        i, Result_Check, i);                    //5
                        
        #10;

        $display("--- End of ALU_Input_Selector Tests ---\n");
        $finish;
    end

endmodule
