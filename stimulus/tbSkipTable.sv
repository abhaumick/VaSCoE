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

	reg 	[31:0]	RfPtr_SimReg;

	IFetchModule SkT(
		.AsyncResetIn(por),  // Asynchronous reset active low
		.ClockIn(clk),

		.PredictedPCIn(predPC),

		.NextPCOut(nextPC),

		.WriteEnIn(wrEn),
		.WriteAddressIn(wrAddr),
		.WriteDataIn(wrData),

		.RfPtr_SimReg      (RfPtr_SimReg)
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

	initial begin
		$display( "Starting testbench" );
		clk = 0;
		por = 0;
		#100
		por = 1;
		RfPtr_SimReg = 32'hAAAA_5555;
	end

	always #5 clk = ~clk;

	

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
			WriteDataIn[29:25]	<= entry.PointerRegId;
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


	assign entry0 = '{	valid: 0, skipType: 0, PointerRegId: 5'h00, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h0, rs2_RB_Idx: 'h0, rd_RB_Idx: 'h0, SkipCount: 'h0};

	assign entry1 = '{	valid: 1, skipType: 0, PointerRegId: 5'h01, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h0, rs2_RB_Idx: 'h0, rd_RB_Idx: 'h1, SkipCount: 'h8};

	assign entry2 = '{	valid: 1, skipType: 1, PointerRegId: 5'h02, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h0, rs2_RB_Idx: 'h0, rd_RB_Idx: 'h2, SkipCount: 'h8};

	assign entry3 = '{	valid: 1, skipType: 1, PointerRegId: 5'h00, rs2_IgnoreFlag: 0,
						rs1_RB_Idx: 'h1, rs2_RB_Idx: 'h2, rd_RB_Idx: 'h3, SkipCount: 'h4};

	PredictedPCIn <= '0;
	resetWriteBus();

	wait (AsyncResetIn == 1);

	//	Table Upload
	#10
	for (int i = 0; i < SKIP_TABLE_SIZE; i++) begin
		#10
		pc = i + PC_Offset;
		writeTable(i*4, pc);
		#10
		writeTable(i*4+1, 'h8000_0000);
		arrayPC[i] = pc;
	end
	#10
	resetWriteBus();

	//	Check CAM
	for (int i = 0; i < PC_Range; i++) begin
		#10
		pc = PC_Offset + i;
		PredictedPCIn <= pc;
	end
		
	$display("Table Test Done !!\n");

	$display("Loading actual table .. \n");

	writeVSTable(0, 'h0, entry0);
	writeVSTable(1, 'h1010, entry1);
	writeVSTable(2, 'h1018, entry2);
	writeVSTable(3, 'h1020, entry3);

	$display("Table Upload Done !!\n");

	//	Finish
	#1E6
	$display("Complete !!\n");

end

endprogram

