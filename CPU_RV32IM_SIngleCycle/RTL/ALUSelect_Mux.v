/*
* Module: ALUSelect_Mux.v
* Description: Selects the final ALU result and Zero flag based on MDSel.
*              This Mux separates critical paths and ensures only one ALU contributes to the 
*              output per instruction, reducing datapath delay and improving branch control
* Author: Aashrith S Narayn
* Date: 13/07/2025
*/

`timescale 1ns / 1ps

//(* dont_touch = "true" *)
module ALUSelect_Mux #(parameter WIDTH = 32)(
    input  wire [WIDTH-1:0] ALUResult_I, ALUResult_M,
    input  wire             Zero_I, Zero_M,
    input  wire             MDSel,
    output reg  [WIDTH-1:0] ALUResult,
    output reg              Zero
    );
    
    always @(*) begin
        if (MDSel) begin                //Takes forward value from RV32M ALU
            ALUResult = ALUResult_M;
            Zero      = Zero_M; 
        end else begin                  //Takes forward value from RV32I ALU
            ALUResult = ALUResult_I;
            Zero      = Zero_I;
        end
    end
    
endmodule
