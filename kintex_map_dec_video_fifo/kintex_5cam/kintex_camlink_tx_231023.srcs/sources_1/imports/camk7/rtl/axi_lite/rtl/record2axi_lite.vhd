library ieee;
use ieee.std_logic_1164.all;
use work.amba_pkg.all;

ENTITY record2axi_lite IS
   PORT( 
      AXILSI        : IN     axil_mo_type;
      m_axi_arready : IN     std_ulogic                                    := '0';
      m_axi_awready : IN     std_ulogic                                    := '0';
      m_axi_bresp   : IN     std_logic_vector (1 DOWNTO 0)                 := (others => '0');
      m_axi_bvalid  : IN     std_ulogic                                    := '0';
      m_axi_rdata   : IN     std_logic_vector (AXIL_DATA_WIDTH-1 DOWNTO 0) := (others => '0');
      m_axi_rresp   : IN     std_logic_vector (1 DOWNTO 0)                 := (others => '0');
      m_axi_rvalid  : IN     std_ulogic                                    := '0';
      m_axi_wready  : IN     std_ulogic                                    := '0';
      AXILSO        : OUT    axil_mi_type;
      m_axi_araddr  : OUT    std_logic_vector (AXIL_ADDR_WIDTH-1 DOWNTO 0);
      m_axi_arvalid : OUT    std_ulogic;
      m_axi_awaddr  : OUT    std_logic_vector (AXIL_ADDR_WIDTH-1 DOWNTO 0);
      m_axi_awvalid : OUT    std_ulogic;
      m_axi_bready  : OUT    std_ulogic;
      m_axi_rready  : OUT    std_ulogic;
      m_axi_wdata   : OUT    std_logic_vector (AXIL_DATA_WIDTH-1 DOWNTO 0);
      m_axi_wstrb   : OUT    std_logic_vector (AXIL_DATA_WIDTH/8-1 DOWNTO 0);
      m_axi_wvalid  : OUT    std_ulogic
   );
END record2axi_lite ;

ARCHITECTURE struct OF record2axi_lite IS

BEGIN

   m_axi_awaddr    <= AXILSI.wa.addr;
   m_axi_awvalid   <= AXILSI.wa.valid;
   AXILSO.wa.ready <= m_axi_awready;
   
   m_axi_wdata     <= AXILSI.wd.data;
   m_axi_wstrb     <= AXILSI.wd.strb;
   m_axi_wvalid    <= AXILSI.wd.valid;
   AXILSO.wd.ready <= m_axi_wready;
   
   AXILSO.wr.resp  <= m_axi_bresp;
   AXILSO.wr.valid <= m_axi_bvalid;
   m_axi_bready    <= AXILSI.wr.ready;
   
   m_axi_araddr    <= AXILSI.ra.addr;
   m_axi_arvalid   <= AXILSI.ra.valid;
   AXILSO.ra.ready <= m_axi_arready;
   
   AXILSO.rd.data  <= m_axi_rdata;
   AXILSO.rd.resp  <= m_axi_rresp;
   AXILSO.rd.valid <= m_axi_rvalid;
   m_axi_rready    <= AXILSI.rd.ready;

END struct;
