///////////////////////////////////////////////////////////////////////////////
//
//    File Name:  lvds_transmitter.v
//      Version:  1.0
//         Date:  
//        Model:  
//
///////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------

module lvds_transmitter
#( 
  parameter                                                 SIMULATION          = "FALSE",
  parameter                                                 DATA_RATE_OQ        = "SDR",
  parameter                                                 DATA_RATE_TQ        = "SDR",
  parameter                                                 DEVICE              = "Virtex6",      // valid values "Virtex6", "7Series"
  parameter                                                 LVDS_LINK_WIDTH     = 17,
  parameter                                                 SERIALIZATION_RATIO = 8
)
(
  input                                                     txclk,                 //SERIAL SIDE TX CLOCK
  input                                                     txclk_div,             //PARALLEL SIDE TX CLOCK (DIVIDED FROM txclk)
  input                                                     txclk_phase_shifted,   //PHASE SHIFTED SERIAL SIDE TX CLOCK
  input                                                     txclk_div_reset,       //TX DOMAIN txclk_div_reset
    
  output   [LVDS_LINK_WIDTH - 1 : 0]                        lvds_tx_data_p,        //SERIAL SIDE TX DATA (P)
  output   [LVDS_LINK_WIDTH - 1 : 0]                        lvds_tx_data_n,        //SERIAL SIDE TX DATA (N)
  output                                                    lvds_tx_clock_p,       //FORWARDED CLOCK TO RX (P)
  output                                                    lvds_tx_clock_n,       //FORWARDED CLOCK TO RX (N)
    
  input                                                     training_enable,       //active high value indicates that training pattern is transmitting
  input    [LVDS_LINK_WIDTH * SERIALIZATION_RATIO - 1 : 0]  training_pattern,      //value of training pattern
  input    [LVDS_LINK_WIDTH * SERIALIZATION_RATIO - 1 : 0]  data_in
);

wire  TXCLK_DELAYED;

wire  TX_CLOCK_PREBUF;
wire  [LVDS_LINK_WIDTH - 1 : 0]  TX_DATA_PREBUF;
reg   [LVDS_LINK_WIDTH - 1 : 0]  TX_DATA_PREBUF1;

////add pipeline reg for txclk_div_reset////
////modified by Joyce on 02/25/11////

wire RESET_FF1 /* synthesis syn_keep = 1 */;
wire RESET_FF2 /* synthesis syn_keep = 1 */;

FD  FD_RESET_FF1(.D(txclk_div_reset),.C(txclk_div),.Q(RESET_FF1));
FD  FD_RESET_FF2(.D(RESET_FF1),.C(txclk_div),.Q(RESET_FF2));


///////////////////////////////////////
wire  [LVDS_LINK_WIDTH * 8 - 1 : 0]  OSERDESE2_DATA_IN;
wire  [LVDS_LINK_WIDTH * 8 - 1 : 0]  OSERDESE2_DATA_IN1;

reg [LVDS_LINK_WIDTH * SERIALIZATION_RATIO - 1 : 0] DATA_TO_OSERDES_REG;
reg training_enable_1d;
reg [2:0] counter = 3'b0;


//DATA SOURCE: TRAINING PAT OR PRBS
//IF NO FEEDBACK CONTROLS FROM RX ARE DESIRED, THE TX CAN BE SET TO SEND THE
//TRAINING PATTERN FOR A FIXED AMOUNT OF TIME, AFTER WHICH IT AUTOMATICALLY
//ASSUMES THAT TRAINING IS COMPLETE AND BEGINS SENDING USER DATA.

always@(posedge txclk_div)
begin
  training_enable_1d <= training_enable;
end

generate
  genvar m;
  genvar n;
  for(m = 0; m < LVDS_LINK_WIDTH; m = m + 1)
  begin:transform_data_on_lvds_links
    for(n = 0; n < SERIALIZATION_RATIO; n = n + 1)
    begin:transform_data_on_lvds_links_in_time
      always @(posedge txclk_div) begin
        if(training_enable)
          DATA_TO_OSERDES_REG[m*SERIALIZATION_RATIO + n] <= training_pattern[n*LVDS_LINK_WIDTH + m];  //TRAINING PATTERN
        else
          DATA_TO_OSERDES_REG[m*SERIALIZATION_RATIO + n] <= data_in[n*LVDS_LINK_WIDTH + m];           //PRBS
      end      
    end
  end
endgenerate


////////////////////////////////////////////////////////////////////////////////
// CLOCK RELATED
////////////////////////////////////////////////////////////////////////////////

//FORWARDED CLOCK
ODDR 
  #(
      .DDR_CLK_EDGE("OPPOSITE_EDGE"),
      .INIT(1'b0),
      .SRTYPE("SYNC")
    )
  ODDR_TX_CLOCK(
      .Q(TX_CLOCK_PREBUF),
      .C(txclk_phase_shifted),
      .CE(1'b1),
      .D1(1'b1),
      .D2(1'b0),
      .R(1'b0),
      .S(1'b0)
    );

//FORWARDED CLOCK OUTPUT BUFFER
OBUFDS 
  OBUFDS_TX_CLOCK(
      .O(lvds_tx_clock_p),
      .OB(lvds_tx_clock_n),
      .I(TX_CLOCK_PREBUF)
    );

////////////////////////////////////////////////////////////////////////////////
//MASTER OSERDES IN DATA PATH
////////////////////////////////////////////////////////////////////////////////

    generate
      wire  [LVDS_LINK_WIDTH : 0] ocascade_sm_d;
      wire  [LVDS_LINK_WIDTH : 0] ocascade_sm_t;
    begin
    if ((DEVICE == "Virtex6") && (SIMULATION == "FALSE"))
    begin
      genvar i;
      for (i = 0; i < LVDS_LINK_WIDTH; i = i + 1)
      begin : gen_oserdes
          OSERDESE1
          # (
            .DATA_RATE_OQ   (DATA_RATE_OQ),
            .DATA_RATE_TQ   (DATA_RATE_TQ),
            .DATA_WIDTH     (SERIALIZATION_RATIO),
            .INTERFACE_TYPE ("DEFAULT"),
            .TRISTATE_WIDTH (1),
            .SERDES_MODE    ("MASTER"))
          oserdese1_master (
            .D1             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+0]),
            .D2             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+1]),
            .D3             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+2]),
            .D4             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+3]),
            .D5             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+4]),
            .D6             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+5]),
            .T1             (1'b0),
            .T2             (1'b0),
            .T3             (1'b0),
            .T4             (1'b0),
            .SHIFTIN1       (ocascade_sm_d[i]),
            .SHIFTIN2       (ocascade_sm_t[i]),
            .SHIFTOUT1      (),
            .SHIFTOUT2      (),
            .OCE            (1'b1),
            .CLK            (txclk),
            .CLKDIV         (txclk_div),
            .CLKPERF        (1'b0), // used only in DDR3 mode
            .CLKPERFDELAY   (1'b0), // used in DDR3 mode only
            .WC             (1'b0), // DDR3 mode only
            .ODV            (1'b0), // DDR3 mode only
            .OQ             (TX_DATA_PREBUF[i]),
            .TQ             (),
            .OCBEXTEND      (), // DDR3
            .OFB            (),
            .TFB            (),
            .TCE            (1'b0),
            .RST            (RESET_FF2));
       
        if (((SERIALIZATION_RATIO > 6) && (SERIALIZATION_RATIO < 9) && (DATA_RATE_OQ == "SDR")) ||
            ((SERIALIZATION_RATIO == 8) && (DATA_RATE_OQ == "DDR")))
        begin
          OSERDESE1
          #  (
              .DATA_RATE_OQ   (DATA_RATE_OQ),
              .DATA_RATE_TQ   (DATA_RATE_TQ),
              .DATA_WIDTH     (SERIALIZATION_RATIO),
              .TRISTATE_WIDTH (1),
              .INTERFACE_TYPE ("DEFAULT"),
              .SERDES_MODE    ("SLAVE"))
            oserdese1_slave (
              .D1             (1'b0), 
              .D2             (1'b0), 
              .D3             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+6]),
              .D4             (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+7]),
              .D5             (1'b0),
              .D6             (1'b0),
              .T1             (1'b0),
              .T2             (1'b0),
              .T3             (1'b0),
              .T4             (1'b0),
              .SHIFTOUT1      (ocascade_sm_d[i]),
              .SHIFTOUT2      (ocascade_sm_t[i]),
              .SHIFTIN1       (1'b0),
              .SHIFTIN2       (1'b0),
              .OCE            (1'b1),
              .CLK            (txclk),
              .CLKDIV         (txclk_div),
              .CLKPERF        (1'b0), // used only in DDR3 mode
              .CLKPERFDELAY   (1'b0), // used in DDR3 mode only
              .WC             (1'b0), // DDR3 mode only
              .ODV            (1'b0), // DDR3 mode only
              .OQ             (), //data_out_to_pins_predelay[pin_count]),
              .TQ             (),
              .OCBEXTEND      (), // DDR3
              .OFB            (),
              .TFB            (),
              .TCE            (1'b0),
              .RST            (RESET_FF2));
          end
          genvar j;
          for (j = 0; j < SERIALIZATION_RATIO; j = j + 1)
          begin : gen_oserdes_data_in
            assign OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i + j] = DATA_TO_OSERDES_REG[SERIALIZATION_RATIO*i + j];
          end
        end
      end
    end
    endgenerate

    generate
    if ((DEVICE == "7Series") && (SIMULATION == "FALSE"))
    begin
      genvar i;
      for (i = 0; i < LVDS_LINK_WIDTH; i = i + 1)
      begin : gen_oserdes
        OSERDESE2 #(
          .DATA_WIDTH       (SERIALIZATION_RATIO),
          .DATA_RATE_OQ     (DATA_RATE_OQ),
          .DATA_RATE_TQ     (DATA_RATE_TQ),
          .TRISTATE_WIDTH   (1)
        ) 
        OSERDES_TX_DATA (
          .OFB              (),
          .OQ               (TX_DATA_PREBUF[i]),
          .TFB              (),
          .TQ               (),
          .SHIFTOUT1        (),
          .SHIFTOUT2        (),
          .TBYTEOUT         (),
          .CLK              (txclk),
          .CLKDIV           (txclk_div),
          .OCE              (1'b1),
          .RST              (RESET_FF2),
          .D1               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+0]),
          .D2               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+1]),
          .D3               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+2]),
          .D4               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+3]),
          .D5               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+4]),
          .D6               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+5]),
          .D7               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+6]),
          .D8               (OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i+7]),
          .SHIFTIN1         (1'b0),
          .SHIFTIN2         (1'b0),
          .T1               (1'b0),
          .T2               (1'b0),
          .T3               (1'b0),
          .T4               (1'b0),
          .TBYTEIN          (1'b0),
          .TCE              (1'b0)
        );
          
        genvar j;
        for (j = 0; j < SERIALIZATION_RATIO; j = j + 1)
        begin : gen_oserdes_data_in
          assign OSERDESE2_DATA_IN[SERIALIZATION_RATIO*i + j] = DATA_TO_OSERDES_REG[SERIALIZATION_RATIO*i + j];
        end
      end
    end
    endgenerate
        
      
      ////////////////////////////////////////////////////////////////////////////////
      //OUTPUT BUFFERS
      ////////////////////////////////////////////////////////////////////////////////
    generate
    if (SIMULATION == "FALSE")
    begin  
        genvar k;
        for (k = 0; k < LVDS_LINK_WIDTH; k = k + 1)
        begin : gen_obufds
          OBUFDS 
            OBUFDS_TX_DATA(
              .O(lvds_tx_data_p[k]),
              .OB(lvds_tx_data_n[k]),
              .I(TX_DATA_PREBUF[k])
              );
        end 

    end
    endgenerate
    
    generate
    if (SIMULATION == "TRUE")
    begin
      integer i;
        if (DATA_RATE_OQ == "DDR") 
        begin
          always@(posedge txclk or negedge txclk)
          begin
            if (RESET_FF2 == 1'b1)
              counter <= 0;
            else 
            begin
              if(counter == SERIALIZATION_RATIO - 1)
                counter <= 0;
              else
                counter <= counter + 1;
            end
              
            for (i=0; i< LVDS_LINK_WIDTH; i=i+1)
            begin
              TX_DATA_PREBUF1[i] <= DATA_TO_OSERDES_REG[(SERIALIZATION_RATIO)*i+counter];
            end
          end
        end
        else
        begin
          integer i;
          always@(posedge txclk)
          begin
            if (RESET_FF2 == 1'b1)
              counter <= 0;
            else 
            begin
              if(counter == SERIALIZATION_RATIO - 1)
                counter <= 0;
              else
                counter <= counter + 1;
            end
              
            for (i=0; i< LVDS_LINK_WIDTH; i=i+1)
            begin
              TX_DATA_PREBUF1[i] <= DATA_TO_OSERDES_REG[(SERIALIZATION_RATIO)*i+counter];
            end
          end          
        end

      ////////////////////////////////////////////////////////////////////////////////
      //OUTPUT BUFFERS
      ////////////////////////////////////////////////////////////////////////////////
        genvar k;
        for (k = 0; k < LVDS_LINK_WIDTH; k = k + 1)
        begin : gen_obufds
          OBUFDS 
            OBUFDS_TX_DATA(
              .O   (lvds_tx_data_p[k]),
              .OB  (lvds_tx_data_n[k]),
              .I   (TX_DATA_PREBUF1[k])
              );
        end 
      end
    endgenerate

endmodule
