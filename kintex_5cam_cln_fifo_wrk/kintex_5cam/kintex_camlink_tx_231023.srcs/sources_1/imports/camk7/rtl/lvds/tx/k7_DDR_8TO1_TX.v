///////////////////////////////////////////////////////////////////////////////
//
//    File Name:  k7_DDR_8TO1_17CHAN_TX.v
//      Version:  1.0
//         Date:  05/19/06
//        Model:  XAPP855 LVDS Transmitter Module
//
//      Company:  Xilinx, Inc.
//  Contributor:  APD Applications Group
//
//   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
//                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
//                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
//                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
//                APPLICATION OR STANDARD, XILINX IS MAKING NO
//                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
//                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
//                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
//                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
//                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
//                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
//                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
//                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
//                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//                PURPOSE.
//
//                (c) Copyright 2006 Xilinx, Inc.
//                All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////
// 
// Summary:
//
// The DDR_8TO1_16CHAN_TX module contains all components in the XAPP855 LVDS Transmitter,
// including 16 channels of LVDS data, one channel of LVDS clock, and a multiplexer
// that selects between a training pattern and user data.
// 
//----------------------------------------------------------------

module k7_DDR_8TO1_TX        
(//inputs
TXCLK,TXCLKDIV,RESET,DATA_TO_OSERDES,
TRAINING_DONE,
//output
TRAINING_START,LVDS_TRAINING_DONE,DEBUG_SIGNALS,
DATA_TX_P,DATA_TX_N,CLOCK_TX_P,CLOCK_TX_N
);

   parameter         P_LVDS_LINES   = 23;
   parameter         P_DATA_WIDTH   = P_LVDS_LINES*8;
   `define           D_DATA_WIDTH   184   //need to change this width and make it same as P_DATA_WIDTH
   //-----------------------------------------------------------------------------------------------
   input                            TXCLK                ; //SERIAL SIDE TX CLOCK
   input                            TXCLKDIV             ; //PARALLEL SIDE TX CLOCK (DIVIDED FROM TXCLK)
   input                            RESET                ; //TX DOMAIN RESET
                                                         
   input    [P_DATA_WIDTH-1:0]      DATA_TO_OSERDES      ; //PARALLEL SIDE TX DATA
   output reg                       TRAINING_START       =1'b0;
   output                           LVDS_TRAINING_DONE   ;
   output   [P_DATA_WIDTH+2:0]      DEBUG_SIGNALS        ;
   //-----------------------------------------------------------------------------------------------
   
   //-----------------------------------------------------------------------------------------------
   //signals below are routed to pins
   output [P_LVDS_LINES-1:0]        DATA_TX_P            ; //SERIAL SIDE TX DATA (P)
   output [P_LVDS_LINES-1:0]        DATA_TX_N            ; //SERIAL SIDE TX DATA (N)
   output                           CLOCK_TX_P           ; //FORWARDED CLOCK TO RX (P)
   output                           CLOCK_TX_N           ; //FORWARDED CLOCK TO RX (N)
   
   input                            TRAINING_DONE        ;  
   //-----------------------------------------------------------------------------------------------

wire                       TX_CLOCK_PREBUF   ;
wire [P_LVDS_LINES-1:0]    TX_DATA_PREBUF    ;

reg  [P_DATA_WIDTH-1:0]    DATA_TO_OSERDES_REG  = `D_DATA_WIDTH'h0;
reg                        RESET_end;

////add pipeline reg for RESET////
////modified by Joyce on 02/25/11////

wire RESET_FF1 /* synthesis syn_keep = 1 */;                                           
wire RESET_FF2 /* synthesis syn_keep = 1 */;                                           

FD  FD_RESET_FF1(.D(RESET),.C(TXCLKDIV),.Q(RESET_FF1)); 
FD  FD_RESET_FF2(.D(RESET_FF1),.C(TXCLKDIV),.Q(RESET_FF2)); 

//-----------------------------------------------------------------------
////registering TRAINING_DONE////
wire TRAINING_DONE_FF1 /* synthesis syn_keep = 1 */;                                           
wire TRAINING_DONE_FF2 /* synthesis syn_keep = 1 */;                                           

//IBUFDS #(.DIFF_TERM("TRUE"),.IOSTANDARD("LVDS_25")) LVDS4_RX_TRAINING_DONE (.O(TRAINING_DONE), .I(TRAINING_DONE_P), .IB(TRAINING_DONE_N));
//IBUFDS #(.DIFF_TERM("TRUE"),.IOSTANDARD("LVDS_25")) LVDS4_hold_inst        (.O(HOLD)         , .I(HOLD_P)         , .IB(HOLD_N));

FD  FD_TRAINING_DONE_FF1(.D(TRAINING_DONE),.C(TXCLKDIV),.Q(TRAINING_DONE_FF1)); 
FD  FD_TRAINING_DONE_FF2(.D(TRAINING_DONE_FF1),.C(TXCLKDIV),.Q(TRAINING_DONE_FF2)); 

//assign lvds_hold            = HOLD;
assign LVDS_TRAINING_DONE   = TRAINING_DONE_FF2;
//-----------------------------------------------------------------------
assign DEBUG_SIGNALS = {TRAINING_DONE,RESET,TRAINING_START,DATA_TO_OSERDES_REG};


//DATA SOURCE: TRAINING PAT OR PRBS 
//IF NO FEEDBACK CONTROLS FROM RX ARE DESIRED, THE TX CAN BE SET TO SEND THE 
//TRAINING PATTERN FOR A FIXED AMOUNT OF TIME, AFTER WHICH IT AUTOMATICALLY
//ASSUMES THAT TRAINING IS COMPLETE AND BEGINS SENDING USER DATA.
always@(posedge TXCLKDIV)
begin
   RESET_end <= !(RESET_FF1) & RESET_FF2;
end

always@(posedge TXCLKDIV)
begin
   if (RESET_end)
      TRAINING_START <= 1'b1;
   else if (TRAINING_DONE_FF2)
      TRAINING_START <= 1'b0;
end
      
always @(posedge TXCLKDIV) begin
   if (TRAINING_DONE_FF2)
   DATA_TO_OSERDES_REG <= DATA_TO_OSERDES;   //PRBS
else
   DATA_TO_OSERDES_REG <= `D_DATA_WIDTH'h2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C2C;  //TRAINING PATTERN
end


////////////////////////////////////////////////////////////////////////////////
// CLOCK RELATED
////////////////////////////////////////////////////////////////////////////////

//FORWARDED CLOCK 
ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE"),.INIT(1'b0),.SRTYPE("SYNC"))
   ODDR_TX_CLOCK(.Q(TX_CLOCK_PREBUF),.C(TXCLK),.CE(1'b1),.D1(1'b1),.D2(1'b0),.R(1'b0),.S(1'b0));

//FORWARDED CLOCK OUTPUT BUFFER
OBUFDS OBUFDS_TX_CLOCK(.O(CLOCK_TX_P),.OB(CLOCK_TX_N),.I(TX_CLOCK_PREBUF));

////////////////////////////////////////////////////////////////////////////////
//MASTER OSERDES IN DATA PATH
////////////////////////////////////////////////////////////////////////////////
genvar      n;
generate
for(n = 0; n < P_LVDS_LINES; n = n + 1)
   begin: OSERDESE2_GEN
      OSERDESE2 #(
         .DATA_WIDTH          (8    ),
         .DATA_RATE_TQ        ("SDR"),      
         .TRISTATE_WIDTH      (1    )
      ) 
      OSERDES_TX_DATA (
         .OFB                 (                          ), 
         .OQ                  (TX_DATA_PREBUF[n]         ),
         .TFB                 (                          ), 
         .TQ                  (                          ),  
         .SHIFTOUT1           (                          ), 
         .SHIFTOUT2           (                          ), 
         .TBYTEOUT            (                          ), 
         .CLK                 (TXCLK                     ), 
         .CLKDIV              (TXCLKDIV                  ),
         .OCE                 (1'b1                      ), 
         .RST                 (RESET_FF2                 ),  
         .D1                  (DATA_TO_OSERDES_REG[n*8]  ), 
         .D2                  (DATA_TO_OSERDES_REG[n*8+1]), 
         .D3                  (DATA_TO_OSERDES_REG[n*8+2]), 
         .D4                  (DATA_TO_OSERDES_REG[n*8+3]), 
         .D5                  (DATA_TO_OSERDES_REG[n*8+4]), 
         .D6                  (DATA_TO_OSERDES_REG[n*8+5]), 
         .D7                  (DATA_TO_OSERDES_REG[n*8+6]), 
         .D8                  (DATA_TO_OSERDES_REG[n*8+7]), 
         .SHIFTIN1            (1'b0                      ), 
         .SHIFTIN2            (1'b0                      ), 
         .T1                  (1'b0                      ), 
         .T2                  (1'b0                      ), 
         .T3                  (1'b0                      ), 
         .T4                  (1'b0                      ), 
         .TBYTEIN             (1'b0                      ), 
         .TCE                 (1'b0                      )
      );
   end
endgenerate

//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_00 (.OFB(), .OQ(TX_DATA_PREBUF[00]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[000]), .D2(DATA_TO_OSERDES_REG[001]), .D3(DATA_TO_OSERDES_REG[002]), .D4(DATA_TO_OSERDES_REG[003]), .D5(DATA_TO_OSERDES_REG[004]), .D6(DATA_TO_OSERDES_REG[005]), .D7(DATA_TO_OSERDES_REG[006]), .D8(DATA_TO_OSERDES_REG[007]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_01 (.OFB(), .OQ(TX_DATA_PREBUF[01]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[008]), .D2(DATA_TO_OSERDES_REG[009]), .D3(DATA_TO_OSERDES_REG[010]), .D4(DATA_TO_OSERDES_REG[011]), .D5(DATA_TO_OSERDES_REG[012]), .D6(DATA_TO_OSERDES_REG[013]), .D7(DATA_TO_OSERDES_REG[014]), .D8(DATA_TO_OSERDES_REG[015]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_02 (.OFB(), .OQ(TX_DATA_PREBUF[02]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[016]), .D2(DATA_TO_OSERDES_REG[017]), .D3(DATA_TO_OSERDES_REG[018]), .D4(DATA_TO_OSERDES_REG[019]), .D5(DATA_TO_OSERDES_REG[020]), .D6(DATA_TO_OSERDES_REG[021]), .D7(DATA_TO_OSERDES_REG[022]), .D8(DATA_TO_OSERDES_REG[023]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_03 (.OFB(), .OQ(TX_DATA_PREBUF[03]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[024]), .D2(DATA_TO_OSERDES_REG[025]), .D3(DATA_TO_OSERDES_REG[026]), .D4(DATA_TO_OSERDES_REG[027]), .D5(DATA_TO_OSERDES_REG[028]), .D6(DATA_TO_OSERDES_REG[029]), .D7(DATA_TO_OSERDES_REG[030]), .D8(DATA_TO_OSERDES_REG[031]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_04 (.OFB(), .OQ(TX_DATA_PREBUF[04]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[032]), .D2(DATA_TO_OSERDES_REG[033]), .D3(DATA_TO_OSERDES_REG[034]), .D4(DATA_TO_OSERDES_REG[035]), .D5(DATA_TO_OSERDES_REG[036]), .D6(DATA_TO_OSERDES_REG[037]), .D7(DATA_TO_OSERDES_REG[038]), .D8(DATA_TO_OSERDES_REG[039]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_05 (.OFB(), .OQ(TX_DATA_PREBUF[05]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[040]), .D2(DATA_TO_OSERDES_REG[041]), .D3(DATA_TO_OSERDES_REG[042]), .D4(DATA_TO_OSERDES_REG[043]), .D5(DATA_TO_OSERDES_REG[044]), .D6(DATA_TO_OSERDES_REG[045]), .D7(DATA_TO_OSERDES_REG[046]), .D8(DATA_TO_OSERDES_REG[047]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_06 (.OFB(), .OQ(TX_DATA_PREBUF[06]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[048]), .D2(DATA_TO_OSERDES_REG[049]), .D3(DATA_TO_OSERDES_REG[050]), .D4(DATA_TO_OSERDES_REG[051]), .D5(DATA_TO_OSERDES_REG[052]), .D6(DATA_TO_OSERDES_REG[053]), .D7(DATA_TO_OSERDES_REG[054]), .D8(DATA_TO_OSERDES_REG[055]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_07 (.OFB(), .OQ(TX_DATA_PREBUF[07]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[056]), .D2(DATA_TO_OSERDES_REG[057]), .D3(DATA_TO_OSERDES_REG[058]), .D4(DATA_TO_OSERDES_REG[059]), .D5(DATA_TO_OSERDES_REG[060]), .D6(DATA_TO_OSERDES_REG[061]), .D7(DATA_TO_OSERDES_REG[062]), .D8(DATA_TO_OSERDES_REG[063]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_08 (.OFB(), .OQ(TX_DATA_PREBUF[08]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[064]), .D2(DATA_TO_OSERDES_REG[065]), .D3(DATA_TO_OSERDES_REG[066]), .D4(DATA_TO_OSERDES_REG[067]), .D5(DATA_TO_OSERDES_REG[068]), .D6(DATA_TO_OSERDES_REG[069]), .D7(DATA_TO_OSERDES_REG[070]), .D8(DATA_TO_OSERDES_REG[071]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_09 (.OFB(), .OQ(TX_DATA_PREBUF[09]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[072]), .D2(DATA_TO_OSERDES_REG[073]), .D3(DATA_TO_OSERDES_REG[074]), .D4(DATA_TO_OSERDES_REG[075]), .D5(DATA_TO_OSERDES_REG[076]), .D6(DATA_TO_OSERDES_REG[077]), .D7(DATA_TO_OSERDES_REG[078]), .D8(DATA_TO_OSERDES_REG[079]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_10 (.OFB(), .OQ(TX_DATA_PREBUF[10]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[080]), .D2(DATA_TO_OSERDES_REG[081]), .D3(DATA_TO_OSERDES_REG[082]), .D4(DATA_TO_OSERDES_REG[083]), .D5(DATA_TO_OSERDES_REG[084]), .D6(DATA_TO_OSERDES_REG[085]), .D7(DATA_TO_OSERDES_REG[086]), .D8(DATA_TO_OSERDES_REG[087]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_11 (.OFB(), .OQ(TX_DATA_PREBUF[11]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[088]), .D2(DATA_TO_OSERDES_REG[089]), .D3(DATA_TO_OSERDES_REG[090]), .D4(DATA_TO_OSERDES_REG[091]), .D5(DATA_TO_OSERDES_REG[092]), .D6(DATA_TO_OSERDES_REG[093]), .D7(DATA_TO_OSERDES_REG[094]), .D8(DATA_TO_OSERDES_REG[095]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_12 (.OFB(), .OQ(TX_DATA_PREBUF[12]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[096]), .D2(DATA_TO_OSERDES_REG[097]), .D3(DATA_TO_OSERDES_REG[098]), .D4(DATA_TO_OSERDES_REG[099]), .D5(DATA_TO_OSERDES_REG[100]), .D6(DATA_TO_OSERDES_REG[101]), .D7(DATA_TO_OSERDES_REG[102]), .D8(DATA_TO_OSERDES_REG[103]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_13 (.OFB(), .OQ(TX_DATA_PREBUF[13]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[104]), .D2(DATA_TO_OSERDES_REG[105]), .D3(DATA_TO_OSERDES_REG[106]), .D4(DATA_TO_OSERDES_REG[107]), .D5(DATA_TO_OSERDES_REG[108]), .D6(DATA_TO_OSERDES_REG[109]), .D7(DATA_TO_OSERDES_REG[110]), .D8(DATA_TO_OSERDES_REG[111]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_14 (.OFB(), .OQ(TX_DATA_PREBUF[14]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[112]), .D2(DATA_TO_OSERDES_REG[113]), .D3(DATA_TO_OSERDES_REG[114]), .D4(DATA_TO_OSERDES_REG[115]), .D5(DATA_TO_OSERDES_REG[116]), .D6(DATA_TO_OSERDES_REG[117]), .D7(DATA_TO_OSERDES_REG[118]), .D8(DATA_TO_OSERDES_REG[119]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_15 (.OFB(), .OQ(TX_DATA_PREBUF[15]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[120]), .D2(DATA_TO_OSERDES_REG[121]), .D3(DATA_TO_OSERDES_REG[122]), .D4(DATA_TO_OSERDES_REG[123]), .D5(DATA_TO_OSERDES_REG[124]), .D6(DATA_TO_OSERDES_REG[125]), .D7(DATA_TO_OSERDES_REG[126]), .D8(DATA_TO_OSERDES_REG[127]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_16 (.OFB(), .OQ(TX_DATA_PREBUF[16]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[128]), .D2(DATA_TO_OSERDES_REG[129]), .D3(DATA_TO_OSERDES_REG[130]), .D4(DATA_TO_OSERDES_REG[131]), .D5(DATA_TO_OSERDES_REG[132]), .D6(DATA_TO_OSERDES_REG[133]), .D7(DATA_TO_OSERDES_REG[134]), .D8(DATA_TO_OSERDES_REG[135]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));                                                                                                                                                                                                        
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_17 (.OFB(), .OQ(TX_DATA_PREBUF[17]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[136]), .D2(DATA_TO_OSERDES_REG[137]), .D3(DATA_TO_OSERDES_REG[138]), .D4(DATA_TO_OSERDES_REG[139]), .D5(DATA_TO_OSERDES_REG[140]), .D6(DATA_TO_OSERDES_REG[141]), .D7(DATA_TO_OSERDES_REG[142]), .D8(DATA_TO_OSERDES_REG[143]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_18 (.OFB(), .OQ(TX_DATA_PREBUF[18]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[144]), .D2(DATA_TO_OSERDES_REG[145]), .D3(DATA_TO_OSERDES_REG[146]), .D4(DATA_TO_OSERDES_REG[147]), .D5(DATA_TO_OSERDES_REG[148]), .D6(DATA_TO_OSERDES_REG[149]), .D7(DATA_TO_OSERDES_REG[150]), .D8(DATA_TO_OSERDES_REG[151]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_19 (.OFB(), .OQ(TX_DATA_PREBUF[19]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[152]), .D2(DATA_TO_OSERDES_REG[153]), .D3(DATA_TO_OSERDES_REG[154]), .D4(DATA_TO_OSERDES_REG[155]), .D5(DATA_TO_OSERDES_REG[156]), .D6(DATA_TO_OSERDES_REG[157]), .D7(DATA_TO_OSERDES_REG[158]), .D8(DATA_TO_OSERDES_REG[159]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_20 (.OFB(), .OQ(TX_DATA_PREBUF[20]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[160]), .D2(DATA_TO_OSERDES_REG[161]), .D3(DATA_TO_OSERDES_REG[162]), .D4(DATA_TO_OSERDES_REG[163]), .D5(DATA_TO_OSERDES_REG[164]), .D6(DATA_TO_OSERDES_REG[165]), .D7(DATA_TO_OSERDES_REG[166]), .D8(DATA_TO_OSERDES_REG[167]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_21 (.OFB(), .OQ(TX_DATA_PREBUF[21]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[168]), .D2(DATA_TO_OSERDES_REG[169]), .D3(DATA_TO_OSERDES_REG[170]), .D4(DATA_TO_OSERDES_REG[171]), .D5(DATA_TO_OSERDES_REG[172]), .D6(DATA_TO_OSERDES_REG[173]), .D7(DATA_TO_OSERDES_REG[174]), .D8(DATA_TO_OSERDES_REG[175]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
//OSERDESE2 #(.DATA_WIDTH(8),.TRISTATE_WIDTH(1)) OSERDES_TX_DATA_22 (.OFB(), .OQ(TX_DATA_PREBUF[22]),.TFB(), .TQ(),  .SHIFTOUT1(), .SHIFTOUT2(), .TBYTEOUT(), .CLK(TXCLK), .CLKDIV(TXCLKDIV),.OCE(1'b1), .RST(RESET_FF2),  .D1(DATA_TO_OSERDES_REG[176]), .D2(DATA_TO_OSERDES_REG[177]), .D3(DATA_TO_OSERDES_REG[178]), .D4(DATA_TO_OSERDES_REG[179]), .D5(DATA_TO_OSERDES_REG[180]), .D6(DATA_TO_OSERDES_REG[181]), .D7(DATA_TO_OSERDES_REG[182]), .D8(DATA_TO_OSERDES_REG[183]), .SHIFTIN1(1'b0), .SHIFTIN2(1'b0), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0), .TBYTEIN(1'b0), .TCE(1'b0));
                                                                                                                                                                                                           
////////////////////////////////////////////////////////////////////////////////
//OUTPUT BUFFERS  
////////////////////////////////////////////////////////////////////////////////
//genvar    n;
generate
for(n = 0; n < P_LVDS_LINES; n = n + 1)
   begin: OBUFDS_GEN
      OBUFDS OBUFDS_TX_DATA (
         .O          (DATA_TX_P[n]        ), 
         .OB         (DATA_TX_N[n]        ), 
         .I          (TX_DATA_PREBUF[n]   )
      );
   end
endgenerate

//OBUFDS OBUFDS_TX_DATA_00(.O(DATA_TX_P[00]), .OB(DATA_TX_N[00]), .I(TX_DATA_PREBUF[00]));
//OBUFDS OBUFDS_TX_DATA_01(.O(DATA_TX_P[01]), .OB(DATA_TX_N[01]), .I(TX_DATA_PREBUF[01]));
//OBUFDS OBUFDS_TX_DATA_02(.O(DATA_TX_P[02]), .OB(DATA_TX_N[02]), .I(TX_DATA_PREBUF[02]));
//OBUFDS OBUFDS_TX_DATA_03(.O(DATA_TX_P[03]), .OB(DATA_TX_N[03]), .I(TX_DATA_PREBUF[03]));
//OBUFDS OBUFDS_TX_DATA_04(.O(DATA_TX_P[04]), .OB(DATA_TX_N[04]), .I(TX_DATA_PREBUF[04]));
//OBUFDS OBUFDS_TX_DATA_05(.O(DATA_TX_P[05]), .OB(DATA_TX_N[05]), .I(TX_DATA_PREBUF[05]));
//OBUFDS OBUFDS_TX_DATA_06(.O(DATA_TX_P[06]), .OB(DATA_TX_N[06]), .I(TX_DATA_PREBUF[06]));
//OBUFDS OBUFDS_TX_DATA_07(.O(DATA_TX_P[07]), .OB(DATA_TX_N[07]), .I(TX_DATA_PREBUF[07]));
//OBUFDS OBUFDS_TX_DATA_08(.O(DATA_TX_P[08]), .OB(DATA_TX_N[08]), .I(TX_DATA_PREBUF[08]));
//OBUFDS OBUFDS_TX_DATA_09(.O(DATA_TX_P[09]), .OB(DATA_TX_N[09]), .I(TX_DATA_PREBUF[09]));
//OBUFDS OBUFDS_TX_DATA_10(.O(DATA_TX_P[10]), .OB(DATA_TX_N[10]), .I(TX_DATA_PREBUF[10]));
//OBUFDS OBUFDS_TX_DATA_11(.O(DATA_TX_P[11]), .OB(DATA_TX_N[11]), .I(TX_DATA_PREBUF[11]));
//OBUFDS OBUFDS_TX_DATA_12(.O(DATA_TX_P[12]), .OB(DATA_TX_N[12]), .I(TX_DATA_PREBUF[12]));
//OBUFDS OBUFDS_TX_DATA_13(.O(DATA_TX_P[13]), .OB(DATA_TX_N[13]), .I(TX_DATA_PREBUF[13]));
//OBUFDS OBUFDS_TX_DATA_14(.O(DATA_TX_P[14]), .OB(DATA_TX_N[14]), .I(TX_DATA_PREBUF[14]));
//OBUFDS OBUFDS_TX_DATA_15(.O(DATA_TX_P[15]), .OB(DATA_TX_N[15]), .I(TX_DATA_PREBUF[15]));
//OBUFDS OBUFDS_TX_DATA_16(.O(DATA_TX_P[16]), .OB(DATA_TX_N[16]), .I(TX_DATA_PREBUF[16]));
//OBUFDS OBUFDS_TX_DATA_17(.O(DATA_TX_P[17]), .OB(DATA_TX_N[17]), .I(TX_DATA_PREBUF[17]));
//OBUFDS OBUFDS_TX_DATA_18(.O(DATA_TX_P[18]), .OB(DATA_TX_N[18]), .I(TX_DATA_PREBUF[18]));
//OBUFDS OBUFDS_TX_DATA_19(.O(DATA_TX_P[19]), .OB(DATA_TX_N[19]), .I(TX_DATA_PREBUF[19]));
//OBUFDS OBUFDS_TX_DATA_20(.O(DATA_TX_P[20]), .OB(DATA_TX_N[20]), .I(TX_DATA_PREBUF[20]));
//OBUFDS OBUFDS_TX_DATA_21(.O(DATA_TX_P[21]), .OB(DATA_TX_N[21]), .I(TX_DATA_PREBUF[21]));
//OBUFDS OBUFDS_TX_DATA_22(.O(DATA_TX_P[22]), .OB(DATA_TX_N[22]), .I(TX_DATA_PREBUF[22]));

endmodule
