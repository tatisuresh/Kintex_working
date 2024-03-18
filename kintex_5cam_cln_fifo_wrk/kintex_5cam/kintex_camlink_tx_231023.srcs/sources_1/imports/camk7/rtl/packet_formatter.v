//verilog module for packet formation

module packet_formatter(
input           clk,
input           rstn,

input[27:0]     data_0,
input           fifo_not_empty_0,
output          rd_en_0,

input[27:0]     data_1,
input           fifo_not_empty_1,
output          rd_en_1,

input[27:0]     data_2,
input           fifo_not_empty_2,
output          rd_en_2,

input[27:0]     data_3,
input           fifo_not_empty_3,
output          rd_en_3,

input[27:0]     data_4,
input           fifo_not_empty_4,
output          rd_en_4,

input			ready,

output [159:0]  packeted_data

);

assign rd_en_0    = ready ? fifo_not_empty_0 : 1'b0;
assign rd_en_1    = ready ? fifo_not_empty_1 : 1'b0;
assign rd_en_2    = ready ? fifo_not_empty_2 : 1'b0;
assign rd_en_3    = ready ? fifo_not_empty_3 : 1'b0;
assign rd_en_4    = ready ? fifo_not_empty_4 : 1'b0;
assign packeted_data = {rd_en_4, 3'b100, data_4, rd_en_3, 3'b011, data_3, rd_en_2, 3'b010, data_2, rd_en_1, 3'b001, data_1, rd_en_0, 3'b00, data_0};

	
endmodule
					
					