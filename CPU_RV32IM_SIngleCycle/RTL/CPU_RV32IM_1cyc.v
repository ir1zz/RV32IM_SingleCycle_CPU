/*
* Module: CPU_RV32IM_1cyc.v
* Description: Top-level RV32IM Single-Cycle CPU integrating all datapath and control modules,
*              with separate ALUs for RV32I and RV32M operations. Performs complete instruction
*              execution in a single cycle. Completely parametrized with hardware for expansion
*              into 5-stage pipelined implementation. Modules follow Pascal Case nomenclature
* 
* Resume: Designed and implemented a fully modular single-cycle CPU supporting the 
*         RV32IM ISA with separate ALUs for integer and multiplication/division operations. 
*         Developed 16 parameterized RTL modules including instruction decode, immediate
*         generator, memory subsystems, and custom control logic. Demonstrated 100% 
*         functional coverage across 40+ RV32I/M instructions and verified using 
*         waveform-driven testbenches and exposed debug ports for integration and 
*         visualization. Architecture designed to scale toward 5-stage pipelined 
*         implementation.
*
* Author: Aashrith S Narayn
* Date: 13/07/2025
*/

`timescale 1ns / 1ps
`include "CPU_Control_Codes.vh"

module CPU_RV32IM_1cyc #(
    parameter DATA_WIDTH   = 32,
    parameter PC_WIDTH     = 32,
    parameter PC_STEP      = 4,
    parameter INSTR_WIDTH  = 32,
    parameter REG_COUNT    = 32,
    parameter IMEM_DEPTH   = 256,
    parameter DMEM_DEPTH   = 512
    )(
    
    //CPU Inputs
    input  wire                   CPU_PCWrite,
    input  wire                   CPU_clk,
    input  wire                   CPU_rst_n,
    
    //Main Debug Outputs
    output wire [PC_WIDTH-1:0]    CPU_PC,
    output wire [INSTR_WIDTH-1:0] CPU_Instr_RV32IM,
    output wire [DATA_WIDTH-1:0]  CPU_Immediate,
    output wire [5:0]             CPU_ALUControl,
    output wire [DATA_WIDTH-1:0]  CPU_ALUResult,
    output wire                   CPU_Zero,
    output wire [DATA_WIDTH-1:0]  CPU_ReadData,
    output wire [DATA_WIDTH-1:0]  CPU_WriteDataReg,
    
    //Control Signals
    output wire [2:0]             CPU_ALUOp,
    output wire                   CPU_MDSel,
    output wire [2:0]             CPU_ImmediateSrc,
    output wire [2:0]             CPU_TargetSel,
    output wire                   CPU_RegWrite,
    output wire                   CPU_MemRead,
    output wire                   CPU_MemWrite,
    output wire [1:0]             CPU_MemToReg,
    output wire [2:0]             CPU_MemDataType,
    output wire                   CPU_ALUSrc1, CPU_ALUSrc2,
    output wire                   CPU_PCSrc
    
    );
    
    
    //----------------------------------------------------------------------------------
    //All connecting wires between the 16 CPU Modules
    //----------------------------------------------------------------------------------
    
    //PC
    wire [PC_WIDTH-1:0]    PC;                //ProgCount --> IMEM, PCAdd, ALUInputSel, BrTargetGen
    
    //IMEM
    wire [INSTR_WIDTH-1:0] Instr_RV32IM;      //IMEM --> RegFile, ImmGen, Control
    
    //PCAdd
    wire [PC_WIDTH-1:0]    PC_Plus_4;         //PCAdd --> NextPCMux, WrBackMux, UjTargetGen
    
    //RegFile
    wire [DATA_WIDTH-1:0]  Rs1Data, Rs2Data;  //RegFile --> ALUInputSel, DMEM(Rs2Data)
    
    //Imm Gen
    wire [DATA_WIDTH-1:0]  Immediate;         //Imm Gen --> ALUInputSel, BrTargetGen
    
    //Control
    wire [2:0]             ALUOp;             //Control --> ALUCtrlGen
    wire                   MDSel;             //Control --> ALU_I, ALU_M, ALUSelMux
    wire [2:0]             ImmediateSrc;      //Control --> ImmGen
    wire [3:0]             TargetSel;         //Control --> TrCtrl, UjTargetGen
    wire                   RegWrite;          //Control --> RegFile
    wire                   MemRead;           //Control --> DMEM
    wire                   MemWrite;          //Control --> DMEM
    wire [1:0]             MemToReg;          //Control --> WrBackMux
    wire [2:0]             MemDataType;       //Control --> DMEM
    wire                   ALUSrc1,ALUSrc2;   //Control --> ALUInputSel
    
    //ALUInputSel
    wire [DATA_WIDTH-1:0]  Op1, Op2;          //ALUInputSel --> ALU_I, ALU_M
    
    //ALUCtrlGen
    wire [5:0]             ALUControl;        //ALUCtrlGen --> ALU_I, ALU_M
    
    //BrTargetGen
    wire [PC_WIDTH-1:0]    BranchTarget;      //BrTargetGen --> NextPCMux
    
    //ALU_I
    wire [DATA_WIDTH-1:0]  ALUResult_I;       //ALU_I --> ALUSelMux
    wire                   Zero_I;            //ALU_I --> ALUSelMux
    
    //ALU_M
    wire [DATA_WIDTH-1:0]  ALUResult_M;       //ALU_M --> ALUSelMux
    wire                   Zero_M;            //ALU_M --> ALUSelMux
    
    //TrCtrl
    wire [1:0]             PCSrc;             //TrCtrl --> NextPCMux
    
    //ALUSelMux
    wire [DATA_WIDTH-1:0]  ALUResult;         //ALUSelMux --> DMEM, WrBackMux, NextPCMux, UjTargetGen
    wire                   Zero;              //ALUSelMux --> TrCtrl
    
    //UjTargetGen
    wire [DATA_WIDTH-1:0]  JumpTarget;        //UjTargetGen --> NextPCMux
    
    //DMEM
    wire [DATA_WIDTH-1:0]  ReadData;          //DMEM --> WrBackMux
    
    //WrBackMux
    wire [DATA_WIDTH-1:0]  WriteDataReg;      //WrBackMux --> RegFile
    
    //NextPCMux
    wire [PC_WIDTH-1:0]    PC_Next;           //NextPCMux --> ProgCount
        
        
        
        
        
    //----------------------------------------------------------------------------------
    //All CPU Modules (16 total)
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
        .WriteData(WriteDataReg),
        .Rs1Data(Rs1Data),
        .Rs2Data(Rs2Data)
        );
     
    
    //------------------------------
    //Module 5
    //Immediate Generator
    //------------------------------   
    //(* keep_hierarchy = "yes" *)
    Imm_Gen #(
        .WIDTH(DATA_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH)
        )   
     CPU_ImmGen (    
        .Instr_RV32IM(Instr_RV32IM),
        .ImmediateSrc(ImmediateSrc),
        .Immediate(Immediate)
        );
      
        
    //-----------------------------
    //Module 6
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
    //Module 7
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
        .Immediate(Immediate),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .Op1(Op1),
        .Op2(Op2)
        );
     
        
    //-----------------------------
    //Module 8
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
    //Module 9
    //Branch Target Generator
    //----------------------------    
    //(* keep_hierarchy = "yes" *)
    Branch_Target_Gen #(
        .WIDTH(DATA_WIDTH),
        .PC_WIDTH(PC_WIDTH)
        )
    CPU_BrTargetGen (
        .Immediate(Immediate),
        .PC(PC),
        .BranchTarget(BranchTarget)
        );
    
    
    //----------------------------
    //Module 10
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
    //Module 11
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
    //Module 12
    //Target Controller
    //----------------------------    
    //(* keep_hierarchy = "yes" *)
    Target_Controller #()
    CPU_TrCtrl (
        .TargetSel(TargetSel),
        .Zero(Zero),
        .PCSrc(PCSrc)
        );
    
    
    //----------------------------
    //Module 13
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
        
    
    //----------------------------
    //Module 14
    //Jump Target Generator
    //----------------------------
    //(* keep_hierarchy = "yes" *) 
    Jump_Target_Gen #(
        .WIDTH(DATA_WIDTH),
        .PC_WIDTH(PC_WIDTH)
        )
    CPU_UjTargetGen(
        .ALU_Result(ALUResult),
        .TargetSel(TargetSel),
        .PC_Plus_4(PC_Plus_4),
        .JumpTarget(JumpTarget)
        );   
        
        
    //----------------------------
    //Module 15
    //Data Memory (DMEM)
    //----------------------------   
    //(* keep_hierarchy = "yes" *)
    Data_Memory #(
        .WIDTH(DATA_WIDTH),
        .DMEM_DEPTH(DMEM_DEPTH)
        )
    CPU_DMEM (
        .CPU_clk(CPU_clk),
        .CPU_rst_n(CPU_rst_n),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MemDataType(MemDataType),
        .ALUResult_Addr(ALUResult),
        .WriteData(Rs2Data),
        .ReadData(ReadData)
        );


    //----------------------------
    //Module 16
    //Data WriteBack Mux
    //----------------------------   
    //(* keep_hierarchy = "yes" *)
    WriteBack_Mux #(
        .WIDTH(DATA_WIDTH),
        .PC_WIDTH(PC_WIDTH)
        )
    CPU_WrBackMux (
        .ALUResult(ALUResult),
        .ReadData(ReadData),
        .PC_Plus_4(PC_Plus_4),
        .MemToReg(MemToReg),
        .WriteData(WriteDataReg)
        );
     
        
    //---------------------------
    //Module 17
    //Next PC Mux
    //---------------------------    
    //(* keep_hierarchy = "yes" *)
    PC_Next_Mux #(
        .PC_WIDTH(PC_WIDTH),
        .WIDTH(DATA_WIDTH)
        )
    CPU_NextPCMux (
        .PC_Plus_4(PC_Plus_4),
        .BranchTarget(BranchTarget),
        .JumpTarget(JumpTarget),
        .PCSrc(PCSrc),
        .PC_Next(PC_Next)
        );
        
        
    
        
    //----------------------------------------------------------------------------------
    //Module Output Assignments from wires (may be removed after simulation)
    //----------------------------------------------------------------------------------
    
    //Main output assignments
    assign CPU_PC            = PC;
    assign CPU_Instr_RV32IM  = Instr_RV32IM;
    assign CPU_Immediate     = Immediate;
    assign CPU_ALUControl    = ALUControl;
    assign CPU_ALUResult     = ALUResult;
    assign CPU_Zero          = Zero;
    assign CPU_ReadData      = ReadData;
    assign CPU_WriteDataReg  = WriteDataReg;  
    
    //Control signal assignments
    assign CPU_ALUOp         = ALUOp;
    assign CPU_MDSel         = MDSel;
    assign CPU_ImmediateSrc  = ImmediateSrc;
    assign CPU_TargetSel     = TargetSel;
    assign CPU_RegWrite      = RegWrite;
    assign CPU_MemRead       = MemRead;
    assign CPU_MemWrite      = MemWrite;
    assign CPU_MemToReg      = MemToReg;
    assign CPU_MemDataType   = MemDataType;
    assign CPU_ALUSrc1       = ALUSrc1;
    assign CPU_ALUSrc2       = ALUSrc2;
    assign CPU_PCSrc         = PCSrc;

    
endmodule