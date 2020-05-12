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

	IFetchModule SkT(
		.AsyncResetIn(por),  // Asynchronous reset active low
		.ClockIn(clk),

		.PredictedPCIn(predPC),

		.NextPCOut(nextPC),

		.WriteEnIn(wrEn),
		.WriteAddressIn(wrAddr),
		.WriteDataIn(wrData)
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

initial begin

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
	$display("Table Upload Done !!\n");

	//	Check CAM
	for (int i = 0; i < PC_Range; i++) begin
		#10
		pc = PC_Offset + i;
		PredictedPCIn <= pc;
		
	end

	//	Finish
	#1E6
	$display("Complete !!\n");

end

endprogram

