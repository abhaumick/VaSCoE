quietly set PROJECT_DIR "D:\\Work\\Purdue\\Research\\ValueSimilarity"

quietly set PROJECT_INCL_DIR "${PROJECT_DIR}/hdl"

# vlog -reportprogress 300 -work work "${PROJECT_DIR}/hdl/constants.h"
vlog -reportprogress 300 -work work "${PROJECT_DIR}/hdl/VSTypes.sv"

vlog -reportprogress 300 -work work "${PROJECT_DIR}/hdl/IFetchModule.sv"

vlog -reportprogress 300 -work work "${PROJECT_DIR}/stimulus/tbSkipTable.sv"

vsim -novopt work.tbSkipTable

add wave sim:/tbSkipTable/SkT/*