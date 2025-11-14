//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: pe.v                                                                 //
// description: TPU module (MODIFIED for 5x5)                                 //
// authors: yuwen (vincent08tw@yahoo.com.tw)                                  //
//                                                                            //
//============================================================================//

//`ifndef TPU_V
//`define TPU_V

`include "define.v"
//`include "pe.v"
`define LEFT_BUF_SIZE 10  // CHANGED: Was 8. (5+5-1) + 1 = 10
`define DOWN_BUF_SIZE 14  // CHANGED: Was 11. (5+5-1) + 5 = 14

module TPU(clk, rst, wr_en_a, wr_en_b, wr_en_o, index_a, index_b, index_o,
		    data_in_a, data_in_b, data_in_o, /*data_out_a, data_out_b,*/
		    data_out_o, m, n, k, start, done);
	input clk, rst, start;
	input [`WORD_SIZE-1:0] data_in_a, // Now 40 bits
						    data_in_b, // Now 40 bits
						    data_in_o; // Now 40 bits
	input [3:0] m, n, k; //matrix A(mxk) matrix B(kxn) 
	output reg done, wr_en_a, wr_en_b, wr_en_o;
	output reg [`DATA_SIZE-1:0] index_a,
								index_b,
								index_o;
	output reg [`WORD_SIZE-1:0] /*data_out_a,
						    data_out_b,*/
						    data_out_o; // Now 40 bits
	
	/******** state definition ********/
	reg [3:0] state,state_nxt;
	parameter [3:0] IDLE 	= 3'd0,
					LOAD 	= 3'd1,
					EXE	 	= 3'd2,
					STORE	= 3'd3,
					OUTPUT	= 3'd4,
					DONE 	= 3'd5;
	
	/******** data storage for PE (5x5) ********/
	reg [`DATA_SIZE-1:0] left_buf0 [`LEFT_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] left_buf1 [`LEFT_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] left_buf2 [`LEFT_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] left_buf3 [`LEFT_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] left_buf4 [`LEFT_BUF_SIZE-1:0]; // ADDED
	reg [`DATA_SIZE-1:0] down_buf0 [`DOWN_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] down_buf1 [`DOWN_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] down_buf2 [`DOWN_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] down_buf3 [`DOWN_BUF_SIZE-1:0];
	reg [`DATA_SIZE-1:0] down_buf4 [`DOWN_BUF_SIZE-1:0]; // ADDED
	
	/******** wire connection of PE (5x5) ********/
	wire [`DATA_SIZE-1:0] down_wire0;
	wire [`DATA_SIZE-1:0] down_wire1;
	wire [`DATA_SIZE-1:0] down_wire2;
	wire [`DATA_SIZE-1:0] down_wire3;
	wire [`DATA_SIZE-1:0] down_wire4; // ADDED
	wire [31:0] wire_row_0; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_row_1; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_row_2; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_row_3; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_row_4; // ADDED
	wire [31:0] wire_col_0; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_col_1; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_col_2; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_col_3; // CHANGED: 4*8 = 32 bits
	wire [31:0] wire_col_4; // ADDED
	
	/******** output buffer ********/
	reg [`WORD_SIZE-1:0] output_buf [4:0]; // CHANGED: 5 elements
	
	/******** control register ********/
	reg weight_en [24:0]; // CHANGED: 25 PEs
	reg output_buf_rst;
	integer i,j;
	reg [6:0] load_count;
	reg [2:0] out_count; // CHANGED: Needs to count to 4
	reg [4:0] weight_base;
	reg go_pe,pe_ok;
	reg [8:0] temp_ma, temp_kb, temp_a, temp_b, temp_o, a_count;
	reg [8:0] base_a, base_b, out_max;
	reg [8:0] exe_count;
	
	/******** PE declaration (5x5) ********/
	// data_in_b[39:32] -> Col 0
	// data_in_b[31:24] -> Col 1
	// data_in_b[23:16] -> Col 2
	// data_in_b[15: 8] -> Col 3
	// data_in_b[ 7: 0] -> Col 4
	
	// Row 0
	PE pe00(.clk(clk), .rst(rst), 
			.in_left(left_buf0[0]), .in_up(8'd0), .in_weight(data_in_b[39:32]),
			.out_right(wire_row_0[31:24]), .out_down(wire_col_0[31:24]), .weight_en(weight_en[0]),
			.go(go_pe)
			); 
	PE pe01(.clk(clk), .rst(rst), 
			.in_left(wire_row_0[31:24]), .in_up(8'd0), .in_weight(data_in_b[31:24]),
			.out_right(wire_row_0[23:16]), .out_down(wire_col_1[31:24]), .weight_en(weight_en[1]),
			.go(go_pe)
			); 
	PE pe02(.clk(clk), .rst(rst), 
			.in_left(wire_row_0[23:16]), .in_up(8'd0), .in_weight(data_in_b[23:16]),
			.out_right(wire_row_0[15:8]), .out_down(wire_col_2[31:24]), .weight_en(weight_en[2]),
			.go(go_pe)
			); 
	PE pe03(.clk(clk), .rst(rst), 
			.in_left(wire_row_0[15:8]), .in_up(8'd0), .in_weight(data_in_b[15:8]),
			.out_right(wire_row_0[7:0]), .out_down(wire_col_3[31:24]), .weight_en(weight_en[3]),
			.go(go_pe)
			); 
	PE pe04(.clk(clk), .rst(rst),  // ADDED
			.in_left(wire_row_0[7:0]), .in_up(8'd0), .in_weight(data_in_b[7:0]),
			.out_right(), .out_down(wire_col_4[31:24]), .weight_en(weight_en[4]),
			.go(go_pe)
			); 
	// Row 1
	PE pe10(.clk(clk), .rst(rst), 
			.in_left(left_buf1[0]), .in_up(wire_col_0[31:24]), .in_weight(data_in_b[39:32]),
			.out_right(wire_row_1[31:24]), .out_down(wire_col_0[23:16]), .weight_en(weight_en[5]),
			.go(go_pe)
			);  
	PE pe11(.clk(clk), .rst(rst), 
			.in_left(wire_row_1[31:24]), .in_up(wire_col_1[31:24]), .in_weight(data_in_b[31:24]),
			.out_right(wire_row_1[23:16]), .out_down(wire_col_1[23:16]), .weight_en(weight_en[6]),
			.go(go_pe)
			); 
	PE pe12(.clk(clk), .rst(rst), 
			.in_left(wire_row_1[23:16]), .in_up(wire_col_2[31:24]), .in_weight(data_in_b[23:16]),
			.out_right(wire_row_1[15:8]), .out_down(wire_col_2[23:16]), .weight_en(weight_en[7]),
			.go(go_pe)
			); 
	PE pe13(.clk(clk), .rst(rst), 
			.in_left(wire_row_1[15:8]), .in_up(wire_col_3[31:24]), .in_weight(data_in_b[15:8]),
			.out_right(wire_row_1[7:0]), .out_down(wire_col_3[23:16]), .weight_en(weight_en[8]),
			.go(go_pe)
			); 
	PE pe14(.clk(clk), .rst(rst),  // ADDED
			.in_left(wire_row_1[7:0]), .in_up(wire_col_4[31:24]), .in_weight(data_in_b[7:0]),
			.out_right(), .out_down(wire_col_4[23:16]), .weight_en(weight_en[9]),
			.go(go_pe)
			); 
	// Row 2
	PE pe20(.clk(clk), .rst(rst), 
			.in_left(left_buf2[0]), .in_up(wire_col_0[23:16]), .in_weight(data_in_b[39:32]),
			.out_right(wire_row_2[31:24]), .out_down(wire_col_0[15:8]), .weight_en(weight_en[10]),
			.go(go_pe)
			);  
	PE pe21(.clk(clk), .rst(rst), 
			.in_left(wire_row_2[31:24]), .in_up(wire_col_1[23:16]), .in_weight(data_in_b[31:24]),
			.out_right(wire_row_2[23:16]), .out_down(wire_col_1[15:8]), .weight_en(weight_en[11]),
			.go(go_pe)
			); 
	PE pe22(.clk(clk), .rst(rst), 
			.in_left(wire_row_2[23:16]), .in_up(wire_col_2[23:16]), .in_weight(data_in_b[23:16]),
			.out_right(wire_row_2[15:8]), .out_down(wire_col_2[15:8]), .weight_en(weight_en[12]),
			.go(go_pe)
			); 
	PE pe23(.clk(clk), .rst(rst), 
			.in_left(wire_row_2[15:8]), .in_up(wire_col_3[23:16]), .in_weight(data_in_b[15:8]),
			.out_right(wire_row_2[7:0]), .out_down(wire_col_3[15:8]), .weight_en(weight_en[13]),
			.go(go_pe)
			); 
	PE pe24(.clk(clk), .rst(rst),  // ADDED
			.in_left(wire_row_2[7:0]), .in_up(wire_col_4[23:16]), .in_weight(data_in_b[7:0]),
			.out_right(), .out_down(wire_col_4[15:8]), .weight_en(weight_en[14]),
			.go(go_pe)
			); 
	// Row 3
	PE pe30(.clk(clk), .rst(rst), 
			.in_left(left_buf3[0]), .in_up(wire_col_0[15:8]), .in_weight(data_in_b[39:32]),
			.out_right(wire_row_3[31:24]), .out_down(wire_col_0[7:0]), .weight_en(weight_en[15]),
			.go(go_pe)
			);  
	PE pe31(.clk(clk), .rst(rst), 
			.in_left(wire_row_3[31:24]), .in_up(wire_col_1[15:8]), .in_weight(data_in_b[31:24]),
			.out_right(wire_row_3[23:16]), .out_down(wire_col_1[7:0]), .weight_en(weight_en[16]),
			.go(go_pe)
			); 
	PE pe32(.clk(clk), .rst(rst), 
			.in_left(wire_row_3[23:16]), .in_up(wire_col_2[15:8]), .in_weight(data_in_b[23:16]),
			.out_right(wire_row_3[15:8]), .out_down(wire_col_2[7:0]), .weight_en(weight_en[17]),
			.go(go_pe)
			); 
	PE pe33(.clk(clk), .rst(rst), 
			.in_left(wire_row_3[15:8]), .in_up(wire_col_3[15:8]), .in_weight(data_in_b[15:8]),
			.out_right(wire_row_3[7:0]), .out_down(wire_col_3[7:0]), .weight_en(weight_en[18]),
			.go(go_pe)
			); 
	PE pe34(.clk(clk), .rst(rst),  // ADDED
			.in_left(wire_row_3[7:0]), .in_up(wire_col_4[15:8]), .in_weight(data_in_b[7:0]),
			.out_right(), .out_down(wire_col_4[7:0]), .weight_en(weight_en[19]),
			.go(go_pe)
			); 
	// Row 4 (ADDED)
	PE pe40(.clk(clk), .rst(rst), 
			.in_left(left_buf4[0]), .in_up(wire_col_0[7:0]), .in_weight(data_in_b[39:32]),
			.out_right(wire_row_4[31:24]), .out_down(down_wire0[7:0]), .weight_en(weight_en[20]),
			.go(go_pe)
			);  
	PE pe41(.clk(clk), .rst(rst), 
			.in_left(wire_row_4[31:24]), .in_up(wire_col_1[7:0]), .in_weight(data_in_b[31:24]),
			.out_right(wire_row_4[23:16]), .out_down(down_wire1[7:0]), .weight_en(weight_en[21]),
			.go(go_pe)
			); 
	PE pe42(.clk(clk), .rst(rst), 
			.in_left(wire_row_4[23:16]), .in_up(wire_col_2[7:0]), .in_weight(data_in_b[23:16]),
			.out_right(wire_row_4[15:8]), .out_down(down_wire2[7:0]), .weight_en(weight_en[22]),
			.go(go_pe)
			); 
	PE pe43(.clk(clk), .rst(rst), 
			.in_left(wire_row_4[15:8]), .in_up(wire_col_3[7:0]), .in_weight(data_in_b[15:8]),
			.out_right(wire_row_4[7:0]), .out_down(down_wire3[7:0]), .weight_en(weight_en[23]),
			.go(go_pe)
			); 
	PE pe44(.clk(clk), .rst(rst), 
			.in_left(wire_row_4[7:0]), .in_up(wire_col_4[7:0]), .in_weight(data_in_b[7:0]),
			.out_right(), .out_down(down_wire4[7:0]), .weight_en(weight_en[24]),
			.go(go_pe)
			);
	
	/******** combinational circuit ********/	
	always @(*) begin
		case (state)
			IDLE: begin
				go_pe = 0; pe_ok = 0; done = 0;
				wr_en_a = 0; wr_en_b = 0; wr_en_o = 0;
				index_a = 0; index_b = 0; 
				
				temp_kb = 0;
				temp_ma = 0; a_count = 1;
				base_a = 0; base_b = 0; out_max = m;
				output_buf_rst = 1;
				wr_en_o = 0;
				if(start == 1'b1) state_nxt = LOAD;
				else state_nxt = IDLE;
			end
			LOAD: begin
				go_pe = 0;
				pe_ok = 0;
				wr_en_a = 1'b0; //buffer read
				wr_en_b = 1'b0;
				wr_en_o = 0;
				
				index_a = temp_a + 1;
				index_b = temp_b + 1;
				
				// CHANGED: 4 -> 5, 3 -> 4
				if(((index_a >= ((k)*a_count))&&(index_a > 5)) || (load_count) == 4) begin
					state_nxt = EXE;
				end
				else begin
					state_nxt = LOAD;
				end
				// CHANGED: 15 -> 24, 3 -> 4
				for(i = 0; i <= 24; i = i + 1) begin
					if(i >= weight_base && i <= (weight_base + 4)) begin 
						weight_en[i] = 1;
					end
					else begin
						weight_en[i] = 0;
					end
				end
			end
			EXE: begin
				output_buf_rst = 0;
				wr_en_o = 0;
				go_pe = 1;
				// CHANGED: 15 -> 24
				for(j = 0; j <= 24; j = j + 1) begin
					weight_en[j] = 0;
				end
				
				// CHANGED: 11 -> 14 (new DOWN_BUF_SIZE)
				if(exe_count == 14) begin 
					pe_ok = 1;
					state_nxt = STORE;
				end
				else begin 
					pe_ok = 0;
					state_nxt = EXE;
				end
			end
			STORE: begin
				wr_en_o = 0;
				// CHANGED: Extended k-check for 5 elements
				if( ((base_a + 1) % k == 0 ) || ((base_a + 2) % k == 0 ) || ((base_a + 3) % k == 0 ) || ((base_a + 4) % k == 0 ) || ((base_a + 5) % k == 0 ) 
				 && ((base_b + 1) % k == 0 ) || ((base_b + 2) % k == 0 ) || ((base_b + 3) % k == 0 ) || ((base_b + 4) % k == 0 ) || ((base_b + 5) % k == 0 )) begin
					state_nxt = OUTPUT;
					temp_ma = temp_ma + 5; // CHANGED: 4 -> 5
				end
				else begin
					base_a = base_a + 5; // CHANGED: 4 -> 5
					base_b = base_b + 5; // CHANGED: 4 -> 5
					
					state_nxt = LOAD;
					output_buf_rst = 0;
				end
			end
			OUTPUT: begin
				wr_en_o = 1'b1; //buffer write
				
				if(out_count == 0) begin
					data_out_o = output_buf[0];
				end
				else if(out_count == 1) begin
					data_out_o = output_buf[1];
				end
				else if(out_count == 2) begin
					data_out_o = output_buf[2];
				end
				else if(out_count == 3) begin
					data_out_o = output_buf[3];
				end
				else if(out_count == 4) begin // ADDED
					data_out_o = output_buf[4];
				end
				
				
				if(((out_count+1) >= out_max) || (out_count == 4)) begin // CHANGED: 3 -> 4
					if(temp_o >= ((((n-1)/5)+1)*m)-1 ) begin // CHANGED: 4 -> 5
						state_nxt = DONE;
					end
					else begin
						output_buf_rst = 1;
						state_nxt = LOAD;
						a_count = a_count + 1;
						
						if(temp_ma >= m) begin
							temp_ma = 0;
							base_a = 0;
							a_count = 1;
							base_b = temp_kb + k;
							temp_kb = temp_kb + k;
							out_max = m;
						end
						else begin
							base_b = temp_kb;
							out_max = out_max - 5; // CHANGED: 4 -> 5
							if( (base_a + 1) % k == 0) base_a = base_a + 1;
							else if( (base_a + 2) % k == 0) base_a = base_a + 2;
							else if( (base_a + 3) % k == 0) base_a = base_a + 3;
							else if( (base_a + 4) % k == 0) base_a = base_a + 4;
							else if( (base_a + 5) % k == 0) base_a = base_a + 5; // ADDED
						end
						index_a = base_a;
						index_b = base_b;
					end
				end
				else begin
					state_nxt = OUTPUT;
				end
			end
			DONE: begin
				wr_en_o = 0;
				done = 1;
			end
			default: begin
			
			end
			
		endcase
	end
	/******** sequential circuit ********/
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			state <= IDLE;
			index_o <= 0;
			/******** buffer reset ********/
			// for(i=0; i<=`LEFT_BUF_SIZE-1; i=i+1) begin
				// left_buf0[i] <= 0;
				// ...
				// left_buf4[i] <= 0;
			// end
			// for(i=0; i<=`DOWN_BUF_SIZE-1; i=i+1) begin
				// down_buf0[i] <= 0;
				// ...
				// down_buf4[i] <= 0;
			// end
			// CHANGED: 4 -> 5
			for(i=0; i<5; i=i+1) begin
				output_buf[i] <= 0;
			end
		end
		else begin
			state <= state_nxt;
			case (state)
				IDLE: begin
					weight_base <= 0;
					out_count <= 0;
					load_count <= 0;
					temp_a <= 0;
					temp_b <= 0;
					temp_o <= 0;
					exe_count <= 0;
				end
				LOAD: begin
					load_count <= load_count + 1;
					exe_count <= 0;
					out_count <= 0;
					// CHANGED: 4 -> 5
					if(output_buf_rst == 1) begin
						for(i=0; i<5; i=i+1) begin
							output_buf[i] <= 0;
						end
					end
					else begin
						for(i=0; i<5; i=i+1) begin
							output_buf[i] <= output_buf[i];
						end
					end
					
					// CHANGED: Load 5 buffers, pack 40-bit data into 80-bit (10*8) buffer lines
					if(load_count == 0 && temp_ma <= m) begin
						{left_buf0[0],left_buf0[1],left_buf0[2],left_buf0[3],left_buf0[4],left_buf0[5],left_buf0[6],left_buf0[7],left_buf0[8],left_buf0[9]} <= {data_in_a, 40'd0};
					end
					else if(load_count == 1 && temp_ma <= m) begin
						{left_buf1[0],left_buf1[1],left_buf1[2],left_buf1[3],left_buf1[4],left_buf1[5],left_buf1[6],left_buf1[7],left_buf1[8],left_buf1[9]} <= {8'd0,data_in_a, 32'd0};
					end
					else if(load_count == 2 && temp_ma <= m) begin
						{left_buf2[0],left_buf2[1],left_buf2[2],left_buf2[3],left_buf2[4],left_buf2[5],left_buf2[6],left_buf2[7],left_buf2[8],left_buf2[9]} <= {16'd0,data_in_a, 24'd0};
					end
					else if(load_count == 3 &&  temp_ma <= m) begin
						{left_buf3[0],left_buf3[1],left_buf3[2],left_buf3[3],left_buf3[4],left_buf3[5],left_buf3[6],left_buf3[7],left_buf3[8],left_buf3[9]} <= {24'd0,data_in_a, 16'd0};
					end
					else if(load_count == 4 &&  temp_ma <= m) begin // ADDED
						{left_buf4[0],left_buf4[1],left_buf4[2],left_buf4[3],left_buf4[4],left_buf4[5],left_buf4[6],left_buf4[7],left_buf4[8],left_buf4[9]} <= {32'd0,data_in_a, 8'd0};
					end
					
					// CHANGED: 3 -> 4
					if(load_count <= 4) begin 
						temp_a <= temp_a + 1; 
						temp_b <= temp_b + 1;
					end
					else begin
						temp_a <= temp_a;
						temp_b <= temp_b;
					end
					
					// CHANGED: 15 -> 20 (5*4), 4 -> 5
					if(weight_base == 20) weight_base <= 0; // 20 is the base for the 5th row
					else weight_base <= weight_base + 5;
				end
				EXE: begin
					weight_base <= 0;
				
					down_buf0[0] <= down_wire0[7:0];
					down_buf1[0] <= down_wire1[7:0];
					down_buf2[0] <= down_wire2[7:0];
					down_buf3[0] <= down_wire3[7:0];
					down_buf4[0] <= down_wire4[7:0]; // ADDED
					
					// CHANGED: 7 -> 9 (LEFT_BUF_SIZE-1)
					for(i = 0; i < 9; i = i + 1) begin
						left_buf0[i] <= left_buf0[i+1];
						left_buf1[i] <= left_buf1[i+1];
						left_buf2[i] <= left_buf2[i+1];
						left_buf3[i] <= left_buf3[i+1];
						left_buf4[i] <= left_buf4[i+1]; // ADDED
					end
					
					// CHANGED: 11 -> 13 (DOWN_BUF_SIZE-1)
					for(i = 0; i < 13; i = i + 1) begin
						down_buf0[i+1] <= down_buf0[i];
						down_buf1[i+1] <= down_buf1[i];
						down_buf2[i+1] <= down_buf2[i];
						down_buf3[i+1] <= down_buf3[i];
						down_buf4[i+1] <= down_buf4[i]; // ADDED
					end
					exe_count <= exe_count + 1;
				end
				STORE: begin
					// CHANGED: New diagonal accumulation logic for 5x5
					// Latency is (5+5-1) = 9
					// buf[i][LATENCY - i]
					output_buf[0] <= output_buf[0] + {down_buf4[5], down_buf3[6], down_buf2[7], down_buf1[8], down_buf0[9]}; // i=0: 9, i=1: 8, i=2: 7, i=3: 6, i=4: 5
					output_buf[1] <= output_buf[1] + {down_buf4[4], down_buf3[5], down_buf2[6], down_buf1[7], down_buf0[8]};
					output_buf[2] <= output_buf[2] + {down_buf4[3], down_buf3[4], down_buf2[5], down_buf1[6], down_buf0[7]};
					output_buf[3] <= output_buf[3] + {down_buf4[2], down_buf3[3], down_buf2[4], down_buf1[5], down_buf0[6]};
					output_buf[4] <= output_buf[4] + {down_buf4[1], down_buf3[2], down_buf2[3], down_buf1[4], down_buf0[5]};
					load_count <= 0;
				end					
				OUTPUT: begin
					out_count <= out_count + 1;
					index_o <= index_o + 1;
					temp_o <= temp_o + 1;
					temp_a <= base_a;
					temp_b <= base_b;
				end
				DONE: begin
				
				end				
				default: begin
				
				end			
			endcase
		end
	end
endmodule
//`endif
