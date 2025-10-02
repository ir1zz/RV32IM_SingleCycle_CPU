/*
* Module: ALU_RV32I.v
* Description: Performs combinational operations as required
*              by the RV32M instruction set and sends result.
*              Leaves RV32I instructions for ALU_RV32I.v
* Author: Aashrith S Narayn
* Date: 16/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module ALU_RV32M_TB();

    parameter WIDTH  = 32;
    
    //0, 1 , -1 and Minimum Integer notation for width-parametrized ALU use
    localparam        [WIDTH-1:0] ZERO      = {WIDTH{1'b0}};
    localparam        [WIDTH-1:0] ONE       = {{WIDTH-1{1'b0}}, 1'b1}; 
    localparam signed [WIDTH-1:0] MINUS_ONE = {WIDTH{1'b1}};   //for division by 0
    localparam signed [WIDTH-1:0] MIN_INT = 1 << (WIDTH-1);
    
    reg     signed [WIDTH-1:0] Op1, Op2;
    reg            [5:0]       ALUControl;
    reg                        MDSel;
    
    wire           [WIDTH-1:0] ALUResult_M;
    wire                       Zero_M;
    
    reg                        Result_Check; 
    integer                    i;
        
    //uut
    ALU_RV32M#(
        .WIDTH(WIDTH)
        )
    CPU_ALU_M (
        .Op1(Op1),
        .Op2(Op2),
        .ALUControl(ALUControl),
        .MDSel(MDSel),
        .ALUResult_M(ALUResult_M),
        .Zero_M(Zero_M)
        );
     
    //Task to apply stimulus and check output  
    task ALU_Test;
        input          signed [WIDTH-1:0] OpA,OpB;
        input                 [5:0]       ALUCtrl;
        input                 [WIDTH-1:0] ALUResult_M_exp;
        input                             Zero_M_exp;
        input  integer                    num;
        output                            Result_Chk;
        output integer                    num_plus;
        
        begin
            Op1        = OpA;
            Op2        = OpB;
            ALUControl = ALUCtrl;
            num_plus   = num + 1;
            
            #5;                 //allow combinational logic to settle
           
            if (ALUResult_M != ALUResult_M_exp || Zero_M !=  Zero_M_exp) begin
                Result_Chk = 0;
                $display("Test: %0d  ERROR: Op1=%0h, Op2=%0h, ALUControl=%0b | Got Result=%0h, Zero=%b | Expected Result=%0h, Zero=%b",
                          num_plus, OpA, OpB, ALUCtrl, ALUResult_M, Zero_M, ALUResult_M_exp, Zero_M_exp);
            end else begin
                Result_Chk = 1;
                $display("Test: %0d  PASS: ALUControl=%0b | Result=%0h (%0d)| Zero=%b",
                      num_plus, ALUCtrl, ALUResult_M, ALUResult_M, Zero_M);
            end
        end
     
    endtask
    
    
    //Stimulus - RV32M
    initial begin
        Op1 = 0; Op2 = 0;
        ALUControl = 0;
        MDSel = 1;          //IMPORTANT: ensures that ALU_RV32M only gives valid inputs
        i = 0;
        
        #20;
        
        $display("\n===== RV32M Full ALU Stress-Test =====\n");
        
        //Multiply Tests
        ALU_Test(5, 3, `ALU_MUL,   15, 0, i, Result_Check, i);                                    // MUL basic                          //1
        ALU_Test(-5, 3, `ALU_MUL,  -15, 0, i, Result_Check, i);                                   // MUL negative*positive              //2
        ALU_Test(-5,-3, `ALU_MUL,   15, 0, i, Result_Check, i);                                   // MUL negative*negative              //3
        ALU_Test(32'h7FFFFFFF, 2, `ALU_MUL, 32'hFFFFFFFE, 0, i, Result_Check, i);                 // MUL overflow wrap                  //4
        ALU_Test(5, 3, `ALU_MULH,  0, 1, i, Result_Check, i);                                     // MULH high half small operands      //5
        ALU_Test(32'h7FFFFFFF, 32'h7FFFFFFF, `ALU_MULH, 32'h3FFFFFFF, 0, i, Result_Check, i);     // MULH high half large operands      //6
        ALU_Test(-5, 3, `ALU_MULH, MINUS_ONE, 0, i, Result_Check, i);                             // MULH signed mix                    //7
        ALU_Test(MINUS_ONE, MINUS_ONE, `ALU_MULHU, 32'hFFFFFFFE, 0, i, Result_Check, i);          // MULHU unsigned max*max high half   //8
        ALU_Test(MIN_INT, 2, `ALU_MULHU, ONE, 0, i, Result_Check, i);                             // MULHU unsigned with MSB set        //9
        ALU_Test(-5, 3, `ALU_MULHSU, MINUS_ONE, 0, i, Result_Check, i);                           // MULHSU signed*unsigned             //10
        ALU_Test(MIN_INT, 2, `ALU_MULHSU, MINUS_ONE, 0, i, Result_Check, i);                      // MULHSU edge cas                    //11
    
        //Divide Tests
        ALU_Test(10, 3, `ALU_DIV,   3, 0, i, Result_Check, i);                                    // DIV basic                          //12
        ALU_Test(-10, 3, `ALU_DIV, -3, 0, i, Result_Check, i);                                    // DIV negative dividend              //13
        ALU_Test(10,-3, `ALU_DIV, -3, 0, i, Result_Check, i);                                     // DIV negative divisor               //14
        ALU_Test(-10,-3,`ALU_DIV,  3, 0, i, Result_Check, i);                                     // DIV both negative                  //15
        ALU_Test(7, -3, `ALU_DIV, -2, 0, i, Result_Check, i);                                     // DIV trunc toward zero              //16
        ALU_Test(10, 0, `ALU_DIV, MINUS_ONE, 0, i, Result_Check, i);                              // DIV divide by zero → -1            //17
        ALU_Test(MIN_INT, MINUS_ONE, `ALU_DIV, MIN_INT, 0, i, Result_Check, i);                   // DIV overflow -2^31 / -1 → -2^31    //18
    
        //Unsigned Divide Tests
        ALU_Test(10, 3, `ALU_DIVU, 3, 0, i, Result_Check, i);                                     // DIVU basic                         //19
        ALU_Test(MINUS_ONE, 2, `ALU_DIVU, 32'h7FFFFFFF, 0, i, Result_Check, i);                   // DIVU max / 2                       //20
        ALU_Test(10, 0, `ALU_DIVU, MINUS_ONE, 0, i, Result_Check, i);                             // DIVU divide by zero → all 1s       //21
        
        //Unsigned Remainder Tests
        ALU_Test(10, 3, `ALU_REMU, 1, 0, i, Result_Check, i);                                     // REMU basic                         //22
        ALU_Test(MINUS_ONE, 10, `ALU_REMU, 5, 0, i, Result_Check, i);                             // REMU max % 10                      //23
        ALU_Test(10, 0, `ALU_REMU, 10,0, i, Result_Check, i);                                     // REMU divide by zero → dividend     //24
    
        //Default Tests
        ALU_Test(123, 456, `ALU_NOP, ZERO, 1, i, Result_Check, i);                                // NOP: result=0, Zero=1              //25
        ALU_Test(123, 456, 6'h3F, ZERO, 1, i, Result_Check, i);                                   // Invalid op → default case          //26
        
        
        //DIV rounding toward zero check (already have some, but including a few more)
        ALU_Test(5, -2,  `ALU_DIV,  -2, 0, i, Result_Check, i);                                   // 5 / -2 => -2 (trunc toward 0)      //27
        ALU_Test(-5, 2,  `ALU_DIV,  -2, 0, i, Result_Check, i);                                   // -5 / 2 => -2                       //28
        
        //DIVU and REMU edge: large unsigned values
        ALU_Test(MINUS_ONE, 3, `ALU_DIVU, 32'h55555555, 0, i, Result_Check, i);                   // check unsigned quotient            //29
        ALU_Test(MINUS_ONE, 3, `ALU_REMU, ZERO, 1, i, Result_Check, i);                           // check unsigned remainder           //30
        
        //REM sign behavior: negative dividend
        ALU_Test(-7, 3, `ALU_REM, -1, 0, i, Result_Check, i);                                     // -7 % 3 => -1                       //31
        
        //MULH sign/unsigned cross-checks
        ALU_Test(MIN_INT, MINUS_ONE, `ALU_MULHSU, MIN_INT, 0, i, Result_Check, i);                // signed MIN * -1(unsigned) case     //32
   
        #10;
        
        $display("\n===== All RV32M ALU Tests Complete =====\n");
        $finish;   
   
    end

endmodule
