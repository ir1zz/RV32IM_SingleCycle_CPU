/*
* Module: Target_Controller.v
* Description: Decides whether to take a branch or a jump based on
*              control signals and condition flags from ALU.
* Author: Aashrith S Narayn
* Date: 10/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

//(* dont_touch = "true" *)
module Target_Controller(
    input  wire [3:0] TargetSel,
    input  wire       Zero,
    output reg  [1:0] PCSrc
    );
    
    always @(*) begin
    
        case (TargetSel)
        
            `BR_EQ:  PCSrc = {1'b0,Zero};     //BEQ
            `BR_NE:  PCSrc = {1'b0,!Zero};    //BNE
            `BR_LT:  PCSrc = {1'b0,!Zero};    //BLT
            `BR_GE:  PCSrc = {1'b0,Zero};     //BGE
            `BR_LTU: PCSrc = {1'b0,!Zero};    //BLTU
            `BR_GEU: PCSrc = {1'b0,Zero};     //BGEU
            `UJ_AL:  PCSrc = 2'b10;           //JAL 
            `UJ_ALR: PCSrc = 2'b10;           //JALR
            `TR_NOP: PCSrc = 2'b00;            //default fallback for both control signals 0
            
            default: PCSrc = 2'b00;            //default fallback for incorrect funct3    
             
        endcase
        
    end
    
endmodule
