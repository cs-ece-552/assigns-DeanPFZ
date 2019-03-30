/* $Author: karu $ */
/* $LastChangedDate: 2009-03-04 23:09:45 -0600 (Wed, 04 Mar 2009) $ */
/* $Rev: 45 $ */
module proc (/*AUTOARG*/
	// Outputs
	err,
	// Inputs
	clk, rst
	);

	//
	// Inputs
	//
	input clk;
	input rst;

	//
	// Outputs
	//
	output err;


	wire cntrlErr, rfErr;

	assign err = cntrlErr | rfErr;
	// None of the above lines can be modified

	// OR all the err ouputs for every sub-module and assign it as this
	// err output

	// As desribed in the homeworks, use the err signal to trap corner
	// cases that you think are illegal in your statemachines

	//
	// Fetch Signals
	//
	wire [15:0] ftch_pre_PC;
	wire [15:0] ftch_post_PC;
	wire ftch_HaltPC;
	wire [15:0] ftch_PC2_after;
	wire [15:0] ftch_PC2_back;
	wire CO_temp1, CO_temp2;


	wire [15:0] ftch_instruction;
	wire [15:0] ftch_PC2;

	//
	// Fetch/Decode Pipeline Reg Signals
	//
	wire [31:0] ftchOut;
	wire [31:0] decIn;
	wire ftchDecEn; 

	//
	// Decode Signals
	//
	wire [2:0] dec_Rs;
	wire [2:0] dec_Rt;
	wire [4:0] dec_Imm5;
	wire [7:0] dec_Imm8;
	wire [10:0] dec_ImmDis;

	wire [15:0] dec_instruction;
	wire [15:0] dec_PC2;
	wire dec_subtraction;

	//register file
	wire [2:0]  dec_readReg1Sel;
	wire [2:0]  dec_readReg2Sel;
	wire [2:0]  dec_writeRegSel;
	wire [15:0] dec_writeData;
	wire        dec_writeEn;
	wire [15:0] dec_readData1;
	wire [15:0] dec_readData2;

	//Control
	wire dec_cntrlErr;
	wire [1:0] dec_RegDst;
	wire dec_RegWrite;
	wire dec_DMemWrite;
	wire dec_DMemEn;
	wire dec_ALUSrc2;
	wire dec_PCImm;
	wire dec_MemToReg;
	wire dec_DMemDump;
	wire dec_Jump;
	wire dec_Set;
	wire [1:0] dec_SetOp;
	wire dec_Branch;
	wire [1:0] dec_BranchOp;
	wire dec_disp;
	wire dec_HaltPC;
	wire dec_BTR;
	wire dec_SLBI;
	wire dec_LBI;
	wire dec_link;
	wire [4:0] dec_OpCode;
	wire [1:0] dec_Funct;
	wire [2:0] dec_Op;
	wire dec_invA;
	wire dec_invB;
	wire dec_Cin;
	wire dec_sign;
	wire dec_rorSel;

	//
	// Execute Signals
	//

	wire exe_cntrlErr;
	wire [1:0] exe_RegDst;
	wire exe_RegWrite;
	wire exe_DMemWrite;
	wire exe_DMemEn;
	wire exe_ALUSrc2;
	wire exe_PCImm;
	wire exe_MemToReg;
	wire exe_DMemDump;
	wire exe_Jump;
	wire exe_Set;
	wire [1:0] exe_SetOp;
	wire exe_Branch;
	wire [1:0] exe_BranchOp;
	wire exe_disp;
	wire exe_HaltPC;
	wire exe_BTR;
	wire exe_SLBI;
	wire exe_LBI;
	wire exe_link;
	wire [4:0] exe_OpCode;
	wire [1:0] exe_Funct;
	wire [2:0] exe_Op;
	wire exe_invA;
	wire exe_invB;
	wire exe_Cin;
	wire exe_sign;
	wire exe_rorSel;
	wire [15:0] exe_PC2;

	wire [15:0] exe_readData1;
	wire [15:0] exe_readData2;

	wire [15:0] exe_Out;
	wire [15:0] exe_aluOut;
	wire [15:0] exe_A;
	wire [15:0] exe_B;
	wire exe_Ofl;
	wire exe_Zero;
	wire exe_subtraction;
	wire [2:0]exe_OutSel;
	wire [15:0] exe_mirr_rd1;
	wire exe_PCSrc;
	wire exe_Carry;
	wire exe_Neg;

	wire [15:0] exe_before_ROR;
	wire [15:0] exe_after_ROR;
	wire [15:0] exe_after_Branch;
	wire [15:0] exe_negReadData2;
	wire exe_ror_with_reg;
	wire [15:0] exe_ShiftLeftValue;
	wire CO_temp3, CO_temp4, CO_temp5;

	// PC
	wire [15:0] exe_after_disp;
	wire [15:0] exe_added;
	// TODO: Need to pipeline these signals below
	wire [15:0] exe_PC2_after;
	wire [15:0] exe_PC2_back;

	wire [63:0] exe_cntrl_out;

	//
	// Memory Signals
	//
	//memory (enable is DMemWrite, wr is DMemEn, addr is Addr[15:0])
	wire [31:0] mem_cntrl_in;
	wire [15:0] mem_Datain;
	wire mem_Createdump;

	wire [15:0] mem_Dataout;
	wire [15:0] mem_readData2;
	wire mem_HaltPC;
	wire mem_MemToReg;
	wire [15:0] mem_Out;
	wire mem_DMemEn;
	wire mem_DMemWrite;
	wire [4:0] mem_OpCode;
	wire [15:0] mem_PC2;
	wire [63:0] mem_cntrl_out;

	//
	// Write Back Signals
	//
	// TODO: Need to pipeline these signals
	wire [4:0] wb_OpCode;
	wire [15:0] wb_PC2;
	wire wb_MemToReg;
	wire [15:0] wb_Dataout;
	wire [15:0] wb_Out;

	//
	// PipeLine Register Enable Signals
	//

	wire ftchDecEn;
	wire decExeEn;
	wire exeMemEn;
	wire memWbEn;

	//
	// Fetch Logic
	//
	assign ftch_pre_PC[15:0] = ftch_HaltPC? ftch_post_PC : ftch_PC2_back;

	//PC Reg
	reg16 regPC(.q(ftch_post_PC[15:0]), .d(ftch_pre_PC[15:0]), .clk(clk), .rst(rst));

	// PC + 4 adder
	rca_16b add1(.A(ftch_post_PC[15:0]), .B(16'h0002), .C_in(1'b0),.S(ftch_PC2), .C_out(CO_temp1));


	//
	// Fetch/Decode Pipeline Reg
	//
 
	// TODO: Assign the enable signal
	assign ftchDecEn = 1'bz; 
 
	assign ftchOut = {ftch_instruction[15:0], ftch_PC2[15:0]};
	reg32_en fet_dec(.q(decIn), .d(ftchOut), .clk(clk), .rst(rst), .en(ftchDecEn));
	assign dec_P2C = decIn[15:0];
	assign dec_instruction = decIn[31:16];


	//
	// Decode Logic
	//
	assign dec_OpCode[4:0] = dec_instruction[15:11];
	assign dec_Funct[1:0] = dec_instruction[1:0];
	assign dec_Rs[2:0] = dec_instruction[10:8];
	assign dec_Rt[2:0] = dec_instruction[7:5];
	assign dec_Imm5[4:0] = dec_instruction[4:0];
	assign dec_Imm8[7:0] = dec_instruction[7:0];
	assign dec_ImmDis[10:0] = dec_instruction[10:0];

	// Subtraction signal
	assign dec_subtraction = exe_OpCode[4]&exe_OpCode[3]&~exe_OpCode[2]&exe_OpCode[1]
						&exe_OpCode[0]&~exe_Funct[1]&exe_Funct[0];

	//rf
	assign dec_writeRegSel[2:0] = (dec_OpCode[4:0] == 5'b10011)? dec_instruction[10:8] :
								(dec_RegDst[1:0] == 2'b00)? dec_instruction[4:2]:
								(dec_RegDst[1:0] == 2'b01)? dec_instruction[7:5]:
								(dec_RegDst[1:0] == 2'b10)? dec_instruction[10:8]:
								(dec_RegDst[1:0] == 2'b11)? 3'b111 : 3'b000; //3'b000 should never happen
	assign dec_readReg1Sel[2:0] = dec_subtraction? dec_Rt[2:0] : dec_Rs[2:0];
	assign dec_readReg2Sel[2:0] = dec_subtraction? dec_Rs[2:0] : dec_Rt[2:0];
	assign dec_writeEn = dec_RegWrite;


	//
	// Decode/Execute Pipeline Reg
	//
	// TODO: need to pipeline dec_PC2 to exe_PC2
	wire [31:0] dec_rf_out;
	wire [63:0] dec_cntrl_out;
	wire [31:0] dec_sign_ext_out;
	wire [31:0] exe_rf_in;
	wire [63:0] exe_cntrl_in;
	wire [31:0] exe_sign_ext_in;
	wire [4:0] exe_Imm5;
	wire [7:0] exe_Imm8;
	wire [10:0] exe_ImmDis;

	// TODO: Assign the enable signal
	assign decExeEn = 1'bz; 

	// Register File Pipeline Reg
	assign dec_rf_out = {dec_readData1[15:0], dec_readData2[15:0]};
	reg32_en dec_rf(.q(exe_rf_in), .d(dec_rf_out), .clk(clk), .rst(rst), .en(decExeEn));
	assign exe_readData1 = exe_rf_in[31:16];
	assign exe_readData2 = exe_rf_in[15:0];

	// Sign-ext Pipeline Reg
	assign dec_sign_ext_out = {dec_Imm5[4:0], dec_Imm8[7:0], dec_ImmDis[10:0]};
	reg32_en dec_sign_ext(.q(exe_sign_ext_in), .d(dec_sign_ext_out), .clk(clk), .rst(rst), .en(decExeEn));
	assign exe_Imm5 = exe_sign_ext_in[23:19];
	assign exe_Imm8 = exe_sign_ext_in[18:11];
	assign exe_ImmDis = exe_sign_ext_in[10:0];

	// Control Signal Pipeline Reg
	assign dec_cntrl_out = {
							dec_cntrlErr,
							dec_RegDst,
							dec_RegWrite,
							dec_DMemWrite,
							dec_DMemEn,
							dec_ALUSrc2,
							dec_PCImm,
							dec_MemToReg,
							dec_DMemDump,
							dec_Jump,
							dec_Set,
							dec_SetOp,
							dec_Branch,
							dec_BranchOp,
							dec_disp,
							dec_HaltPC,
							dec_BTR,
							dec_SLBI,
							dec_LBI,
							dec_link,
							dec_OpCode,
							dec_Funct,
							dec_Op,
							dec_invA,
							dec_invB,
							dec_Cin,
							dec_sign,
							dec_rorSel,
							dec_subtraction
							};
	reg64_en dec_cntl_sign(.q(exe_cntrl_in), .d(dec_cntrl_out), .clk(clk), .rst(rst), .en(decExeEn));
	// TODO: this won't work, need to assign signals differently
	assign {exe_cntrlErr,
			exe_RegDst,
			exe_RegWrite,
			exe_DMemWrite,
			exe_DMemEn,
			exe_ALUSrc2,
			exe_PCImm,
			exe_MemToReg,
			exe_DMemDump,
			exe_Jump,
			exe_Set,
			exe_SetOp,
			exe_Branch,
			exe_BranchOp,
			exe_disp,
			exe_HaltPC,
			exe_BTR,
			exe_SLBI,
			exe_LBI,
			exe_link,
			exe_OpCode,
			exe_Funct,
			exe_Op,
			exe_invA,
			exe_invB,
			exe_Cin,
			exe_sign,
			exe_rorSel,
			exe_subtraction
			} = exe_cntrl_in;

	//
	// Execute Logic
	//
	rca_16b add3(.A(16'h0010), .B(~{{12{1'b0}},exe_Imm5[3:0]}), .C_in(1'b1), .S(exe_before_ROR[15:0]), .C_out(CO_temp3));

	assign exe_after_ROR[15:0] = exe_rorSel? exe_before_ROR[15:0] : exe_readData2[15:0];
	assign exe_after_Branch[15:0] = exe_Branch? exe_readData1[15:0] : exe_after_ROR[15:0];

	rca_16b add4(.A(~exe_readData2[15:0]), .B(16'b0), .C_in(1'b1),.S(exe_negReadData2[15:0]), .C_out(CO_temp4));

/*
*	MOVED ASSIGN TO DECODE
*
*	assign exe_subtraction = exe_OpCode[4]&exe_OpCode[3]&~exe_OpCode[2]&exe_OpCode[1]
*						&exe_OpCode[0]&~exe_Funct[1]&exe_Funct[0];
*/
	assign exe_ror_with_reg = ~exe_rorSel? 0 : exe_OpCode[4]&exe_OpCode[3]&~exe_OpCode[2]
						&exe_OpCode[1]&~exe_OpCode[0]&exe_Funct[1]&~exe_Funct[0];

	rca_16b add5(.A(16'h0010), .B(~{{12{1'b0}},exe_readData2[3:0]}), .C_in(1'b1), .S(exe_ShiftLeftValue[15:0]), .C_out(CO_temp5));

	// B input to the ALU Module
	assign exe_B[15:0] = (exe_OpCode[4:0] == 5'b01010) ? {{11{1'b0}}, exe_Imm5[4:0]} :
						(exe_OpCode[4:0] == 5'b01011) ? {{11{1'b0}}, exe_Imm5[4:0]} :
						(exe_subtraction)? exe_negReadData2 :
						(exe_ror_with_reg) ? exe_ShiftLeftValue :
						(exe_rorSel) ? exe_after_Branch :
						(exe_ALUSrc2) ? {{11{exe_Imm5[4]}}, exe_Imm5[4:0]} : exe_after_Branch;

	// A input to the ALU Module
	assign exe_A[15:0] = exe_readData1[15:0];

	assign exe_mirr_rd1 = {{exe_readData1[0]},{exe_readData1[1]},{exe_readData1[2]},
						{exe_readData1[3]},{exe_readData1[4]},{exe_readData1[5]},{exe_readData1[6]},{exe_readData1[7]},
						{exe_readData1[8]},{exe_readData1[9]},{exe_readData1[10]},{exe_readData1[11]},
						{exe_readData1[12]},{exe_readData1[13]},{exe_readData1[14]},{exe_readData1[15]}};

	assign exe_Out =(exe_OutSel == 3'b000) ? exe_mirr_rd1 :
					(exe_OutSel == 3'b001) ? 16'h0001 :
					(exe_OutSel == 3'b010) ? 16'h0000 :
					(exe_OutSel == 3'b011) ? exe_PC2:
					(exe_OutSel == 3'b100) ? {{8{exe_Imm8[7]}}, exe_Imm8} :
					(exe_OutSel == 3'b101) ? {exe_readData1[7:0], exe_Imm8} : exe_aluOut;

	// PC logic
	assign exe_PC2_after[15:0] = (exe_link)? exe_readData1[15:0] : exe_PC2[15:0];

	// displacement amount
	assign exe_after_disp[15:0] = exe_disp? {{5{exe_ImmDis[10]}},exe_ImmDis[10:0]} : {{8{exe_Imm8[7]}},exe_Imm8[7:0]};

	// Add the displacement to the PC
	rca_16b add2(.A(exe_after_disp[15:0]), .B(exe_PC2_after[15:0]), .C_in(1'b0),.S(exe_added[15:0]), .C_out(CO_temp2));

	// Wire to update the PC
	assign exe_PC2_back[15:0] = exe_PCSrc? exe_added[15:0] : exe_PC2_after[15:0];


	//
	// Execute/Memory Pipeline Reg
	//

	// TODO: Assign the enable signal
	assign exeMemEn = 1'bz;

	assign exe_cntrl_out = {exe_readData2[15:0],
							exe_HaltPC,
							exe_MemToReg,
							exe_Out,
							exe_DMemEn,
							exe_DMemWrite,
							exe_OpCode,
							exe_PC2
							};
	reg64_en exe_mem_cntrl(.q(mem_cntrl_in), .d(exe_cntrl_out), .clk(clk), .rst(rst), .en(exeMemEn));
	assign {mem_readData2[15:0],
			mem_HaltPC,
			mem_MemToReg,
			mem_Out,
			mem_DMemEn,
			mem_DMemWrite,
			mem_OpCode,
			mem_PC2
			} = mem_cntrl_in;


	//
	// Memory Logic
	//
	assign mem_Datain[15:0] = mem_readData2[15:0];
	assign mem_Createdump = (mem_HaltPC);


	//
	// Write Back Logic
	//
	assign wb_writeData = (wb_OpCode[4:0] == 5'b00110)? wb_PC2 :
						(wb_OpCode[4:0] == 5'b00111)? wb_PC2 :
						(wb_MemToReg) ? wb_Dataout[15:0] : wb_Out[15:0];

	//
	// Fetch Modules
	//
	memory2c instruction_memory(
		//Output
		.data_out				(ftch_instruction[15:0]),
		//Inputs
		.data_in				(16'b0),
		.addr					(ftch_post_PC[15:0]),
		.enable					(1'b1),
		.wr					(1'b0),
		.createdump				(1'b0),
		.clk					(clk),
		.rst					(rst)
		);

	//
	// Decode Modules
	//
	rf rf0(
		// Outputs
		.readData1				(dec_readData1[15:0]),
		.readData2				(dec_readData2[15:0]),
		.err					(dec_rfErr),
		// Inputs
		.clk					(clk),
		.rst					(rst),
		.readReg1Sel			(dec_readReg1Sel[2:0]),
		.readReg2Sel			(dec_readReg2Sel[2:0]),
		.writeRegSel			(dec_writeRegSel[2:0]),
		.writeData				(dec_writeData[15:0]),
		.writeEn				(dec_writeEn)
		);

	control c0(
		// Outputs
		.err					(dec_cntrlErr),
		.RegDst					(dec_RegDst),
		.RegWrite				(dec_RegWrite),
		.DMemWrite				(dec_DMemWrite),
		.DMemEn					(dec_DMemEn),
		.ALUSrc2				(dec_ALUSrc2),
		.PCImm					(dec_PCImm),
		.MemToReg				(dec_MemToReg),
		.DMemDump				(dec_DMemDump),
		.Jump					(dec_Jump),
		//our implementation
		.Set					(dec_Set),
		.SetOp					(dec_SetOp),
		.Branch					(dec_Branch),
		.BranchOp				(dec_BranchOp),
		.disp					(dec_disp),
		.HaltPC					(dec_HaltPC),
		.BTR					(dec_BTR),
		.SLBI					(dec_SLBI),
		.LBI					(dec_LBI),
		.link					(dec_link),
		// Inputs
		.OpCode					(dec_OpCode)
		);

	alu_cntrl alu_c0(
		//inputs
		.opCode					(dec_OpCode),
		.funct					(dec_Funct),
		//outputs
		.aluOp					(dec_Op),
		.invA					(dec_invA),
		.invB					(dec_invB),
		.Cin					(dec_Cin),
		.sign					(dec_sign),
		.rorSel					(dec_rorSel)
		);

	//
	// Execute Modules
	//
	branch_ctrl b0(
		.Rs						(exe_readData1),
		.BranchOp				(exe_BranchOp),
		.Branch					(exe_Branch),
		.PCImm					(exe_PCImm),
		.Jump					(exe_Jump),
		.PCSrc					(exe_PCSrc)
		);

	output_ctrl ooutput_ctrl(
		//inputs
		.BTR					(exe_BTR),
		.Carry					(exe_Carry),
		.Ofl					(exe_Ofl),
		.Zero					(exe_Zero),
		.Neg					(exe_Neg),
		.Set					(exe_Set),
		.SetOp					(exe_SetOp),
		.link					(exe_link),
		.SLBI					(exe_SLBI),
		.LBI					(exe_LBI),
		//output
		.OutSel					(exe_OutSel)
		);

	alu a0(
		// Outputs
		.Out					(exe_aluOut[15:0]),
		.Ofl					(exe_Ofl),
		.Zero					(exe_Zero),
		// Inputs
		.A						(exe_A[15:0]),
		.B						(exe_B[15:0]),
		.Cin					(exe_Cin),
		.Op						(exe_Op[2:0]),
		.invA					(exe_invA),
		.invB					(exe_invB),
		.sign					(exe_sign),
		.Carry					(exe_Carry),
		.Neg					(exe_Neg)
		);

	//
	// Memory Modules
	//
	memory2c data_memory(
		//Output
		.data_out				(mem_Dataout[15:0]),
		//Inputs
		.data_in				(mem_Datain[15:0]),
		.addr					(mem_Out[15:0]),
		.enable					(mem_DMemEn),
		.wr						(mem_DMemWrite),
		.createdump				(mem_Createdump),
		.clk					(clk),
		.rst					(rst)
		);

endmodule // proc
// DUMMY LINE FOR REV CONTROL :0:
