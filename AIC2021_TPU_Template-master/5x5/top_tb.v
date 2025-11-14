//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: top_tb.v                                                             //
// description: testbench for tpu top module (MODIFIED for 5x5)               //
// authors: kaikai (deekai9139@gmail.com)                                     //
//          suhan  (jjs93126@gmail.com)                                       //
//============================================================================//

`timescale 1ns/10ps
`include "define.v"
//`include "top.v"

module top_tb;

  reg clk;
  reg rst;
  reg start;
  wire done;
  reg [3:0] row_a, col_b, k;
  integer err, i, row_offset;

  reg [`WORD_SIZE-1:0] GOLDEN [`GBUFF_ADDR_SIZE-1:0];

  always #(`CYCLE/2) clk = ~clk;

  top TOP(.clk(clk),
          .rst(rst),
          .start(start),
          .m(row_a),
          .k(k),
          .n(col_b),
          .done(done));

  initial begin
    $dumpfile("top.fsdb");
    $dumpvars(0, TOP);
//----------------------------------------------------------------------------//
// Global Buffers Initialization                                              //
//----------------------------------------------------------------------------//
    clk = 0;  rst = 1; start = 0;
    #(`CYCLE) rst = 0; start = 1;
    row_a = `MATRIX_A_ROW; col_b = `MATRIX_B_COL; k = `MATRIX_A_COL;
    $readmemb("build/matrix_a.bin", TOP.GBUFF_A.gbuff);
    $readmemb("build/matrix_b.bin", TOP.GBUFF_B.gbuff);
    $readmemb("build/golden.bin", GOLDEN); 
    
    row_offset = (`MATRIX_B_COL - 1) / 5 + 1;
    
	//$display ("done : %d", done);
    wait(done == 1);
    $display("\nSimulation Done.\n");


//----------------------------------------------------------------------------//
// Verify output global buffer with golden                                    //
//----------------------------------------------------------------------------//
    err = 0;
    for (i = 0; i < `MATRIX_A_ROW * row_offset; i=i+1) begin
      // [7:0] vs [39:32]
      if (GOLDEN[i][39:32] != TOP.GBUFF_OUT.gbuff[i][7:0]) begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][7:0], GOLDEN[i][39:32]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][7:0]);
      end
      // [15:8] vs [31:24]
      if (GOLDEN[i][31:24] != TOP.GBUFF_OUT.gbuff[i][15:8]) begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][15:8], GOLDEN[i][31:24]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][15:8]);
      end
      // [23:16] vs [23:16]
      if (GOLDEN[i][23:16] != TOP.GBUFF_OUT.gbuff[i][23:16]) begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][23:16], GOLDEN[i][23:16]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][23:16]);
      end
      // [31:24] vs [15:8]
      if (GOLDEN[i][15:8] != TOP.GBUFF_OUT.gbuff[i][31:24]) begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][31:24], GOLDEN[i][15:8]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][31:24]);
      end
      // [39:32] vs [7:0]
      if (GOLDEN[i][7:0] != TOP.GBUFF_OUT.gbuff[i][39:32]) begin
        $display("GBUFF_OUT[%2d][39:32] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][39:32], GOLDEN[i][7:0]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][39:32] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][39:32]);
      end
    end

    check_err(err);
  end

//----------------------------------------------------------------------------//
// Maximum Simulation time                                                    //
//----------------------------------------------------------------------------//
  initial begin

    #(`CYCLE*`MAX)
    err = 0;
    for (i = 0; i < `MATRIX_A_ROW * row_offset; i=i+1) begin
      // [7:0] vs [39:32]
      if (GOLDEN[i][39:32] != TOP.GBUFF_OUT.gbuff[i][7:0]) begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][7:0], GOLDEN[i][39:32]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][7:0]);
      end
      // [15:8] vs [31:24]
      if (GOLDEN[i][31:24] != TOP.GBUFF_OUT.gbuff[i][15:8]) begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][15:8], GOLDEN[i][31:24]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][15:8]);
      end
      // [23:16] vs [23:16]
      if (GOLDEN[i][23:16] != TOP.GBUFF_OUT.gbuff[i][23:16]) begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][23:16], GOLDEN[i][23:16]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][23:16]);
      end
      // [31:24] vs [15:8]
      if (GOLDEN[i][15:8] != TOP.GBUFF_OUT.gbuff[i][31:24]) begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][31:24], GOLDEN[i][15:8]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][31:24]);
      end
      // [39:32] vs [7:0]
      if (GOLDEN[i][7:0] != TOP.GBUFF_OUT.gbuff[i][39:32]) begin
        $display("GBUFF_OUT[%2d][39:32] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][39:32], GOLDEN[i][7:0]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][39:32] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][39:32]);
      end
    end
    check_err(err);
    $finish;
  end

//----------------------------------------------------------------------------//
// Task Declarations                                                          //
//----------------------------------------------------------------------------//
  task check_err;
    input integer err;

    if( err == 0 )
    begin
      $display("\n");
      $display("******************************");
      $display("** Congratulations!         **");
      $display("** Simulation Passed!       **");
      $display("******************************");
      $display("\n");
    end
    else
    begin
      $display("\n");
      $display("******************************");
      $display("** Awwwww                   **");
      $display("** Simulation Failed!       **");
      $display("******************************");
      $display(" Total %4d errors\n", err);
    end
  endtask


endmodule
