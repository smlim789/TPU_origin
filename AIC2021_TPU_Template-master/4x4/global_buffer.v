`include "define.v"

module global_buffer(clk, rst, wr_en, index, data_in, data_out);

  input clk;
  input rst;
  input wr_en; // Write enable: 1->write 0->read
  input        [`GBUFF_INDX_SIZE-1:0] index;
  input        [`WORD_SIZE-1:0]       data_in;
  output reg [`WORD_SIZE-1:0]       data_out;
  integer i;
  reg wr_en_reg;

  reg [`WORD_SIZE-1:0] gbuff [0:`GBUFF_ADDR_SIZE-1];

  always @ (*) begin
    wr_en_reg = wr_en;
  end
  
  always @ (posedge clk or posedge rst) begin
    if(rst)begin
      for(i=0; i<`GBUFF_ADDR_SIZE; i=i+1)
        gbuff[i] <= `WORD_SIZE'd0;
    end
    else begin
      if(wr_en_reg) begin
        gbuff[index] <= data_in;
      end
      else begin
        data_out <= gbuff[index];
      end
    end
  end

endmodule
