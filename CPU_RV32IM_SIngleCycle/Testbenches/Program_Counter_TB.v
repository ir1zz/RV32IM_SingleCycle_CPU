/*
* Module: Program_Counter_TB.v
* Description: Testbench for Program_Counter.v
*              Verifies reset behaviour, PC write/hold, and next-PC updates.
* Author: Aashrith S Narayn
* Date: 16/09/2025
*/

`timescale 1ns / 1ps

module Program_Counter_TB();

    parameter PC_WIDTH = 32;
    parameter PC_STEP  = 4;

    //PC Reset value before clock update
    localparam [PC_WIDTH-1:0] RESET_PC = 32'hFFFFFFFC;

    reg     [PC_WIDTH-1:0] PC_Next;
    reg                    CPU_clk;
    reg                    CPU_rst_n;
    reg                    PCWrite;
    
    wire    [PC_WIDTH-1:0] PC;

    integer                i;
    reg                    Result_Check;

    //uut
    Program_Counter #(
        .PC_WIDTH(PC_WIDTH),
        .PC_STEP (PC_STEP)
    ) CPU_ProgCount (
        .PC_Next(PC_Next),
        .CPU_clk(CPU_clk),
        .CPU_rst_n(CPU_rst_n),
        .PCWrite(PCWrite),
        .PC(PC)
    );

    //clk logic
    initial begin
        CPU_clk = 0;
        forever #5 CPU_clk = ~CPU_clk;   //100 MHz (synthesis supported)
    end


    //Task to apply stimulus and check output
    task PC_Test;
        input          [PC_WIDTH-1:0] next_PC;
        input                         Wr_En;
        input                         rst_n;
        input          [PC_WIDTH-1:0] PC_expected;
        input  integer                num;
        output                        result;
        output integer                num_plus;
        
        begin
            PC_Next   = next_PC;
            PCWrite   = Wr_En;
            CPU_rst_n = rst_n;
            num_plus = num + 1;

            @(posedge CPU_clk); #1;     //sample after clock edge

            if (PC !== PC_expected) begin
                $display("Test %0d  ERROR: PC_Next=%h PCWrite=%b rst_n=%b | Got PC=%h | Expected PC=%h",
                          num, next_PC, Wr_En, rst_n, PC, PC_expected);
                result = 0;
            end else begin
                $display("Test %0d  PASS : PC=%h", num, PC);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        PC_Next = 0;
        PCWrite = 0;
        CPU_rst_n = 1;   //Initial reset (active low)
        
        #10;

        $display("\n--- Program Counter Tests ---");
        CPU_rst_n = 0;   // assert reset
        @(posedge CPU_clk);
        PC_Test(0, 0, 0, RESET_PC, i, Result_Check, i);                     //1

        //Release reset → next cycle PC should update to 0 if PCWrite=1
        CPU_rst_n = 1;
        PC_Next   = 32'h00000000;
        PCWrite   = 1;
        @(posedge CPU_clk);
        PC_Test(32'h00000000, 1, 1, 32'h00000000, i, Result_Check, i);      //2

        //Hold PC (PCWrite=0)
        PC_Next = 32'h00000004;
        PCWrite = 0;
        @(posedge CPU_clk);
        PC_Test(32'h00000004, 0, 1, 32'h00000000, i, Result_Check, i);      //3

        //Update PC
        PC_Next = 32'h00000008;
        PCWrite = 1;
        @(posedge CPU_clk);
        PC_Test(32'h00000008, 1, 1, 32'h00000008, i, Result_Check, i);      //4

        //Multiple increments
        repeat (3) begin
            i = i + 1;
            PC_Next = PC + PC_STEP;
            @(posedge CPU_clk);
            PC_Test(PC_Next, 1, 1, PC_Next, i, Result_Check, i);            //5-7
        end

        //Asynchronous reset while running
        CPU_rst_n = 0;
        @(posedge CPU_clk);
        PC_Test(PC_Next, 1, 0, RESET_PC, i, Result_Check, i);               //8
        
        #10;
        
        $display("--- End of Program Counter Tests ---\n");
        $finish;
    end

endmodule