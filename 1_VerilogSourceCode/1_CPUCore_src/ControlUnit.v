`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB (Embeded System Lab)
// Engineer: Haojun Xia
// Create Date: 2019/02/08
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////
`include "Parameters.v"   
module ControlUnit(
    input wire [6:0] Op,
    input wire [2:0] Fn3,
    input wire [6:0] Fn7,
    //output wire JalD,
    output reg JalD,
    //output wire JalrD,
    output reg JalrD,
    output reg [2:0] RegWriteD,
    //output wire MemToRegD,
    output reg MemToRegD,
    output reg [3:0] MemWriteD,
    //output wire LoadNpcD,
    output reg LoadNpcD,
    output reg [1:0] RegReadD,
    output reg [2:0] BranchTypeD,
    output reg [3:0] AluContrlD,
    //output wire [1:0] AluSrc2D,
    output reg [1:0] AluSrc2D,
    //output wire AluSrc1D,
    output reg AluSrc1D,
    output reg [2:0] ImmType        
    );
    
    initial begin
        RegWriteD = 3'b0;
        MemWriteD = 4'b0;
        RegReadD = 2'b0;
        BranchTypeD = 3'b0;
        AluContrlD = 4'b0;

        JalD = 0;
        JalrD = 0;
        MemToRegD = 0;
        LoadNpcD = 0;
    end
    
    always@(*) begin
        case(Op) 
            `JL: begin
                JalD <= 1;
                JalrD <= 0;
                LoadNpcD <= 1;        
            end
            `JLR: begin
                JalD <= 0;
                JalrD <= 1;
                LoadNpcD <= 1;   
            end
            default: begin
                JalD <= 0;
                JalrD <= 0;
                LoadNpcD <= 0;    
            end
        endcase
    end
    
    always@(*) begin
        if(Op == `BR) begin
            case(Fn3)
                3'b000: BranchTypeD <= `BEQ;
                3'b001: BranchTypeD <= `BNE;
                3'b100: BranchTypeD <= `BLT;
                3'b101: BranchTypeD <= `BGE;
                3'b110: BranchTypeD <= `BLTU;
                3'b111: BranchTypeD <= `BGEU;
                default:BranchTypeD <= `NOBRANCH;
            endcase
        end
        else
            BranchTypeD <= `NOBRANCH;
    end

    always@(*) begin
        case(Op)
            `NIMM:  RegWriteD <= `LW;
            `IMM:   RegWriteD <= `LW;
            `LUIOP: RegWriteD <= `LW; 
            `AUIPC: RegWriteD <= `LW;
            `LD:    begin
                    case(Fn3)
                        3'b000: RegWriteD <= `LB;
                        3'b001: RegWriteD <= `LH;
                        3'b010: RegWriteD <= `LW;
                        3'b100: RegWriteD <= `LBU;
                        3'b101: RegWriteD <= `LHU;
                    endcase
            end
            `ST:    RegWriteD <= `NOREGWRITE;
            `BR:    RegWriteD <= `NOREGWRITE; 
            `JL:    RegWriteD <= `LW;
            `JLR:   RegWriteD <= `LW;
            default:RegWriteD <= `NOREGWRITE;
        endcase
    end

    always@(*) begin
        if(Op == `ST) begin
            case(Fn3)
            3'b000: MemWriteD <= 4'b0001;
            3'b001: MemWriteD <= 4'b0011;
            3'b010: MemWriteD <= 4'b1111;
            default:MemWriteD <= 4'b0000;
            endcase
        end
        else    
            MemWriteD <= 4'b0000;
    end

    always@(*) begin
        if(Op == `IMM || Op == `NIMM) begin
            case(Fn3)
                3'b000: begin
                    if(Op == `NIMM && Fn7 == 7'b0100000)
                        AluContrlD <= `SUB;
                    else
                        AluContrlD <= `ADD;
                end
                3'b100: AluContrlD <= `XOR;
                3'b110: AluContrlD <= `OR;
                3'b111: AluContrlD <= `AND;
                3'b001: AluContrlD <= `SLL;
                3'b101: begin
                    if(Fn7 == 7'b0000000)
                        AluContrlD <= `SRL;
                    else
                        AluContrlD <= `SRA;
                end
                3'b010: AluContrlD <= `SLT;
                3'b011: AluContrlD <= `SLTU;
                default
                    AluContrlD <= 4'hx;
            endcase
            end
            else if(Op == `LUIOP)
                AluContrlD <= `LUI;
            else
                AluContrlD <= `ADD;
    end

    always@(*) begin
        case(Op)
            `NIMM:  begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b00;
            end
            `IMM:   begin
                AluSrc1D <= 1'b0;
                if(Fn3 == 3'b101 || Fn3 == 3'b001)
                    AluSrc2D <= 2'b01;
                else
                    AluSrc2D <= 2'b10;
            end
            `LUIOP: begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b10;
            end
            `AUIPC: begin
                AluSrc1D <= 1'b1;
                AluSrc2D <= 2'b10;
            end
            `LD:    begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b10;
            end
            `ST:    begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b10;
            end
            `BR:    begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b00;
            end
            `JL:    begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b00;
            end
            `JLR:   begin
                AluSrc1D <= 1'b0;
                AluSrc2D <= 2'b10;
            end
        endcase
    end

    always@(*) begin
        if(Op == `LD)
            MemToRegD <= 1'b1;
        else
            MemToRegD <= 1'b0;
    end
    
    always@(*) begin
        case(Op)
            `NIMM:  ImmType <= `RTYPE;
            `IMM:   ImmType <= `ITYPE;
            `LUIOP: ImmType <= `UTYPE;
            `AUIPC: ImmType <= `UTYPE;
            `LD:    ImmType <= `ITYPE;
            `ST:    ImmType <= `STYPE;
            `BR:    ImmType <= `BTYPE;
            `JL:    ImmType <= `JTYPE;
            `JLR:   ImmType <= `ITYPE;
        endcase
    end

    always@(*) begin
        case(Op)
            `NIMM:  RegReadD <= 2'b11;
            `IMM:   RegReadD <= 2'b10;
            `LUIOP: RegReadD <= 2'b00; 
            `AUIPC: RegReadD <= 2'b00;
            `LD:    RegReadD <= 2'b10;
            `ST:    RegReadD <= 2'b11;
            `BR:    RegReadD <= 2'b11; 
            `JL:    RegReadD <= 2'b00; 
            `JLR:   RegReadD <= 2'b10; 
        endcase
    end
endmodule

//功能说明
    //ControlUnit       是本CPU的指令译码器，组合�?�辑电路
//输入
    // Op               是指令的操作码部�??
    // Fn3              是指令的func3部分
    // Fn7              是指令的func7部分
//输出
    // JalD==1          表示Jal指令到达ID译码阶段
    // JalrD==1         表示Jalr指令到达ID译码阶段
    // RegWriteD        表示ID阶段的指令对应的 寄存器写入模�?? ，所有模式定义在Parameters.v�??
    // MemToRegD==1     表示ID阶段的指令需要将data memory读取的�?�写入寄存器,
    // MemWriteD        �??4bit，采用独热码格式，对于data memory�??32bit字按byte进行写入,MemWriteD=0001表示只写入最�??1个byte，和xilinx bram的接口类�??
    // LoadNpcD==1      表示将NextPC输出到ResultM
    // RegReadD[1]==1   表示A1对应的寄存器值被使用到了，RegReadD[0]==1表示A2对应的寄存器值被使用到了，用于forward的处�??
    // BranchTypeD      表示不同的分支类型，�??有类型定义在Parameters.v�??
    // AluContrlD       表示不同的ALU计算功能，所有类型定义在Parameters.v�??
    // AluSrc2D         表示Alu输入�??2的�?�择
    // AluSrc1D         表示Alu输入�??1的�?�择
    // ImmType          表示指令的立即数格式，所有类型定义在Parameters.v�??   
//实验要求  
    //实现ControlUnit模块   