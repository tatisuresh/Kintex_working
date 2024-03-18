-- ENABLE_OPTIMIZATION enables Address width optimization
-- Address of slave becomes OPTIMIZED_WIDTH
-- for eg. if ADDRESS WIDTH is 16 and OPTIMIZED WIDTH 8
-- addresses for 1st slave = 0x0000 to 0x00FF
-- addresses for 2nd slave = 0x0100 to 0x01FF
-- addresses for 3rd slave = 0x0200 to 0x02FF and so on...

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use work.amba_pkg.all;


ENTITY axil_lite_master IS
   GENERIC (DEVICE             : string     := "7SERIES"
   );
   PORT(
        -----------------------clk_rst
        axil_clk               : in  std_logic;
        axil_rst               : in  std_logic;
        design_clk             : in  std_logic;
        --axi_bus
        axilmi                 : in  axil_mi_type;
        axilmo                 : out axil_mo_type;
        --read
        rd_addr                : in  std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0);
        Rd_data                : out std_logic_vector(AXIL_DATA_WIDTH-1 downto 0);
        rd_en                  : in  std_logic;
        Rd_Done                : out std_logic;
        Rd_Ack                 : out std_logic;
        --write 
        wr_addr                : in  std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0);
        wr_be                  : in  std_logic_vector(AXIL_DATA_WIDTH/8-1 downto 0) := (others => '1');  
        wr_data                : in  std_logic_vector(AXIL_DATA_WIDTH-1 downto 0);
        wr_en                  : in  std_logic;
        wr_busy                : out std_logic  := '0'
    );
END entity;

ARCHITECTURE rtl OF axil_lite_master IS

	signal response_wait	:	std_logic_vector(9 downto 0)	:= (others => '0');

BEGIN

	axilmo.wd.data		<=	wr_data(AXIL_DATA_WIDTH - 1 downto 0);
	axilmo.wd.valid		<=	wr_en;
	axilmo.wa.addr		<=	wr_addr(AXIL_ADDR_WIDTH - 1 downto 0);
	axilmo.wa.valid		<=	rd_en or wr_en;
	
	response:process(axil_clk)
	begin
		if rising_edge(axil_clk) then
			response_wait	<=	response_wait(response_wait'left - 1 downto 0) & (rd_en or wr_en);
			if (axilmi.rd.valid = '1') then
				response_wait	<=	(others => '0');
				Rd_Done		<=	'1';
				Rd_data(AXIL_DATA_WIDTH - 1 downto 0)	<=	axilmi.rd.data;
			elsif (response_wait(response_wait'left) = '1') then
				Rd_Done		<=	'1';
				Rd_data		<=	x"DEADDEAD";
			else
				Rd_Done		<=	'0';
			end if;
		end if;
	end process;
	
END ARCHITECTURE;
