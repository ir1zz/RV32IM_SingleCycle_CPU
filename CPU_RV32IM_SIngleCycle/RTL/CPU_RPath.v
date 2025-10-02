/*
* Module: CPU_RV32IM_1cyc.v
* Description: Top-level RV32IM Single-Cycle CPU integrating all datapath and control modules 
*              for the R-Type datapath (arithmetic and M-type instructions).
*
* Author: Aashrith S Narayn
* Date: 30/09/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

module CPU_RPath #(
    parameter DATA_WIDTH   = 32,
    parameter PC_WIDTH     = 32,
    parameter PC_STEP      = 4,
    parameter INSTR_WIDTH  = 32,
    parameter REG_COUNT    = 32,
    parameter IMEM_DEPTH   = 256
    )(
    
    //CPU Inputs
    input  wire                   CPU_PCWrite,
    input  wire                   CPU_clk,
    input  wire                   CPU_rst_n,
    
    //Main Debug Outputs
    output wire [PC_WIDTH-1:0]    CPU_PC,
    output wire [INSTR_WIDTH-1:0] CPU_Instr_RV32IM,
    output wire [5:0]             CPU_ALUControl,
    output wire [DATA_WIDTH-1:0]  CPU_ALUResult,
    output wire                   CPU_Zero,
    output wire [DATA_WIDTH-1:0]  CPU_Op1,CPU_Op2,
    
    //Control Signals
    output wire [2:0]             CPU_ALUOp,
    output wire                   CPU_MDSel,
    output wire                   CPU_RegWrite,
    output wire                   CPU_ALUSrc1, CPU_ALUSrc2   
    
    );
    
        
    //----------------------------------------------------------------------------------
    //All connecting wires between R-Type modules
    //----------------------------------------------------------------------------------
    
    //PC
    wire [PC_WIDTH-1:0]    PC;                //ProgCount --> IMEM, PCAdd, ALUInputSel
    
    //IMEM
    wire [INSTR_WIDTH-1:0] Instr_RV32IM;      //IMEM --> RegFile, Control
    
    //PCAdd
    wire [PC_WIDTH-1:0]    PC_Plus_4;         //PCAdd --> ProgCount
    
    //RegFile
    wire [DATA_WIDTH-1:0]  Rs1Data, Rs2Data;  //RegFile --> ALUInputSel
    
    //Control
    wire [2:0]             ALUOp;             //Control --> ALUCtrlGen
    wire                   MDSel;             //Control --> ALU_I, ALU_M, ALUSelMux
    wire [2:0]             ImmediateSrc;      //Control --> placeholder
    wire [3:0]             TargetSel;         //Control --> placeholder
    wire                   RegWrite;          //Control --> RegFile
    wire                   MemRead;           //Control --> placeholder
    wire                   MemWrite;          //Control --> placeholder
    wire [1:0]             MemToReg;          //Control --> placeholder
    wire [2:0]             MemDataType;       //Control --> placeholder
    wire                   ALUSrc1,ALUSrc2;   //Control --> ALUInputSel
    
    //ALUInputSel
    wire [DATA_WIDTH-1:0]  Op1, Op2;          //ALUInputSel --> ALU_I, ALU_M
    
    //ALUCtrlGen
    wire [5:0]             ALUControl;        //ALUCtrlGen --> ALU_I, ALU_M
    
    //ALU_I
    wire [DATA_WIDTH-1:0]  ALUResult_I;       //ALU_I --> ALUSelMux
    wire                   Zero_I;            //ALU_I --> ALUSelMux
    
    //ALU_M
    wire [DATA_WIDTH-1:0]  ALUResult_M;       //ALU_M --> ALUSelMux
    wire                   Zero_M;            //ALU_M --> ALUSelMux
    
    
    //ALUSelMux
    wire [DATA_WIDTH-1:0]  ALUResult;         //ALUSelMux --> RegFile
    wire                   Zero;              //ALUSelMux --> placeholder
    
        
        
    //----------------------------------------------------------------------------------
    //R-Type Datapath and Controlpath Modules
    //----------------------------------------------------------------------------------
        
    //----------------------------------
    //Module 1
    //Program Counter
    //----------------------------------   
    //(* keep_hierarchy = "yes" *)
    Program_Counter #(
        .PC_WIDTH(PC_WIDTH),
        .PC_STEP(PC_STEP)
        )
    CPU_ProgCount (
        .PC_Next(PC_Next),
        .CPU_clk(CPU_clk),
        .CPU_rst_n(CPU_rst_n),
        .PCWrite(CPU_PCWrite),
        .PC(PC)
    );
    
    
    //--------------------------------
    //Module 2
    //Instruction Memory (IMEM)
    //--------------------------------  
    //(* keep_hierarchy = "yes" *) 
    Instruction_Memory #(
        .PC_WIDTH(PC_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH),
        .IMEM_DEPTH(IMEM_DEPTH)
        )
    CPU_IMEM (
        .PC(PC),
        .Instr_RV32IM(Instr_RV32IM)
        );
    
        
    //--------------------------------
    //Module 3
    //PC Incrementer
    //-------------------------------- 
    //(* keep_hierarchy = "yes" *)  
    PC_Incrementer #(
        .PC_WIDTH(PC_WIDTH),
        .PC_STEP(PC_STEP)
        )
    CPU_PCAdd (
        .PC(PC),
        .PC_Plus_4(PC_Plus_4)
        );
        
    
    //-------------------------------
    //Module 4
    //Register File
    //-------------------------------  
    //(* keep_hierarchy = "yes" *)   
    Register_File #(
        .WIDTH(DATA_WIDTH),
        .REG_COUNT(REG_COUNT)
        )
    CPU_RegFile (
        .CPU_clk(CPU_clk),
        .CPU_rst_n(CPU_rst_n),
        .RegWrite(RegWrite),
        .Rs1Addr(Instr_RV32IM[19:15]),
        .Rs2Addr(Instr_RV32IM[24:20]),
        .RdAddr(Instr_RV32IM[11:7]),
        .WriteData(ALUResult),
        .Rs1Data(Rs1Data),
        .Rs2Data(Rs2Data)
        );
     
        
    //-----------------------------
    //Module 5
    //Control Unit
    //-----------------------------    
    //(* keep_hierarchy = "yes" *)  
    Control_Unit #(
        .WIDTH(DATA_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH)
        )
    CPU_Control (
        .Instr_RV32IM(Instr_RV32IM),
        .ALUOp(ALUOp),
        .ImmediateSrc(ImmediateSrc),
        .TargetSel(TargetSel),
        .MDSel(MDSel),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MemToReg(MemToReg),
        .MemDataType(MemDataType),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2)
        );
     
        
    //-----------------------------
    //Module 6
    //ALU Input Selector
    //-----------------------------   
    //(* keep_hierarchy = "yes" *)
    ALU_Input_Selector #(
        .WIDTH(DATA_WIDTH),
        .PC_WIDTH(PC_WIDTH)
        )
    CPU_ALUInputSel (
        .Rs1Data(Rs1Data),
        .Rs2Data(Rs2Data),
        .PC(PC),
        .Immediate(32'h00000000),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .Op1(Op1),
        .Op2(Op2)
        );
     
        
    //-----------------------------
    //Module 7
    //ALU Control Generator
    //-----------------------------    
    //(* keep_hierarchy = "yes" *)
    ALUControl_Gen #(
        .WIDTH(DATA_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH)
        )
    CPU_ALUCtrlGen (
        .ALUOp(ALUOp),
        .Instr_RV32IM(Instr_RV32IM),
        .ALUControl(ALUControl)
        );
        
        
    //----------------------------
    //Module 8
    //ALU for RV32I
    //----------------------------    
    //(* keep_hierarchy = "yes" *)
    ALU_RV32I #(
        .WIDTH(DATA_WIDTH)
        )
    CPU_ALU_I (
        .Op1(Op1),
        .Op2(Op2),
        .ALUControl(ALUControl),
        .MDSel(MDSel),
        .ALUResult_I(ALUResult_I),
        .Zero_I(Zero_I)
        );
      
     
    //----------------------------
    //Module 9
    //ALU for RV32M
    //----------------------------    
    //(* keep_hierarchy = "yes" *)
    ALU_RV32M #(
        .WIDTH(DATA_WIDTH)
        )
    CPU_ALU_M (
        .Op1(Op1),
        .Op2(Op2),
        .ALUControl(ALUControl),
        .MDSel(MDSel),
        .ALUResult_M(ALUResult_M),
        .Zero_M(Zero_M)
        );  
 
      
    //----------------------------
    //Module 10
    //ALU Selector Mux
    //----------------------------
    //(* keep_hierarchy = "yes" *)
    ALUSelect_Mux #(
        .WIDTH(DATA_WIDTH)
        )
    CPU_ALUSelMux (
        .ALUResult_I(ALUResult_I),
        .ALUResult_M(ALUResult_M),
        .Zero_I(Zero_I),
        .Zero_M(Zero_M),
        .MDSel(MDSel),
        .ALUResult(ALUResult),
        .Zero(Zero)
        );
        
             
    //----------------------------------------------------------------------------------
    //Module Output Assignments from wires (may be removed after simulation)
    //----------------------------------------------------------------------------------
    
    //Main output assignments
    assign CPU_PC            = PC;
    assign CPU_Instr_RV32IM  = Instr_RV32IM;
    assign CPU_ALUControl    = ALUControl;
    assign CPU_ALUResult     = ALUResult;
    assign CPU_Zero          = Zero;
    assign CPU_Op1           = Op1;
    assign CPU_Op2           = Op2;

    
    //Control signal assignments
    assign CPU_ALUOp         = ALUOp;
    assign CPU_MDSel         = MDSel;
    assign CPU_RegWrite      = RegWrite;
    assign CPU_ALUSrc1       = ALUSrc1;
    assign CPU_ALUSrc2       = ALUSrc2;  
  
endmodule
