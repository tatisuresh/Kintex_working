library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.uart_pkg.all;

entity uart_top is
    generic(
        ENABLE_PARITY           :    std_logic_vector(0 downto 0)    :=  "0";
        MAKE_PARITY_ODD         :    std_logic                       :=  '0';
        BaudRate                :    integer                         :=  115200;      --- bps
        ClockRate               :    integer                         :=  100000000;   --- Hz
        NUMBER_OF_INTERFACES    :    integer                         :=  4;
        BASE_ADDRESS            :    std_logic_vector(31 downto 0)   :=  x"00004200";
        CHIPSCOPE               :    integer                         :=  0
    );
    Port(
        RST                     :     In  std_logic;
        CLK                     :     In  std_logic;
        UART_RX                 :     In  std_logic;
        UART_TX                 :     Out std_logic;
                            
        reg_addr                :     out std_logic_vector(31 downto 0);
        reg_wr_data             :     out std_logic_vector(31 downto 0);
        reg_rd_data             :     in  std_logic_vector(31 downto 0)    :=     (others => '0');
        reg_wr_en               :     out std_logic;
        reg_rd_en               :     out std_logic;
        reg_rd_done             :     in  std_logic :=    '0';
                            
        bulk_write_data         :     out    vector_array(NUMBER_OF_INTERFACES - 1 downto 0);
        bulk_write_en           :     out    std_logic_vector(NUMBER_OF_INTERFACES - 1 downto 0);
        bulk_read_en            :     out    std_logic_vector(NUMBER_OF_INTERFACES - 1 downto 0);
        bulk_read_data          :     in    vector_array(NUMBER_OF_INTERFACES - 1 downto 0);
        bulk_read_data_valid    :     in    std_logic_vector(NUMBER_OF_INTERFACES - 1 downto 0);
        chipscope_control       :     inout std_logic_vector(35 downto 0)
    );
end entity;

Architecture RTL of uart_top is


component chipscope_ila
  PORT (
    CONTROL     : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK         : IN STD_LOGIC;
    TRIG0       : IN STD_LOGIC_VECTOR(255 DOWNTO 0)
    );

end component;

    signal    reg_addr_i           :    std_logic_vector(31 downto 0)    := (others => '0');
    signal    reg_wr_data_i        :    std_logic_vector(31 downto 0)    := (others => '0');
    signal    reg_rd_data_i        :    std_logic_vector(31 downto 0)    := (others => '0');
    signal    reg_wr_en_i          :    std_logic                        := '0';
    signal    reg_rd_en_i          :    std_logic                        := '0';
    signal    reg_rd_done_i        :    std_logic                        := '0';
    signal    reset                :    std_logic                        := '0';
    signal    reset_sh_reg         :    std_logic_vector(9 downto 0)     := (others => '1');
    signal    debug_bus            :    std_logic_vector(255 downto 0)   := (others => '0');

begin
    process (CLK)
    begin 
    if rising_edge (CLK) then 
    reset_sh_reg  <= reset_sh_reg (8 downto 0) & '0' ;
    end if;
    end process ;
   reset   <= RST or reset_sh_reg(7);

    reg_if:Entity work.reg_inf_via_uart
    generic map(
        ENABLE_PARITY              =>    ENABLE_PARITY,
        MAKE_PARITY_ODD            =>    MAKE_PARITY_ODD,
        BaudRate                   =>    BaudRate,
        ClockRate                  =>    ClockRate,
        BASE_ADDRESS               =>    BASE_ADDRESS
    )
    Port map(
        RST                       =>    reset,
        CLK                       =>    CLK,
        UART_RX                   =>    UART_RX,
        UART_TX                   =>    UART_TX,
        reg_addr                  =>    reg_addr_i,
        reg_wr_data               =>    reg_wr_data_i,
        reg_rd_data               =>    reg_rd_data_i,
        reg_wr_en                 =>    reg_wr_en_i,
        reg_rd_en                 =>    reg_rd_en_i,
        reg_rd_done               =>    reg_rd_done_i,
        debug_bus                 =>    debug_bus
    );

    process(clk)
    begin
        if (rising_edge(clk)) then
            for i in 0 to NUMBER_OF_INTERFACES - 1 loop
                if (reg_addr_i = BASE_ADDRESS + 4*i) then
                    bulk_write_data(i)        <=    reg_wr_data_i;
                    bulk_write_en(i)          <=    reg_wr_en_i;
                    bulk_read_en(i)           <=    reg_rd_en_i;
                    reg_rd_data_i             <=    bulk_read_data(i);
                    reg_rd_done_i             <=    bulk_read_data_valid(i);
                elsif (reg_addr_i(31 downto 16) = x"0000") and (reg_addr_i(15 downto 12) /= BASE_ADDRESS(15 downto 12)) then 
                    bulk_write_data(i)        <=    (others => '0');
                    bulk_write_en(i)          <=    '0';
                    bulk_read_en(i)           <=    '0';
                    reg_rd_data_i             <=    reg_rd_data;
                    reg_rd_done_i             <=    reg_rd_done;
                    reg_wr_data               <=    reg_wr_data_i;
                    reg_wr_en                 <=    reg_wr_en_i;
                    reg_rd_en                 <=    reg_rd_en_i;
                end if;
            end loop;
        end if;
    end process;

    reg_addr <= reg_addr_i;


--CHIPSCOPE_inst : if CHIPSCOPE = 1 generate
--  chipscope_ila_inst : chipscope_ila
--    port map(
--      CONTROL         => chipscope_control,
--      CLK             => clk,
--      TRIG0           => debug_bus
--    );
--end generate;
    
end Architecture;
