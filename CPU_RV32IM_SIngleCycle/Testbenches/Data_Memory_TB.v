/*
* Module: Data_Memory_TB.v
* Description : Corner-case verification of Data_Memory.v
*               Covers reset, byte/half/word accesses, misalignment,
*               upper-bit masking and randomised accesses. 
* Author      : Aashrith S Narayn
* Date        : 24/09/2025
*/

`timescale 1ns/1ps
`include "CPU_Control_Codes_TB.vh"   

module Data_Memory_TB;              //SIM TIME = 1800ns

    parameter WIDTH      = 32;
    parameter DMEM_DEPTH = 64;      //small depth for test purposes
    
    localparam BYTE_RANGE = $clog2(4*DMEM_DEPTH);

    reg                 CPU_clk;
    reg                 CPU_rst_n;
    reg                 MemWrite;
    reg                 MemRead;
    reg     [2:0]       MemDataType;
    reg     [WIDTH-1:0] ALUResult_Addr;
    reg     [WIDTH-1:0] WriteData;
    wire    [WIDTH-1:0] ReadData;

    //Reference Model Array 
    reg     [WIDTH-1:0] Golden_Mem [0:DMEM_DEPTH-1];
    integer             i,j;
    reg                 Result_Check;

    //uut
    Data_Memory #(
        .WIDTH(WIDTH),
        .DMEM_DEPTH(DMEM_DEPTH)
    ) 
    CPU_DMEM (
        .CPU_clk(CPU_clk),
        .CPU_rst_n(CPU_rst_n),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MemDataType(MemDataType),
        .ALUResult_Addr(ALUResult_Addr),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );

    //clk logic
    initial begin
        CPU_clk = 0;
        forever #5 CPU_clk = ~CPU_clk;          //100 MHz (synthesis supported)
    end

    //Task to compare UUT output with reference model
    task DMEM_Test;
        input          [WIDTH-1:0] ALUAddr;
        input          [WIDTH-1:0] expReadData;
        input                      MemWrite_in;
        input                      MemRead_in;
        input          [2:0]       MemDataType_in;
        input  integer             num;
        output                     result;
        output integer             num_plus;
        
        begin
            ALUResult_Addr = ALUAddr;
            MemWrite       = MemWrite_in;
            MemRead        = MemRead_in;
            MemDataType    = MemDataType_in;
            
            #5;             //allow combinational read to settle
            
            num_plus = num + 1;
            if (ReadData !== expReadData) begin
                $display("ERROR[%0d]: Addr=%h  Got=%h  Exp=%h",
                          num, ALUAddr, ReadData, expReadData);
                result = 0;
            end else begin
                $display("PASS [%0d]: Addr=%h  Data=%h",
                          num, ALUAddr, ReadData);
                result = 1;
            end
        end
        
    endtask

    //Stimulus
    initial begin
        CPU_rst_n      = 1;
        MemWrite       = 0;
        MemRead        = 0;
        MemDataType    = 3'b111;
        ALUResult_Addr = 0;
        WriteData      = 0;
        i = 0; j = 0;
    
        $display("=== Data_Memory Corner-Case Test ===");
        $readmemh(`DMEM_HEX_BLOCK, Golden_Mem);
        
        
        //Golden memory preload readback                                    //1
        $display("\n-- Golden memory preload sweep --");
        for (j = 0; j < DMEM_DEPTH; j = j + 1) begin
            DMEM_Test(i*4, Golden_Mem[i],
                      1'b0, 1'b1, 3'b010, i, Result_Check, i);
        end
     
        //Word Write/Word Read                                              //2
        $display("\n-- Word Write/Read --");
        
        //write sequence - SW
        @(posedge CPU_clk);         //buffer half cycle for previous control signals to be refreshed
        WriteData = 32'hDEADBEEF;
        MemWrite  = 1;
        MemRead   = 0;
        MemDataType = 3'b010;    
        ALUResult_Addr = 8'h04;
        
        @(posedge CPU_clk);         //aligning for write operation on clk positive edge
        MemWrite  = 0;
        
        DMEM_Test(8'h04, 32'hDEADBEEF, 1'b0, 1'b1, 3'b010, i, Result_Check, i);
    
    
        //Byte Write / Byte Read (Sign-extended LB)                         //3
        $display("\n-- Byte Write/Read (LB) --");
        
        //write sequence - SB
        @(posedge CPU_clk);         //buffer half cycle for previous control signals to be refreshed (setup time guarantee)
        WriteData = 32'h000000AA;
        MemWrite  = 1;
        MemRead   = 0;
        MemDataType = 3'b000;       
        ALUResult_Addr = 8'h08;
        
        @(posedge CPU_clk);         //aligning for write operation on clk positive edge
        
        MemWrite = 0;
        DMEM_Test(8'h08, 32'hFFFFFFAA, 1'b0, 1'b1, 3'b000, i, Result_Check, i);
    
    
        //Unsigned Byte (LBU)                                               //4
        $display("\n-- Byte Write/Read (LBU) --");
        DMEM_Test(8'h08, 32'h000000AA, 1'b0, 1'b1, 3'b100, i, Result_Check, i);
    
    
        //Halfword Write / Halfword Read (Sign-extended LH)                 //5
        $display("\n-- Halfword Write/Read (LH) --");
        
        //write sequence - SH       //no need for buffer half cycle since two DMEM_Test calls gives a natural 5ns delay
        WriteData = 32'h0000BEEF;
        MemWrite  = 1;
        MemRead   = 0;
        MemDataType = 3'b001;       
        ALUResult_Addr = 8'h0C;
        
        @(posedge CPU_clk);
        
        MemWrite = 0;
        DMEM_Test(8'h0C, 32'hFFFFBEEF, 1'b0, 1'b1, 3'b001, i, Result_Check, i);
    
    
        //Unsigned Halfword (LHU)                                           //6
        $display("\n-- Halfword Write/Read (LHU) --");
        DMEM_Test(8'h0C, 32'h0000BEEF, 1'b0, 1'b1, 3'b101, i, Result_Check, i);
    
    
        //Misalignment tests (lower bits ignored)                           //7-8
        $display("\n-- Misalignment test --");
        DMEM_Test(8'h14 + 1, Golden_Mem[8'h14>>2], 1'b0, 1'b1, 3'b010, i, Result_Check, i);
        DMEM_Test(8'h18 + 2, Golden_Mem[8'h18>>2], 1'b0, 1'b1, 3'b010, i, Result_Check, i);
    
    
        //Upper-bit masking (address beyond range)                          //9
        $display("\n-- Upper bits masking --");
        DMEM_Test({20'hABCDE,12'h01C}, Golden_Mem[8'h1C>>2],
                  1'b0, 1'b1, 3'b010, i, Result_Check, i);
    
    
        //Randomised write/read                                             //10-14
        $display("\n-- Randomised sweep --");
        repeat (5) begin : RANDOM_SWEEP
            reg [WIDTH-1:0] rand_addr;
            reg [WIDTH-1:0] rand_data;
            
            rand_addr = {$random} % (DMEM_DEPTH*4);
            rand_data = $random;
            
            //write sequence - SW
            @(posedge CPU_clk);
            WriteData = rand_data;
            MemWrite  = 1;
            MemRead   = 0;
            MemDataType = 3'b010;       
            ALUResult_Addr = rand_addr;
            
            @(posedge CPU_clk);
            MemWrite = 0;
            
            DMEM_Test(rand_addr, rand_data, 1'b0, 1'b1, 3'b010, i, Result_Check, i);
        end
    
    
        //Full sweep: randomised write (SB/SH/SW) + readback               //15
        //This will interfere with the memory preload as all 64 preloaded lines
        //are overwritten with the loop
        $display("\n-- Full Sweep: Randomised write & readback --");
        for (j = 0; j < DMEM_DEPTH; j = j + 1) begin : FULL_SWEEP
            reg [WIDTH-1:0] rand_data;
            reg [1:0]       mode_sel;   //select between SB/SH/SW
            
            rand_data = $random;
            mode_sel  = $random % 3;    //0=SB, 1=SH, 2=SW
    
            case (mode_sel)
                2'd0: begin
                
                    //write sequence - SB
                    @(posedge CPU_clk);
                    WriteData   = rand_data;       
                    MemWrite    = 1;
                    MemRead   = 0;
                    MemDataType = 3'b000;
                    ALUResult_Addr = i * 4;
                    
                    @(posedge CPU_clk);
                    MemWrite    = 0;
                    
                    //Byte Load (LB - sign-extended)
                    DMEM_Test(i*4,
                              {{24{rand_data[7]}}, rand_data[7:0]},
                              1'b0, 1'b1, 3'b000, i, Result_Check, i);
                end
    
                2'd1: begin
                    //Half-word Store (SH)
                    @(posedge CPU_clk);
                    WriteData   = rand_data;
                    MemDataType = 3'b001;       //SH
                    MemWrite    = 1;
                    MemRead     = 0;
                    ALUResult_Addr = i * 4;
                    @(posedge CPU_clk);
                    MemWrite    = 0;
                    
                    //Half-word Load (LH - sign-extended)
                    DMEM_Test(i*4,
                              {{16{rand_data[15]}}, rand_data[15:0]},
                              1'b0, 1'b1, 3'b001, i, Result_Check, i);
                end
    
                default: begin
                    //Word Store (SW)
                    @(posedge CPU_clk);
                    WriteData   = rand_data;
                    MemDataType = 3'b010;       //SW
                    MemWrite    = 1;
                    MemRead     = 0;
                    ALUResult_Addr = i * 4;
                    @(posedge CPU_clk);
                    MemWrite    = 0;
                    
                    //Word Load (LW)
                    DMEM_Test(i*4,
                              rand_data,
                              1'b0, 1'b1, 3'b010, i, Result_Check, i);
                end
                
            endcase
        end
        
        //Release reset and check clearing of memory                        //16
        #20; CPU_rst_n = 0;      //active low reset after preload sweep
        $display("\n-- Reset sweep (all zeros) --");
        for (j = 0; j < DMEM_DEPTH; j = j + 1) begin
            DMEM_Test(i*4, 32'h0, 1'b0, 1'b1, 3'b010, i, Result_Check, i);
        CPU_rst_n = 1;                      //removing reset state
        end
    
        $display("\n=== Test Completed ===");
        $finish;
    end
    
endmodule
