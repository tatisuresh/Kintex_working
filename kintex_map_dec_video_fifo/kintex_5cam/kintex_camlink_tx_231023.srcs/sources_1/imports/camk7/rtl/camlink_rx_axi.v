//verilog 

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
	
	// input                  clk_idelay_ctrl,
	// input                  video_clk_1x,	
	// input                  video_clk_7x,	
	// input                  reset,
	// input                  user_clock,
	
//	input                  camlink_rx_clk_p,
//	input                  camlink_rx_clk_n,
//	input[3:0]             camlink_rx_data_p,
//	input[3:0]             camlink_rx_data_n,
	
	// output                 camlink_rx_clk_to_pll,
	
	input                  video_data_out_valid,
	output[27:0]           video_data_out,
	output                 rx_buffer_full_flag,
	output                 rx_buffer_ready,

	// output [31:0]          rd_data,
	// output                 rd_data_valid,
						   
	// input                  addr_valid,
						   
	// input [31:0] 		   wr_data,
	// input                  wr_data_valid,
    input [27:0]           camlink_data_in
	// output[39:0]           dbg_sig

);

// function nearest_2power(input integer in ) ;
  // integer ret_nearest_2power ;
// begin
    // ret_nearest_2power = 2;
  // while (in > ret_nearest_2power) begin
    // nearest_2power = 2*nearest_2power;
  // end 
   // nearest_2power = ret_nearest_2power; 
// end endfunction 

//function log2_of( input integer in ) ;
//  integer ret_log2 ;
//  begin
//  assign ret_log2 = 0;
//  if (in == 1) begin
//    log2_of = 0;
//  end 
//  while (2*ret_log2 < in) begin
//    log2_of = ret_log2 + 1;
//  end 
//  //return ret_log2;
//end endfunction 

// wire  idelay_ctrl_reset_axi            ;
// wire  idelay_reset_axi                 ;
// wire  idelay_inc_axi                   ;
// wire  idelay_inc_valid_axi             ;
// wire  idelay_dyn_clk_inv_en_axi        ;

// wire  [IDELAY_TAP_WIDTH * (LVDS_LINK_WIDTH + 1) - 1 : 0]  idelay_tap_value_in_axi   ;
// reg   [IDELAY_TAP_WIDTH * (LVDS_LINK_WIDTH + 1) - 1 : 0]  idelay_tap_value_out_axi  ;

// reg  idelay_locked_axi                ;
// wire training_enable_axi              ;

// wire [LVDS_LINK_WIDTH * DESERIALIZATION_RATIO - 1 : 0]  training_pattern_axi       ;

// wire  bitslip_force_axi                ;
// reg   training_done_axi                ;

// reg [DESERIALIZATION_RATIO - 1 : 0]  lvds_rx_clock_pattern_axi                    ;

// wire  rx_enable_axi                    ;
// reg  idelay_ctrl_reset_metastable     ;
// reg  idelay_reset_metastable          ;
// reg  idelay_inc_metastable            ;
// reg  idelay_inc_valid_metastable      ;
// reg  idelay_dyn_clk_inv_en_metastable ;

// reg[IDELAY_TAP_WIDTH * (LVDS_LINK_WIDTH + 1) - 1 : 0]  idelay_tap_value_in_metastable  ;
// reg[IDELAY_TAP_WIDTH * (LVDS_LINK_WIDTH + 1) - 1 : 0]  idelay_tap_value_out_metastable ;

// reg  idelay_locked_metastable         ;
// reg  training_enable_metastable       ;

// reg[LVDS_LINK_WIDTH * DESERIALIZATION_RATIO - 1 : 0]  training_pattern_metastable      ;

// reg  bitslip_force_metastable         ;
// reg  training_done_metastable         ;

// reg[DESERIALIZATION_RATIO - 1 : 0]  lvds_rx_clock_pattern_metastable ;

// reg  rx_enable_metastable             ;
// reg  idelay_ctrl_reset                ;
// reg  idelay_reset                     ;
// reg  idelay_inc                       ;
// reg  idelay_inc_valid                 ;
// reg  idelay_dyn_clk_inv_en            ;

// reg[IDELAY_TAP_WIDTH * (LVDS_LINK_WIDTH + 1) - 1 : 0]  idelay_tap_value_in           ;
// wire[IDELAY_TAP_WIDTH * (LVDS_LINK_WIDTH + 1) - 1 : 0]  idelay_tap_value_out          ;

// wire  idelay_locked                    ;
// reg  training_enable                  ;

// reg[LVDS_LINK_WIDTH * DESERIALIZATION_RATIO - 1 : 0]  training_pattern               ;

// reg  bitslip_force                    ;
// wire training_done                    ;

// wire [DESERIALIZATION_RATIO - 1 : 0]  lvds_rx_clock_pattern                            ;

// reg  rx_enable                        ;
  
// wire[27:0]  data_out                   ;
 wire[27:0]  video_data_in              ;
 reg [27:0]  video_data_in_d            ;
 reg [27:0]  video_data_in_2d            ;
 reg         video_data_in_valid        ;
 reg         video_data_in_valid_d       ;
 
 // wire [11:0] zero_12bit;
 // wire [39:0] dbg_sig;
  
// reg         training_done_stable       ;
// reg         training_done_stable_1d    ;
// reg         training_enable_axi_1d     ;
  
// wire[23:0]  prbs_data_error            ;
// reg         error_counter_reset        ;
// reg         error_counter_snap         ;
// wire        error_counter_flag         ;
// wire [15:0]   error_counter_ecount       ;
// reg         error_counter_reset_metastable   ;
// reg         error_counter_snap_metastable    ;
// reg         error_counter_flag_metastable    ;
// reg[15:0]   error_counter_ecount_metastable  ;
// wire        error_counter_reset_axi          ;
// wire        error_counter_snap_axi           ;
// reg         error_counter_flag_axi           ;
// reg[15:0]   error_counter_ecount_axi         ;
wire        rst                              ;
wire        read_fifo_empty                  ;
// reg         prbs_error_valid                 ;

// camlink_rx_reg_interface #(
    // .ADDRESS_BASE          ( ADDRESS_BASE),
    // .LVDS_LINK_WIDTH       ( LVDS_LINK_WIDTH),
    // .DESERIALIZATION_RATIO ( DESERIALIZATION_RATIO),
    // .IDELAY_TAP_WIDTH      ( IDELAY_TAP_WIDTH)
    // )
// camlink_rx_reg_interface_inst(
    // .clk              ( clk),
    // .rstn             ( rstn),

    // .idelay_ctrl_reset     ( idelay_ctrl_reset_axi),
    // .idelay_reset          ( idelay_reset_axi),
    // .idelay_inc            ( idelay_inc_axi),
    // .idelay_inc_valid      ( idelay_inc_valid_axi),
    // .idelay_dyn_clk_inv_en ( idelay_dyn_clk_inv_en_axi),
    // .idelay_tap_value_in   ( idelay_tap_value_in_axi),
    // .idelay_tap_value_out  ( idelay_tap_value_out_axi),
    // .idelay_locked         ( idelay_locked_axi),
    
    // .training_enable       ( training_enable_axi),
    // .training_pattern      ( training_pattern_axi),
    // .bitslip_force         ( bitslip_force_axi),
    // .training_done         ( training_done_axi),
    // .rx_enable             ( rx_enable_axi),
    
    // .lvds_rx_clock_pattern ( lvds_rx_clock_pattern_axi),
    
    // .error_counter_reset   ( error_counter_reset_axi),  
    // .error_counter_snap    ( error_counter_snap_axi),   
    // .error_counter_flag    ( error_counter_flag_axi),   
    // .error_counter_ecount  ( error_counter_ecount_axi ),
	// .rd_data               ( rd_data        ),          
	// .rd_data_valid         ( rd_data_valid  ),
	// .addr_valid            ( addr_valid     ),        
    // .wr_data               ( wr_data        ),         
	// .wr_data_valid         ( wr_data_valid  ) 	
  // );
//
////synchronizer logic for video_clk_1x
//always@(posedge video_clk_1x) begin
//   idelay_reset_metastable           <=  idelay_reset_axi;
//   idelay_reset                      <=  idelay_reset_metastable;
//    
//   idelay_inc_metastable             <=  idelay_inc_axi;
//   idelay_inc                        <=  idelay_inc_metastable;
//    
//   idelay_inc_valid_metastable       <=  idelay_inc_valid_axi;
//   idelay_inc_valid                  <=  idelay_inc_valid_metastable;
//    
//   idelay_dyn_clk_inv_en_metastable  <=  idelay_dyn_clk_inv_en_axi;
//   idelay_dyn_clk_inv_en             <=  idelay_dyn_clk_inv_en_metastable;
//    
//   idelay_tap_value_in_metastable    <=  idelay_tap_value_in_axi;
//   idelay_tap_value_in               <=  idelay_tap_value_in_metastable;
//    
//   training_enable_metastable        <=  training_enable_axi;
//   training_enable                   <=  training_enable_metastable;
//    
//   training_pattern_metastable       <=  training_pattern_axi;
//   training_pattern                  <=  training_pattern_metastable;
//    
//   bitslip_force_metastable          <=  bitslip_force_axi;
//   bitslip_force                     <=  bitslip_force_metastable;
//    
//   rx_enable_metastable              <=  rx_enable_axi;
//   rx_enable                         <=  rx_enable_metastable;
//    
//   error_counter_reset_metastable    <=  error_counter_reset_axi;  
//   error_counter_reset               <=  error_counter_reset_metastable; 
//    
//   error_counter_snap_metastable     <=  error_counter_snap_axi;
//   error_counter_snap                <=  error_counter_snap_metastable;  
//    
//  
//end 
//
////synchronizer logic for clk
//always@(posedge clk) begin
//
//    idelay_tap_value_out_metastable <=  idelay_tap_value_out;
//    idelay_tap_value_out_axi        <=  idelay_tap_value_out_metastable;
//  
//    idelay_locked_metastable        <=  idelay_locked;
//    idelay_locked_axi               <=  idelay_locked_metastable;
//  
//    training_done_metastable        <=  training_done;
//    training_done_stable            <=  training_done_metastable;
//    training_done_stable_1d         <=  training_done_stable;
//  
//    training_enable_axi_1d          <=  training_enable_axi;
//  
//    if(training_enable_axi==1'b1 && training_enable_axi_1d == 1'b0) begin
//		training_done_axi <=  1'b0;
//    end else if(training_done_stable == 1'b1 && training_done_stable_1d == 1'b0) begin
//		training_done_axi <=  1'b1;
//    end
//
//    error_counter_flag_metastable     <= error_counter_flag;  
//    error_counter_ecount_metastable   <= error_counter_ecount;
//    lvds_rx_clock_pattern_metastable  <= lvds_rx_clock_pattern;
//  
//    error_counter_flag_axi            <= error_counter_flag_metastable;
//    error_counter_ecount_axi          <= error_counter_ecount_metastable;
//  
//    lvds_rx_clock_pattern_axi         <= lvds_rx_clock_pattern_metastable;    
//
//end
//
//always@(posedge clk_idelay_ctrl)begin
//
//   idelay_ctrl_reset_metastable  <=  idelay_ctrl_reset_axi;
//   idelay_ctrl_reset             <=  idelay_ctrl_reset_metastable;
//
//end
//
//lvds_receiver_top #(
//    .SIMULATION                (  SIMULATION),
//    .IDELAY_REFCLK_FREQUENCY   (  IDELAY_REFCLK_FREQUENCY),
//    .DEVICE                    (  "7Series"),
//    .DATA_RATE                 (  DATA_RATE),
//    .LVDS_LINK_WIDTH           (  LVDS_LINK_WIDTH),
//    .DESERIALIZATION_RATIO     (  DESERIALIZATION_RATIO),
//    .IDELAY_TAP_WIDTH          (  IDELAY_TAP_WIDTH)
//    )
// lvds_receiver_top_inst(
//    .clk_idelay_ctrl       (  clk_idelay_ctrl),
//    .idelay_ctrl_reset     (  idelay_ctrl_reset),
//    .idelay_reset          (  idelay_reset),
//    .idelay_inc            (  idelay_inc),
//    .idelay_inc_valid      (  idelay_inc_valid),
//    .idelay_dyn_clk_inv_en (  idelay_dyn_clk_inv_en),
//    .idelay_tap_value_in   (  idelay_tap_value_in),
//    .idelay_tap_value_out  (  idelay_tap_value_out),
//    .idelay_locked         (  idelay_locked),
//    .lvds_rx_clock_to_pll  (  camlink_rx_clk_to_pll),
//    
//    .lvds_rx_clock_pattern (  lvds_rx_clock_pattern),
//    .lvds_rx_clock_p       (  camlink_rx_clk_p),
//    .lvds_rx_clock_n       (  camlink_rx_clk_n),
//    .bitslip_force         (  bitslip_force),
//    .training_enable       (  training_enable),
//    .training_pattern      (  training_pattern),
//    .lvds_rx_data_p        (  camlink_rx_data_p),
//    .lvds_rx_data_n        (  camlink_rx_data_n),
//    .lvds_rx_clock         (  video_clk_7x),
//    .lvds_rx_clock_div     (  video_clk_1x),
//    .training_done         (  training_done),
//    .data_out              (  data_out)
//    );

assign rst = ~ rstn;

//prbs_gen_check
////#(      
////    .NBITS       (24),
////    .CHK_MODE    (true)
////)
// prbs_gen_check_inst (
//    .RST         ( rst),      
//    .CLK         ( video_clk_1x),  
//    .DATA_IN     ( video_data_in[23:0]),     
//    .EN          ( video_data_in[25]),   
//	.insert_error(1'b0),
//	.sync        (1'b0),
//    .DATA_OUT    ( prbs_data_error)
//  );
//
//error_counter #(
//	.count_width ( 16),
//	.data_width  ( 24)
//  )
//error_counter_inst(
//	.rst          ( rstn),          
//	.clk          ( video_clk_1x), 
//	.ce           ( 1'b1),               
//	
//    .valid_in     ( 1'b1),                    
//	.din          ( prbs_data_error),        
//	.din_ref      ( 24'b0 ),        
//	.rst_count    ( error_counter_reset),    
//	.snap_count   ( error_counter_snap),     
//	
//	.eflag        ( error_counter_flag),                  
//    .s_ecount     ( error_counter_ecount),               
//    .s_count      (  )                 
//	);

// NEEDS to be chked and modified according to DATASHEET 

//video_data_in <=  data_out(6)  & data_out(10) & (data_out(2) and data_out(10))  & data_out(3)  &  data_out(23) & data_out(27) & data_out(4)                     & data_out(8)  &  --red[7:4]  pix[23]:
//                  data_out(12) & data_out(16) & data_out(20)                    & data_out(24) &  --red[3:0]         : 
//                  data_out(15) & data_out(19) & data_out(9)                     & data_out(13) &  --green[7:4]       :
//                  data_out(17) & data_out(21) & data_out(25)                    & data_out(0)  &  --green[3:0]       :
//                  data_out(7)  & data_out(11) & data_out(14)                    & data_out(18) &  --blue[7:4]        :
//                 data_out(22) & data_out(26) & data_out(1)                     & data_out(5) ;   --blue[3:0]        :pix[0]
// NOt required 
/*
assign video_data_in = {data_out[6],data_out[10],data_out[2]} & 
					   {data_out[10],data_out[3],data_out[23],
					    data_out[27],data_out[4],data_out[12],
						data_out[16],data_out[20],data_out[24],
						data_out[15],data_out[19],data_out[9],
						data_out[13],data_out[17],data_out[21],
						data_out[25],data_out[0],data_out[7],
						data_out[11],data_out[14],data_out[18],
						data_out[22],data_out[26],data_out[1],data_out[5]};
*/

// assign video_data_in = {camlink_data_in[6],camlink_data_in[10],camlink_data_in[2]} & 
					   // {camlink_data_in[10],camlink_data_in[3],camlink_data_in[23],
					    // camlink_data_in[27],camlink_data_in[4],camlink_data_in[12],
						// camlink_data_in[16],camlink_data_in[20],camlink_data_in[24],
						// camlink_data_in[15],camlink_data_in[19],camlink_data_in[9],
						// camlink_data_in[13],camlink_data_in[17],camlink_data_in[21],
						// camlink_data_in[25],camlink_data_in[0],camlink_data_in[7],
						// camlink_data_in[11],camlink_data_in[14],camlink_data_in[18],
						// camlink_data_in[22],camlink_data_in[26],camlink_data_in[1],camlink_data_in[5]};

// always@(posedge clk) begin

   // video_data_in_d          <=  camlink_data_in;
   // video_data_in_2d         <=  video_data_in_d;
   // video_data_in_valid      <=  cam_sync & cam_clk;
   // video_data_in_valid_d    <=  video_data_in_valid;
   //prbs_error_valid      <=  video_data_in[25];

// end 

// module ila_0 (
  // input clk_in,
  // input probe0
// );


// ila_0_inst ila_0 (
// .clk_in(cam_clk),
// .dbg_sig()

// );



// Signal assignments
//assign dbg_sig = {zero_12bit[5:0], pll_locked_1, clk_71mhz, rd_en_0, camlink_data_in_0, reset_n, video_data_in, cam_sync};

// assign dbg_sig = {8'b0, video_data_in_valid, video_data_in, cam_sync, read_fifo_empty, video_data_out_valid};
  wire                                       lfifo_full;
  wire                                       lfifo_empty;
  wire                                       lfifo_rst;
  wire                                       lfifo_wrreq;
  wire [27:0]                lfifo_wrdata;
// endmodule

  
 reg valid_en ;        // Output valid signal


reg hsync_prev;  // Previous state of hsync signal

// Detect rising edge of hsync signal
always @(negedge cam_clk) begin
    hsync_prev <= lfifo_wrdata[24];
end

// Generate valid signal between hsync pulses
always @(negedge cam_clk) begin
    if (!hsync_prev && lfifo_wrdata[24]) begin
        valid_en <= 1'b1;  // Hsync pulse detected
    end else begin
        valid_en <= 1'b0;  // Between hsync pulses
    end
end

// Line Buffer Control
assign lfifo_rst   = rst;  // Ensure proper reset
assign lfifo_full  = rx_buffer_full_flag;
assign lfifo_wrreq = cam_sync & ~lfifo_full;  // Request write when cam_sync is active and buffer is not full

async_fifo_28by256 fifo_inst(
    .rst           (lfifo_rst),
    .wr_clk        (cam_clk),
    .wr_en         (lfifo_wrreq),
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

