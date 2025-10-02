/*
* Module: Jump_Target_Gen_TB.v
* Description: Testbench for Jump_Target_Gen.v
*              Verifies correct computation of JAL/JALR jump target
*              and default fall-through behaviour.
* Author: Aashrith S Narayn
* Date: 18/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module Jump_Target_Gen_TB;

    parameter WIDTH    = 32;
    parameter PC_WIDTH = 32;

    reg     [WIDTH-1:0]    ALUResult;
    reg     [3:0]          TargetSel;
    reg     [PC_WIDTH-1:0] PC_Plus_4;
    
    wire    [WIDTH-1:0]    JumpTarget;

    integer                i;
    reg                    Result_Check;

    //uut
    Jump_Target_Gen #(
        .WIDTH(WIDTH),
        .PC_WIDTH(PC_WIDTH)
    )
    CPU_UjTargetGen (
        .ALUResult(ALUResult),
        .TargetSel(TargetSel),
        .PC_Plus_4(PC_Plus_4),
        .JumpTarget(JumpTarget)
    );


    //Task to apply stimulus and check output
    task Jump_Target_Test;
        input          [WIDTH-1:0]    ALU_in;
        input          [3:0]          TargetSel_in;
        input          [PC_WIDTH-1:0] PC4_in;
        input          [WIDTH-1:0]    ExpTarget;
        input  integer                num;
        output                        result;
        output integer                num_plus;
        
    begin
        ALUResult  = ALU_in;
        TargetSel  = TargetSel_in;
        PC_Plus_4  = PC4_in;
        #5;                 //allow combinational logic to settle

        num_plus = num + 1;

        if (JumpTarget !== ExpTarget) begin
            $display("Test %0d  ERROR:", num_plus);
            $display("  Inputs  -> ALU_Result=%h  TargetSel=%b  PC+4=%h",
                      ALU_in, TargetSel_in, PC4_in);
            $display("  Got     -> JumpTarget=%h", JumpTarget);
            $display("  Expected-> JumpTarget=%h", ExpTarget);
            result = 0;
        end else begin
            $display("Test %0d  PASS : JumpTarget=%h", num_plus, JumpTarget);
            result = 1;
        end
    end
    
    endtask


    //Stimulus
    initial begin
        i = 0;
        ALUResult = 32'h0000_0000;
        TargetSel  = 4'h0;
        PC_Plus_4  = 32'h0000_0000;

        #20;
        $display("\n--- Jump_Target_Gen Tests ---");

        //NOTE: Since JAL calculates PC+Imm (20 bit) in the ALU, and JALR calculates Rs1 + Imm (12 bit)
        //The ALUResult signals can be any valid 32 bit value, hence our overflow and corner case testing

        //JAL normal target: ALUResult passthrough                          //1
        Jump_Target_Test(32'h0000_1000, `UJ_AL, 32'h0000_0004,
                         32'h0000_1000, i, Result_Check, i);

        //JAL with large positive address                                   //2
        Jump_Target_Test(32'h7FFF_FFFC, `UJ_AL, 32'h0000_0004,
                         32'h7FFF_FFFC, i, Result_Check, i);

        //JAL with wrap-around near 32-bit max                              //3
        Jump_Target_Test(32'hFFFF_FFF8, `UJ_AL, 32'h0000_0004,
                         32'hFFFF_FFF8, i, Result_Check, i);

        //JALR normal target: mask LSB to 0                                 //4
        Jump_Target_Test(32'h0000_1001, `UJ_ALR, 32'h0000_0004,
                         32'h0000_1000, i, Result_Check, i);

        //JALR already aligned (LSB already 0)                              //5
        Jump_Target_Test(32'h0000_1ABC, `UJ_ALR, 32'h0000_0004,
                         32'h0000_1ABC, i, Result_Check, i);

        //JALR with all 1s: mask only LSB                                   //6
        Jump_Target_Test(32'hFFFF_FFFF, `UJ_ALR, 32'h0000_0004,
                         32'hFFFF_FFFE, i, Result_Check, i);

        //JALR with odd -ve pattern (sign extension irrelevant)             //7
        Jump_Target_Test(32'h8000_0001, `UJ_ALR, 32'h0000_0004,
                         32'h8000_0000, i, Result_Check, i);

        //Default case (TargetSel invalid) should output PC+4               //8
        Jump_Target_Test(32'h1234_5678, 4'b1111, 32'h0000_0004,
                         32'h0000_0004, i, Result_Check, i);

        //Default case with high PC+4 value                                 //9
        Jump_Target_Test(32'hDEAD_BEEF, 4'b0000, 32'hFFFF_FFFC,
                         32'hFFFF_FFFC, i, Result_Check, i);

        //JALR with ALU_Result zero (force mask behaviour)                  //10
        Jump_Target_Test(32'h0000_0001, `UJ_ALR, 32'hABCD_1234,
                         32'h0000_0000, i, Result_Check, i);

        #10;
        $display("--- End of Jump_Target_Gen Tests ---\n");
        $finish;
    end

endmodule
