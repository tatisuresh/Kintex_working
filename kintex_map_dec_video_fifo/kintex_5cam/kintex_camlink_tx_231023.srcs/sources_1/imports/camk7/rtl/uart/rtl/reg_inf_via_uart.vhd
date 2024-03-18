library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


Entity reg_inf_via_uart is
    generic(
        ENABLE_PARITY    : std_logic_vector(0 downto 0)  :=  "0";
        MAKE_PARITY_ODD  : std_logic                     :=  '0';
        BaudRate         : integer                       :=  115200;      --- bps
        ClockRate        : integer                       :=  100000000;    --- Hz
        BASE_ADDRESS     : std_logic_vector(31 downto 0) :=  x"0000f000"
    );
    Port(
        RST              :     In      std_logic;
        CLK              :     In      std_logic;
        UART_RX          :     In      std_logic;
        UART_TX          :     Out     std_logic;
        reg_addr         :     out     std_logic_vector(31 downto 0);
        reg_wr_data      :     out     std_logic_vector(31 downto 0);
        reg_rd_data      :     in      std_logic_vector(31 downto 0)    :=     (others => '0');
        reg_wr_en        :     out     std_logic;
        reg_rd_en        :     out     std_logic;
        reg_rd_done      :     in      std_logic                        :=    '0';
        debug_bus        :     out     std_logic_vector(255 downto 0)   :=    (others => '0')
    );
end reg_inf_via_uart;

-- ----------------------------------------------------
Architecture RTL of reg_inf_via_uart is

    component uart_controller
    generic(
        ENABLE_PARITY    :    std_logic_vector(0 downto 0);
        MAKE_PARITY_ODD  : std_logic    :=    '0';
        BaudRate         :    integer;
        ClockRate        :    integer
    );
    Port(
        RST              :    In     std_logic;
        CLK              :    In     std_logic;
        Dout             :    Out    std_logic_vector( 7 downto 0);
        DoutValid        :    Out    std_logic;
        RX               :    In     std_logic;
        DinValid         :    In     std_logic;
        TxBusy           :    Out    std_logic;
        Din              :    In     std_logic_vector( 7 downto 0);
        TX               :    Out    std_logic;
        debug_bus_u      :    Out    std_logic_vector(20 downto 0)
    );
    end component;

    constant IDLE                          :    std_logic_vector(  4 downto 0) := "00000";
    constant REQ_MAGIC_WORD1               :    std_logic_vector(  4 downto 0) := "00001";
    constant REQ_MAGIC_WORD2               :    std_logic_vector(  4 downto 0) := "00010";
    constant REQ_LENGTH_WORD1              :    std_logic_vector(  4 downto 0) := "00011";
    constant REQ_LENGTH_WORD2              :    std_logic_vector(  4 downto 0) := "00100";
    constant REQ_CMD_VALUE_WORD1           :    std_logic_vector(  4 downto 0) := "00101";
    constant REQ_CMD_VALUE_WORD2           :    std_logic_vector(  4 downto 0) := "00110";
    constant REQ_CMD_VALUE_WORD3           :    std_logic_vector(  4 downto 0) := "00111";
    constant REQ_CMD_VALUE_WORD4           :    std_logic_vector(  4 downto 0) := "01000";
    constant REQ_ADDR_WORD1                :    std_logic_vector(  4 downto 0) := "01001";
    constant REQ_ADDR_WORD2                :    std_logic_vector(  4 downto 0) := "01010";
    constant REQ_ADDR_WORD3                :    std_logic_vector(  4 downto 0) := "01011";
    constant REQ_ADDR_WORD4                :    std_logic_vector(  4 downto 0) := "01100";
    constant REQ_DATA                      :    std_logic_vector(  4 downto 0) := "01101";
    constant RSP_MAGIC_WORD1               :    std_logic_vector(  4 downto 0) := "01110";
    constant RSP_MAGIC_WORD2               :    std_logic_vector(  4 downto 0) := "01111";
    constant RSP_LENGTH_WORD1              :    std_logic_vector(  4 downto 0) := "10000";
    constant RSP_LENGTH_WORD2              :    std_logic_vector(  4 downto 0) := "10001";
    constant RSP_CMD_VALUE_WORD1           :    std_logic_vector(  4 downto 0) := "10010";
    constant RSP_CMD_VALUE_WORD2           :    std_logic_vector(  4 downto 0) := "10011";
    constant RSP_CMD_VALUE_WORD3           :    std_logic_vector(  4 downto 0) := "10100";
    constant RSP_CMD_VALUE_WORD4           :    std_logic_vector(  4 downto 0) := "10101";
    constant RSP_STATUS_WORD1              :    std_logic_vector(  4 downto 0) := "10110";
    constant RSP_STATUS_WORD2              :    std_logic_vector(  4 downto 0) := "10111";
    constant RSP_STATUS_WORD3              :    std_logic_vector(  4 downto 0) := "11000";
    constant RSP_STATUS_WORD4              :    std_logic_vector(  4 downto 0) := "11001";
    constant RSP_DATA                      :    std_logic_vector(  4 downto 0) := "11010";
    constant WAIT_FOR_ONE_CLK_CYCLE        :    std_logic_vector(  4 downto 0) := "11011";

    signal Dout                            :    std_logic_vector(  7 downto 0) := (others => '0');
    signal DoutValid                       :    std_logic := '0';
    signal Din                             :    std_logic_vector(  7 downto 0) := (others => '0');
    signal DinValid                        :    std_logic := '0';
    signal TxBusy                          :    std_logic := '0';
    signal req_cmd_packet_length           :    std_logic_vector( 15 downto 0) := (others => '0');
    signal rsp_cmd_pkt_length              :    std_logic_vector( 15 downto 0) := (others => '0');
    signal req_cmd_value                   :    std_logic_vector( 31 downto 0) := (others => '0');
    signal rsp_cmd_value                   :    std_logic_vector( 31 downto 0) := (others => '0');
    signal req_cmd_addr                    :    std_logic_vector( 31 downto 0) := (others => '0');
    signal req_cmd_data                    :    std_logic_vector(  7 downto 0) := (others => '0');
    signal rsp_cmd_data                    :    std_logic_vector(  7 downto 0) := (others => '0');
    signal req_cmd_data_valid              :    std_logic := '0';
    signal length_counter                  :    std_logic_vector( 15 downto 0) := (others => '0');
    signal length_counter_R                :    std_logic_vector( 15 downto 0) := (others => '0');
    signal CS                              :    std_logic_vector(  4 downto 0) := (others => '0');
    signal CS_R                            :    std_logic_vector(  4 downto 0) := (others => '0');
    signal CS_d                            :    std_logic_vector(  4 downto 0) := (others => '0');
    signal CS_R_d                          :    std_logic_vector(  4 downto 0) := (others => '0');
    signal req_cmd_rcvd                    :    std_logic := '0';
    signal req_cmd_rcvd_d                  :    std_logic := '0';
    signal req_cmd_rcvd_2d                 :    std_logic := '0';
    signal reg_rd_data_d                   :    std_logic_vector( 31 downto 0) := (others => '0');
    signal req_32_bit_data                 :    std_logic_vector( 31 downto 0) := (others => '0');
    signal byte_swap_32                    :    std_logic_vector( 31 downto 0) := (others => '0');
    signal debug_bus_u                     :    std_logic_vector( 20 downto 0)  := (others => '0');
    signal zeros                           :    std_logic_vector(255 downto 0) := (others => '0');
    signal Timer_cnt                       :    std_logic_vector( 31 downto 0) := (others => '0');
    signal Timer_cnt_RSP                   :    std_logic_vector( 31 downto 0) := (others => '0');
    signal word_cnt                        :    std_logic_vector(  1 downto 0) := (others => '0');
    signal word_cnt_rd                     :    std_logic_vector(  1 downto 0) := (others => '0');
    signal req_32_bit_valid                :    std_logic := '0';
    signal read_byte_ack_int               :    std_logic := '0';
    signal read_word_ack_int               :    std_logic := '0';
    signal reg_rd_en_int                   :    std_logic := '0';
    signal reg_wr_en_int                   :    std_logic := '0';
    signal read_command                    :    std_logic := '0';
    signal write_command                   :    std_logic := '0';
    signal response_pending                :    std_logic := '0';

begin

    uart_inst : uart_controller
    Generic map(
        ENABLE_PARITY     =>    ENABLE_PARITY,
        MAKE_PARITY_ODD   =>    MAKE_PARITY_ODD,
        BaudRate          =>    BaudRate,
        ClockRate         =>    ClockRate
    )
    Port Map (
        RST               =>    RST,
        CLK               =>    CLK,
        Dout              =>    Dout,
        DoutValid         =>    DoutValid,
        RX                =>    UART_RX,
        Din               =>    Din,
        DinValid          =>    DinValid,
        TxBusy            =>    TxBusy,
        TX                =>    UART_TX,
        debug_bus_u       =>    debug_bus_u
    );

    REQ_FSM: process (RST, CLK)
    begin
        if RST='1' then
            CS                          <=     IDLE;
            length_counter              <=     (others => '0');
            Timer_cnt                   <=     (others => '0');
            req_cmd_rcvd_d              <=     '0';
        elsif rising_edge(CLK) then     
            req_cmd_data_valid          <=     '0';
            req_cmd_rcvd_d              <=     req_cmd_rcvd;
            req_cmd_rcvd                <=     '0';
            CS_d                        <=     CS;
            if (CS_d /= CS) then        
                Timer_cnt               <=     (others => '0');
            else                        
                Timer_cnt               <=     Timer_cnt + 1;
            end if;
            if Timer_cnt = x"FFFFFFFF" then
                CS                      <=     IDLE;
            elsif (DoutValid='1') then
                CS                      <=     IDLE;
                case CS is
                when IDLE =>
                    if Dout = x"cc" then
                        CS              <=     REQ_MAGIC_WORD1;
                    end if;
                    req_cmd_value <= (others => '0');
                when REQ_MAGIC_WORD1 =>
                    if Dout = x"77" then
                        CS              <=     REQ_MAGIC_WORD2;
                    end if;
                when REQ_MAGIC_WORD2 =>
                        CS              <=     REQ_LENGTH_WORD1;
                    req_cmd_packet_length(15 downto 8) <= Dout;
                    req_cmd_data        <=     Dout;
                    req_cmd_data_valid  <=     '1';
                when REQ_LENGTH_WORD1 =>
                    CS                  <=     REQ_LENGTH_WORD2;
                    req_cmd_packet_length(7 downto 0) <= Dout;
                    req_cmd_data        <=     Dout - 12;
                    req_cmd_data_valid  <=     '1';
                when REQ_LENGTH_WORD2 =>
                    CS                  <=     REQ_CMD_VALUE_WORD1;
                    req_cmd_value(7 downto 0) <= Dout;
                when REQ_CMD_VALUE_WORD1 =>
                    CS                  <=     REQ_CMD_VALUE_WORD2;
                    req_cmd_value(15 downto 8) <= Dout;
                when REQ_CMD_VALUE_WORD2 =>
                    CS                  <=     REQ_CMD_VALUE_WORD3;
                    req_cmd_value(23 downto 16) <= Dout;
                when REQ_CMD_VALUE_WORD3 =>
                    CS                  <=     REQ_CMD_VALUE_WORD4;
                    req_cmd_value(31 downto 24) <= Dout;
                when REQ_CMD_VALUE_WORD4 =>
                    CS                  <=     REQ_ADDR_WORD1;
                    req_cmd_addr(31 downto 24) <= Dout;
                when REQ_ADDR_WORD1 =>
                    CS                  <=     REQ_ADDR_WORD2;
                    req_cmd_addr(23 downto 16) <= Dout;
                when REQ_ADDR_WORD2 =>
                    CS                  <=     REQ_ADDR_WORD3;
                    req_cmd_addr(15 downto 8) <= Dout;
                when REQ_ADDR_WORD3 =>
                    CS                  <=     REQ_ADDR_WORD4;
                    req_cmd_addr(7 downto 0) <= Dout;
                when REQ_ADDR_WORD4 =>
                    CS                  <=     REQ_DATA;
                    if (req_cmd_packet_length >= 16) and (write_command = '1') then
                        length_counter  <=     req_cmd_packet_length - 13;
                    elsif (req_cmd_packet_length >= 16) and (read_command = '1')then
                        length_counter  <=     x"0003";
                    else
                        length_counter  <=     (others => '0');
                        CS              <=     IDLE;
                    end if;
                    if write_command = '1' then
                        req_cmd_data         <=     Dout;
                        req_cmd_data_valid   <=     '1';
                    end if;    
                when REQ_DATA =>
                    Timer_cnt           <=     (others => '0');
                    CS                  <=     REQ_DATA;
                    if write_command = '1' then
                        req_cmd_data         <=     Dout;
                        req_cmd_data_valid   <=     '1';
                    end if;
                    length_counter      <=     length_counter - 1;
                    if length_counter = 1 then
                        CS              <=     IDLE;
                        req_cmd_rcvd    <=     '1';
                    end if;
                when others =>
                    CS                  <=     IDLE;
                end case;
            end if;
        end if;
    end process;
    
    RSP_FSM: process (RST, CLK)
    begin
        if RST='1' then
            CS_R                        <=     IDLE;
            CS_R_d                      <=     IDLE;
            Timer_cnt_RSP               <=     (others => '0');
            read_byte_ack_int           <=    '0';
            response_pending            <=    '0';
            reg_rd_en_int               <=    '0';
        elsif rising_edge(CLK) then
            reg_rd_en_int               <=    '0';
            DinValid                    <=     '0';
            read_byte_ack_int           <=     '0';
            CS_R_d                      <=     CS_R;
            if (reg_rd_done = '1') then
                response_pending        <=    '0';
            end if;
            if (CS_R_d /= CS_R) then
                Timer_cnt_RSP           <=     (others => '0');
            else
                Timer_cnt_RSP           <=     Timer_cnt_RSP + 1;
            end if;
            if Timer_cnt_RSP = x"FFFFFFFF" then
                CS_R                    <=     IDLE;
            elsif (TxBusy = '0') and (response_pending = '0') and (DinValid = '0') then
                CS_R                    <=    IDLE;
                case CS_R is
                when IDLE =>
                    if (req_cmd_rcvd_d = '1') and (((write_command = '1') and (req_cmd_addr(31 downto 16) = x"0000") and (req_cmd_addr(15 downto 12) /= BASE_ADDRESS(15 downto 12))) or (read_command = '1')) then
                        CS_R            <=     RSP_MAGIC_WORD1;
                        Din             <=     x"aa";
                        DinValid        <=     '1';
                        length_counter_R<=     rsp_cmd_pkt_length - 12;
                    end if;
                when RSP_MAGIC_WORD1 =>
                        CS_R            <=     RSP_MAGIC_WORD2;
                        Din             <=     x"88";
                        DinValid        <=     '1';
                when RSP_MAGIC_WORD2 =>
                        CS_R            <=     RSP_LENGTH_WORD1;
                        Din             <=     rsp_cmd_pkt_length(15 downto 8);
                        DinValid        <=     '1';
                when RSP_LENGTH_WORD1 =>
                        CS_R            <=     RSP_LENGTH_WORD2;
                        Din             <=     rsp_cmd_pkt_length(7 downto 0);
                        DinValid        <=     '1';
                when RSP_LENGTH_WORD2 =>
                        CS_R            <=    RSP_CMD_VALUE_WORD1;
                        Din             <=    rsp_cmd_value(31 downto 24);
                        DinValid        <=    '1';
                when RSP_CMD_VALUE_WORD1 =>
                        CS_R            <=    RSP_CMD_VALUE_WORD2;
                        Din             <=    rsp_cmd_value(23 downto 16);
                        DinValid        <=    '1';
                when RSP_CMD_VALUE_WORD2 =>
                        CS_R            <=    RSP_CMD_VALUE_WORD3;
                        Din             <=    rsp_cmd_value(15 downto 8);
                        DinValid        <=    '1';
                when RSP_CMD_VALUE_WORD3 =>
                        CS_R            <=    RSP_CMD_VALUE_WORD4;
                        Din             <=    rsp_cmd_value(7 downto 0);
                        DinValid        <=    '1';
                when RSP_CMD_VALUE_WORD4 =>
                        CS_R            <=    RSP_STATUS_WORD1;
                        Din             <=    x"00";
                        DinValid        <=    '1';
                when RSP_STATUS_WORD1 =>
                        CS_R            <=     RSP_STATUS_WORD2;
                        Din             <=    x"00";
                        DinValid        <=     '1';
                when RSP_STATUS_WORD2 =>
                        CS_R            <=    RSP_STATUS_WORD3;
                        Din             <=    x"00";
                        DinValid        <=    '1';
                when RSP_STATUS_WORD3 =>
                        CS_R            <=    RSP_STATUS_WORD4;
                        Din             <=    x"00";
                        DinValid        <=    '1';
                    if read_command = '1' then
                        reg_rd_en_int    <=    '1';
                        response_pending <=    '1';
                    end if;
                when RSP_STATUS_WORD4 =>
                    CS_R                <=    RSP_DATA;
                    Din                 <=    rsp_cmd_data;
                    DinValid            <=    '1';
                    length_counter_R    <=    length_counter_R - 1;
                when RSP_DATA =>
                    if length_counter_R /= 0 then
                        Timer_cnt_RSP     <=    (others => '0');
                        CS_R              <=    RSP_DATA;
                        Din               <=    rsp_cmd_data;
                        DinValid          <=    '1';
                        length_counter_R  <=    length_counter_R - 1;
                        if (length_counter_R(1 downto 0) = "01") and (length_counter_R(15 downto 2) /= 0) then
                            reg_rd_en_int    <=    '1';
                            response_pending <=    '1';
                        end if;
                    else
                        CS_R                 <=    IDLE;
                    end if;
                when others =>
                        CS_R                 <=    IDLE;
                end case;
            end if;
        end if;
    end process;

    word_wr_valid:process (RST,CLK)
    begin
        if (RST = '1') then
            word_cnt                     <=     (others => '0');
            req_32_bit_valid             <=     '0';
            byte_swap_32                 <=     (others =>'0');
        elsif rising_edge(CLK) then
            req_32_bit_valid             <=     '0';
            if (reg_rd_done = '1') then
                reg_rd_data_d           <=  reg_rd_data;
            end if;
            if req_cmd_data_valid = '1' then
                req_32_bit_data         <=     req_32_bit_data(23 downto 0) & req_cmd_data;
                byte_swap_32            <=     req_cmd_data & byte_swap_32(31 downto 8);
                if write_command = '1' then
                    word_cnt                <=     word_cnt + 1;
                end if;    
                if word_cnt = "11" then
                    req_32_bit_valid        <=     '1';
                end if;
            end if;
        end if;
    end process;

    read_command      	<=  '1' when (req_cmd_value = x"00000200") else '0';
    write_command     	<=  '1' when (req_cmd_value = x"00000100") else '0';
    rsp_cmd_pkt_length	<=  req_32_bit_data(15 downto 0) + 12 when (read_command = '1') else x"0010";
    rsp_cmd_value     	<=  req_cmd_value;

    rsp_cmd_data        <=  reg_rd_data_d( 7 downto  0) when length_counter_R(1 downto 0) = "01" else
							reg_rd_data_d(15 downto  8) when length_counter_R(1 downto 0) = "10" else
							reg_rd_data_d(23 downto 16) when length_counter_R(1 downto 0) = "11" else
							reg_rd_data_d(31 downto 24) when length_counter_R(1 downto 0) = "00" else x"00";

    ------------Register write
    reg_wr_en_int        <=    req_cmd_rcvd_d or req_32_bit_valid  when write_command = '1' else '0';

    reg_rd_en            <=    reg_rd_en_int;
    reg_addr             <=    req_cmd_addr;
    reg_wr_data          <=    req_32_bit_data;
    reg_wr_en            <=    reg_wr_en_int;

    debug_bus            <=    zeros(192 downto 0) &   --255:63
                        debug_bus_u &                  --62:42
                        RST &                          --41
                        UART_RX &                      --40
                        CS &                           --39:35
                        length_counter &               --34:19
                        TxBusy &                       --18
                        DinValid &                     --17
                        Din &                          --16:9
                        DoutValid &                    --8
                        Dout;                          --7:0

end rtl;