//camlink_rx_reg_interface

module camlink_rx_reg_interface
#(
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	parameter integer C_S_AXI_ADDR_WIDTH	= 32,
	parameter integer LVDS_LINK_WIDTH       = 17,
	parameter integer DESERIALIZATION_RATIO = 8,
	parameter integer IDELAY_TAP_WIDTH      = 5,
	parameter [32:0]  ADDRESS_BASE          = 32'h0000
)
(
	input             											clk,
	input             											rstn,

	input[(LVDS_LINK_WIDTH+1)*IDELAY_TAP_WIDTH - 1 : 0]			idelay_tap_value_out,
	input                                                       idelay_locked,
	
	output                                                      idelay_dyn_clk_inv_en,
	output                                                      idelay_ctrl_reset,
	output                                                      idelay_reset,
	output                                                      idelay_inc,
	output                                                      idelay_inc_valid,
	output[(LVDS_LINK_WIDTH+1)*IDELAY_TAP_WIDTH - 1 : 0]        idelay_tap_value_in,
	
	input                                                       training_done,
	input[DESERIALIZATION_RATIO - 1 : 0]                        lvds_rx_clock_pattern,
	
	output                                                      bitslip_force,
	output                                                      training_enable,
	output[LVDS_LINK_WIDTH*DESERIALIZATION_RATIO - 1 : 0]       training_pattern,
	output                                                      rx_enable,
	
	output                                                      error_counter_reset,
	output                                                      error_counter_snap,
	input                                                       error_counter_flag,
	input[15:0]                                                 error_counter_ecount,
												                
	output reg [31:0]   					                    rd_data,
	output reg                                                  rd_data_valid,
												                
	input                                                       addr_valid,
												                
	input [31:0] 							                    wr_data,
	input                                                       wr_data_valid	

);

function integer nearest_32multiple(input integer num_in);
integer index;
begin

	if(num_in <= 32) begin
		nearest_32multiple = 32;
	end else begin
		while (index < num_in)
		begin
			index = index + 32;
		end
	  nearest_32multiple = index;
	    end		
      end 
endfunction

localparam 	integer				DATA_WIDTH     = LVDS_LINK_WIDTH*DESERIALIZATION_RATIO;
localparam 	integer				IDELAY_TAP_REG  = 2;//nearest_32multiple(8*(LVDS_LINK_WIDTH+1))/32;
localparam 	integer				CLOCK_PTRN_REG = 1;
localparam  integer             REGISTERS_NBR  = 7;//(DATA_WIDTH)/32 + 2*IDELAY_TAP_REG + CLOCK_PTRN_REG + 1;

integer						train_count;
integer						train_count_1;
integer						train_count_2;
integer						idelay_tap_in_count;
integer						idelay_tap_in_count_1;
integer						idelay_tap_in_count_2;
integer						idelay_tap_out_count;
integer						idelay_tap_out_count_1;
integer						idelay_tap_out_count_2;

reg [31:0]		reg_rstvalue[0:REGISTERS_NBR-1];
wire [31:0]		reg_rd_value[0:REGISTERS_NBR-1];
reg [31:0]		reg_wr_value[0:REGISTERS_NBR-1];

reg[REGISTERS_NBR-1:0]		reg_wr_flag;
reg[REGISTERS_NBR-1:0]		reg_rd_flag;

wire 			selected;
wire[28:0]		local_address;
wire[31:0]		wr_addr;

assign local_address          = wr_addr[31:2] - ADDRESS_BASE[32:2];

assign selected = ((local_address[28] == 0) && (local_address < REGISTERS_NBR))? 1'b1 : 1'b0;

integer k;
integer reg_count;

always@(posedge clk)
	begin
		if(rstn == 1'b0) begin	
		  for( k =0; k <= REGISTERS_NBR - 1; k=k+1) begin
			  reg_wr_value[k]				<= 0;
			  reg_rd_flag					<= 0;
			  reg_wr_flag					<= 0;
			  rd_data						<= 0;
		 end	  
		 	  rd_data_valid				    <= 0;

		end else begin
			reg_rd_flag					<= 0;
			reg_wr_flag					<= 0;
			rd_data						<= 0;
			rd_data_valid				<= 0;
			if (selected && addr_valid) begin
				for (reg_count = 0; reg_count <= REGISTERS_NBR-1; reg_count = reg_count + 1) begin
					if (reg_count == local_address) begin
						if (wr_data_valid) begin
							reg_wr_flag[reg_count]	<= 1'b1;
							reg_wr_value[reg_count]	<= wr_data;
						end
						
						reg_rd_flag[reg_count]		<= 1'b1;
						rd_data						<= reg_rd_value[reg_count];
						rd_data_valid				<= 1'b1;
					end
				end
			end
		end
	end

genvar i;
for (i = 0; i <= ((REGISTERS_NBR - 1) - (2*IDELAY_TAP_REG) - 1 - CLOCK_PTRN_REG); i = i + 1) begin
	if(DATA_WIDTH < (i+1)*32) begin
		assign training_pattern [DATA_WIDTH - 1 : (i*32)]  = reg_wr_value[i+1][DATA_WIDTH - i*32 - 1 : 0];
	end 
    if(DATA_WIDTH >= (i+1)*32) begin
	   assign	training_pattern[(i+1)*32 - 1 : i*32]    = reg_wr_value[i+1];
	end 
	assign reg_rd_value[i + 1]               = reg_wr_value[i + 1];
end 
	
for (i = 0; i <= IDELAY_TAP_REG - 1; i = i + 1) begin
genvar j;
  if((LVDS_LINK_WIDTH + 1)*8 >= (i+1)*32) begin
	for (j=0; j<= 32/8 - 1; j=j+1) begin
      assign idelay_tap_value_in[j*IDELAY_TAP_WIDTH + IDELAY_TAP_WIDTH - 1 + (i*4*IDELAY_TAP_WIDTH) : j*IDELAY_TAP_WIDTH + (i*4*IDELAY_TAP_WIDTH)]  = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -2*IDELAY_TAP_REG][j*8 + IDELAY_TAP_WIDTH - 1 : j*8];
    end 
  end 
  if((LVDS_LINK_WIDTH + 1)*8 < (i+1)*32) begin
   // genvar j;
    for (j = 0; j<= ((LVDS_LINK_WIDTH + 1)*8 - i*32)/8 - 1; j=j+1) begin
     assign idelay_tap_value_in[j*IDELAY_TAP_WIDTH + IDELAY_TAP_WIDTH - 1 + (i*4*IDELAY_TAP_WIDTH) : j*IDELAY_TAP_WIDTH + (i*4*IDELAY_TAP_WIDTH)]  = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -2*IDELAY_TAP_REG][j*8 + IDELAY_TAP_WIDTH - 1 : j*8];
    end 
  end 
  assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -2*IDELAY_TAP_REG] = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -2*IDELAY_TAP_REG];
end
for (i = 0; i<= IDELAY_TAP_REG - 1; i=i+1) begin
genvar j;
   if((LVDS_LINK_WIDTH + 1)*8 > (i+1)*32) begin
	for (j=0; j<= 32/8 - 1; j=j+1) begin
     assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][j*8 + IDELAY_TAP_WIDTH - 1 : j*8]    = idelay_tap_value_out[j*IDELAY_TAP_WIDTH + IDELAY_TAP_WIDTH - 1 : j*IDELAY_TAP_WIDTH];
     assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][(j+1)*8 - 1 : j*8 + IDELAY_TAP_WIDTH] = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -IDELAY_TAP_REG][(j+1)*8 - 1 : j*8 + IDELAY_TAP_WIDTH];
    end 
  end 
   if((LVDS_LINK_WIDTH + 1)*8 == (i+1)*32) begin
    for (j=0; j<= 32/8 - 1; j=j+1)  begin
     assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][j*8 + IDELAY_TAP_WIDTH - 1 : j*8]    = idelay_tap_value_out[j*IDELAY_TAP_WIDTH + IDELAY_TAP_WIDTH - 1 : j*IDELAY_TAP_WIDTH];
     assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][(j+1)*8 - 1 : j*8 + IDELAY_TAP_WIDTH] = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -IDELAY_TAP_REG][(j+1)*8 - 1 : j*8 + IDELAY_TAP_WIDTH];
    end 
  end 
   if((LVDS_LINK_WIDTH + 1)*8 < (i+1)*32) begin
    for (j=0; j<= ((LVDS_LINK_WIDTH + 1)*8 - i*32)/8 - 1; j=j+1) begin
     assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][j*8 + IDELAY_TAP_WIDTH - 1 : j*8]    = idelay_tap_value_out[j*8 + IDELAY_TAP_WIDTH - 1 : j*8];
     assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][(j+1)*8 - 1 : j*8 + IDELAY_TAP_WIDTH] = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 -IDELAY_TAP_REG][(j+1)*8 - 1 : j*8 + IDELAY_TAP_WIDTH];
    end  
    assign reg_rd_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][32 - 1 : (LVDS_LINK_WIDTH + 1)*8 - i*32]  = reg_wr_value[i+1+REGISTERS_NBR - CLOCK_PTRN_REG - 1 - IDELAY_TAP_REG][32 - 1 : (LVDS_LINK_WIDTH + 1)*8 - i*32];
  end 
end 

assign training_enable               = reg_wr_value[0][0];
assign bitslip_force                 = reg_wr_value[0][1];
assign idelay_ctrl_reset             = reg_wr_value[0][2];
assign idelay_reset                  = reg_wr_value[0][3];
assign idelay_inc                    = reg_wr_value[0][4];
assign idelay_inc_valid              = reg_wr_value[0][5];
assign error_counter_reset           = reg_wr_value[0][6];
assign error_counter_snap            = reg_wr_value[0][7];
assign idelay_dyn_clk_inv_en         = reg_wr_value[0][8];
assign rx_enable                     = reg_wr_value[0][9];

assign reg_rd_value[0][9 : 0]        = reg_wr_value[0][9 : 0];
assign reg_rd_value[0][10]           = idelay_locked;
assign reg_rd_value[0][11]           = training_done;
assign reg_rd_value[0][12]           = error_counter_flag;
assign reg_rd_value[0][15 : 13]      = reg_wr_value[0][15 : 13];
assign reg_rd_value[0][31 : 16]      = error_counter_ecount;

 //last register stores clock pattern
assign reg_rd_value[REGISTERS_NBR - 1][DESERIALIZATION_RATIO - 1 : 0]   = lvds_rx_clock_pattern;
assign reg_rd_value[REGISTERS_NBR - 1][32 - 1 : DESERIALIZATION_RATIO]  = reg_wr_value[REGISTERS_NBR - 1][32 - 1 : DESERIALIZATION_RATIO];

	
endmodule