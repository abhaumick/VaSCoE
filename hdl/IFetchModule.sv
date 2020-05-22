/**
 *	IFetchModule.sv
 *
 * 	Created	:	11 Mar 2020, 18:20 EST
 * 	Auhtor	:	Abhishek Bhaumick
 *
 * 
 */

import VSTypes::*;

module IFetchModule (
	input 	logic				AsyncResetIn,  // Asynchronous reset active low
	input	logic				ClockIn,

	input	logic	[31:0]		PredictedPCIn,

	output	logic	[31:0]		NextPCOut,


	input	logic				WriteEnIn,
	input	logic	[31:0]		WriteAddressIn,
	input	logic	[31:0]		WriteDataIn,

	input	logic	[31:0]		RfPtr_SimReg,
	input	logic	[15:0]		RB_ValidIn,

	output	logic				rs1_RB_ReadEn,
	output	logic				rs2_RB_ReadEn,

	output	logic				SkipEnOut,
	output	SkipTableEntryType	SkipEntryOut,
	output	logic				IsRefElemOut,

	input	logic				RefElemWrEnIn,
	input	logic				RefElemWrFlagIn,
	input	logic	[4:0]		RefElemWrIdxIn
);


	//	Storage Structres
	
		SkipTableEntryType			[SKIP_TABLE_SIZE - 1:0]	SkipTable;
		addr32b						[SKIP_TABLE_SIZE - 1:0]	CamPC;
		SkipStatusTableEntryType	[SKIP_TABLE_SIZE - 1:0]	SkipStatusTable;

	//	Wires and Registers
		
		addr32b									camSearchPC;
		logic	[$clog2(SKIP_TABLE_SIZE - 1):0]	camHitIdx;
		logic									camHit;
		logic	[SKIP_TABLE_SIZE - 1:0]			camHitVector;

		logic 	tblWriteEn;
		logic	[31-$clog2(SKIP_TABLE_SIZE)-3 : 0]	writeBlockIdx;
		logic	[$clog2(SKIP_TABLE_SIZE) + 1 : 0]	tblWrAddress;
		logic	[$clog2(SKIP_TABLE_SIZE) - 1 : 0]	tblWrIdx;
		logic										tblWrOffset;

		SkipTableEntryType							skipEntry;

		logic	skipEn;
		logic	ptrRegVSb;

		addr32b	skipTargetPC;
		addr32b nextPC;

		logic 	rs1WasSkipped;
		logic	rs2WasSkipped;
		logic	rs1WasRefElem;
		logic	rs2WasRefElem;

	////    Assignments    ////

		assign NextPCOut 	= nextPC;

		assign SkipEnOut 	= skipEn;
		assign SkipEntryOut	= skipEntry;

	
	////    Table Write    ////
	
		assign tblWriteEn 		= WriteEnIn;
		assign writeBlockIdx	= WriteAddressIn[31:$clog2(SKIP_TABLE_SIZE) + 2];
		assign tblWrAddress		= WriteAddressIn[$clog2(SKIP_TABLE_SIZE) + 1 : 0];
		assign tblWrIdx			= WriteAddressIn[$clog2(SKIP_TABLE_SIZE) + 0 : 1];
		assign tblWrOffset		= WriteAddressIn[0];

		//	Asynchronous Table Write
		// always_comb begin : tblWr
		// 	if (AsyncResetIn == 0) begin
		// 		for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
		// 			CamPC[i] <= 0;
		// 			SkipTable[i] <= SkipTableEntryDefault;
		// 		end
		// 	end else begin
		// 		if (tblWriteEn == 1 && writeBlockIdx == SkipTableBlockIdx ) begin
		// 			case (tblWrOffset)
		// 				'h0:	CamPC[tblWrIdx] <= WriteDataIn;
		// 				default : /* default */;
		// 			endcase
		// 		end
		// 	end
		// end
		
		//	Synchronous Table Write
		always_ff @(posedge(ClockIn)) begin : tblWr
			if (AsyncResetIn == 0) begin
				for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
					CamPC[i] <= 0;
					SkipTable[i] <= SkipTableEntryDefault;
				end
			end else begin
				if (tblWriteEn == 1 && writeBlockIdx == SkipTableBlockIdx ) begin
					case (tblWrOffset)
						'h0:	CamPC[tblWrIdx] <= WriteDataIn;
						'h1:	begin
									SkipTable[tblWrIdx].valid 			<= WriteDataIn[31];
									SkipTable[tblWrIdx].skipType 		<= WriteDataIn[30];
									SkipTable[tblWrIdx].pointerRegId 	<= WriteDataIn[29:25];
									SkipTable[tblWrIdx].rs2_IgnoreFlag 	<= WriteDataIn[24];

									SkipTable[tblWrIdx].rs1_RB_Idx 		<= WriteDataIn[23:20];
									SkipTable[tblWrIdx].rs2_RB_Idx 		<= WriteDataIn[19:16];

									SkipTable[tblWrIdx].rd_RB_Idx 		<= WriteDataIn[15:12];

									SkipTable[tblWrIdx].SkipCount 		<= WriteDataIn[7:0];
								end
						default : /* default */;
					endcase
				end
			end
		end


	////    PC CAM    ////

		assign camSearchPC = PredictedPCIn;

		always_comb begin : camSearch
			if (AsyncResetIn == 0) begin
				camHitVector	<= '{default: '0};
			end else begin
				for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
					if (CamPC[i] == PredictedPCIn && SkipTable[i].valid == 1) begin
						camHitVector[i] <= 1;
					end else begin
						camHitVector[i] <= 0;
					end
				end
			end
		end

		//	CAM Hit Flag
		always_comb begin
			if (AsyncResetIn == 0) begin
				camHit <= 0;
			end else begin
				if (camHitVector == 0) begin
					camHit <= 0;
				end else begin
					camHit <= 1; 
				end
			end
		end

		//	CAM Hit Index Priority Encoder
		always_comb begin : camPE
			if (AsyncResetIn == 0) begin
				camHitIdx <= '0;
			end else begin
				for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
					if (camHitVector[i] == 1) begin
						camHitIdx <= i;
					end
				end
			end
		end


	////    Process Skip Entry    ////
	
		assign skipEntry 	= SkipTable[camHitIdx];
		assign skipStatus 	= SkipStatusTable[camHitIdx];
		assign skipType 	= SkipTable[camHitIdx].skipType;

		assign ptrRegVSb 	= RfPtr_SimReg[skipEntry.pointerRegId];


		always_comb begin
			if (AsyncResetIn == 0) begin
				skipEn <= 0;
			end else begin
				if (camHit == 1) begin
					if (skipEntry.skipType == SkipTypeLoad) begin
					 	if (ptrRegVSb == 1) begin
					 		skipEn <= 1;
					 	end else begin
					 		skipEn <= 0;
					 	end
					end else begin
						if (rs1WasSkipped == 1 && RB_ValidIn[skipEntry.rs1_RB_Idx] == 1) begin
							if (skipEntry.rs2_IgnoreFlag == 1) begin 
								skipEn <= 1;
							end else begin
								if (rs2WasSkipped == 1 && RB_ValidIn[skipEntry.rs2_RB_Idx] == 1) begin
									skipEn <= 1;
								end else begin
									skipEn <= 0;
								end
							end
						end else begin
							skipEn <= 0;
						end
					end
				end else begin
					skipEn <= 0;
				end
			end
		end

		assign skipTargetPC = PredictedPCIn + skipEntry.SkipCount;

		assign nextPC = skipEn ? skipTargetPC : PredictedPCIn;

		assign rs1_RB_ReadEn	= skipEn;
		assign rs2_RB_ReadEn	= (skipEntry.skipType == SkipTypeCompute) ? skipEn : 0;


	////    Write SkipStatusTable    ////


		assign rs1WasSkipped = SkipStatusTable[skipEntry.rs1_RB_Idx].InstrSkipSts;
		assign rs2WasSkipped = SkipStatusTable[skipEntry.rs2_RB_Idx].InstrSkipSts;

		assign rs1WasRefElem = SkipStatusTable[skipEntry.rs1_RB_Idx].IsRefElem;
		assign rs2WasRefElem = SkipStatusTable[skipEntry.rs2_RB_Idx].IsRefElem;


		always_ff @(posedge ClockIn) begin
			if(AsyncResetIn == 0) begin
				for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
					SkipStatusTable[i].InstrSkipSts <= 0;
					// SkipStatusTable[i].IsRefElem 	<= 0;
				end
			end else begin
				if (camHit == 1) begin
					SkipStatusTable[camHitIdx].InstrSkipSts <= skipEn;
				end
			end
		end

		always_ff @(posedge ClockIn) begin
			if(AsyncResetIn == 0) begin
				for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
					SkipStatusTable[i].IsRefElem <= 0;
				end
			end else begin
				if (RefElemWrEnIn == 1) begin
					SkipStatusTable[RefElemWrIdxIn].IsRefElem <= RefElemWrFlagIn;
				end
			end
		end

		assign IsRefElemOut = (rs1WasRefElem == 1 && rs2WasRefElem == 1) ? 1 : 0;

	
endmodule

