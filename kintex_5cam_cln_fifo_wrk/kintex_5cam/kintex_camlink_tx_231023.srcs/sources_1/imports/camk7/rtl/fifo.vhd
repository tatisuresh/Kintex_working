library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
library std;
use std.textio.all;

entity fifo is
    generic(
        DEPTH_g                 :   positive    :=  64;
        WIDTH_g                 :   positive    :=  28;
        RAM_STYLE_g             :   string      :=  "BRAM";     -- BRAM,DRAM
        FWFT_g                  :   boolean     :=  false;
        SYNC_g                  :   boolean     :=  false;
        ALMOST_FULL_LEVEL_g     :   integer     :=  32;
        ALMOST_EMPTY_LEVEL_g    :   integer     :=  8;
        RESET_EXTEND_SIZE       :   integer     :=  10;
        -- MAX_TIME_SKEW is timing constraint for skew among CDC signals.
        -- This parameter is Only meant to be increased in steps of 100 ps, "strictly" in case of timing failures
        -- for most of practical projects, 200 PS should be sufficient.
        -- Please contact developer in case this parameter is not met till a value 500 PS
        MAX_TIME_SKEW           :   string      :=  "200 ps"
    );
    port(
        Rst             : in    std_logic                                                           := '0';
        Wr_Clk          : in    std_logic                                                           := '0';
        --- fifo is internally protected for write and read
        Wr_Ena          : in    std_logic                                                           := '0';
        Wr_Level        : out   std_logic_vector (integer((log2(real(DEPTH_g)))) downto 0)          := (others => '0');
        Wr_Data         : in    std_logic_vector (WIDTH_g-1 downto 0)                               := (others => '0');
        Full            : out   std_logic;
        AlmFull         : out   std_logic;
        Rd_Clk          : in    std_logic                                                           := '0';
        Rd_Ena          : in    std_logic                                                           := '0';
        Rd_Level        : out   std_logic_vector (integer((log2(real(DEPTH_g)))) downto 0)          := (others => '0');
        Rd_Data         : out   std_logic_vector (WIDTH_g-1 downto 0)                               := (others => '0');
        Rd_Valid        : out   std_logic;
        Empty           : out   std_logic;
        AlmEmpty        : out   std_logic;
		debug_wr_fifo	: out	std_logic_vector(69 downto 0);
		debug_rd_fifo	: out	std_logic_vector(60 downto 0)
    );
    
attribute dont_touch : string;
attribute dont_touch of fifo : entity is "true|yes";
    
end entity;

architecture rtl of fifo is




    function is_block_ram(a : string) return string is
    begin
        if a = "BRAM" then
            return "block";
        else
            return "distributed";
        end if;
    end function;

    function altera_ram(a : string) return string is
    begin
        if a = "BRAM" then
            return "M20K";
        else
            return "MLAB";
        end if;
    end function;

    type memory_type is array (natural range <> ) of std_logic_vector(WIDTH_g - 1 downto 0);
    signal MEMORY                           :   memory_type(DEPTH_g - 1 downto 0)   :=  (others => (others => '0'));
    attribute ram_style                     :   string;
    attribute ram_style of MEMORY           :   signal is is_block_ram(RAM_STYLE_g);
    attribute ramstyle                      :   string;
    attribute ramstyle of MEMORY            :   signal is altera_ram(RAM_STYLE_g);
    attribute block_ram                     :   boolean;
    attribute block_ram of MEMORY           :   signal is (RAM_STYLE_g = "BRAM");

    signal extended_reset_a                 :   std_logic_vector(RESET_EXTEND_SIZE downto 0)    :=  (others => '0');
    signal extended_reset_b                 :   std_logic_vector(RESET_EXTEND_SIZE downto 0)    :=  (others => '0');
    signal wr_port_address                  :   std_logic_vector(Wr_Level'left     downto 0)    :=  (others => '0');
    signal wr_port_address_binary           :   std_logic_vector(Wr_Level'left + 1 downto 0)    :=  (others => '0');
    signal wr_port_address_synced_binary    :   std_logic_vector(Wr_Level'left + 1 downto 0)    :=  (others => '0');
    signal Wr_Level_diff                    :   std_logic_vector(Wr_Level'left + 1 downto 0)    :=  (others => '0');
    signal Wr_Level_i                       :   std_logic_vector(Wr_Level'left     downto 0)    :=  (others => '0');
    signal rd_port_address                  :   std_logic_vector(Wr_Level'left     downto 0)    :=  (others => '0');
    signal rd_port_address_binary           :   std_logic_vector(Wr_Level'left + 1 downto 0)    :=  (others => '0');
    signal rd_port_address_synced_binary    :   std_logic_vector(Wr_Level'left + 1 downto 0)    :=  (others => '0');
    signal Rd_Level_diff                    :   std_logic_vector(Wr_Level'left + 1 downto 0)    :=  (others => '0');
    signal Rd_Level_i                       :   std_logic_vector(Wr_Level'left     downto 0)    :=  (others => '0');
    signal a_address                        :   std_logic_vector(Wr_Level'left + 2 downto 0)    :=  (others => '0');
    signal b_address                        :   std_logic_vector(Wr_Level'left + 2 downto 0)    :=  (others => '0');
    signal B_Q_I                            :   std_logic_vector(Rd_Data'range)                 :=  (others => '0');
    signal B_Q_I_d                          :   std_logic_vector(Rd_Data'range)                 :=  (others => '0');
    signal a_valid_metastable               :   std_logic                                       :=  '0';
    signal a_valid_synced                   :   std_logic                                       :=  '0';
    signal b_valid_metastable               :   std_logic                                       :=  '0';
    signal b_valid_synced                   :   std_logic                                       :=  '0';
    signal fifo_full                        :   std_logic                                       :=  '0';
    signal fifo_empty                       :   std_logic                                       :=  '0';
    signal reg_is_valid                     :   std_logic                                       :=  '0';
    signal B_RdEna_d                        :   std_logic                                       :=  '0';
    signal rd_en_int                        :   std_logic                                       :=  '0';
    signal rd_en_int_d                      :   std_logic                                       :=  '0';
    signal A_Rst                            :   std_logic                                       :=  '0';
    signal B_Rst                            :   std_logic                                       :=  '0';

    attribute MAXSKEW                       :   string;
    attribute MAXSKEW of a_address          :   signal is MAX_TIME_SKEW;
    attribute MAXSKEW of b_address          :   signal is MAX_TIME_SKEW;

begin

    a_rst_extend:process(Wr_Clk, rst)
    begin
        if rst = '1' then
            extended_reset_a    <=  (others => '1');
        elsif rising_edge(Wr_Clk) then
            extended_reset_a    <=  extended_reset_a(extended_reset_a'left - 1 downto 0) & '0'; --using shift register to make A_Rst ='0' after 10 clock cycle
        end if;
    end process;
    A_Rst   <=  extended_reset_a(extended_reset_a'left);

    b_rst_extend:process(Rd_Clk, rst)
    begin
        if rst = '1' then
            extended_reset_b    <=  (others => '1');
        elsif rising_edge(Rd_Clk) then
            extended_reset_b    <=  extended_reset_b(extended_reset_b'left - 1 downto 0) & '0';  --using shift register to make B_Rst ='0' after 10 clock cycle
        end if;
    end process;
    B_Rst   <=  extended_reset_b(extended_reset_b'left);

    wr_addr:process(Wr_Clk)
    begin
        if rising_edge(Wr_Clk) then
            if A_rst = '1' then
                wr_port_address_binary                      <=  (others => '0');
                wr_port_address                             <=  (others => '0');
            else
                if (Wr_Ena = '1') and (fifo_full = '0') then -- checking for wr_en and (fifo_full < fifo_depth then only fifo_full = '0')
                        wr_port_address_binary              <=  wr_port_address_binary + 1;
                    if (wr_port_address = DEPTH_g - 1) then
                        wr_port_address                     <=  (others => '0');
                    else
                        wr_port_address                     <=  wr_port_address + 1;
                    end if;
                    MEMORY(to_integer(unsigned(wr_port_address)))   <=  Wr_Data;
                end if;
            end if;
        end if;
    end process;

    rd_addr:process(Rd_Clk)
    begin
        if rising_edge(Rd_Clk) then
            if B_rst = '1' then
                rd_port_address_binary          <=  (others => '0');
                rd_port_address                 <=  (others => '0');
                B_Q_I                           <=  (others => '0');
                B_Q_I_d                         <=  (others => '0');
                rd_en_int_d                     <=  '0';
            else
                rd_en_int_d                     <=  rd_en_int;
                if rd_en_int = '1' then
                    rd_port_address_binary      <=  rd_port_address_binary + 1;
                    if (rd_port_address = DEPTH_g - 1) then
                        rd_port_address         <=  (others => '0');
                    else
                        rd_port_address         <=  rd_port_address + 1;
                    end if;
                end if;
                if rd_en_int_d = '1' then
                    B_Q_I_d                     <=  B_Q_I;
                end if;
                B_Q_I                           <=  MEMORY(to_integer(unsigned(rd_port_address)));
            end if;
        end if;
    end process;
    rd_en_int           <=  '1' when ((Rd_Ena = '1') and (fifo_empty = '0')) or ((FWFT_g) and (fifo_empty = '0') and (reg_is_valid = '0')) else '0';

    reg_valid:process(Rd_Clk)
    begin
        if rising_edge(Rd_Clk) then
            if (B_rst = '1') then
                reg_is_valid    <=  '0';
                B_RdEna_d       <=  '0';
            else
                B_RdEna_d       <=  Rd_Ena and (not fifo_empty);
                if (Rd_Ena = '1') and (fifo_empty = '1') then
                    reg_is_valid    <=  '0';
                elsif rd_en_int = '1' then
                    reg_is_valid    <=  '1';
                end if;
            end if;
        end if;
    end process;

    Rd_Data     <=  B_Q_I when rd_en_int_d = '1' else B_Q_I_d;
    Rd_Valid    <=  reg_is_valid when (FWFT_g) else B_RdEna_d;

    a_to_b_sync:process(Wr_Clk)
    begin
        if rising_edge(Wr_Clk) then
            if (A_rst = '1') then
                b_valid_metastable      <=  '0';
                b_valid_synced          <=  '0';
                a_address               <=  (others => '0');
                rd_port_address_synced_binary   <=  (others => '0');
            else
                b_valid_metastable      <=  b_address(b_address'left);
                b_valid_synced          <=  b_valid_metastable;
                if (a_address(a_address'left)  = '0') and (a_valid_metastable = '0') then
                    a_address           <=  '1' & wr_port_address_binary;
                elsif (a_valid_metastable = '1') and (a_address(a_address'left)  = '1') then
                    a_address           <=  '0' & wr_port_address_binary;
                end if;
                if (b_valid_synced = '0') and (b_valid_metastable = '1') then
                    rd_port_address_synced_binary   <=  b_address(b_address'left - 1 downto 0);
                end if;
            end if;
        end if;
    end process;

    b_to_a_sync:process(Rd_Clk)
    begin
        if rising_edge(Rd_Clk) then
            if (B_rst = '1') then
                a_valid_metastable      <=  '0';
                a_valid_synced          <=  '0';
                wr_port_address_synced_binary   <=  (others => '0');
                b_address               <=  (others => '0');
            else
                a_valid_metastable      <=  a_address(a_address'left);
                a_valid_synced          <=  a_valid_metastable;
                if (b_address(b_address'left)  = '0') and (b_valid_metastable = '0') then
                    b_address           <=  '1' & rd_port_address_binary;
                elsif (b_valid_metastable   = '1') and (b_address(b_address'left)  = '1') then
                    b_address           <=  '0' & rd_port_address_binary;
                end if;
                if (a_valid_synced = '0') and (a_valid_metastable = '1') then
                    wr_port_address_synced_binary   <=  a_address(a_address'left - 1 downto 0);
                end if;
            end if;
        end if;
    end process;

    sync_fifo_gen : if SYNC_g = true generate
        Level:process(Wr_Clk)
        begin
            if rising_edge(Wr_Clk) then
                if (B_rst = '1') then
                    Wr_Level_i <= (others => '0');
                    Rd_Level_i <= (others => '0');
                elsif (Wr_Ena = '1') and (fifo_full = '0') and (rd_en_int = '1') then
                    Wr_Level_i <= Wr_Level_i;
                    Rd_Level_i <= Rd_Level_i;
                elsif (Wr_Ena = '1') and (fifo_full = '0') then
                    Wr_Level_i <= Wr_Level_i + 1;
                    Rd_Level_i <= Rd_Level_i + 1;
                elsif rd_en_int = '1' then
                    Wr_Level_i <= Wr_Level_i - 1;
                    Rd_Level_i <= Rd_Level_i - 1;
                end if;
            end if;
        end process;
    end generate sync_fifo_gen;

    async_fifo_gen : if SYNC_g = false generate
        Rd_Level_diff   <=  wr_port_address_synced_binary - rd_port_address_binary;
        Rd_Level_i      <=  not Rd_Level_diff(Rd_Level_diff'left - 1 downto 0) when (rd_port_address_binary(rd_port_address_binary'left) = '1') and (wr_port_address_synced_binary(wr_port_address_synced_binary'left) = '0') else Rd_Level_diff(Rd_Level_diff'left - 1 downto 0);
        Wr_Level_diff   <=  wr_port_address_binary - rd_port_address_synced_binary;
        Wr_Level_i      <=  not Wr_Level_diff(Wr_Level_diff'left - 1 downto 0) when (rd_port_address_synced_binary(rd_port_address_synced_binary'left) = '1') and (wr_port_address_binary(wr_port_address_binary'left) = '0') else Wr_Level_diff(Wr_Level_diff'left - 1 downto 0);
    end generate async_fifo_gen;

    Wr_Level        <=  Wr_Level_i(Wr_Level'range);
    Rd_Level        <=  Rd_Level_i(Wr_Level'range);
    fifo_full       <=  '1' when (A_Rst = '1') or (Wr_Level_i = DEPTH_g) else '0';
    Full            <=  fifo_full;
    AlmFull         <=  '1' when ((Wr_Level_i >= ALMOST_FULL_LEVEL_g) and (not FWFT_g)) or ((Wr_Level_i > ALMOST_FULL_LEVEL_g) and (FWFT_g)) else '0';
    fifo_empty      <=  '1' when (B_Rst = '1') or (Rd_Level_i = 0) else '0';
    Empty           <=  not reg_is_valid when (FWFT_g) else fifo_empty;
    AlmEmpty        <=  '1' when ((Rd_Level_i <= ALMOST_EMPTY_LEVEL_g) and (not FWFT_g)) or ((Rd_Level_i < ALMOST_EMPTY_LEVEL_g) and (FWFT_g)) else '0';

end architecture;
