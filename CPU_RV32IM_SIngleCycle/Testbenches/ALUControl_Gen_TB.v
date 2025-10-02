/*
* Module: ALUControl_Gen_TB.v
* Description: Testbench for ALUControl_Gen module.
*              Exhaustively verifies all ALUOp / funct3 / funct7 combinations
*              for RV32IM instructions.
* Author: Aashrith S Narayn
* Date: 17/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module ALUControl_Gen_TB;               //SIME TIME = 250ns

    parameter WIDTH       = 32;
    parameter INSTR_WIDTH = 32;

    reg  [2:0]             ALUOp;
    reg  [INSTR_WIDTH-1:0] Instr_RV32IM;
    
    wire [5:0]             ALUControl;

    integer                i;
    reg                    Result_Check;

    //uut
    ALUControl_Gen #(
        .WIDTH(WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH)
    ) 
    CPU_ALUCtrlGen (
        .ALUOp(ALUOp),
        .Instr_RV32IM(Instr_RV32IM),
        .ALUControl(ALUControl)
    );


    //Task to apply stimulus and check output
    task ALUControl_Test;
        input          [2:0]  aluop;
        input          [31:0] instr;
        input          [5:0]  expALUCtrl;
        input  integer        num;
        output integer        num_plus;
        output                result;
        
        begin
            ALUOp         = aluop;
            Instr_RV32IM  = instr;
            #5;             //allow combinational logic to settle

            num_plus = num + 1;

            $display("Test %0d: ALUOp=%b | Instr[31:0]=%h | ALUControl=%b (Expected=%b)",
                      num_plus, aluop, instr, ALUControl, expALUCtrl);      

            if (ALUControl !== expALUCtrl) begin
                result = 0;
                $display(" Test FAILED!");
            end else begin
                result = 1;
                $display(" Test PASSED!");
            end
            
        end
        
    endtask


    //Stimulus
    initial begin
        i = 0;
        Instr_RV32IM = 32'h00000000;
        ALUOp        = 3'b000;

        #20;
        
        $display("\n===== ALUControl_Gen Full Stress-Test =====\n");
        
        
        //LSJ(Load/Store/JALR) - ADD operation
        ALUControl_Test(`ALUOP_LSJ,
            {7'b0000000,5'd1,5'd2,3'b000,5'd3,`OPCODE_LOAD}, `ALU_ADD, i, i, Result_Check);     //1  lw   x3,0(x2)
        
        ALUControl_Test(`ALUOP_LSJ,
            {7'b0000000,5'd1,5'd2,3'b000,5'd3,`OPCODE_STORE}, `ALU_ADD, i, i, Result_Check);    //2  sw   x1,0(x2)
        
        ALUControl_Test(`ALUOP_LSJ,
            {7'b0000000,5'd1,5'd2,3'b000,5'd3,`OPCODE_JALR}, `ALU_ADD, i, i, Result_Check);     //3  jalr x3,0(x2)
        

        //Branches(BEQ,BNE,BLT,BGE,BLTU,BGEU)
        ALUControl_Test(`ALUOP_BRANCH,
            {7'h12,5'd1,5'd2,3'b000,5'h3,`OPCODE_BRANCH}, `ALU_BEQ, i, i, Result_Check);        //4  beq  x1,x2,<imm 0x12>
        ALUControl_Test(`ALUOP_BRANCH,
            {7'h12,5'd3,5'd4,3'b001,5'h3,`OPCODE_BRANCH}, `ALU_BNE, i, i, Result_Check);        //5  bne  x3,x4,<imm 0x12>
        ALUControl_Test(`ALUOP_BRANCH,
            {7'h12,5'd5,5'd6,3'b100,5'h3,`OPCODE_BRANCH}, `ALU_BLT, i, i, Result_Check);        //6  blt  x5,x6,<imm 0x12>
        ALUControl_Test(`ALUOP_BRANCH,
            {7'h12,5'd7,5'd8,3'b101,5'h3,`OPCODE_BRANCH}, `ALU_BGE, i, i, Result_Check);        //7  bge  x7,x8,<imm 0x12>
        ALUControl_Test(`ALUOP_BRANCH,
            {7'h12,5'd9,5'd10,3'b110,5'h3,`OPCODE_BRANCH}, `ALU_BLTU, i, i, Result_Check);      //8  bltu x9,x10,<imm 0x12>
        ALUControl_Test(`ALUOP_BRANCH,
            {7'h12,5'd11,5'd12,3'b111,5'h3,`OPCODE_BRANCH}, `ALU_BGEU, i, i, Result_Check);     //9  bgeu x11,x12,<imm 0x12>


        //R-Type(ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND)
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b000,5'd3,`OPCODE_RTYPE}, `ALU_ADD, i, i, Result_Check);    //10 add  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0100000,5'd1,5'd2,3'b000,5'd3,`OPCODE_RTYPE}, `ALU_SUB, i, i, Result_Check);    //11 sub  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b001,5'd3,`OPCODE_RTYPE}, `ALU_SLL, i, i, Result_Check);    //12 sll  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b010,5'd3,`OPCODE_RTYPE}, `ALU_SLT, i, i, Result_Check);    //13 slt  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b011,5'd3,`OPCODE_RTYPE}, `ALU_SLTU, i, i, Result_Check);   //14 sltu x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b100,5'd3,`OPCODE_RTYPE}, `ALU_XOR, i, i, Result_Check);    //15 xor  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b101,5'd3,`OPCODE_RTYPE}, `ALU_SRL, i, i, Result_Check);    //16 srl  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0100000,5'd1,5'd2,3'b101,5'd3,`OPCODE_RTYPE}, `ALU_SRA, i, i, Result_Check);    //17 sra  x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b110,5'd3,`OPCODE_RTYPE}, `ALU_OR,  i, i, Result_Check);    //18 or   x3,x1,x2
        ALUControl_Test(`ALUOP_RTYPE,
            {7'b0000000,5'd1,5'd2,3'b111,5'd3,`OPCODE_RTYPE}, `ALU_AND, i, i, Result_Check);    //19 and  x3,x1,x2


        //I-Type(ADDI/ANDI/ORI etc + Shifts)
        ALUControl_Test(`ALUOP_ITYPE,
            {12'h123,5'd1,3'b000,5'd3,`OPCODE_ITYPE}, `ALU_ADD, i, i, Result_Check);            //20 addi x3,x1,0x123
        ALUControl_Test(`ALUOP_ITYPE,
            {12'h456,5'd1,3'b111,5'd3,`OPCODE_ITYPE}, `ALU_AND, i, i, Result_Check);            //21 andi x3,x1,0x456
        ALUControl_Test(`ALUOP_ITYPE,
            {12'h789,5'd1,3'b110,5'd3,`OPCODE_ITYPE}, `ALU_OR,  i, i, Result_Check);            //22 ori  x3,x1,0x789
        ALUControl_Test(`ALUOP_ITYPE,
            {12'hABC,5'd1,3'b100,5'd3,`OPCODE_ITYPE}, `ALU_XOR, i, i, Result_Check);            //23 xori x3,x1,0xABC
        ALUControl_Test(`ALUOP_ITYPE,
            {7'b0000000,5'd1,5'd2,3'b001,5'd3,`OPCODE_ITYPE}, `ALU_SLL, i, i, Result_Check);    //24 slli x3,x1,x2
        ALUControl_Test(`ALUOP_ITYPE,
            {7'b0000000,5'd1,5'd2,3'b101,5'd3,`OPCODE_ITYPE}, `ALU_SRL, i, i, Result_Check);    //25 srli x3,x1,x2
        ALUControl_Test(`ALUOP_ITYPE,
            {7'b0100000,5'd1,5'd2,3'b101,5'd3,`OPCODE_ITYPE}, `ALU_SRA, i, i, Result_Check);    //26 srai x3,x1,x2
        ALUControl_Test(`ALUOP_ITYPE,
            {12'hDEF,5'd1,3'b010,5'd3,`OPCODE_ITYPE}, `ALU_SLT, i, i, Result_Check);            //27 slti x3,x1,0xDEF
        ALUControl_Test(`ALUOP_ITYPE,
            {12'hEEE,5'd1,3'b011,5'd3,`OPCODE_ITYPE}, `ALU_SLTU,i, i, Result_Check);            //28 sltiu x3,x1,0xEEE


        //RV32M(MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU)
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b000,5'd3,`OPCODE_RTYPE}, `ALU_MUL, i, i, Result_Check);    //29 mul   x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b001,5'd3,`OPCODE_RTYPE}, `ALU_MULH,i, i, Result_Check);    //30 mulh  x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b010,5'd3,`OPCODE_RTYPE}, `ALU_MULHSU,i,i,Result_Check);    //31 mulhsu x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b011,5'd3,`OPCODE_RTYPE}, `ALU_MULHU,i,i,Result_Check);     //32 mulhu x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b100,5'd3,`OPCODE_RTYPE}, `ALU_DIV, i, i, Result_Check);    //33 div   x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b101,5'd3,`OPCODE_RTYPE}, `ALU_DIVU,i,i,Result_Check);      //34 divu  x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b110,5'd3,`OPCODE_RTYPE}, `ALU_REM, i, i, Result_Check);    //35 rem   x3,x1,x2
        ALUControl_Test(`ALUOP_RMUL,
            {7'b0000001,5'd1,5'd2,3'b111,5'd3,`OPCODE_RTYPE}, `ALU_REMU,i,i,Result_Check);      //36 remu  x3,x1,x2


        //U-Type(LUI/AUIPC)
        ALUControl_Test(`ALUOP_UTYPE,
            {20'hABCDE,5'd3,`OPCODE_LUI},   `ALU_LUI,   i, i, Result_Check);                    //37 lui   x3,0xABCDE
        ALUControl_Test(`ALUOP_UTYPE,
            {20'h12345,5'd3,`OPCODE_AUIPC}, `ALU_AUIPC, i, i, Result_Check);                    //38 auipc x3,0x12345


        //Jump(JAL)
        ALUControl_Test(`ALUOP_JUMP,
            {20'h54321,5'd3,`OPCODE_JAL}, `ALU_JAL, i, i, Result_Check);                        //39 jal   x3,<imm 0x54321>


        #10;
        
        $display("\n===== All ALUControl_Gen Tests Complete =====\n");
        $finish;
    end

endmodule
