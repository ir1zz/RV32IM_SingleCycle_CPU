/*
* Module: Branch_Target_Gen_TB.v
* Description: Testbench for Branch_Target_Gen.v
*              Verifies correct computation of branch target address
*              by adding PC to sign-extended Immediate.
* Author: Aashrith S Narayn
* Date: 17/09/2025
*/

`timescale 1ns / 1ps

module Branch_Target_Gen_TB;

    parameter WIDTH    = 32;
    parameter PC_WIDTH = 32;

    reg     [WIDTH-1:0]    Immediate;
    reg     [PC_WIDTH-1:0] PC;
    
    wire    [PC_WIDTH-1:0] BranchTarget;

    integer                i;
    reg                    Result_Check;

    //uut
    Branch_Target_Gen #(
        .WIDTH(WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) 
    CPU_BrTargetGen (
        .Immediate(Immediate),
        .PC(PC),
        .BranchTarget(BranchTarget)
    );


    //Task to apply stimulus and check output
    task Branch_Target_Test;
        input  [WIDTH-1:0]    Imm_in;
        input  [PC_WIDTH-1:0] PC_in;
        input  [PC_WIDTH-1:0] ExpTarget;
        input  integer        num;
        output                result;
        output integer        num_plus;
        
        begin
            Immediate = Imm_in;
            PC        = PC_in;
            #5;                //allow combinational logic to settle
            num_plus = num + 1;

            if (BranchTarget !== ExpTarget) begin
                $display("Test %0d  ERROR:", num_plus);
                $display("  Inputs  -> PC=%h  Immediate=%h", PC_in, Imm_in);
                $display("  Got     -> BranchTarget=%h", BranchTarget);
                $display("  Expected-> BranchTarget=%h", ExpTarget);
                result = 0;
            end else begin
                $display("Test %0d  PASS : BranchTarget=%h", num_plus, BranchTarget);
                result = 1;
            end
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        PC = 32'h0000_0000;
        Immediate = 32'h0000_0000;

        #20;
        $display("\n--- Branch_Target_Gen Comprehensive Tests ---");

        //Zero PC + Zero Imm = Target 0                                        //1
        Branch_Target_Test(32'h0000_0000, 32'h0000_0000,
                           32'h0000_0000, i, Result_Check, i);

        //Small positive offset (+4)                                            //2
        Branch_Target_Test(32'h0000_0004, 32'h0000_0100,
                           32'h0000_0104, i, Result_Check, i);

        //Small negative offset (-4)                                            //3
        Branch_Target_Test(32'hFFFF_FFFC, 32'h0000_0100,
                           32'h0000_00FC, i, Result_Check, i);

        //Mid-range positive offset (+512)                                      //4
        Branch_Target_Test(32'h0000_0200, 32'h0000_0400,
                           32'h0000_0600, i, Result_Check, i);

        //Mid-range negative offset (-512)                                      //5
        Branch_Target_Test(32'hFFFF_FE00, 32'h0000_0400,
                           32'h0000_0200, i, Result_Check, i);

        //Maximum positive branch offset (+4095 bytes)                          //6
        //(Imm_Gen sign-extends 0x00000FFE) or +4094 bit byte offaet
        Branch_Target_Test(32'h0000_0FFE, 32'h0000_1000,
                           32'h0000_1FFE, i, Result_Check, i);
        
         //(was previously FFFF_F800)
        //Minimum negative branch offset (-4096 bit byte offset)                //7
        //(Imm_Gen sign-extends 0xFFFF_F000) (it was orginally 0x1000)
        Branch_Target_Test(32'hFFFF_F000, 32'h0000_2000,
                           32'h0000_1000, i, Result_Check, i);

        //PC high value + positive offset (check overflow)                      //8
        Branch_Target_Test(32'h0000_0FFC, 32'hFFFF_F000,
                           32'hFFFF_FFFC, i, Result_Check, i);

        //PC high value + negative offset (wrap downward)                       //9
        Branch_Target_Test(32'hFFFF_F000, 32'hFFFF_F000,
                           32'hFFFF_E000, i, Result_Check, i);

        //PC random + random aligned immediate (positive)                       //10
        Branch_Target_Test(32'h0000_0556, 32'h1234_0000,
                           32'h1234_0556, i, Result_Check, i);

        //PC random + random aligned immediate (negative)                       //11
        Branch_Target_Test(32'hFFFF_FAAA, 32'h1234_1000,
                           32'h1234_0AAA, i, Result_Check, i);

        //PC = 0x7FFF_FFFC + positive offset to overflow sign bit               //12
        Branch_Target_Test(32'h0000_0004, 32'h7FFF_FFFC,
                           32'h8000_0000, i, Result_Check, i);

        //PC = 0x8000_0000 + negative offset to cross back                      //13
        Branch_Target_Test(32'hFFFF_FFFC, 32'h8000_0000,
                           32'h7FFF_FFFC, i, Result_Check, i);

        //All-ones immediate (-2) from a high PC                                //14
        Branch_Target_Test(32'hFFFF_FFFE, 32'hDEAD_BEEF,
                           32'hDEAD_BEED, i, Result_Check, i);

        //Large negative with large random PC                                   //15
        Branch_Target_Test(32'hFFFF_F000, 32'hABCD_E000,
                           32'hABCD_D000, i, Result_Check, i);

        #10;
        $display("--- End of Branch_Target_Gen Comprehensive Tests ---\n");
        $finish;
        
    end
    
endmodule