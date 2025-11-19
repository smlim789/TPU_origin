//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: define.v                                                             //
// description: All Definitions                                               //
//============================================================================//

`ifndef MATRIX_DEFINE_V
`define MATRIX_DEFINE_V
    // Dimensions handled manually in TB, but defined here for safety
    `define MATRIX_A_ROW 5
    `define MATRIX_A_COL 5
    `define MATRIX_B_ROW 5
    `define MATRIX_B_COL 5
`endif

`ifndef DEFINE_V
`define DEFINE_V

`define DATA_SIZE 8
`define WORD_SIZE 40  // 5 bytes for 5x5 matrix
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
