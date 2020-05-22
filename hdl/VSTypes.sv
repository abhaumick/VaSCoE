/**
 * 	VSTypes.sv
 *
 * 	Created	:	12 Mar 2020 16:27 PM EST
 * 	Author	:	Abhishek Bhaumick
 * 	
 */

package VSTypes;

	////    Defines    ////

		`define REGISTER_COUNT			32

		`define SKIP_TABLE_SIZE			16

		`define RESULT_BUFFER_SIZE		8

	////    Parameters    ////

		parameter REGISTER_COUNT			= `REGISTER_COUNT;
		parameter SKIP_TABLE_SIZE			= `SKIP_TABLE_SIZE;
		parameter RESULT_BUFFER_SIZE		= `RESULT_BUFFER_SIZE;

		parameter REGISTER_ID_SIZE			= $clog2(`REGISTER_COUNT);
		parameter RESULT_BUFFER_ID_SIZE		= $clog2(`RESULT_BUFFER_SIZE);


	////    Type Definition    ////

		typedef logic[31:0] data32b;
		typedef logic[31:0] addr32b;

		typedef struct packed
		{
			logic [31:0]	result;
			logic			valid;
			logic [4:0]		pointerRegId;
		} ResultBufferEntryType;

		typedef struct packed
		{
			logic valid;
			logic skipType;
			logic [4:0] pointerRegId;
			logic rs2_IgnoreFlag;
			logic [RESULT_BUFFER_ID_SIZE-1:0] rs1_RB_Idx;
			logic [RESULT_BUFFER_ID_SIZE-1:0] rs2_RB_Idx;
			logic [RESULT_BUFFER_ID_SIZE-1:0] rd_RB_Idx;
			logic [7:0] SkipCount;
		} SkipTableEntryType;

		const SkipTableEntryType SkipTableEntryDefault = 
		'{
			valid			:	'0,
			skipType		:	'0,
			pointerRegId	:	'{default: '0},
			rs2_IgnoreFlag	:	'0,
			rs1_RB_Idx		:	'{default: '0},
			rs2_RB_Idx		:	'{default: '0},
			rd_RB_Idx		:	'{default: '0},
			SkipCount		:	'{default: '0}
		};

		typedef struct packed
		{
			logic InstrSkipSts;
			logic IsRefElem;
		}	SkipStatusTableEntryType;

		typedef struct packed
		{
			logic [31:0] CacheTag;
			logic [ 7:0] VSBy;
		} VSBTableEntryType;

		typedef struct packed
		{
			logic Enable;
			logic [RESULT_BUFFER_ID_SIZE-1:0] RBIdx;
		}	RBPickupType;



	////    Predefined Constants    ////

		logic	[31: $clog2(SKIP_TABLE_SIZE) + 2]	SkipTableBlockIdx = '0;

		const logic SkipTypeLoad = '0;
		const logic SkipTypeCompute = '1;

		//	OpCodes
		
			// @custom0            rd rs1 imm12 14..12=0 6..2=0x02 1..0=3
			// @custom0.rs1        rd rs1 imm12 14..12=2 6..2=0x02 1..0=3
			// @custom0.rs1.rs2    rd rs1 imm12 14..12=3 6..2=0x02 1..0=3
			// @custom0.rd         rd rs1 imm12 14..12=4 6..2=0x02 1..0=3
			// @custom0.rd.rs1     rd rs1 imm12 14..12=6 6..2=0x02 1..0=3
			// @custom0.rd.rs1.rs2 rd rs1 imm12 14..12=7 6..2=0x02 1..0=3
			
			//	PTRINC == ADDI
			
			//	VsLOAD == LOAD-FP
			//	Imm[11:0] rs1[4:0] funct3(14:12) rd[4:0] OpCode[6:0] = 'b000_1011
			
			// @custom2            rd rs1 imm12 14..12=0 6..2=0x16 1..0=3
			// @custom2.rs1        rd rs1 imm12 14..12=2 6..2=0x16 1..0=3
			// @custom2.rs1.rs2    rd rs1 imm12 14..12=3 6..2=0x16 1..0=3
			// @custom2.rd         rd rs1 imm12 14..12=4 6..2=0x16 1..0=3
			// @custom2.rd.rs1     rd rs1 imm12 14..12=6 6..2=0x16 1..0=3
			// @custom2.rd.rs1.rs2 rd rs1 imm12 14..12=7 6..2=0x16 1..0=3

			//	VsOP-FP == OP-FP
			//	funct5[31:27] fmt2[26:25] rs2[24:20] rs1[19:15] RM[14:12] rd[11:7] opcode[6:0] = 'b101_1011
		



	////    Instructions    ////
	
		const logic	[6:0]	PTRINC 	= 'h1;
		const logic [6:0]	LOAD 	= 'h4;
		const logic [6:0]	COMPUTE	= 'h8;

endpackage

