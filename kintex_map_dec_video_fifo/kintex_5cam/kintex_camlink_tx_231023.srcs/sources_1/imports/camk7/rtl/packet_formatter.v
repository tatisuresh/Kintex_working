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
// output          wr_en
);

// wire[4:0]       fifo_not_empty;
// wire[4:0]       rd_en;
// wire[30:0]      data[4 : 0];


assign rd_en_0    = ready ? fifo_not_empty_0 : 1'b0;
assign rd_en_1    = ready ? fifo_not_empty_1 : 1'b0;
assign rd_en_2    = ready ? fifo_not_empty_2 : 1'b0;
assign rd_en_3    = ready ? fifo_not_empty_3 : 1'b0;
assign rd_en_4    = ready ? fifo_not_empty_4 : 1'b0;
							
// assign rd_en[0]   = ready ? fifo_not_empty_0 : 1'b0;
// assign rd_en[1]   = ready ? fifo_not_empty_1 : 1'b0;
// assign rd_en[2]   = ready ? fifo_not_empty_2 : 1'b0;
// assign rd_en[3]   = ready ? fifo_not_empty_3 : 1'b0;
// assign rd_en[4]   = ready ? fifo_not_empty_4 : 1'b0;


// assign fifo_not_empty[0] = fifo_not_empty_0;
// assign fifo_not_empty[1] = fifo_not_empty_1;
// assign fifo_not_empty[1] = fifo_not_empty_2;
// assign fifo_not_empty[2] = fifo_not_empty_3;
// assign fifo_not_empty[3] = fifo_not_empty_4;

// assign data[0] = {3'b000,data_0};
// assign data[1] = {3'b001,data_1};
// assign data[2] = {3'b010,data_2};
// assign data[3] = {3'b011,data_3};
// assign data[4] = {3'b100,data_4};

//integer n;
//
//always @(posedge clk)
//begin
//	if (rstn == 1'b0) begin
//		packeted_data     <= 169'b0;
//		wr_en             <= 1'b0;
//	end else begin		
//		if (ready==1'b1) begin
//			for(n=0; n<5; n= n+1) begin
//				packeted_data[30*(n+1)+n : (30*n)+n] <= {rd_en[n], data[n]};
//			end
//			wr_en 							   <= 1'b1;
//		end else begin
//			wr_en							   <= 1'b0;			
//		end 
//	 end
//			
//end	

// assign packeted_data = {rd_en[4],data[4],rd_en[3],data[3],rd_en[2],data[2],rd_en[1],data[1],rd_en[0],data[0]};
assign packeted_data = {rd_en_4, 3'b100, data_4, rd_en_3, 3'b011, data_3, rd_en_2, 3'b010, data_2, rd_en_1, 3'b001, data_1, rd_en_0, 3'b00, data_0};
// assign wr_en         = ready;
//generate
//genvar n;
//	if (ready==1'b1) begin
//		for(n=0; n<5; n= n+1) begin
//			packeted_data[30*(n+1)+n : (30*n)+n] <= {rd_en[n], data[n]};
//		end
//		wr_en 							   <= 1'b1;
//	end else begin
//		wr_en							   <= 1'b0;			
//	end 
//endgenerate
	
endmodule
					
					