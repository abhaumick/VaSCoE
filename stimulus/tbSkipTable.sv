/**
 * 	tbSkipTable.sv
 *
 * 	Created	:	12 Mar 2020
 * 	Author	:	Abhishek Bhaumick
 * 	
 */

`timescale 1 ns / 1 ns

import VSTypes::*;

module tbSkipTable ();

	reg por;
	reg clk;

	addr32b predPC;
	addr32b nextPC;

	wire wrEn;
	addr32b wrAddr;
	data32b wrData;

	logic [6:0] VSBy = 'b1111011;


	logic rs1_RB_ReadEn;
	logic rs2_RB_ReadEn;
	logic [15:0] RB_Valid;
	logic [31:0] RfPtr_SimReg;
	logic 				IF_SkipEn;
	SkipTableEntryType 	IF_SkipEntry;

	logic DC_rs1_RB_ReadEn;
	logic DC_rs2_RB_ReadEn;

	logic DC_SkipEn, EX_SkipEn, MEM_SkipEn, WB_SkipEn;
	addr32b DC_pc, EX_pc, MEM_pc, WB_pc;
	SkipTableEntryType DC_SkipEntry, EX_SkipEntry, MEM_SkipEntry, WB_SkipEntry;
	logic DC_IsRefElem, EX_IsRefElem, MEM_IsRefElem, WB_IsRefElem;
	data32b DC_Instr, EX_Instr, MEM_Instr, WB_Instr;
	data32b MEM_Data, WB_Data;

	data32b EX_rs1_data, MEM_rs1_data, WB_rs1_data;
	data32b EX_rs2_data, MEM_rs2_data, WB_rs2_data;

	logic CacheHit, WB_CacheHit;
	addr32b CacheAddr, WB_CacheAddr;
	data32b CacheData, WB_CacheData;

	logic 			RB_WriteEn;			//	Pointer is first elem
	logic 			RB_WriteValid;
	logic 	[3:0]	RB_WriteIdx;
	logic	[1:0]	RB_PtrRegId;
	data32b			RB_WriteData;

	logic 			RfPtr_Sim_Wr;
	logic 			RfPtr_Sim_Bit;
	logic 	[4:0]	RfPtr_RegIdx;

	logic 	[4:0]	rs1_Idx;
	logic 	[31:0]	rs1_Data;
	logic 	[4:0]	rs2_Idx;
	logic 	[31:0]	rs2_Data;

	logic			rd_WrEn;
	logic	[4:0]	rd_Idx;
	logic	[31:0]	rd_Data;

	logic 			RefElemWrEnOut;
	logic 			RefElemWrFlagOut;
	logic 	[4:0]	RefElemWrIdxOut;

	IFetchModule SkT(
		.AsyncResetIn(por),  // Asynchronous reset active low
		.ClockIn(clk),

		.PredictedPCIn(predPC),

		.NextPCOut(nextPC),

		.WriteEnIn(wrEn),
		.WriteAddressIn(wrAddr),
		.WriteDataIn(wrData),

		.RfPtr_SimReg		(RfPtr_SimReg),
		.RB_ValidIn			(RB_Valid),
		.rs1_RB_ReadEn		(rs1_RB_ReadEn),
		.rs2_RB_ReadEn		(rs2_RB_ReadEn),

		.SkipEnOut 			(IF_SkipEn),
		.SkipEntryOut		(IF_SkipEntry),
		.IsRefElemOut   	(IF_IsRefElem),

		.RefElemWrEnIn    	(RefElemWrEnOut),
		.RefElemWrFlagIn	(RefElemWrFlagOut),
		.RefElemWrIdxIn		(RefElemWrIdxOut)
	);


	DecodeModule dec
	(
		.AsyncResetIn 		(por),
		.ClockIn			(clk),

		.SkipEnIn         	(DC_SkipEn),
		.SkipEntryIn      	(DC_SkipEntry),
		.rs1_RB_ReadEn    	(DC_rs1_RB_ReadEn),
		.rs2_RB_ReadEn    	(DC_rs2_RB_ReadEn),
		.RB_Table_ValidOut	(RB_Valid),
		.RfPtr_SimRegOut  	(RfPtr_SimReg),

		.rs1_In           	(rs1_Data),
		.rs2_In           	(rs2_Data),

		.RB_WriteEn			(RB_WriteEn),
		.RB_WriteValid		(RB_WriteValid),
		.RB_WriteIdx		(RB_WriteIdx),
		.RB_PtrRegId		(RB_PtrRegId),
		.RB_WriteData		(RB_WriteData),

		.RfPtr_Sim_Wr		(RfPtr_Sim_Wr),
		.RfPtr_Sim_Bit		(RfPtr_Sim_Bit),
		.RfPtr_RegIdx		(RfPtr_RegIdx)		
	);

	WritebackModule Wb
	(
		.AsyncResetIn		(por),
		.ClockIn			(clk),

		.Instruction		(WB_Instr),

		.SkipEnIn 			(WB_SkipEn),
		.SkipEntryIn		(WB_SkipEntry),
		.IsRefElemIn 		(WB_IsRefElem),
		.WB_Data			(WB_Data),

		.CacheHit			(WB_CacheHit),
		.CacheAddr			(WB_CacheAddr),
		.CacheData			(WB_CacheData),
		.VSBy				(VSBy),

		.RB_WriteEn			(RB_WriteEn),
		.RB_WriteValid		(RB_WriteValid),
		.RB_WriteIdx		(RB_WriteIdx),
		.RB_PtrRegId		(RB_PtrRegId),
		.RB_WriteData		(RB_WriteData),

		.RfPtr_Sim_Wr		(RfPtr_Sim_Wr),
		.RfPtr_Sim_Bit		(RfPtr_Sim_Bit),
		.RfPtr_RegIdx 		(RfPtr_RegIdx),

		.RefElemWrEnOut  	(RefElemWrEnOut),
		.RefElemWrFlagOut	(RefElemWrFlagOut),
		.RefElemWrIdxOut 	(RefElemWrIdxOut)

	);

	testSkipTable testSkT
	(
		.AsyncResetIn(por),  // Asynchronous reset active low

		.PredictedPCIn(predPC),

		.NextPCOut(nextPC),

		.WriteEnIn(wrEn),
		.WriteAddressIn(wrAddr),
		.WriteDataIn(wrData)
	);

	// memSim mem 
	// (
	// 	.instr    (MEM_Instr),
	// 	.CacheHit (CacheHit),
	// 	.CacheAddr(CacheAddr),
	// 	.CacheData(CacheData)
	// );

	cacheSim cSim
	(
		.instr    (MEM_Instr),
		.rs1_Data (MEM_rs1_data),
		.rs2_Data (MEM_rs2_data),

		.CacheHit (CacheHit),
		.CacheAddr(CacheAddr),
		.CacheData(CacheData)		
	);

	regFile rf
	(
		.AsyncResetIn	(por),
		.ClockIn		(clk),

		.rs1_Idx     (rs1_Idx),
		.rs1_Data    (rs1_Data),
		.rs2_Idx     (rs2_Idx),
		.rs2_Data    (rs2_Data),

		.rd_WrEn     (rd_WrEn),
		.rd_Idx      (rd_Idx),
		.rd_Data     (rd_Data)
	);

	assign rs1_Idx = DC_Instr[19:15];
	assign rs2_Idx = DC_Instr[14:10];

	assign rd_Idx  = WB_Instr[24:20];

	always_comb begin
		if (WB_Instr[31:25] == PTRINC || WB_Instr[31:25] == LOAD || WB_Instr[31:25] == COMPUTE) begin
			rd_WrEn <= 1;
		end else begin
			rd_WrEn <= 0;
		end
	end

	always_comb begin
		case (WB_Instr[31:25])
			PTRINC	:	rd_Data <= WB_rs1_data + 4;
			LOAD 	:	rd_Data <= WB_CacheData;
			COMPUTE :	rd_Data <= WB_rs1_data + WB_rs2_data;
			default :	rd_Data <= '0;
		endcase
	end

	always_ff @(posedge clk) begin
		if(por == 0) begin
			EX_rs1_data <= 0;
			EX_rs2_data <= 0;
			MEM_rs1_data <= 0;
			MEM_rs2_data <= 0;
			WB_rs1_data <= 0;
			WB_rs2_data <= 0;
		end else begin
			EX_rs1_data 	<= rs1_Data;
			EX_rs2_data 	<= rs2_Data;
			MEM_rs1_data	<= EX_rs1_data; 
			MEM_rs2_data	<= EX_rs2_data; 
			WB_rs1_data		<= MEM_rs1_data; 
			WB_rs2_data		<= MEM_rs2_data; 
		end
	end


	initial begin
		$display( "Starting testbench" );
		clk = 0;
		por = 0;
		#100
		por = 1;
		//RfPtr_SimReg = 32'hAAAA_5555;
	end

	always #5 clk = ~clk;

	////    Pipeline Registers    ////
		//	IF / DEC FlipFlops
		always_ff @(posedge clk) begin
			if (por == 0) begin
				DC_SkipEn <= 0;
				DC_rs1_RB_ReadEn	<= 0;
				DC_rs2_RB_ReadEn	<= 0;
			end else begin
				DC_SkipEn 			<= IF_SkipEn;
				DC_SkipEntry 		<= IF_SkipEntry;
				DC_IsRefElem		<= IF_IsRefElem;
				DC_rs1_RB_ReadEn	<= rs1_RB_ReadEn;
				DC_rs2_RB_ReadEn	<= rs2_RB_ReadEn;
				DC_pc 				<= nextPC;
			end
		end

		//	DEC / EX FlipFlops
		always_ff @(posedge clk) begin
			if (por == 0) begin
				EX_SkipEn <= 0;
			end else begin
				EX_SkipEn 			<= DC_SkipEn;
				EX_SkipEntry 		<= DC_SkipEntry;
				EX_IsRefElem		<= DC_IsRefElem;
				EX_pc				<= DC_pc;
			end
		end

		//	EX / MEM FlipFlops
		always_ff @(posedge clk) begin
			if (por == 0) begin
				MEM_SkipEn <= 0;
			end else begin
				MEM_SkipEn 			<= EX_SkipEn;
				MEM_SkipEntry 		<= EX_SkipEntry;
				MEM_IsRefElem		<= EX_IsRefElem;
				MEM_pc				<= EX_pc;
			end
		end
		assign MEM_Data = CacheData;


		//	EX / MEM FlipFlops
		always_ff @(posedge clk) begin
			if (por == 0) begin
				WB_SkipEn <= 0;
			end else begin
				WB_SkipEn 			<= MEM_SkipEn;
				WB_SkipEntry 		<= MEM_SkipEntry;
				WB_pc				<= MEM_pc;
				WB_IsRefElem		<= MEM_IsRefElem;

				WB_CacheHit			<= CacheHit;	
				WB_CacheAddr		<= CacheAddr;	
				WB_CacheData		<= CacheData;	
				//WB_Data				<= CacheData;
			end
		end
		assign WB_Data = rd_Data;

		function data32b getInst (input addr32b pc = 'h1000); // (addr32b pc, output data32b instr);
			data32b instr;
			case (pc)
				32'h1004	:	instr = {PTRINC,  5'h2,  5'h2, 15'h1}; 
				32'h1008	:	instr = {PTRINC,  5'h3,  5'h3, 15'h1};
				32'h1010 	:	instr = {LOAD,    5'h13, 5'h2, 15'h0};
				32'h1018 	:	instr = {LOAD,    5'h14, 5'h3, 15'h0};
				32'h1020	:	instr = {COMPUTE, 5'h18, 5'h13, 5'h14, 10'h0};

				default : instr = 32'h0;
			endcase
			return instr;
		endfunction

	assign DC_Instr = getInst(DC_pc);
	assign EX_Instr = getInst(EX_pc);
	assign MEM_Instr = getInst(MEM_pc);
	assign WB_Instr = getInst(WB_pc);

endmodule

module memSim (
	input data32b instr,

	output logic	CacheHit,
	output addr32b	CacheAddr,
	output data32b	CacheData
);

	logic [4:0]	rdReg;

	assign rdReg = instr[24:20];

	assign CacheHit = (instr[31:25] == LOAD) ? 1 : 0;
	assign CacheAddr = {rdReg, 27'h0};
	assign CacheData = {27'h0, rdReg};

endmodule

module cacheSim
(
	input data32b instr,
	input data32b rs1_Data,
	input data32b rs2_Data,

	output logic	CacheHit,
	output addr32b	CacheAddr,
	output data32b	CacheData

);

	assign CacheHit = (instr[31:25] == LOAD) ? 1 : 0;
	assign CacheAddr = rs1_Data;
	assign CacheData = {27'h0, instr[24:20]};

endmodule

module regFile
(
	input	logic			AsyncResetIn,
	input	logic			ClockIn,

	input 	logic	[4:0]	rs1_Idx,
	input 	logic	[4:0]	rs2_Idx,
	output	data32b			rs1_Data,
	output	data32b			rs2_Data,

	input	logic			rd_WrEn,
	input 	logic	[4:0]	rd_Idx,
	input	data32b 		rd_Data
);

	logic [31:0] regs [31:0];

	assign rs1_Data = regs[rs1_Idx];
	assign rs2_Data = regs[rs2_Idx];

	always_ff @(posedge ClockIn) begin : proc_rs1
		if(AsyncResetIn == 0) begin
			for (int i = 0; i < 32; i++) begin
				regs[i] <= (i << 24);
			end
		end else begin
			if (rd_WrEn == 1) begin
				regs[rd_Idx] <= rd_Data;
			end
		end
	end

endmodule


program testSkipTable
(
	input 	logic			AsyncResetIn,  // Asynchronous reset active low

	output	logic [31:0]	PredictedPCIn,

	input	logic [31:0]	NextPCOut,

	output	logic			WriteEnIn,
	output	logic [31:0]	WriteAddressIn,
	output	logic [31:0]	WriteDataIn
);

	int arrayPC[SKIP_TABLE_SIZE];

	int PC_Offset = 32;
	int PC_Range = 32;
	int pc;
	addr32b nextPC;

	SkipTableEntryType entry0;
	SkipTableEntryType entry1;
	SkipTableEntryType entry2;
	SkipTableEntryType entry3;

	task automatic resetWriteBus;
		begin
			WriteEnIn		<= 0;
			WriteAddressIn	<= '0;
			WriteDataIn		<= '0;
		end
	endtask : resetWriteBus

	task automatic writeTable;
		input int address;
		input int data;
		begin
			WriteEnIn		<= 1;
			WriteAddressIn	<= address;
			WriteDataIn		<= data;
		end
	endtask : writeTable

	task automatic pickPC;
		output int pickedPC;
		begin
			pickedPC = $urandom_range(PC_Range,0) + PC_Offset;
		end
	endtask : pickPC

	task writeVSTable;
		input logic	[3:0]			idx;
		input addr32b				pc;
		input SkipTableEntryType	entry;
		begin
			WriteEnIn		<= 0;
			#10
			WriteEnIn		<= 1;
			WriteAddressIn	<= idx * 2;
			WriteDataIn 	<= pc;
			#10
			WriteEnIn		<= 1;
			WriteAddressIn	<= idx * 2 + 1;
			WriteDataIn[31]		<= entry.valid;
			WriteDataIn[30] 	<= entry.skipType;
			WriteDataIn[29:25]	<= entry.pointerRegId;
			WriteDataIn[24]		<= entry.rs2_IgnoreFlag;
			WriteDataIn[23:20]	<= entry.rs1_RB_Idx;
			WriteDataIn[19:16]	<= entry.rs2_RB_Idx;
			WriteDataIn[15:12]	<= entry.rd_RB_Idx;
			WriteDataIn[11: 8]	<= 4'h0;
			WriteDataIn[ 7: 0]	<= entry.SkipCount;

			// #10
			// WriteEnIn		<= 1;
			// WriteAddressIn	<= idx * 4 + 2;
			// WriteDataIn		<= {entry.rs1_RB_Idx, entry.rs2_RB_Idx};
			// #10
			// WriteEnIn		<= 1;
			// WriteAddressIn	<= idx * 4 + 3;
			// WriteDataIn		<= {entry.rd_RB_Idx, 4'h0};
			#10
			WriteEnIn		<= 0;
		end
	endtask : writeVSTable

initial begin


	assign entry0 = '{	valid: 0, skipType: 0, pointerRegId: 5'h00, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h0, rs2_RB_Idx: 'h0, rd_RB_Idx: 'h0, SkipCount: 'h0};

	assign entry1 = '{	valid: 1, skipType: 0, pointerRegId: 5'h02, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h1, rs2_RB_Idx: 'h0, rd_RB_Idx: 'h1, SkipCount: 'h4};

	assign entry2 = '{	valid: 1, skipType: 0, pointerRegId: 5'h03, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h2, rs2_RB_Idx: 'h0, rd_RB_Idx: 'h2, SkipCount: 'h4};

	assign entry3 = '{	valid: 1, skipType: 1, pointerRegId: 5'h00, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h1, rs2_RB_Idx: 'h2, rd_RB_Idx: 'h3, SkipCount: 'h4};

	PredictedPCIn <= '0;
	resetWriteBus();

	wait (AsyncResetIn == 1);

	//	Table Upload
	// #10
	// for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
	// 	#10
	// 	pc = i + PC_Offset;
	// 	writeTable(i*4, pc);
	// 	#10
	// 	writeTable(i*4+1, 'h8000_0000);
	// 	arrayPC[i] = pc;
	// end
	// #10
	// resetWriteBus();

	// //	Check CAM
	// for (int i = 0; i < PC_Range; i++) begin
	// 	#10
	// 	pc = PC_Offset + i;
	// 	PredictedPCIn <= pc;
	// end
		
	// $display("Table Test Done !!\n");

	$display("Loading actual table .. \n");

	writeVSTable(0, 'h0, entry0);
	writeVSTable(1, 'h1010, entry1);
	writeVSTable(2, 'h1018, entry2);
	writeVSTable(3, 'h1020, entry3);

	$display("Table Upload Done !!\n");

	#100

	for (int i = 0; i < 40; i++) begin
		#40

	nextPC = 'h1000;
	for (int j = 'h1000; j < 'h1030; j+=4) begin
		#40
		pc = j;
		PredictedPCIn <= nextPC;
		nextPC <= nextPC + 4;
	end

	$display("Iter %d\n", i);
	end

	//	Finish
	#1E6
	$display("Complete !!\n");

end

endprogram

