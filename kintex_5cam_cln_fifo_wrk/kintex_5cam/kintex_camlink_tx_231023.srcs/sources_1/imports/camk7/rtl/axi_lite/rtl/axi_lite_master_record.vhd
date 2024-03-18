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


ENTITY axi_lite_master_record IS
	GENERIC (
		AXIL_TIMEOUT     		: std_logic_vector(15 downto 0)
	);
	PORT(
        -----------------------clk_rst
		axilmi                 	: in  	axil_mi_type;
		Clk                   	: in 	std_logic;
		rd_addr                	: in  	std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0);
		Rd_Req                	: in 	std_ulogic;
		Rst                   	: in 	std_logic;
		wr_addr                	: in  	std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0);
		wr_data                	: in  	std_logic_vector(AXIL_DATA_WIDTH-1 downto 0);
		Wr_DataStrobe         	: in 	std_logic_vector(AXIL_DATA_WIDTH/8-1 downto 0) := (others => '1');
		Wr_Req                	: in 	std_ulogic;
		AXILMO                	: out 	axil_mo_type;
		Rd_Ack                	: out 	std_ulogic;
		Rd_Data               	: out 	std_logic_vector(AXIL_DATA_WIDTH-1 downto 0);
		Rd_Done               	: out 	std_ulogic;
		Rd_Resp               	: out 	std_logic_vector(1 downto 0);
		Wr_Ack                	: out 	std_ulogic;  
		Wr_Done               	: out 	std_ulogic; 
		Wr_Resp               	: out 	std_logic_vector(1 downto 0)
    );
END entity;

ARCHITECTURE rtl OF axi_lite_master_record IS

	signal response_wait	:	std_logic_vector(9 downto 0)	:= (others => '0');

BEGIN

	axilmo.wd.data		<=	wr_data(AXIL_DATA_WIDTH - 1 downto 0);
	AXILMO.wd.valid		<=	Wr_Req;
	axilmo.wa.addr		<=	wr_addr(AXIL_ADDR_WIDTH - 1 downto 0);
	AXILMO.wa.valid		<=	Rd_Req or Wr_Req;
	
	response:process(Clk)
	begin
		if rising_edge(Clk) then
			response_wait		<=	response_wait(response_wait'left - 1 downto 0) & (Rd_Req or Wr_Req);
			if (axilmi.rd.valid = '1') then
				response_wait	<=	(others => '0');
				Rd_Done			<=	'1';
				Rd_data(AXIL_DATA_WIDTH - 1 downto 0)	<=	axilmi.rd.data;
			elsif (response_wait(response_wait'left) = '1') then
				Rd_Done			<=	'1';
				Rd_data			<=	x"DEADDEAD";
			else
				Rd_Done			<=	'0';
			end if;
		end if;
	end process;
	
END ARCHITECTURE;
