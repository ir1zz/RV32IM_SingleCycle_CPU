/*
* Module: ALUSelect_Mux_TB.v
* Description: Testbench for ALUSelect_Mux.v
*              Verifies correct output selection between RV32I and RV32M ALU
*              based on MDSel control signal.
* Author: Aashrith S Narayn
* Date: 17/09/2025
*/

`timescale 1ns / 1ps

module ALUSelect_Mux_TB;                //SIME_TIME = 100ns

    parameter WIDTH = 32;

    reg     [WIDTH-1:0] ALUResult_I, ALUResult_M;
    reg                 Zero_I, Zero_M;
    reg                 MDSel;

    wire    [WIDTH-1:0] ALUResult;
    wire                Zero;

    integer             i;
    reg                 Result_Check;

    //uut
    ALUSelect_Mux #(.WIDTH(WIDTH)) 
    CPU_ALUSelMux (
        .ALUResult_I(ALUResult_I),
        .ALUResult_M(ALUResult_M),
        .Zero_I(Zero_I),
        .Zero_M(Zero_M),
        .MDSel(MDSel),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );


    //Task to apply stimulus and check output
    task ALU_Select_Test;
        input          [WIDTH-1:0] ALU_I_in;
        input          [WIDTH-1:0] ALU_M_in;
        input                      Zero_I_in;
        input                      Zero_M_in;
        input                      MDSel_in;
        input          [WIDTH-1:0] ALUResult_expected;
        input                      Zero_expected;
        input  integer             num;
        output                     result;
        output integer             num_plus;
        
        begin
            ALUResult_I = ALU_I_in;
            ALUResult_M = ALU_M_in;
            Zero_I      = Zero_I_in;
            Zero_M      = Zero_M_in;
            MDSel       = MDSel_in;

            #5;                 //allow combinational logic to settle
            
            num_plus = num + 1;

            if ((ALUResult !== ALUResult_expected) || (Zero !== Zero_expected)) begin
                $display("Test %0d  ERROR:", num_plus);
                $display("  Inputs  -> ALU_I=%h  ALU_M=%h  Zero_I=%b Zero_M=%b  MDSel=%b",
                          ALU_I_in, ALU_M_in, Zero_I_in, Zero_M_in, MDSel_in);
                $display("  Got     -> ALUResult=%h  Zero=%b", ALUResult, Zero);
                $display("  Expected-> ALUResult=%h  Zero=%b", ALUResult_expected, Zero_expected);
                result = 0;
            end else begin
                $display("Test %0d  PASS : ALUResult=%h  Zero=%b", num_plus, ALUResult, Zero);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        ALUResult_I = 32'h00000000;
        ALUResult_M = 32'h00000000;
        Zero_I = 1;
        Zero_M = 1;                     //ALU 0 outputs cause Zero signals to assert
        MDSel  = 0;
        
        #20;
        
        $display("\n--- ALUSelect_Mux Tests ---");

        //Select RV32I (MDSel=0)
        ALU_Select_Test(32'hAAAA_BBBB, 32'h0000_0000,
                        1'b0, 1'b1,
                        1'b0,
                        32'hAAAA_BBBB, 1'b0,
                        i, Result_Check, i);                //1

        //Select RV32M (MDSel=1)
        ALU_Select_Test(32'h0000_0000, 32'hCAFEBABE,
                        1'b1, 1'b0,
                        1'b1,
                        32'hCAFEBABE, 1'b0,
                        i, Result_Check, i);                //2

        //Both ALUs same result, choose RV32I               //normally wouldn't occur as MDSel deassertion would cause RV32M ALU to output 0
        ALU_Select_Test(32'hFACE_CAFE, 32'hFACE_CAFE,
                        1'b0, 1'b0,
                        1'b0,
                        32'hFACE_CAFE, 1'b0,
                        i, Result_Check, i);                //3

        //Both ALUs same result, choose RV32M               //MDSel assertion would cause RV32I ALU to output 0
        ALU_Select_Test(32'h0000_0000, 32'h0000_0000,
                        1'b1, 1'b1,
                        1'b1,
                        32'h0000_0000, 1'b1,
                        i, Result_Check, i);                 //4

        //Random pattern, MDSel=0
        ALU_Select_Test(32'h1234_5678, 32'h8765_4321,
                        1'b0, 1'b0,
                        1'b0,
                        32'h1234_5678, 1'b0,
                        i, Result_Check, i);                 //5

        //Random pattern, MDSel=1
        ALU_Select_Test(32'h89AB_CDEF, 32'hFEDC_BA98,
                        1'b0, 1'b0,
                        1'b1,
                        32'hFEDC_BA98, 1'b0,
                        i, Result_Check, i);                 //6

        #10;

        $display("--- End of ALUSelect_Mux Tests ---\n");
        $finish;
    end

endmodule
