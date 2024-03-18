-- ENABLE_OPTIMIZATION enables Address width optimization
-- Address of slave becomes OPTIMIZED_WIDTH
-- for eg. if ADDRESS WIDTH is 16 and OPTIMIZED WIDTH 8
-- addresses for 1st slave = 0x0000 to 0x00FF
-- addresses for 2nd slave = 0x0100 to 0x01FF
-- addresses for 3rd slave = 0x0200 to 0x02FF and so on...

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;
use work.amba_pkg.all;

ENTITY axi_lite_reg_bank_slave_record IS
	GENERIC( 
		ADDRESS_BASE		:	std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0)	:=	(others => '0');
		ADDRESS_MASK		:	std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0)	:=	(others => '0');
		REGISTERS_NBR	  	:	positive 	:= 	64
	);
	PORT( 
		AXILSI       		: 	IN     	axil_mo_type;
		AXILSO       		: 	OUT    	axil_mi_type;
		reg_rd_value  		:	IN		registers_t (REGISTERS_NBR-1 DOWNTO 0)	:= (others => (others => '0'));
		reg_rstvalue  		:	IN		registers_t (REGISTERS_NBR-1 DOWNTO 0)	:= (others => (others => '0'));
		reg_rd_valid   		:	in		std_logic_vector (REGISTERS_NBR-1 DOWNTO 0):= (others => '0');
		reg_wr_ready   		:	in		std_logic_vector (REGISTERS_NBR-1 DOWNTO 0):= (others => '1'); -- unused
		reg_rd_flag   		:	out		std_logic_vector (REGISTERS_NBR-1 DOWNTO 0):= (others => '1'); -- unused
		reg_wr_flag   		:	OUT		std_logic_vector (REGISTERS_NBR-1 DOWNTO 0):= (others => '0');
		reg_wr_value  		:	OUT		registers_t (REGISTERS_NBR-1 DOWNTO 0)	:= (others => (others => '0'));
		axil_clk			:	in		std_logic;
		axil_rstn			:	in		std_logic
	);
END entity ;

ARCHITECTURE rtl OF axi_lite_reg_bank_slave_record IS

	constant	VALID_ADDR_BITS	:	integer		:=	integer(ceil(log2(real(REGISTERS_NBR))));
	
	signal	selected			:	std_logic;
	signal	local_address		:	std_logic_vector(AXIL_ADDR_WIDTH-3 downto 0)	:= (others => '0');

BEGIN

	local_address	<=	AXILSI.wa.addr(AXIL_ADDR_WIDTH-1 downto 2) - ADDRESS_BASE(AXIL_ADDR_WIDTH-1 downto 2);
	selected		<=	'1'	when (local_address(local_address'left) = '0') and (local_address < REGISTERS_NBR) else '0';
	
	selection:process(axil_clk)
	begin
		if rising_edge(axil_clk) then
			if axil_rstn = '0' then
				reg_wr_value					<=	reg_rstvalue;
				reg_rd_flag						<=	(others => '0');
				reg_wr_flag						<=	(others => '0');
				AXILSO.rd.DATA					<=	(others => '0');
				AXILSO.rd.VALID					<=	'0';
			else
				reg_rd_flag						<=	(others => '0');
				reg_wr_flag						<=	(others => '0');
				AXILSO.rd.DATA					<=	(others => '0');
				AXILSO.rd.VALID					<=	'0';
				if (selected = '1') and (AXILSI.wa.valid = '1') then
					for i in 0 to REGISTERS_NBR - 1 loop
						if (i = local_address(VALID_ADDR_BITS - 1 downto 0)) then
							if (AXILSI.wd.valid = '1') then
								reg_wr_flag(i)	<=	'1';
								reg_wr_value(i)	<=	AXILSI.wd.DATA;
							end if;
							reg_rd_flag(i)		<=	not AXILSI.wd.valid;
							AXILSO.rd.DATA		<=	reg_rd_value(i);
							AXILSO.rd.VALID		<=	'1';
						end if;
					end loop;
				end if;
			end if;
		end if;
	end process;
	
	
END ARCHITECTURE;
