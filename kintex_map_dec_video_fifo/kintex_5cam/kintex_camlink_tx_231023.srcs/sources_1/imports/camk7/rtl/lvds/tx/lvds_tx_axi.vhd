library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

USE work.amba_pkg.all;
USE work.lvds_tx_pkg.all;


entity lvds_tx_axi is
  generic(
    SIMULATION                : string  := "FALSE";
    LVDS_LINK_WIDTH           : natural := 17;
    SERIALIZATION_RATIO       : natural := 8;
    DATA_RATE_OQ              : string  := "DDR";
    DATA_RATE_TQ              : string  := "DDR";
    DEVICE                    : string  := "Virtex6";      -- valid values "Virtex6", "7Series"
    ADDRESS_BASE              : std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0) := (others => '0')
    );
  port(
    axil_clk                  : in  std_logic;
    axil_rstn                 : in  std_logic;
    axilsi                    : in  axil_mo_type;
    axilso                    : out axil_mi_type;

    ---------------------LVDS INTERFACE-------------------------------------------
    txclk                     : in std_logic; --SERIAL SIDE TX CLOCK
    txclk_div                 : in std_logic; --PARALLEL SIDE TX CLOCK (DIVIDED FROM TXCLK)
    txclk_phase_shifted       : in std_logic; --PHASE SHIFTED SERIAL SIDE TX CLOCK
    txclk_div_reset           : in std_logic; --TX DOMAIN RESET
    
    data_in                   : in std_logic_vector(LVDS_LINK_WIDTH * SERIALIZATION_RATIO - 1 downto 0);
    
    lvds_tx_data_p            : out std_logic_vector(LVDS_LINK_WIDTH - 1 downto 0); --SERIAL SIDE TX DATA (P)
    lvds_tx_data_n            : out std_logic_vector(LVDS_LINK_WIDTH - 1 downto 0); --SERIAL SIDE TX DATA (N)
    lvds_tx_clock_p           : out std_logic; --FORWARDED CLOCK TO RX (P)
    lvds_tx_clock_n           : out std_logic  --FORWARDED CLOCK TO RX (N)
    );

end lvds_tx_axi;

architecture rtl of lvds_tx_axi is

constant DATA_WIDTH : natural := LVDS_LINK_WIDTH * SERIALIZATION_RATIO;
---------------------------------------------------------------------
--SIGNAL DECLARATION
---------------------------------------------------------------------

signal training_enable                : std_logic := '0';
signal training_done                  : std_logic := '1';
signal training_pattern               : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

signal training_enable_axi            : std_logic := '0';
signal training_pattern_axi           : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

signal training_enable_metastable     : std_logic := '0';
signal training_pattern_metastable    : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
signal prbs_data_out                  : std_logic_vector(LVDS_LINK_WIDTH*SERIALIZATION_RATIO-1 downto 0);
signal send_prbs_pattern              : std_logic;
signal tx_data_in                     : std_logic_vector(LVDS_LINK_WIDTH * SERIALIZATION_RATIO - 1 downto 0);


begin


inst_reg_interface  : entity work.lvds_tx_reg_interface
  generic map(
    DATA_WIDTH          => DATA_WIDTH,
    ADDRESS_BASE        => ADDRESS_BASE
    )
  port map(
    axil_clk            => axil_clk,
    axil_rstn           => axil_rstn,
    axilsi              => axilsi,
    axilso              => axilso,

    training_enable     => training_enable_axi,
    training_pattern    => training_pattern_axi,
    send_prbs_pattern   => send_prbs_pattern
    );

--synchronizer logic

process(txclk_div)
begin
  if(rising_edge(txclk_div)) then
    training_enable_metastable      <=  training_enable_axi;
    training_pattern_metastable     <=  training_pattern_axi;
    
    training_enable                 <=  training_enable_metastable;
    training_pattern                <=  training_pattern_metastable;
  end if;
end process;


prbs_gen_inst : entity work.prbs_gen_check
   generic map(      
      NBITS       => LVDS_LINK_WIDTH*SERIALIZATION_RATIO
   )
   port map(
      RST         => txclk_div_reset,      
      CLK         => txclk_div,  
      DATA_IN     => (others => '0'),     
      EN          => '1',      
      DATA_OUT    => prbs_data_out 
   );

   
tx_data_in <= prbs_data_out when send_prbs_pattern = '1' else data_in;

-- inst_lvds_tx : entity work.lvds_transmitter
  -- generic map(
    -- SIMULATION          =>  SIMULATION,
    -- DATA_RATE_OQ        =>  DATA_RATE_OQ,
    -- DATA_RATE_TQ        =>  DATA_RATE_TQ,
    -- DEVICE              =>  DEVICE,
    -- LVDS_LINK_WIDTH     =>  LVDS_LINK_WIDTH,
    -- SERIALIZATION_RATIO =>  SERIALIZATION_RATIO
    
    -- )
  -- port map(
    -- txclk               =>  txclk,
    -- txclk_div           =>  txclk_div,
    -- txclk_phase_shifted =>  txclk_phase_shifted,
    -- txclk_div_reset     =>  txclk_div_reset,

    -- lvds_tx_data_p      =>  lvds_tx_data_p,
    -- lvds_tx_data_n      =>  lvds_tx_data_n,
    -- lvds_tx_clock_p     =>  lvds_tx_clock_p,
    -- lvds_tx_clock_n     =>  lvds_tx_clock_n,

    -- training_enable     =>  training_enable,
    -- training_pattern    =>  training_pattern,
    -- data_in             =>  tx_data_in
-- );


inst_lvds_tx : entity work.k7_DDR_8TO1_TX
     generic map(
    P_LVDS_LINES => 16
    )
  port map(
  
         TXCLK              => txclk,
		 TXCLKDIV           => txclk_div,
		 RESET              => txclk_div_reset,

		 DATA_TO_OSERDES    => tx_data_in (127 downto 0),
		 TRAINING_START     => open ,
		 LVDS_TRAINING_DONE => open ,
		 DEBUG_SIGNALS      => open ,
			
		 DATA_TX_P          => lvds_tx_data_p,
		 DATA_TX_N          => lvds_tx_data_n,
         CLOCK_TX_P         => lvds_tx_clock_p,
         CLOCK_TX_N         => lvds_tx_clock_n,
			
         TRAINING_DONE      => training_done
  
  
  
  );
  
end rtl;
