/*
* Module: Control_Unit_tb.v
* Description: Testbench for Control_Unit module.
*              Exhaustively verifies all RV32IM instruction types
*              (R/I/S/B/U/J + M-extension + Loads/Stores)
*              against expected control signal outputs.
* Author: Aashrith S Narayn
* Date: 17/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes_TB.vh"

module Control_Unit_TB();
    
    parameter WIDTH       = 32;
    parameter INSTR_WIDTH = 32;


    reg     [31:0] Instr_RV32IM;
    
    wire    [2:0]  ALUOp;
    wire           MDSel;
    wire    [2:0]  ImmediateSrc;
    wire    [3:0]  TargetSel;
    wire           RegWrite;
    wire           MemRead;
    wire           MemWrite;
    wire    [1:0]  MemToReg;
    wire    [2:0]  MemDataType;
    wire           ALUSrc1, ALUSrc2;
    
    integer        i;
    reg            Result_Check;
    

    //uut
    Control_Unit #(
    .WIDTH(WIDTH),
    .INSTR_WIDTH(INSTR_WIDTH)
    )
    CPU_Control (
        .Instr_RV32IM(Instr_RV32IM),
        .ALUOp(ALUOp),
        .MDSel(MDSel),
        .ImmediateSrc(ImmediateSrc),
        .TargetSel(TargetSel),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .MemDataType(MemDataType),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2)
    );

    //Task to apply stimulus and check output
    task Control_Test;
        input         [31:0] instr;
        input         [2:0]  expALUOp;
        input                expMDSel;
        input         [2:0]  expImm;
        input         [3:0]  expTarget;
        input                expRegWrite;
        input                expMemRead;
        input                expMemWrite;
        input         [1:0]  expMemToReg;
        input         [2:0]  expMemData;
        input                expALUSrc1;
        input                expALUSrc2;
        input  integer       num;
        output integer       num_plus;
        output               result;
        
        begin
            Instr_RV32IM = instr;             
            
            
            #5;         //allowing combinational logic to settle
            
            num_plus = num + 1;
            $display("Test %0d: OpCode = %b | ALUOp=%b MDSel=%b Imm=%b Target=%b RW=%b MR=%b MW=%b M2R=%b MDT=%b A1=%b A2=%b",
                     num_plus, instr[6:0], ALUOp, MDSel, ImmediateSrc, TargetSel,
                     RegWrite, MemRead, MemWrite, MemToReg, MemDataType,
                     ALUSrc1, ALUSrc2);
                     
            $display("Expected: OpCode = %b | ALUOp=%b MDSel=%b Imm=%b Target=%b RW=%b MR=%b MW=%b M2R=%b MDT=%b A1=%b A2=%b",
                     instr[6:0], expALUOp, expMDSel, expImm, expTarget,
                     expRegWrite, expMemRead, expMemWrite, expMemToReg, expMemData,
                     expALUSrc1, expALUSrc2);
                     
            if (ALUOp!=expALUOp || MDSel!=expMDSel || ImmediateSrc!=expImm || TargetSel!=expTarget ||
                RegWrite!=expRegWrite || MemRead!=expMemRead || MemWrite!=expMemWrite ||
                MemToReg!=expMemToReg || MemDataType!=expMemData || ALUSrc1!=expALUSrc1 || ALUSrc2!=expALUSrc2)
            begin
                result = 0;
                $display("  Test FAILED!");
            end
            else begin
                result = 1;
                $display("  Test PASSED!");
            end
        end
        
    endtask



    //Stimulus - Full RV32IM
    initial begin
        i = 0;
        Instr_RV32IM = 32'h00000000;
        
        #20;
        
        $display("\n===== RV32IM Full Stress-Test =====\n");


        //R-TYPE (funct7 | rs2 | rs1 | funct3 | rd | opcode)
        //Base ALU
        Control_Test({7'b0000000,5'd10,5'd11,3'b000,5'd1,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // ADD     //1
        Control_Test({7'b0100000,5'd12,5'd13,3'b000,5'd2,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // SUB     //2
        Control_Test({7'b0000000,5'd14,5'd15,3'b001,5'd3,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // SLL     //3
        Control_Test({7'b0000000,5'd16,5'd17,3'b010,5'd4,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // SLT     //4
        Control_Test({7'b0000000,5'd18,5'd19,3'b011,5'd5,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // SLTU    //5    
        Control_Test({7'b0000000,5'd20,5'd21,3'b100,5'd6,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // XOR     //6
        Control_Test({7'b0000000,5'd22,5'd23,3'b101,5'd7,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // SRL     //7
        Control_Test({7'b0100000,5'd24,5'd25,3'b101,5'd8,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // SRA     //8
        Control_Test({7'b0000000,5'd26,5'd27,3'b110,5'd9,`OPCODE_RTYPE}, `ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // OR      //9
        Control_Test({7'b0000000,5'd28,5'd29,3'b111,5'd10,`OPCODE_RTYPE},`ALUOP_RTYPE,0,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // AND     //10

        //RV32M Extension (funct7 = 0000001)
        Control_Test({7'b0000001,5'd1,5'd2,3'b000,5'd11,`OPCODE_RTYPE}, `ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // MUL       //11
        Control_Test({7'b0000001,5'd3,5'd4,3'b001,5'd12,`OPCODE_RTYPE}, `ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // MULH      //12
        Control_Test({7'b0000001,5'd5,5'd6,3'b011,5'd13,`OPCODE_RTYPE}, `ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // MULHU     //13
        Control_Test({7'b0000001,5'd7,5'd8,3'b010,5'd14,`OPCODE_RTYPE}, `ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // MULHSU    //14
        Control_Test({7'b0000001,5'd9,5'd10,3'b100,5'd15,`OPCODE_RTYPE},`ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // DIV       //15
        Control_Test({7'b0000001,5'd11,5'd12,3'b101,5'd16,`OPCODE_RTYPE},`ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // DIVU     //16
        Control_Test({7'b0000001,5'd13,5'd14,3'b110,5'd17,`OPCODE_RTYPE},`ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // REM      //17
        Control_Test({7'b0000001,5'd15,5'd16,3'b111,5'd18,`OPCODE_RTYPE},`ALUOP_RMUL,1,`IMM_NONE,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,0, i, i, Result_Check); // REMU     //18



        //I-TYPE  (imm[11:0] | rs1 | funct3 | rd | opcode)
        //Base ALU
        Control_Test({12'h111,5'd3,3'b000,5'd19,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // ADDI                //19
        Control_Test({12'h222,5'd4,3'b110,5'd20,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // ORI                 //20
        Control_Test({12'h333,5'd5,3'b100,5'd21,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // XORI                //21
        Control_Test({7'b0000000,5'd20, 5'd6,3'b001,5'd22,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // SLLI      //22
        Control_Test({7'b0000000,5'd12, 5'd7,3'b101,5'd23,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // SRLI      //23
        Control_Test({7'b0100000,5'd31, 5'd8,3'b101,5'd24,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // SRAI      //24
        Control_Test({12'h444,5'd9,3'b010,5'd25,`OPCODE_ITYPE}, `ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // SLTI                //25
        Control_Test({12'h555,5'd10,3'b011,5'd26,`OPCODE_ITYPE},`ALUOP_ITYPE,0,`IMM_I,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // SLTIU               //26

        //Loads
        Control_Test({12'h010,5'd11,3'b010,5'd27,`OPCODE_LOAD}, `ALUOP_LSJ,0,`IMM_I,`TR_NOP,1,1,0,2'b01,`MEM_WORD,0,1, i, i, Result_Check); // LW                       //27
        Control_Test({12'h020,5'd12,3'b001,5'd28,`OPCODE_LOAD}, `ALUOP_LSJ,0,`IMM_I,`TR_NOP,1,1,0,2'b01,`MEM_HALF_SIGNED,0,1, i, i, Result_Check); // LH                //28
        Control_Test({12'h030,5'd13,3'b000,5'd29,`OPCODE_LOAD}, `ALUOP_LSJ,0,`IMM_I,`TR_NOP,1,1,0,2'b01,`MEM_BYTE_SIGNED,0,1, i, i, Result_Check); // LB                //29

        //JALR
        Control_Test({12'h060,5'd14,3'b000,5'd30,`OPCODE_JALR}, `ALUOP_LSJ,0,`IMM_I,`UJ_ALR,1,0,0,2'b10,`MEM_INVALID,0,1, i, i, Result_Check); //JALR                   //30



        //S-TYPE (imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode)
        Control_Test({7'h12,5'd15,5'd16,3'b010,5'd17,`OPCODE_STORE}, `ALUOP_LSJ,0,`IMM_S,`TR_NOP,0,0,1,2'bxx,`MEM_WORD,0,1, i, i, Result_Check); // SW                  //31
        Control_Test({7'h13,5'd18,5'd19,3'b001,5'd20,`OPCODE_STORE}, `ALUOP_LSJ,0,`IMM_S,`TR_NOP,0,0,1,2'bxx,`MEM_HALF_SIGNED,0,1, i, i, Result_Check); // SH           //32
        Control_Test({7'h14,5'd21,5'd22,3'b000,5'd23,`OPCODE_STORE}, `ALUOP_LSJ,0,`IMM_S,`TR_NOP,0,0,1,2'bxx,`MEM_BYTE_SIGNED,0,1, i, i, Result_Check); // SB           //33



        //B-TYPE (imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode)
        Control_Test({7'h15,5'd24,5'd25,3'b000,5'h10,`OPCODE_BRANCH}, `ALUOP_BRANCH,0,`IMM_B,`BR_EQ,0,0,0,2'bxx,`MEM_INVALID,0,0, i, i, Result_Check); // BEQ           //34
        Control_Test({7'h17,5'd26,5'd27,3'b001,5'h12,`OPCODE_BRANCH}, `ALUOP_BRANCH,0,`IMM_B,`BR_NE,0,0,0,2'bxx,`MEM_INVALID,0,0, i, i, Result_Check); // BNE           //35
        Control_Test({7'h19,5'd28,5'd29,3'b100,5'h14,`OPCODE_BRANCH}, `ALUOP_BRANCH,0,`IMM_B,`BR_LT,0,0,0,2'bxx,`MEM_INVALID,0,0, i, i, Result_Check); // BLT           //36
        Control_Test({7'h21,5'd30,5'd1, 3'b101,5'h16,`OPCODE_BRANCH}, `ALUOP_BRANCH,0,`IMM_B,`BR_GE,0,0,0,2'bxx,`MEM_INVALID,0,0, i, i, Result_Check); // BGE           //37
        Control_Test({7'h23,5'd2, 5'd3, 3'b110,5'h18,`OPCODE_BRANCH}, `ALUOP_BRANCH,0,`IMM_B,`BR_LTU,0,0,0,2'bxx,`MEM_INVALID,0,0, i, i, Result_Check); // BLTU         //38
        Control_Test({7'h25,5'd4, 5'd5, 3'b111,5'h1A,`OPCODE_BRANCH}, `ALUOP_BRANCH,0,`IMM_B,`BR_GEU,0,0,0,2'bxx,`MEM_INVALID,0,0, i, i, Result_Check); // BGEU         //39



        //U-TYPE (imm[31:12] | rd | opcode)
        Control_Test({20'hABCDE,5'd6,`OPCODE_LUI},   `ALUOP_UTYPE,0,`IMM_U,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,0,1, i, i, Result_Check); // LUI                            //40
        Control_Test({20'h54321,5'd7,`OPCODE_AUIPC}, `ALUOP_UTYPE,0,`IMM_U,`TR_NOP,1,0,0,2'b00,`MEM_INVALID,1,1, i, i, Result_Check); // AUIPC                          //41



        //J-TYPE (imm[20|10:1|11|19:12] | rd | opcode)
        Control_Test({20'hABCDE,5'd8,`OPCODE_JAL},  `ALUOP_JUMP,0,`IMM_J,`UJ_AL,1,0,0,2'b10,`MEM_INVALID,1,1, i, i, Result_Check); // JAL                               //42
        
        #10;
        
        $display("\n===== All RV32IM Tests Complete =====\n");
        $finish;
    end

endmodule
