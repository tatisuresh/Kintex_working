
module camlink_rx_axi 
#(
parameter SIMULATION                 = "FALSE",
parameter IDELAY_REFCLK_FREQUENCY    = 200,
parameter DEVICE                     = "Virtex6",
parameter IDELAY_TAP_WIDTH           = 5,
parameter DESERIALIZATION_RATIO      = 7,
parameter LVDS_LINK_WIDTH            = 4,
parameter DATA_RATE                  = "SDR",
parameter [32:0] ADDRESS_BASE        = 32'h0000
)
(
	input                  clk,
	input                  rstn,
	input                  cam_clk,
	input                  cam_sync,
	input                  video_data_out_valid,
	input [27:0]           camlink_data_in,
	output[27:0]           video_data_out,
	output                 rx_buffer_full_flag,
	output                 rx_buffer_ready
);
// Signal assignments
 wire[27:0]  video_data_in              ;
 reg [27:0]  video_data_in_d            ;
 reg [27:0]  video_data_in_2d            ;
 reg         video_data_in_valid        ;
 reg         video_data_in_valid_d       ;
wire        rst                              ;
wire        read_fifo_empty                  ;
assign rst = ~ rstn;

// Line Buffer Control
assign fifo_wrreq = cam_sync & ~rx_buffer_full_flag;  // Request write when cam_sync is active and buffer is not full

async_fifo_28by256 fifo_inst(
    .rst           (rst),
    .wr_clk        (cam_clk),
    .wr_en         (fifo_wrreq),
    .wr_data_count (),
    .din           (camlink_data_in),
    .full          (),
    .almost_full   (rx_buffer_full_flag),
    .rd_clk        (clk),
    .rd_en         (video_data_out_valid),
    .rd_data_count (),
    .dout          (video_data_out),
    .empty         (read_fifo_empty),
    .almost_empty  (),
    .wr_rst_busy   (),
    .rd_rst_busy   ()
);

assign rx_buffer_ready = ~read_fifo_empty;
 endmodule

