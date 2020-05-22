/**
 *	DecodeModule.sv
 *
 * 	Created	:	11 Mar 2020, 18:20 EST
 * 	Auhtor	:	Abhishek Bhaumick
 *
 * 
 */

import VSTypes::*;

module DecodeModule 
(
	input	logic			AsyncResetIn,  // Asynchronous reset active low
	input	logic 			ClockIn,

	//	Interface With IF module 
	input	logic				SkipEnIn,
	input	SkipTableEntryType	SkipEntryIn,

	input	logic				rs1_RB_ReadEn,
	input	logic				rs2_RB_ReadEn,

	output	logic 	[15:0]		RB_Table_ValidOut,
	output	logic 	[31:0]		RfPtr_SimRegOut,

	//	Interface with Decode Logic & RegFile Read

	input	data32b			rs1_In,
	input	data32b			rs2_In,

	output	data32b			rs1_Out,
	output	data32b			rs2_Out,

	//	Interface with EXE Stage
	
	output	SkipTableEntryType	SkipEntryOut,

	//	Interface with Writeback Stage (before LD/ST Queue)
	
	input	logic 			RB_WriteEn,			//	Pointer is first elem
	input	logic 			RB_WriteValid,
	input	logic 	[3:0]	RB_WriteIdx,
	input	logic 	[1:0]	RB_PtrRegId,
	input	data32b			RB_WriteData,

	input	logic			RfPtr_Sim_Wr,
	input	logic			RfPtr_Sim_Bit,
	input	logic	[4:0]	RfPtr_RegIdx

);



	//	Storage Structures

		ResultBufferEntryType	[SKIP_TABLE_SIZE - 1:0]	RB_Table;	

		logic 					[31:0]					RfPtr_SimReg;

	//	Wires and Registers
	
		logic	[3:0]	rs1_RB_ReadIdx;
		logic	[3:0]	rs2_RB_ReadIdx;


	//	Through Connections

		assign SkipEntryOut	=	SkipEntryIn;

	//	Assignments

		assign rs1_RB_ReadIdx = SkipEntryIn.rs1_RB_Idx;
		assign rs2_RB_ReadIdx = SkipEntryIn.rs2_RB_Idx;


	////    Result Buffer Read    ////

		always_comb begin : rs1_Mux
			if (rs1_RB_ReadEn == 1) begin			//	Assumes .. valid bit checked in previous stage
				rs1_Out <= RB_Table[rs1_RB_ReadIdx].result;
			end else begin
				rs1_Out <= rs1_In; 
			end
		end

		always_comb begin : rs2_Mux
			if (rs2_RB_ReadEn == 1) begin
				rs2_Out <= RB_Table[rs2_RB_ReadIdx].result;
			end else begin
				rs2_Out <= rs2_In;
			end
		end

	////    Result Buffer    ////
	
		always_comb begin
			for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
				RB_Table_ValidOut[i] <=RB_Table[i].valid;
			end
		end

		always_ff @(posedge ClockIn) begin
			if (AsyncResetIn == 0) begin
				for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
					RB_Table[i].valid 			<= 0;
					RB_Table[i].result 			<= 0;
					RB_Table[i].pointerRegId 	<= 0;
				end
			end else begin
				if (RB_WriteEn == 1) begin
					if (RB_WriteValid == 1) begin
						RB_Table[RB_WriteIdx].valid 		<= 1;
						RB_Table[RB_WriteIdx].result 		<= RB_WriteData;
						RB_Table[RB_WriteIdx].pointerRegId  <= RB_PtrRegId;
					end else begin
						for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
							if (RB_Table[RB_WriteIdx].pointerRegId == RB_PtrRegId) begin
								RB_Table[RB_WriteIdx].valid <= 0;
							end
						end
					end
				end
			end
		end

	////    Register File Pointer Similaroty Vector    ////
	
		assign RfPtr_SimRegOut = RfPtr_SimReg;

		always_ff @(posedge ClockIn) begin
			if (AsyncResetIn == 0) begin
				RfPtr_SimReg <= '{default: '0};
			end else begin
				if (RfPtr_Sim_Wr == 1) begin
					RfPtr_SimReg[RfPtr_RegIdx] <= RfPtr_Sim_Bit;
				end
			end
		end

endmodule
