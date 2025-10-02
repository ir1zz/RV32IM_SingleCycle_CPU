/*
* Module: Target_Controller_TB.v
* Description: Testbench for Target_Controller.v
*              Verifies correct branch/jump decision logic
* Author: Aashrith S Narayn
* Date: 18/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module Target_Controller_TB;

    reg     [3:0] TargetSel;
    reg           Zero;
    reg     [1:0] PCSrc;

    integer       i;
    reg           Result_Check;

    //uut
    Target_Controller CPU_TrCtrl (
        .TargetSel(TargetSel),
        .Zero(Zero),
        .PCSrc(PCSrc)
    );


    //Task to apply stimulus and check result
    task Target_Test;
        input          [3:0] TargetSel_in;
        input                Zero_in;
        input          [1:0] ExpPCSrc;
        input  integer       num;
        output               result;
        output integer       num_plus;

        begin
            TargetSel = TargetSel_in;
            Zero      = Zero_in;
            #5;               //allow combinational logic to settle

            num_plus = num + 1;

            if (PCSrc !== ExpPCSrc) begin
                $display("Test %0d  ERROR:", num_plus);
                $display("  Inputs  -> TargetSel=%b  Zero=%b", TargetSel_in, Zero_in);
                $display("  Got     -> PCSrc=%b", PCSrc);
                $display("  Expected-> PCSrc=%b", ExpPCSrc);
                result = 0;
            end else begin
                $display("Test %0d  PASS : PCSrc=%b", num_plus, PCSrc);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        TargetSel = 0;
        Zero      = 0;

        #20;
        $display("\n--- Target_Controller Tests ---");

        //BEQ: branch if Zero=1
        Target_Test(`BR_EQ, 1'b0, 2'b00, i, Result_Check, i);           //1
        Target_Test(`BR_EQ, 1'b1, 2'b01, i, Result_Check, i);           //2

        //BNE: branch if Zero=0
        Target_Test(`BR_NE, 1'b0, 2'b01, i, Result_Check, i);           //3
        Target_Test(`BR_NE, 1'b1, 2'b00, i, Result_Check, i);           //4

        //BLT: branch if !Zero (placeholder for < condition)
        Target_Test(`BR_LT, 1'b0, 2'b01, i, Result_Check, i);           //5
        Target_Test(`BR_LT, 1'b1, 2'b00, i, Result_Check, i);           //6

        //BGE: branch if Zero (placeholder for >= condition)
        Target_Test(`BR_GE, 1'b0, 2'b00, i, Result_Check, i);           //7
        Target_Test(`BR_GE, 1'b1, 2'b01, i, Result_Check, i);           //8

        //BLTU: unsigned <
        Target_Test(`BR_LTU,1'b0, 2'b01, i, Result_Check, i);           //9
        Target_Test(`BR_LTU,1'b1, 2'b00, i, Result_Check, i);           //10

        //BGEU: unsigned >=
        Target_Test(`BR_GEU,1'b0, 2'b00, i, Result_Check, i);           //11
        Target_Test(`BR_GEU,1'b1, 2'b01, i, Result_Check, i);           //12

        //JAL: unconditional jump
        Target_Test(`UJ_AL, 1'b0, 2'b10, i, Result_Check, i);           //13
        Target_Test(`UJ_AL, 1'b1, 2'b10, i, Result_Check, i);           //14

        //JALR: unconditional jump
        Target_Test(`UJ_ALR,1'b0, 2'b10, i, Result_Check, i);           //15
        Target_Test(`UJ_ALR,1'b1, 2'b10, i, Result_Check, i);           //16

        //TR_NOP: no branch/jump
        Target_Test(`TR_NOP,1'b0, 2'b00, i, Result_Check, i);           //17
        Target_Test(`TR_NOP,1'b1, 2'b00, i, Result_Check, i);           //18

        //Default: invalid TargetSel
        Target_Test(4'b1111,1'b0, 2'b00, i, Result_Check, i);           //19

        #10;
        
        $display("--- End of Target_Controller Tests ---\n");
        $finish;
    end

endmodule
