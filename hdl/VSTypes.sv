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
		} ResultBufferEntryType;

		typedef struct packed
		{
			logic valid;
			logic skipType;
			logic [4:0] PointerRegId;
			logic rs2_SkipFlag;
			logic [RESULT_BUFFER_ID_SIZE-1:0] rs1_RB_Idx;
			logic [RESULT_BUFFER_ID_SIZE-1:0] rs2_RB_Idx;
			logic [RESULT_BUFFER_ID_SIZE-1:0] rd_RB_Idx;
			logic [7:0] SkipCount;
		} SkipTableEntryType;

		const SkipTableEntryType SkipTableEntryDefault = 
		'{
			valid			:	'0,
			skipType		:	'0,
			PointerRegId	:	'{default: '0},
			rs2_SkipFlag	:	'0,
			rs1_RB_Idx		:	'{default: '0},
			rs2_RB_Idx		:	'{default: '0},
			rd_RB_Idx		:	'{default: '0},
			SkipCount		:	'{default: '0}
		};

		typedef struct packed
		{
			logic InstrSkipEn;
		}	SkipStatusTableEntryType;

		typedef struct packed
		{
			logic [31:0] CacheTag;
			logic [ 7:0] VSBy;
		} VSBTableEntryType;



	////    Predefined Constants    ////

		logic	[31: $clog2(SKIP_TABLE_SIZE) + 2]	SkipTableBlockIdx = '0; 

endpackage

