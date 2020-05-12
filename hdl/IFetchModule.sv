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
	input 	logic			AsyncResetIn,  // Asynchronous reset active low
	input	logic			ClockIn,

	input	logic [31:0]	PredictedPCIn,

	output	logic [31:0]	NextPCOut,


	input	logic			WriteEnIn,
	input	logic [31:0]	WriteAddressIn,
	input	logic [31:0]	WriteDataIn
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
		logic	[1:0]								tblWrOffset;

		SkipTableEntryType							skipEntry;

	
	////    Table Write    ////
	
	assign tblWriteEn 		= WriteEnIn;
	assign writeBlockIdx	= WriteAddressIn[31:$clog2(SKIP_TABLE_SIZE) + 2];
	assign tblWrAddress		= WriteAddressIn[$clog2(SKIP_TABLE_SIZE) + 1 : 0];
	assign tblWrIdx			= WriteAddressIn[$clog2(SKIP_TABLE_SIZE) + 1 : 2];
	assign tblWrOffset		= WriteAddressIn[1:0];

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
					'h1:	SkipTable[tblWrIdx].valid <= WriteDataIn[31];
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
	
		assign skipEntry = SkipTable[camHitIdx];
		assign skipStatus =  SkipStatusTable[camHitIdx];

	// SkipTable = '{default: SkipTableEntryDefault};
	
endmodule

