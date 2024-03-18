library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


Entity uart_controller is
    generic(
        ENABLE_PARITY      : std_logic_vector(0 downto 0)  :=  "0";
        MAKE_PARITY_ODD    : std_logic                     :=  '0';        -- would need ENABLE_PARITY = "1"
        BaudRate           : integer                       :=  115200;     -- (bps) possible values 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600              
        ClockRate          : integer                       :=  100000000   -- (Hz)
    );
    Port(
        rst                : in  std_logic;
        clk                : in  std_logic;
        dout               : out std_logic_vector (7 downto 0);
        doutvalid          : out std_logic;
        overflow           : out std_logic;
        parity_err         : out std_logic;
        rx                 : in  std_logic;
        din                : in  std_logic_vector (7 downto 0);
        dinvalid           : in  std_logic;
        txbusy             : out std_logic;
        tx                 : out std_logic;
        debug_bus_u        : out std_logic_vector(20 downto 0)
    );
end uart_controller;
-- ----------------------------------------------------
Architecture RTL of uart_controller is

    constant TX_IDLE          : std_logic_vector( 1 downto 0) := "00";
    constant LOAD_TX          : std_logic_vector( 1 downto 0) := "01";
    constant SHIFT_TX         : std_logic_vector( 1 downto 0) := "10";
    constant STOP_TX          : std_logic_vector( 1 downto 0) := "11";
    
    constant RX_IDLE          : std_logic_vector( 2 downto 0) := "000";
    constant START_RX         : std_logic_vector( 2 downto 0) := "001";
    constant EDGE_RX          : std_logic_vector( 2 downto 0) := "010";
    constant SHIFT_RX         : std_logic_vector( 2 downto 0) := "011";
    constant STOP_RX          : std_logic_vector( 2 downto 0) := "100";
    constant RX_OVF           : std_logic_vector( 2 downto 0) := "101";
    
    signal Divisor             : std_logic_vector(10 downto 0) := (others => '0');
    signal Top16_tx            : std_logic := '0';
    signal Top16_rx            : std_logic := '0';
    signal Div16_tx            : std_logic_vector(10 downto 0) := (others => '0');
    signal Div16_rx            : std_logic_vector(10 downto 0) := (others => '0');
    signal TopTx               : std_logic := '0';
    signal ClkDiv              : std_logic_vector( 7 downto 0) := (others => '0');
    signal Divi_Rx             : std_logic_vector( 7 downto 0) := (others => '0');
    signal Divi_Tx             : std_logic_vector( 7 downto 0) := (others => '0');
    signal TopRx               : std_logic := '0';
    signal RxDiv               : std_logic_vector( 7 downto 0) := (others => '0');
    signal Tx_Reg              : std_logic_vector( 9 downto 0) := (others => '0');
    signal TxBitCnt            : std_logic_vector( 3 downto 0) := (others => '0');
    signal RegDin              : std_logic_vector( 7 downto 0) := (others => '0');
    signal TxFSM               : std_logic_vector( 1 downto 0) := TX_IDLE;
    
    signal Rx_Reg              : std_logic_vector( 7 downto 0) := (others => '0');
    signal RxBitCnt            : std_logic_vector( 3 downto 0) := (others => '0');
    signal RxFSM               : std_logic_vector( 2 downto 0) := RX_IDLE;
    signal RX_d                : std_logic := '1';
    signal RX_2d               : std_logic := '1';
    signal RX_3d               : std_logic := '1';
    signal RxRdyi              : std_logic := '0';
    signal ClrDiv              : std_logic := '0';
    signal RxErr               : std_logic := '0';
    signal parity              : std_logic := '0';
    signal Rx_Parity           : std_logic := '0';
    signal Calc_Parity         : std_logic := '0';
    signal RxFSM_d             : std_logic_vector( 2 downto 0) := RX_IDLE;
    signal enable_div16_rx     : std_logic := '0';

begin

    rx_sample:process (CLK,RST)
    begin
        if RST = '1' then
            RX_d    <= '1';
            RX_2d   <= '1';
            RX_3d   <= '1';
        elsif (CLK'event and CLK = '1') then
            RX_d    <= RX;
            RX_2d   <= RX_d;
            RX_3d   <= RX_2d;
        end if;
    end process;
    
    -- --------------------------
    -- Baud rate selection
    -- --------------------------
    Divi_Tx     <=  "00001001";     --9 (10 - 1) counting from 0
    Divi_Rx     <=  "00000100";     --4 ( 5 - 1) counting from 0
    Divisor     <=  std_logic_vector(to_unsigned((ClockRate/(10*BaudRate) - 1), 11));
    
    -- --------------------------
    -- Clk16 Clock Generation
    -- --------------------------
    clk16_gen_rx:process (RST, CLK)
    begin
        if RST='1' then
            enable_div16_rx      <=     '0';
            Top16_rx             <=     '0';
            Div16_rx             <=     (others => '0');
        elsif rising_edge(CLK) then
            Top16_rx             <=     '0';
            if Rx_3d = '1' and Rx_2d = '0' and RxFSM = 0 then
                enable_div16_rx <= '1';
            elsif RxFSM = 0 and RxFSM_d /= 0 then
                enable_div16_rx <= '0';
            end if;
            
            if enable_div16_rx =  '1' then
                if Div16_rx = Divisor then
                    Div16_rx     <= (others => '0');
                    Top16_rx     <= '1';
                else
                    Div16_rx     <= Div16_rx + 1;
                end if;
            else
                Div16_rx         <= Divisor - 1;
            end if;    
        end if;
    end process;
    
    clk16_gen_tx:process (RST, CLK)
    begin
        if RST='1' then
            Top16_tx         <=     '0';
            Div16_tx         <=     (others => '0');
        elsif rising_edge(CLK) then
            Top16_tx         <=     '0';
            if Div16_tx = Divisor then
                Div16_tx     <=     (others => '0');
                Top16_tx     <=     '1';
            else
                Div16_tx     <=     Div16_tx + 1;
            end if;
        end if;
    end process;
    
    -- --------------------------
    -- Tx Clock Generation
    -- --------------------------
    clk_gen_tx:process (RST, CLK)
    begin
        if RST='1' then
            TopTx              <=     '0';
            ClkDiv             <=     (others=>'0');
        elsif rising_edge(CLK) then
            TopTx              <=     '0';
            if Top16_tx='1' then
            ClkDiv             <=     ClkDiv + 1;
                if ClkDiv = Divi_Tx then
                    TopTx      <=     '1';
                    ClkDiv     <=     (others=>'0');
                end if;
            end if;
        end if;
    end process;

    -- ------------------------------
    -- Rx Sampling Clock Generation
    -- ------------------------------
    clk_gen_rx:process (RST, CLK)
    begin
        if RST='1' then
            TopRx             <=     '0';
            RxDiv             <=     (others => '0');
        elsif rising_edge(CLK) then
            TopRx             <=     '0';
            if ClrDiv='1' then
                RxDiv         <=     (others => '0');
            elsif Top16_rx='1' then
                if RxDiv = Divi_Rx then
                    RxDiv     <=     (others => '0');
                    TopRx     <=     '1';
                else
                    RxDiv     <=     RxDiv + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- --------------------------
    -- Transmit State Machine
    -- --------------------------
    TX            <=     Tx_Reg(0);
    parity        <=    MAKE_PARITY_ODD xor (Din(0) xor Din(1) xor Din(2) xor Din(3) xor Din(4) xor Din(5) xor Din(6) xor Din(7)) when ENABLE_PARITY = "1" else '1';
    
    Tx_FSM: process (RST, CLK)
    begin
        if RST='1' then
            Tx_Reg                     <=    (others => '1');
            TxBitCnt                   <=    (others => '0');
            TxFSM                      <=    TX_IDLE;
            TxBusy                     <=    '0';
            RegDin                     <=    (others=>'0');
        elsif rising_edge(CLK) then
            TxBusy                     <=    '1'; -- except when explicitly '0'
            case TxFSM is
            when TX_IDLE =>
                if DinValid='1' then
                    -- latch the input data immediately.
                    RegDin             <=    Din;
                    TxBusy             <=    '1';
                    TxFSM              <=    LOAD_TX;
                else
                    TxBusy             <=    '0';
                end if;
            when LOAD_TX =>
                if TopTx='1' then
                    TxFSM              <=     SHIFT_TX;
                    TxBitCnt           <=     x"9" + ENABLE_PARITY; -- start + data
                    Tx_reg             <=     parity & RegDin & '0';
                end if;
            when SHIFT_TX =>
                if TopTx='1' then
                    TxBitCnt           <=     TxBitCnt - 1;
                    Tx_reg             <=     '1' & Tx_reg (Tx_reg'high downto 1);
                    if TxBitCnt=1 then
                        TxFSM          <=     STOP_TX;
                    end if;
                end if;
            when STOP_TX =>
                if TopTx='1' then
                    TxFSM              <=     TX_IDLE;
                end if;
            when others =>
                TxFSM                  <=     TX_IDLE;
            end case;
        end if;
    end process;

    -- ------------------------
    -- RECEIVE State Machine
    -- ------------------------
    Calc_Parity        <=    MAKE_PARITY_ODD xor (Rx_Reg(0) xor Rx_Reg(1) xor Rx_Reg(2) xor Rx_Reg(3) xor Rx_Reg(4) xor Rx_Reg(5) xor Rx_Reg(6) xor Rx_Reg(7)) when ENABLE_PARITY = "1" else '0';
    
    Rx_FSM: process (RST, CLK)
    begin
        if RST='1' then
            Rx_Reg                 <=    (others => '0');
            Dout                   <=    (others => '0');
            RxBitCnt               <=    (others => '0');
            RxFSM                  <=    RX_IDLE;
            RxRdyi                 <=    '0';
            ClrDiv                 <=    '0';
            RxErr                  <=    '0';
            Rx_Parity              <=    '0';
        elsif rising_edge(CLK) then
            RxFSM_d                <=    RxFSM;
            ClrDiv                 <=    '0'; -- default value
            -- reset error when a word has been received Ok:
            if RxRdyi='1' then
                RxErr              <=    '0';
                RxRdyi             <=    '0';
            end if;
            case RxFSM is
            when RX_IDLE => -- wait on start bit
                RxBitCnt          <=    (others => '0');
                if Top16_rx='1' then
                    if RX_2d='0' then
                        RxFSM     <=     START_RX;
                        ClrDiv    <=    '1'; -- Synchronize the divisor
                    end if; -- else false start, stay in Idle
                end if;
            when START_RX => -- wait on first data bit
                if TopRx = '1' and ClrDiv = '0' then
                    if RX_2d='1' then -- framing error
                        RxFSM     <=     RX_OVF;
                        report "Start bit error." severity note;
                    else
                        RxFSM     <=     EDGE_RX;
                    end if;
                end if;
            when EDGE_RX => -- should be near Rx edge
                if TopRx = '1' and ClrDiv = '0' then
                    RxFSM         <=     SHIFT_RX;
                    if (RxBitCnt = ("1000" or ("000" & ENABLE_PARITY))) then
                        RxFSM     <=     STOP_RX;
                    else
                        RxFSM     <=     SHIFT_RX;
                    end if;
                end if;
            when SHIFT_RX => -- Sample data !
                if TopRx = '1' and ClrDiv = '0' then
                    RxBitCnt      <=     RxBitCnt + 1;
                    -- shift right :
                    if (RxBitCnt(3) = '0') then
                        Rx_Reg    <=     RX_2d & Rx_Reg (7 downto 1);
                    else
                        Rx_Parity <=    RX_2d;
                    end if;
                    RxFSM         <=     EDGE_RX;
                end if;
            when STOP_RX => -- during Stop bit
                if TopRx = '1' and ClrDiv = '0' then
                    Dout          <=     Rx_reg;
                    RxRdyi        <=    '1';
                    RxFSM         <=     RX_IDLE;
                end if;
            when RX_OVF => -- Overflow / Error
                RxErr             <=     '1';
                if RX_2d='1' then
                    RxFSM         <=     RX_IDLE;
                end if;
            when Others =>
                RxFSM             <=     RX_IDLE;
            end case;
        end if;
    end process;
    
    overflow        <=  RxErr;
    parity_err      <=  RxRdyi when Rx_Parity /= Calc_Parity else '0';
                        
    DoutValid       <=  RxRdyi;
    
    debug_bus_u     <=  RxBitCnt &      --20:17
                        Rx_Reg      &      --16:9
                        TopRx      &      --8
                        RX_2d      &      --7
                        Top16_rx &      --6
                        RxRdyi   &      --5
                        ClrDiv   &      --4
                        RxErr      &      --3
                        RxFSM;          --2:0
    
end rtl;