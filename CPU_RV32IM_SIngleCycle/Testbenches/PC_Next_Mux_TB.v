/*
* Module: PC_Next_Mux_TB.v
* Description: Testbench for PC_Next_Mux.v
*              Verifies next-PC selection for PC+4, BranchTarget, JumpTarget
*              and default fallback.
* Author: Aashrith S Narayn
* Date: 18/09/2025
*/

`timescale 1ns / 1ps

module PC_Next_Mux_TB;

    parameter WIDTH    = 32;
    parameter PC_WIDTH = 32;

    reg     [PC_WIDTH-1:0] PC_Plus_4;
    reg     [PC_WIDTH-1:0] BranchTarget;
    reg     [WIDTH-1:0]    JumpTarget;
    reg     [1:0]          PCSrc;

    wire    [PC_WIDTH-1:0] PC_Next;

    integer                i;
    reg                    Result_Check;

    //uut
    PC_Next_Mux #(
        .PC_WIDTH(PC_WIDTH),
        .WIDTH(WIDTH)
    ) 
    CPU_NextPCMux (
        .PC_Plus_4(PC_Plus_4),
        .BranchTarget(BranchTarget),
        .JumpTarget(JumpTarget),
        .PCSrc(PCSrc),
        .PC_Next(PC_Next)
    );


    //Task to drive stimulus and verify result
    task NextPC_Test;
        input         [PC_WIDTH-1:0] PC4_in;
        input         [PC_WIDTH-1:0] Br_in;
        input         [WIDTH-1:0]    Jmp_in;
        input         [1:0]          PCSrc_in;
        input         [PC_WIDTH-1:0] ExpNextPC;
        input integer                num;
        output                       result;
        output integer               num_plus;
        
        begin
            PC_Plus_4   = PC4_in;
            BranchTarget= Br_in;
            JumpTarget  = Jmp_in;
            PCSrc       = PCSrc_in;
            #5;                     //allow combinational logic to settle

            num_plus = num + 1;

            if (PC_Next !== ExpNextPC) begin
                $display("Test %0d  ERROR:", num_plus);
                $display("  Inputs  -> PCSrc=%b  PC+4=%h  BranchTarget=%h  JumpTarget=%h",
                          PCSrc_in, PC4_in, Br_in, Jmp_in);
                $display("  Got     -> PC_Next=%h", PC_Next);
                $display("  Expected-> PC_Next=%h", ExpNextPC);
                result = 0;
            end else begin
                $display("Test %0d  PASS : PC_Next=%h", num_plus, PC_Next);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        PC_Plus_4    = 0;
        BranchTarget = 0;
        JumpTarget   = 0;
        PCSrc        = 0;

        #20;
        
        $display("\n--- PC_Next_Mux Tests ---");

        //PC+4 normal update (branch target unused)                      //1
        NextPC_Test(32'h0000_0004, 32'h0000_0000, 32'h2222_2222,
                    2'b00, 32'h0000_0004, i, Result_Check, i);

        //BranchTarget selected: +16 bytes                               //2
        NextPC_Test(32'h0000_1004, 32'h0000_1014, 32'h8765_4321,
                    2'b01, 32'h0000_1014, i, Result_Check, i);

        //BranchTarget selected: -32 bytes (negative offset)             //3
        NextPC_Test(32'h0000_2000, 32'h0000_1FE0, 32'hCAFEBABE,
                    2'b01, 32'h0000_1FE0, i, Result_Check, i);

        //JumpTarget selected                                            //4
        NextPC_Test(32'hABCD_EF01, 32'h0000_0008, 32'hABCD_F000,
                    2'b10, 32'hABCD_F000, i, Result_Check, i);

        //Default fallback: invalid PCSrc                                //5
        NextPC_Test(32'hDEAD_BEEF, 32'hDEAD_BEF3, 32'hCCCC_DDDD,
                    2'b11, 32'hDEAD_BEEF, i, Result_Check, i);

        //Edge case: all zeros (PC+4 path)                               //6
        NextPC_Test(32'h0000_0000, 32'h0000_0004, 32'h0000_0000,
                    2'b00, 32'h0000_0000, i, Result_Check, i);

        //Edge case: near 32-bit max, branch fwd within range            //7
        //PC near max, branch +8 (will later wrap around)
        NextPC_Test(32'hFFFF_FFF4, 32'hFFFF_FFFC, 32'hFFFF_F000,
                    2'b01, 32'hFFFF_FFFC, i, Result_Check, i);

        //Branch backward near max (negative offset)                     //8
        NextPC_Test(32'hFFFF_FFF0, 32'hFFFF_FFE0, 32'h8000_0000,
                    2'b01, 32'hFFFF_FFE0, i, Result_Check, i);

        //Jump target with high bit pattern                              //9
        NextPC_Test(32'h8000_0004, 32'h8000_0008, 32'h8000_1234,
                    2'b10, 32'h8000_1234, i, Result_Check, i);



        #10;
        
        $display("--- End of PC_Next_Mux Tests ---\n");
        $finish;
    end

endmodule
