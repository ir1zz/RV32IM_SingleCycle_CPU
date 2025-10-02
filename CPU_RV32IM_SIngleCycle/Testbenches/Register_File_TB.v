/*
* Module: Register_File_TB.v
* Description: Testbench for Register_File.v
*              Verifies reset, x0 hardwire, read/write correctness,
*              dual-port independence, and read-during-write behaviour.
* Author: Aashrith S Narayn
* Date: 18/09/2025
*/

`timescale 1ns / 1ps

module Register_File_TB;

    parameter WIDTH      = 32;
    parameter REG_COUNT  = 32;
    parameter ADDR_WIDTH = $clog2(REG_COUNT);

    reg                      CPU_clk;
    reg                      CPU_rst_n;
    reg                      RegWrite;
    reg     [ADDR_WIDTH-1:0] Rs1Addr, Rs2Addr, RdAddr;
    reg     [WIDTH-1:0]      WriteData;
    
    wire    [WIDTH-1:0]      Rs1Data, Rs2Data;

    integer                  i,j;
    reg                      Result_Check;

    //uut
    Register_File #(
        .WIDTH(WIDTH),
        .REG_COUNT(REG_COUNT)
    ) 
    CPU_RegFile (
        .CPU_clk(CPU_clk),
        .CPU_rst_n(CPU_rst_n),
        .RegWrite(RegWrite),
        .Rs1Addr(Rs1Addr),
        .Rs2Addr(Rs2Addr),
        .RdAddr(RdAddr),
        .WriteData(WriteData),
        .Rs1Data(Rs1Data),
        .Rs2Data(Rs2Data)
    );

    //Clock logic
    initial begin
        CPU_clk = 0;
        forever #5 CPU_clk = ~CPU_clk;   //100 MHz (synthesis supported)
    end


    //Task to apply stimulus and check output
    task Reg_Test;
        input [ADDR_WIDTH-1:0] addr;
        input [WIDTH-1:0]      expRs1Data;
        input integer          num;
        output                 result;
        output integer         num_plus;
        
        begin
            Rs1Addr = addr;
            #5;             //allow read (combinational logic) to settle
            num_plus = num + 1;
            if (Rs1Data !== expRs1Data) begin
                $display("Test %0d  ERROR:", num_plus);
                $display("  Read Addr -> %0d", addr);
                $display("  Got      -> %h", Rs1Data);
                $display("  Expected -> %h", expRs1Data);
                result = 0;
            end else begin
                $display("Test %0d  PASS : Addr=%0d Data=%h", num_plus, addr, Rs1Data);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0; j = 0;
        RegWrite  = 0;
        Rs1Addr   = 0;
        Rs2Addr   = 0;
        RdAddr    = 0;
        WriteData = 0;

        $display("\n--- Register_File Tests ---");

        //Reset check                                       //1
        CPU_rst_n = 0;
        @(posedge CPU_clk);
        CPU_rst_n = 1;
        @(posedge CPU_clk);
        $display("Checking reset values...");
        for (j = 0; j < REG_COUNT; j = j + 1)
            Reg_Test(j, 32'h0000_0000, i, Result_Check, i);


        //Single write & read                               //2
        $display("\nSingle write/read test...");
        RdAddr    = 5;
        WriteData = 32'hDEAD_BEEF;
        RegWrite  = 1;
        @(posedge CPU_clk);
        RegWrite  = 0;
        Reg_Test(5, 32'hDEAD_BEEF, i, Result_Check, i);


        //x0 hardwire test                                  //3
        $display("\nHardwire x0 test...");
        RdAddr    = 0;
        WriteData = 32'hFFFF_FFFF;
        RegWrite  = 1;
        @(posedge CPU_clk);
        RegWrite  = 0;
        Reg_Test(0, 32'h0000_0000, i, Result_Check, i);


        //Full sweep write/read                             //4
        $display("\nFull Register sweep...");
        for (j = 1; j < REG_COUNT; j = j + 1) begin
            @(negedge CPU_clk);         //aligning signals before each iteration
            RdAddr    = j;
            WriteData = 32'h1111_0000 + j;
            RegWrite  = 1;
            @(posedge CPU_clk); 
        end
        
        @(posedge CPU_clk);
        RegWrite = 0;
        for (j = 1; j < REG_COUNT; j = j + 1)
            Reg_Test(j, 32'h1111_0000 + j, i, Result_Check, i);


        //Dual-port independence                            //5
        $display("\nDual-port read test...");
        Rs1Addr = 5;   //already written above
        Rs2Addr = 10;
        #1;
        if ((Rs1Data === (32'h1111_0000 + 5)) &&
            (Rs2Data === (32'h1111_0000 + 10)))
            $display("Dual-port PASS: Rs1=%h Rs2=%h", Rs1Data, Rs2Data);
        else
            $display("Dual-port ERROR: Rs1=%h Rs2=%h", Rs1Data, Rs2Data);


        //Read-during-write hazard (expect old value)       //6
        $display("\nRead-during-write hazard test...");
        @(negedge CPU_clk);
        Rs1Addr   = 7;
        RdAddr    = 7;
        WriteData = 32'hAAAA_5555;
        RegWrite  = 1;
        #1; //before clock edge
        $display("Pre-edge read (should be OLD) -> %h", Rs1Data);
        @(posedge CPU_clk);         
        #1;         //allowing the Data in reg 07 to be updated in RegArray after write
        RegWrite  = 0;
        $display("Post-edge read (should be NEW) -> %h", Rs1Data);


        //Sequential overwrite                              //7
        @(posedge CPU_clk);
        $display("\nSequential overwrite test...");
        RdAddr    = 7;
        WriteData = 32'hBBBB_CCCC;
        RegWrite  = 1;
        @(posedge CPU_clk);
        RegWrite  = 0;
        Reg_Test(7, 32'hBBBB_CCCC, i, Result_Check, i);

        #20;
        
        $display("--- End of Register_File Tests ---\n");


        $finish;
    end

endmodule
