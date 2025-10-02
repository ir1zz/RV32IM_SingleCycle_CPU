/*
* Module: ALU_RV32I_TB.v
* Description: Testbench for the module ALU_RV32i.V - Performs combinational operations as required
*              by the RV32I instruction set and sends result. Leaves RV32M instructions for ALU_RV32M.v
* Author: Aashrith S Narayn
* Date: 08/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module ALU_RV32I_TB();

    parameter WIDTH  = 32;
    
    //0 and 1 notation for width-parametrized ALU use
    localparam [WIDTH-1:0] ZERO      = {WIDTH{1'b0}};
    localparam [WIDTH-1:0] ONE       = {{WIDTH-1{1'b0}}, 1'b1}; 
    
    reg     signed [WIDTH-1:0] Op1, Op2;
    reg            [5:0]       ALUControl;
    reg                        MDSel;
    
    wire           [WIDTH-1:0] ALUResult_I;
    wire                       Zero_I;
    
    reg                        Result_Check; 
    integer                    i;
        
    //uut
    ALU_RV32I #(
        .WIDTH(WIDTH)
        )
    CPU_ALU_I (
        .Op1(Op1),
        .Op2(Op2),
        .ALUControl(ALUControl),
        .MDSel(MDSel),
        .ALUResult_I(ALUResult_I),
        .Zero_I(Zero_I)
        );
     
    //Task to apply stimulus and check output  
    task ALU_Test;
        input          signed [WIDTH-1:0] OpA,OpB;
        input                 [5:0]       ALUCtrl;
        input                 [WIDTH-1:0] ALUResult_I_exp;
        input                             Zero_I_exp;
        input  integer                    num;
        output                            Result_Chk;
        output integer                    num_plus;
        
        begin
            Op1        = OpA;
            Op2        = OpB;
            ALUControl = ALUCtrl;
            num_plus   = num + 1;
            
            #5;             //allow combinational logic to settle
           
            if (ALUResult_I != ALUResult_I_exp || Zero_I !=  Zero_I_exp) begin
                Result_Chk = 0;
                $display("Test: %0d  ERROR: Op1=%0h, Op2=%0h, ALUControl=%0b | Got Result=%0h, Zero=%b | Expected Result=%0h, Zero=%b",
                          num_plus, OpA, OpB, ALUCtrl, ALUResult_I, Zero_I, ALUResult_I_exp, Zero_I_exp);
            end else begin
                Result_Chk = 1;
                $display("Test: %0d  PASS: ALUControl=%0b | Result=%0h (%0d)| Zero=%b",
                      num_plus, ALUCtrl, ALUResult_I, ALUResult_I, Zero_I);
            end
        end
     
    endtask
    
    
    //Stimulus - RV32I
    initial begin
        Op1 = 0; Op2 = 0;
        ALUControl = 0;
        MDSel = 0;          //IMPORTANT: ensures that ALU_RV32I only gives valid inputs
        i = 0;
        
        #20;
        
        $display("\n===== RV32I Full ALU Stress-Test =====\n");
        
        //Arithmetic tests
        ALU_Test(5, 3, `ALU_ADD, 8, 0, i, Result_Check, i);                               //ADD basic                           //1
        ALU_Test(32'h7FFFFFFF, 1, `ALU_ADD, 32'h80000000, 0, i, Result_Check, i);         //ADD overflow check                  //2
        ALU_Test(10, 3, `ALU_SUB, 7, 0, i, Result_Check, i);                              //SUB positive                        //3
        ALU_Test(10, 10, `ALU_SUB, 0, 1, i, Result_Check, i);                             //SUB zero                            //4
        ALU_Test(3, 10, `ALU_SUB, 32'hFFFF_FFF9, 0, i, Result_Check, i);                  //SUB negative                        //5
 
        //Logical tests
        ALU_Test(6, 12, `ALU_AND, 4, 0, i, Result_Check, i);                              // AND: 0110 & 1100 = 0100            //6
        ALU_Test(6, 12, `ALU_OR, 14, 0, i, Result_Check, i);                              // OR: 0110 | 1100 = 1110             //7
        ALU_Test(6, 12, `ALU_XOR, 10, 0,  i, Result_Check, i);                            // XOR: 0110 ^ 1100 = 1010            //8
   
        //Shift tests
        ALU_Test(32'h0000_0001, 3, `ALU_SLL, 32'h0000_0008, 0,  i, Result_Check, i);      // SLL: 1 << 3 = 8                    //9
        ALU_Test(32'h0000_0010, 2, `ALU_SRL, 32'h0000_0004, 0, i, Result_Check, i);       // SRL: 16 >> 2 = 4 (logical)         //10
        ALU_Test(32'hFFFF_FFF0, 2, `ALU_SRA, 32'hFFFF_FFFC, 0, i, Result_Check, i);       // SRA: -16 >>> 2 = -4 (arith)        //11

        //Conditional Set tests
        ALU_Test(-5, 3, `ALU_SLT, ONE, 0, i, Result_Check, i);                            //SLT assert                          //12             
        ALU_Test(5, -3, `ALU_SLT, ZERO, 1, i, Result_Check, i);                           //SLT deassert                        //13
        ALU_Test(5, 3, `ALU_SLTU, ZERO, 1, i, Result_Check, i);                           //SLTU deassert                       //14
        ALU_Test(3, 5, `ALU_SLTU, ONE, 0, i, Result_Check, i);                            //SLTU assert                         //15
   
        //LUI and AUIPC tests
        ALU_Test(0, 32'h12345000, `ALU_LUI, 32'h12345000, 0, i, Result_Check, i);         //LUI                                 //16
        ALU_Test(1000, 20, `ALU_AUIPC, 1020, 0, i, Result_Check, i);                      //AUIPC - PC is 1000                  //17
        
        //Branch tests
        ALU_Test(10, 10, `ALU_BEQ, 0, 1, i, Result_Check, i);                             // BEQ: 10 == 10 → taken              //18 
        ALU_Test(10, 20, `ALU_BEQ, 1, 0, i, Result_Check, i);                             // BEQ: 10 != 20 → not taken          //19
        ALU_Test(10, 20, `ALU_BNE, 1, 0, i, Result_Check, i);                             // BNE: 10 != 20 → taken              //20
        ALU_Test(10, 10, `ALU_BNE, 0, 1, i, Result_Check, i);                             // BNE: 10 == 10 → not taken          //21
        ALU_Test(-1, 1, `ALU_BLT, ONE, 0, i, Result_Check, i);                            // BLT: -1 < 1 → true                 //22
        ALU_Test(5, 3, `ALU_BLT, ZERO, 1, i, Result_Check, i);                            // BLT: 5 < 3 → false                 //23
        ALU_Test(5, 3, `ALU_BGE, 0, 1, i, Result_Check, i);                               // BGE: 5 >= 3 → true (inverted)      //24
        ALU_Test(-1, 1, `ALU_BGE, 1, 0, i, Result_Check, i);                              // BGE: -1 >= 1 → true (inverted)     //25
        ALU_Test(3, 5, `ALU_BLTU, ONE, 0, i, Result_Check, i);                            // BLTU: 3 < 5 (unsgn) → true         //26
        ALU_Test(5, 3, `ALU_BLTU, ZERO, 1, i, Result_Check, i);                           // BLTU: 5 < 3 (unsgn) → false        //27
        ALU_Test(5, 3, `ALU_BGEU, ZERO, 1, i, Result_Check, i);                           // BGEU: 5 >= 3 (unsgn) → true (inv)  //28
        ALU_Test(3, 5, `ALU_BGEU, ONE, 0, i, Result_Check, i);                            // BGEU: 3 >= 5 (unsgn) → false (inv) //29
    
        //NOTE: BGE AND BGEU show same behaviour as BLT and BLTU due to having
        //      the same behaviour in ALU. They are seperated in the branch control 
        //      logic in TrCtrl where the Zero flag logic is inverted
        
        //Jump tests
        ALU_Test(100, 20, `ALU_JAL, (100+20) & ~1, 0, i, Result_Check, i);                // JAL                                //30
        ALU_Test(200, 15, `ALU_JALR, 215, 0, i, Result_Check, i);                         // JALR                               //31

        //Default tests
        ALU_Test(123, 456, `ALU_NOP, 0, 1, i, Result_Check, i);                           // NOP: result=0, Zero=1              //32
        ALU_Test(123, 456, 6'h3F, 0, 1, i, Result_Check, i);                              // Invalid op → default case          //33
      
      
        //Edge or Corner-Case Tests
        ALU_Test(32'h7FFFFFFF, 1, `ALU_ADD, 32'h80000000, 0, i, Result_Check, i);         //ADD signed overflow (+max + 1)      //34 
        ALU_Test(32'h80000000, 1, `ALU_SUB, 32'h7FFFFFFF, 0, i, Result_Check, i);         //SUB signed underflow (-max - 1)     //35

        //Shift boundary conditions
        ALU_Test(1, 32, `ALU_SLL, 32'h00000001, 0, i, Result_Check, i);                   //SLL by 32 (lower 5 bits masked)     //36
        ALU_Test(32'h80000000, 1, `ALU_SRL, 32'h40000000, 0, i, Result_Check, i);         //SRL logical right shift clr sgn     //37
        ALU_Test(32'h80000000, 1, `ALU_SRA, 32'hC0000000, 0, i, Result_Check, i);         //SRA arith right shift sgn-ext       //38

        //Set-less-than extremes
        ALU_Test(32'h80000000, 32'h7FFFFFFF, `ALU_SLT, ONE, 0, i, Result_Check, i);       //SLT signed negative < positive      //39
        ALU_Test(32'hFFFFFFFF, 1, `ALU_SLTU, ZERO, 1, i, Result_Check, i);                //SLTU (max val < 1 -> false)         //40

        //Logical edge cases
        ALU_Test(32'hFFFFFFFF, 32'hFFFFFFFF, `ALU_XOR, ZERO, 1, i, Result_Check, i);      //XOR all ones -> 0                   //41
        ALU_Test(32'h12345678, ZERO, `ALU_AND, ZERO, 1, i, Result_Check, i);              //AND with zero                       //42

        #10;
        
        $display("\n===== All RV32I ALU Tests Complete =====\n");
        $finish;
        
    end
    
endmodule
