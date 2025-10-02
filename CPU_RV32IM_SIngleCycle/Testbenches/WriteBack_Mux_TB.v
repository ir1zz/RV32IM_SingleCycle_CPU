/*
* Module: WriteBack_Mux_TB.v
* Description: Testbench for WriteBack_Mux.v
*              Verifies correct selection of write-back data for all MemToReg cases.
* Author: Aashrith S Narayn
* Date: 18/09/2025
*/

`timescale 1ns / 1ps

module WriteBack_Mux_TB;

    parameter WIDTH    = 32;
    parameter PC_WIDTH = 32;

    reg     [WIDTH-1:0]    ALUResult;
    reg     [WIDTH-1:0]    ReadData;
    reg     [PC_WIDTH-1:0] PC_Plus_4;
    reg     [1:0]          MemToReg;

    wire    [WIDTH-1:0]    WriteData;
    
    integer                i;
    reg                    Result_Check;

    //uut
    WriteBack_Mux #(
        .WIDTH(WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) 
    CPU_WrBackMux (
        .ALUResult(ALUResult),
        .ReadData(ReadData),
        .PC_Plus_4(PC_Plus_4),
        .MemToReg(MemToReg),
        .WriteData(WriteData)
    );


    //Task for stimulus and checking
    task WriteBack_Test;
        input           [WIDTH-1:0]    ALU_in;
        input           [WIDTH-1:0]    RdData_in;
        input           [PC_WIDTH-1:0] PC4_in;
        input           [1:0]          MemToReg_in;
        input           [WIDTH-1:0]    ExpWriteData;
        input  integer                 num;
        output                         result;
        output integer                 num_plus;
        
        begin
            ALUResult = ALU_in;
            ReadData  = RdData_in;
            PC_Plus_4 = PC4_in;
            MemToReg  = MemToReg_in;
            
            #5;                 //allow combinational logic to settle

            num_plus = num + 1;

            if (WriteData !== ExpWriteData) begin
                $display("Test %0d  ERROR:", num_plus);
                $display("  Inputs  -> MemToReg=%b  ALU=%h  ReadData=%h  PC+4=%h",
                         MemToReg_in, ALU_in, RdData_in, PC4_in);
                $display("  Got     -> WriteData=%h", WriteData);
                $display("  Expected-> WriteData=%h", ExpWriteData);
                result = 0;
            end else begin
                $display("Test %0d  PASS : WriteData=%h", num_plus, WriteData);
                result = 1;
            end
        end
    endtask


    //Stimulus
    initial begin
        i = 0;
        ALUResult = 0;
        ReadData  = 0;
        PC_Plus_4 = 0;
        MemToReg  = 0;

        #20;
        
        $display("\n--- WriteBack_Mux Tests ---");

        //ALU result write-back
        WriteBack_Test(32'h0000_1234, 32'hAAAA_BBBB, 32'h1111_1111,
                       2'b00, 32'h0000_1234, i, Result_Check, i);               //1

        //Memory read write-back
        WriteBack_Test(32'hDEAD_BEEF, 32'hFACE_CAFE, 32'h2222_2222,
                       2'b01, 32'hFACE_CAFE, i, Result_Check, i);               //2

        //PC + 4 write-back (for JAL/JALR link wire)
        WriteBack_Test(32'h1357_9BDF, 32'h2468_ACED, 32'h0000_1004,
                       2'b10, 32'h0000_1004, i, Result_Check, i);               //3

        //Default fallback: unknown MemToReg to ALUResult
        WriteBack_Test(32'hCAFEBABE, 32'hABCD_EF01, 32'h3333_3333,
                       2'b11, 32'hCAFEBABE, i, Result_Check, i);                //4

        //Edge case: all zeros
        WriteBack_Test(32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                       2'b00, 32'h0000_0000, i, Result_Check, i);               //5

        //Edge case: all ones (max unsigned)
        WriteBack_Test(32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
                       2'b01, 32'hFFFF_FFFF, i, Result_Check, i);               //6

        //Mixed high/low values
        WriteBack_Test(32'h8000_0000, 32'h7FFF_FFFF, 32'h0000_FFFF,
                       2'b10, 32'h0000_FFFF, i, Result_Check, i);               //7

        #10;
        $display("--- End of WriteBack_Mux Tests ---\n");
        $finish;
    end

endmodule
