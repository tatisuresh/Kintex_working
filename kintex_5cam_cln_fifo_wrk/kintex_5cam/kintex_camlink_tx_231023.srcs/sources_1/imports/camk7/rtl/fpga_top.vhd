library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_textio.all;
USE std.textio.all;

USE work.amba_pkg.all;

--Library UNISIM;
--use UNISIM.vcomponents.all;

entity fpga_top is
  generic (
    DEVICE                  : string    :=  "7SERIES";
    BAUDRATE                : integer   :=  115200;      --- bps
    LVDS_LINK_WIDTH         : natural   :=  4;
    CHIPSCOPE               : integer   :=  0
  );
  Port (

    ----clock input from board
    --fpga_ref_clk               : in  std_logic;
    fpga_ref_clk_p          : in  std_logic;
    fpga_ref_clk_n          : in  std_logic;
	
	fpga_ref_clk_opt_p      : in  std_logic;
    fpga_ref_clk_opt_n      : in  std_logic;
	
	rst                     : in std_logic;

    -----UART Signals for debug only
    --RS232_Uart_out            : out std_logic;
    --RS232_Uart_in             : in  std_logic;
	
	-----Debug Leds---------------
	led0_out                  : out std_logic;
	led1_out                  : out std_logic;

	-- CAMlink data 
	
	camlink_data_in_0         : in std_logic_vector(27 downto 0);
	camlink_data_in_1         : in std_logic_vector(27 downto 0);
	camlink_data_in_2         : in std_logic_vector(27 downto 0);
	camlink_data_in_3         : in std_logic_vector(27 downto 0);
	camlink_data_in_4         : in std_logic_vector(27 downto 0);
	
	CAMLINK1_EXT_SYNC         : in std_logic;
	CAMLINK1_CLK              : in std_logic;
	CAMLINK2_EXT_SYNC         : in std_logic;
	CAMLINK2_CLK              : in std_logic;
	CAMLINK3_EXT_SYNC         : in std_logic;
	CAMLINK3_CLK              : in std_logic;
	CAMLINK4_EXT_SYNC         : in std_logic;
	CAMLINK4_CLK              : in std_logic;
	CAMLINK5_EXT_SYNC         : in std_logic;
	CAMLINK5_CLK              : in std_logic;
	
	-- RS232 interface 
	
--	CAMLINK_TXD               : out std_logic_vector(4 downto 0);
--	CAMLINK_RXD               : in std_logic_vector(4 downto 0);
	
	
    -- Power dwn and pwren	
	CAMLINK1_PDWN          	  : out std_logic;
	CAMLINK1_PWR_EN           : out std_logic;
	CAMLINK2_PDWN             : out std_logic;
	CAMLINK2_PWR_EN           : out std_logic;
	CAMLINK3_PDWN             : out std_logic;
	CAMLINK3_PWR_EN           : out std_logic;
	CAMLINK4_PDWN             : out std_logic;
	CAMLINK4_PWR_EN           : out std_logic;
	CAMLINK5_PDWN             : out std_logic;
	CAMLINK5_PWR_EN           : out std_logic;
	-- output control signals
	cam0_vsync_out             : out std_logic;
	cam0_hsync_out             : out std_logic;
	cam1_vsync_out             : out std_logic;
	cam1_hsync_out             : out std_logic;
	cam2_vsync_out             : out std_logic;
	cam2_hsync_out             : out std_logic;
	cam0_clk_out               : out std_logic;
    CLINK_CTRL_P    		  : out std_logic_vector(5 downto 0);
    CLINK_CTRL_N    		  : out std_logic_vector(5 downto 0);
	
    CLINK_DATA_P              : out std_logic_vector(15 downto 0);
    CLINK_DATA_N              : out std_logic_vector(15 downto 0);
    CLINK_CLK_P               : out std_logic;
    CLINK_CLK_N               : out std_logic
 );
  
attribute dont_touch : string;
attribute dont_touch of fpga_top : entity is "true|yes";
      
  
end fpga_top;


architecture RTL of fpga_top is

component ila_0 is 
port (
 clk  : in std_logic ;
  probe0 : in std_logic_vector(39 downto 0)
);
end component;

component clk_wiz_1 is 
port (
clk_out1  : out std_logic;
clk_out2  : out std_logic;
clk_out3  : out std_logic;
clk_out4  : out std_logic;
locked    : out std_logic;
clk_in1   : in std_logic

);
end component;

constant SIMULATION : string    :=  "FALSE";
------------------------------------------------------------------------
-- function Declarations
------------------------------------------------------------------------
function func(simulation : STRING) return boolean is
begin
    if(simulation = "TRUE") then
        return TRUE;
    else
        return FALSE;
    end if;
end function func;

function func2(simulation : STRING) return std_logic is
begin
    if(simulation = "TRUE") then
        return '1';
    else
        return '0';
    end if;
end function func2;

function func3(simulation : STRING) return natural is
begin
    if(simulation = "TRUE") then
        return 1;
    else
        return 0;
    end if;
end function func3;
------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------

------------------------------------------------------------------------
--  Constant Declarations
------------------------------------------------------------------------
  constant SIM                     : boolean    := func(SIMULATION);
  constant SIM_SL                  : std_logic  := func2(SIMULATION);
  constant SIM_INT                 : natural    := func3(SIMULATION);
  constant zeros                   : std_logic_vector(255 downto 0) := (others => '0');

------------------------------------------------------------------------
-- Signal_Port Declarations Internal
------------------------------------------------------------------------
  signal pll_locked_1                       : std_logic := '0';
  signal pll_locked_2                       : std_logic := '0';
  signal clk_in                             : std_logic := '0';
  signal reset                              : std_logic := '1';
  signal reset_n                            : std_logic := '1';
  signal clk_71mhz                          : std_logic := '0';
  signal clk_71mhz_shifted                  : std_logic := '0';
  signal clk_500mhz                         : std_logic := '0';
  signal clk_200mhz                         : std_logic := '0';
  signal lvds_rx_clock_in                   : std_logic := '0';
  signal lvds_rx_clock_div                  : std_logic := '0';
  signal lvds_rx_clock                      : std_logic := '0';
  
  
  signal reg_wr_data                        : std_logic_vector(31 downto 0):= (others => '0');
  signal reg_wr_en                          : std_logic := '0';
  signal reg_addr                           : std_logic_vector(31 downto 0):= (others => '0');
  signal reg_rd_data                        : std_logic_vector(31 downto 0):= (others => '0');
  signal reg_rd_en                          : std_logic := '0';
  signal reg_rd_done                        : std_logic := '0';

  signal axilmo                             : axil_mo_type;
  signal axilmi                             : axil_mi_type := AXILMI_INIT;
  signal axilso_camlink  	                : axil_mi_type := AXILMI_INIT;
  signal axilso_camlink_0	                : axil_mi_type := AXILMI_INIT;
  signal axilso_camlink_1                   : axil_mi_type := AXILMI_INIT;
  signal axilso_camlink_2                   : axil_mi_type := AXILMI_INIT;
  signal axilso_camlink_3                   : axil_mi_type := AXILMI_INIT;
  signal axilso_camlink_4                   : axil_mi_type := AXILMI_INIT;
  signal axilso_lvds_tx                     : axil_mi_type := AXILMI_INIT;
  signal chipscope_control                  : std_logic_vector(35 downto 0);
  signal reset_tx_clk_div                   : std_logic := '1';
  signal reset_tx_clk_div_metastable        : std_logic := '1';
  signal tx_buffer_ready                    : std_logic;
  signal data_en                            : std_logic;
  signal data_en_1d                         : std_logic :=  '0';
  signal reset_rx_clk_div                   : std_logic := '1';
  signal reset_rx_clk_div_metastable        : std_logic := '1';
  signal video_data_out_0                   : std_logic_vector(27 downto 0);
  signal video_data_out_1                   : std_logic_vector(27 downto 0);
  signal video_data_out_2                   : std_logic_vector(27 downto 0);
  signal video_data_out_3                   : std_logic_vector(27 downto 0);
  signal video_data_out_4                   : std_logic_vector(27 downto 0);
  signal rx_buffer_full_flag_0              : std_logic ;
  signal rx_buffer_full_flag_1              : std_logic ;
  signal rx_buffer_full_flag_2              : std_logic ;
  signal rx_buffer_full_flag_3              : std_logic ;
  signal rx_buffer_full_flag_4              : std_logic ;
  signal rx_buffer_ready_0                  : std_logic ;
  signal rx_buffer_ready_1                  : std_logic ;
  signal rx_buffer_ready_2                  : std_logic ;
  signal rx_buffer_ready_3                  : std_logic ;
  signal rx_buffer_ready_4                  : std_logic ;
  signal rd_en_0			                : std_logic ;
  signal rd_en_1			                : std_logic ;
  signal rd_en_2			                : std_logic ;
  signal rd_en_3			                : std_logic ;
  signal rd_en_4			                : std_logic ;
  -- signal wr_en   			                : std_logic ;
  signal ready_i                            : std_logic ;
  signal error_counter_flag                 : std_logic ;
  signal error_counter_ecount               : std_logic_vector(16 - 1 downto 0);
  signal clock_as_data                      : std_logic_vector(8 - 1 downto 0);
  signal lvds_data_out                      : std_logic_vector(28 - 1 downto 0);
  signal packeted_data                      : std_logic_vector(159 downto 0);  
  signal my_cam0 : std_logic_vector(1 downto 0);
  signal my_cam_sig : std_logic;
  signal read_fifo_empty : std_logic;
  
  

  
 

  constant REGISTERS_NBR                    :  natural := 5;
  signal reg_rd_value                       : Registers_t(REGISTERS_NBR - 1 downto 0);
  signal reg_wr_value                       : Registers_t(REGISTERS_NBR - 1 downto 0);
  signal reg_rst_value                      : Registers_t(REGISTERS_NBR - 1 downto 0):= (others => (others => '0'));
						                    
  signal reg_rd_flag                        : std_logic_vector(REGISTERS_NBR - 1 downto 0)   :=  (others => '0');
  signal reg_wr_flag                        : std_logic_vector(REGISTERS_NBR - 1 downto 0)   :=  (others => '0');
  
  signal fpga_ref_clk                       : std_logic := '0';
  signal fpga_ref_clk_opt                   : std_logic := '0';
  signal CLINK_CLK_N_d                        : std_logic := '0';
  signal CLINK_CLK_P_d                        : std_logic := '0';
  signal cam_vsync_in                 :  std_logic_vector (1 downto 0) := (others => '0');
  signal cam_hsync_out        : std_logic := '0';
  signal CLINK_CLK_N_inv        :std_logic;
  signal CLINK_DATA_N_d      : std_logic_vector (15 downto 0) := (others => '0');
  signal CLINK_DATA_P_d      : std_logic_vector (15 downto 0) := (others => '0');
  signal zero_12bit          : std_logic_vector (11 downto 0) := (others => '0');
  signal dbg_sig             : std_logic_vector (39 downto 0) := (others => '0');
  signal dbg_sig_0           : std_logic_vector (39 downto 0) := (others => '0');
  signal uart_tx_debug        :std_logic;
  signal uart_tx_iobuf_out        :std_logic;

  -- lvds related signals 
 ---------------------------------------------------------------------------------------------------------------------------
   
begin
ref_clk_bufds: IBUFGDS
port map(
O  => clk_in,
I  => fpga_ref_clk_p,
IB => fpga_ref_clk_n
);

ref_clk_opt_bufds: IBUFGDS
port map(
O   => fpga_ref_clk_opt,
I   => fpga_ref_clk_opt_p,
IB  => fpga_ref_clk_opt_n
);

SIMULATION_GEN : if (SIMULATION = " TRUE") generate
  clk_in    <= not clk_in                          after 5.0000 ns;
  clk_71mhz <= not clk_71mhz                       after 7.0000 ns;
  clk_71mhz_shifted <= not clk_71mhz_shifted       after 7.0000 ns;
  clk_500mhz  <= not clk_500mhz                    after 1.0000 ns;
  lvds_rx_clock_div <= not lvds_rx_clock_div       after 7.0000 ns;
  lvds_rx_clock <= not lvds_rx_clock               after 1.0000 ns;
  clk_200mhz    <= not clk_200mhz                  after 2.5000 ns;
  
  reset <= '0' after 100 ns;
  pll_locked_1 <= '1' after 100 ns;
  pll_locked_2 <= '1' after 100 ns;
end generate SIMULATION_GEN;
  
SYNTH_GEN : if (SIMULATION = "FALSE") generate
 camlink_tx_pll : clk_wiz_1
 port map
  (
   CLK_IN1  => clk_in,
   CLK_OUT1 => clk_71mhz,
   CLK_OUT2 => clk_71mhz_shifted,
   CLK_OUT3 => clk_500mhz,
   CLK_OUT4 => clk_200mhz,
   LOCKED   => pll_locked_1
  
  );

 reset <= rst  or (not pll_locked_1);
 reset_n <= (not rst) or pll_locked_1;
 

 
end generate SYNTH_GEN;

 CLINK_CLK_P <= clk_71mhz;

 led0_out <= camlink_data_in_0(24);
led1_out <= CAMLINK1_EXT_SYNC or CAMLINK2_EXT_SYNC or CAMLINK3_EXT_SYNC or CAMLINK4_EXT_SYNC or CAMLINK5_EXT_SYNC;

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
------------------------------UART INTERFACE---------------------------------------
--/////////////////////////////////////////////////////////////////////////////////


  uart_controller : entity work.uart_top
  generic map(
    ENABLE_PARITY         =>  "0",
    MAKE_PARITY_ODD       =>  '1',
    baudrate              =>  115200,
    clockrate             =>  71428571,
    NUMBER_OF_INTERFACES  =>  1,
    CHIPSCOPE             =>  CHIPSCOPE 
  )
  port map(
    RST                   =>  reset,
    CLK                   =>  clk_71mhz,
    UART_RX               =>  '0',
    UART_TX               =>  open,

    reg_addr              =>  reg_addr,
    reg_wr_data           =>  reg_wr_data,
    reg_rd_data           =>  reg_rd_data,
    reg_wr_en             =>  reg_wr_en,
    reg_rd_en             =>  reg_rd_en,
    reg_rd_done           =>  reg_rd_done,
    
    bulk_write_data       =>  open,
    bulk_write_en         =>  open,
    bulk_read_en          =>  open,
    bulk_read_data_valid  =>  (others => '0'),
    bulk_read_data        =>  (others => (others => '0')) ,
    chipscope_control     =>  chipscope_control
  );

axil_lite_master_inst : ENTITY work.axil_lite_master
   GENERIC MAP (DEVICE   => DEVICE)
   PORT MAP(
   --clk_rst
   axil_clk     =>  clk_71mhz,
   axil_rst     =>  reset,
   design_clk   =>  clk_71mhz,
   --axi_bus
   axilmi       =>  AXILMI,
   axilmo       =>  axilmo,
   --read
   rd_addr      =>  reg_addr(AXIL_ADDR_WIDTH-1 downto 0),
   Rd_data      =>  reg_rd_data,
   rd_en        =>  reg_rd_en,
   Rd_Done      =>  reg_rd_done,
   Rd_Ack       =>  open,
   --write
   wr_addr      =>  reg_addr(AXIL_ADDR_WIDTH-1 downto 0),
   wr_data      =>  reg_wr_data,
   wr_en        =>  reg_wr_en,
   wr_busy      =>  open
  );

axi_lite_interconnect_top_inst : ENTITY work.axi_lite_interconnect_top
  PORT MAP(
   AXILSO0  => axilso_lvds_tx,
   AXILSO1  => axilso_camlink,
   AXILMI   => AXILMI
  );

  
process(clk_71mhz)
begin
  if(rising_edge(clk_71mhz)) then
    reset_tx_clk_div            <=  reset_tx_clk_div_metastable;
    reset_tx_clk_div_metastable <=  not pll_locked_1;
  end if;
end process;   
 
lvds_rx_camlink_0 : entity work.camlink_rx_axi
   generic map(
     SIMULATION              =>  SIMULATION,
    -- ADDRESS_BASE            =>  x"00000080",
     IDELAY_REFCLK_FREQUENCY =>  200,
     DEVICE                  =>  DEVICE 
   )
   port map(
   ---axi interface
     clk                     =>  clk_71mhz, -- clk_71mhz,
     rstn                    =>  pll_locked_1,
	 cam_clk                 => CAMLINK1_CLK,
	 cam_sync                => CAMLINK1_EXT_SYNC,

     video_data_out_valid    =>  rd_en_0,
     video_data_out          =>  video_data_out_0,
     
     -- camlink_rx_clk_to_pll   =>  lvds_rx_clock_in,

     rx_buffer_full_flag     =>  rx_buffer_full_flag_0,
     rx_buffer_ready         =>  rx_buffer_ready_0,

     camlink_data_in         =>  camlink_data_in_0  
   );
   
lvds_rx_camlink_1 : entity work.camlink_rx_axi
   generic map(
     SIMULATION              =>  SIMULATION,
    -- ADDRESS_BASE            =>  x"00000080",
     IDELAY_REFCLK_FREQUENCY =>  200,
     DEVICE                  =>  DEVICE 
   )
   port map(
   ---axi interface
     clk                     =>  clk_71mhz,
     rstn                    =>  reset_n,
	 cam_clk                 => CAMLINK2_CLK,
	 cam_sync                => CAMLINK2_EXT_SYNC,     
     video_data_out_valid    =>  rd_en_1,
     video_data_out          =>  video_data_out_1,
     rx_buffer_full_flag     =>  rx_buffer_full_flag_1,
     rx_buffer_ready         =>  rx_buffer_ready_1,
     camlink_data_in         =>  camlink_data_in_1  
   );  
   
 
lvds_rx_camlink_2 : entity work.camlink_rx_axi
   generic map(
     SIMULATION              =>  SIMULATION,
     IDELAY_REFCLK_FREQUENCY =>  200,
     DEVICE                  =>  DEVICE 
   )
   port map(
   ---axi interface
     clk                     =>  clk_71mhz,
     rstn                    =>  reset_n,
	 cam_clk                 => CAMLINK3_CLK,
	 cam_sync                => CAMLINK3_EXT_SYNC,
     video_data_out_valid    =>  rd_en_2,
     video_data_out          =>  video_data_out_2,
     rx_buffer_full_flag     =>  rx_buffer_full_flag_2,
     rx_buffer_ready         =>  rx_buffer_ready_2,
     camlink_data_in         =>  camlink_data_in_2  
   ); 

lvds_rx_camlink_3 : entity work.camlink_rx_axi
   generic map(
     SIMULATION              =>  SIMULATION,
    -- ADDRESS_BASE            =>  x"00000080",
     IDELAY_REFCLK_FREQUENCY =>  200,
     DEVICE                  =>  DEVICE 
   )
   port map(
   ---axi interface
     clk                     =>  clk_71mhz,
     rstn                    =>  reset_n,
	 cam_clk                 => CAMLINK4_CLK,
	 cam_sync                => CAMLINK4_EXT_SYNC,
     video_data_out_valid    =>  rd_en_3,
     video_data_out          =>  video_data_out_3,
     rx_buffer_full_flag     =>  rx_buffer_full_flag_3,
     rx_buffer_ready         =>  rx_buffer_ready_3,
     camlink_data_in         =>  camlink_data_in_3  
   );    
   
 lvds_rx_camlink_4 : entity work.camlink_rx_axi
   generic map(
     SIMULATION              =>  SIMULATION,
     IDELAY_REFCLK_FREQUENCY =>  200,
     DEVICE                  =>  DEVICE 
   )
   port map(
   ---axi interface
     clk                     =>  clk_71mhz,
     rstn                    =>  reset_n,
	 cam_clk                 => CAMLINK5_CLK,
	 cam_sync                => CAMLINK5_EXT_SYNC,
     video_data_out_valid    =>  rd_en_4,
     video_data_out          =>  video_data_out_4,
     rx_buffer_full_flag     =>  rx_buffer_full_flag_4,
     rx_buffer_ready         =>  rx_buffer_ready_4,
     camlink_data_in         =>  camlink_data_in_4  
   );    
  
ready_i <= reset_n;

  
 packet_formatter_inst: entity work.packet_formatter
 port map(
	clk					=> CAMLINK1_CLK,
	rstn				=> reset_n,
	
	data_0				=> video_data_out_0,
	fifo_not_empty_0    => rx_buffer_ready_0,
	rd_en_0				=> rd_en_0,
	
	data_1				=> video_data_out_1,
	fifo_not_empty_1    => rx_buffer_ready_1,
	rd_en_1				=> rd_en_1,
	
	data_2				=> video_data_out_2,
	fifo_not_empty_2    => rx_buffer_ready_2,
	rd_en_2				=> rd_en_2,
	
	data_3				=> video_data_out_3,
	fifo_not_empty_3    => rx_buffer_ready_3,
	rd_en_3				=> rd_en_3,
	
	data_4				=> video_data_out_4,
	fifo_not_empty_4    => rx_buffer_ready_4,
	rd_en_4				=> rd_en_4,
	
	ready               => ready_i,
	
	packeted_data		=> packeted_data
	-- wr_en				=> wr_en
); 

debuger : ila_0
port map (
clk => clk_in,
probe0 => dbg_sig
);

   dbg_sig <= "000000000000" &"00000000"&video_data_out_0(24)& video_data_out_0(25) &camlink_data_in_0(24)& camlink_data_in_0(25)& video_data_out_0(18) & video_data_out_0(19) & video_data_out_0(15) & video_data_out_0(23) & video_data_out_0(11) & video_data_out_0(10) & video_data_out_0(9) & video_data_out_0(8)
 & camlink_data_in_0(18) & camlink_data_in_0(19) & camlink_data_in_0(15) & camlink_data_in_0(23) & camlink_data_in_0(11) & camlink_data_in_0(10) & camlink_data_in_0(9) & camlink_data_in_0(8);
cam0_vsync_out <= video_data_out_0(24);
cam0_hsync_out <= video_data_out_0(25);

cam1_vsync_out  <= video_data_out_1(24);
cam1_hsync_out  <= video_data_out_1(25);

cam2_vsync_out  <= video_data_out_2(24);
cam2_hsync_out  <= video_data_out_2(25);

CLINK_DATA_P <= video_data_out_1(18) & video_data_out_1(19) & video_data_out_1(15) & video_data_out_1(23) & video_data_out_1(11) & video_data_out_1(10) & video_data_out_1(9) & video_data_out_1(8)
 & video_data_out_0(18) & video_data_out_0(19) & video_data_out_0(15) & video_data_out_0(23) & video_data_out_0(11) & video_data_out_0(10) & video_data_out_0(9) & video_data_out_0(8);
 
 
 CLINK_DATA_N <= video_data_out_3(18) & video_data_out_3(19) & video_data_out_3(15) & video_data_out_3(23) & video_data_out_3(11) & video_data_out_3(10) & video_data_out_3(9) & video_data_out_3(8)
 & video_data_out_2(18) & video_data_out_2(19) & video_data_out_2(15) & video_data_out_2(23) & video_data_out_2(11) & video_data_out_2(10) & video_data_out_2(9) & video_data_out_2(8);
 
 CLINK_CTRL_P <= video_data_out_4(15) & video_data_out_4(23) & video_data_out_4(11) & video_data_out_4(10) & video_data_out_4(9) & video_data_out_4(8);
 
 CLINK_CTRL_N <= video_data_out_3(24) &video_data_out_3(25)&video_data_out_4(24)& video_data_out_4(25)& video_data_out_4(18) & video_data_out_4(19);

 lvds_tx_inst: entity work.lvds_tx_axi
 generic map(
	SIMULATION          => SIMULATION,
	LVDS_LINK_WIDTH     => 16,
	SERIALIZATION_RATIO => 10,
	DEVICE              => DEVICE,
	ADDRESS_BASE        => x"00002000"
)
port map(	
	axil_clk 			=>  clk_71mhz,
    axil_rstn 			=>  reset_n,
    axilsi              =>  axilmo,
    axilso              =>  axilso_lvds_tx,
	
	txclk               => clk_500mhz,
	txclk_div           => clk_71mhz,
	txclk_phase_shifted => clk_71mhz_shifted,
	txclk_div_reset     => reset_tx_clk_div,
	
	data_in				=> packeted_data,
	
	lvds_tx_data_p      => CLINK_DATA_P_d,
	lvds_tx_data_n      => CLINK_DATA_N_d,
	lvds_tx_clock_p     => CLINK_CLK_P_d,
	lvds_tx_clock_n     => CLINK_CLK_N_d
);

camlink_reg_bank_inst : entity work.axi_lite_reg_bank_slave_record
   GENERIC MAP(
      ADDRESS_BASE  => x"00001000",
      ADDRESS_MASK  => (others => '1'),
      REGISTERS_NBR => REGISTERS_NBR
   )
   PORT MAP(
      AXILSI                 =>  axilmo,
      axil_clk               =>  clk_71mhz,
      axil_rstn              =>  reset_n,
      reg_rd_valid           =>  open,
      reg_rd_value           =>  reg_rd_value,
      reg_rstvalue           =>  reg_rst_value,
      reg_wr_ready           =>  open,
      AXILSO                 =>  axilso_camlink,
      reg_rd_flag            =>  reg_rd_flag,
      reg_wr_flag            =>  reg_wr_flag,
      reg_wr_value           =>  reg_wr_value
   );

reg_rst_value(0) <= x"00000001";
reg_rst_value(1) <= x"00000001";
reg_rst_value(2) <= x"00000001";
reg_rst_value(3) <= x"00000001";
reg_rst_value(4) <= x"00000001";

reg_rd_value(0)  <= reg_wr_value(0);
CAMLINK1_PWR_EN	 <= reg_wr_value(0)(0);
CAMLINK1_PDWN	 <= reg_wr_value(0)(0);

reg_rd_value(1)  <= reg_wr_value(1);
CAMLINK2_PWR_EN	 <= reg_wr_value(1)(0);
CAMLINK2_PDWN	 <= reg_wr_value(1)(0);

reg_rd_value(2)  <= reg_wr_value(2);
CAMLINK3_PWR_EN	 <= reg_wr_value(2)(0);
CAMLINK3_PDWN	 <= reg_wr_value(2)(0);

reg_rd_value(3)  <= reg_wr_value(3);
CAMLINK4_PWR_EN	 <= reg_wr_value(3)(0);
CAMLINK4_PDWN	 <= reg_wr_value(3)(0);

reg_rd_value(4)  <= reg_wr_value(4);
CAMLINK5_PWR_EN	 <= reg_wr_value(4)(0);
CAMLINK5_PDWN	 <= reg_wr_value(4)(0);



end RTL;
