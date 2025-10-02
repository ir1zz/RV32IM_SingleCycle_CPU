/*
* Module: ALU_RV32M.v
* Description: Performs combinational operations as required
*              by the RV32M instruction set and sends result.
*              Leaves RV32I instructions for ALU_RV32I.v
* Author: Aashrith S Narayn
* Date: 16/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//NOTE: This ALU can be scaled from 32 bit to any instruction length using the parameter WIDTH
//(* dont_touch = "true" *)
module ALU_RV32M #(parameter WIDTH = 32)(       //NOTE: PC_WIDTH must be the same as WIDTH due to both register and PC being operands in the same ALU
    input  wire signed [WIDTH-1:0] Op1, Op2,    //NOTE below
    input  wire        [5:0]       ALUControl,
    input  wire                    MDSel,
    output reg         [WIDTH-1:0] ALUResult_M,
    output wire                    Zero_M
    );
    
    //0, 1 , -1 and Minimum Integer notation for width-parametrized ALU use
    localparam        [WIDTH-1:0] ZERO      = {WIDTH{1'b0}};
    localparam        [WIDTH-1:0] ONE       = {{WIDTH-1{1'b0}}, 1'b1}; 
    localparam signed [WIDTH-1:0] MINUS_ONE = {WIDTH{1'b1}};   //for division by 0
    localparam signed [WIDTH-1:0] MIN_INT = 1 << (WIDTH-1);

    
    //temporary 64 bit register to store products
    reg signed [2*WIDTH-1:0] mul_temp;
    
    //NOTE: operations that require signed inputs need the inputs to be declared as signed at the module definition
    //This means unsigned operations within the ALU logic need to be explicitly casted using temp variables
    //Output ALUResult_I need not be casted as signed within module definition
    
    //unsigned temps
    wire [WIDTH-1:0] uOp1 = $unsigned(Op1);
    wire [WIDTH-1:0] uOp2 = $unsigned(Op2);
    
    
    always @(*) begin
        
        //avoiding latch inference
        mul_temp    = 0;
        ALUResult_M = ZERO;
        
        if (MDSel) begin
            case (ALUControl) 

                //Multiply Operations
                `ALU_MUL:    begin
                    mul_temp    = Op1 * Op2;
                    ALUResult_M = mul_temp[WIDTH-1:0];
                end
                `ALU_MULH:   begin
                    mul_temp    = Op1 * Op2;
                    ALUResult_M = mul_temp[2*WIDTH-1:WIDTH]; 
                end
                `ALU_MULHU:  begin
                    mul_temp    = uOp1 * uOp2;
                    ALUResult_M = mul_temp[2*WIDTH-1:WIDTH];
                 end
                `ALU_MULHSU: begin
                    mul_temp    = $signed(Op1) * $signed({1'b0, uOp2});  //explicitly casting Op1 as signed and Op2 as positive signed (even after unsigned value)
                    ALUResult_M = mul_temp[2*WIDTH-1:WIDTH];             //as signedxunsigned operations are treated as unsignedxunsigned by default
                end
                
                //Divide Operations with appropriate checks
                `ALU_DIV:   begin
                    if (Op2 == 0) ALUResult_M = MINUS_ONE;   
                    else if (Op1 == MIN_INT && Op2 == MINUS_ONE)         //as per RV32M spec, -2^31 / -1 = 2^31, which is out of range
                    begin                                                //so the spec states that -2^31 is the result of this op
                                  ALUResult_M = MIN_INT;                      
                    end                                     
                    else          ALUResult_M = Op1 / Op2;
                end
                `ALU_DIVU:  begin
                    if (Op2 != 0) ALUResult_M = uOp1 / uOp2;
                    else          ALUResult_M = MINUS_ONE;
                end
                `ALU_REM:   begin
                    if (Op2 != 0) ALUResult_M = Op1 % Op2;
                    else if (Op1 == MIN_INT && Op2 == MINUS_ONE)         //as per RV32M spec, -2^31 % -1 = 0
                    begin                                                     
                                  ALUResult_M = ZERO;                      
                    end
                    else          ALUResult_M = Op1;                     //dividend % 0 = dividend
                end
                `ALU_REMU:  begin
                    if (Op2 != 0) ALUResult_M = uOp1 % uOp2;
                    else          ALUResult_M = Op1;                     //dividend % 0 = dividend
                end
                
                //No Operation (default case)
                `ALU_NOP:         ALUResult_M = ZERO;
                
                default:          ALUResult_M = ZERO;                    //Unknown ALUControl, default to NOP

                
            endcase
            
        end else begin
            
            ALUResult_M = ZERO;                //Zero default for when MDSel is deasserted in this ALU
            
        end
        
    end
    
    assign Zero_M = (ALUResult_M == ZERO);     //NOTE: This flag is used in ALU_RV32I as a condition flag for BEQ
                                               //and as an inverted condition flag for BNE, BLT, BGE, BLTU, BGEU
                                               //Left as is for readability and modularity
    
endmodule