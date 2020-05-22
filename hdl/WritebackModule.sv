/**
 *	WritebackModule.sv
 *
 * 	Created	:	11 Mar 2020, 18:20 EST
 * 	Auhtor	:	Abhishek Bhaumick
 *
 * 
 */

import VSTypes::*;

module WritebackModule 
(
	input	logic			AsyncResetIn,  // Asynchronous reset active low
	input	logic 			ClockIn,

	input	data32b			Instruction,

	//	Interface With MEM module 
	input	logic				SkipEnIn,
	input	SkipTableEntryType	SkipEntryIn,
	input	logic				IsRefElemIn,

	input	data32b				WB_Data,

	//	Interface with Cache
	input	logic				CacheHit,
	input 	addr32b				CacheAddr,
	input	data32b				CacheData,
	input	logic	[6:0]		VSBy,

	//	Interface with Writeback Stage (before LD/ST Queue)
	
	output	logic 			RB_WriteEn,			//	Pointer is first elem
	output	logic 			RB_WriteValid,
	output	logic 	[3:0]	RB_WriteIdx,
	output	logic	[1:0]	RB_PtrRegId,
	output	data32b			RB_WriteData,

	//	Interface to Register File
	
	output	logic			RfPtr_Sim_Wr,
	output	logic			RfPtr_Sim_Bit,
	output	logic	[4:0]	RfPtr_RegIdx,

	//	Interface to Instruction Status
	
	output	logic			RefElemWrEnOut,
	output	logic			RefElemWrFlagOut,
	output	logic	[4:0]	RefElemWrIdxOut
);


	//	Storage Structures
		
		VSBTableEntryType	[3:0]	VSB_Table;

	//	Wire and Register
	
		logic 			isLoad;
		logic			isFirstElemLoad;
		logic	[1:0]	VSB_Table_Idx;
		logic	[2:0]	VSBit_Idx;

		logic 			VSB_Tag_Match;

		logic	[6:0]	OpCode;
		logic	[4:0]	rd;
		logic	[4:0]	rs;

	////    VSB Table    ////

		assign isFirstElemLoad = (CacheAddr[4:0] == 0) ? 1 : 0;
	
		always_ff @(posedge ClockIn) begin
			if (AsyncResetIn == 0) begin
				for (int i = 0; i < 4; i++) begin
					VSB_Table[i].CacheTag 	<= 'h0;
					VSB_Table[i].VSBy 		<= 'h0; 
				end;
			end else begin
				if (OpCode == LOAD) begin
					if (CacheHit == 1 && isFirstElemLoad == 1) begin
						VSB_Table[VSB_Table_Idx].CacheTag 	<= CacheAddr;
						VSB_Table[VSB_Table_Idx].VSBy 		<= {1'h1,VSBy};
					end
				end
			end
		end
	

	////    Write RFPtr_Sim Vector @ DEC    ////
	
		assign OpCode 	= Instruction[31:25];
		assign rd 		= Instruction[24:20];
		assign rs 		= Instruction[19:15];

		assign VSB_Tag_Match = (WB_Data[31:5] == VSB_Table[VSB_Table_Idx].CacheTag[31:5]) ? 1 : 0;
		assign isLoad		= (OpCode == LOAD) ? 1 : 0;

		always_comb begin
			if (OpCode == PTRINC) begin
				VSB_Table_Idx 	<= rd[1:0];
				VSBit_Idx 		<= CacheAddr[4:2];
			end else if (OpCode == LOAD) begin
				VSB_Table_Idx	<= rs[1:0];
				VSBit_Idx		<= '0;
			end else if (OpCode == COMPUTE) begin
				VSB_Table_Idx	<= '0;
				VSBit_Idx		<=  0;
			end else begin
				VSB_Table_Idx 	<= 0;
				VSBit_Idx		<= 0;
			end
		end

		assign isFirstElemPtr = (WB_Data[4:0] == 0) ? 1 : 0;

		always_comb begin
			RfPtr_Sim_Wr 	<= 0;
			RfPtr_Sim_Bit 	<= 0;
			RfPtr_RegIdx	<= 0;
			if (OpCode == PTRINC) begin
				if (isFirstElemPtr == 1) begin
					//	Clear PtrSim
					RfPtr_Sim_Wr	<= 1;
					RfPtr_Sim_Bit	<= 0;
					RfPtr_RegIdx	<= rd;
				end else if (VSB_Tag_Match == 1) begin
					//	Update VSBit on RFPtr
					RfPtr_Sim_Wr 	<= 1;
					RfPtr_Sim_Bit 	<= VSB_Table[VSB_Table_Idx].VSBy[7 - VSBit_Idx];
					RfPtr_RegIdx	<= rd;
				end else begin
					RfPtr_Sim_Wr	<= 0;
				end
			end
		end

	////   Write RB Table    ////
	
		always_comb begin
			RB_WriteEn 		<= 0;
			RB_WriteValid 	<= 0;
			RB_WriteIdx 	<= 0;
			RB_PtrRegId		<= 0;
			RB_WriteData 	<= 0;
			if (OpCode == PTRINC) begin
				if (VSB_Tag_Match == 1) begin
					RB_WriteEn 		<= 0;
				end else begin
					//	Invalidate RB
					RB_WriteEn 		<= 1;
					RB_WriteValid	<= 0;
					RB_WriteIdx		<= 0;
					RB_PtrRegId		<= rd[1:0];
				end
			end else if (OpCode == LOAD) begin
				if (isFirstElemLoad == 1) begin
					RB_WriteEn 		<= 1;
					RB_WriteValid 	<= 1;
					RB_WriteIdx 	<= SkipEntryIn.rd_RB_Idx;
					RB_PtrRegId		<= SkipEntryIn.pointerRegId;
					RB_WriteData 	<= WB_Data;
				end
			end else if (OpCode == COMPUTE) begin
				if (IsRefElemIn == 1) begin
					RB_WriteEn		<= 1;
					RB_WriteValid	<= 1;
					RB_WriteIdx		<= SkipEntryIn.rd_RB_Idx;
					RB_WriteData	<= WB_Data;
				end
			end
		end

	////    Write Instruction Status Table    ////
	

		always_comb begin
			RefElemWrEnOut		<= 0;
			RefElemWrFlagOut	<= 0;
			RefElemWrIdxOut		<= 0;
			if (OpCode == LOAD) begin
				if (isFirstElemLoad == 1) begin
					RefElemWrEnOut		<= 1;
					RefElemWrFlagOut	<= 1;
					RefElemWrIdxOut		<= SkipEntryIn.rd_RB_Idx;
				end else begin
					RefElemWrEnOut		<= 1;
					RefElemWrFlagOut	<= 0;
					RefElemWrIdxOut		<= SkipEntryIn.rd_RB_Idx;
				end
			end
		end

endmodule