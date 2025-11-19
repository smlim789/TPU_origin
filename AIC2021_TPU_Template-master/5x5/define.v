//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: define.v                                                             //
// description: All Definations                                               //
// authors: kaikai (deekai9139@gmail.com)                                     //
//          suhan  (jjs93126@gmail.com)                                       //
//============================================================================//

//----------------------------------------------------------------------------//
// Matrix Parameters Definations                                              //
//----------------------------------------------------------------------------//
`ifndef MATRIX_DEFINE_V
`define MATRIX_DEFINE_V

`include "matrix_define.v"
`endif

//----------------------------------------------------------------------------//
// Common Definations                                                         //
//----------------------------------------------------------------------------//

`ifndef DEFINE_V
`define DEFINE_V

`define DATA_SIZE 8
`define WORD_SIZE 32 // *** CHANGED: Was 32 (4x8), now 40 (5x8) ***
`define GBUFF_ADDR_SIZE 256
//`define GBUFF_INDX_SIZE (GBUFF_ADDR_SIZE/WORD_SIZE)
`define GBUFF_INDX_SIZE 8
`define GBUFF_SIZE (WORD_SIZE*GBUFF_ADDR_SIZE)

// Buffer Sizing for 5x5
// Left Buf: Latency for skewing (approx 2*N)
`define LEFT_BUF_SIZE 10 
// Down Buf: Latency for collection (approx 3*N - 1)
`define DOWN_BUF_SIZE 14 

//----------------------------------------------------------------------------//
// Simulations Definations                                                    //
//----------------------------------------------------------------------------//
`define CYCLE 10
`define MAX   500000

//----------------------------------------------------------------------------//
// User Definations                                                           //
//----------------------------------------------------------------------------//

`endif
