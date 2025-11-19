`ifndef MATRIX_DEFINE_V
`define MATRIX_DEFINE_V
    // No include needed here for this fix
`endif

`ifndef DEFINE_V
`define DEFINE_V

`define DATA_SIZE 8
`define WORD_SIZE 40  // Set to 40 bits for 5x5 Matrix (5 bytes)
`define GBUFF_ADDR_SIZE 256
`define GBUFF_INDX_SIZE 8
`define GBUFF_SIZE (WORD_SIZE*GBUFF_ADDR_SIZE)

// Buffer Sizing
`define LEFT_BUF_SIZE 10 
`define DOWN_BUF_SIZE 14 

// Simulation
`define CYCLE 10
`define MAX   500000

`endif
