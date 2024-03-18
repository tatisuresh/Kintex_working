library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

USE work.amba_pkg.all;


entity lvds_tx_reg_interface is
  generic(
    DATA_WIDTH              : natural;
    ADDRESS_BASE            : std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0)
    );
  port(
    axil_clk                : in  std_logic;
    axil_rstn               : in  std_logic;
    axilsi                  : in  axil_mo_type;
    axilso                  : out axil_mi_type;

    training_enable         : out std_logic;                                  --active high value indicates that training pattern is transmitting 
    training_pattern        : out std_logic_vector(DATA_WIDTH - 1 downto 0);  --value of training pattern
    send_prbs_pattern       : out std_logic                                   --active high value indicates that PRBS pattern should be transmitted  
    );
    
end lvds_tx_reg_interface;
    
architecture rtl of lvds_tx_reg_interface is

function nearest_32multiple( num_in : natural) return natural is
  variable index  : natural := 1;
begin
  if(num_in <= 32 ) then
    return 32;
  else
    while index < num_in loop
      index := index + 32;
    end loop;
  end if;
  return index;
end function nearest_32multiple;

constant REGISTERS_NBR  :  natural := nearest_32multiple(DATA_WIDTH)/32 + 1;

signal reg_rd_value     : Registers_t(REGISTERS_NBR - 1 downto 0);
signal reg_wr_value     : Registers_t(REGISTERS_NBR - 1 downto 0);
signal reg_rst_value    : Registers_t(REGISTERS_NBR - 1 downto 0):= (others => (others => '0'));

signal reg_rd_flag      : std_logic_vector(REGISTERS_NBR - 1 downto 0)   :=  (others => '0');
signal reg_wr_flag      : std_logic_vector(REGISTERS_NBR - 1 downto 0)   :=  (others => '0');


begin

reg_bank_inst : entity work.axi_lite_reg_bank_slave_record
   GENERIC MAP(
      ADDRESS_BASE  => ADDRESS_BASE,
      ADDRESS_MASK  => (others => '1'),
      REGISTERS_NBR => REGISTERS_NBR
   )
   PORT MAP(
      AXILSI                 =>  axilsi,
      axil_clk               =>  axil_clk,
      axil_rstn              =>  axil_rstn,
      reg_rd_valid           =>  open,
      reg_rd_value           =>  reg_rd_value,
      reg_rstvalue           =>  reg_rst_value,
      reg_wr_ready           =>  open,
      AXILSO                 =>  axilso,
      reg_rd_flag            =>  reg_rd_flag,
      reg_wr_flag            =>  reg_wr_flag,
      reg_wr_value           =>  reg_wr_value
   );
   
gen_registers : for i in 0 to REGISTERS_NBR - 2 generate
  gen_less :  if(DATA_WIDTH < (i+1)*32) generate
    training_pattern(DATA_WIDTH - 1 downto i*32)  <= reg_wr_value(i+1)(DATA_WIDTH - i*32 - 1 downto 0);
  end generate gen_less;
  gen_full :  if(DATA_WIDTH >= (i+1)*32) generate
    training_pattern((i+1)*32 - 1 downto i*32)    <= reg_wr_value(i+1);
  end generate gen_full;
  reg_rd_value(i + 1)               <= reg_wr_value(i + 1);
end generate gen_registers;

training_enable     <= reg_wr_value(0)(0);
send_prbs_pattern   <= reg_wr_value(0)(1);
reg_rd_value(0)     <= reg_wr_value(0);


end rtl;
