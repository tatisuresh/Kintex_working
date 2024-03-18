--*****************************************************************************
--  ______________
-- |              |
-- |    ^         |  Vendor             : Logic Fruit
-- |   / \        |  Version            : 1.0
-- |  /   \      _|  Application        : Project
-- |-/     \    / |  Filename           : bar_pattern_source.vhd
-- |        \  /  |  Date Last Modified : $Date: 2014/04/08 11:00:45 $
-- |         \/   |  Date Created       : Wed July 09 2014
-- |______________|
--
-- Device           : 7 Series
-- Design Name      : VSS
-- Purpose          :
-- Reference        :
-- Revision History :
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity bar_pattern_source is
    generic(
        RGB_YCbCr           : integer     := 0;           -- Selects RGB -> 0  :  YCbCr -> 1.
        FFF_FTT             : integer     := 0;           -- YCbCr_4:4:4 -> 0 : YCbCr_4:2:2 -> 1.
        PIXEL_DEPTH         : integer     := 8;            -- Selects 8  or 10
        HSYNC_ACTIVE        : natural     := 640
    );
    port(
        clk                 :  in  std_logic;
        rst                 :  in  std_logic;
        -- input timing signals
        hsync_in            :  in  std_logic;
        vsync_in            :  in  std_logic;
        data_en             :  in  std_logic;
        -- output data signals
        hsync_out           :  out std_logic;
        vsync_out           :  out std_logic;
        data_out_valid      :  out std_logic;
        data_out            :  out std_logic_vector(3*PIXEL_DEPTH - 1 downto 0) -- data in RGB format(msb to lsb)
    );
END entity;

ARCHITECTURE rtl OF bar_pattern_source IS



    signal  hsync_int                   :  std_logic                                    :=  '1';
    signal  vsync_int                   :  std_logic                                    :=  '1';
    signal  hsync_int_1d                :  std_logic                                    :=  '1';
    signal  vsync_int_1d                :  std_logic                                    :=  '1';
    signal  count                       :  integer range 0 to 4095                      :=   0;
    signal  data_int                    :  std_logic_vector(3*PIXEL_DEPTH - 1 downto 0) :=  (others => '0');
    signal  data_valid_int              :  std_logic                                    :=  '0';
    signal  data_valid_int_1d           :  std_logic                                    :=  '0';
    signal  pattern_zeros               :  std_logic_vector(PIXEL_DEPTH - 1 downto 0)   :=  (others => '0');
    signal  pattern_ones                :  std_logic_vector(PIXEL_DEPTH - 1 downto 0)   :=  (others => '1');
    signal  pattern_all_ones_minus_one  :  std_logic_vector(PIXEL_DEPTH - 1 downto 0)   := (0 => '0',others => '1');
    signal  pattern_msb_bit_one         :  std_logic_vector(PIXEL_DEPTH - 1 downto 0)   := (others => '1');
    signal  pattern_first_one_other_zero:  std_logic_vector(PIXEL_DEPTH - 1 downto 0)   := (1 => '1',others => '0');

BEGIN
    pattern_msb_bit_one       <= ('0' & pattern_all_ones_minus_one(PIXEL_DEPTH - 2 downto 0)) + pattern_first_one_other_zero;
    -- process to delay inputs for synchronization
    delay:process(clk,rst)
    begin
        if rst = '1' then
            hsync_int         <=  '0';
            vsync_int         <=  '0';
            hsync_int_1d      <=  '0';
            vsync_int_1d      <=  '0';
            data_valid_int    <=  '0';
            data_valid_int_1d <=  '0';
        elsif rising_edge(clk) then
            hsync_int         <=  hsync_in;
            vsync_int         <=  vsync_in;
            hsync_int_1d      <=  hsync_int;
            vsync_int_1d      <=  vsync_int;
            data_valid_int    <=  data_en;
            data_valid_int_1d <=  data_valid_int;
            data_out          <=  data_int;
        end if;
    end process;

    -- process to assign different colour values to generate colour pattern
    video_gen:process(clk,rst)
    begin
        if rst = '1' then
            count       <=  0;
            data_int    <=  (others => '0');
        elsif rising_edge(clk) then

            if data_en = '1' then
                count       <=  count + 1;
            elsif data_valid_int = '0' then
                count       <= 0;
            end if;

            if data_en = '1' then
                if RGB_YCbCr = 0 then -- RGB bit pattern data.
                    case count is
                        when 0 =>
                            data_int  <=  pattern_ones & pattern_zeros & pattern_zeros;
                        when HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_ones & pattern_msb_bit_one & pattern_zeros;
                        when 2*HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_ones & pattern_ones & pattern_zeros;
                        when 3*HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_msb_bit_one & pattern_ones & pattern_zeros;
                        when 4*HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_zeros & pattern_ones & pattern_ones;
                        when 5*HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_zeros & pattern_zeros & pattern_ones;
                        when 6*HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_ones & pattern_zeros & pattern_ones;
                        when 7*HSYNC_ACTIVE/8 =>
                            data_int  <=  pattern_msb_bit_one & pattern_zeros & pattern_all_ones_minus_one;
                        when others =>
                            null;
                    end case;
                elsif (RGB_YCbCr = 1) and PIXEL_DEPTH = 8 then
                    case count is
                        when 0 =>
                            data_int  <=  x"80" & x"80" & x"B4"   ;
                        when HSYNC_ACTIVE/8 =>
                            data_int  <=  x"2C" & x"88" & x"A4"   ;
                        when 2*HSYNC_ACTIVE/8 =>
                            data_int  <=  x"93" & x"2C" & x"91"   ;
                        when 3*HSYNC_ACTIVE/8 =>
                            data_int  <=  x"C1" & x"CC" & x"3F"   ;
                        when 4*HSYNC_ACTIVE/8 =>
                            data_int  <=  x"3F" & x"34" & x"85"   ;
                        when 5*HSYNC_ACTIVE/8 =>
                            data_int  <=  x"6D" & x"D4" & x"33"   ;
                        when 6*HSYNC_ACTIVE/8 =>
                            data_int  <=  x"D4" & x"78" & x"1C"   ;
                        when 7*HSYNC_ACTIVE/8 =>
                            data_int  <=  x"80" & x"80" & x"10"   ;
                        when others =>
                            null;
                    end case;
                elsif (RGB_YCbCr = 1) and PIXEL_DEPTH = 10 then --XXXXXXXX Doesn't give right pattern... XXXX--- have to modify
                    case count is
                        when 0 =>
                            data_int  <=  x"80" & "00" & x"80" & "00" & x"B4" & "00" ;
                        when HSYNC_ACTIVE/8 =>                                
                            data_int  <=  x"2C" & "00" & x"88" & "00" & x"A4" & "00" ;
                        when 2*HSYNC_ACTIVE/8 =>                              
                            data_int  <=  x"93" & "00" & x"2C" & "00" & x"91" & "00" ;
                        when 3*HSYNC_ACTIVE/8 =>                              
                            data_int  <=  x"C1" & "00" & x"CC" & "00" & x"3F" & "00" ;
                        when 4*HSYNC_ACTIVE/8 =>                              
                            data_int  <=  x"3F" & "00" & x"34" & "00" & x"85" & "00" ;
                        when 5*HSYNC_ACTIVE/8 =>                              
                            data_int  <=  x"6D" & "00" & x"D4" & "00" & x"33" & "00" ;
                        when 6*HSYNC_ACTIVE/8 =>                              
                            data_int  <=  x"D4" & "00" & x"78" & "00" & x"1C" & "00" ;
                        when 7*HSYNC_ACTIVE/8 =>                              
                            data_int  <=  x"80" & "00" & x"80" & "00" & x"10" & "00" ;
                        when others =>
                            null;
                    end case;
                end if;
            elsif data_valid_int = '0' then
                data_int  <=  pattern_zeros & pattern_zeros & pattern_zeros;
            end if;
        end if;
    end process;

    -- output assignment
  hsync_out       <=  hsync_int_1d;
  vsync_out       <=  vsync_int_1d;
  data_out_valid  <=  data_valid_int_1d;


END ARCHITECTURE rtl;