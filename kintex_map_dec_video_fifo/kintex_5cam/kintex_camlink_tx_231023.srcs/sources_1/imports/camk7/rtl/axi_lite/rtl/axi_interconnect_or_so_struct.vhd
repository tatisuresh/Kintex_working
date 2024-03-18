library ieee;
use ieee.std_logic_1164.all;
library work;
use work.amba_pkg.all;

ENTITY axi_interconnect_or_so IS
   GENERIC( 
      LITE_NBR_MASTERS_g : positive := 1;
      LITE_NBR_SLAVES_g  : positive := 1;
      FULL_NBR_MASTERS_g : positive := 1;
      FULL_NBR_SLAVES_g  : positive := 1
   );
   PORT( 
      AXIFMI : IN     axif_mi_array_type (FULL_NBR_SLAVES_g-1 DOWNTO 0) := (others => (wa => (ready => '0'), wd => (ready => '0'), wr => (id => (others => '0'), resp => (others => '0'), valid => '0'), ra => (ready => '0'), rd => (id => (others => '0'), data => (others => '0'), resp => (others => '0'), last => '0', valid => '0')));
      AXILMI : IN     axil_mi_array_type (LITE_NBR_SLAVES_g-1 DOWNTO 0) := (others => AXILMI_INIT);
      AXIFSO : OUT    axif_mi_array_type (FULL_NBR_MASTERS_g-1 DOWNTO 0);
      AXILSO : OUT    axil_mi_array_type (LITE_NBR_MASTERS_g-1 DOWNTO 0)
   );


END axi_interconnect_or_so ;

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.amba_pkg.all;


ARCHITECTURE struct OF axi_interconnect_or_so IS



BEGIN
   assert LITE_NBR_MASTERS_g = 1
       report "axi_interconnect_or: LITE_NBR_MASTERS_g > 1 not implemented yet."
       severity failure;
   
   assert FULL_NBR_MASTERS_g = 1
       report "axi_interconnect_or: FULL_NBR_MASTERS_g > 1 not implemented yet."
       severity failure;

   p_lite : process (AXILMI)
     variable v_AXILSO : axil_mi_array_type(LITE_NBR_SLAVES_g-1 downto 0);
   begin
     v_AXILSO := AXILMI;
   
     if LITE_NBR_SLAVES_g > 1 then
       for i in 1 to v_AXILSO'left loop
         v_AXILSO(i).wa.ready := v_AXILSO(i).wa.ready or v_AXILSO(i-1).wa.ready;
         v_AXILSO(i).wd.ready := v_AXILSO(i).wd.ready or v_AXILSO(i-1).wd.ready;
         v_AXILSO(i).wr.resp  := v_AXILSO(i).wr.resp or v_AXILSO(i-1).wr.resp;
         v_AXILSO(i).wr.valid := v_AXILSO(i).wr.valid or v_AXILSO(i-1).wr.valid;
         v_AXILSO(i).ra.ready := v_AXILSO(i).ra.ready or v_AXILSO(i-1).ra.ready;
         v_AXILSO(i).rd.resp  := v_AXILSO(i).rd.resp or v_AXILSO(i-1).rd.resp;
         v_AXILSO(i).rd.data  := v_AXILSO(i).rd.data or v_AXILSO(i-1).rd.data;
         v_AXILSO(i).rd.valid := v_AXILSO(i).rd.valid or v_AXILSO(i-1).rd.valid;
       end loop;
     end if;
   
     AXILSO <= (others => v_AXILSO(v_AXILSO'left));
   end process;
   
   p_full : process (AXIFMI)
     variable v_AXIFSO : axif_mi_array_type(FULL_NBR_SLAVES_g-1 downto 0);
   begin
     v_AXIFSO := AXIFMI;
   
     if FULL_NBR_SLAVES_g > 1 then
       for i in 1 to v_AXIFSO'left loop
         v_AXIFSO(i).wa.ready := v_AXIFSO(i).wa.ready or v_AXIFSO(i-1).wa.ready;
         v_AXIFSO(i).wd.ready := v_AXIFSO(i).wd.ready or v_AXIFSO(i-1).wd.ready;
         v_AXIFSO(i).wr.id    := v_AXIFSO(i).wr.id or v_AXIFSO(i-1).wr.id;
         v_AXIFSO(i).wr.resp  := v_AXIFSO(i).wr.resp or v_AXIFSO(i-1).wr.resp;
         v_AXIFSO(i).wr.valid := v_AXIFSO(i).wr.valid or v_AXIFSO(i-1).wr.valid;
         v_AXIFSO(i).ra.ready := v_AXIFSO(i).ra.ready or v_AXIFSO(i-1).ra.ready;
         v_AXIFSO(i).rd.id    := v_AXIFSO(i).rd.id or v_AXIFSO(i-1).rd.id;
         v_AXIFSO(i).rd.resp  := v_AXIFSO(i).rd.resp or v_AXIFSO(i-1).rd.resp;
         v_AXIFSO(i).rd.data  := v_AXIFSO(i).rd.data or v_AXIFSO(i-1).rd.data;
         v_AXIFSO(i).rd.last  := v_AXIFSO(i).rd.last or v_AXIFSO(i-1).rd.last;
         v_AXIFSO(i).rd.valid := v_AXIFSO(i).rd.valid or v_AXIFSO(i-1).rd.valid;
       end loop;
     end if;
   
     AXIFSO <= (others => v_AXIFSO(v_AXIFSO'left));
   end process;
   



END struct;
