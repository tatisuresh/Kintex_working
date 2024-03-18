library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

--:wlibrary unisim;
--:use unisim.vcomponents.all;

USE work.amba_pkg.all;

ENTITY axi_lite_interconnect_top IS
   PORT(      
      AXILSO0        : in  axil_mi_type := AXILMI_INIT;
      AXILSO1        : in  axil_mi_type := AXILMI_INIT;
      AXILSO2        : in  axil_mi_type := AXILMI_INIT;
      AXILSO3        : in  axil_mi_type := AXILMI_INIT;
      AXILSO4        : in  axil_mi_type := AXILMI_INIT;
      AXILSO5        : in  axil_mi_type := AXILMI_INIT;
      AXILSO6        : in  axil_mi_type := AXILMI_INIT;
      AXILSO7        : in  axil_mi_type := AXILMI_INIT;
      AXILSO8        : in  axil_mi_type := AXILMI_INIT;
      AXILSO9        : in  axil_mi_type := AXILMI_INIT;
      AXILMI         : out axil_mi_type        
   );
END axi_lite_interconnect_top ;

ARCHITECTURE rtl OF axi_lite_interconnect_top IS
constant LITE_NBR_SLAVES_g : positive := 10;
signal AXILSO_ALL          : axil_mi_array_type (LITE_NBR_SLAVES_g-1 DOWNTO 0) := (others => AXILMI_INIT);
signal AXILMI_ALL          : axil_mi_array_type (0 DOWNTO 0) := (others => AXILMI_INIT); --only single master

BEGIN

AXILSO_ALL <= AXILSO9 & AXILSO8 & AXILSO7 & AXILSO6 & AXILSO5 & AXILSO4 & AXILSO3 & AXILSO2 & AXILSO1 & AXILSO0;
axi_interconnect_or_so_inst : entity work.axi_interconnect_or_so
   GENERIC MAP( 
      LITE_NBR_MASTERS_g      =>       1,
      LITE_NBR_SLAVES_g       =>       LITE_NBR_SLAVES_g,
      FULL_NBR_MASTERS_g      =>       1,
      FULL_NBR_SLAVES_g       =>       1
   )
   PORT MAP( 
      AXIFMI   =>  open,
      AXILMI   =>  AXILSO_ALL,
      AXIFSO   =>  open,
      AXILSO   =>  AXILMI_ALL
   );

--output mapping
AXILMI <=  AXILMI_ALL(0); 

END rtl;

