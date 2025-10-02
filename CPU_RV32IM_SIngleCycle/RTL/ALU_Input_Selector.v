/*
* Module: ALU_input_selector.v
* Description: Selects 32 bit inputs from Registers, Program Counter 
*              and Immediate Generator according to control signal inputs 
*              to feed into ALU.
* Author: Aashrith S Narayn
* Date: 03/07/2025
*/

`timescale 1ns / 1ps
    

//MUX for Operand 1 of ALU
module Op1_Mux #(
    parameter WIDTH    = 32,    //NOTE: PC_WIDTH AND WIDTH HAS TO BE SAME, OTHERWISE SIGN EXTENSION IS NEEDED 
    parameter PC_WIDTH = 32     //ON ONE OPERAND OR THE OTHER - COMPLICATES ALU INPUT SELECTION AND ALU DATA WIDTH
    )(
    input wire [WIDTH-1:0]    Rs1Data,
    input wire [PC_WIDTH-1:0] PC,
    input wire                ALUSrc1,
    output reg [WIDTH-1:0]    Op1
    );
    always @(*) begin
        Op1 = (ALUSrc1) ? PC : Rs1Data;     //PC used by LUI, AUIPC and JAL
    end
endmodule

//MUX for Operand 2 of ALU
module Op2_Mux #(parameter WIDTH = 32)(
    input wire [WIDTH-1:0] Rs2Data,
    input wire [WIDTH-1:0] Imm,
    input wire             ALUSrc2,
    output reg [WIDTH-1:0] Op2
    );
    always @(*) begin
        Op2 = (ALUSrc2) ? Imm : Rs2Data;    //Imm used by I,U-type, LW,SW etc
    end
endmodule

//Top level selector module for both Operands of ALU
//(* dont_touch = "true" *)
module ALU_Input_Selector  #(
    parameter WIDTH    = 32,
    parameter PC_WIDTH = 32     //extensible program counter design
    )(
    input  wire [WIDTH-1:0]    Rs1Data, Rs2Data,
    input  wire [PC_WIDTH-1:0] PC,
    input  wire [WIDTH-1:0]    Immediate,
    input  wire                ALUSrc1,ALUSrc2,
    output wire [WIDTH-1:0]    Op1, Op2
    );
    
    Op1_Mux #(.WIDTH(WIDTH), .PC_WIDTH(PC_WIDTH)) Mux1(
        .Rs1Data(Rs1Data),
        .PC(PC),
        .ALUSrc1(ALUSrc1),
        .Op1(Op1)    
        );
        
    Op2_Mux #(.WIDTH(WIDTH)) Mux2(
        .Rs2Data(Rs2Data),
        .Imm(Immediate),
        .ALUSrc2(ALUSrc2),
        .Op2(Op2)    
        );
    
endmodule