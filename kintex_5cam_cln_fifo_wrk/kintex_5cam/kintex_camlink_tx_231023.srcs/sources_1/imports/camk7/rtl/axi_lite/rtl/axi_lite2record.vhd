library ieee;
use ieee.std_logic_1164.all;
use work.amba_pkg.all;

ENTITY axi_lite2record IS
   PORT( 
      AXILMI        : IN     axil_mi_type;
      s_axi_araddr  : IN     std_logic_vector (AXIL_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
      s_axi_arvalid : IN     std_ulogic                                      := '0';
      s_axi_awaddr  : IN     std_logic_vector (AXIL_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
      s_axi_awvalid : IN     std_ulogic                                      := '0';
      s_axi_bready  : IN     std_ulogic                                      := '0';
      s_axi_rready  : IN     std_ulogic                                      := '0';
      s_axi_wdata   : IN     std_logic_vector (AXIL_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
      s_axi_wstrb   : IN     std_logic_vector (AXIL_DATA_WIDTH/8-1 DOWNTO 0) := (others => '0');
      s_axi_wvalid  : IN     std_ulogic                                      := '0';
      AXILMO        : OUT    axil_mo_type;
      s_axi_arready : OUT    std_ulogic;
      s_axi_awready : OUT    std_ulogic;
      s_axi_bresp   : OUT    std_logic_vector (1 DOWNTO 0);
      s_axi_bvalid  : OUT    std_ulogic;
      s_axi_rdata   : OUT    std_logic_vector (AXIL_DATA_WIDTH-1 DOWNTO 0);
      s_axi_rresp   : OUT    std_logic_vector (1 DOWNTO 0);
      s_axi_rvalid  : OUT    std_ulogic;
      s_axi_wready  : OUT    std_ulogic
   );
END axi_lite2record ;

ARCHITECTURE struct OF axi_lite2record IS

BEGIN

   AXILMO.wa.addr  <= s_axi_awaddr;
   AXILMO.wa.valid <= s_axi_awvalid;
   s_axi_awready   <= AXILMI.wa.ready;
   
   AXILMO.wd.data  <= s_axi_wdata;
   AXILMO.wd.strb  <= s_axi_wstrb;
   AXILMO.wd.valid <= s_axi_wvalid;
   s_axi_wready    <= AXILMI.wd.ready;
   
   s_axi_bresp     <= AXILMI.wr.resp;
   s_axi_bvalid    <= AXILMI.wr.valid;
   AXILMO.wr.ready <= s_axi_bready;
   
   AXILMO.ra.addr  <= s_axi_araddr;
   AXILMO.ra.valid <= s_axi_arvalid;
   s_axi_arready   <= AXILMI.ra.ready;
   
   s_axi_rresp     <= AXILMI.rd.resp;
   s_axi_rdata     <= AXILMI.rd.data;
   s_axi_rvalid    <= AXILMI.rd.valid;
   AXILMO.rd.ready <= s_axi_rready;

END struct;
