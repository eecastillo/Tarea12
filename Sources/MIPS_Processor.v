

module MIPS_Processor
#(
	parameter MEMORY_DEPTH = 64,
	parameter PC_INCREMENT = 4,
	parameter jump_start   = 32'b11_1111_1111_0000_0000_0000_0000_0000_00,
	parameter RA = 31
	//parameter RAM_INCREMENT =
)

(
	// Inputs
	input clk,
	input reset,
	input [7:0] PortIn,
	// Output
	output [31:0] ALUResultOut,
	output [31:0] PortOut
);
//******************************************************************/
//******************************************************************/
assign  PortOut = 0;

//******************************************************************/
//******************************************************************/
// signals to connect modules
wire branch_ne_wire;
wire branch_eq_wire;
wire reg_dst_wire;
wire not_zero_and_brach_ne;
wire zero_and_brach_eq;
wire or_for_branch;
wire alu_src_wire;
wire reg_write_wire;
wire zero_wire;
wire wMemWrite;
wire wMemRead;

wire wJump;
wire wJump_R;
wire wJAL;
wire Branch_Analyzer_Result_wire;

wire [2:0] aluop_wire;
wire [3:0] alu_operation_wire;
wire [4:0] write_register_wire;
wire [4:0] jal2_result;
wire [31:0] mux_pc_wire;
wire [31:0] jal_result;
wire [31:0] pc_wire;
wire [31:0] instruction_bus_wire;
wire [31:0] read_data_1_wire;
wire [31:0] read_data_2_wire;
wire [31:0] Inmmediate_extend_wire;
wire [31:0] read_data_2_orr_inmmediate_wire;
wire [31:0] alu_result_wire;
wire [31:0] pc_plus_4_wire;
wire [31:0] inmmediate_extended_wire;
wire [31:0] pc_to_branch_wire;

wire [31:0] wReadData;
wire [31:0] wMemtoReg;
wire [31:0] wRamAluMux;

wire [31:0] wBranchAdder;
wire [31:0] PC_Puls_ShiftLeft_RESULT;
wire [31:0] MUX_ForPCSource_RESULT;
wire [31:0] PC_R;
wire [31:0] New_PC;
wire [27:0] Shift_wire;
wire [31:0] offset_Start;

wire [31:0] PipeID_instruction_bus_wire;
wire [31:0] PipeID_pc_plus_4_wire;

wire PipeEX_reg_write_wire;
wire PipeEX_branch_ne_wire;
wire PipeEX_branch_eq_wire;
wire [2:0] PipeEX_aluop_wire;
wire PipeEX_alu_src_wire;
wire PipeEX_wMemRead;
wire PipeEX_wMemtoReg;
wire PipeEX_wMemWrite;
wire [31:0] PipeEX_read_data_1_wire;
wire [31:0] PipeEX_read_data_2_wire;
wire [31:0] PipeEX_Inmmediate_extend_wire;
wire [31:0] PipeEX_instruction_bus_wire;
wire PipeEX_reg_dst_wire;

wire PipeMEM_reg_write_wire;
wire PipeMEM_wMemRead;
wire PipeMEM_wMemtoReg;
wire PipeMEM_wMemWrite;
wire [31:0] PipeMEM_instruction_bus_wire;
wire [31:0] PipeMEM_alu_result_wire;
wire [31:0] PipeMEM_read_data_2_wire;
wire [4:0] PipeMEM_write_register_wire;

wire PipeWB_reg_write_wire;
wire PipeWB_wMemtoReg;
wire [31:0] PipeWB_instruction_bus_wire;
wire [31:0] PipeWB_wReadData;
wire [31:0] PipeWB_alu_result_wire;
wire [4:0] PipeWB_write_register_wire;

//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
PC_Register
ProgramCounter
(
	.clk(clk),
	.reset(reset),
	.NewPC(New_PC),//PC_R
	.PCValue(pc_wire)
);

ProgramMemory
#(
	.MEMORY_DEPTH(MEMORY_DEPTH)
)
ROMProgramMemory
(
	.Address(pc_wire),
	.Instruction(instruction_bus_wire)
);

Adder32bits
PC_Puls_4
(
	.Data0(pc_wire),
	.Data1(PC_INCREMENT),
	
	.Result(pc_plus_4_wire)
);

//REGISTER PIPELINE IF_ID

PipelineRegister
#(
	.N(64),
	.start(0)
)
IF_ID_Pipeline(
	.clk(clk),
	.enable(1),
	.reset(reset),
	.DataInput({instruction_bus_wire,pc_plus_4_wire}),
	.DataOutput({PipeID_instruction_bus_wire,PipeID_pc_plus_4_wire})
	
);

//////////////////////////
ShiftLeft2
ShiftLeft
(
	.DataInput(PipeID_instruction_bus_wire[25:0]),
	.DataOutput(Shift_wire)
);
//////////////////////////
//////////////////////////

Control
ControlUnit
(
	.OP(PipeID_instruction_bus_wire[31:26]),//From Pipeline ID
	.FUN(PipeID_instruction_bus_wire[5:0]),//From Pipeline ID
	.RegDst(reg_dst_wire),
	.BranchNE(branch_ne_wire),
	.BranchEQ(branch_eq_wire),
	.ALUOp(aluop_wire),
	.ALUSrc(alu_src_wire),
	.RegWrite(reg_write_wire),
	.MemWrite(wMemWrite),
	.MemRead(wMemRead),
	.MemtoReg(wMemtoReg),
	.Jump(wJump),
	.Jump_R(wJump_R),
	.JAL(wJAL)
);

RegisterFile
Register_File
(
	.clk(clk),
	.reset(reset),
	.RegWrite(PipeWB_reg_write_wire),////From Pipeline WB
	.WriteRegister(PipeWB_write_register_wire),//From Pipeline WB
	.ReadRegister1(PipeID_instruction_bus_wire[25:21]),//From Pipeline ID
	.ReadRegister2(PipeID_instruction_bus_wire[20:16]),//From Pipeline ID
	.WriteData(wRamAluMux),
	.ReadData1(read_data_1_wire),
	.ReadData2(read_data_2_wire)

);

SignExtend
SignExtendForConstants
(   
	.DataInput(PipeID_instruction_bus_wire[15:0]),//From Pipeline ID
   .SignExtendOutput(Inmmediate_extend_wire)
);



////////REGISTER PIPELINE ID_EX

PipelineRegister
#(
	.N(139),
	.start(0)
)
ID_EX_Pipeline(
	.clk(clk),
	.enable(1),
	.reset(reset),
	.DataInput({reg_write_wire,branch_ne_wire,branch_eq_wire,aluop_wire,alu_src_wire,wMemRead,wMemtoReg,wMemWrite,read_data_1_wire,read_data_2_wire,Inmmediate_extend_wire,PipeID_instruction_bus_wire,reg_dst_wire}),
	.DataOutput({PipeEX_reg_write_wire,PipeEX_branch_ne_wire,PipeEX_branch_eq_wire,PipeEX_aluop_wire,PipeEX_alu_src_wire,PipeEX_wMemRead,PipeEX_wMemtoReg,PipeEX_wMemWrite,PipeEX_read_data_1_wire,PipeEX_read_data_2_wire,PipeEX_Inmmediate_extend_wire,PipeEX_instruction_bus_wire,PipeEX_reg_dst_wire})
	
);


/*
.RegDst(reg_dst_wire),
	.BranchNE(),
	.BranchEQ(),
	.ALUOp(),
	.ALUSrc(),
	.RegWrite(),
	.MemWrite(),
	.MemRead(),
	.MemtoReg(),
	.Jump(wJump),
	.Jump_R(wJump_R),			write_register_wire
	.JAL(wJAL)*/
////////////////////////////
////////////////////////////
////////////////////////////

Multiplexer2to1
#(
	.NBits(5)
)
MUX_ForRTypeAndIType
(
	.Selector(PipeEX_reg_dst_wire),//From Pipeline EX
	.MUX_Data0(PipeEX_instruction_bus_wire[20:16]),//From Pipeline EX
	.MUX_Data1(PipeEX_instruction_bus_wire[15:11]),//From Pipeline EX
	
	.MUX_Output(write_register_wire)

);


Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForReadDataAndInmediate
(
	.Selector(PipeEX_alu_src_wire),//From Pipeline EX
	.MUX_Data0(PipeEX_read_data_2_wire),//From Pipeline EX
	.MUX_Data1(PipeEX_Inmmediate_extend_wire),//From Pipeline EX
	
	.MUX_Output(read_data_2_orr_inmmediate_wire)

);

ALUControl
ArithmeticLogicUnitControl
(
	.ALUOp(PipeEX_aluop_wire),//From Pipeline EX
	.ALUFunction(PipeEX_instruction_bus_wire[5:0]),//From Pipeline EX
	.ALUOperation(alu_operation_wire)

);



ALU
ArithmeticLogicUnit 
(
	.shamt(PipeEX_instruction_bus_wire[10:6]),//From Pipeline EX
	.ALUOperation(alu_operation_wire),
	.A(PipeEX_read_data_1_wire),//From Pipeline EX
	.B(read_data_2_orr_inmmediate_wire),
	.Zero(zero_wire),
	.ALUResult(alu_result_wire)
);

assign ALUResultOut = alu_result_wire;

//////REGISTER PIPELINE EX_MEM

PipelineRegister
#(
	.N(105),
	.start(0)
)
EX_MEM_Pipeline(
	.clk(clk),
	.enable(1),
	.reset(reset),
	.DataInput({PipeEX_reg_write_wire,PipeEX_wMemRead,PipeEX_wMemtoReg,PipeEX_wMemWrite,PipeEX_instruction_bus_wire,alu_result_wire,PipeEX_read_data_2_wire,write_register_wire}),
	.DataOutput({PipeMEM_reg_write_wire,PipeMEM_wMemRead,PipeMEM_wMemtoReg,PipeMEM_wMemWrite,PipeMEM_instruction_bus_wire,PipeMEM_alu_result_wire,PipeMEM_read_data_2_wire,PipeMEM_write_register_wire})
	
);

//**********************/
//**********************/
//**********************/
//**********************/
//**********************/
DataMemory
#(	.DATA_WIDTH(32),
	.MEMORY_DEPTH(256)
)
RamMemory
(
	.WriteData(PipeMEM_read_data_2_wire),//From Pipeline MEM
	.Address(PipeMEM_alu_result_wire),//From Pipeline MEM
	.MemWrite(PipeMEM_wMemWrite),//From Pipeline MEM
	.MemRead(PipeMEM_wMemRead),//From Pipeline MEM
	.clk(clk),
	.ReadData(wReadData)
);

////////////////REGISTER PIPELINE MEM_WB
PipelineRegister
#(
	.N(103),
	.start(0)
)
MEM_WB_Pipeline(
	.clk(clk),
	.enable(1),
	.reset(reset),
	.DataInput({PipeMEM_reg_write_wire,PipeMEM_wMemtoReg,PipeMEM_instruction_bus_wire,wReadData,PipeMEM_alu_result_wire,PipeMEM_write_register_wire}),
	.DataOutput({PipeWB_reg_write_wire,PipeWB_wMemtoReg,PipeWB_instruction_bus_wire,PipeWB_wReadData,PipeWB_alu_result_wire,PipeWB_write_register_wire})
	
);

//**********************/
//**********************/
//**********************/
//**********************/
//**********************/
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForAluAndRamMemory
(
	.Selector(PipeWB_wMemtoReg),//From Pipeline WB
	.MUX_Data0(PipeWB_alu_result_wire),//From Pipeline WB
	.MUX_Data1(PipeWB_wReadData),//From Pipeline WB
	.MUX_Output(wRamAluMux)
);


/********************************************************************
******************************************************************
******************************************************************
******************************************************************
**************************************************************/
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForBranch
(
	.Selector(Branch_Analyzer_Result_wire),
	.MUX_Data0(pc_plus_4_wire),
	.MUX_Data1(PC_Puls_ShiftLeft_RESULT),
	
	.MUX_Output(MUX_ForPCSource_RESULT)
);
ShiftLeft2
ShiftLeft2_Branch(
	.DataInput(PipeEX_Inmmediate_extend_wire),
	.DataOutput(wBranchAdder)
);

Adder32bits
PC_Plus_ShiftLeft
(
	.Data0(pc_plus_4_wire),
	.Data1(wBranchAdder),
	
	.Result(PC_Puls_ShiftLeft_RESULT)
);

Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForJump
(
	.Selector(wJump),
	.MUX_Data0(MUX_ForPCSource_RESULT),
	.MUX_Data1(offset_Start),
	
	.MUX_Output(New_PC)
);
BranchesGates
BranchAnalyzer(
	.Branch(PipeEX_branch_eq_wire),
	.Branch_Not_Equal(PipeEX_branch_ne_wire),
	.zero(zero_wire),
	.PCSrc(Branch_Analyzer_Result_wire)
);

Adder32bits
ADD_ALU_OFFSET
(
	.Data0({pc_plus_4_wire[31:28],Shift_wire[27:0]}),
	.Data1(jump_start),
	.Result(offset_Start)
	
);
/*
******************************************************************
*****************************************************************
******************************************************************
*/


Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForJump_R
(
	.Selector(wJump_R),
	.MUX_Data0(New_PC),
	.MUX_Data1(PipeEX_read_data_1_wire),
	
	.MUX_Output(PC_R)
);

Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForJAL
(
	.Selector(wJAL),
	.MUX_Data0(wRamAluMux),
	.MUX_Data1(pc_plus_4_wire),
	
	.MUX_Output(jal_result)
);

Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForJAL_2
(
	.Selector(wJAL),
	.MUX_Data0(write_register_wire),
	.MUX_Data1(RA),
	
	.MUX_Output(jal2_result)
);



endmodule