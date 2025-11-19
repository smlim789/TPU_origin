`timescale 1ns/10ps
`include "define.v"

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

    clk = 0;  rst = 1; start = 0;
    #(`CYCLE) rst = 0; start = 1;
    row_a = `MATRIX_A_ROW; col_b = `MATRIX_B_COL; k = `MATRIX_A_COL;
    
    // -----------------------------------------------------------
    // MANUAL DATA LOADING (Bypassing 32-bit binary files)
    // Mapping: MSB [39:32] = Index 0 (First Element)
    //          LSB [7:0]   = Index 4 (Last Element)
    // -----------------------------------------------------------

    // Initialize Global Buffers with 0
    for(i=0; i<`GBUFF_ADDR_SIZE; i=i+1) begin
        TOP.GBUFF_A.gbuff[i] = 40'd0;
        TOP.GBUFF_B.gbuff[i] = 40'd0;
        GOLDEN[i] = 40'd0;
    end

    // MATRIX A (5x5)
    // Row 0: 0 1 0 0 0 -> 00 01 00 00 00
    TOP.GBUFF_A.gbuff[0] = 40'h00_01_00_00_00;
    // Row 1: 1 0 0 0 1 -> 01 00 00 00 01
    TOP.GBUFF_A.gbuff[1] = 40'h01_00_00_00_01;
    // Row 2: 0 0 0 0 1 -> 00 00 00 00 01
    TOP.GBUFF_A.gbuff[2] = 40'h00_00_00_00_01;
    // Row 3: 0 1 1 1 0 -> 00 01 01 01 00
    TOP.GBUFF_A.gbuff[3] = 40'h00_01_01_01_00;
    // Row 4: 1 0 1 1 1 -> 01 00 01 01 01
    TOP.GBUFF_A.gbuff[4] = 40'h01_00_01_01_01;

    // MATRIX B (5x5)
    // Row 0: 1 1 1 1 1 -> 01 01 01 01 01
    TOP.GBUFF_B.gbuff[0] = 40'h01_01_01_01_01;
    // Row 1: 0 0 1 1 1 -> 00 00 01 01 01
    TOP.GBUFF_B.gbuff[1] = 40'h00_00_01_01_01;
    // Row 2: 0 1 0 0 0 -> 00 01 00 00 00
    TOP.GBUFF_B.gbuff[2] = 40'h00_01_00_00_00;
    // Row 3: 0 0 1 1 1 -> 00 00 01 01 01
    TOP.GBUFF_B.gbuff[3] = 40'h00_00_01_01_01;
    // Row 4: 1 1 0 1 1 -> 01 01 00 01 01
    TOP.GBUFF_B.gbuff[4] = 40'h01_01_00_01_01;

    // MATRIX C (GOLDEN) - This is what we expect
    // Row 0: 0 0 1 1 1 -> 00 00 01 01 01
    GOLDEN[0] = 40'h00_00_01_01_01;
    // Row 1: 2 2 1 2 2 -> 02 02 01 02 02
    GOLDEN[1] = 40'h02_02_01_02_02;
    // Row 2: 1 1 0 1 1 -> 01 01 00 01 01
    GOLDEN[2] = 40'h01_01_00_01_01;
    // Row 3: 0 1 2 2 2 -> 00 01 02 02 02
    GOLDEN[3] = 40'h00_01_02_02_02;
    // Row 4: 2 3 2 3 3 -> 02 03 02 03 03
    GOLDEN[4] = 40'h02_03_02_03_03;

    row_offset = (`MATRIX_B_COL - 1) / 5 + 1;
    
    wait(done == 1);
    $display("\nSimulation Done.\n");

    err = 0;
    // Loop for 5x5 (only need to check first 5 addresses)
    for (i = 0; i < 5; i=i+1) begin
      // Check all 5 bytes. MSB is Index 0.
      // Check Byte 0 (MSB)
      if (GOLDEN[i][39:32] !== TOP.GBUFF_OUT.gbuff[i][39:32]) begin
        $display("GBUFF_OUT[%2d][39:32] = %2h, expect = %2h", i, TOP.GBUFF_OUT.gbuff[i][39:32], GOLDEN[i][39:32]); err = err + 1;
      end else $display("GBUFF_OUT[%2d][39:32] = %2h, pass!", i, TOP.GBUFF_OUT.gbuff[i][39:32]);

      // Check Byte 1
      if (GOLDEN[i][31:24] !== TOP.GBUFF_OUT.gbuff[i][31:24]) begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, expect = %2h", i, TOP.GBUFF_OUT.gbuff[i][31:24], GOLDEN[i][31:24]); err = err + 1;
      end else $display("GBUFF_OUT[%2d][31:24] = %2h, pass!", i, TOP.GBUFF_OUT.gbuff[i][31:24]);

      // Check Byte 2
      if (GOLDEN[i][23:16] !== TOP.GBUFF_OUT.gbuff[i][23:16]) begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, expect = %2h", i, TOP.GBUFF_OUT.gbuff[i][23:16], GOLDEN[i][23:16]); err = err + 1;
      end else $display("GBUFF_OUT[%2d][23:16] = %2h, pass!", i, TOP.GBUFF_OUT.gbuff[i][23:16]);

      // Check Byte 3
      if (GOLDEN[i][15:8] !== TOP.GBUFF_OUT.gbuff[i][15:8]) begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, expect = %2h", i, TOP.GBUFF_OUT.gbuff[i][15:8], GOLDEN[i][15:8]); err = err + 1;
      end else $display("GBUFF_OUT[%2d][15: 8] = %2h, pass!", i, TOP.GBUFF_OUT.gbuff[i][15:8]);
      
      // Check Byte 4 (LSB)
      if (GOLDEN[i][7:0] !== TOP.GBUFF_OUT.gbuff[i][7:0]) begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, expect = %2h", i, TOP.GBUFF_OUT.gbuff[i][7:0], GOLDEN[i][7:0]); err = err + 1;
      end else $display("GBUFF_OUT[%2d][ 7: 0] = %2h, pass!", i, TOP.GBUFF_OUT.gbuff[i][7:0]);
    end

    check_err(err);
    $finish;
  end

  task check_err;
    input integer err;
    if( err == 0 ) begin
      $display("\n");
      $display("******************************");
      $display("** Congratulations!         **");
      $display("** Simulation Passed!       **");
      $display("******************************");
      $display("\n");
    end else begin
      $display("\n");
      $display("******************************");
      $display("** Awwwww                   **");
      $display("** Simulation Failed!       **");
      $display("******************************");
      $display(" Total %4d errors\n", err);
    end
  endtask

endmodule
