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

    // -----------------------------------------------------------
    // 1. SETUP DIMENSIONS
    // -----------------------------------------------------------
    clk = 0;  rst = 1; start = 0;
    #(`CYCLE) rst = 0; start = 1;
    
    row_a = 5; 
    col_b = 5; 
    k     = 5; 
    
    // -----------------------------------------------------------
    // 2. MANUAL DATA LOADING
    // -----------------------------------------------------------
    // Initialize Buffers
    for(i=0; i<`GBUFF_ADDR_SIZE; i=i+1) begin
        TOP.GBUFF_A.gbuff[i] = 40'd0;
        TOP.GBUFF_B.gbuff[i] = 40'd0;
        GOLDEN[i] = 40'd0;
    end

    // --- MATRIX A (TRANSPOSED) ---
    // The architecture expects Columns of A to be fed to Rows of the Array.
    // Original A:
    // 0 1 0 0 0
    // 1 0 0 0 1
    // 0 0 0 0 1
    // 0 1 1 1 0
    // 1 0 1 1 1
    
    // Transposed A (Col 0 becomes Row 0): 0 1 0 0 1
    TOP.GBUFF_A.gbuff[0] = 40'h00_01_00_00_01;
    // Transposed A (Col 1 becomes Row 1): 1 0 0 1 0
    TOP.GBUFF_A.gbuff[1] = 40'h01_00_00_01_00;
    // Transposed A (Col 2 becomes Row 2): 0 0 0 1 1
    TOP.GBUFF_A.gbuff[2] = 40'h00_00_00_01_01;
    // Transposed A (Col 3 becomes Row 3): 0 0 0 1 1
    TOP.GBUFF_A.gbuff[3] = 40'h00_00_00_01_01;
    // Transposed A (Col 4 becomes Row 4): 0 1 1 0 1
    TOP.GBUFF_A.gbuff[4] = 40'h00_01_01_00_01;

    // --- MATRIX B (STANDARD) ---
    // PE grid holds B statically. Row k of PEs gets Row k of B.
    // Row 0: 1 1 1 1 1 -> Hex: 01 01 01 01 01
    TOP.GBUFF_B.gbuff[0] = 40'h01_01_01_01_01;
    // Row 1: 0 0 1 1 1 -> Hex: 00 00 01 01 01
    TOP.GBUFF_B.gbuff[1] = 40'h00_00_01_01_01;
    // Row 2: 0 1 0 0 0 -> Hex: 00 01 00 00 00
    TOP.GBUFF_B.gbuff[2] = 40'h00_01_00_00_00;
    // Row 3: 0 0 1 1 1 -> Hex: 00 00 01 01 01
    TOP.GBUFF_B.gbuff[3] = 40'h00_00_01_01_01;
    // Row 4: 1 1 0 1 1 -> Hex: 01 01 00 01 01
    TOP.GBUFF_B.gbuff[4] = 40'h01_01_00_01_01;

    // --- GOLDEN RESULT (C = A @ B) ---
    // Row 0: 0 0 1 1 1 -> Hex: 00 00 01 01 01
    GOLDEN[0] = 40'h00_00_01_01_01;
    // Row 1: 2 2 1 2 2 -> Hex: 02 02 01 02 02
    GOLDEN[1] = 40'h02_02_01_02_02;
    // Row 2: 1 1 0 1 1 -> Hex: 01 01 00 01 01
    GOLDEN[2] = 40'h01_01_00_01_01;
    // Row 3: 0 1 2 2 2 -> Hex: 00 01 02 02 02
    GOLDEN[3] = 40'h00_01_02_02_02;
    // Row 4: 2 3 2 3 3 -> Hex: 02 03 02 03 03
    GOLDEN[4] = 40'h02_03_02_03_03;

    row_offset = (5 - 1) / 5 + 1;
    
    wait(done == 1);
    $display("\nSimulation Done.\n");

    // -----------------------------------------------------------
    // 3. VERIFICATION
    // -----------------------------------------------------------
    err = 0;
    // Check only the 5 output rows
    for (i = 0; i < 5; i=i+1) begin
      
      // Byte 0 (Bits 39:32) - First Column
      if (GOLDEN[i][39:32] !== TOP.GBUFF_OUT.gbuff[i][39:32]) begin
        $display("Row %d Col 0: Found %h, Expect %h", i, TOP.GBUFF_OUT.gbuff[i][39:32], GOLDEN[i][39:32]); 
        err = err + 1;
      end else $display("Row %d Col 0: Pass!", i);

      // Byte 1 (Bits 31:24)
      if (GOLDEN[i][31:24] !== TOP.GBUFF_OUT.gbuff[i][31:24]) begin
        $display("Row %d Col 1: Found %h, Expect %h", i, TOP.GBUFF_OUT.gbuff[i][31:24], GOLDEN[i][31:24]); 
        err = err + 1;
      end else $display("Row %d Col 1: Pass!", i);

      // Byte 2 (Bits 23:16)
      if (GOLDEN[i][23:16] !== TOP.GBUFF_OUT.gbuff[i][23:16]) begin
        $display("Row %d Col 2: Found %h, Expect %h", i, TOP.GBUFF_OUT.gbuff[i][23:16], GOLDEN[i][23:16]); 
        err = err + 1;
      end else $display("Row %d Col 2: Pass!", i);

      // Byte 3 (Bits 15:8)
      if (GOLDEN[i][15:8] !== TOP.GBUFF_OUT.gbuff[i][15:8]) begin
        $display("Row %d Col 3: Found %h, Expect %h", i, TOP.GBUFF_OUT.gbuff[i][15:8], GOLDEN[i][15:8]); 
        err = err + 1;
      end else $display("Row %d Col 3: Pass!", i);
      
      // Byte 4 (Bits 7:0) - Last Column
      if (GOLDEN[i][7:0] !== TOP.GBUFF_OUT.gbuff[i][7:0]) begin
        $display("Row %d Col 4: Found %h, Expect %h", i, TOP.GBUFF_OUT.gbuff[i][7:0], GOLDEN[i][7:0]); 
        err = err + 1;
      end else $display("Row %d Col 4: Pass!", i);
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
