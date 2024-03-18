library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

package amba_pkg is

      type StdLogic2Array_t   is array (natural range <>) of std_logic_vector(  1 downto 0);
      type StdLogic3Array_t   is array (natural range <>) of std_logic_vector(  2 downto 0);
      type StdLogic4Array_t   is array (natural range <>) of std_logic_vector(  3 downto 0);
      type StdLogic5Array_t   is array (natural range <>) of std_logic_vector(  4 downto 0);
      type StdLogic8Array_t   is array (natural range <>) of std_logic_vector(  7 downto 0);
      type StdLogic10Array_t  is array (natural range <>) of std_logic_vector( 9 downto 0);
      type StdLogic16Array_t  is array (natural range <>) of std_logic_vector( 15 downto 0);
      type StdLogic20Array_t  is array (natural range <>) of std_logic_vector( 19 downto 0);
      type StdLogic32Array_t  is array (natural range <>) of std_logic_vector( 31 downto 0);
      type StdLogic64Array_t  is array (natural range <>) of std_logic_vector( 63 downto 0);
      type StdLogic128Array_t is array (natural range <>) of std_logic_vector(127 downto 0);
      
      type NaturalArray_t     is array (natural range <>) of natural;
      
      subtype Registers_t     is StdLogic32Array_t;
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Global constants and Type definitions for  AXI LITE
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	  constant AXIL_ADDR_WIDTH        : positive := 32; -- Width of the ADDRESS bus
	  constant AXIL_DATA_WIDTH        : positive := 32; -- Width of the DATA bus
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Global constants and Type definitions for  AXI FULL
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	  constant AXIF_ID_WIDTH          : positive := 4;  -- Width of the IDENTIFIER bus
	  constant AXIF_ADDR_WIDTH        : positive := 34; -- Width of the ADDRESS bus
	  constant AXIF_DATA_WIDTH        : positive := 512; -- Width of the DATA bus
	
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	--  Types and Records definition for AXI LIGHT
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	Type axil_wadr_mo_type is 
		record
			addr:  std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0);
			valid: std_logic;
		end record;

	Type axil_wadr_mi_type is 
		record
			ready: std_logic;
		end record;

	Type axil_wdat_mo_type is 
		record
			data:  std_logic_vector(AXIL_DATA_WIDTH-1 downto 0);
			strb:  std_logic_vector(AXIL_DATA_WIDTH/8-1 downto 0);
			valid: std_logic;
		end record;

	Type axil_wdat_mi_type is 
		record
			ready: std_logic;
		end record;

	Type axil_wres_mo_type is 
		record
			ready: std_logic;
		end record;

	Type axil_wres_mi_type is 
		record
			resp:  std_logic_vector(1 downto 0);
			valid: std_logic;
		end record;

	Type axil_radr_mo_type is 
		record
			addr:  std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0);
			valid: std_logic;
		end record;

	Type axil_radr_mi_type is 
		record
			ready: std_logic;
		end record;

	Type axil_rdat_mo_type is 
		record
			ready: std_logic;
		end record;

	Type axil_rdat_mi_type is 
		record
			data:  std_logic_vector(AXIL_DATA_WIDTH-1 downto 0);
			resp:  std_logic_vector(1 downto 0);
			valid: std_logic;
		end record;

	Type axil_mo_type is
		record
			wa : axil_wadr_mo_type;
			wd : axil_wdat_mo_type;
			wr : axil_wres_mo_type;
			ra : axil_radr_mo_type;
			rd : axil_rdat_mo_type;
		end record;

	Type axil_mo_array_type is array (natural range <>) of axil_mo_type;

        Type axil_mi_type is
		record
			wa : axil_wadr_mi_type;
			wd : axil_wdat_mi_type;
			wr : axil_wres_mi_type;
			ra : axil_radr_mi_type;
			rd : axil_rdat_mi_type;
		end record;

	Type axil_so_array_type is array (natural range <>) of axil_mi_type;
	Type axil_mi_array_type is array (natural range <>) of axil_mi_type;

	----------------------------------------------------------------------------------------------------------------------------------------------------------
	--  Types and Records definition for AXI FULL
	----------------------------------------------------------------------------------------------------------------------------------------------------------

	Type axif_wadr_mo_type is 
		record
			id:    std_logic_vector(AXIF_ID_WIDTH-1 downto 0);
			addr:  std_logic_vector(AXIF_ADDR_WIDTH-1 downto 0);
			len:   std_logic_vector(7 downto 0);
			size:  std_logic_vector(2 downto 0);
			burst: std_logic_vector(1 downto 0);
			lock:  std_logic_vector(1 downto 0);
			cache: std_logic_vector(3 downto 0);
			prot:  std_logic_vector(2 downto 0);
			valid: std_logic;
		end record;

	Type axif_wadr_mi_type is 
		record
			ready: std_logic;
		end record;

	Type axif_wdat_mo_type is 
		record
			id:    std_logic_vector(AXIF_ID_WIDTH-1 downto 0);
			data:  std_logic_vector(AXIF_DATA_WIDTH-1 downto 0);
			strb:  std_logic_vector(AXIF_DATA_WIDTH/8-1 downto 0);
			last:  std_logic;
			valid: std_logic;
		end record;

	Type axif_wdat_mi_type is 
		record
			ready: std_logic;
		end record;

	Type axif_wres_mo_type is 
		record
			ready: std_logic;
		end record;

	Type axif_wres_mi_type is 
		record
			id:    std_logic_vector(AXIF_ID_WIDTH-1 downto 0);
			resp:  std_logic_vector(1 downto 0);
			valid: std_logic;
		end record;

	Type axif_radr_mo_type is 
		record
			id:    std_logic_vector(AXIF_ID_WIDTH-1 downto 0);
			addr:  std_logic_vector(AXIF_ADDR_WIDTH-1 downto 0);
			len:   std_logic_vector(7 downto 0);
			size:  std_logic_vector(2 downto 0);
			burst: std_logic_vector(1 downto 0);
			lock:  std_logic_vector(1 downto 0);
			cache: std_logic_vector(3 downto 0);
			prot:  std_logic_vector(2 downto 0);
			valid: std_logic;
		end record;

	Type axif_radr_mi_type is 
		record
			ready: std_logic;
		end record;

	Type axif_rdat_mo_type is 
		record
			ready: std_logic;
		end record;

	Type axif_rdat_mi_type is 
		record
			id:    std_logic_vector(AXIF_ID_WIDTH-1 downto 0);
			data:  std_logic_vector(AXIF_DATA_WIDTH-1 downto 0);
			resp:  std_logic_vector(1 downto 0);
			last:  std_logic;
			valid: std_logic;
		end record;

	Type axif_mo_type is
		record
			wa : axif_wadr_mo_type;
			wd : axif_wdat_mo_type;
			wr : axif_wres_mo_type;
			ra : axif_radr_mo_type;
			rd : axif_rdat_mo_type;
		end record;

	Type axif_mo_array_type is array (natural range <>) of axif_mo_type;

        Type axif_mi_type is
		record
			wa : axif_wadr_mi_type;
			wd : axif_wdat_mi_type;
			wr : axif_wres_mi_type;
			ra : axif_radr_mi_type;
			rd : axif_rdat_mi_type;
		end record;

	Type axif_so_array_type is array (natural range <>) of axif_mi_type;
	Type axif_mi_array_type is array (natural range <>) of axif_mi_type;

	Constant AXILMI_INIT : axil_mi_type := (wa => (ready => '0'), wd => (ready => '0'), wr => (resp => (others => '0'), valid => '0'), ra => (ready => '0'), rd => (data => (others => '0'), resp => (others => '0'), valid => '0'));
	Constant AXIFMI_INIT : axif_mi_type := (wa => (ready => '0'), wd => (ready => '0'), wr => (id => (others => '0'), resp => (others => '0'), valid => '0'), ra => (ready => '0'), rd => (id => (others => '0'), data => (others => '0'), resp => (others => '0'), last => '0', valid => '0'));

end amba_pkg;
