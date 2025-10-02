/*
* Module: PC_Incrementer_TB.v
* Description: Testbench for PC_Incrementer.v
*              Verifies correct +4 increments for a variety of PC values.
* Author: Aashrith S Narayn
* Date: 16/09/2025
*/

`timescale 1ns / 1ps

module PC_Incrementer_TB();

    parameter PC_WIDTH = 32;
    parameter PC_STEP  = 4;

    reg     [PC_WIDTH-1:0] PC;
    wire    [PC_WIDTH-1:0] PC_Plus_4;

    integer                i;
    reg                    Result_Check;

    //uut
    PC_Incrementer #(
        .PC_WIDTH(PC_WIDTH),
        .PC_STEP (PC_STEP)
    ) 
    CPU_PCAdd (
        .PC(PC),
        .PC_Plus_4(PC_Plus_4)
    );


    //Task to apply stimulus and check output
    task PC_Inc_Test;
        input          [PC_WIDTH-1:0] PC_in;
        input          [PC_WIDTH-1:0] PC_expected;
        input  integer                num;
        output                        result;
        output integer                num_plus;
        
        begin
            PC = PC_in;
            
            #5;                 //allow combinational logic to settle
            num_plus = num + 1;

            if (PC_Plus_4 !== PC_expected) begin
                $display("Test %0d  ERROR: PC=%h | Got PC_Plus_4=%h | Expected=%h",
                          num, PC_in, PC_Plus_4, PC_expected);
                result = 0;
            end else begin
                $display("Test %0d  PASS : PC=%h -> PC_Plus_4=%h",
                          num, PC_in, PC_Plus_4);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        PC = 32'h00000000;
        
        #20;
        
        $display("\n--- PC_Incrementer Tests ---");

        //Basic increment from zero
        PC_Inc_Test(32'h00000000, 32'h00000004, i, Result_Check, i);    //1

        //Increment from non-zero
        PC_Inc_Test(32'h00000008, 32'h0000000C, i, Result_Check, i);    //2

        //Increment from large value
        PC_Inc_Test(32'h7FFFFFFC, 32'h80000000, i, Result_Check, i);    //3

        //Increment from max value (wraparound behavior)
        PC_Inc_Test(32'hFFFFFFFC, 32'h00000000, i, Result_Check, i);    //4

        //Random patterns
        PC_Inc_Test(32'h12345678, 32'h1234567C, i, Result_Check, i);    //5
        PC_Inc_Test(32'hABCDEF00, 32'hABCDEF04, i, Result_Check, i);    //6
        
        #10;
        
        $display("--- End of PC_Incrementer Tests ---\n");
        $finish;
    end

endmodule
